//! Repository gates and verification commands for PrismPM.

// Gate orchestration preserves the complete public PrismError before
// converting it into the repository's boxed failure type.
#![allow(clippy::result_large_err)]

use sha2::Digest;
use std::path::Path;
use std::process::{Command, ExitCode, Output};
use std::sync::OnceLock;

mod audit;
mod codegen;
mod spec_links;

/// General error type for xtask commands.
pub type Fail = Box<dyn std::error::Error>;

static BUILD: OnceLock<Result<prismpm::controller::BuildResult, String>> = OnceLock::new();
static VERIFY: OnceLock<Result<prismpm::controller::VerifyResult, String>> = OnceLock::new();

fn build_once(root: &Path) -> Result<&'static prismpm::controller::BuildResult, Fail> {
    BUILD
        .get_or_init(|| {
            prismpm::Controller::load(root)
                .and_then(|controller| {
                    controller.build(prismpm::controller::BuildRequest { config_path: None })
                })
                .map_err(|error| error.to_string())
        })
        .as_ref()
        .map_err(|error| error.clone().into())
}

fn verify_once(root: &Path) -> Result<&'static prismpm::controller::VerifyResult, Fail> {
    VERIFY
        .get_or_init(|| {
            prismpm::Controller::load(root)
                .and_then(|controller| {
                    controller.verify(prismpm::controller::VerifyRequest { config_path: None })
                })
                .map_err(|error| error.to_string())
        })
        .as_ref()
        .map_err(|error| error.clone().into())
}

fn main() -> ExitCode {
    let task = std::env::args().nth(1).unwrap_or_else(|| "help".to_owned());
    let write = std::env::args().any(|arg| arg == "--write");
    let root = repo_model::repo_root();

    let result = match task.as_str() {
        "validate-model" => codegen::check_model(&root, write),
        "validate-spec-links" => spec_links::validate(&root),
        "validate-contract" => validate_contract(),
        "verify-examples" => verify_examples(&root, write),
        "check-golden" => check_golden(&root, write),
        "check-reproducibility" => check_reproducibility(&root),
        "check-fixtures" => check_fixtures(&root, write),
        "package-api" => package_api_check(&root),
        "release-artifacts" => release_artifacts(&root),
        "release-check" => release_check(&root),
        "validate" => validate_all(&root, false),
        "vv" => run_vv(&root),
        _ => {
            eprintln!("Usage: cargo xtask <task>");
            return ExitCode::from(2);
        }
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("gate failed: {err}");
            ExitCode::FAILURE
        }
    }
}

fn validate_contract() -> Result<(), Fail> {
    let mut arguments = std::env::args().skip(2);
    let id = arguments
        .next()
        .ok_or("validate-contract requires a contract identifier")?;
    let path = arguments
        .next()
        .ok_or("validate-contract requires a document path")?;
    if arguments.next().is_some() {
        return Err("validate-contract accepts exactly two arguments".into());
    }
    let id: &'static str = match id.as_str() {
        "prismpm/bootstrap-evidence/1" => "prismpm/bootstrap-evidence/1",
        _ => return Err(format!("validate-contract does not expose {id}").into()),
    };
    let bytes = std::fs::read(&path)?;
    let document = prismpm::contracts::CanonicalDocument::parse(id, &bytes)?;
    println!("{} {}", document.schema(), document.digest());
    Ok(())
}

fn validate_all(root: &Path, write: bool) -> Result<(), Fail> {
    codegen::check_model(root, write)?;
    spec_links::validate(root)?;
    audit_all(root)
}

fn audit_all(root: &Path) -> Result<(), Fail> {
    audit::audit_no_handwritten_lean(root)?;
    audit::audit_formal_contract(root)?;
    audit::audit_no_unsafe(root)?;
    audit::audit_shipped(root)?;
    audit::audit_dependencies(root)?;
    audit::audit_tools_ci(root)?;
    let model = repo_model::Model::load_from_repo_root()?;
    audit::audit_errors(root, &model)?;
    audit::audit_emitter_inputs(root, &model)?;
    audit::audit_standards_map(root, &model)?;
    Ok(())
}

fn command(root: &Path, program: &str, args: &[&str]) -> Result<(), Fail> {
    let status = Command::new(program)
        .args(args)
        .current_dir(root)
        .env("CARGO_NET_OFFLINE", "true")
        .status()?;
    if !status.success() {
        return Err(format!("{program} {} exited {status}", args.join(" ")).into());
    }
    Ok(())
}

fn command_quiet_stdout(root: &Path, program: &str, args: &[&str]) -> Result<(), Fail> {
    let output = Command::new(program)
        .args(args)
        .current_dir(root)
        .env("CARGO_NET_OFFLINE", "true")
        .output()?;
    if !output.status.success() {
        return Err(format!(
            "{program} {} exited {}: {}",
            args.join(" "),
            output.status,
            String::from_utf8_lossy(&output.stderr).trim()
        )
        .into());
    }
    Ok(())
}

