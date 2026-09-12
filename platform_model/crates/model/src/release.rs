//! Release checks and criteria.

use std::path::Path;
use std::process::Command;

/// Host targets supported for binary distribution.
pub const HOST_TARGETS: &[&str] = &["aarch64-unknown-linux-gnu", "x86_64-unknown-linux-gnu"];

/// Validate release criteria for PrismPM.
pub fn check(root: &Path, hidden_tests: &[String]) -> Result<(), Vec<String>> {
    let mut issues = Vec::new();
    if !hidden_tests.is_empty() {
        issues.push(format!(
            "normative conformance tests are disabled or deferred: {}",
            hidden_tests.join(", ")
        ));
    }

    let head = Command::new("git")
        .args(["rev-parse", "HEAD"])
        .current_dir(root)
        .output()
        .ok()
        .filter(|output| output.status.success())
        .and_then(|output| String::from_utf8(output.stdout).ok())
        .map(|value| value.trim().to_owned());
    let Some(head) = head else {
        issues.push("source is not an exact Git commit".to_owned());
        return Err(issues);
    };
    if head.len() != 40 || !head.bytes().all(|byte| byte.is_ascii_hexdigit()) {
        issues.push("HEAD is not a full immutable commit identity".to_owned());
    }
    let dirty = Command::new("git")
        .args(["status", "--porcelain=v1", "--untracked-files=all"])
        .current_dir(root)
        .output()
        .ok()
        .filter(|output| output.status.success())
        .map(|output| !output.stdout.is_empty())
        .unwrap_or(true);
    if dirty {
        issues.push("release source tree is not clean".to_owned());
    }

    let dependencies =
        std::fs::read_to_string(root.join("model/dependencies.toml")).unwrap_or_default();
    for forbidden in ["pending", "placeholder", "../LexLean", "../lean4-prod"] {
        if dependencies.contains(forbidden) {
            issues.push(format!(
                "dependency register contains forbidden token `{forbidden}`"
            ));
        }
    }
    let changelog = std::fs::read_to_string(root.join("CHANGELOG.md")).unwrap_or_default();
    if !changelog.contains("## [0.3.0] - 2026-09-05") {
        issues.push("CHANGELOG.md has no dated 0.3.0 release entry".to_owned());
    }
    let cargo = std::fs::read_to_string(root.join("Cargo.toml")).unwrap_or_default();
    if !cargo.contains("version = \"0.3.0\"") {
        issues.push("workspace release version is not 0.3.0".to_owned());
    }
    if !changelog.contains("### Compatibility")
        || !changelog.contains("incompatible schema change requires a new schema")
    {
        issues.push("CHANGELOG.md has no current schema compatibility policy".to_owned());
    }
    let tag = Command::new("git")
        .args(["tag", "--points-at", &head])
        .current_dir(root)
        .output()
        .ok()
        .filter(|output| output.status.success())
        .and_then(|output| String::from_utf8(output.stdout).ok())
        .unwrap_or_default();
    if !tag.lines().any(|line| line == "v0.3.0") {
        issues.push("release source commit is not tagged v0.3.0".to_owned());
    }
    let annotated = Command::new("git")
        .args(["cat-file", "-t", "refs/tags/v0.3.0"])
        .current_dir(root)
        .output()
        .ok()
        .filter(|output| output.status.success())
        .and_then(|output| String::from_utf8(output.stdout).ok())
        .is_some_and(|kind| kind.trim() == "tag");
    if !annotated {
        issues.push("release tag v0.3.0 is absent or not annotated".to_owned());
    }

    match crate::Model::load(&root.join("model")) {
        Ok(model) => {
            if let Err(error) = model.check() {
                issues.push(format!("release model is invalid: {error}"));
            }
            for standard in model.standards.standard {
                if standard.release_scope && standard.coverage_state != "implemented" {
                    issues.push(format!(
                        "release standard {} is not implemented",
                        standard.id
                    ));
                }
            }
            for claim in model.ledger.claim {
                if claim.level == crate::Level::Open {
                    issues.push(format!(
                        "open measurement {} may not be release acceptance evidence",
                        claim.id
                    ));
                }
            }
        }
        Err(error) => issues.push(format!("release model cannot be loaded: {error}")),
    }

    let evidence_path = root.join("target/vv-evidence.json");
    match std::fs::read(&evidence_path)
        .ok()
        .and_then(|bytes| serde_json::from_slice::<serde_json::Value>(&bytes).ok())
    {
        Some(evidence)
            if evidence.get("schema").and_then(serde_json::Value::as_str)
                == Some("prismpm/vv-evidence/1")
                && evidence.get("status").and_then(serde_json::Value::as_str) == Some("passed")
                && evidence.get("commit").and_then(serde_json::Value::as_str)
                    == Some(head.as_str())
                && evidence
                    .get("gates")
                    .and_then(serde_json::Value::as_array)
                    .is_some_and(|gates| {
                        gates.len() == 15
                            && gates.iter().enumerate().all(|(index, gate)| {
                                gate.as_u64() == Some(u64::try_from(index + 1).unwrap_or(u64::MAX))
                            })
                    }) => {}
        _ => issues.push(format!(
            "full vv evidence for exact commit {head} is absent or incomplete"
        )),
    }

    if issues.is_empty() {
        Ok(())
    } else {
        Err(issues)
    }
}
