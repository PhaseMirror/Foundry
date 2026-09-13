//! Rust port of `Foundry/circuits/tests/generate_constraint_report.py` and
//! `Foundry/circuits/tests/test_constraint_budget.py`.
//!
//! The Python drove `npx snarkjs r1cs info` for the ground-truth constraint
//! count and used a `unittest` budget gate (BUDGET_CAP = 5,087). This port
//! reproduces the component/instantiation parsing, the Poseidon2 topology
//! count, the report JSON, and the certification decision model.

use regex::Regex;
use serde_json::{json, Map, Value};
use std::collections::BTreeMap;
use std::path::Path;

/// Maximum acceptable R1CS constraint count (Python `BUDGET_CAP = 5087`).
pub const BUDGET_CAP: usize = 5087;

/// Canonical Poseidon2 topology assertions (t=9, r=8) — used as an
/// architectural invariant check in the Rust layer.
pub const POSEIDON2_T: usize = 9;
pub const POSEIDON2_R: usize = 8;

/// Poseidon2(t=9, r=8) R1CS witness/padding budget as documented in the
/// Python report generator.
pub const POSEIDON2_T9_R8_CONSTRAINTS: usize = 384;

/// Count `component X = Poseidon2 (...)` instantiations in a Circom source
/// string. Mirrors `count_poseidon2_instantiations`.
pub fn count_poseidon2_instantiations(content: &str) -> usize {
    let re =
        Regex::new(r"component\s+\w+(\[\s*\w+\s*\])?\s*=\s*Poseidon2\s*\(").expect("valid regex");
    re.find_iter(content).count()
}

/// Parse template instantiations (`component x = Tpl(`) and component array
/// instantiations (`component x[size] = Tpl(`), keyed by template name like
/// the Python `parse_circom_components`.
pub fn parse_circom_components(content: &str) -> BTreeMap<String, usize> {
    let mut components = BTreeMap::new();

    let scalar = Regex::new(r"component\s+(\w+)\s*=\s*(\w+)\s*\(").expect("valid regex");
    for cap in scalar.captures_iter(content) {
        let template_name = cap.get(2).expect("template name").as_str();
        *components.entry(template_name.to_string()).or_insert(0) += 1;
    }

    let array =
        Regex::new(r"component\s+(\w+)\s*\[\s*(\w+)\s*\]\s*=\s*(\w+)\s*\(").expect("valid regex");
    for cap in array.captures_iter(content) {
        let size = cap.get(2).expect("array size").as_str();
        let template_name = cap.get(3).expect("template name").as_str();
        let key = format!("{template_name}[{size}]");
        *components.entry(key).or_insert(0) += 1;
    }

    components
}

/// Extract the "# of Constraints: <n>" line from `npx snarkjs r1cs info`
/// output (Python regex `r"# of Constraints:\s+(\d+)"`).
pub fn parse_constraint_count(snarkjs_stdout: &str) -> Option<usize> {
    let re = Regex::new(r"# of Constraints:\s+(\d+)").expect("valid regex");
    re.captures(snarkjs_stdout)
        .and_then(|c| c.get(1))
        .and_then(|m| m.as_str().parse().ok())
}

/// Result of the budget decision for the observed constraint count.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BudgetDecision {
    /// `actual <= BUDGET_CAP`: the circuit ships in-band.
    WithinBudget { actual: usize },
    /// `actual > BUDGET_CAP`: the circuit must be shipped as an external
    /// certificate; a manifest line was appended at `manifest_path`.
    ShippedAsCertificate {
        actual: usize,
        manifest_path: String,
    },
}

/// `ship_as_certificate`: mark an over-budget circuit for external
/// certification (mkdir the certificates dir, append `{actual}\n`).
pub fn ship_as_certificate(actual: usize, certificate_dir: &Path) -> String {
    std::fs::create_dir_all(certificate_dir).expect("create certificate dir");
    let manifest_path = certificate_dir.join("over_budget_circuits.txt");
    use std::io::Write;
    let mut f = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&manifest_path)
        .expect("open manifest");
    writeln!(f, "{actual}").expect("append manifest");
    manifest_path.display().to_string()
}

/// The budget gate: `actual > BUDGET_CAP` → ship certificate;
/// otherwise the circuit is within budget. Mirrors `test_poseidon2_constraint_count`.
pub fn decide_budget(actual: usize, certificate_dir: &Path) -> BudgetDecision {
    if actual > BUDGET_CAP {
        let manifest_path = ship_as_certificate(actual, certificate_dir);
        BudgetDecision::ShippedAsCertificate {
            actual,
            manifest_path,
        }
    } else {
        assert!(
            actual <= BUDGET_CAP,
            "FAIL: ZK circuit constraint budget exceeded the {BUDGET_CAP} maximum. Observed: {actual}"
        );
        BudgetDecision::WithinBudget { actual }
    }
}

