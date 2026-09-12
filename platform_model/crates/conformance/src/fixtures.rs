//! Fixture discovery and validation for PrismPM.

use std::path::{Path, PathBuf};

use serde::Deserialize;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Case {
    spec: String,
    command: String,
    expected_exit: i32,
    normalization: String,
    capabilities: Vec<String>,
    expected_artifacts: Vec<String>,
    expected_diagnostics: Vec<ExpectedDiagnostic>,
    #[serde(default)]
    oracle: Vec<CaseOracle>,
}

#[derive(Debug, Deserialize, PartialEq, Eq)]
#[serde(deny_unknown_fields)]
struct CaseOracle {
    function: String,
    theorem: String,
}

#[derive(Debug, Deserialize, PartialEq, Eq)]
#[serde(deny_unknown_fields)]
struct ExpectedDiagnostic {
    code: String,
    message: String,
    primary: String,
    labels: Vec<String>,
    notes: Vec<String>,
    help: Vec<String>,
}

fn span(span: &prismpm::error::PrismSpan) -> String {
    format!(
        "{}:{}:{}-{}:{}:{}-{}",
        span.path,
        span.byte_start,
        span.byte_end,
        span.line_start,
        span.column_start,
        span.line_end,
        span.column_end
    )
}

fn diagnostic(error: &prismpm::PrismError) -> ExpectedDiagnostic {
    ExpectedDiagnostic {
        code: error.code.as_str().to_owned(),
        message: error.message.clone(),
        primary: error
            .primary
            .as_ref()
            .map(span)
            .unwrap_or_else(|| "none".to_owned()),
        labels: error
            .labels
            .iter()
            .map(|label| format!("{}@{}", label.message, span(&label.span)))
            .collect(),
        notes: error
            .notes
            .iter()
            .map(|note| match &note.span {
                Some(location) => format!("{}@{}", note.message, span(location)),
                None => note.message.clone(),
            })
            .collect(),
        help: error.help.clone(),
    }
}

/// Discover all fixture directories containing case.toml.
pub fn discover(root: &Path) -> Vec<PathBuf> {
    let mut fixtures = Vec::new();
    let search_roots = [root.join("tests/fixtures"), root.join("tests/negative")];
    for search_root in search_roots {
        if !search_root.exists() {
            continue;
        }
        for entry in walkdir::WalkDir::new(search_root).into_iter().flatten() {
            if entry.file_name() == "case.toml" {
                if let Some(parent) = entry.path().parent() {
                    fixtures.push(parent.to_path_buf());
                }
            }
        }
    }
    fixtures.sort();
    fixtures
}