fn require_clean_worktree(root: &Path) -> Result<(), Fail> {
    let output = Command::new("git")
        .args(["status", "--porcelain=v1", "--untracked-files=all"])
        .current_dir(root)
        .output()?;
    if !output.status.success() {
        return Err(format!(
            "cannot inspect VV source worktree: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        )
        .into());
    }
    if !output.stdout.is_empty() {
        return Err(format!(
            "VV requires a clean source commit; worktree changes:\n{}",
            String::from_utf8_lossy(&output.stdout).trim_end()
        )
        .into());
    }
    Ok(())
}

fn docker_sdk_command(image: &str, extra: &[&str]) -> Result<Output, Fail> {
    let mut arguments = vec![
        "run",
        "--rm",
        "--network",
        "none",
        "--read-only",
        "--tmpfs",
        "/tmp:rw,noexec,nosuid,nodev",
        "--user",
        "1000:1000",
        "--cap-drop",
        "ALL",
        "--security-opt",
        "no-new-privileges",
    ];
    arguments.extend_from_slice(extra);
    arguments.extend_from_slice(&[
        "--entrypoint",
        "/usr/local/bin/prismpm",
        image,
        "--json",
        "completion",
        "bash",
    ]);
    Ok(Command::new("docker").args(arguments).output()?)
}

fn assert_sdk_inventory_rejection(output: &Output, mutation: &str) -> Result<(), Fail> {
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    if output.status.success()
        || !stdout.contains("\"schema\":\"prismpm/error-result/1\"")
        || !stdout.contains("\"code\":\"PP5401\"")
    {
        return Err(format!(
            "released SDK accepted {mutation}, or returned the wrong diagnostic: status={} stdout={} stderr={}",
            output.status,
            stdout.trim(),
            stderr.trim()
        )
        .into());
    }
    Ok(())
}

fn mutated_sdk_command(
    image: &str,
    environment: Option<&str>,
    source: &Path,
    target: &str,
) -> Result<Output, Fail> {
    let mut arguments = vec![
        "create",
        "--network",
        "none",
        "--user",
        "1000:1000",
        "--cap-drop",
        "ALL",
        "--security-opt",
        "no-new-privileges",
    ];
    if let Some(environment) = environment {
        arguments.extend_from_slice(&["--env", environment]);
    }
    arguments.extend_from_slice(&[
        "--entrypoint",
        "/usr/local/bin/prismpm",
        image,
        "--json",
        "completion",
        "bash",
    ]);
    let created = Command::new("docker").args(arguments).output()?;
    if !created.status.success() {
        return Err(format!(
            "cannot create SDK mutation container: {}",
            String::from_utf8_lossy(&created.stderr).trim()
        )
        .into());
    }
    let container = String::from_utf8(created.stdout)?.trim().to_owned();
    if container.len() != 64 || !container.bytes().all(|byte| byte.is_ascii_hexdigit()) {
        return Err("Docker returned a malformed mutation container ID".into());
    }
    let destination = format!("{container}:{target}");
    let copied = Command::new("docker")
        .arg("cp")
        .arg(source)
        .arg(&destination)
        .output()?;
    if !copied.status.success() {
        let _ = Command::new("docker")
            .args(["rm", "--force", &container])
            .output();
        return Err(format!(
            "cannot plant SDK mutation at {target}: {}",
            String::from_utf8_lossy(&copied.stderr).trim()
        )
        .into());
    }
    let output = Command::new("docker")
        .args(["start", "--attach", &container])
        .output();
    let removed = Command::new("docker")
        .args(["rm", "--force", &container])
        .output()?;
    if !removed.status.success() {
        return Err(format!(
            "cannot remove SDK mutation container: {}",
            String::from_utf8_lossy(&removed.stderr).trim()
        )
        .into());
    }
    Ok(output?)
}

fn check_sdk_runtime_boundary() -> Result<(), Fail> {
    let image = std::env::var("PRISMPM_TEST_SDK_IMAGE")
        .map_err(|_| "PRISMPM_TEST_SDK_IMAGE is required for the SDK runtime boundary gate")?;
    if !image.contains("@sha256:") {
        return Err("SDK runtime boundary requires a digest-qualified image".into());
    }

    let baseline = docker_sdk_command(&image, &[])?;
    if !baseline.status.success()
        || !String::from_utf8_lossy(&baseline.stdout)
            .contains("\"schema\":\"prismpm/completion-result/1\"")
    {
        return Err(format!(
            "released SDK failed its immutable inventory baseline: status={} stdout={} stderr={}",
            baseline.status,
            String::from_utf8_lossy(&baseline.stdout).trim(),
            String::from_utf8_lossy(&baseline.stderr).trim()
        )
        .into());
    }

    let override_attempt = docker_sdk_command(
        &image,
        &[
            "--env",
            "PRISMPM_SDK_INVENTORY=/tmp/attacker-inventory.json",
        ],
    )?;
    if !override_attempt.status.success() || override_attempt.stdout != baseline.stdout {
        return Err(format!(
            "caller-controlled inventory environment changed released SDK behavior: status={} stdout={} stderr={}",
            override_attempt.status,
            String::from_utf8_lossy(&override_attempt.stdout).trim(),
            String::from_utf8_lossy(&override_attempt.stderr).trim()
        )
        .into());
    }

    let planted = tempfile::tempdir()?;
    let planted_command = planted.path().join("undeclared-sdk-command");
    std::fs::write(&planted_command, b"#!/bin/sh\nexit 0\n")?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(&planted_command, std::fs::Permissions::from_mode(0o755))?;
    }
    let injected = mutated_sdk_command(
        &image,
        Some("PATH=/planted:/usr/local/elan/bin:/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin"),
        planted.path(),
        "/planted",
    )?;
    assert_sdk_inventory_rejection(&injected, "an undeclared executable on PATH")?;

    let tampered = tempfile::NamedTempFile::new()?;
    std::fs::write(tampered.path(), b"#!/bin/sh\nexit 0\n")?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(tampered.path(), std::fs::Permissions::from_mode(0o755))?;
    }
    let changed = mutated_sdk_command(&image, None, tampered.path(), "/usr/local/bin/just")?;
    assert_sdk_inventory_rejection(&changed, "a changed declared executable")?;

    println!(
        "SDK runtime boundary: immutable inventory accepted the exact image and rejected environment override, PATH injection, and executable tampering"
    );
    Ok(())
}

