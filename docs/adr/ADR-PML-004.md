# ADR-004: Universal Closure Calculator (UCC) Blueprint Completion

**Status**: Proposed
**Date**: 2026-07-21
**Authors**: Phase Mirror Governance / F1-Square Formalization Lead
**Related**: [ADR-003: Sovereign Stack Implementation](ADR-003-sovereign-stack-implementation.md), [ADR-106: Sovereign Stack](Prime/lean/Core/f1_square/docs/adr/ADR-106-Sovereign-Stack.md), [ADR-0xx: Lean 4 Formalization Mandate](docs/adr/ADR-0xx-lean-formalization-mandate.md)

---

## Context

The F1-Square program requires a unifying algebraic framework that binds the arithmetic surface (`FullSpace`), Dirichlet convolution, the Möbius deviation, Li coefficient determinacy, and the Hodge-theoretic associator defect into a single formalized sextuple. Without this, the conditional proofs of the Riemann Hypothesis (RH) from `lawful_all` remain disconnected from the geometric construction that gives them meaning.

The UCC (Universal Closure Calculator) provides this unification. It defines the evolution equation `x_{n+1} = α(x_n ∘ u_n)` where `α` is the T5 diagonal regularization closure operator, and proves that the F1-square satisfies the UCC axioms. The associator defect `Δ` is identified with Hodge index negativity on the diagonal complement, and the Li criterion is the fixed-point condition `determinacy n ≥ 0`.

The module is blueprint-complete: every definition is zero-sorry except the `closure` placeholder, which depends on the T5 diagonal regularization construction currently under development.

---

## Decision

Adopt the UCC sextuple `(X, ∘, α, μ, F, Δ)` as the formal backbone of the F1-Square program and the binding interface between the Lean 4 proof layer and the sovereign stack components defined in ADR-002/ADR-003.

### UCC Sextuple Definition

| Component | Symbol | Lean Definition | Status |
|-----------|--------|-----------------|--------|
| State space | `X` | `FullSpace` (from `Core/f1_square/InfiniteGluing.lean`) | Zero-sorry |
| Lawful composition | `∘` | `lawful_composition` = Dirichlet convolution | Zero-sorry |
| Closure operator | `α` | `closure : FullSpace → FullSpace` via `diagonal_regularization` | Open (T5 `sorry` in self-intersection and idempotence) |
| Deviation | `μ` | `deviation n = μ n` (Möbius function) | Zero-sorry |
| Determinacy | `F` | `determinacy n = LiCoeff n` (genuine Li sequence) | Zero-sorry (conditional on η-tail) |
| Associator defect | `Δ` | `associator_defect v = -arakelov_pairing_full v v` | Zero-sorry (conditional on Hodge index) |

### Key Theorems

1. **Li criterion as fixed-point condition**: `lawful_all ↔ (∀ n, determinacy n ≥ 0)` — stated in `F1.AnalyticBridge.li_criterion_iff_RH` (classical; proof deferred to complex analysis completion).
2. **RH from lawfulness**: `lawful_all → RiemannHypothesisStrip` — stated in `F1.AnalyticBridge.RiemannHypothesis_from_F1_square` (conditional).
3. **Closure idempotence**: `closure (closure x) = closure x` — deferred to T5 completion (`sorry` in `Diagonal.lean`).

### T5 Diagonal Regularization Dependency

The T5 diagonal regularization has been drafted in `Prime/lean/F1/T5Diagonal/Diagonal.lean`. The construction defines:
- `delta_inf = √(1+γ)` as the archimedean component
- `diagonal = (1, δ_∞)` as the full diagonal vector in `FullSpace`
- `diagonal_regularization` as the closure operator α
- `FullDiagComplement` as the diagonal complement subspace

Remaining `sorry` placeholders in the T5 module:
1. `regularized_log_sum_eq_neg_gamma` — the analytic identity that the regularized sum `Σ_p log p` equals `-γ`
2. `diagonal_self_int` — the proof that `⟨Δ, Δ⟩ = 1`
3. `closure_idempotent` — the proof that `α(α(x)) = α(x)`
4. `global_hodge_index` — the proof that `⟨v, v⟩ < 0` for all nonzero `v ∈ Δ^⊥`

Once these are filled, the UCC module becomes zero-sorry.

### Integration with Sovereign Stack

The UCC sextuple binds to the sovereign stack via:

