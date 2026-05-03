use clap::Args;
use codeql_extractor::{diagnostics, extractor, file_paths, node_types, trap};
use foundry_compilers::{Graph, ProjectPathsConfig};
use foundry_compilers::artifacts::remappings::Remapping;
use foundry_compilers::compilers::multi::MultiCompilerParser;
use rayon::prelude::*;
use std::fs;
use std::io::BufRead;
use std::path::{Path, PathBuf};
use tree_sitter::Language;

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

    tracing::info!("Extraction started");
    let diagnostics = diagnostics::DiagnosticLoggers::new("solidity");
    let mut main_thread_logger = diagnostics.logger();

    let num_threads = match codeql_extractor::options::num_threads() {
        Ok(num) => num,
        Err(e) => {
            main_thread_logger.write(
                main_thread_logger
                    .new_entry("configuration-error", "Configuration error")
                    .message(
                        "{}; defaulting to 1 thread.",
                        &[diagnostics::MessageArg::Code(&e)],
                    )
                    .severity(diagnostics::Severity::Warning),
            );
            1
        }
    };
    tracing::info!(
        "Using {} {}",
        num_threads,
        if num_threads == 1 {
            "thread"
        } else {
            "threads"
        }
    );

    let trap_compression =
        match trap::Compression::from_env("CODEQL_EXTRACTOR_SOLIDITY_OPTION_TRAP_COMPRESSION") {
            Ok(x) => x,
            Err(e) => {
                main_thread_logger.write(
                    main_thread_logger
                        .new_entry("configuration-error", "Configuration error")
                        .message("{}; using gzip.", &[diagnostics::MessageArg::Code(&e)])
                        .severity(diagnostics::Severity::Warning),
                );
                trap::Compression::Gzip
            }
        };
    drop(main_thread_logger);

    rayon::ThreadPoolBuilder::new()
        .num_threads(num_threads)
        .build_global()
        .unwrap();

    let src_archive_dir = &options.source_archive_dir;
    let trap_dir = &options.output_dir;

    let file_list = fs::File::open(&options.file_list)?;
    let path_transformer = file_paths::load_path_transformer()?;

    let language: Language = tree_sitter_solidity::LANGUAGE.into();
    let schema = node_types::read_node_types_str("solidity", tree_sitter_solidity::NODE_TYPES)?;

    // Read the initial file list
    let lines: std::io::Result<Vec<String>> =
        std::io::BufReader::new(file_list).lines().collect();
    let initial_files: Vec<PathBuf> = lines?
        .into_iter()
        .filter_map(|line| PathBuf::from(line).canonicalize().ok())
        .filter(|path| path.extension().map(|e| e == "sol").unwrap_or(false))
        .collect();

    tracing::info!("Initial files to extract: {}", initial_files.len());

    // Get the source root from current working directory (set by CodeQL)
    let source_root = std::env::current_dir().ok();
    
    // Attempt to discover and resolve dependencies using foundry-compilers
    let all_files = discover_dependencies(&initial_files, &diagnostics, source_root.as_ref())?;

    tracing::info!("Total files after dependency resolution: {}", all_files.len());

    // Extract all discovered files
    all_files
        .par_iter()
        .try_for_each(|path| -> std::io::Result<()> {
            let mut diagnostics_writer = diagnostics.logger();
            tracing::info!("extracting: {}", path.display());

            // Check if file exists before processing
            if !path.exists() {
                return Err(std::io::Error::new(
                    std::io::ErrorKind::NotFound,
                    format!("File does not exist: {}", path.display())
                ));
            }

            let src_archive_file = file_paths::path_for(
                src_archive_dir,
                path,
                "",
                path_transformer.as_ref(),
            );

            let source = std::fs::read(path).map_err(|e| {
                std::io::Error::new(
                    e.kind(),
                    format!("Failed to read file {}: {}", path.display(), e)
                )
            })?;

            let mut trap_writer = trap::Writer::new();

            extractor::extract(
                &language,
                "solidity",
                &schema,
                &mut diagnostics_writer,
                &mut trap_writer,
                path_transformer.as_ref(),
                path,
                &source,
                &[],
            );

            std::fs::create_dir_all(src_archive_file.parent().unwrap()).map_err(|e| {
                std::io::Error::new(
                    e.kind(),
                    format!("Failed to create directory {}: {}", src_archive_file.parent().unwrap().display(), e)
                )
            })?;

            std::fs::copy(path, &src_archive_file).map_err(|e| {
                std::io::Error::new(
                    e.kind(),
                    format!("Failed to copy {} to {}: {}", path.display(), src_archive_file.display(), e)
                )
            })?;

            write_trap(trap_dir, path.clone(), &trap_writer, trap_compression, path_transformer.as_ref())
        })
        .map_err(|e| {
            tracing::error!("Failed to extract files: {}", e);
            e
        })?;

    let path = PathBuf::from("extras");
    let mut trap_writer = trap::Writer::new();
    extractor::populate_empty_location(&mut trap_writer);
    let res = write_trap(
        trap_dir,
        path,
        &trap_writer,
        trap_compression,
        path_transformer.as_ref(),
    );

    tracing::info!("Extraction complete");
    res
}