fn run_vv(root: &Path) -> Result<(), Fail> {
    // Evidence is a result of this run, never an input to it.  Removing a
    // prior ignored record makes the gate repeatable and prevents a stale
    // success marker from changing the outcome of negative release tests.
    match std::fs::remove_file(root.join("target/vv-evidence.json")) {
        Ok(()) => {}
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
        Err(error) => return Err(format!("cannot invalidate prior vv evidence: {error}").into()),
    }
    require_clean_worktree(root)?;

    println!("VV gate 1/15: formatting");
    command(root, "cargo", &["fmt", "--all", "--", "--check"])?;

    println!("VV gate 2/15: model, diagnostics, standards, and generated documentation");
    codegen::check_model(root, false)?;

    println!("VV gate 3/15: SPEC/register/scenario/test links");
    spec_links::validate(root)?;

    println!("VV gate 4/15: source, error, unsafe, dependency, and generated-file audits");
    command_quiet_stdout(
        root,
        "cargo",
        &["metadata", "--locked", "--offline", "--format-version", "1"],
    )?;
    audit_all(root)?;
    command(root, "bash", &["scripts/bootstrap-verify.sh"])?;
    check_sdk_runtime_boundary()?;

    println!("VV gate 5/15: Clippy with warnings denied");
    command(
        root,
        "cargo",
        &[
            "clippy",
            "--workspace",
            "--all-targets",
            "--all-features",
            "--locked",
            "--offline",
            "--",
            "-D",
            "warnings",
        ],
    )?;

    println!("VV gate 6/15: workspace unit and property tests");
    command(
        root,
        "cargo",
        &[
            "test",
            "--workspace",
            "--all-features",
            "--locked",
            "--offline",
        ],
    )?;

    println!("VV gate 7/15: feature, conformance, and negative fixtures");
    check_fixtures(root, false)?;

    println!("VV gate 8/15: generated Lean build, replay, axiom audit, and source audit");
    verify_examples(root, false)?;
    audit::audit_no_handwritten_lean(root)?;

    println!("VV gate 9/15: LexLean format/lock and Prism check/build/verify");
    for operation in [["fmt", "--check"], ["lock", "--check"]] {
        command(
            root,
            "cargo",
            &[
                "run",
                "--locked",
                "--offline",
                "--target-dir",
                "target/vendor-lexlean",
                "--manifest-path",
                "vendor/lexlean/Cargo.toml",
                "--",
                "--project",
                "lexlean.toml",
                operation[0],
                operation[1],
            ],
        )?;
    }
    let controller = prismpm::Controller::load(root)?;
    controller.check(prismpm::controller::CheckRequest { config_path: None })?;
    let _ = build_once(root)?;
    let _ = verify_once(root)?;

    println!("VV gate 10/15: Holo schema and reviewed golden bytes");
    check_golden(root, false)?;

    println!("VV gate 11/15: named export, coverage, Rust compilation, and execution evidence");
    check_verified_evidence(root)?;

    println!("VV gate 12/15: two-absolute-directory reproducibility");
    check_reproducibility(root)?;

    println!("VV gate 13/15: authoritative upstream corpora, registry, and runtime conformance");
    let upstream = prismpm::upstream_conformance::verify(root)?;
    println!(
        "upstream conformance: JSON Schema +{}/-{}, Unicode {}, OCI Runtime +{}/-{}, OCI Distribution {}/{}",
        upstream.json_schema.positive,
        upstream.json_schema.negative,
        upstream.unicode.positive,
        upstream.oci_runtime.positive,
        upstream.oci_runtime.negative,
        upstream.oci_distribution.passed,
        upstream.oci_distribution.failed
    );

    println!("VV gate 14/15: dependency policy");
    command(
        root,
        "cargo",
        &["deny", "--frozen", "--all-features", "check"],
    )?;

    println!("VV gate 15/15: packaged crate and downstream public API");
    package_api_check(root)?;

    require_clean_worktree(root)?;

    let commit = Command::new("git")
        .args(["rev-parse", "HEAD"])
        .current_dir(root)
        .output()?;
    if !commit.status.success() {
        return Err("cannot identify vv source commit".into());
    }
    let commit = String::from_utf8(commit.stdout)?.trim().to_owned();
    let evidence = serde_json::json!({
        "commit": commit,
        "gates": (1_u8..=15).collect::<Vec<_>>(),
        "schema": "prismpm/vv-evidence/1",
        "status": "passed"
    });
    std::fs::create_dir_all(root.join("target"))?;
    std::fs::write(
        root.join("target/vv-evidence.json"),
        prismpm::holo::canonical::encode_value(&evidence)?,
    )?;
    println!("All 15 VV gates PASSED for commit {commit}.");
    Ok(())
}

