//! Controller orchestration and atomic platform-independent publication.

use crate::config::ProjectConfig;
use crate::error::PrismError;
use crate::holo::canonical::{content_id, encode_canonical, encode_value};
use crate::holo::model_document::ModelDocument;
use crate::holo::projector::project_snapshot;
use camino::Utf8PathBuf;
use fs4::fs_std::FileExt;
use lexlean::{
    BuildRequest as LexBuildRequest, CheckRequest as LexCheckRequest, Engine, Selection,
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sha2::{Digest, Sha256};
use std::collections::BTreeSet;
use std::fs::{File, OpenOptions};
use std::io::Write;
use std::path::{Component, Path, PathBuf};

/// Controller for one canonical project root.
#[derive(Debug, Clone)]
pub struct Controller {
    pub(crate) root: PathBuf,
}

/// Request for a no-write model check.
#[derive(Debug, Clone)]
pub struct CheckRequest {
    /// Confined project configuration path, or the default prismpm.toml.
    pub config_path: Option<PathBuf>,
}

/// Successful check result.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CheckResult {
    /// Result schema.
    pub schema: String,
    /// LexLean semantic identity.
    pub semantic_id: String,
    /// Semantic snapshot identity.
    pub snapshot_id: String,
    /// Canonical Holo identity.
    pub model_id: String,
    /// Number of domain entities, excluding fixed catalogs.
    pub entity_count: u64,
}

/// Request for a platform-independent build.
#[derive(Debug, Clone)]
pub struct BuildRequest {
    /// Confined project configuration path, or the default prismpm.toml.
    pub config_path: Option<PathBuf>,
}

/// Successful build publication.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct BuildResult {
    /// Result schema.
    pub schema: String,
    /// Prism content-addressed build identity.
    pub build_id: String,
    /// LexLean source identity.
    pub source_id: String,
    /// LexLean semantic identity.
    pub semantic_id: String,
    /// Canonical relative Holo path.
    pub model_path: String,
    /// Canonical relative manifest path.
    pub manifest_path: String,
}

/// Request for complete verified execution.
#[derive(Debug, Clone)]
pub struct VerifyRequest {
    /// Confined project configuration path, or the default prismpm.toml.
    pub config_path: Option<PathBuf>,
}

/// Successful verification publication.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct VerifyResult {
    /// Result schema.
    pub schema: String,
    /// Prism attestation identity.
    pub attestation_id: String,
    /// Prism build identity.
    pub build_id: String,
    /// Published verified root.
    pub verified_root: String,
}

/// Request to remove only the configured Prism output root.
#[derive(Debug, Clone)]
pub struct CleanRequest {
    /// Confined project configuration path, or the default prismpm.toml.
    pub config_path: Option<PathBuf>,
}

/// Successful confined cleanup result.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CleanResult {
    /// Result schema.
    pub schema: String,
    /// Configured project-relative output root that was absent or removed.
    pub removed: String,
}

struct Prepared {
    config: ProjectConfig,
    engine: Engine,
    snapshot: lexlean::SemanticSnapshot,
    model: ModelDocument,
    model_bytes: Vec<u8>,
}

#[derive(Serialize)]
struct FileRow {
    path: String,
    kind: String,
    byte_length: u64,
    sha256: String,
}

fn utf8(path: PathBuf) -> Result<Utf8PathBuf, PrismError> {
    Utf8PathBuf::from_path_buf(path)
        .map_err(|_| PrismError::new("PP1001", "configured path is not UTF-8"))
}

fn count_entities(doc: &ModelDocument) -> Result<u64, PrismError> {
    let count = doc.architecture.components.len()
        + doc.architecture.edges.len()
        + doc.architecture.stakeholders.len()
        + doc.architecture.concerns.len()
        + doc.architecture.viewpoints.len()
        + doc.architecture.views.len()
        + doc.security.assets.len()
        + doc.security.threats.len()
        + doc.security.risks.len()
        + doc.security.controls.len()
        + doc.security.activities.len()
        + doc.security.measurements.len()
        + doc.quality.characteristics.len()
        + doc.quality.subcharacteristics.len()
        + doc.quality.requirements.len()
        + doc.quality.measures.len();
    u64::try_from(count).map_err(|_| PrismError::new("PP1003", "entity count exceeds u64"))
}

