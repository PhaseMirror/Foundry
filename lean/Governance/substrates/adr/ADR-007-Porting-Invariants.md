# ADR-007: MOC v2 Porting Invariants & Structural Hardening

## Status
Proposed (Ratified by Architecture Audit)

## Context
The Multiplicity Operator Calculus (MOC) version 2 transition introduced a dual-layer architecture (Common Lisp frontend, Lean 4 verified core). An architecture audit identified a critical gap between Lisp's syntactic expressivity and Lean's constructive determinism, specifically regarding the primality of subdivisions and resonance stability.

## Decisions

### 1. Parameterized Prime Restriction (Schema-Driven)
The `MOC.Operator` and related core structures are now parameterized by a `MOC.Schema`. The subdivision and permutation operators use a dependently-typed `PermittedPrime` structure that requires a proof of membership in the schema's prime set.

**Refinement:** The previous static-only path (restricting to $\{2, 3\}$ at the type level) is **deprecated**. Operational multiplicity is now achieved by loading a cryptographically signed `extended` schema that can broaden the permitted prime set (e.g., to include $\{5, 7, 11\}$) without requiring re-certification of the base library code.

**Governance:** Zero-drift attestation is enforced in CI by validating the S-expression against the intended schema before Lean AST emission.

### 2. 108-Cycle Architecture Anchor
The system anchors on a $108 = 2^2 \cdot 3^3$ cycle structure for ternary-first phrasing validation. 

### 3. Static Bridge Validation
The `sexpr_to_lean.py` bridge includes mandatory structural guards:
- Validation of prime bases before emitting Lean AST.
- Warning/Error checks for total dimension alignment against the 108-cycle target.

### 4. Mandatory Resonance Verification
The CI/Justfile pipeline requires a numerical resonance check (`tests/numerical_verification.py`) to pass before any Lean verification is attempted. This ensures $R = (R_1, R_2, R_3)$ stays within the "Attested Convergence Envelope" (ACE).

## Consequences
- **Security:** Absolute auditability of the prime-indexed transition matrix.
- **Reliability:** Zero-drift convergence metrics enforced by the pipeline.
- **Velocity:** Potential minor friction in CI due to increased verification rigour, offset by reduced runtime failures.

<!-- LawfulRecursionVersion:1.0 -->