fn verify_examples(root: &Path, _write: bool) -> Result<(), Fail> {
    let controller = prismpm::Controller::load(root)?;
    let check_res = controller.check(prismpm::controller::CheckRequest { config_path: None })?;
    println!(
        "verify-examples: checked model document {}",
        check_res.model_id
    );
    let verify_res = verify_once(root)?;
    println!(
        "verify-examples: verified attestation {}",
        verify_res.attestation_id
    );

    let calculator_root = root.join("examples/Calculator");
    let calculator = prismpm::Controller::load(&calculator_root)?;
    let calculator_check =
        calculator.check(prismpm::controller::CheckRequest { config_path: None })?;
    let first = calculator.build(prismpm::controller::BuildRequest { config_path: None })?;
    let second = calculator.build(prismpm::controller::BuildRequest { config_path: None })?;
    if first.build_id != second.build_id {
        return Err("Calculator build identity changed between consecutive builds".into());
    }
    let first_verify =
        calculator.verify(prismpm::controller::VerifyRequest { config_path: None })?;
    let second_verify =
        calculator.verify(prismpm::controller::VerifyRequest { config_path: None })?;
    if first_verify.attestation_id != second_verify.attestation_id {
        return Err("Calculator verification identity changed between consecutive runs".into());
    }
    println!(
        "verify-examples: Calculator model {} reproduced build {} and verified attestation {}",
        calculator_check.model_id, first.build_id, first_verify.attestation_id
    );
    Ok(())
}

fn tree_files(root: &Path) -> Result<Vec<(String, Vec<u8>)>, Fail> {
    let mut files = Vec::new();
    for entry in walkdir::WalkDir::new(root) {
        let entry = entry?;
        if entry.file_type().is_symlink() {
            return Err(format!("golden input contains symlink {}", entry.path().display()).into());
        }
        if entry.file_type().is_file() {
            files.push((
                entry
                    .path()
                    .strip_prefix(root)?
                    .to_string_lossy()
                    .replace('\\', "/"),
                std::fs::read(entry.path())?,
            ));
        }
    }
    files.sort_by(|a, b| a.0.as_bytes().cmp(b.0.as_bytes()));
    Ok(files)
}

fn golden_files(root: &Path, review_reason: &str) -> Result<Vec<(String, Vec<u8>)>, Fail> {
    let build_res = build_once(root)?;
    let verify_res = verify_once(root)?;
    if verify_res.build_id != build_res.build_id {
        return Err("golden build and verification IDs differ".into());
    }
    let build_root = root.join(".prism/build").join(&build_res.build_id);
    let verified_root = root
        .join(".prism/verified")
        .join(&verify_res.attestation_id);
    let mut files = Vec::new();
    for (relative, bytes) in tree_files(&root.join("stdlib/src"))? {
        if relative.ends_with(".lex.tex") {
            files.push((format!("source/{relative}"), bytes));
        }
    }
    for (relative, bytes) in tree_files(&build_root)? {
        files.push((format!("build/{relative}"), bytes));
    }
    for (relative, bytes) in tree_files(&verified_root)? {
        if !matches!(relative.as_str(), "generated.rs" | "kernel.ir") {
            files.push((format!("verified/{relative}"), bytes));
        }
    }
    files.sort_by(|a, b| a.0.as_bytes().cmp(b.0.as_bytes()));

    let model: serde_json::Value =
        serde_json::from_slice(&std::fs::read(build_root.join("model.prism.json"))?)?;
    let compiler_semantics_id = model
        .pointer("/provenance/compiler_semantics_id")
        .and_then(serde_json::Value::as_str)
        .ok_or("golden model-document compiler semantics ID is absent")?;
    let rows = files
        .iter()
        .map(|(path, bytes)| {
            serde_json::json!({
                "byte_length": bytes.len(),
                "path": path,
                "sha256": format!("{:x}", sha2::Sha256::digest(bytes))
            })
        })
        .collect::<Vec<_>>();
    let sources = rows
        .iter()
        .filter(|row| {
            row.get("path")
                .and_then(serde_json::Value::as_str)
                .is_some_and(|path| path.starts_with("source/"))
        })
        .cloned()
        .collect::<Vec<_>>();
    let source_hashes = sources
        .iter()
        .filter_map(|row| {
            Some((
                row.get("path")?.as_str()?.to_owned(),
                row.get("sha256")?.as_str()?.to_owned(),
            ))
        })
        .collect::<std::collections::BTreeMap<_, _>>();
    let generated_lean = rows
        .iter()
        .filter(|row| {
            row.get("path")
                .and_then(serde_json::Value::as_str)
                .is_some_and(|path| path.starts_with("build/") && path.ends_with(".lean"))
        })
        .map(|row| {
            let path = row
                .get("path")
                .and_then(serde_json::Value::as_str)
                .expect("filtered golden path is a string");
            let logical = path
                .strip_prefix("build/lexlean/build/modules/PrismPM/")
                .and_then(|path| path.strip_suffix(".lean"))
                .ok_or_else(|| format!("unexpected generated Lean golden path {path}"))?;
            let source_path = format!("source/{logical}.lex.tex");
            let source_sha256 = source_hashes.get(&source_path).ok_or_else(|| {
                format!("generated Lean golden {path} has no source {source_path}")
            })?;
            Ok(serde_json::json!({
                "byte_length": row.get("byte_length"),
                "path": path,
                "sha256": row.get("sha256"),
                "source_path": source_path,
                "source_sha256": source_sha256
            }))
        })
        .collect::<Result<Vec<_>, Fail>>()?;
    let manifest = serde_json::json!({
        "attestation_id": verify_res.attestation_id,
        "build_id": build_res.build_id,
        "compiler_semantics_id": compiler_semantics_id,
        "files": rows,
        "generated_lean": generated_lean,
        "review_reason": review_reason,
        "schema": "prismpm/golden-manifest/1",
        "sources": sources
    });
    files.push((
        "golden-manifest.json".to_owned(),
        prismpm::holo::canonical::encode_value(&manifest)?,
    ));
    files.sort_by(|a, b| a.0.as_bytes().cmp(b.0.as_bytes()));
    Ok(files)
}

