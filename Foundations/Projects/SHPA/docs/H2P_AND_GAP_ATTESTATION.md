# Project SHPA: Hash-to-Prime Protocol & Succinct Gap Attestation

This document specifies the step-by-step protocol for stateless prime assignment, offset pinning, and verification.

---

## 1. Prover Protocol

1. **Serialize Operator:** Compute $\sigma(o) = \text{BCS}(o)$ and $h = \text{SHA256}(\sigma(o))$.
2. **Derive Seed:** Convert $h$ into 256-bit odd integer $N$.
3. **Incremental Search & Witness Collection:**
   - Iterate $k = 0, 2, 4, \dots$ until $N + k$ is prime.
   - For each composite candidate $N + \ell$ ($\ell < k$), record a compositeness witness $w_\ell$ (e.g. non-trivial divisor).
4. **Commitment & Manifest:**
   - Compute witness commitment root: $\text{Root} = \text{SHA256}(\text{WitnessVector})$.
   - Construct execution manifest $\{ h, \sigma(o), N, k, p = N+k, \text{Root}, W \}$.

---

## 2. Verifier Protocol ($O(1)$ Complexity)

1. **Recompute Seed:** $N = g(h)$ and check $p = N + k$.
2. **Primality Test:** Run deterministic Baillie-PSW / Miller-Rabin primality test on $p$.
3. **Commitment Check:** Recompute witness root from $W$ and verify equality with claimed $\text{Root}$.
4. **Offset Bound Check:** Verify $k \le 65,536$.
5. **Accept / Reject:** Accept if and only if all checks pass.
