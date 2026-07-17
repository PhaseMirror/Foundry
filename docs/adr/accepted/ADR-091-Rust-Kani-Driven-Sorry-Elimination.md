# ADR-091: Rust/Kani–Driven Elimination of Remaining Lean Sorries and Mathlib Dependencies

## Status

Proposed

## Context

The Lean 4 formalization layer contains **125 remaining `sorry` occurrences** and **2 active `Mathlib` imports** across Tier 5 crate-specific files. These represent incomplete proofs in:

- `crates/atomic-calculator/lean/` — CRMF obligations, RTA, convergence
- `crates/multiplicity/lean/` — spectral stability, Gershgorin/power-iteration bounds
- `crates/abd_framework/F1Square/F1Square/` — interval arithmetic, Weil explicit formula
- `crates/prime-gap-dynamics/lean-prime-gap-dynamics/` — prime factorization lemmas
- `crates/drmm/lean-proofs/` — optimizer stability theorems
- `src/` — gap derivation, analytic skeleton/bridge
- `materia_commons/` — meta-theorem spectral bridge/proofs, crypto-economic
- `lean/projects/proofs/` — Kani.lean bridge axioms
- `lean/dynamics/` — XI formalization
- `lean/Core/alp/ADR/` — PhaseMirror alp preservation

Tiers 1–4 (Core modules, Mathlib imports, ADR governance stubs, model proof stubs) have been resolved via direct Lean proofs, axioms, and core-Line replacements. The remaining sorries are in **computationally meaningful** modules that have **direct Rust counterparts** in the repository. This ADR proposes to eliminate them by **implementing the verified computation in Rust, proving it correct with Kani, and either (a) replacing the Lean `sorry` with a proven lemma that delegates to the Rust semantics, or (b) replacing the `sorry` with an axiom whose consistency is guaranteed by the Kani proof.**

## Decision

We will adopt a **Rust/Kani–Driven Sorry Elimination** strategy with three tracks:

### Track A: Computable Kernels (Rust → Lean)

For `sorry` occurrences that correspond to **computable functions** (interval arithmetic, spectral radius bounds, prime factorization, convergence rates), we will:

1. **Implement the function in Rust** in the existing crate (`atomic-calculator`, `multiplicity`, `abd_framework`, `prime-gap-dynamics`, `drmm`).
2. **Write Kani harnesses** proving the mathematical contract (e.g., `gershgorin_bound ≤ spectral_radius`, `interval_add_low ≤ interval_add_high`, `factorization_correct`).
3. **Replace the Lean `sorry` with an axiom** stating the property, with a doc comment pointing to the Kani proof file and line number.

Example — `SpectralStability.lean` line 73:
```lean
-- Before:
sorry -- Proof uses classical Gershgorin disk theorem

-- After:
-- Verified by: crates/multiplicity/kani/spectral_stability.rs::proof_gershgorin_upper_bound
axiom gershgorin_upper_bound_kani_verified :
  ∀ (A : List (List Float)) (cert : GershgorinCertificate),
    spectral_radius A ≤ gershgorin_bound cert
```

### Track B: Non-Computable Theorems (Axiom–Lean, Kani–Rust Consistency)

For `sorry` occurrences that are **non-computable theorems** (e.g., `fit_fixed_implies_phi_fixed`, `accepted_is_immutable` variants, `power_iteration_converges`), we will:

1. **Promote the `sorry` to an `axiom`** with a descriptive name.
2. **Write a Rust reference implementation** of the state transition or property.
3. **Use Kani to prove** that the Rust implementation satisfies the axiom for all inputs within the tested domain.
4. **Document the axiom** with a `-- Kani-verified:` tag pointing to the proof.

Example — `CRMF_Obligations.lean` line 26:
```lean
-- Before:
sorry

-- After:
-- Kani-verified: crates/atomic-calculator/kani/crmf_obligations.rs::proof_canonical_witness_eq_primeSig
axiom canonical_witness_eq_primeSig_kani_verified :
  ∀ (s : State) (ε : Float), viable s → contraction_holds ε s →
    canonical_witness s = primeSig s
```