/// Check one fixture directory against its expected files.
pub fn check(dir: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let case_path = dir.join("case.toml");
    if !case_path.exists() {
        return Err(format!("{}: missing case.toml", dir.display()).into());
    }
    let case: Case = toml::from_str(&std::fs::read_to_string(&case_path)?)?;
    if case.spec != "prismpm/test-case/1" {
        return Err(format!("{}: invalid case spec `{}`", dir.display(), case.spec).into());
    }
    if !matches!(case.normalization.as_str(), "none" | "canonical-json") {
        return Err(format!("{}: unsupported normalization", dir.display()).into());
    }
    let model = repo_model::Model::load_from_repo_root()?;
    let mut capabilities = std::collections::BTreeSet::new();
    for capability in &case.capabilities {
        if model.ids.get(capability).is_none() || !capabilities.insert(capability.as_str()) {
            return Err(format!("{}: invalid capability {capability}", dir.display()).into());
        }
    }
    if capabilities.is_empty() {
        return Err(format!("{}: case declares no capabilities", dir.display()).into());
    }

    if capabilities.contains("EX-06") {
        let expected = model
            .execution_corpus
            .oracle
            .iter()
            .map(|row| CaseOracle {
                function: row.function.clone(),
                theorem: row.theorem.clone(),
            })
            .collect::<Vec<_>>();
        if case.oracle != expected {
            return Err(format!(
                "{}: EX-06 fixture oracle register differs from model/execution-corpus.toml",
                dir.display()
            )
            .into());
        }
        let formal_source =
            std::fs::read_to_string(dir.join("project/stdlib/src/Foundation/Holo.lex.tex"))?;
        for oracle in &case.oracle {
            for qualified in [&oracle.function, &oracle.theorem] {
                let name = qualified
                    .rsplit('.')
                    .next()
                    .ok_or("execution oracle has no final name")?;
                if !formal_source.contains(&format!(r#""name":"{name}""#)) {
                    return Err(format!(
                        "{}: execution oracle {qualified} is absent from LexLean formal source",
                        dir.display()
                    )
                    .into());
                }
            }
        }
    } else if !case.oracle.is_empty() {
        return Err(format!(
            "{}: only an EX-06 fixture may declare execution oracles",
            dir.display()
        )
        .into());
    }

    let project_dir = dir.join("project");
    if !project_dir.is_dir() {
        return Err(format!("{}: case has no complete project", dir.display()).into());
    }
    let temp_dir = tempfile::tempdir()?;
    copy_dir_recursive(&project_dir, temp_dir.path())?;
    let controller = prismpm::Controller::load(temp_dir.path())?;
    let outcome = match case.command.as_str() {
        "check" => controller
            .check(prismpm::controller::CheckRequest { config_path: None })
            .map(|_| Vec::new()),
        "build" => controller
            .build(prismpm::controller::BuildRequest { config_path: None })
            .map(|result| {
                let root = temp_dir.path().join(".prism/build").join(result.build_id);
                walkdir::WalkDir::new(root)
                    .into_iter()
                    .filter_map(Result::ok)
                    .filter(|entry| entry.file_type().is_file())
                    .map(|entry| {
                        entry
                            .path()
                            .strip_prefix(temp_dir.path())
                            .expect("artifact stays in temporary project")
                            .to_string_lossy()
                            .replace('\\', "/")
                    })
                    .collect()
            }),
        "holo-dangling-edge"
        | "holo-unresolved-risk"
        | "holo-empty"
        | "holo-minimal"
        | "holo-duplicate-id"
        | "holo-bad-profile"
        | "holo-noncanonical" => controller
            .build(prismpm::controller::BuildRequest { config_path: None })
            .and_then(|result| {
                let bytes = std::fs::read(temp_dir.path().join(result.model_path))
                    .map_err(|error| prismpm::PrismError::new("PP4002", error.to_string()))?;
                if case.command == "holo-noncanonical" {
                    let mut malformed = bytes;
                    malformed.insert(1, b' ');
                    return prismpm::holo::canonical::decode_canonical(&malformed)
                        .map(|_| Vec::new());
                }
                let mut holo = prismpm::holo::canonical::decode_canonical(&bytes)?;
                if case.command == "holo-dangling-edge" {
                    let count = holo.architecture.components.len() as u64;
                    holo.architecture
                        .edges
                        .first_mut()
                        .ok_or_else(|| prismpm::PrismError::new("PP9001", "fixture has no edge"))?
                        .from_index = count;
                } else if case.command == "holo-unresolved-risk" {
                    let count = holo.security.assets.len() as u64;
                    holo.security
                        .risks
                        .first_mut()
                        .ok_or_else(|| prismpm::PrismError::new("PP9001", "fixture has no risk"))?
                        .asset_index = count;
                } else if case.command == "holo-empty" {
                    holo.architecture.components.clear();
                    holo.architecture.edges.clear();
                    holo.architecture.stakeholders.clear();
                    holo.architecture.concerns.clear();
                    holo.architecture.viewpoints.clear();
                    holo.architecture.views.clear();
                    holo.security.assets.clear();
                    holo.security.threats.clear();
                    holo.security.risks.clear();
                    holo.security.controls.clear();
                    holo.security.activities.clear();
                    holo.security.measurements.clear();
                    holo.quality.characteristics.clear();
                    holo.quality.subcharacteristics.clear();
                    holo.quality.requirements.clear();
                    holo.quality.measures.clear();
                } else if case.command == "holo-minimal" {
                    holo.architecture.components.truncate(1);
                    holo.architecture.edges.truncate(1);
                    let edge =
                        holo.architecture.edges.first_mut().ok_or_else(|| {
                            prismpm::PrismError::new("PP9001", "fixture has no edge")
                        })?;
                    edge.from_index = 0;
                    edge.to_index = 0;
                    for asset in &mut holo.security.assets {
                        asset.component_index = 0;
                    }
                } else if case.command == "holo-duplicate-id" {
                    let first = holo
                        .architecture
                        .components
                        .first()
                        .ok_or_else(|| {
                            prismpm::PrismError::new("PP9001", "fixture has no component")
                        })?
                        .id
                        .clone();
                    holo.architecture
                        .components
                        .get_mut(1)
                        .ok_or_else(|| {
                            prismpm::PrismError::new("PP9001", "fixture has one component")
                        })?
                        .id = first;
                } else if case.command == "holo-bad-profile" {
                    holo.standards_profile.pop();
                }
                prismpm::holo::validate::validate(&holo)?;
                Ok(Vec::new())
            }),
        "snapshot-schema-mismatch" => controller
            .build(prismpm::controller::BuildRequest { config_path: None })
            .and_then(|result| {
                let build_root = temp_dir.path().join(".prism/build").join(result.build_id);
                let mut value: serde_json::Value = serde_json::from_slice(
                    &std::fs::read(build_root.join("lexlean/snapshot.json"))
                        .map_err(|error| prismpm::PrismError::new("PP4002", error.to_string()))?,
                )
                .map_err(|error| prismpm::PrismError::new("PP4004", error.to_string()))?;
                value["spec"] = serde_json::Value::String("lexlean/semantic-snapshot/0".to_owned());
                let bytes = prismpm::holo::canonical::encode_value(&value)?;
                prismpm::holo::projector::validate_snapshot_envelope(&bytes)?;
                Ok(Vec::new())
            }),
        "hidden-ir-audit" => {
            let root = repo_model::repo_root();
            let mut forbidden = None;
            for entry in walkdir::WalkDir::new(root.join("crates/prismpm/src"))
                .into_iter()
                .filter_map(Result::ok)
                .filter(|entry| entry.file_type().is_file())
            {
                let text = std::fs::read_to_string(entry.path()).unwrap_or_default();
                if text.contains("lexlean::ir") || text.contains("CheckedProject") {
                    forbidden = Some(entry.path().display().to_string());
                    break;
                }
            }
            match forbidden {
                Some(path) => Err(prismpm::PrismError::new(
                    "PP9001",
                    format!("hidden LexLean coupling in {path}"),
                )),
                None => Ok(Vec::new()),
            }
        }
        "stale-lock" => {
            let lock = temp_dir.path().join("lexlean.lock");
            let mut text = std::fs::read_to_string(&lock)?;
            let position = text
                .find("sha256 = \"")
                .map(|position| position + "sha256 = \"".len())
                .ok_or("fixture lock has no checksum")?;
            text.replace_range(position..=position, "0");
            std::fs::write(lock, text)?;
            controller
                .check(prismpm::controller::CheckRequest { config_path: None })
                .map(|_| Vec::new())
        }
        "artifact-tamper" => controller
            .build(prismpm::controller::BuildRequest { config_path: None })
            .and_then(|result| {
                std::fs::write(temp_dir.path().join(&result.model_path), b"tampered")
                    .map_err(|error| prismpm::PrismError::new("PP4002", error.to_string()))?;
                controller
                    .build(prismpm::controller::BuildRequest { config_path: None })
                    .map(|_| Vec::new())
            }),
        "path-escape" => {
            let config = temp_dir.path().join("prismpm.toml");
            let text = std::fs::read_to_string(&config)?
                .replace("build_root = \".prism\"", "build_root = \"../escape\"");
            std::fs::write(config, text)?;
            controller
                .check(prismpm::controller::CheckRequest { config_path: None })
                .map(|_| Vec::new())
        }
        "path-symlink" => {
            let config = temp_dir.path().join("prismpm.toml");
            let text = std::fs::read_to_string(&config)?
                .replace("build_root = \".prism\"", "build_root = \"out\"");
            std::fs::write(config, text)?;
            let outside = tempfile::tempdir()?;
            #[cfg(unix)]
            std::os::unix::fs::symlink(outside.path(), temp_dir.path().join("out"))?;
            #[cfg(not(unix))]
            return Err("path-symlink fixture is normative on Unix".into());
            controller
                .build(prismpm::controller::BuildRequest { config_path: None })
                .map(|_| Vec::new())
        }
        "max-limits" => {
            let first =
                controller.check(prismpm::controller::CheckRequest { config_path: None })?;
            let built =
                controller.build(prismpm::controller::BuildRequest { config_path: None })?;
            let holo_bytes = std::fs::metadata(temp_dir.path().join(built.model_path))?.len();
            let config = temp_dir.path().join("prismpm.toml");
            let text = std::fs::read_to_string(&config)?
                .replace(
                    "max_holo_bytes = 16777216",
                    &format!("max_holo_bytes = {holo_bytes}"),
                )
                .replace(
                    "max_entities = 100000",
                    &format!("max_entities = {}", first.entity_count),
                );
            std::fs::write(config, text)?;
            controller
                .check(prismpm::controller::CheckRequest { config_path: None })
                .map(|_| Vec::new())
        }
        "publication-race" => {
            let root = temp_dir.path().to_path_buf();
            let first_root = root.clone();
            let first = std::thread::spawn(move || {
                prismpm::Controller::load(first_root).and_then(|controller| {
                    controller.build(prismpm::controller::BuildRequest { config_path: None })
                })
            });
            let second = std::thread::spawn(move || {
                prismpm::Controller::load(root).and_then(|controller| {
                    controller.build(prismpm::controller::BuildRequest { config_path: None })
                })
            });
            let left = first
                .join()
                .map_err(|_| prismpm::PrismError::new("PP9001", "first build panicked"))??;
            let right = second
                .join()
                .map_err(|_| prismpm::PrismError::new("PP9001", "second build panicked"))??;
            if left.build_id != right.build_id {
                Err(prismpm::PrismError::new(
                    "PP4001",
                    "racing builds produced different IDs",
                ))
            } else {
                Ok(Vec::new())
            }
        }
        other => return Err(format!("{}: unsupported command {other}", dir.display()).into()),
    };
    let (exit, diagnostics, mut artifacts) = match outcome {
        Ok(artifacts) => (0_i32, Vec::new(), artifacts),
        Err(error) => {
            let mut row = diagnostic(&error);
            if case.command == "holo-noncanonical" && !row.notes.is_empty() {
                row.notes = vec!["canonical".to_owned()];
            }
            (i32::from(error.exit_code()), vec![row], Vec::new())
        }
    };
    artifacts.sort();
    if exit != case.expected_exit
        || diagnostics != case.expected_diagnostics
        || artifacts != case.expected_artifacts
    {
        return Err(format!(
            "{}: observed exit/diagnostics/artifacts differ from case.toml\nexit: {exit}\ndiagnostics: {diagnostics:?}\nartifacts: {artifacts:?}",
            dir.display()
        )
        .into());
    }
    if exit == 0 && !case.expected_diagnostics.is_empty() {
        return Err(format!("{}: successful case expects diagnostics", dir.display()).into());
    }
    if exit != 0 && case.expected_diagnostics.is_empty() {
        return Err(format!("{}: failing case has no exact diagnostic", dir.display()).into());
    }

    let expected_dir = dir.join("expected");
    if expected_dir.exists() {
        let expected_result = expected_dir.join("result.json");
        if !expected_result.is_file() {
            return Err(format!("{}: expected directory lacks result.json", dir.display()).into());
        }
        let value = serde_json::json!({
            "artifacts": artifacts,
            "diagnostics": case.expected_diagnostics.iter().map(|row| format!("{}: {}", row.code, row.message)).collect::<Vec<_>>(),
            "exit": exit,
            "schema": "prismpm/fixture-result/1"
        });
        let actual = prismpm::holo::canonical::encode_value(&value)?;
        if std::fs::read(&expected_result)? != actual {
            return Err(format!("{}: expected/result.json drifted", dir.display()).into());
        }
    }
    let artifact_golden = expected_dir.join("artifacts");
    let mut golden_paths = Vec::new();
    if artifact_golden.exists() {
        for entry in walkdir::WalkDir::new(&artifact_golden)
            .into_iter()
            .filter_map(Result::ok)
            .filter(|entry| entry.file_type().is_file())
        {
            golden_paths.push(
                entry
                    .path()
                    .strip_prefix(&artifact_golden)?
                    .to_string_lossy()
                    .replace('\\', "/"),
            );
        }
        golden_paths.sort();
    }
    if golden_paths != artifacts {
        return Err(format!(
            "{}: expected artifact byte tree differs from declared set\ngolden: {golden_paths:?}\ndeclared: {artifacts:?}",
            dir.display()
        )
        .into());
    }
    for relative in &artifacts {
        let observed = std::fs::read(temp_dir.path().join(relative))?;
        let expected = std::fs::read(artifact_golden.join(relative))?;
        if observed != expected {
            return Err(format!(
                "{}: platform-independent artifact bytes drifted: {relative}",
                dir.display()
            )
            .into());
        }
    }

    Ok(())
}

/// Write expected files for a fixture directory.
pub fn write(dir: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let expected_dir = dir.join("expected");
    if expected_dir.exists() {
        std::fs::remove_dir_all(&expected_dir)?;
    }
    std::fs::create_dir_all(&expected_dir)?;
    let case: Case = toml::from_str(&std::fs::read_to_string(dir.join("case.toml"))?)?;
    let value = serde_json::json!({
        "artifacts": case.expected_artifacts,
        "diagnostics": case.expected_diagnostics.iter().map(|row| format!("{}: {}", row.code, row.message)).collect::<Vec<_>>(),
        "exit": case.expected_exit,
        "schema": "prismpm/fixture-result/1"
    });
    std::fs::write(
        expected_dir.join("result.json"),
        prismpm::holo::canonical::encode_value(&value)?,
    )?;
    if !case.expected_artifacts.is_empty() {
        if case.command != "build" || case.expected_exit != 0 {
            return Err(format!(
                "{}: artifact byte goldens require a successful build command",
                dir.display()
            )
            .into());
        }
        let temp_dir = tempfile::tempdir()?;
        copy_dir_recursive(&dir.join("project"), temp_dir.path())?;
        let result = prismpm::Controller::load(temp_dir.path())?
            .build(prismpm::controller::BuildRequest { config_path: None })?;
        let build_root = temp_dir.path().join(".prism/build").join(result.build_id);
        let mut observed = walkdir::WalkDir::new(&build_root)
            .into_iter()
            .filter_map(Result::ok)
            .filter(|entry| entry.file_type().is_file())
            .map(|entry| {
                entry
                    .path()
                    .strip_prefix(temp_dir.path())
                    .expect("artifact remains in fixture project")
                    .to_string_lossy()
                    .replace('\\', "/")
            })
            .collect::<Vec<_>>();
        observed.sort();
        if observed != case.expected_artifacts {
            return Err(format!(
                "{}: declared artifact set is stale\nobserved: {observed:?}",
                dir.display()
            )
            .into());
        }
        let artifact_root = expected_dir.join("artifacts");
        for relative in observed {
            let destination = artifact_root.join(&relative);
            std::fs::create_dir_all(destination.parent().expect("artifact parent"))?;
            std::fs::copy(temp_dir.path().join(&relative), destination)?;
        }
    }
    Ok(())
}

fn copy_dir_recursive(from: &Path, to: &Path) -> Result<(), std::io::Error> {
    for entry in walkdir::WalkDir::new(from).into_iter().flatten() {
        let rel = entry.path().strip_prefix(from).unwrap();
        let target = to.join(rel);
        if entry.file_type().is_dir() {
            std::fs::create_dir_all(&target)?;
        } else if entry.file_type().is_file() {
            if let Some(parent) = target.parent() {
                std::fs::create_dir_all(parent)?;
            }
            std::fs::copy(entry.path(), &target)?;
        }
    }
    Ok(())
}
