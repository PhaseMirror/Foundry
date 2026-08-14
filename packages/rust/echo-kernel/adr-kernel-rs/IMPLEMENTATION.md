# Implementation scaffold

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
