# ADR Governance — Single Source of Truth

This directory is the **canonical home** of the Multiplicity formal ADR
governance system. It supersedes:

* `../../../adr_scaffolding/` (deleted) — the original lightweight scaffolding.
* `../Foundations/ADR/` (deleted) — a stale parallel stub layer that was
  never kept in sync with the canonical type.

All ADR code lives under the `ADR.*` namespace, declared in the lakefile:

```lean
lean_lib ADR where roots := #[`ADR]
lean_exe adrTest where root := `ADR.Test  -- @[test_driver]
```

## Layout

| File | Purpose |
|---|---|
| `Core.lean` | Foundational types: `ADRId`, `ADRStatus`, `ArtifactLink`, `ADR` structure, embedded propositional logic (`PropTerm`, `eval`, `evalB`, `Entails`, `Contradictory`), lifecycle state machine, supersession graph theory, registry coherence predicate. |
| `Proofs.lean` | Machine-checked theorems: immutability, acyclicity, traceability, consequence entailment, conflict symmetry. |
| `Examples.lean` | 10 production ADRs (ADR-001 … ADR-010) with embedded claims, jointly-satisfying witness environment, and a verified `sampleRegistry : ADRRegistry`. |
| `Migrated.lean` | 9 ADRs (0040, 0041, 0043, 0057–0061, 0064) migrated from the old `adr_scaffolding/` into the canonical namespace. Each is a `def` in the `ADR.Migrated` namespace and discharges the full set of registry invariants. |
| `Export.lean` | Markdown/HTML/JSON export pipeline targeting `docs/adr/`. |
| `Test.lean` | `#[test_driver]` for `lake test`. Exercises: registry invariants, consequence entailment, positive and negative cases, export determinism. |
| `Theorems/CareViability.lean` | Care Viability thresholds (aggregate audit + averaging blind spot). |
| `Theorems/HardwareInterlock.lean` | SystemVerilog `uac_safety_interlock.sv` ↔ Rust `InterlockClient` isomorphism. |
| `Theorems/Homestead_UCC_Care_Bridge.lean` | Homestead UCC ↔ Care bridge. |
| `Theorems/UacAlpBoundary.lean` | UAC/ALP boundary invariants. |
| `Theorems/HundianPauli.lean` | Hundian term-order / Pauli gate and `M = n_unpaired + 1` (ADR-0064). |

## Building & Testing

From the `packages/Foundry/` directory:

```bash
lake build ADR      # compile the canonical ADR library
lake test           # run the test driver (also re-exports docs/adr/)
```

From the repository root:

```bash
make adr-verify     # unified gate: build + test + anchoring check + export
```

## Adding a New ADR

1. Edit `Examples.lean` (production ADRs) or `Migrated.lean` (re-located
   historical ADRs). Use the existing record declarations as templates.
2. If the new ADR asserts a propositional claim, add a `PropTerm` claim
   and add it to `sampleClaims` (or `mergedRegistry.claims`).
3. Re-run `lake test`. All invariants are discharged by `decide` over the
   concrete registry; the test driver will fail if any invariant breaks.
4. Re-run `make adr-verify` to regenerate `docs/adr/` and verify the
   witness anchoring manifest.