fn kind(path: &str) -> &'static str {
    if path.ends_with(".lean") {
        "lean"
    } else if path.ends_with(".tex") {
        "latex"
    } else if path.contains("/maps/") || path.starts_with("maps/") {
        "source-map"
    } else if path.contains("/coverage/") || path.starts_with("coverage/") {
        "coverage"
    } else if path.contains("/lexicons/") || path.starts_with("lexicons/") {
        "lexicon-closure"
    } else if path.ends_with("manifest.json") {
        "lexlean-manifest"
    } else if path.ends_with("snapshot.json") {
        "semantic-snapshot"
    } else {
        "artifact"
    }
}

fn artifact_relative(path: &str) -> Result<&str, PrismError> {
    if path.is_empty()
        || path.contains('\\')
        || Path::new(path)
            .components()
            .any(|component| !matches!(component, Component::Normal(_)))
    {
        return Err(PrismError::new(
            "PP4002",
            "LexLean manifest contains a noncanonical artifact path",
        ));
    }
    Ok(path)
}

fn write_file(root: &Path, relative: &str, bytes: &[u8]) -> Result<(), PrismError> {
    let path = root.join(relative);
    let parent = path
        .parent()
        .ok_or_else(|| PrismError::new("PP4002", "artifact has no parent"))?;
    std::fs::create_dir_all(parent)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", parent.display())))?;
    let mut file = OpenOptions::new()
        .create_new(true)
        .write(true)
        .open(&path)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", path.display())))?;
    file.write_all(bytes)
        .and_then(|()| file.sync_all())
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", path.display())))
}

fn verify_existing(root: &Path, files: &[(String, Vec<u8>)]) -> Result<(), PrismError> {
    let expected_paths = files
        .iter()
        .map(|(relative, _)| relative.as_str())
        .collect::<BTreeSet<_>>();
    let mut expected_directories = BTreeSet::new();
    for relative in &expected_paths {
        let mut parent = Path::new(relative).parent();
        while let Some(path) = parent.filter(|path| !path.as_os_str().is_empty()) {
            expected_directories.insert(path.to_string_lossy().replace('\\', "/"));
            parent = path.parent();
        }
    }
    let mut observed_paths = BTreeSet::new();
    let mut observed_directories = BTreeSet::new();
    for entry in walkdir::WalkDir::new(root).min_depth(1) {
        let entry =
            entry.map_err(|error| PrismError::new("PP4002", format!("artifact walk: {error}")))?;
        if entry.file_type().is_symlink() {
            return Err(PrismError::new(
                "PP4001",
                "published artifact contains a symlink",
            ));
        }
        if entry.file_type().is_file() {
            observed_paths.insert(
                entry
                    .path()
                    .strip_prefix(root)
                    .map_err(|_| PrismError::new("PP9001", "published artifact path escaped"))?
                    .to_string_lossy()
                    .replace('\\', "/"),
            );
        } else if entry.file_type().is_dir() {
            observed_directories.insert(
                entry
                    .path()
                    .strip_prefix(root)
                    .map_err(|_| PrismError::new("PP9001", "published directory escaped"))?
                    .to_string_lossy()
                    .replace('\\', "/"),
            );
        } else {
            return Err(PrismError::new(
                "PP4001",
                "published artifact contains a non-file entry",
            ));
        }
    }
    if observed_paths
        .iter()
        .map(String::as_str)
        .collect::<BTreeSet<_>>()
        != expected_paths
        || observed_directories != expected_directories
    {
        return Err(PrismError::new(
            "PP4001",
            "published artifact set differs from its manifest",
        ));
    }
    for (relative, expected) in files {
        let path = root.join(relative);
        let metadata = std::fs::symlink_metadata(&path)
            .map_err(|_| PrismError::new("PP4002", format!("missing {}", path.display())))?;
        if !metadata.is_file() || metadata.file_type().is_symlink() {
            return Err(PrismError::new("PP4001", "published artifact type changed"));
        }
        let observed = std::fs::read(&path)
            .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", path.display())))?;
        if &observed != expected {
            return Err(PrismError::new(
                "PP4001",
                format!("published artifact was modified: {relative}"),
            ));
        }
    }
    Ok(())
}

