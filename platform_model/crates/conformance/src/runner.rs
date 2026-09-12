//! Reading features/suites/*.feature under the small Gherkin subset.

use std::path::Path;

/// One scenario, and the conformance ID it discharges.
#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct Scenario {
    /// The conformance ID from the scenario's tag.
    pub id: String,
    /// The honesty level from the scenario's tag.
    pub level: String,
    /// The scenario's one-line statement.
    pub statement: String,
    /// Which suite file it came from.
    pub suite: String,
    /// The steps, in order.
    pub steps: Vec<String>,
    /// The raw tag line, for exact-order validation.
    pub tag_line: String,
}

/// What a suite directory contains.
#[derive(Clone, Debug, Default)]
pub struct SuiteReport {
    /// Every scenario found.
    pub scenarios: Vec<Scenario>,
    /// Files that were read.
    pub files: usize,
    /// Subset violations.
    pub violations: Vec<String>,
}

const STEP_KEYWORDS: [&str; 5] = ["Given ", "When ", "Then ", "And ", "But "];
const FORBIDDEN_HEADINGS: [&str; 4] = ["Background:", "Scenario Outline:", "Examples:", "Rule:"];

fn pending_markers() -> [String; 3] {
    [
        "pending".to_owned(),
        format!("to{}", "do"),
        format!("not yet {}", "implemented"),
    ]
}

enum State {
    Start,
    Description,
    Tagged(String),
    Steps,
}

/// Parse every .feature file in dir.
pub fn scenarios_in(dir: &Path) -> std::io::Result<SuiteReport> {
    let mut report = SuiteReport::default();
    let mut entries: Vec<_> = std::fs::read_dir(dir)?.collect::<Result<_, _>>()?;
    entries.sort_by_key(std::fs::DirEntry::path);
    let pending = pending_markers();

    for entry in entries {
        let path = entry.path();
        if path
            .extension()
            .is_none_or(|extension| extension != "feature")
        {
            continue;
        }
        report.files += 1;
        let suite = path
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        let text = std::fs::read_to_string(&path)?;
        let mut state = State::Start;
        let mut current: Option<Scenario> = None;
        let violate = |report: &mut SuiteReport, line_number: usize, message: String| {
            report
                .violations
                .push(format!("{suite}.feature:{line_number}: {message}"));
        };

        for (index, raw) in text.lines().enumerate() {
            let line_number = index + 1;
            let line = raw.trim();
            if line.is_empty() {
                continue;
            }
            for forbidden in FORBIDDEN_HEADINGS {
                if line.starts_with(forbidden) {
                    violate(
                        &mut report,
                        line_number,
                        format!("`{forbidden}` is outside the subset"),
                    );
                }
            }
            if let Some(name) = line.strip_prefix("Feature:") {
                if !matches!(state, State::Start) {
                    violate(
                        &mut report,
                        line_number,
                        "a second `Feature:` heading; each suite file has one".to_owned(),
                    );
                }
                if name.trim() != suite {
                    violate(
                        &mut report,
                        line_number,
                        format!(
                            "the `Feature:` heading names `{}`, the file is `{suite}.feature`",
                            name.trim()
                        ),
                    );
                }
                state = State::Description;
                continue;
            }
            if matches!(state, State::Start) {
                violate(
                    &mut report,
                    line_number,
                    "the file must begin with its `Feature:` heading".to_owned(),
                );
                state = State::Description;
            }
            if line.starts_with('@') {
                if let State::Tagged(_) = state {
                    violate(
                        &mut report,
                        line_number,
                        "a tag line must be followed by its `Scenario:` line".to_owned(),
                    );
                }
                if let Some(done) = current.take() {
                    finish(&mut report, done, &suite);
                }
                let tags: Vec<&str> = line.split_whitespace().collect();
                if tags.len() != 2 || tags[1] != "@build" {
                    violate(
                        &mut report,
                        line_number,
                        format!("the tag line is exactly `@<ID> @build`, found `{line}`"),
                    );
                }
                state = State::Tagged(line.to_owned());
                continue;
            }
            if let Some(rest) = line.strip_prefix("Scenario:") {
                let State::Tagged(tag_line) = std::mem::replace(&mut state, State::Steps) else {
                    violate(
                        &mut report,
                        line_number,
                        "a `Scenario:` line without its `@<ID> @build` tag line".to_owned(),
                    );
                    state = State::Steps;
                    current = Some(Scenario {
                        id: String::new(),
                        level: String::new(),
                        statement: rest.trim().to_owned(),
                        suite: suite.clone(),
                        steps: Vec::new(),
                        tag_line: String::new(),
                    });
                    continue;
                };
                let tags: Vec<&str> = tag_line.split_whitespace().collect();
                let id = tags
                    .first()
                    .map(|tag| tag.trim_start_matches('@').to_owned())
                    .unwrap_or_default();
                let level = tags
                    .get(1)
                    .map(|tag| tag.trim_start_matches('@').to_owned())
                    .unwrap_or_default();
                current = Some(Scenario {
                    id,
                    level,
                    statement: rest.trim().to_owned(),
                    suite: suite.clone(),
                    steps: Vec::new(),
                    tag_line,
                });
                continue;
            }
            let step = STEP_KEYWORDS
                .iter()
                .find_map(|keyword| line.strip_prefix(keyword).map(|text| (*keyword, text)));
            match (&state, step) {
                (State::Description, None) => {}
                (State::Description, Some(_)) => violate(&mut report, line_number, "a step outside any scenario".to_owned()),
                (State::Steps, Some((keyword, text))) => {
                    let text = text.trim();
                    let lower = text.to_lowercase();
                    if text.is_empty() {
                        violate(&mut report, line_number, "an empty step".to_owned());
                    } else if pending.iter().any(|marker| lower.contains(marker.as_str())) || text.ends_with("...") {
                        violate(&mut report, line_number, format!("`{keyword}{text}` is a pending step"));
                    }
                    if let Some(scenario) = current.as_mut() {
                        if scenario.steps.is_empty() && keyword != "Given " {
                            violate(&mut report, line_number, "the first step of a scenario is `Given`".to_owned());
                        }
                        scenario.steps.push(format!("{keyword}{text}"));
                    }
                }
                (State::Steps | State::Tagged(_), None) | (State::Start, _) => violate(
                    &mut report,
                    line_number,
                    format!("unknown line `{line}`; only tag, Scenario, and step lines are accepted"),
                ),
                (State::Tagged(_), Some(_)) => violate(
                    &mut report,
                    line_number,
                    "a step line immediately following a tag line; a `Scenario:` line must separate them".to_owned(),
                ),
            }
        }
        if let Some(done) = current.take() {
            finish(&mut report, done, &suite);
        }
    }
    Ok(report)
}

fn finish(report: &mut SuiteReport, scenario: Scenario, suite: &str) {
    if scenario.steps.is_empty() {
        report.violations.push(format!(
            "{suite}.feature: scenario `{}` has no steps",
            scenario.statement
        ));
    }
    report.scenarios.push(scenario);
}
