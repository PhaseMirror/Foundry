# MTPI Specification

## Purpose
`mtpi` (Multiplicity Prime Identity) serves as the core cryptographic identity and authentication substrate for PhaseSpace OS. It maps execution environments and trust chains into prime number topological identifiers.

## Core Components
1. **Identity Generator**: Cryptographically derives prime-based execution identities for system sub-components and external operators.
2. **ZK Proof Circuitry**: Employs Poseidon hashing and BN254 snarks to prove identity compliance without revealing core entropy.
3. **Certifier Guard**: Enforces compliance checks to ensure an identity token satisfies the Prime Verification Gate before it can be used to anchor a `UnifiedWitness` in the Archivum ledger.

## Invariants
- Identity generation must exclusively map to prime sequences.
- Nullifiers generated during state transitions must be uniquely deterministic per identity hash to prevent double-spending of computational resources.
- All structural validations must pass the Certifier logic before an external token is granted internal trust bounds.
