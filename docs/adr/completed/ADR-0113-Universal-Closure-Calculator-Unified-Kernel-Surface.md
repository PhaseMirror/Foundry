# ADR-0113: Universal Closure Calculator — Unified Kernel Surface

**Status:** Completed
**Lean registry ID:** ADR-0113 (`ADR/Examples.lean`)
**Supersedes:** none
**Related:** ADR-0013 (UOR Civic Infrastructure), ADR-0014 (UCC as a Service), ADR-0028 / docs-0107 (target-first observability), ADR-PML-056 (UCC audit acceptance)

## Context

The Foundry hosts several independently verified surfaces, each with its own
proofs, artifacts, and failure modes:

* **ADR governance** — the formal registry and its invariants (`ADR/`).
* **Care Circle viability** — the Phase Mirror v2 audit kernel (`Care`, `ADR/Theorems/CareViability.lean`).
* **Homestead L0 civic-edge gate** — fail-closed admission over Raspberry Pi / IoT / LangChain RAG edges (`ADR/Theorems/Homestead_UCC_Care_Bridge.lean`).
* **Kappa contractivity** — spectral-gap, Lyapunov, and stability witnesses (`Foundations/Kappa/`).
* **WordLove** — the certified language surface (`Foundations/WordLove/`).
* **Governance machinery** — the ADR-0010 proof-debt manifest, the manifest-aware `sorry` checker, the CI gate, the export pipeline, and the property/concurrency tests.

The Universal Closure Calculator (UCC) sextuple `(X, ∘, α, μ, F, Δ)` is the
declared kernel boundary (`docs/specs/ucc_sextuple_v1.md`). Before this
decision, no single accepted record bound those surfaces to it, so
traceability, proof debt, and CI enforcement were fragmented across modules
and repositories. The Phase Mirror audit of the external `PhaseMirror/UCC`
tree re-confirmed that a labeling-only remediation is not a mechanism.

## Decision

Adopt the UCC sextuple as the canonical integration surface and wire every
verified Foundry surface to it. The record `adr0113` is registered (Accepted)
in the formal registry with an embedded `PropTerm` claim, and each wire is
bound to a concrete, machine-checked artifact:

1. **Edge admission — L0 fail-closed gate.** `ADR/Theorems/Homestead_UCC_Care_Bridge.lean`
   is the admission rule: `Seal` implies contractivity `Λ_m < 1`, entropy
   non-increase `ΔS ≤ 0`, Care Phase Mirror v2 viability, and the Hundian
   structural-load budget.
2. **Contractivity evidence for Δ.** The Kappa witnesses in
   `Foundations/Kappa/Spectral.lean` and `Foundations/Kappa/Stability.lean`
   (spectral-gap positivity, finite relaxation time, Lyapunov non-negativity,
   stability decreasing, prime stability advantage) supply the numerical
   evidence that `Λ_m < 1`.
3. **Governance machinery.** The ADR-0010 proof-debt manifest
   (`state/alp_sorry_manifest.json`), `scripts/check_adr_sorry.py`, the CI gate
   `.github/workflows/lean-gate.yml`, the `adrExport` executable, and the
   property/concurrency suite (`ADR/Properties.lean`) enforce the surface.
4. **Wire contract.** The integer-only BCS wire of
   `docs/specs/ucc_sextuple_v1.md` and the declarative tolerances of
   `contracts/universal_closure.yaml` (`Δ ≤ ε`, fail-closed) are the binding
   contract; floating point is structurally excluded (ADR-0021).
5. **Single source of truth.** Retire the `ADR/ADR/` and
   `pirtm/lean/Foundations/ADR/` shadow scaffolds so the `ADR.*` namespace is
   the sole governance authority.

**No claim is made about the Riemann Hypothesis.** The UCC kernel SLA is
kernel version, latency, and receipt integrity; lawfulness is a structural
contractivity/associator property of the kernel boundary.

## Consequences

* Every closure call returns **Closure**, **Defect** (Δ named in English),
  **Receipt**, and **Levers** (owner — action — metric — horizon), per ADR-0014.
* Unlawful transitions fail closed at L0; `Seal` implies contractivity,
  `ΔS ≤ 0`, and Care viability, so a sealed edge can never regress the
  embodied-capacity or resonance floors.
* Proof debt is explicit and bounded: 13 manifest-authorized Kappa `sorry`s,
  zero untracked, checker-enforced in CI and re-verified on a cold
  `lake build` / `lake test`.
* Shadow scaffolds are retired; any import of `ADR.ADR.*` or the pirtm
  `Foundations.ADR.*` is out of policy.
* The ID mapping convention is respected: the Lean core registry uses the
  block `ADR-0013..ADR-0028 ↔ docs/completed ADR-0092..ADR-0107` (+79), so the
  next globally free identifier is `ADR-0113`, used here in both trees.
* The integration claim is machine-checked: `adr0113_claim` is owned by an
  Accepted record and is jointly satisfiable with every other registry claim
  under `envP2C` (no semantic conflict).

## Traceability & Artifact Links

* **[Specification]** `docs/specs/ucc_sextuple_v1.md` — canonical sextuple `(X, ∘, α, μ, F, Δ)` wire format and the L0 lawfulness gate.
* **[Specification]** `contracts/universal_closure.yaml` — declarative associator tolerance `Δ ≤ ε` and closure-operator bounds (fail-closed).
* **[Lean Declaration]** `ADR/Theorems/Homestead_UCC_Care_Bridge.lean` — L0 gate soundness (Seal ⟹ contractivity, entropy non-increase, Care viability, Hundian budget).
* **[Lean Declaration]** `Foundations/Kappa/Spectral.lean` — spectral-gap positivity and finite relaxation time.
* **[Lean Declaration]** `Foundations/Kappa/Stability.lean` — Lyapunov non-negativity, stability decreasing, prime stability advantage.
* **[Lean Declaration]** `ADR/Properties.lean` — property-based concurrency conflict, traceability, and export-determinism tests.
* **[Source File]** `scripts/check_adr_sorry.py` — manifest-aware proof-debt gate (ADR-0010).
* **[Source File]** `.github/workflows/lean-gate.yml` — CI gate: `lake build` + `lake test` + `sorry` checker on the pinned toolchain.
* **[Specification]** `state/alp_sorry_manifest.json` — proof-debt ledger: 13 authorized Kappa `sorry`s, zero drift.
* **[Source File]** `ADR/README.md` — single source of truth; records shadow-scaffold retirement.
* **[Related ADR]** ADR-0013 / docs-0092 — the civic model the UCC governs.
* **[Related ADR]** ADR-0014 / docs-0093 — UCC as a Service year-one roadmap.
* **[Related ADR]** ADR-PML-056 — Universal Closure Calculator audit acceptance.
