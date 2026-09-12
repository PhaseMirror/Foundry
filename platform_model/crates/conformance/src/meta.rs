//! The honesty meta-gate.

use crate::runner::SuiteReport;
use repo_model::Model;
use std::collections::BTreeSet;
use std::path::Path;

/// What the meta-gate found.
#[derive(Clone, Debug, Default)]
pub struct HonestyReport {
    /// Every problem found.
    pub violations: Vec<String>,
    /// IDs checked.
    pub ids_checked: usize,
    /// Scenarios read.
    pub scenarios_checked: usize,
}

impl HonestyReport {
    /// Check if no violations were found.
    #[must_use]
    pub fn is_clean(&self) -> bool {
        self.violations.is_empty()
    }
}

/// The exact test name for an ID.
#[must_use]
pub fn test_name_for(id: &str) -> String {
    format!("conformance_{}", id.to_lowercase().replace('-', "_"))
}

/// Run the meta-gate.
pub fn check_honesty(root: &Path, tests: &BTreeSet<String>) -> std::io::Result<HonestyReport> {
    let mut report = HonestyReport::default();
    let model = match Model::load(&root.join("model")) {
        Ok(model) => model,
        Err(error) => {
            report
                .violations
                .push(format!("R1: model load failed: {error}"));
            return Ok(report);
        }
    };
    let suites: SuiteReport = crate::runner::scenarios_in(&root.join("features/suites"))?;
    report.scenarios_checked = suites.scenarios.len();
    report.ids_checked = model.ids.id.len();
    report.violations.extend(suites.violations.clone());

    for row in &model.ids.id {
        let matching: Vec<_> = suites
            .scenarios
            .iter()
            .filter(|scenario| scenario.id == row.id)
            .collect();
        match matching.as_slice() {
            [] => report.violations.push(format!(
                "R3: {} is registered but has no scenario in features/suites/.",
                row.id
            )),
            [scenario] => {
                if scenario.suite != row.suite {
                    report.violations.push(format!(
                        "R3: {} lives in `{}`, register says `{}`.",
                        row.id, scenario.suite, row.suite
                    ));
                }
                if scenario.statement.trim() != row.statement.trim() {
                    report.violations.push(format!("R3: {}'s scenario statement differs from register:\n  scenario: {}\n  register: {}", row.id, scenario.statement, row.statement));
                }
                if scenario.tag_line != format!("@{} @{}", row.id, row.level.as_str()) {
                    report.violations.push(format!(
                        "R3: {} tag line `{}` does not match `@{} @{}`",
                        row.id,
                        scenario.tag_line,
                        row.id,
                        row.level.as_str()
                    ));
                }
            }
            multiple => report.violations.push(format!(
                "R3: {} has {} scenarios; exactly one is required",
                row.id,
                multiple.len()
            )),
        }

        let test_name = test_name_for(&row.id);
        if !tests.contains(&test_name) {
            report.violations.push(format!(
                "R3: {} has scenario in `{}` but no test named `{test_name}`.",
                row.id, row.suite
            ));
        }
    }

    Ok(report)
}
