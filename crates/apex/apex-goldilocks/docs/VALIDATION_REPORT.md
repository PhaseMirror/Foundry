# Apex-Goldilocks Validation Report

## 1. Abstract
This report verifies the structural and behavioral integrity of the standalone Rust Apex stack.

## 2. Results

### Phase 1: Rust Workspace Tests
- **Status**: PASS
```

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 2 tests
test boundary_lattice::tests::test_r96_distribution ... ok
test boundary_lattice::tests::test_lattice_tiling ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 3 tests
test test_aep_structure ... ok
test test_recursive_proof_chain ... ok
test test_hologram_phi_resolution ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 8 tests
test test_contraction_certificate ... ok
test test_mub_audit ... ok
test test_ledger_sha256 ... ok
test test_pi_index_grid ... ok
test test_projector_family_disjoint ... ok
test test_rns_crt ... ok
test test_weighted_l1_projection ... ok
test test_poseidon_educational ... ok

test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s


running 1 test
test tests::test_e8_root_system_properties ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 12 tests
test polynomial::tests::test_interpolate ... ok
test polynomial::tests::test_eval_poly ... ok
test sse::tests::test_sse_add ... ok
test sse::tests::test_sse_mul ... ok
test sse::tests::test_sse_sub ... ok
test polynomial::tests::test_ntt_intt_roundtrip ... ok
test sse::tests::test_sse_mul_edge_cases ... ok
test tests::test_add ... ok
test tests::test_inverse ... ok
test tests::test_mul ... ok
test sse::tests::test_sse_butterfly_differential ... ok
test sse::tests::test_sse_differential ... ok

test result: ok. 12 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.22s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 3 tests
test bridge::tests::test_validate_and_seal_inflation_veto ... ok
test bridge::tests::test_validate_and_seal_stable ... ok
test bridge::tests::test_validate_and_seal_unstable ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 1 test
test test_contractivity_fixtures ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 5 tests
test test_harness_budget_veto ... ok
test test_harness_echobraid_valid_flow ... ok
test test_harness_multiplicity_veto ... ok
test test_harness_prime_gate_veto ... ok
test test_harness_lattice_certified_adaptation ... ok

test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 1 test
test test_validate_source ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 3 tests
test test_spectral_radius_violation ... ok
test test_stability_violation ... ok
test test_successful_verification ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 2 tests
test crates/hologram-app/src/lib.rs - (line 22) ... ignored
test crates/hologram-app/src/lib.rs - (line 8) ... ignored

test result: ok. 0 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s


```

### Phase 2: Combinatorial Audit
- **Status**: PASS
```
Auditing 12,288 Boundary Lattice...
Total Elements: 12288
Orbit Sizes: [2048, 2048, 2048, 2048, 2048, 2048]
Free Action: true
Lattice Verification: PASSED

```

### Phase 3: ACE Stability
- **Status**: PASS
```
Verifying ACE Stability (PIRTM Phase C)...
Stability Check: PASSED

```

## 3. Conclusion
The stack is fully coherent and satisfies all L0 invariants.
