# MTPI Circuit Test Suite

This directory contains comprehensive tests for all Zero-Knowledge circuits in the MTPI/Web4 system.

## Overview

The test suite validates circuit correctness, constraint enforcement, and edge case handling for:
- **Main Circuits**: root, recovery, consent, attestation, prescription, eligibility, breakglass, research_consent, device_attest, data_pointer
- **Library Components**: MillerRabin, MillerRabin64, DriftBound, PrimeCheck

## Running Tests

### All Tests
```bash
pnpm run circuits:test
```

### Individual Circuit
```bash
node circuits/root.test.js
node circuits/consent.test.js
```

### Quick Test (subset)
```bash
pnpm run circuits:test:quick
```

## Test Structure

Each test file follows this pattern:

```javascript
// 1. Setup: Load circuit artifacts
const circuit = await wasm_tester(circuitPath);

// 2. Valid input tests (happy path)
const validInput = { /* ... */ };
const witness = await circuit.calculateWitness(validInput);
await circuit.checkConstraints(witness);

// 3. Constraint violation tests (should fail)
const invalidInput = { /* ... */ };
try {
  await circuit.calculateWitness(invalidInput);
  // Should not reach here
} catch (err) {
  // Expected failure
}

// 4. Edge cases
// Test boundary values, zero inputs, maximum values, etc.
```

## Test Dependencies

- **circom**: Circuit compiler (v2.1.6)
- **snarkjs**: zk-SNARK JavaScript library
- **circomlibjs**: JavaScript utilities for circomlib
- **circom_tester**: Test harness for circom circuits
- **mocha**: Test framework
- **chai**: Assertion library (optional)

All dependencies are managed via pnpm workspace.

## Test Principles (MTPI/Web4 Aligned)

### 1. No PHI in Tests
- Use synthetic, non-identifiable data only
- Hash all pseudo-identifiers before using in tests
- Never use real patient data, even for "realistic" tests

### 2. Privacy Verification
- Verify private inputs are not leaked in public signals
- Check nullifiers are properly derived and unique
- Ensure commitments hide underlying secrets

### 3. Constraint Coverage
- Test all arithmetic constraints
- Verify range checks (bit decomposition)
- Test cryptographic primitives (Poseidon hashes)
- Validate prime gates (Miller-Rabin)
- Check drift bounds

### 4. Auditable Test Cases
- Clear test descriptions
- Expected behavior documented inline
- Failure modes explicitly tested
- Edge cases comprehensively covered

### 5. Zero-Surveillance
- No test telemetry or external reporting
- No test data uploaded to third parties
- Local-only test execution

## Circuit-Specific Test Coverage

### RootContract (root.test.js)
- ✓ Valid state transition
- ✓ Prime index validation (Miller-Rabin)
- ✓ Identity hash computation
- ✓ State continuity check
- ✓ Drift bound enforcement
- ✓ Proof hash binding
- ✗ Invalid prime (composite number)
- ✗ Drift exceeds bound
- ✗ State hash mismatch

### ConsentCircuit (consent.test.js)
- ✓ Valid consent with expiry check
- ✓ Purpose ID bounds (< 2^32)
- ✓ Commitment structure
- ✓ Nullifier derivation
- ✓ Optional Merkle membership (USE_ROOT=1)
- ✗ Expired consent (now > expiry)
- ✗ Invalid commitment
- ✗ Merkle proof failure

### AttestationCircuit (attestation.test.js)
- ✓ Valid attestation with receipt
- ✓ Timestamp bounds (< 2^64)
- ✓ Nullifier = Poseidon(receipt_secret, attestation_digest)
- ✗ Invalid nullifier

### PrescriptionCircuit (prescription.test.js)
- ✓ Valid dispense (fills_used < max_fills)
- ✓ Multi-fill tracking
- ✓ Prescription commitment
- ✓ Per-pharmacy nullifier
- ✗ Exceed fill limit
- ✗ Invalid commitment

### EligibilityCircuit (eligibility.test.js)
- ✓ Valid eligibility check
- ✓ CPT code bounds (< 2^16)
- ✓ Coverage class bounds (< 2^8)
- ✓ Commitment and nullifier
- ✗ Out-of-bounds codes

### BreakGlassCircuit (breakglass.test.js)
- ✓ Valid emergency override
- ✓ Reason code bounds (< 2^16)
- ✓ Timebound bounds (< 2^64)
- ✓ Case commitment
- ✓ Nullifier binding
- ✗ Invalid commitment

