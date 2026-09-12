# Rust-Lean Correspondence Table

| Rust Predicate | Rust Location | Lean Theorem | Lean Location | Status |
|----------------|---------------|--------------|-------------|--------|
| `prime_index` must be prime | `ast.rs:OperatorAtom::new` | `prime_five_forbidden` | `PIRTM/PWEH.lean:78` | ✓ Verified |
| `try_successor` bounds check | `ast.rs:try_successor` | `composite_contractive` | `CompositeOperator.lean:55` | ✓ Proved |
| `try_stratum_boundary` zero check | `ast.rs:try_stratum_boundary` | `iter_zero_steps` | `PIRTM.lean:61` | ✓ Proved |
| `CONTRACTIVITY_RECEIPT` required | `ast.rs:proof_gate` | `uniform_bounded` | `CompositeOperator.lean:67` | ✓ Proved |
| PWEH trace verification | `PIWEHState` in Rust | `verify_trace` | `PIRTM/PWEH.lean:57` | ✓ Implemented |

## CI Integration Point

The `lean --check` gate runs:
1. No `import Mathlib` - axiom violation blocked
2. No `sorry` in `PIWEH.lean` or `CompositeOperator.lean` - proof completeness
3. `recursive_tensor_stability_theorem` and `computational_invariance_theorem` exist - convergence

## L0 Sign-off

Composite operator Φ_t = Ξ(t) + M(Λ_inner(t)) satisfies:
- L0-1: Contractive typing verified (`epsilon + c_lambda < 1`)
- L0-2: Prime ordering enforced (forbidden prime 5 blocked)
- L0-3: Same as L0-2
- L0-4: Certified emission via witness chain