fn check_golden(root: &Path, write: bool) -> Result<(), Fail> {
    let destination = root.join("tests/golden/stdlib");
    let review_reason = if write {
        std::env::var("PRISMPM_GOLDEN_REASON")
            .map_err(|_| "golden rewrite requires nonempty PRISMPM_GOLDEN_REASON")?
    } else {
        let value: serde_json::Value = serde_json::from_slice(
            &std::fs::read(destination.join("golden-manifest.json")).map_err(|error| {
                format!("golden manifest is absent: {error}; use just golden-write with a review reason")
            })?,
        )?;
        value
            .get("review_reason")
            .and_then(serde_json::Value::as_str)
            .filter(|reason| !reason.trim().is_empty())
            .ok_or("golden review reason is absent")?
            .to_owned()
    };
    if review_reason.trim().is_empty() {
        return Err("golden review reason may not be empty".into());
    }
    let expected = golden_files(root, &review_reason)?;
    if write {
        let parent = destination
            .parent()
            .ok_or("golden destination has no parent")?;
        std::fs::create_dir_all(parent)?;
        let staging = tempfile::Builder::new()
            .prefix("stdlib-golden-")
            .tempdir_in(parent)?;
        for (relative, bytes) in &expected {
            let path = staging.path().join(relative);
            if let Some(directory) = path.parent() {
                std::fs::create_dir_all(directory)?;
            }
            std::fs::write(path, bytes)?;
        }
        if destination.exists() {
            std::fs::remove_dir_all(&destination)?;
        }
        std::fs::rename(staging.keep(), &destination)?;
        println!(
            "check-golden: wrote {} reviewed files for build {}",
            expected.len(),
            build_once(root)?.build_id
        );
        return Ok(());
    }
    let observed = tree_files(&destination)?;
    if observed != expected {
        return Err("golden artifact tree drifted; use just golden-write with a review reason and review the exact diff".into());
    }
    println!(
        "check-golden: {} files match reviewed build {}",
        observed.len(),
        build_once(root)?.build_id
    );
    Ok(())
}

fn check_verified_evidence(root: &Path) -> Result<(), Fail> {
    let verified = verify_once(root)?;
    let repeated = prismpm::Controller::load(root)?
        .verify(prismpm::controller::VerifyRequest { config_path: None })?;
    if repeated.attestation_id != verified.attestation_id || repeated.build_id != verified.build_id
    {
        return Err("repeated fixed-seed verification produced a different identity".into());
    }
    let directory = root.join(".prism/verified").join(&verified.attestation_id);
    let manifest: serde_json::Value =
        serde_json::from_slice(&std::fs::read(directory.join("manifest.json"))?)?;
    if manifest.get("schema").and_then(serde_json::Value::as_str)
        != Some("prismpm/verification-manifest/1")
        || manifest
            .pointer("/execution/status")
            .and_then(serde_json::Value::as_str)
            != Some("passed")
        || manifest
            .pointer("/execution/no_allocation")
            .and_then(serde_json::Value::as_bool)
            != Some(true)
        || manifest
            .pointer("/execution/no_panic")
            .and_then(serde_json::Value::as_bool)
            != Some(true)
    {
        return Err("verification manifest does not contain passing execution evidence".into());
    }
    for artifact in [
        "coverage",
        "executable",
        "generated_rust",
        "kernel_ir",
        "lexlean_attestation",
        "model",
        "execution_corpus",
        "execution_evidence",
        "roots",
    ] {
        if manifest
            .pointer(&format!("/artifacts/{artifact}/sha256"))
            .is_none()
        {
            return Err(format!("verification manifest lacks artifact {artifact}").into());
        }
    }
    let coverage: serde_json::Value =
        serde_json::from_slice(&std::fs::read(directory.join("coverage.json"))?)?;
    for rejected in ["opaque_nodes", "external_calls", "unsupported_types"] {
        if !coverage
            .get(rejected)
            .and_then(serde_json::Value::as_array)
            .is_some_and(Vec::is_empty)
        {
            return Err(format!("verification coverage contains {rejected}").into());
        }
    }
    println!(
        "check-verified-evidence: named closure and execution evidence are complete for {}",
        verified.attestation_id
    );
    Ok(())
}

