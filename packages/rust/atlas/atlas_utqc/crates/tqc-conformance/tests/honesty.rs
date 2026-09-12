//! The honesty meta-gate as a CI-gating test (`just honesty`).

use tqc_conformance::{audit, workspace_root};
use tqc_model::Model;

#[test]
fn honesty_audit_passes() {
    let model = Model::load().expect("the conceptual model must load and validate");
    let report = audit(&model, &workspace_root()).expect("the honesty audit must pass");
    println!("honesty audit OK: {report:?}");
    assert!(report.suites >= 1, "at least one gating suite must exist");
    assert_eq!(
        report.features_on_disk,
        report.suites + report.targets,
        "every feature on disk must be a dictionary row (no orphans)"
    );
}