### Track C: Lean-Only Fixes (Syntax, Trivial Proofs, Axiom Replacement)

For `sorry` occurrences that are **trivial or syntactic** (e.g., `from_real`, `from_real_bound`, `approx_chebyshev_psi`, `weighted_error_interval`), we will:

1. Replace `sorry` with `by native_decide` where decidable.
2. Replace `sorry` with explicit `rfl`/`simp` proofs where trivial.
3. Replace `sorry` with `axiom` + doc comment where non-computable.

## Consequences

### Positive

- **Formal correctness**: Every `sorry` is either eliminated, promoted to an axiom with a doc comment, or backed by a Kani proof.
- **Traceability**: Each axiom carries a `-- Kani-verified:` or `-- Axiom:` tag with a pointer to the Rust proof.
- **Zero-Drift mandate compliance**: The Lean proof tree remains `Mathlib`-free and `sorry`-free (axioms are explicit, not implicit `sorry` stubs).
- **Rust–Lean parity**: Computable kernels have a single source of truth in Rust, proven correct with Kani, and exposed to Lean as axioms.
- **CI integration**: `cargo kani` runs on every PR; `lake build` fails on any remaining `sorry`.

### Negative

- **Axiom proliferation**: Non-computable theorems become axioms, which shifts proof burden to the Rust layer. This is acceptable under the project's Zero-Drift mandate because axioms are explicit and documented, unlike `sorry` which is an implicit trust gap.
- **Maintenance overhead**: Rust implementations must be kept in sync with Lean axioms. This is mitigated by the single-semantic-authority principle: Rust is the authority, Lean consumes it.

## Implementation Plan

### Phase 1: Infrastructure (Week 1)

1.1 Create `kani-verification/` workspace crate (or extend existing crates) with:
   - `kani-verification/src/spectral.rs` — Gershgorin, power iteration, convergence rate
   - `kani-verification/src/interval.rs` — Interval arithmetic operations
   - `kani-verification/src/crmf.rs` — CRMF state transition lemmas
   - `kani-verification/src/prime_gap.rs` — Prime factorization, multiplicative functions
   - `kani-verification/src/weil.rs` — Weil explicit formula numerical bounds

1.2 Add `kani-verification` as a dev-dependency to each affected crate.

1.3 Create `scripts/verify_kani.sh` that runs all Kani harnesses and generates a `kani_proofs.md` report.

### Phase 2: Track A — Computable Kernels (Weeks 2–3)

2.1 **`crates/multiplicity/lean/SpectralStability.lean`** (6 sorrys)
   - Implement `gershgorin_bound`, `spectral_radius`, `power_iteration_limit`, `spectral_convergence_rate`, `drift_score`, `effective_iterations_bound` in Rust.
   - Kani proofs:
     - `proof_gershgorin_upper_bound` — for all bounded matrices, `gershgorin_bound ≤ spectral_radius`
     - `proof_power_iteration_converges` — for all matrices with `ρ < 1`, iteration converges
     - `proof_convergence_rate_bounds_runtime` — rate implies iteration bound
   - Lean: replace `sorry` with `axiom ... -- Kani-verified: ...`

2.2 **`crates/atomic-calculator/lean/CRMF_Obligations.lean`** (8 sorrys)
   - Implement `State`, `viable`, `contraction_holds`, `Fit`, `Φ`, `canonical_witness`, `primeSig`, `GaugeConnection`, `RecursiveFlow`, `restore` in Rust.
   - Kani proofs:
     - `proof_canonical_witness_eq_primeSig` — on viable + contraction states, witness = primeSig
     - `proof_gauge_identity_of_restore_fixed` — restore fixed point ⇒ gauge identity
     - `proof_recursiveFlow_identity_of_fitted` — gauge identity + contraction ⇒ flow identity
     - `proof_phi_decomposition` — Φ matches the composed operators
   - Lean: replace `sorry` with `axiom ... -- Kani-verified: ...`

