# ADR-0037: System Architecture & Toy Domain Isolation
### Production Specification (v5.5 / v6 Sealed Closure)

---

## 1. Non-Negotiable Scope Guard (§0)

The mathematical function $F_{10}(y, u) = 4y + u$ is a **bounded 1-D affine test fixture** in an abstract mathematical domain:
- It is strictly **not** a clinical operator, not a medical treatment function, and not a decision support model.
- **Strict Domain Isolation:** No type, namespace, comment, or telemetry label may import or reference `Patient`, `Clinical`, `Medicine`, or `treatment`.
- The only telemetry label permitted is `conc:10`, interpreted as a dimensionless integer in a toy evaluation space.

---

## 2. Layer Separation & Component Topology

```mermaid
graph TD
    subgraph Layer 1: Mathematical Map Separation
        F10[Expansive Operator F_10 y, u = 4y + u Lip = 4 on Z]
        FScaled[Scaled Operator F y, u = 0.4y + 0.1u Lip = 0.4 on Q]
    end

    subgraph Layer 2: Machine-Checked Proofs Lean 4
        Proof1[lip_F10 Theorem: Exact L = 4 Scaling]
        Proof2[F10_ignores_state: State Independence]
        Proof3[Pedersen Hiding Translation Bijection]
        Proof4[Pedersen Algebraic Collision Reduction]
        Proof1 --- Proof2
        Proof3 --- Proof4
    end

    subgraph Layer 3: Cryptographic Commitment BN254
        H_new[Generator H_new from try-and-increment hash-to-curve]
        Preimage[Preimage: n=1,0,0 | y_digest=conc:10 | ctx=pm-v3-audit]
        C_new[Commitment C_new = r G + v H_new]
        H_new --> C_new
        Preimage --> C_new
    end

    subgraph Layer 4: Runtime Monitor & Failure Policy
        Update[on update y, u: expected = 4y + u]
        Check{actual == expected?}
        Update --> Check
        Check -->|Yes| EmitNominal[Emit Event NOMINAL]
        Check -->|No| EmitViolation[Emit Event VIOLATED & Unseal]
    end

    subgraph Layer 5: Cross-Layer Merkle Binding
        Merkle[MerkleRoot = SHA256 C || Lean Artifacts || Preimage || Policy]
        C_new --> Merkle
        Proof1 --> Merkle
        Preimage --> Merkle
    end
```

---

## 3. Operational Invariants & Policies

1. **Lean Policy (PM-2):**
   - Verified with `lean -DautoImplicit=false`.
   - Zero Mathlib imports, zero `sorry`, zero `admit`, zero `native_decide`.
   - `#print axioms` must return `[]`.
2. **Pedersen Commitment Policy (PM-4):**
   - Generator $H_{\text{new}}$ is derived via try-and-increment without exposing any discrete logarithm scalar in repository code.
   - Perfectly hiding (information-theoretic) and computationally binding under the assumed hardness of ECDLP in $\mathbb{G}_1$ on BN254.
3. **Runtime Monitor Policy (PM-7):**
   - Asserts exact equality $y_{\text{next}} = 4y + u$; any discrepancy triggers state violation and forces unsealing.
