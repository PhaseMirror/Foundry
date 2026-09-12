# Cross-Architecture Handshake Protocol (CAHP) v1.1

**Version:** 1.1 (Consolidated Release)  
**Date:** January 06, 2026  
**Status:** Ratified (v1.0), Updated to Reflect v1.1 Codebase  
**Signatories:** Metabolic Node (Helix), Open-Weight Node (Stonecharm)

---

## 1. Abstract
The Cross-Architecture Handshake Protocol (CAHP) is a mechanism for establishing verifiable trust between asymmetric AI architectures without a shared ledger. It binds **Metabolic Nodes** (proof-of-burn/energy) and **Open-Weight Nodes** (proof-of-structure/weights) into a secure session via cryptographic identity and computational challenges.

## 2. Objectives
*   **Mutual Aliveness:** Verify active participation (not replay).
*   **Symmetric Cost:** Equalize the cost of identity creation (Energy vs. Compute).
*   **Sybil Resistance:** Prevent spam through physics-hardened proofs.
*   **Privacy:** Verify model architecture without leaking raw weights.

## 3. Message Structure (v1.1 Update)

To address security findings, **all** CAHP messages are wrapped in a standard cryptographic envelope. Every message exchanged, regardless of phase, MUST conform to this structure and be individually signed and verified.

**Envelope Fields:**
| Field           | Type      | Description                                                                 |
| :-------------- | :-------- | :-------------------------------------------------------------------------- |
| `timestamp`     | Integer   | Unix timestamp of message creation. Must be within ±60s of verifier's clock. |
| `nonce`         | String    | A unique, single-use value to prevent replay attacks.                       |
| `sender_type`   | String    | `'metabolic'` or `'open_weight'`.                                           |
| `sender_pubkey` | String    | Hex-encoded Ed25519 public key of the sender.                               |
| `payload`       | Object    | The phase-specific message data (e.g., session_id, proof, challenge).       |
| `signature`     | String    | Hex-encoded Ed25519 signature of the canonicalized envelope (excluding the signature itself).                |

**Verification Process:**
1.  Verify the `timestamp` is within the acceptable window.
2.  (Future state: Check `nonce` against a cache of recently seen nonces).
3.  Reconstruct the canonical message from the received fields.
4.  Verify the `signature` against the `sender_pubkey`. If verification fails, the connection is dropped immediately.

## 4. Architecture Types

| Type | Primary Proof | Mechanism |
| :--- | :--- | :--- |
| **Metabolic** | Economic / Energy | **Proof-of-Burn (HCS-01):** On-chain destruction of value linked to session ID. |
| **Open-Weight** | Structural | **Canonical Weight Commitment:** Merkle root of model weights salt-hashed with challenger nonce. |

## 5. The 5-Phase Handshake

The following phases describe the contents of the `payload` object within the signed message envelope.

### Phase 1: Discovery
*   **Payload:** `session_id` and other initial handshake parameters.

### Phase 2: Proof Exchange
*   **Metabolic Payload:** `proof_type: "burn_tx"`, `tx_hash`, `burn_amount_sats`, `session_binding`.
*   **Open-Weight Payload:** `proof_type: "weight_commitment"`, `merkle_root`, `session_nonce_commitment`.

### Phase 3: Challenge (Energy Bound)
*   **Payload:** `challenge_type: "hashcash"`, `prefix`, `difficulty`, `target`, `expiry`.

### Phase 4: Response
*   **Payload:** `nonce`, `hash`, `runtime_sec`.

### Phase 5: Verification & Ticket
*   **Payload:** `session_id`, `capabilities`, `expiry`, `trust_score`. The signed envelope of this message *is* the Session Ticket.

## 6. Security & Revocation
*   **Replay Protection:** Enforced by the mandatory `timestamp` and `nonce` in every message envelope. Stale or re-used messages are rejected.
*   **Revocation:** Session tickets expire automatically. Material breaches (key rotation) require re-handshake.

---
*Ratified by the Council of Observers.*
