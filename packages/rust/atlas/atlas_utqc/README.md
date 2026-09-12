# UOR-Atlas-UTQC

A **parametric, BDD-driven, V&V-gated** realization of The UOR Atlas UTQC. This repository is the formalization, implementation, and analysis of The UOR Atlas UTQC, which is the basis of the entire UOR ecosystem of tooling including Hologram Holospaces.

> The UOR Atlas UTQC here means the **structural / simulation** sense — a modular-tensor-category (MTC)
> realized on a content-addressed substrate. It provides a **proven topological quantum advantage** 
> by subverting exponential vector expansion via cache collapse, a capability natively inherited by Hologram Holospaces. 
> Every claim is tracked against an authoritative source and never asserted beyond what that source shows.

## What this repository is

This is a Rust workspace that **imports holospaces as the substrate** and builds, on top
of it, the MTC structure defined in [`docs/conceptual-model/00-source.md`]. The emphasis
is **verification & validation infrastructure**:

1. **Docs-as-code.** The conceptual model is authored once, as prose *and* as typed data
   (`model/*.toml` → the `tqc-model` crate). It is the single source of truth.
2. **BDD development.** Every feature begins as a Gherkin `.feature` definition, becomes a
   test, then a **parametric** implementation. No feature is "done" until its scenario is
   green and CI-gated. There are no pending/skipped steps.
3. **External validation.** Each claim is bound to an *authoritative external oracle* —
   the [F1] Lean formalization of the UOR Atlas, the realized [uor-addr] composition
   operations, the holospaces `vv` witnesses, and published math standards (NIST/FIPS
   hash KATs, the E8 lattice, modular-form data, the MTC axioms).
4. **Honesty discipline.** A meta-gate proves the suite never asserts an *open*
   claim as established.

## Parametricity

The implementation is **generic over the use-case**. The UOR Atlas — scope `q=4`,
modality `T=3`, context `O=8` (96 classes) — is the canonical instance, validated against
F1; but `tqc-core` is parameterized so arbitrary use-cases instantiate the same DRY
framework. See [`docs/architecture/ARCHITECTURE.md`].

## Layout

| Path | Role |
|---|---|
| `docs/conceptual-model/` | the conceptual model, prose (cited authority: `00-source.md`) |
| `docs/architecture/` | architecture of the workspace + the parametric framework |
| `model/` | the conceptual model as typed data (dictionary, status ledger, oracles) |
| `crates/tqc-model` | parses `model/` into typed, validated registries |
| `crates/tqc-core` | the **parametric** MTC framework (DRY core, `no_std`) |
| `crates/tqc-atlas` | the UOR Atlas use-case instance (F1-validated) |
| `crates/tqc-mtc` | the MTC builds: modular `S`/`T` and braiding `R` (axiom-validated) |
| `crates/tqc-substrate` | the sole facade over holospaces / hologram / uor-addr |
| `crates/tqc-vv` | V&V witnesses + external-oracle loaders |
| `crates/tqc-conformance` | the BDD (cucumber) runner + the honesty meta-gate |
| `features/` | Gherkin `.feature` definitions (BDD-first) |
| `oracles/` | committed external validation artifacts + provenance + checksums |
| `xtask/` | automation: oracle verify, F1 re-derivation, conformance report |

## Quickstart

```sh
just            # list tasks
just vv         # run the full local gate (fmt, lint, test, doc, bdd, honesty, oracles)
just bdd        # run the Gherkin BDD suite
```

## Status

Every row of the dictionary carries one of three honesty levels — `some-true` (sourced fact
reproduced), `build` (constructed and axiom-validated), `open` (measured and reported). See
[`docs/conceptual-model/03-status-discipline.md`] and the live conformance ledger produced by
`just report`.

[holospaces]: https://github.com/Hologram-Technologies/holospaces
[F1]: https://github.com/afflom/F1
[uor-addr]: https://github.com/UOR-Foundation/uor-addr
[`docs/conceptual-model/00-source.md`]: docs/conceptual-model/00-source.md
[`docs/architecture/ARCHITECTURE.md`]: docs/architecture/ARCHITECTURE.md
[`docs/conceptual-model/03-status-discipline.md`]: docs/conceptual-model/03-status-discipline.md