### RecoveryContract (recovery.test.js)
- ✓ Valid recovery with dual prime gates
- ✓ Recovery hash computation
- ✓ State recovery transition
- ✓ Drift bound check
- ✗ Invalid recovery key (composite)
- ✗ Drift exceeds bound

### ResearchConsentCircuit (research_consent.test.js)
- ✓ Valid research participation
- ✓ Study ID bounds (< 2^32)
- ✓ Commitment structure
- ✓ Period-based nullifier
- ✗ Out-of-bounds study ID

### DeviceAttestCircuit (device_attest.test.js)
- ✓ Valid telemetry with range proofs
- ✓ Metric bounds enforcement (min ≤ value ≤ max)
- ✓ Metric folding
- ✓ Device root binding
- ✗ Metric out of range
- ✗ Invalid bounds (min > max)

### DataPointerCircuit (data_pointer.test.js)
- ✓ Valid FHIR pointer
- ✓ Purpose ID bounds (< 2^32)
- ✓ Resource type bounds (< 2^16)
- ✓ Pointer commitment
- ✗ Out-of-bounds codes

### MillerRabin64 (millerRabin64.test.js)
- ✓ Known primes (2, 3, 5, 7, 11, 13, ...)
- ✓ Small primes (< 100)
- ✓ Medium primes (100-1000)
- ✗ Known composites (4, 6, 8, 9, 10, ...)
- ✗ Carmichael numbers (if applicable)

### DriftBound (driftBound.test.js)
- ✓ Valid drift (δ ≤ 0.3·ξ)
- ✓ Boundary case (δ = 0.3·ξ exactly)
- ✓ Zero drift (δ = 0)
- ✗ Excessive drift (δ > 0.3·ξ)

## Test Files Status

| Circuit | Test File | Status |
|---------|-----------|--------|
| root.circom | root.test.js | ✓ Complete |
| consent.circom | consent.test.js | ✓ Complete |
| attestation.circom | attestation.test.js | ✓ Complete |
| MillerRabin64.circom | millerRabin64.test.js | ✓ Complete |
| prescription.circom | prescription.test.js | ⚠ Template |
|  |  | Note: Foundry/contract tests now use precomputed prescription fixtures when present at `packages/mtpi-contracts/test/fixtures/prescription_proof.json` (falls back to mock verifier when missing). |
| eligibility.circom | eligibility.test.js | ⚠ Template |
| breakglass.circom | breakglass.test.js | ⚠ Template |
| recovery.circom | recovery.test.js | ⚠ Template |
| research_consent.circom | research_consent.test.js | ⚠ Template |
| device_attest.circom | device_attest.test.js | ⚠ Template |
| data_pointer.circom | data_pointer.test.js | ⚠ Template |
| DriftBound.circom | driftBound.test.js | ⚠ Template |
| PrimeCheck.circom | primeCheck.test.js | ⚠ Template |

⚠ Template tests follow the established pattern and can be expanded with additional test cases as needed.

## Adding New Tests

When adding a new circuit or test:

1. **Create test file**: `circuits/<circuit-name>.test.js`
2. **Follow template**: Use existing tests as reference
3. **Add to test runner**: Update `circuits/run-tests.js`
4. **Document coverage**: Update this README
5. **Verify MTPI alignment**: Ensure no PHI, no surveillance, auditable

## Test Artifacts

Generated during testing:
- `circuits/test/.cache/`: Compiled circuit artifacts (gitignored)
- `circuits/test/logs/`: Test execution logs (gitignored)

These should NOT be committed to version control.

## Continuous Integration

Tests run automatically on:
- Pull requests (all circuits)
- Main branch commits (all circuits)
- Release tags (full test suite + smoke tests)

## Troubleshooting

### "PTau file not found"
```bash
pnpm run ptau:fetch
```

### "Circuit compilation failed"
```bash
pnpm run circuits:build
```

### "Out of memory"
- Reduce circuit size or test batch
- Use `--max-old-space-size=4096` Node flag
- Run tests individually instead of all at once

### "circom_tester not found"
```bash
pnpm add -D circom_tester mocha chai
```

## References

- [Circom Documentation](https://docs.circom.io/)
- [snarkjs Guide](https://github.com/iden3/snarkjs)
- [circomlib Reference](https://github.com/iden3/circomlib)
- [MTPI RootContract Specification](../docs/MTPI%20RootContract.pdf)

## License

SPDX-License-Identifier: UNLICENSED
