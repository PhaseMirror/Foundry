# UOR Foundry

The UOR Foundation modeled with PrismPM: a non-profit dedicated to the
democratization of technology. The model is defined and validated against
explicitly adopted standards; its outputs are the views, artifacts, and
deployed services describing how the Foundation is implemented, governed,
operated, sustained, and improved.

> **Identity / provenance.** This repository is the **Universal Closure
> Calculator** (UCC) / UOR Foundry monorepo. Licensing entities: **UOR
> Foundation** and **Prime Materia Commons**; Lead Multiplicity Theorist:
> **Ryan O. Van Gelder**. Upstream provenance: UOR Foundation / Multiplicity /
> PhaseMirror (`PhaseMirror/UOR`). The Riemann Hypothesis remains a
> **conjecture**; no component in this repository constitutes a proof of it.

This directory is a **bounded sub-module** restricted to formal proofs,
mathematically-bound Rust verification engines, and core cryptography. It
intentionally contains **no** UI frameworks or outer-loop orchestrators; those
concerns live in the parent Phase Mirror workspace. Any non-mathematical
deployments, UI code, or orchestrators should be pushed up to the workspace
root.

## Verification Policy

Universal verification policy is enforced through `VERIFICATION.md` and the
`just vv` acceptance gate in `Justfile`
(`template-check fmt-check model lint test features bdd deny`). The gate
requires `prismpm` and `just`; when those tools are unavailable, the direct
`cargo` / `lake` commands in [Building & Testing](#building--testing) are the
working checks.

## Repository Layout

Toolchains: Rust `1.97.1` (`rust-toolchain.toml`), Lean 4 root project
`leanprover/lean4:v4.34.0-rc2` (`lean-toolchain`), Lean 4 ADR scaffold
sub-project `leanprover/lean4:v4.33.0-rc2` (`lean/lean-toolchain`).

```
packages/uor-foundry/
|-- Cargo.toml              Cargo workspace root (20 members)
|-- rust-toolchain.toml     rustc 1.97.1 + clippy/rustfmt targets
|-- lakefile.lean           Root Lean 4 project: Foundations, ADR, WordLove
|-- lean-toolchain          leanprover/lean4:v4.34.0-rc2
|-- justfile, Justfile      `just vv` acceptance gate
|-- VERIFICATION.md         Universal verification policy
|-- CONFORMANCE.md, CONTRACT.md, CHANGELOG.md, ROADMAP.md, RELEASE.md
|-- LICENSE                 MIT (plus LICENSE-APACHE, LICENSE-MIT)
|
|-- src/                    Rust engine binaries + Lean entry points (Lean*.lean)
|-- ADR/                    Formal ADR governance library (Lean 4, @[test_driver] adrTest)
|-- crates/                 39 Rust crates (legacy; not workspace members)
|-- packages/rust/          ~172 Rust crates, incl. the verified ADR-0013 crate crmf/
|-- packages/contracts/     Solidity contracts
|-- packages/circuits/      zk-SNARK circuit sources
|-- packages/materia_commons/, packages/operator-atlas/, packages/wasm/
|-- lean/                   ADR scaffold — separate Lean 4 project (adr_scaffold)
|-- contracts/              YAML contract/schema definitions (PWEH, NIST-RMF, zeta, ...)
|-- circuits/               Circom circuits + proving artifacts (ace, poseidon2)
|-- observability/          Prometheus, Alertmanager, anomaly detection
|-- models/                 Small-model JSON definitions (4)
|-- scripts/                140 operational scripts (build, verify, audit, deploy)
|-- state/                  Ledgers, witnesses, phase-mirror loop, certification receipts
|-- tests/                  Rust integration + Lean check harnesses
|-- docs/                   ADR ledger, registry, research documents, index
|-- uor_standards/          prism, uor-addr, UOR-Framework standards
|-- bootstrap/, tools/, xtask/    tooling
|-- methods/, model/, features/   R3 model + feature-suite manifests
```

Paths cited throughout this README are relative to `packages/uor-foundry/`
within the Multiplicity workspace.

## Architecture Decision Records

The ADR ledger lives in `docs/adr/` with `registry.json` and status
directories (`completed/` — 16 markdown, formerly in `accepted/`; `proposed/` is empty,
`grp/` — group ADRs). The canonical index is `docs/adr/README.md`.

- **ADR-0013 — UOR Civic Infrastructure** is the governing document:
  `docs/adr/completed/0013-UOR Civic Infrastructure.md`. It specifies the
  `UnsignedCrmfEnvelope` canonical wire format, the contractive kernel gate
  (`Λ_m < 1`), fail-closed interlocks (`SIG_GOV_KILL` / `L0_HALT` on defect or
  expansive transition), and the prime-indexed PWEH integrity chain
  `S(t) = Hash(S(t-1) ‖ pᵗ ‖ ‖A_{p^t} T(t)‖ ‖ M(t))`.
- The **formal Lean 4 ADR library** lives in `ADR/` at the workspace root with
  `ADR.Core`, `ADR.Proofs`, `ADR.Examples`, `ADR.Export`, and the `adrTest`
  test driver (builds and runs `@[test_driver]` on `lake test`).

### ADR verification results

Per-ADR verification gates are run with
`scripts/run_adr_tests.py <adr.md>`, which regenerates the ledger index
(`docs/adr/README.md`), checks for `sorry` debt, builds the Lean library, and
runs the `adrTest` driver before persisting `summary.json` + `REPORT.md` + raw
logs under `docs/adr/results/<adr-id>-<slug>/` (a `latest/` mirror plus an
immutable `run-YYYYMMDD-HHMMSS/` snapshot).

| ADR | Gate | Result | Report |
| :--- | :--- | :---: | :--- |
| **ADR-0110 — OSCAL and PrismPM** | `adr-index` · `adr-sorry-check` · `lake build ADR` · `lake test` | `PASS` | [`docs/adr/results/ADR-0110-OSCAL-and-PrismPM/latest/REPORT.md`](docs/adr/results/ADR-0110-OSCAL-and-PrismPM/latest/REPORT.md) |

The ADR-0110 gate passes the full zero-`sorry` OSCAL/Scopist formal model
(`ADR/OSCAL.lean`, exercised by `testOscalScopistLaw`,
`testOscalLawConsequences`, `testOscalConsequenceEntailment`,
`testOscalRegistryInvariants`): Scopist determinism/idempotency, zero-drift
(`SIG_GOV_KILL ⇒ UNATTESTED`), attestation boundary, packaging-only OSCAL, and
registry invariants (uniqueIds, acyclic, supersession, traceability, immutability).

## ADR-0013 Core slice — implementation status

Implemented, and currently the verified ADR-0013 Core-slice baseline:

### Rust / Kani (`packages/rust/crmf`, workspace member)
| Module | Content |
|:-------|:--------|
| `src/canonical.rs` | BCS primitives (`be_u64`, `be_u32`, `uleb128`) and `UnsignedCrmfEnvelope` — exact ADR field order, u32-BE metadata length prefix, `canonical_len = 184 + 4 + len(meta)`, length-safe decode, roundtrip/tamper tests (`*_adr_0013`) |
| `src/failgate.rs` | `GovSignal::{Nominal, SigGovKill}`, contractivity gate (`is_contractive`, scale `1e9`), associator-defect detection (`‖Δ‖ > ε`), `FailLatch` (fail-closed, no un-halt) |
| `src/pweh.rs` | `bind_step`/`hash_bind` (SHA-256) over `[u8; 128]`, `PwevhIntegrity` chain core, determinism/path-order/forbidden-channel tests |
| `src/bcs.rs`, `src/envelope.rs`, `src/ledger.rs`, `src/poseidon2.rs`, `src/seal.rs` | Supporting CRMF modules (pre-existing) |

Evidence (all green at HEAD): `cargo check -p crmf`, `cargo test -p crmf`
(18 unit + 4 integration), `cargo clippy -p crmf --all-targets`, and
`cargo kani -p crmf` — **7/7 harnesses VERIFICATION: SUCCESSFUL**
(5 fail-gate + 2 PWEH injectivity proofs).

### Lean 4 zero-sorry mirrors (`lean/MTPI/`)
| Module | Content |
|:-------|:--------|
| `ADRAttr.lean` | Registers the `@[adr]` / `@[proof]` attributes (must live in a separate leaf module — see note below) |
| `ADR0013.lean` | Lean core-only mirror: BCS widths/length theorems (`canonicalBytes_length`, ...), fail-closed interlock theorems (`kill_requires_evidence`, `latch_never_unhalts`, ...), PWEH binding injectivity / path-dependence, canonical example envelope — **zero `sorry`s, no Mathlib** |
| `ADR0013Test.lean` | Runtime driver (`lean_exe adr0013_test`), 17/17 PASS |
| `Core.lean`, `ADR.lean`, `Proofs.lean`, `Examples.lean`, `Export.lean`, `Test.lean` | Reusable ADR formal scaffold (`ADRStatus`, `ADR`, `validTransition`, acceptance/supersession invariants) |

Verified with `lake build`, `lake test`, and `lake exe adr0013_test` in the
`lean/` sub-project (build exit 0, all checks PASS).

> **Toolchain note.** In the Lean 4 builds used here (no Mathlib, core-only),
> tag attributes registered via `initialize` cannot be used in the same module
> that registers them; hence `ADRAttr.lean` exists as a distinct compiled leaf.
> Arithmetic goals are closed with `simp +arith`; `norm_num` is unavailable
> without Mathlib. The consequence-entailment checker in the scaffold is
> deliberately simple — it is a holding point for a full embedded DSL.

## Rust Workspace

The workspace root is `Cargo.toml` with **20 members**, including
`crmf`, `certificate-runtime`, `language-mapping`, `multiplicity-core`,
`ramanujan-multiplicity`, `archivum`, `alpha-rs`, `adr-verifier`,
`al-gft-derive`, `kani_harnesses`, and `phase-mirror-agent`. A large legacy
crate surface exists under `crates/` (39 crates, not members) and
`packages/rust/` (~172 crates). `cargo check --workspace` is **not green**:
`phase-mirror-agent` has pre-existing unresolved imports (`pirtm_core`,
`nalgebra`). The verified member-by-member build path is documented below.

## Lean 4 Formal Layer

- **Root project** (`lakefile.lean`, v4.34.0-rc2): default target `Foundations`,
  ADR governance library (`adrTest` `@[test_driver]`), `WordLove` (hybrid
  primality + certified coupling, `libFoundations_WordLove.so` for
  `wordlove-ffi`), plus `src/ADR/` modules. `lake-manifest.json` vendored.
- **ADR scaffold sub-project** (`lean/`, v4.33.0-rc2, `@[default_target]
  lean_lib MTPI`): the MTPI ADR scaffold and ADR-0013 mirrors above, plus
  `PdeRnn`, `CertificateCore`, `AlphaFunction`, `IfmdSafety`, `SpectralAttractor`
  targets and three executables (`adr_test` `@[test_driver]`, `mtpi_test`,
  `adr0013_test`). Core-only: **no Mathlib dependency**; honesty constraints are
  recorded in `alp_sorry_manifest.json`.

## Other Directories

- **`contracts/`** — YAML contract/schema definitions (PWEH receipt schema,
  NIST-RMF mapping, sedona/word-love/zeta/unc contracts).
- **`circuits/`** — Circom circuits (`ace.circom`, `poseidon2.circom`) plus
  generated R1CS/`.zkey`/`.sym` artifacts and `ACEVerifier.sol`.
- **`observability/`** — Prometheus, Alertmanager, anomaly monitor pipeline.
- **`models/`** — small-model JSON definitions (gpt2/smollm2/t5 variants).
- **`state/`** — phase-mirror loop, levers, epoch/witness/trace ledgers,
  certification receipts (`certification_mark_receipt.json`), xi governance
  records.
- **`scripts/`** — 140 operational scripts: build/verify gates
  (`honesty_audit.sh`, `check_sorry.sh`), PWEH verification, certification-mark
  pipeline (`verify_certification_mark.py`), deployment, and migrations.
- **`tests/`** — Rust integration (L0 invariants, linker harness, serialization,
  parity/determinism) and Lean harnesses (`AllTests.lean`, `SorryCheck.lean`).

## Building & Testing

Commands verified green in this workspace (see ADR-0013 section above for the
full evidence matrix):

```bash
# Rust — ADR-0013 verified crate
cargo check -p crmf
cargo test -p crmf          # 18 unit + 4 integration
cargo clippy -p crmf --all-targets
cargo kani -p crmf          # 7/7 harnesses (requires Kani 0.67+)

# Lean — ADR scaffold sub-project (lean/)
cd lean
lake build                  # exit 0
lake test                   # runs adr_test (ADR-045 anchor)
lake exe adr0013_test       # 17/17 PASS
```

The **root** Lean project (v4.34.0-rc2) builds the `Foundations`, `ADR`
(`adrTest`), and `WordLove` targets; `lake build ADR` and `lake test` pass at
HEAD with the root toolchain (see the per-ADR gate run under
[ADR verification results](#adr-verification-results)).
`cargo check --workspace` is not green (see
[Rust Workspace](#rust-workspace)).

`cargo test -p crmf` and `lake test` remain the local acceptance paths when
`just`/`prismpm` are unavailable; `just vv` is the full gate in CI contexts.

## License

MIT (see `LICENSE`), dual-licensed Apache-2.0 / MIT (`LICENSE-APACHE`,
`LICENSE-MIT`). See `CONTRACT.md` for the contract boundary and
`TEMPLATE-CONTRACT.md` / `TEMPLATE-Verification.md` for template conformance.