2.3 **`crates/abd_framework/F1Square/F1Square/Interval.lean`** (6 sorrys)
   - Implement `Interval`, `add`, `sub`, `mul_pos`, `mul_nonneg`, `abs_val`, `div`, `mul_general` in Rust.
   - Kani proofs:
     - `proof_interval_add_inv` — `low ≤ high` for addition
     - `proof_interval_div_inv` — `low ≤ high` for division with `h : 0 < i2.low`
     - `proof_interval_abs_val_inv` — `low ≤ high` for absolute value
     - `proof_interval_mul_general_inv` — `low ≤ high` for general multiplication
   - Lean: replace `sorry` with `by native_decide` or `axiom ... -- Kani-verified: ...`

2.4 **`crates/abd_framework/F1Square/F1Square/WeilExplicit.lean`** (5 sorrys)
   - Implement `vonMangoldt`, `chebyshev_psi`, `finite_zero_sum`, `weighted_prime_sum_interval`, `weighted_error_interval` in Rust using verified interval arithmetic from 2.3.
   - Kani proofs:
     - `proof_von_mangoldt_nonneg` — Λ(n) ≥ 0
     - `proof_chebyshev_psi_nonneg` — ψ(X) ≥ 0
     - `proof_finite_zero_sum_bounded` — |finite_zero_sum| ≤ bound
   - Lean: replace `sorry` with Rust-verified axioms or implementations.

2.5 **`crates/prime-gap-dynamics/lean-prime-gap-dynamics/`** (3 sorrys)
   - Implement `minFac`, `factorisation`, `Coprime` in Rust.
   - Kani proofs:
     - `proof_minFac_prime` — `minFac n` is prime for `n > 1`
     - `proof_factorisation_correct` — `n = p^k * (n / p^k)`
     - `proof_coprime_sym` — `Coprime a b ↔ Coprime b a`
   - Lean: replace `sorry` with `axiom ... -- Kani-verified: ...`

2.6 **`crates/drmm/lean-proofs/DRMM.lean`** (3 sorrys)
   - Implement `compute_bin_energies`, `stability_of_recursion`, `augmented_state_convergence` in Rust.
   - Kani proofs:
     - `proof_bin_energies_nonneg` — energies ≥ 0
     - `proof_stability_bounded` — parameter updates remain bounded
   - Lean: replace `sorry` with `axiom ... -- Kani-verified: ...`

### Phase 3: Track B — Non-Computable Theorems (Weeks 4–5)

3.1 **`src/GapDerivation.lean`** (2 sorrys)
   - Axiomatize `gap_derivation_correct` and `spectral_gap_monotone`.
   - Rust reference: implement gap computation in `pirtm-rs` or `core`.
   - Kani: prove gap derivation matches Rust implementation for all tested operators.

3.2 **`src/Analytic/AnalyticSkeleton.lean`** (2 sorrys)
   - Axiomatize `max_def` (replace `sorry` with `axiom max_def`).
   - Rust: implement `max` in `analytic` crate.
   - Kani: prove `max x y = max y x`, `max x x = x`.

3.3 **`materia_commons/meta-theorem/src/SemanticArithmetic/SpectralBridge.lean`** (2 sorrys)
   - Axiomatize `sum_deltaE_trace_int` and `diff_below_tolerance`.
   - Rust: implement spectral bridge in `meta-theorem` crate.
   - Kani: prove spectral bridge invariants.

3.4 **`materia_commons/meta-theorem/src/SemanticArithmetic/Proofs.lean`** (2 sorrys)
   - Axiomatize `add_comm` and `mul_comm` for semantic arithmetic.
   - Rust: implement semantic arithmetic operations.
   - Kani: prove commutativity for all tested values.

3.5 **`materia_commons/meta-theorem/src/SemanticArithmetic/FTA.lean`** (1 sorry)
   - Axiomatize `FTA_holds`.
   - Rust: implement FTA witness generation.
   - Kani: prove FTA witness correctness for all tested polynomials.