fn package_api_check(root: &Path) -> Result<(), Fail> {
    let selection = Command::new("cargo")
        .args(["package", "--package", "prismpm", "--list"])
        .current_dir(root)
        .env("CARGO_NET_OFFLINE", "true")
        .output()?;
    if !selection.status.success() {
        return Err(format!(
            "cargo package selection failed: {}",
            String::from_utf8_lossy(&selection.stderr)
        )
        .into());
    }
    let temp = tempfile::tempdir()?;
    let packaged = temp
        .path()
        .join(format!("prismpm-{}", env!("CARGO_PKG_VERSION")));
    std::fs::create_dir(&packaged)?;
    let crate_root = root.join("crates/prismpm");
    for relative in String::from_utf8(selection.stdout)?.lines() {
        if matches!(
            relative,
            ".cargo_vcs_info.json" | "Cargo.lock" | "Cargo.toml" | "Cargo.toml.orig"
        ) {
            continue;
        }
        let source = crate_root.join(relative);
        let destination = packaged.join(relative);
        if let Some(parent) = destination.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::copy(&source, &destination).map_err(|error| {
            format!(
                "copying selected package file {}: {error}",
                source.display()
            )
        })?;
    }
    std::fs::write(
        packaged.join("Cargo.toml"),
        r#"[package]
name = "prismpm"
version = "0.3.0"
edition = "2021"
rust-version = "1.97"
license = "MIT OR Apache-2.0"
description = "Prism Platform Model Framework"
readme = "README.md"

[dependencies]
camino = "1.2"
clap = { version = "4.5", features = ["derive"] }
fs4 = { version = "0.13", features = ["sync"] }
hologram = { package = "uor-hologram", version = "0.12.1", git = "https://github.com/Hologram-Technologies/hologram", rev = "2bda6a9a9476872dade705bd61ece4209607f6da", default-features = false, features = ["archive", "space"] }
lexlean = "0.3.0"
prod-codegen = "0.1.0"
prod-ir = "0.1.0"
same-file = "1.0"
semver = "1.0"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sha2 = "0.10"
tempfile = "3"
tar = "0.4"
toml = "0.8"
unicode-normalization = "0.1"
walkdir = "2"

[lints.rust]
missing_docs = "deny"
unsafe_op_in_unsafe_fn = "deny"

[lints.clippy]
undocumented_unsafe_blocks = "deny"
missing_safety_doc = "deny"
"#,
    )?;
    for required in [
        "CHANGELOG.md",
        "CONFORMANCE.md",
        "ERRORS.md",
        "LICENSE-APACHE",
        "LICENSE-MIT",
        "README.md",
        "SPEC.md",
        "language/prism.arch/lexicon.toml",
        "model/dependencies.toml",
        "schemas/model-document.schema.json",
        "src/prod_alloc_counter.rs.inc",
        "stdlib/src/Foundation/Holo.lex.tex",
        "vendor/lean4-prod/lean.tar",
    ] {
        if !packaged.join(required).is_file() {
            return Err(format!("packaged crate omits {required}").into());
        }
    }
    for entry in walkdir::WalkDir::new(&packaged) {
        let entry = entry?;
        let relative = entry.path().strip_prefix(&packaged)?.to_string_lossy();
        if relative.ends_with("lakefile.lean")
            || (relative.ends_with(".lean") && !relative.contains("tests/golden/stdlib/"))
            || relative.contains("/.lake/")
            || relative.contains("/.prism/")
            || relative.contains("/.lexlean/")
        {
            return Err(format!("packaged crate contains forbidden path {relative}").into());
        }
    }

    let downstream = temp.path().join("downstream");
    std::fs::create_dir(&downstream)?;
    let cargo_toml = format!(
        "[package]\nname = \"prismpm-downstream\"\nversion = \"0.0.0\"\nedition = \"2021\"\n\n[dependencies]\nprismpm = {{ path = {:?} }}\n\n[patch.crates-io]\nlexlean = {{ path = {:?} }}\nprod-codegen = {{ path = {:?} }}\nprod-ir = {{ path = {:?} }}\n",
        packaged,
        root.join("vendor/lexlean"),
        root.join("vendor/lean4-prod/rust/prod-codegen"),
        root.join("vendor/lean4-prod/rust/prod-ir"),
    );
    std::fs::write(downstream.join("Cargo.toml"), cargo_toml)?;
    std::fs::create_dir(downstream.join("src"))?;
    std::fs::write(
        downstream.join("src/main.rs"),
        "use prismpm::{controller::CheckRequest, Controller};\nfn main() { let _ = Controller::load(\".\"); let _ = CheckRequest { config_path: None }; }\n",
    )?;
    command(&downstream, "cargo", &["check", "--offline"])?;
    let package_files = tree_files(&packaged)?;
    let mut package_hasher = sha2::Sha256::new();
    for (path, bytes) in package_files {
        package_hasher.update((path.len() as u64).to_be_bytes());
        package_hasher.update(path.as_bytes());
        package_hasher.update((bytes.len() as u64).to_be_bytes());
        package_hasher.update(bytes);
    }
    println!(
        "package-api: Cargo-selected package assets and downstream public API compile (tree sha256 {:x})",
        package_hasher.finalize()
    );
    command(
        root,
        "sh",
        &["scripts/package-release-crates.sh", "--check"],
    )?;
    Ok(())
}