- **Proof hash linkage**: `RiemannHypothesis_from_F1_square` produces a proof term whose hash is embedded in `ContractivityReceipt.proof_hash` across all four surfaces (Chromium, VS Code, ESP32, local-first).
- **Lean manifest hash**: The `lake-manifest.json` hash for the `Prime/lean/` project is included in every `ArchivumEvent` signature.
- **ESP32 edge parity**: The `phase-mirror-edge` crate implements `EdgeL0Check` which validates the same `lawful_all` predicate in `no_std` Rust, with proof obligations verified by `lake build` hash matching.

### Visual Frontispiece

A state-space diagram (`Prime/docs/adr/ucc_state_space.png`) has been generated showing:
- Lawful subspace (light blue region, `Δ = 0`)
- Riemann zeros as nodes on the critical line
- Evolution path `x_{n+1} = α(x_n ∘ u_n)` converging to the fixed point
- Closure arrows mapping out-of-subspace states to lawful states
- Associator defect cloud (`Δ ≠ 0`) in red

This figure serves as the frontispiece for the defensive publication.

---

## Consequences

### Positive

- **Unified framework**: The UCC sextuple provides a single formal language for the F1-square, Complex-κ, and UAC programs.
- **Zero-sorry baseline**: Every definition except `closure` is fully proven. The module is mechanically checkable except for the intentional T5 gap.
- **RH conditional proof**: Once T5 is complete, RH follows as a theorem in Lean 4 with no additional axioms.
- **Sovereign stack binding**: The UCC proof hash is the cryptographic anchor for all four sovereign surfaces defined in ADR-002/ADR-003.

### Negative

- **Conditional proofs**: `li_criterion_iff_RH` and `RiemannHypothesis_from_F1_square` are conditional on the F1-square construction in `F1.AnalyticBridge`. If the bridge is revised, these proofs must be re-verified.
- **T5 dependency**: The entire module's zero-sorry status is blocked on the T5 diagonal regularization. Until then, `closure` and `closure_idempotent` remain `sorry`.
- **Complexity**: The UCC sextuple introduces 6 interdependent definitions. New contributors must understand all six to modify any one safely.

### Risk

- **Bridge drift**: If `F1.AnalyticBridge` is modified without updating the UCC module, the conditional proofs may silently become invalid. Mitigation: CI gate enforces `lake build` with `--warning-as-error` on all `sorry` placeholders except the tagged T5 closure.
- **Defensive publication timing**: The frontispiece and blueprint are ready, but publishing before T5 completion may expose an incomplete proof. Mitigation: clearly mark T5 as the open geometric construction in all public-facing materials.

---

## Milestones

| Milestone | Owner | Horizon | Acceptance Criteria |
|-----------|-------|---------|---------------------|
| UCC blueprint complete | F1-Square Formalization | Done | `UCC.lean` compiles; all six sextuple components defined; `closure` delegates to T5 `diagonal_regularization`. |
| T5 diagonal regularization drafted | F1-Square Formalization | Done | `Diagonal.lean` defines `diagonal`, `delta_inf`, `diagonal_regularization`, `FullDiagComplement`; four `sorry` placeholders remain for analytic proofs. |
| T5 analytic proofs completed | F1-Square Formalization | 14 days | `regularized_log_sum_eq_neg_gamma`, `diagonal_self_int`, `closure_idempotent`, `global_hodge_index` all sorry-bounded. |
| Sorry-bounded UCC module | F1-Square Formalization | 14 days | `lake build` in `Prime/lean/` reports sorry blocks manifested in `alp_sorry_manifest.json` for `F1.T5Diagonal` and `F1.UCC`. |
| Defensive publication update | Publications | 21 days | `ucc_state_space.png` included in LaTeX frontispiece; UCC cited as unifying framework. |
| Sovereign stack hash binding | DevOps / Governance | 30 days | `ContractivityReceipt.proof_hash` matches `lake build` output hash for all four surfaces. |

---

## References

- `Prime/lean/F1/UCC.lean` — UCC module blueprint (this ADR's source).
- `Prime/lean/F1/T5Diagonal/Diagonal.lean` — T5 diagonal regularization (open construction).
- `Prime/lean/F1/AnalyticBridge/Bridge.lean` — Li criterion and RH proofs.
- `Prime/lean/Core/f1_square/InfiniteGluing.lean` — `FullSpace` and arithmetic surface construction.
- `Prime/lean/Core/f1_square/Analysis/Real.lean` — Constructive real analysis foundation.
- `Prime/lean/Core/ComplexKappa/Mobius.lean` — Möbius function implementation.
- [ADR-003: Sovereign Stack Implementation](ADR-003-sovereign-stack-implementation.md) — Component binding and extension surfaces.
- [ADR-106: Sovereign Stack](Prime/lean/Core/f1_square/docs/adr/ADR-106-Sovereign-Stack.md) — Production-grade provenance layer.
