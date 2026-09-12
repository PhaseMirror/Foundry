# ADR kernel Rust scaffold

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