fn check_reproducibility(root: &Path) -> Result<(), Fail> {
    let temp1 = tempfile::tempdir()?;
    let temp2 = tempfile::tempdir()?;

    copy_dir_recursive(&root.join("stdlib"), &temp1.path().join("stdlib"))?;
    copy_dir_recursive(&root.join("language"), &temp1.path().join("language"))?;
    copy_dir_recursive(&root.join("schemas"), &temp1.path().join("schemas"))?;
    for file in [
        "lake-manifest.json",
        "lakefile.toml",
        "lean-toolchain",
        "lexlean.lock",
        "lexlean.toml",
        "prismpm.toml",
    ] {
        std::fs::copy(root.join(file), temp1.path().join(file))?;
    }
    std::fs::create_dir_all(temp1.path().join("vendor/lean4-prod"))?;
    std::fs::copy(
        root.join("vendor/lean4-prod/lean.tar"),
        temp1.path().join("vendor/lean4-prod/lean.tar"),
    )?;

    copy_dir_recursive(&root.join("stdlib"), &temp2.path().join("stdlib"))?;
    copy_dir_recursive(&root.join("language"), &temp2.path().join("language"))?;
    copy_dir_recursive(&root.join("schemas"), &temp2.path().join("schemas"))?;
    for file in [
        "lake-manifest.json",
        "lakefile.toml",
        "lean-toolchain",
        "lexlean.lock",
        "lexlean.toml",
        "prismpm.toml",
    ] {
        std::fs::copy(root.join(file), temp2.path().join(file))?;
    }
    std::fs::create_dir_all(temp2.path().join("vendor/lean4-prod"))?;
    std::fs::copy(
        root.join("vendor/lean4-prod/lean.tar"),
        temp2.path().join("vendor/lean4-prod/lean.tar"),
    )?;

    let c1 = prismpm::Controller::load(temp1.path())?;
    let c2 = prismpm::Controller::load(temp2.path())?;

    let b1 = c1.build(prismpm::controller::BuildRequest { config_path: None })?;
    let b2 = c2.build(prismpm::controller::BuildRequest { config_path: None })?;

    if b1.build_id != b2.build_id {
        return Err(format!(
            "check-reproducibility: build IDs differ across directories: {} vs {}",
            b1.build_id, b2.build_id
        )
        .into());
    }
    let files1 = tree_files(&temp1.path().join(".prism/build").join(&b1.build_id))?;
    let files2 = tree_files(&temp2.path().join(".prism/build").join(&b2.build_id))?;
    if files1 != files2 {
        return Err("check-reproducibility: platform-independent artifact trees differ".into());
    }
    for (_, bytes) in &files1 {
        let text = String::from_utf8_lossy(bytes);
        if text.contains(temp1.path().to_string_lossy().as_ref())
            || text.contains(temp2.path().to_string_lossy().as_ref())
        {
            return Err("check-reproducibility: artifact embeds an absolute checkout path".into());
        }
    }

    let v1 = c1.verify(prismpm::controller::VerifyRequest { config_path: None })?;
    let v2 = c2.verify(prismpm::controller::VerifyRequest { config_path: None })?;
    if v1.attestation_id != v2.attestation_id {
        return Err(format!(
            "check-reproducibility: verification IDs differ across directories: {} vs {}",
            v1.attestation_id, v2.attestation_id
        )
        .into());
    }
    let verified1 = tree_files(
        &temp1
            .path()
            .join(".prism/verified")
            .join(&v1.attestation_id),
    )?;
    let verified2 = tree_files(
        &temp2
            .path()
            .join(".prism/verified")
            .join(&v2.attestation_id),
    )?;
    if verified1 != verified2 {
        return Err("check-reproducibility: platform-independent verification trees differ".into());
    }

    println!(
        "check-reproducibility: {} build and {} verification artifacts are byte-identical across distinct roots: {} / {}",
        files1.len(), verified1.len(), b1.build_id, v1.attestation_id
    );
    Ok(())
}

fn check_fixtures(root: &Path, write: bool) -> Result<(), Fail> {
    let fixtures = repo_conformance::fixtures::discover(root);
    if fixtures.is_empty() {
        return Err(
            "check-fixtures: no fixture directories discovered; the fixture gate is unarmed".into(),
        );
    }
    for fixture in &fixtures {
        if write {
            repo_conformance::fixtures::write(fixture)?;
        } else {
            repo_conformance::fixtures::check(fixture)?;
        }
    }
    println!("check-fixtures: {} fixtures checked", fixtures.len());
    Ok(())
}

fn release_artifacts(root: &Path) -> Result<(), Fail> {
    release_check(root)?;
    let first = tempfile::tempdir()?;
    let second = tempfile::tempdir()?;
    assemble_release(root, first.path())?;
    assemble_release(root, second.path())?;
    let expected = tree_files(first.path())?;
    if expected != tree_files(second.path())? {
        return Err("release artifacts do not reproduce byte-for-byte".into());
    }

    let release_dir = root.join("release");
    if release_dir.exists() {
        std::fs::remove_dir_all(&release_dir)?;
    }
    std::fs::create_dir(&release_dir)?;
    for (relative, bytes) in &expected {
        let destination = release_dir.join(relative);
        if let Some(parent) = destination.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(destination, bytes)?;
    }
    println!(
        "release-artifacts: {} reproducible files staged under release/",
        expected.len()
    );
    Ok(())
}