impl Controller {
    /// Load a project root without parsing or mutating its model.
    pub fn load(root: impl AsRef<Path>) -> Result<Self, PrismError> {
        let supplied = root.as_ref();
        if std::fs::symlink_metadata(supplied)
            .map(|metadata| metadata.file_type().is_symlink())
            .unwrap_or(false)
        {
            return Err(PrismError::new("PP8001", "project root is a symlink"));
        }
        let root = supplied.canonicalize().map_err(|error| {
            PrismError::new("PP1002", format!("{}: {error}", supplied.display()))
        })?;
        if !root.is_dir() {
            return Err(PrismError::new("PP1002", "project root is not a directory"));
        }
        Ok(Self { root })
    }

    fn prepare(&self, config_path: Option<&Path>) -> Result<Prepared, PrismError> {
        let (config, _) = ProjectConfig::load(&self.root, config_path)?;
        let project_file = utf8(config.lexlean_path(&self.root)?)?;
        let engine = Engine::load(&project_file).map_err(|error| {
            PrismError::from_lexlean(
                "PP2001",
                "LexLean project load failed",
                error,
                config.limits.max_diagnostics,
            )
        })?;
        let snapshot = engine
            .snapshot(LexCheckRequest {
                selection: Selection::Entrypoints,
            })
            .map_err(|error| {
                PrismError::from_lexlean(
                    "PP2001",
                    "LexLean snapshot failed",
                    error,
                    config.limits.max_diagnostics,
                )
            })?;
        crate::holo::projector::validate_snapshot_envelope(&snapshot.canonical_bytes())?;
        let model = match crate::holo::application::project_application(&snapshot)? {
            Some(model) => model,
            None => project_snapshot(&snapshot)?,
        };
        let model_bytes = encode_canonical(&model)?;
        let entities = count_entities(&model)?;
        if entities > config.limits.max_entities {
            return Err(PrismError::new("PP1003", "max_entities exceeded"));
        }
        if model_bytes.len() as u64 > config.limits.max_holo_bytes {
            return Err(PrismError::new("PP1003", "max_holo_bytes exceeded"));
        }
        Ok(Prepared {
            config,
            engine,
            snapshot,
            model,
            model_bytes,
        })
    }

    /// Check through LexLean snapshot, Holo projection, and validation in memory.
    pub fn check(&self, request: CheckRequest) -> Result<CheckResult, PrismError> {
        let prepared = self.prepare(request.config_path.as_deref())?;
        Ok(CheckResult {
            schema: "prismpm/check-result/1".to_owned(),
            semantic_id: prepared.snapshot.semantic_id().to_string(),
            snapshot_id: prepared.snapshot.snapshot_id().to_string(),
            model_id: content_id(&prepared.model_bytes),
            entity_count: count_entities(&prepared.model)?,
        })
    }

