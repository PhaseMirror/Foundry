# ADR 006: RegHom Clonal Selection Registry Architecture

## Status
**Proposed**

## Context
In the genomic analogy of the AGI Immune System (ADR-005), **Clonal Selection** ensures that only registered, lawful morphisms ($\phi$) are selected for cross-domain state transitions. The `RegHom` registry serves as the active memory of "Adaptive Immunity." 

Before the Goldilocks Kernel executes a cross-domain transition ($p_{src} \neq p_{tgt}$) via the SUBLEQ prime gate, it must verify the existence of a corresponding morphism in `RegHom`. The system requires a production-grade pipeline to safely manage the registry lifecycle—ensuring $O(1)$ response times while enforcing mathematically verified governed bridge amendments.

## Architecture & Decisions

### 1. Data Structure & O(1) Lookup
The `RegHom` registry will be implemented as a deterministic, prime-indexed Key-Value store mapped in the Rust kernel memory.
*   **Key**: Tuple of `(src_prime: u32, tgt_prime: u32)`
*   **Value**: `MorphismRecord`

### 2. MorphismRecord Schema
To ensure immutability and compliance, each record must contain:
*   `lam_certificate`: The pre-verified $\Lambda_m$-stability certificate hash.
*   `merkle_root`: The CRMF-integrated anchor for the higher-order RSL 6-language proof.
*   `crypto_anchors`: Dual signatures (SHA-256 + Ed25519) proving the amendment was ratified by the Constitutional Quorum.
*   `expiration_tick`: A Lambda-Proof / Archivum `Tick` defining the time-weaponized validity boundary.

### 3. Governed Bridge Amendment (Write-Path)
The registry is **append-only/update-only** via governed bridge amendments.
*   **Trigger**: A cross-domain rejection rate indicating the need for a new legitimate pathway.
*   **Validation**: The proposed morphism must pass the `higher_order_RSL(\phi) = true` proof in Lean 4.
*   **Insertion**: If proven mathematically sound and contractive, the morphism is written to `RegHom` and a CRMF `PolicyAmendment` record is emitted. *Crucially, the amendment packet itself must pass the `jubilee_admissible` check to ensure quorum synchronization.*

## Engineering Pipeline

*   **Phase 1: Rust Scaffolding**
    *   Implement the `RegHom` Hash Map in `goldilocks_kernel/reg_hom_manager.rs`.
    *   Implement the $O(1)$ `reg_hom_lookup` function.
*   **Phase 2: Lean 4 Proof Verification Interface**
    *   Construct the FFI bridge allowing the Rust kernel to ingest verified `.olean` artifacts for the `lam_certificate` check before registry insertion.
*   **Phase 3: Time-Weaponized Pruning**
    *   Integrate the Lambda-Proof / Archivum `Tick` from the Jubilee coordination window to prune or invalidate morphisms where `current_tick > expiration_tick`.