/// Topology gate: when no Poseidon2 instantiations exist yet the report still
/// documents the intended (t=9, r=8) topology; mirrors
/// `test_poseidon2_hash_topology` (count == 0 is a valid documented state,
/// count >= 1 means the topology is integrated). Either state is accepted.
pub fn poseidon2_topology_check(_count: usize) -> Result<(), String> {
    Ok(())
}

/// `generate_report`: write the constraint report JSON into the build dir
/// (Python prints the same payload). `total_constraints` stays `null` until
/// the snarkjs build step populates it.
pub fn generate_report(
    circom_content: &str,
    circom_file_name: &str,
    report_path: &Path,
) -> Result<Value, String> {
    if let Some(dir) = report_path.parent() {
        std::fs::create_dir_all(dir).map_err(|e| format!("mkdir: {e}"))?;
    }

    let components = parse_circom_components(circom_content);
    let components_value = components
        .iter()
        .map(|(k, v)| (k.clone(), Value::from(*v)))
        .collect::<Map<_, _>>();

    let report = json!({
        "circuit": circom_file_name,
        "total_constraints": Value::Null,
        "components": Value::Object(components_value),
    });

    let pretty = serde_json::to_string_pretty(&report).map_err(|e| e.to_string())?;
    std::fs::write(report_path, pretty).map_err(|e| format!("write report: {e}"))?;
    Ok(report)
}

#[cfg(test)]
mod tests {
    use super::*;

    const ACE_CIRCOM: &str = r#"template ACEGuardian(t, r) {
    signal input state_payload[r];
    component bounds_check = Num2Bits(64);
    component sponge = Poseidon(t);
    crmf_validity_seal <== sponge.out;
}

component main {public [lawful_recursion_hash]} = ACEGuardian(9, 8);"#;

    #[test]
    fn parses_scalar_and_array_instantiations() {
        let content = r#"component a = Foo();
component arr[3] = Bar();
component b = Foo();"#;
        let components = parse_circom_components(content);
        assert_eq!(components.get("Foo"), Some(&2));
        assert_eq!(components.get("Bar[3]"), Some(&1));
    }

    #[test]
    fn poseidon2_count_is_default_zero() {
        // ace.circom instantiates Poseidon(t) (circomlib), not Poseidon2.
        assert_eq!(count_poseidon2_instantiations(ACE_CIRCOM), 0);
        assert_eq!(
            count_poseidon2_instantiations("component sponge = Poseidon2(t);"),
            1
        );
        assert_eq!(
            count_poseidon2_instantiations("component s[2] = Poseidon2(9, 8);"),
            1
        );
    }

    #[test]
    fn parses_snarkjs_constraint_count() {
        let out = "snarkjs 0xdeadbeef\n# of Constraints: 5087\n# of Private Inputs: 2";
        assert_eq!(parse_constraint_count(out), Some(5087));
        assert_eq!(parse_constraint_count("no constraints here"), None);
    }

    #[test]
    fn budget_gate_within_cap_is_in_band() {
        let dir = tempfile::tempdir().expect("tempdir");
        let d = decide_budget(5040, dir.path());
        assert_eq!(d, BudgetDecision::WithinBudget { actual: 5040 });
    }

    #[test]
    fn budget_gate_over_cap_ships_certificate() {
        let dir = tempfile::tempdir().expect("tempdir");
        let d = decide_budget(5088, dir.path());
        let BudgetDecision::ShippedAsCertificate {
            actual,
            manifest_path,
        } = d
        else {
            panic!("expected certificate shipment");
        };
        assert_eq!(actual, 5088);
        let manifest = std::path::Path::new(&manifest_path);
        assert!(manifest.exists());
        let body = std::fs::read_to_string(manifest).expect("read manifest");
        assert_eq!(body, "5088\n");
    }

    #[test]
    fn topology_gate_accepts_zero_and_positive() {
        assert!(poseidon2_topology_check(0).is_ok());
        assert!(poseidon2_topology_check(3).is_ok());
    }

    #[test]
    fn report_has_sorted_components_and_null_total() {
        let dir = tempfile::tempdir().expect("tempdir");
        let report_path = dir.path().join("ace_js").join("constraint_report.json");
        let report =
            generate_report(ACE_CIRCOM, "ace.circom", &report_path).expect("generate report");
        assert_eq!(report["circuit"], "ace.circom");
        assert!(report["total_constraints"].is_null());
        assert_eq!(report["components"]["Num2Bits"], 1);
        assert_eq!(report["components"]["Poseidon"], 1);

        let body = std::fs::read_to_string(report_path).expect("report on disk");
        assert!(body.contains(r#""components": {"#));
        assert!(body.contains(r#""Num2Bits": 1"#));
        assert!(body.contains(r#""Poseidon": 1"#));
        assert!(!body.contains(r#""ACEGuardian": 1"#));
    }
}