    /// Build LexLean artifacts and atomically publish the fixed Prism artifact set.
    pub fn build(&self, request: BuildRequest) -> Result<BuildResult, PrismError> {
        let prepared = self.prepare(request.config_path.as_deref())?;
        let lex = prepared
            .engine
            .build(LexBuildRequest {
                selection: Selection::Entrypoints,
            })
            .map_err(|error| {
                PrismError::from_lexlean(
                    "PP4002",
                    "LexLean build failed",
                    error,
                    prepared.config.limits.max_diagnostics,
                )
            })?;
        let lex_build_id = lex
            .build_id
            .ok_or_else(|| PrismError::new("PP9001", "LexLean build omitted its identity"))?
            .to_string();
        let output_root = prepared.config.output_root(&self.root)?;
        let lex_root = self.root.join(".lexlean/build").join(&lex_build_id);
        let lex_manifest_path = lex_root.join("manifest.json");
        let lex_manifest_bytes = std::fs::read(&lex_manifest_path).map_err(|error| {
            PrismError::new(
                "PP4002",
                format!("{}: {error}", lex_manifest_path.display()),
            )
        })?;
        let lex_manifest: serde_json::Value = serde_json::from_slice(&lex_manifest_bytes)
            .map_err(|error| PrismError::new("PP4002", format!("LexLean manifest: {error}")))?;
        let outputs = lex_manifest
            .get("outputs")
            .and_then(serde_json::Value::as_array)
            .ok_or_else(|| PrismError::new("PP4002", "LexLean manifest has no output list"))?;
        let mut lex_paths = BTreeSet::new();
        for output in outputs {
            let path = output
                .get("path")
                .and_then(serde_json::Value::as_str)
                .ok_or_else(|| PrismError::new("PP4002", "LexLean output has no path"))?;
            artifact_relative(path)?;
            if !lex_paths.insert(path.to_owned()) {
                return Err(PrismError::new(
                    "PP4002",
                    "LexLean manifest contains a duplicate artifact path",
                ));
            }
        }
        lex_paths.insert("manifest.json".to_owned());

        let mut artifacts = vec![
            ("model.prism.json".to_owned(), prepared.model_bytes.clone()),
            (
                "lexlean/snapshot.json".to_owned(),
                prepared.snapshot.canonical_bytes(),
            ),
        ];
        for path in lex_paths {
            let source = lex_root.join(&path);
            let metadata = std::fs::symlink_metadata(&source).map_err(|error| {
                PrismError::new("PP4002", format!("{}: {error}", source.display()))
            })?;
            if !metadata.is_file() || metadata.file_type().is_symlink() {
                return Err(PrismError::new("PP4002", "LexLean artifact is not a file"));
            }
            artifacts.push((
                format!("lexlean/build/{path}"),
                std::fs::read(&source).map_err(|error| {
                    PrismError::new("PP4002", format!("{}: {error}", source.display()))
                })?,
            ));
        }
        if prepared.model.application.is_some() {
            artifacts.extend(crate::application_build::generate(
                &self.root,
                &prepared.model,
                &prepared.model_bytes,
                &lex_root,
                &lex_manifest_bytes,
            )?);
        }
        artifacts.sort_by(|a, b| a.0.as_bytes().cmp(b.0.as_bytes()));
        let model_id = content_id(&prepared.model_bytes);
        let dependency_digest = format!(
            "{:x}",
            Sha256::digest(include_bytes!("../../model/dependencies.toml"))
        );
        let inputs = json!({
            "application_generator_sha256": format!("{:x}", Sha256::digest([
                include_bytes!("../application_build.rs").as_slice(),
                include_bytes!("../holo/archive.rs").as_slice(),
                include_bytes!("../embedded/lean4-prod-rust.MANIFEST.sha256").as_slice()
            ].concat())),
            "dependency_register_sha256": dependency_digest,
            "emitter_semantics_id": prepared.model.provenance.emitter_semantics_id,
            "model_id": model_id,
            "lexlean_build_id": lex_build_id,
            "lexlean_semantic_id": prepared.snapshot.semantic_id().to_string(),
            "lexlean_source_id": prepared.snapshot.source_id().to_string(),
            "schema": "prismpm/build-inputs/1"
        });
        let build_id = content_id(&encode_value(&inputs)?);
        let rows: Vec<FileRow> = artifacts
            .iter()
            .map(|(path, bytes)| FileRow {
                path: path.clone(),
                kind: kind(path).to_owned(),
                byte_length: bytes.len() as u64,
                sha256: format!("{:x}", Sha256::digest(bytes)),
            })
            .collect();
        let manifest_value = serde_json::to_value(json!({
            "files": rows,
            "inputs": inputs,
            "schema": "prismpm/build-manifest/1"
        }))
        .map_err(|error| PrismError::new("PP9001", error.to_string()))?;
        let manifest_bytes = encode_value(&manifest_value)?;
        artifacts.push(("manifest.json".to_owned(), manifest_bytes));

        std::fs::create_dir_all(&output_root).map_err(|error| {
            PrismError::new("PP4002", format!("{}: {error}", output_root.display()))
        })?;
        if std::fs::symlink_metadata(&output_root)
            .map(|metadata| metadata.file_type().is_symlink())
            .unwrap_or(false)
        {
            return Err(PrismError::new("PP8001", "output root is a symlink"));
        }
        let lock_path = output_root.join(".prismpm.lock");
        let lock = OpenOptions::new()
            .create(true)
            .truncate(false)
            .write(true)
            .open(&lock_path)
            .map_err(|error| {
                PrismError::new("PP4002", format!("{}: {error}", lock_path.display()))
            })?;
        lock.lock_exclusive()
            .map_err(|error| PrismError::new("PP4002", format!("publish lock: {error}")))?;
        let build_parent = output_root.join("build");
        std::fs::create_dir_all(&build_parent).map_err(|error| {
            PrismError::new("PP4002", format!("{}: {error}", build_parent.display()))
        })?;
        let destination = build_parent.join(&build_id);
        if destination.exists() {
            verify_existing(&destination, &artifacts)?;
        } else {
            let staging_parent = output_root.join(".staging");
            std::fs::create_dir_all(&staging_parent).map_err(|error| {
                PrismError::new("PP4002", format!("{}: {error}", staging_parent.display()))
            })?;
            let staging = tempfile::Builder::new()
                .prefix("build-")
                .tempdir_in(&staging_parent)
                .map_err(|error| PrismError::new("PP4002", format!("staging: {error}")))?;
            for (path, bytes) in &artifacts {
                write_file(staging.path(), path, bytes)?;
            }
            File::open(staging.path())
                .and_then(|file| file.sync_all())
                .map_err(|error| PrismError::new("PP4002", format!("staging fsync: {error}")))?;
            std::fs::rename(staging.path(), &destination)
                .map_err(|error| PrismError::new("PP4002", format!("publish rename: {error}")))?;
            File::open(&build_parent)
                .and_then(|file| file.sync_all())
                .map_err(|error| PrismError::new("PP4002", format!("build fsync: {error}")))?;
        }
        drop(lock);
        Ok(BuildResult {
            schema: "prismpm/build-result/1".to_owned(),
            build_id: build_id.clone(),
            source_id: prepared.snapshot.source_id().to_string(),
            semantic_id: prepared.snapshot.semantic_id().to_string(),
            model_path: format!(
                "{}/build/{build_id}/model.prism.json",
                prepared.config.build_root
            ),
            manifest_path: format!(
                "{}/build/{build_id}/manifest.json",
                prepared.config.build_root
            ),
        })
    }

    /// Remove only the configured real Prism output directory.
    pub fn clean(&self, request: CleanRequest) -> Result<CleanResult, PrismError> {
        let (config, _) = ProjectConfig::load(&self.root, request.config_path.as_deref())?;
        let output = config.output_root(&self.root)?;
        if let Ok(metadata) = std::fs::symlink_metadata(&output) {
            if metadata.file_type().is_symlink() || !metadata.is_dir() {
                return Err(PrismError::new(
                    "PP8001",
                    "configured output root is not a real directory",
                ));
            }
            std::fs::remove_dir_all(&output).map_err(|error| {
                PrismError::new("PP4002", format!("clean {}: {error}", output.display()))
            })?;
        }
        Ok(CleanResult {
            schema: "prismpm/clean-result/1".to_owned(),
            removed: config.build_root,
        })
    }

    /// Run the complete verified Lean-to-LCNF-to-Rust execution chain.
    pub fn verify(&self, request: VerifyRequest) -> Result<VerifyResult, PrismError> {
        crate::verification::run(self, request)
    }
}
