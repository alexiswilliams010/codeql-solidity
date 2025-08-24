use clap::Args;
use std::path::PathBuf;

use codeql_extractor::{extractor::simple::{Extractor, LanguageSpec}, trap};

#[derive(Args)]
pub struct Options {
    /// Sets a custom source archive folder
    #[arg(long)]
    source_archive_dir: PathBuf,

    /// Sets a custom trap folder
    #[arg(long)]
    output_dir: PathBuf,

    /// A text file containing the paths of the files to extract
    #[arg(long)]
    file_list: PathBuf,
}

pub fn run(options: Options) -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_target(false)
        .without_time()
        .with_level(true)
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    // The shared extractor framework for tree-sitter languages will handle the parsing and extraction.
    // We just need to specify the language and the node types.
    let extractor = Extractor {
        prefix: "solidity".to_string(),
        source_archive_dir: options.source_archive_dir,
        trap_dir: options.output_dir,
        file_lists: vec![options.file_list],
        languages: vec![LanguageSpec {
            prefix: "solidity",
            ts_language: tree_sitter_solidity::LANGUAGE.into(),
            node_types: tree_sitter_solidity::NODE_TYPES,
            file_globs: vec!["sol".into()],
        }],
        trap_compression: trap::Compression::from_env("CODEQL_KALEIDOSCOPE_TRAP_COMPRESSION"),
    };
    extractor.run()
}