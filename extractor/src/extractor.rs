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

    // Extract all discovered files. Per-file failures are logged as diagnostics
    // and skipped so a single bad file doesn't abort the whole extraction.
    let failed_count = std::sync::atomic::AtomicUsize::new(0);
    all_files.par_iter().for_each(|path| {
        let mut diagnostics_writer = diagnostics.logger();
        tracing::debug!("extracting: {}", path.display());

        if let Err(e) = extract_one_file(
            path,
            &language,
            &schema,
            &mut diagnostics_writer,
            src_archive_dir,
            trap_dir,
            trap_compression,
            path_transformer.as_ref(),
        ) {
            failed_count.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
            tracing::warn!("Failed to extract {}: {}", path.display(), e);
            diagnostics_writer.write(
                diagnostics_writer
                    .new_entry("file-extraction-failed", "File extraction failed")
                    .file(&path.display().to_string())
                    .message(
                        "Failed to extract {}: {}",
                        &[
                            diagnostics::MessageArg::Code(&path.display().to_string()),
                            diagnostics::MessageArg::Code(&e.to_string()),
                        ],
                    )
                    .severity(diagnostics::Severity::Warning),
            );
        }
    });
    let failed = failed_count.load(std::sync::atomic::Ordering::Relaxed);
    if failed > 0 {
        tracing::warn!("{} of {} files failed to extract", failed, all_files.len());
    }

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

fn extract_one_file(
    path: &Path,
    language: &Language,
    schema: &node_types::NodeTypeMap,
    diagnostics_writer: &mut diagnostics::LogWriter,
    src_archive_dir: &Path,
    trap_dir: &Path,
    trap_compression: trap::Compression,
    path_transformer: Option<&file_paths::PathTransformer>,
) -> std::io::Result<()> {
    let source = std::fs::read(path)?;

    let src_archive_file = file_paths::path_for(src_archive_dir, path, "", path_transformer);

    let mut trap_writer = trap::Writer::new();
    extractor::extract(
        language,
        "solidity",
        schema,
        diagnostics_writer,
        &mut trap_writer,
        path_transformer,
        path,
        &source,
        &[],
    );

    if let Some(parent) = src_archive_file.parent() {
        std::fs::create_dir_all(parent)?;
    }
    std::fs::copy(path, &src_archive_file)?;

    write_trap(
        trap_dir,
        path.to_path_buf(),
        &trap_writer,
        trap_compression,
        path_transformer,
    )
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

#[derive(Default)]
struct FoundryConfig {
    src: Option<String>,
    libs: Vec<String>,
    remappings: Vec<Remapping>,
}

/// Parse the `[profile.default]` section of foundry.toml.
/// Returns None if foundry.toml doesn't exist or can't be parsed; missing fields fall back to None/empty.
fn parse_foundry_toml(root: &Path) -> Option<FoundryConfig> {
    let path = root.join("foundry.toml");
    let content = std::fs::read_to_string(&path).ok()?;
    let value: toml::Value = content.parse().ok()?;
    let profile = value.get("profile")?.get("default")?;

    let src = profile
        .get("src")
        .and_then(|v| v.as_str())
        .map(String::from);

    let libs = profile
        .get("libs")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(String::from))
                .collect()
        })
        .unwrap_or_default();

    let remappings = profile
        .get("remappings")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str())
                .filter_map(|s| match s.parse::<Remapping>() {
                    Ok(r) => Some(r),
                    Err(e) => {
                        tracing::warn!("Skipping invalid remapping in foundry.toml '{}': {}", s, e);
                        None
                    }
                })
                .collect()
        })
        .unwrap_or_default();

    Some(FoundryConfig {
        src,
        libs,
        remappings,
    })
}

fn load_remappings_txt(root: &Path) -> std::io::Result<Vec<Remapping>> {
    let path = root.join("remappings.txt");
    if !path.exists() {
        return Ok(Vec::new());
    }
    let content = std::fs::read_to_string(&path)?;
    let mut remappings = Vec::new();
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
    Ok(remappings)
}

/// Try to resolve dependencies using foundry-compilers
fn try_resolve_with_foundry(
    root: &Path,
    layout: ProjectLayout,
) -> Result<Vec<PathBuf>, Box<dyn std::error::Error>> {
    let foundry_config = if matches!(layout, ProjectLayout::Foundry) {
        parse_foundry_toml(root).unwrap_or_default()
    } else {
        FoundryConfig::default()
    };

    let sources = match foundry_config.src.as_deref() {
        Some(src) => root.join(src),
        None => layout.sources_dir(root),
    };

    let lib_dirs: Vec<PathBuf> = if !foundry_config.libs.is_empty() {
        foundry_config.libs.iter().map(|l| root.join(l)).collect()
    } else {
        match layout {
            ProjectLayout::Foundry | ProjectLayout::Default => vec![root.join("lib")],
            ProjectLayout::Hardhat => vec![root.join("node_modules")],
        }
    };

    let mut remappings: Vec<Remapping> = foundry_config.remappings;
    remappings.extend(load_remappings_txt(root)?);
    for lib_dir in &lib_dirs {
        if lib_dir.exists() {
            remappings.extend(Remapping::find_many(lib_dir));
        }
    }

    let mut builder = ProjectPathsConfig::builder()
        .root(root)
        .sources(&sources)
        .remappings(remappings);
    for lib_dir in &lib_dirs {
        builder = builder.lib(lib_dir);
    }

    let paths: ProjectPathsConfig = builder
        .build()
        .map_err(|e| format!("Failed to build paths config: {}", e))?;

    tracing::info!(
        "Building project with sources at: {} ({} remappings, {} lib dirs)",
        paths.sources.display(),
        paths.remappings.len(),
        lib_dirs.len()
    );

    let graph: Graph<MultiCompilerParser> = Graph::resolve(&paths)?;

    Ok(graph.files().keys().cloned().collect())
}