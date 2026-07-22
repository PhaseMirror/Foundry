# Kani Coverage Report

## Harnesses

| Harness | File | Property Verified | Status |
|---------|------|-------------------|--------|
| `verify_composition_preserved` | kani_proofs.rs | If x ∘_p y = z, then Comp(x,y) ~ z | ✅ |
| `verify_congruence_closure` | kani_proofs.rs | If a ~ b, then Close(a) ~ Close(b) | ✅ |
| `verify_termination` | kani_proofs.rs | complete() terminates without panic | ✅ |
| `verify_associator_bounded` | kani_proofs.rs | Associator defect is non-negative and bounded | ✅ |
| `verify_blockade_enforced` | kani_proofs.rs | Rydberg blockade prevents unlawful compositions | ✅ |
| `verify_union_find_no_panic` | kani_proofs.rs | Union-Find operations never panic | ✅ |
| `verify_no_index_out_of_bounds` | kani_proofs.rs | Array indices always within bounds | ✅ |

## Bounds

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| MAX_TERMS | 32 | Covers all realistic partial systems |
| MAX_QUBITS | 4 | Covers small quantum circuits |
| Kani unwind | 1025 | Sufficient for all loop bounds |

## Coverage Summary

- **Total harnesses**: 7
- **Passing**: 7/7
- **Properties verified**: 7
- **Panic freedom**: Verified for all core operations
- **Index bounds**: Verified for all array accesses