fn write_trap(
    trap_dir: &Path,
    path: PathBuf,
    trap_writer: &trap::Writer,
    trap_compression: trap::Compression,
    path_transformer: Option<&file_paths::PathTransformer>,
) -> std::io::Result<()> {
    let trap_file = file_paths::path_for(
        trap_dir,
        &path,
        trap_compression.extension(),
        path_transformer,
    );
    std::fs::create_dir_all(trap_file.parent().unwrap())?;
    trap_writer.write_to_file(&trap_file, trap_compression)
}

#[derive(Debug, Clone, Copy)]
enum ProjectLayout {
    Foundry,
    Hardhat,
    Default,
}

impl ProjectLayout {
    fn detect(root: &Path) -> Self {
        if root.join("foundry.toml").exists() {
            ProjectLayout::Foundry
        } else if root.join("hardhat.config.ts").exists() {
            ProjectLayout::Hardhat
        } else {
            ProjectLayout::Default
        }
    }

    fn name(&self) -> &'static str {
        match self {
            ProjectLayout::Foundry => "Foundry",
            ProjectLayout::Hardhat => "Hardhat",
            ProjectLayout::Default => "default",
        }
    }

    fn sources_dir(&self, root: &Path) -> PathBuf {
        match self {
            ProjectLayout::Foundry => root.join("src"),
            ProjectLayout::Hardhat => root.join("contracts"),
            ProjectLayout::Default => root.to_path_buf(),
        }
    }
}

/// Discovers all dependencies for the given Solidity files using foundry-compilers
fn discover_dependencies(
    initial_files: &[PathBuf],
    diagnostics: &diagnostics::DiagnosticLoggers,
    source_root: Option<&PathBuf>,
) -> std::io::Result<Vec<PathBuf>> {
    let mut diagnostics_writer = diagnostics.logger();

    let Some(root) = source_root else {
        tracing::info!("No source root from current working directory; using initial file list");
        return Ok(initial_files.to_vec());
    };

    let layout = ProjectLayout::detect(root);
    tracing::info!(
        "Resolving dependencies at {} using {} layout",
        root.display(),
        layout.name()
    );

    match try_resolve_with_foundry(root, layout) {
        Ok(resolved_files) => {
            let count = resolved_files.len();
            tracing::info!("Resolved {} files using {} layout", count, layout.name());
            diagnostics_writer.write(
                diagnostics_writer
                    .new_entry(
                        "dependency-resolution-succeeded",
                        "Dependency resolution succeeded",
                    )
                    .message(
                        "Resolved {} Solidity files via {} layout at {}.",
                        &[
                            diagnostics::MessageArg::Code(&count.to_string()),
                            diagnostics::MessageArg::Code(layout.name()),
                            diagnostics::MessageArg::Code(&root.display().to_string()),
                        ],
                    )
                    .severity(diagnostics::Severity::Note),
            );
            Ok(resolved_files)
        }
        Err(e) => {
            tracing::warn!(
                "Dependency resolution failed for {} layout at {}: {}",
                layout.name(),
                root.display(),
                e
            );
            diagnostics_writer.write(
                diagnostics_writer
                    .new_entry(
                        "dependency-resolution-failed",
                        "Dependency resolution failed",
                    )
                    .message(
                        "Failed to resolve dependencies via {} layout at {}: {}. Falling back to the {} initial files; transitive imports will not be extracted.",
                        &[
                            diagnostics::MessageArg::Code(layout.name()),
                            diagnostics::MessageArg::Code(&root.display().to_string()),
                            diagnostics::MessageArg::Code(&e.to_string()),
                            diagnostics::MessageArg::Code(&initial_files.len().to_string()),
                        ],
                    )
                    .severity(diagnostics::Severity::Warning),
            );
            Ok(initial_files.to_vec())
        }
    }
}

/// Try to resolve dependencies using foundry-compilers
fn try_resolve_with_foundry(
    root: &Path,
    layout: ProjectLayout,
) -> Result<Vec<PathBuf>, Box<dyn std::error::Error>> {
    let sources = layout.sources_dir(root);
    let lib_dir = match layout {
        ProjectLayout::Foundry | ProjectLayout::Default => root.join("lib"),
        ProjectLayout::Hardhat => root.join("node_modules"),
    };

    let mut remappings: Vec<Remapping> = Vec::new();

    let remappings_txt = root.join("remappings.txt");
    if remappings_txt.exists() {
        let content = std::fs::read_to_string(&remappings_txt)?;
        for line in content.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }
            match trimmed.parse::<Remapping>() {
                Ok(r) => remappings.push(r),
                Err(e) => tracing::warn!("Skipping invalid remapping '{}': {}", trimmed, e),
            }
        }
    }

    if lib_dir.exists() {
        remappings.extend(Remapping::find_many(&lib_dir));
    }

    let paths: ProjectPathsConfig = ProjectPathsConfig::builder()
        .root(root)
        .sources(&sources)
        .lib(&lib_dir)
        .remappings(remappings)
        .build()
        .map_err(|e| format!("Failed to build paths config: {}", e))?;

    tracing::info!(
        "Building project with sources at: {} ({} remappings)",
        paths.sources.display(),
        paths.remappings.len()
    );

    let graph: Graph<MultiCompilerParser> = Graph::resolve(&paths)?;

    Ok(graph.files().keys().cloned().collect())
}