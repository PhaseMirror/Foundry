//! The honesty meta-gate: a mechanical proof that the suite stays honest.
//!
//! It cross-checks the model against the feature files on disk and enforces status
//! discipline — mirroring F1's `scripts/honesty_audit.sh`, promoted to a typed invariant.

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;
use tqc_model::{Model, Tier};

/// A summary of a passing audit.
#[derive(Debug, Clone, Copy)]
pub struct AuditReport {
    /// Total dictionary rows.
    pub rows_total: usize,
    /// Gating, green suite rows.
    pub suites: usize,
    /// Expected-RED, non-gating target rows.
    pub targets: usize,
    /// Feature files discovered on disk.
    pub features_on_disk: usize,
}

/// Run the full honesty audit against a workspace rooted at `root`.
///
/// # Errors
/// Returns a description of the first violation found.
pub fn audit(model: &Model, root: &Path) -> Result<AuditReport, String> {
    let mut referenced = BTreeSet::new();

    for row in &model.rows {
        let rel = normalize(&row.feature);
        let path = root.join(&rel);
        if !path.is_file() {
            return Err(format!("row `{}`: feature file missing: {rel}", row.id));
        }
        let text = fs::read_to_string(&path).map_err(|e| format!("read {rel}: {e}"))?;
        let tag = format!("@row:{}", row.id);
        if !text.contains(&tag) {
            return Err(format!("feature `{rel}` is missing the `{tag}` tag"));
        }
        let prefix = match row.tier {
            Tier::Suite => "features/suites/",
            Tier::Target => "features/targets/",
        };
        if !rel.starts_with(prefix) {
            return Err(format!(
                "row `{}`: tier requires prefix `{prefix}` (got `{rel}`)",
                row.id
            ));
        }
        referenced.insert(rel);

        // Status discipline: a non-gating level (open) may never be a gating suite.
        let status = model
            .status(&row.status)
            .ok_or_else(|| format!("row `{}`: unknown status `{}`", row.id, row.status))?;
        if !status.gating && row.tier == Tier::Suite {
            return Err(format!(
                "row `{}`: non-gating status `{}` may not be a gating suite",
                row.id, row.status
            ));
        }
    }

    // Bidirectional coverage: dictionary <-> features on disk.
    let mut on_disk = BTreeSet::new();
    collect_features(&root.join("features"), root, &mut on_disk)?;
    let missing: Vec<_> = referenced.difference(&on_disk).cloned().collect();
    let orphan: Vec<_> = on_disk.difference(&referenced).cloned().collect();
    if !missing.is_empty() || !orphan.is_empty() {
        return Err(format!(
            "feature coverage mismatch: missing-on-disk={missing:?}, orphan-not-in-dictionary={orphan:?}"
        ));
    }

    // The inner product must be the positive-definite Euclidean composition norm.
    inner_product_is_euclidean(root)?;

    // Parametricity: no Atlas composite literal may appear in the generic core.
    no_literal_leak(root)?;

    Ok(AuditReport {
        rows_total: model.rows.len(),
        suites: model.rows_in_tier(Tier::Suite).count(),
        targets: model.rows_in_tier(Tier::Target).count(),
        features_on_disk: on_disk.len(),
    })
}

fn normalize(rel: &str) -> String {
    rel.replace('\\', "/")
}

fn collect_features(dir: &Path, root: &Path, out: &mut BTreeSet<String>) -> Result<(), String> {
    if !dir.is_dir() {
        return Ok(());
    }
    for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        if path.is_dir() {
            collect_features(&path, root, out)?;
        } else if path.extension().and_then(|s| s.to_str()) == Some("feature") {
            let rel = path
                .strip_prefix(root)
                .map_err(|e| e.to_string())?
                .to_string_lossy()
                .replace('\\', "/");
            out.insert(rel);
        }
    }
    Ok(())
}

/// No Atlas composite literal may appear in `tqc-core` (the generic framework). The canonical
/// numbers live only in `tqc-atlas` / the oracle. Comments and `#[cfg(test)]` modules are
/// excluded; only executable generic code is scanned.
fn no_literal_leak(root: &Path) -> Result<(), String> {
    let dir = root.join("crates/tqc-core/src");
    let mut paths: Vec<_> = fs::read_dir(&dir)
        .map_err(|e| format!("read tqc-core/src: {e}"))?
        .filter_map(Result::ok)
        .map(|e| e.path())
        .collect();
    paths.sort();
    for path in paths {
        if path.extension().and_then(|s| s.to_str()) != Some("rs") {
            continue;
        }
        let text = fs::read_to_string(&path).map_err(|e| e.to_string())?;
        // Drop the test module (conventionally at the file's end) and all comment lines.
        let before_tests = text.split("#[cfg(test)]").next().unwrap_or(&text);
        let code: String = before_tests
            .lines()
            .filter(|l| !l.trim_start().starts_with("//"))
            .collect::<Vec<_>>()
            .join("\n");
        let file = path.file_name().and_then(|s| s.to_str()).unwrap_or("?");
        for lit in ["96", "24", "12288"] {
            if contains_standalone_number(&code, lit) {
                return Err(format!(
                    "tqc-core/src/{file}: Atlas literal `{lit}` leaked into the generic core"
                ));
            }
        }
    }
    Ok(())
}

/// Whether `num` occurs in `text` as a standalone integer (no adjacent ASCII digit).
fn contains_standalone_number(text: &str, num: &str) -> bool {
    let bytes = text.as_bytes();
    let mut from = 0;
    while let Some(rel) = text[from..].find(num) {
        let start = from + rel;
        let end = start + num.len();
        let before_ok = start == 0 || !bytes[start - 1].is_ascii_digit();
        let after_ok = end >= bytes.len() || !bytes[end].is_ascii_digit();
        if before_ok && after_ok {
            return true;
        }
        from = start + 1;
    }
    false
}

/// The inner product is the positive-definite Euclidean composition norm `Σxᵢ²`.
fn inner_product_is_euclidean(root: &Path) -> Result<(), String> {
    let inner = root.join("crates/tqc-core/src/inner.rs");
    let text = fs::read_to_string(&inner).map_err(|e| format!("read inner.rs: {e}"))?;
    if !text.contains("euclidean_norm_sq") {
        return Err(
            "the inner product must be the Euclidean composition norm (euclidean_norm_sq)".into(),
        );
    }
    Ok(())
}
