# ADR-046: ZK Matrix Constraints & Arithmetic Circuit Widening

**Status:** Proposed  
**Date:** 2026-06-16  
**Owner:** Substrates  

## Context

The current `agios-ingress-spine` implementation normalizes FHIR JSON observations into a fixed-width $N=100$ array to fit the `SafeNecessityProjector` witness template. While optimal for basic clinical scenarios, this constraint is insufficient for high-density clinical telemetry (such as multi-channel EEG or genomic sequences) which requires up to $N=1000$ points. Increasing the matrix constraints requires unsealing the R1CS circuit specifications without introducing side-channel vulnerabilities or violating the ~4.98s prove time floor.

## Decision

We commit to widening the ZK circuit inputs by updating the `SafeNecessityProjector` constants and R1CS matrix constraints:
1. **Dynamic Scaling Range**: Update `CIRCUIT_WIDTH` from `100` to a target width of `1000` to support dense clinical datasets.
2. **Fixed-Point Modulus Checks**: Maintain the $10^6$ decimal scaling factor while integrating overflow assertions during witness generation to prevent finite field wrap-around vulnerabilities.
3. **Multi-Scalar Multiplication (MSM)**: Leverage parallel MSM algorithms in the proving system to ensure the expanded R1CS constraints do not cause prove times to exceed the ADR-035 threshold.

This maps to the `Ξ-Constitutional-Core` mandate by maintaining mathematical precision bounds under scale.

## Consequences

- **Security Posture**: Enhances data-integrity gates. Prevents parameter truncation errors that could lead to misdiagnoses in clinical observations.
- **Performance**: Proving time for 1M rows increases by an estimated 12%, but is kept within the 4.98s limit using multi-threaded proving pipelines.
- **Compliance**: Satisfies **45 CFR §164.312(c)(1) (Integrity)**.

## Verification Plan

We will verify this in the test harness:
1. **Scaled Witness Test**: Feed observation vectors of length 1000 and confirm correct quantization and field mapping.
2. **Boundary Overflow Test**: Input values that exceed field modulus limits and verify that the quantization engine throws an error instead of producing wrapping field elements.
