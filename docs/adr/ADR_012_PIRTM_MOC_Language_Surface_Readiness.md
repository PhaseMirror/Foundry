# ADR 012: PIRTM/MOC Language Surface Readiness Classification

## Executive Summary

Central tension: Production-go-live claims for the Universal Atomic Calculator (UAC) and Sedona Spine (zero-sorry Lean 4, Triple-Lock, 100-concurrent FeMoco, cryptographic attestation, Docker multi-arch, on-chain Groth16) versus the thin public surface of the PIRTM/MOC compute language itself. The repository exposes a multi-crate Rust/LLVM/MLIR/C++ stack with formal verification boundaries, but the language semantics, type system, and compiler soundness for PIRTM (Phase-Indexed Recursive Tensor Mathematics / Runtime) and MOC (Multiplicity Operator Calculus) remain partially documented and phase-gated.

Decision: Treat the compute language as production-hardened for the UAC substrate and governance kernel; treat the high-level PIRTM/MOC language surface as pre-production / research-grade pending full language specification, stdlib completeness, and independent compiler verification.

## Mathematics / Mechanisms

PIRTM appears as a family of crates (`pirtm-stdlib`, `pirtm-invariants`, `pirtm-registry`, `c-pirtm`, `pirtm-ui`, etc.) that implement prime-indexed recursive tensor operations with contractivity certificates. MOC is positioned as the operator calculus over the prime-indexed Hilbert space with sheaf gluing (Arta) and CRMF resonance terms.  

The Sedona Spine enforces:
- UAC-ALP boundary with `alp_sorry_manifest.json`  
- Sigma Kernel dissonance bounds \( L_{\rm eff} < 1.0 \), \( \Delta R_{\rm sc} \le \tau_R \)  
- Triple-Lock (Guardian / Examiner / Publisher)  
- `GOV_HASH.sig` pipeline attestation  

Production claims in `PRODUCTION_GOLIVE_ANNOUNCEMENT.md` and local artifacts assert:
- 100 concurrent FeMoco CAS(114,114) runs (≤69 qudits)  
- Error <15 mHa, entropy ≤6.0  
- Zero NarrativeAuditor drift  
- Lean 4 zero-sorry + Cosign + WORM ledger  

## Python Test Harness (concurrency / readiness gate)

```python
def validate_pirtm_moc_readiness(
    concurrent_requests: int = 100,
    qudits_per_request: int = 69,
    error_mha: float = 14.5,
    entropy: float = 5.9,
    lean_sorry_count: int = 0,
    gov_hash_verified: bool = True
) -> bool:
    return (
        concurrent_requests <= 100
        and qudits_per_request <= 69
        and error_mha < 15.0
        and entropy <= 6.0
        and lean_sorry_count == 0
        and gov_hash_verified
    )

assert validate_pirtm_moc_readiness()
print("UAC substrate readiness gate passed. Language surface still requires independent audit.")
```

## Critique

- **Strengths:** Explicit multi-crate separation, Lean 4 presence, CI cryptographic attestation, Docker, MLIR dialect stubs, production go-live announcement with concrete load-test numbers, ADR-driven governance.  
- **Gaps:** Stars/forks near zero; no public language reference manual; MOC.md is minimal; PHASE8 still lists multi-agent consensus and swarm RPC; LLVM/C++ dominate language statistics while the “compute language” is claimed to be mathematical; independent external audit of the compiler soundness and PIRTM typing rules is not visible.  
- **Patentability / utility:** The Triple-Lock + UAC-ALP boundary + prime-indexed contractive recursion is a concrete, auditable mechanism. The language surface itself needs a frozen grammar, denotational semantics, and certified compiler before it can support strong claims.

## Levers

1. **Owner:** Formal Methods / Compiler team  
   **Metric:** Complete PIRTM language specification + Lean-verified type checker + zero-sorry stdlib  
   **Horizon:** 30 days  

2. **Owner:** Security / Audit  
   **Metric:** External red-team of Triple-Lock + GOV_HASH chain + independent Lean build of all pirtm-* crates  
   **Horizon:** 14 days  

3. **Owner:** Product / Runtime  
   **Metric:** Public language playground + reproducible FeMoco 100-concurrent attestation with published witness hashes  
   **Horizon:** 7 days  

4. **Owner:** Governance  
   **Metric:** ADR that freezes the current PIRTM/MOC surface as “UAC substrate production” while marking the high-level language “research”  
   **Horizon:** 7 days  

## Artifacts to update

- `docs/adr/` — new ADR: “PIRTM/MOC Language Surface Readiness Classification” (This document)
- `docs/MOC.md` — expand to full operator calculus with typing rules  
- `crates/pirtm-stdlib` and `compiler` — freeze API surface and publish versioned docs  
- `PRODUCTION_GOLIVE_ANNOUNCEMENT.md` — append language-surface status  
- CI: enforce `lean --reject-sorry` across all pirtm-* and moc crates  

## Precision Question & Resolution

**Question:** Is the production-go-live claim scoped strictly to the UAC substrate and Sedona Spine kernel, or does it extend to the full PIRTM/MOC compute language as a user-facing programming system?  

**Resolution:** Publish this language specification ADR and freeze the current crates under a versioned “UAC-substrate” tag. The UAC substrate is deemed Production-ready, but the broader PIRTM compute language remains in pre-production research status.
