# ADR-045: PWEH Runtime Attestation and Merkle Leaf Serialization

**Status:** Ratified
**Date:** 2026-06-30
**Owner:** L0 Substrate + PWEH Maintainers

## Context
The prior hybrid audit ledger utilized generic state hashes, which exposed an attestation window gap due to the non-associativity of operators and prime-constrained metadata. Disallowed moves were considered "self-disqualifying," but physical execution of forbidden primes or recursion depth $\beta > \beta_{\max}$ remained possible, lacking an internal L0-style invariant that blocks the transition directly.

Furthermore, policy manifolds ($\pi \in \Pi$) and their signed roots ($R_\pi$) may not remain stable over decade-scale horizons. Rapid policy evolution or root compromise could create attestation windows the hash chain cannot close by itself.

## Decision
To close this gap, PWEH $S_{\text{integrity}}(t)$ will be integrated as a canonical, prefix-committing checkpoint. We replace generic state hashes in the hybrid audit ledger with the triple:
$(S_{\text{integrity}}(t),\; \text{CRMF contraction certificate},\; \Lambda_m\text{-modulated resonance score})$

**Formal Extension (as applied to L0 Substrate Core ADRs):**
> L0 Substrate now serializes PWEH integrity updates as prime-indexed Merkle leaves under the existing $\Pi_{\text{CSL}} \circ P_E$ projector.

## Metrics & Enforcement
- **Verification Threshold:** End-to-end verification of any $10^5$-step prefix completes in $\leq 150$ ms on reference hardware.
- **Drift Tolerance:** False-negative drift detection rate $\leq 10^{-6}$ under Monte-Carlo policy-violation injection.
- **Formal Verification:** All new lemmas must be Lean-extracted and axiom-audited before being merged into the L0 execution bound.
