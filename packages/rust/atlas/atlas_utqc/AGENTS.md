# Working contract

Timeless orientation for anyone (human or agent) working in this repository. For *what* is
being built, read [`docs/conceptual-model/00-source.md`](docs/conceptual-model/00-source.md);
for *how*, read [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md).

## Principles

1. **Docs-as-code, one direction.** The conceptual model is authored first
   (`00-source.md` → `model/*.toml`). Code realizes the model; it never gets ahead of it.
   Adding behavior without a dictionary row is a defect.
2. **BDD-first.** A feature starts as a Gherkin `.feature`, becomes a cucumber test, then a
   parametric implementation. No pending, skipped, or `#[ignore]`d scenarios. Ever.
3. **Parametric, no hardcoding.** Atlas quantities (`96`, `24`, …) are functions of
   `UseCaseParams`. The generic code in `tqc-core` must contain no Atlas literal; `tqc-atlas`
   supplies parameters and F1 expectations only.
4. **DRY.** A fact is defined once. Shared dep versions live in `[workspace.dependencies]`;
   shared lints in `[workspace.lints]`; each formula in exactly one function.
5. **External ground truth.** Validation is against authoritative external oracles (F1,
   uor-addr, holospaces `vv`, NIST/FIPS, E8, modular data, MTC axioms) — never
   self-reference. Oracles are committed with provenance + checksum.
6. **Honesty.** Status (`some-true` / `build` / `open`) is a contract on what V&V may assert.
   `open` rows are measured, never asserted. The honesty gate enforces this; do not route
   around it.
7. **No half-measures.** A standard is implemented in full or marked `build`/`open`. No
   narrowing (all five σ-axes, the full MTC axiom set, the whole class space).

## Status lives in three places only

The dictionary rows (`model/dictionary.toml`), the V&V tiers (`crates/tqc-vv`), and CI +
git. Never in a prose "status" paragraph that can drift.

## Before you commit

`just vv` must be green: `fmt`, `lint` (clippy `-D warnings`), `test`, `doc`, `bdd`,
`honesty`, `oracles`.
