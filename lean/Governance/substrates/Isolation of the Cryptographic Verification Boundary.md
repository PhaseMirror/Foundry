# Isolation of the Cryptographic Verification Boundary

**Note: This architectural concept has been expanded into a production-grade Architecture Decision Record. See [ADR-008: Isolation of the Cryptographic Verification Boundary](ADR-008-Cryptographic-Verification-Boundary.md) for the latest specification.**

## Executive Summary

The structural refactoring addresses the single-horizon perimeter trust vulnerability by decoupling the schema-signing key material from the active orchestration layer. The solution implements an isolated verification boundary (HSM or independent enclave) using a 2-of-3 threshold signature protocol and monotonic sequence counters to prevent replay attacks.

## Key Mechanisms

1.  **Enclave Gating:** Signing is deferred to an out-of-band enclave. The bridge (`sexpr_to_lean.py`) requires a detached cryptographic manifest signature ($S_{\text{threshold}}$).
2.  **Anti-Replay Invariants:** A monotonic counter is embedded in every signed schema. Lean 4 verification logic in `MOC/Core.lean` enforces `sequence > last_verified_sequence`.
3.  **Zero-Trust Bridge:** The translation bridge is treated as an un-trusted parser. It cannot emit Lean AST unless the manifest hash matches the threshold signature.

## Reference

- [ADR-008: Isolation of the Cryptographic Verification Boundary](ADR-008-Cryptographic-Verification-Boundary.md)
- [MOC Core Invariants (Lean 4)](../lean/MOC/Core.lean)
- [Bridge Gating Logic (Python)](../bridge/sexpr_to_lean.py)

<!-- LawfulRecursionVersion:1.0 -->