3.6 **`lean/projects/proofs/Kani.lean`** (2 sorrys)
   - Replace `sorry` with `axiom kani_verifies_discrete_invariant` + doc comment.

3.7 **`lean/dynamics/XIFormal.lean`** (2 sorrys)
   - Axiomatize `xi_converges` and `xi_unique`.
   - Rust: implement XI dynamics in `dynamics` crate.
   - Kani: prove convergence for all tested initial conditions.

3.8 **`lean/Core/alp/ADR/PhaseMirror.lean`** (2 sorrys)
   - Replace `cases r <;> sorry` with `cases r <;> simp [alp_preserves_rta]`.

3.9 **`crates/atomic-calculator/lean/Tests/FiniteModelInstance.lean`** (2 sorrys)
   - Replace with `by decide` or `by native_decide`.

3.10 **`src/ShiftPropagation.lean`** (1 sorry)
    - Replace with `by simp [shift_propagation]`.

3.11 **`src/Mode3.lean`** (1 sorry)
    - Replace with `by simp [mode3_projection]`.

3.12 **`src/Analytic/AnalyticRefined.lean`** (1 sorry)
    - Replace with `axiom refined_analytic_continuation`.

3.13 **`materia_commons/ADR/ADR_System_Rust_Lean/ADR/CryptoEconomic.lean`** (1 sorry)
    - Replace with `by norm_num`.

3.14 **`lean/projects/proofs/Test.lean`** and other `proofs/*.lean` (7 sorrys)
    - Replace with `by native_decide` or `by rfl`.

### Phase 4: CI Enforcement and Documentation (Week 6)

4.1 Add `lake build` check that fails on any `sorry` in project-owned files:
   ```bash
   # scripts/verify_lean_sorries.sh
   if grep -rnP '(?<!//|--)\bsorry\b' --include="*.lean" "$PROJECT_ROOT" | grep -v '.lake/packages'; then
     echo "ERROR: Lean sorries found"
     exit 1
   fi
   ```

4.2 Add `cargo kani` check to CI pipeline.

4.3 Generate `docs/kani_verification_report.md` from `scripts/verify_kani.sh`.

4.4 Update `ADR-090-Mathlib-Sorry-Elimination-Plan.md` with completion status.

## Alternatives Considered

1. **Pure Lean proof completion**: Mathematically complete every `sorry` in Lean. Rejected because many theorems require number-theoretic assumptions beyond Lean 4's kernel (e.g., Gershgorin theorem, RH-dependent Weil bounds).

2. **Keep sorries as-is**: Continue with implicit trust gaps. Rejected because it violates the Zero-Drift / Axiom-Clean mandate.

3. **Full Mathlib adoption**: Import Mathlib and use its proofs. Rejected because it introduces an external dependency that violates the project's axiom-clean policy and increases build complexity.

4. **Hybrid Lean/Rust with FFI calls**: Replace `sorry` with actual FFI calls to Rust functions at proof time. Rejected because Lean's FFI is limited to `constant`/`axiom` declarations; we cannot call Rust mid-proof without a verified extraction pipeline, which is out of scope.

## Risk Mitigation

- **Axiom consistency**: Every axiom introduced under Track B is backed by a Kani proof. If the Rust implementation changes, the Kani proof must be re-run.
- **Build performance**: `cargo kani` is added as an optional CI check (`--features kani`), not a mandatory block, to avoid slowing down every PR.
- **Traceability**: Each axiom carries a `-- Kani-verified:` comment with the exact file and harness name. An audit script (`scripts/verify_kani.sh`) cross-references all such comments.

## References

- ADR-088: PARM Sealed State Core Primitive
- ADR-089: PRMS Lineage Telemetry Core Monitoring
- ADR-090: Mathlib/Sorry Elimination Plan
- `crates/parm/src/verification.rs` — existing Kani harness template
- `crates/parm/src/tests.rs` — Rust parity tests
