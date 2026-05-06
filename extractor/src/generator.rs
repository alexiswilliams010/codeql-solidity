use clap::Args;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::{Path, PathBuf};

use codeql_extractor::generator::{generate, language::Language};

#[derive(Args)]
pub struct Options {
    /// Path of the generated dbscheme file
    #[arg(long)]
    dbscheme: PathBuf,

    /// Path of the generated QLL file
    #[arg(long)]
    library: PathBuf,
}

pub fn run(options: Options) -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_target(false)
        .without_time()
        .with_level(true)
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let languages = vec![Language {
        name: "Solidity".to_owned(),
        node_types: tree_sitter_solidity::NODE_TYPES,
    }];

    let dbscheme_path = options.dbscheme.clone();
    generate(languages, options.dbscheme, options.library)?;
    append_extra_relations(&dbscheme_path)
}

/// Append non-AST relations that the tree-sitter generator can't produce.
///
/// `solidity_import_resolution` maps each `import "X" ...;` directive to the
/// file it resolves to via the project's remappings/lib paths. Populated by
/// the extractor's foundry-compilers post-pass; unresolved imports have no row.
/// `source_string` is the import path as foundry-compilers parsed it (no
/// surrounding quotes); the QL accessor strips quotes from the AST token
/// before joining.
fn append_extra_relations(dbscheme_path: &Path) -> std::io::Result<()> {
    let extras = "\n\
        /*- Extractor-supplied relations (not derived from the tree-sitter grammar) -*/\n\
        \n\
        solidity_import_resolution(\n  \
        int importer: @file ref,\n  \
        string source_string: string ref,\n  \
        int resolved: @file ref\n\
        );\n";
    let mut f = OpenOptions::new().append(true).open(dbscheme_path)?;
    f.write_all(extras.as_bytes())
}