fn assemble_release(root: &Path, destination: &Path) -> Result<(), Fail> {
    let head = String::from_utf8(
        Command::new("git")
            .args(["rev-parse", "HEAD"])
            .current_dir(root)
            .output()?
            .stdout,
    )?
    .trim()
    .to_owned();
    let archive = Command::new("git")
        .args(["archive", "--format=tar", "--prefix=PrismPM-0.3.0/", "HEAD"])
        .current_dir(root)
        .output()?;
    if !archive.status.success() {
        return Err(format!(
            "git archive failed: {}",
            String::from_utf8_lossy(&archive.stderr)
        )
        .into());
    }
    let source_name = "PrismPM-0.3.0-source.tar";
    std::fs::write(destination.join(source_name), archive.stdout)?;

    let metadata = Command::new("cargo")
        .args(["metadata", "--locked", "--offline", "--format-version", "1"])
        .current_dir(root)
        .output()?;
    if !metadata.status.success() {
        return Err(format!(
            "cargo metadata for SBOM failed: {}",
            String::from_utf8_lossy(&metadata.stderr)
        )
        .into());
    }
    let metadata: serde_json::Value = serde_json::from_slice(&metadata.stdout)?;
    let mut components = metadata
        .get("packages")
        .and_then(serde_json::Value::as_array)
        .ok_or("cargo metadata package array is absent")?
        .iter()
        .map(|package| {
            serde_json::json!({
                "license": package.get("license").cloned().unwrap_or(serde_json::Value::Null),
                "name": package.get("name").cloned().unwrap_or(serde_json::Value::Null),
                "source": package.get("source").cloned().unwrap_or(serde_json::Value::Null),
                "version": package.get("version").cloned().unwrap_or(serde_json::Value::Null)
            })
        })
        .collect::<Vec<_>>();
    components.sort_by(|left, right| {
        left.get("name")
            .and_then(serde_json::Value::as_str)
            .unwrap_or("")
            .cmp(
                right
                    .get("name")
                    .and_then(serde_json::Value::as_str)
                    .unwrap_or(""),
            )
            .then_with(|| {
                left.get("version")
                    .and_then(serde_json::Value::as_str)
                    .unwrap_or("")
                    .cmp(
                        right
                            .get("version")
                            .and_then(serde_json::Value::as_str)
                            .unwrap_or(""),
                    )
            })
            .then_with(|| {
                left.get("source")
                    .and_then(serde_json::Value::as_str)
                    .unwrap_or("")
                    .cmp(
                        right
                            .get("source")
                            .and_then(serde_json::Value::as_str)
                            .unwrap_or(""),
                    )
            })
    });
    let sbom = serde_json::json!({
        "components": components,
        "source_commit": head,
        "spec": "prismpm/sbom/1",
        "version": "0.3.0"
    });
    let mut sbom_bytes = prismpm::holo::canonical::encode_value(&sbom)?;
    sbom_bytes.push(b'\n');
    let sbom_name = "PrismPM-0.3.0-sbom.json";
    std::fs::write(destination.join(sbom_name), &sbom_bytes)?;

    let artifact_rows = [
        (
            source_name,
            format!(
                "{:x}",
                sha2::Sha256::digest(std::fs::read(destination.join(source_name))?)
            ),
        ),
        (
            sbom_name,
            format!("{:x}", sha2::Sha256::digest(&sbom_bytes)),
        ),
    ];
    let manifest = serde_json::json!({
        "artifacts": artifact_rows.iter().map(|(path, sha256)| serde_json::json!({"path": path, "sha256": sha256})).collect::<Vec<_>>(),
        "commit": head,
        "schema": "prismpm/release-manifest/1",
        "version": "0.3.0"
    });
    let mut manifest_bytes = prismpm::holo::canonical::encode_value(&manifest)?;
    manifest_bytes.push(b'\n');
    let manifest_name = "RELEASE.json";
    std::fs::write(destination.join(manifest_name), &manifest_bytes)?;

    let mut checksums = artifact_rows
        .iter()
        .map(|(path, sha256)| format!("{sha256}  {path}\n"))
        .collect::<String>();
    checksums.push_str(&format!(
        "{:x}  {manifest_name}\n",
        sha2::Sha256::digest(&manifest_bytes)
    ));
    std::fs::write(destination.join("SHA256SUMS"), checksums)?;
    Ok(())
}

fn release_check(root: &Path) -> Result<(), Fail> {
    let (_, hidden_tests) = repo_conformance::workspace_test_names_with_flags(root);
    let hidden_vec: Vec<String> = hidden_tests.into_iter().collect();
    let unmet = repo_model::release::check(root, &hidden_vec);
    if let Err(issues) = unmet {
        return Err(format!(
            "release-check refused: unmet criteria:\n  {}",
            issues.join("\n  ")
        )
        .into());
    }
    println!("release-check: all release criteria hold");
    Ok(())
}

fn copy_dir_recursive(from: &Path, to: &Path) -> Result<(), std::io::Error> {
    if !from.exists() {
        return Ok(());
    }
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
