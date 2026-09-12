from pathlib import Path
root = Path('output/adr-kernel-rs')
(root / 'crates' / 'kernel-core' / 'src').mkdir(parents=True, exist_ok=True)
(root / 'crates' / 'kernel-cli' / 'src').mkdir(parents=True, exist_ok=True)
(root / 'crates' / 'xtask' / 'src').mkdir(parents=True, exist_ok=True)
(root / 'tests' / 'fixtures').mkdir(parents=True, exist_ok=True)
(root / 'docs' / 'adr').mkdir(parents=True, exist_ok=True)
(root / '.github' / 'workflows').mkdir(parents=True, exist_ok=True)

files = {}
files['Cargo.toml'] = '''[workspace]
members = [
  "crates/kernel-core",
  "crates/kernel-cli",
  "crates/xtask"
]
resolver = "2"

[workspace.package]
edition = "2021"
license = "MIT"
version = "0.1.0"
authors = ["Multiplicity Foundation"]
rust-version = "1.78"

[workspace.dependencies]
anyhow = "1"
clap = { version = "4.5", features = ["derive"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
thiserror = "1"
petgraph = "0.6"
regex = "1"
once_cell = "1"
assert_cmd = "2"
predicates = "3"
tempfile = "3"
'''
files['README.md'] = '''# ADR kernel Rust scaffold

Production-grade scaffolding for an ADR-governed Rust kernel that enforces NF-style stratification constraints on rule graphs.

## Central tension
- Velocity vs governance: kernel evolution must stay fast without allowing unreviewed rule admission.
- Accuracy vs compliance: executable validation must match architectural intent and legal/operational constraints.
- Autonomy vs safety: exploratory rules may exist, but only stratified rules can install.

## Workspace layout
- `crates/kernel-core`: parser, validator, proof/report generation.
- `crates/kernel-cli`: command-line interface for validate/report/scaffold.
- `crates/xtask`: repo automation for CI, formatting, and test orchestration.
- `docs/adr`: ADR records that bind design choices to artifacts.
- `tests/fixtures`: sample rule sets for regression testing.

## Quick start
1. `cargo run -p kernel-cli -- validate tests/fixtures/valid.rules`
2. `cargo run -p kernel-cli -- report tests/fixtures/valid.rules --format json`
3. `cargo run -p xtask -- ci`

## Precision question
Are you optimizing this kernel scaffold for compliance-first governance or for rapid research iteration with governance gates at merge time?

## Owners, metrics, horizons
- Kernel team, metric: percent of rule sets producing deterministic proofs, horizon: 7 days.
- Platform team, metric: CI pass rate on workspace + fixture suite, horizon: 30 days.
- Governance team, metric: ADR coverage for breaking architectural changes, horizon: 30 days.
- Product owner, metric: time from proposal to validated rule package, horizon: 90 days.
'''
files['.gitignore'] = '''target/
Cargo.lock
.DS_Store
'''
files['rustfmt.toml'] = 'edition = "2021"\n'
files['clippy.toml'] = 'msrv = "1.78"\n'
files['docs/adr/0001-record-architecture-decisions.md'] = '''# 0001. Record architecture decisions

Date: 2026-05-24

## Status
Accepted

## Context
The kernel needs explicit governance artifacts so validation logic, CLI behavior, and proof generation can evolve without hidden assumptions.

## Decision
Store ADRs in `docs/adr` and require architectural changes affecting validation semantics, proof formats, or CI release policy to land with an ADR.

## Consequences
Decision lineage becomes auditable.
Review cost rises slightly, but kernel drift becomes visible.
'''
files['docs/adr/0002-adopt-rust-workspace-for-kernel.md'] = '''# 0002. Adopt Rust workspace for kernel

Date: 2026-05-24

## Status
Accepted

## Context
The kernel requires a stable core library, a thin operational CLI, and automatable repository tasks.

## Decision
Use a Cargo workspace with three crates: `kernel-core`, `kernel-cli`, and `xtask`.

## Consequences
Compile boundaries stay clean.
Testing and release automation scale without mixing orchestration code into the core crate.
'''
files['docs/adr/0003-enforce-nf-stratification-gate.md'] = '''# 0003. Enforce NF stratification gate

Date: 2026-05-24

## Status
Accepted

## Context
Type-dynamic rule systems can admit recursive evaluation loops unless membership-like edges preserve strict level ascent.

## Decision
Admit rule sets only when they satisfy a solvable level assignment where `member(x,y)` implies `level(y)=level(x)+1` and `equal(x,y)` implies equal levels.

## Consequences
Some expressive but unsafe rule sets remain explorable but not executable.
The validator becomes a non-negotiable kernel gate.
'''
files['.github/workflows/ci.yml'] = '''name: ci

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - name: Format
        run: cargo fmt --all -- --check
      - name: Lint
        run: cargo clippy --workspace --all-targets --all-features -- -D warnings
      - name: Test
        run: cargo test --workspace
'''
files['tests/fixtures/valid.rules'] = '''level raw 0
level echo 1
level belief 2
member raw echo
member echo belief
equal belief belief
'''
files['tests/fixtures/invalid.rules'] = '''level x 0
member x x
call f f
'''
files['crates/kernel-core/Cargo.toml'] = '''[package]
name = "kernel-core"
version.workspace = true
edition.workspace = true
license.workspace = true
rust-version.workspace = true

[dependencies]
anyhow.workspace = true
serde.workspace = true
serde_json.workspace = true
thiserror.workspace = true
regex.workspace = true
once_cell.workspace = true
petgraph.workspace = true
'''
files['crates/kernel-core/src/lib.rs'] = '''pub mod parser;
pub mod proof;
pub mod report;
pub mod stratify;

pub use parser::{Atom, RuleSet};
pub use proof::ProofArtifact;
pub use report::{Report, ReportFormat};
pub use stratify::{ValidationIssue, ValidationResult, Validator};
'''
files['crates/kernel-core/src/parser.rs'] = r'''use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Atom {
    Level { symbol: String, level: i32 },
    Member { left: String, right: String },
    Equal { left: String, right: String },
    Call { from: String, to: String },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuleSet {
    pub atoms: Vec<Atom>,
}

impl RuleSet {
    pub fn parse(input: &str) -> Result<Self> {
        let mut atoms = Vec::new();
        for (idx, raw) in input.lines().enumerate() {
            let line = raw.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let parts: Vec<&str> = line.split_whitespace().collect();
            let atom = match parts.as_slice() {
                ["level", symbol, level] => Atom::Level {
                    symbol: (*symbol).to_string(),
                    level: level.parse().map_err(|_| anyhow!("invalid level at line {}", idx + 1))?,
                },
                ["member", left, right] => Atom::Member {
                    left: (*left).to_string(),
                    right: (*right).to_string(),
                },
                ["equal", left, right] => Atom::Equal {
                    left: (*left).to_string(),
                    right: (*right).to_string(),
                },
                ["call", from, to] => Atom::Call {
                    from: (*from).to_string(),
                    to: (*to).to_string(),
                },
                _ => return Err(anyhow!("unrecognized syntax at line {}: {}", idx + 1, line)),
            };
            atoms.push(atom);
        }
        Ok(Self { atoms })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_rules() {
        let input = "level x 0\nmember x y\nequal y y\ncall f g\n";
        let set = RuleSet::parse(input).unwrap();
        assert_eq!(set.atoms.len(), 4);
    }
}
'''
files['crates/kernel-core/src/stratify.rs'] = r'''use crate::parser::{Atom, RuleSet};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidationIssue {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidationResult {
    pub admissible: bool,
    pub levels: BTreeMap<String, i32>,
    pub issues: Vec<ValidationIssue>,
}

pub struct Validator;

impl Validator {
    pub fn validate(rule_set: &RuleSet) -> ValidationResult {
        let mut issues = Vec::new();
        let mut explicit = BTreeMap::new();
        let mut symbols = BTreeSet::new();

        for atom in &rule_set.atoms {
            match atom {
                Atom::Level { symbol, level } => {
                    if let Some(prev) = explicit.insert(symbol.clone(), *level) {
                        if prev != *level {
                            issues.push(ValidationIssue {
                                code: "LEVEL_CONFLICT".into(),
                                message: format!("symbol {symbol} has conflicting explicit levels {prev} and {level}"),
                            });
                        }
                    }
                    symbols.insert(symbol.clone());
                }
                Atom::Member { left, right } | Atom::Equal { left, right } => {
                    symbols.insert(left.clone());
                    symbols.insert(right.clone());
                }
                Atom::Call { from, to } => {
                    symbols.insert(from.clone());
                    symbols.insert(to.clone());
                }
            }
        }

        let mut levels: BTreeMap<String, i32> = symbols.into_iter().map(|s| (s, 0)).collect();
        for (k, v) in &explicit {
            levels.insert(k.clone(), *v);
        }

        let node_count = levels.len().max(1);
        for _ in 0..node_count {
            let mut changed = false;
            for atom in &rule_set.atoms {
                match atom {
                    Atom::Member { left, right } => {
                        if left == right {
                            issues.push(ValidationIssue {
                                code: "SELF_MEMBERSHIP".into(),
                                message: format!("member({left},{right}) collapses a level into itself"),
                            });
                        }
                        let left_level = *levels.get(left).unwrap_or(&0);
                        let target = left_level + 1;
                        let right_level = *levels.get(right).unwrap_or(&0);
                        if right_level < target {
                            levels.insert(right.clone(), target);
                            changed = true;
                        }
                    }
                    Atom::Equal { left, right } => {
                        let l = *levels.get(left).unwrap_or(&0);
                        let r = *levels.get(right).unwrap_or(&0);
                        let target = l.max(r);
                        if l != target {
                            levels.insert(left.clone(), target);
                            changed = true;
                        }
                        if r != target {
                            levels.insert(right.clone(), target);
                            changed = true;
                        }
                    }
                    Atom::Call { from, to } => {
                        if from == to {
                            issues.push(ValidationIssue {
                                code: "SELF_CALL".into(),
                                message: format!("call({from},{to}) is an immediate recursive cycle"),
                            });
                        }
                        let from_level = *levels.get(from).unwrap_or(&0);
                        let target = from_level + 1;
                        let to_level = *levels.get(to).unwrap_or(&0);
                        if to_level < target {
                            levels.insert(to.clone(), target);
                            changed = true;
                        }
                    }
                    Atom::Level { .. } => {}
                }
            }
            for (symbol, level) in &explicit {
                if levels.get(symbol).copied().unwrap_or_default() != *level {
                    issues.push(ValidationIssue {
                        code: "PINNED_LEVEL_VIOLATION".into(),
                        message: format!("derived constraints move {symbol} away from pinned level {level}"),
                    });
                }
            }
            if !changed {
                break;
            }
        }

        for atom in &rule_set.atoms {
            match atom {
                Atom::Member { left, right } => {
                    if levels.get(right).copied().unwrap_or_default()
                        != levels.get(left).copied().unwrap_or_default() + 1
                    {
                        issues.push(ValidationIssue {
                            code: "NON_STRATIFIED_MEMBER".into(),
                            message: format!("member({left},{right}) violates NF ascent"),
                        });
                    }
                }
                Atom::Equal { left, right } => {
                    if levels.get(right) != levels.get(left) {
                        issues.push(ValidationIssue {
                            code: "NON_STRATIFIED_EQUAL".into(),
                            message: format!("equal({left},{right}) violates same-level constraint"),
                        });
                    }
                }
                Atom::Call { from, to } => {
                    if levels.get(to).copied().unwrap_or_default()
                        <= levels.get(from).copied().unwrap_or_default()
                    {
                        issues.push(ValidationIssue {
                            code: "NON_ASCENDING_CALL".into(),
                            message: format!("call({from},{to}) does not strictly ascend"),
                        });
                    }
                }
                Atom::Level { .. } => {}
            }
        }

        issues.sort_by(|a, b| a.code.cmp(&b.code).then(a.message.cmp(&b.message)));
        issues.dedup_by(|a, b| a.code == b.code && a.message == b.message);

        ValidationResult {
            admissible: issues.is_empty(),
            levels,
            issues,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::RuleSet;

    #[test]
    fn validates_good_rules() {
        let rules = RuleSet::parse("level a 0\nmember a b\nmember b c\n").unwrap();
        let result = Validator::validate(&rules);
        assert!(result.admissible);
        assert_eq!(result.levels.get("b"), Some(&1));
        assert_eq!(result.levels.get("c"), Some(&2));
    }

    #[test]
    fn flags_bad_rules() {
        let rules = RuleSet::parse("level a 0\nmember a a\n").unwrap();
        let result = Validator::validate(&rules);
        assert!(!result.admissible);
        assert!(result.issues.iter().any(|i| i.code == "SELF_MEMBERSHIP"));
    }
}
'''
files['crates/kernel-core/src/proof.rs'] = r'''use crate::stratify::ValidationResult;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProofArtifact {
    pub title: String,
    pub body: String,
}

impl ProofArtifact {
    pub fn from_validation(result: &ValidationResult) -> Self {
        let mut body = String::new();
        if result.admissible {
            body.push_str("A consistent NF-style level assignment exists.\n");
            for (symbol, level) in &result.levels {
                body.push_str(&format!("- level({symbol}) = {level}\n"));
            }
            body.push_str("Every membership edge ascends exactly one level, equality preserves level, and calls ascend strictly.\n");
            body.push_str("Therefore no admissible evaluation cycle exists under the current rule set.\n");
        } else {
            body.push_str("No proof of non-cyclicity can be constructed.\n");
            for issue in &result.issues {
                body.push_str(&format!("- [{}] {}\n", issue.code, issue.message));
            }
        }
        Self {
            title: "NF stratification proof artifact".into(),
            body,
        }
    }
}
'''
files['crates/kernel-core/src/report.rs'] = r'''use crate::{proof::ProofArtifact, stratify::ValidationResult};
use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReportFormat {
    Json,
    Text,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Report {
    pub admissible: bool,
    pub levels: std::collections::BTreeMap<String, i32>,
    pub issues: Vec<crate::stratify::ValidationIssue>,
    pub proof: ProofArtifact,
}

impl Report {
    pub fn from_validation(validation: ValidationResult) -> Self {
        let proof = ProofArtifact::from_validation(&validation);
        Self {
            admissible: validation.admissible,
            levels: validation.levels,
            issues: validation.issues,
            proof,
        }
    }

    pub fn render(&self, format: ReportFormat) -> Result<String> {
        Ok(match format {
            ReportFormat::Json => serde_json::to_string_pretty(self)?,
            ReportFormat::Text => {
                let mut out = String::new();
                out.push_str(&format!("admissible: {}\n", self.admissible));
                out.push_str("levels:\n");
                for (k, v) in &self.levels {
                    out.push_str(&format!("  - {} => {}\n", k, v));
                }
                if self.issues.is_empty() {
                    out.push_str("issues: none\n");
                } else {
                    out.push_str("issues:\n");
                    for issue in &self.issues {
                        out.push_str(&format!("  - [{}] {}\n", issue.code, issue.message));
                    }
                }
                out.push_str("proof:\n");
                out.push_str(&self.proof.body);
                out
            }
        })
    }
}
'''
files['crates/kernel-cli/Cargo.toml'] = '''[package]
name = "kernel-cli"
version.workspace = true
edition.workspace = true
license.workspace = true
rust-version.workspace = true

[dependencies]
anyhow.workspace = true
clap.workspace = true
serde_json.workspace = true
kernel-core = { path = "../kernel-core" }

[dev-dependencies]
assert_cmd.workspace = true
predicates.workspace = true
tempfile.workspace = true
'''
files['crates/kernel-cli/src/main.rs'] = r'''use anyhow::{Context, Result};
use clap::{Parser, Subcommand, ValueEnum};
use kernel_core::{Report, ReportFormat, RuleSet, Validator};
use std::{fs, path::PathBuf};

#[derive(Parser)]
#[command(name = "kernel-cli")]
#[command(about = "ADR-governed kernel validation CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Validate { file: PathBuf },
    Report {
        file: PathBuf,
        #[arg(long, value_enum, default_value_t = OutputFormat::Text)]
        format: OutputFormat,
    },
    ScaffoldAdr {
        #[arg(long)]
        number: u16,
        #[arg(long)]
        title: String,
    },
}

#[derive(Copy, Clone, Eq, PartialEq, ValueEnum)]
enum OutputFormat {
    Json,
    Text,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Validate { file } => {
            let contents = fs::read_to_string(&file).with_context(|| format!("reading {}", file.display()))?;
            let rules = RuleSet::parse(&contents)?;
            let result = Validator::validate(&rules);
            if result.admissible {
                println!("VALID");
                Ok(())
            } else {
                println!("INVALID");
                for issue in result.issues {
                    println!("[{}] {}", issue.code, issue.message);
                }
                std::process::exit(2)
            }
        }
        Commands::Report { file, format } => {
            let contents = fs::read_to_string(&file).with_context(|| format!("reading {}", file.display()))?;
            let rules = RuleSet::parse(&contents)?;
            let result = Validator::validate(&rules);
            let report = Report::from_validation(result);
            let rendered = report.render(match format {
                OutputFormat::Json => ReportFormat::Json,
                OutputFormat::Text => ReportFormat::Text,
            })?;
            println!("{}", rendered);
            Ok(())
        }
        Commands::ScaffoldAdr { number, title } => {
            let slug = title.to_lowercase().replace(' ', "-");
            let path = format!("docs/adr/{:04}-{}.md", number, slug);
            let body = format!("# {:04}. {}\n\nDate: YYYY-MM-DD\n\n## Status\nProposed\n\n## Context\n\n## Decision\n\n## Consequences\n", number, title);
            fs::write(&path, body).with_context(|| format!("writing {path}"))?;
            println!("created {}", path);
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use assert_cmd::Command;
    use predicates::prelude::*;

    #[test]
    fn validate_valid_fixture() {
        let mut cmd = Command::cargo_bin("kernel-cli").unwrap();
        cmd.arg("validate").arg("tests/fixtures/valid.rules");
        cmd.assert().success().stdout(predicate::str::contains("VALID"));
    }
}
'''
files['crates/xtask/Cargo.toml'] = '''[package]
name = "xtask"
version.workspace = true
edition.workspace = true
license.workspace = true
rust-version.workspace = true

[dependencies]
anyhow.workspace = true
clap.workspace = true
'''
files['crates/xtask/src/main.rs'] = r'''use anyhow::{bail, Result};
use clap::{Parser, Subcommand};
use std::process::Command;

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Ci,
    Test,
    Lint,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Ci => run_all(["fmt --all -- --check", "clippy --workspace --all-targets --all-features -- -D warnings", "test --workspace"]),
        Commands::Test => run("cargo", &["test", "--workspace"]),
        Commands::Lint => run_all(["fmt --all -- --check", "clippy --workspace --all-targets --all-features -- -D warnings"]),
    }
}

fn run_all<const N: usize>(commands: [&str; N]) -> Result<()> {
    for command in commands {
        let parts: Vec<&str> = command.split_whitespace().collect();
        run("cargo", &parts)?;
    }
    Ok(())
}

fn run(program: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(program).args(args).status()?;
    if !status.success() {
        bail!("command failed: {} {:?}", program, args);
    }
    Ok(())
}
'''
files['IMPLEMENTATION.md'] = '''# Implementation scaffold

## Central tension
- Governance vs throughput: kernel updates must stay reviewable without paralyzing research.
- Local safety vs expressive power: unstratified rules remain inspectable but never executable.

## Levers
- Owner: kernel team, metric: validator false-positive rate, horizon: 7 days.
- Owner: platform team, metric: workspace CI duration under 5 minutes, horizon: 30 days.
- Owner: governance lead, metric: all semantic validator changes linked to ADRs, horizon: 30 days.
- Owner: product owner, metric: time to scaffold and validate a new rule package, horizon: 90 days.

## Artifacts to update
- `docs/adr/0003-enforce-nf-stratification-gate.md`
- `.github/workflows/ci.yml`
- `crates/kernel-core/src/stratify.rs`
- `tests/fixtures/*`

## File scaffold
```text
adr-kernel-rs/
├── Cargo.toml
├── README.md
├── IMPLEMENTATION.md
├── docs/adr/
├── tests/fixtures/
├── crates/kernel-core/
├── crates/kernel-cli/
├── crates/xtask/
└── .github/workflows/ci.yml
```

## Detailed instructions
1. Create the workspace and keep governance artifacts beside code, not in a separate process silo.
2. Put parsing, validation, and proof generation in `kernel-core`; keep the CLI thin.
3. Treat `member(x,y)` as a +1 ascent constraint and `equal(x,y)` as a same-level constraint.
4. Reject self-membership, self-call cycles, and any derived assignment that violates pinned levels.
5. Generate both text and JSON reports so CI, humans, and downstream agents share one source of truth.
6. Require every breaking change in validation semantics to ship with an ADR and a new fixture.
7. Use `xtask` for formatting, linting, and workspace tests so local and CI workflows stay identical.

## Test harness
- Unit tests live with parser and stratifier modules.
- CLI smoke tests verify binary behavior against checked-in fixtures.
- Add regression fixtures for each newly discovered edge case: conflicting pinned levels, hidden equality collapse, indirect call cycle, and mixed admissible/inadmissible bundles.

## Commands
- `cargo run -p kernel-cli -- validate tests/fixtures/valid.rules`
- `cargo run -p kernel-cli -- report tests/fixtures/valid.rules --format json`
- `cargo run -p kernel-cli -- scaffold-adr --number 4 --title "Add call graph visualization"`
- `cargo run -p xtask -- ci`

## Precision question
Are recursive calls merely required to ascend one logical level, or must they also satisfy a separate well-founded measure beyond NF ascent for production admission?
'''

for path, content in files.items():
    p = root / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding='utf-8')
print(root)