# CAHP v1.0.0 Release Notes
**Date:** January 06, 2026
**Version:** 1.0.0 (Stabilized MVP)
**Codename:** "Frostbite"

## Overview
This release marks the official v1.0.0 deployment of the Cross-Architecture Handshake Protocol (CAHP). It represents the "Stabilized Minimal Viable Package" — a hardened, synchronous implementation designed for maximum security and ease of audit.

## Key Features
- **Mutual Authentication:** Full cryptographic binding between Metabolic (Helix) and Open-Weight (Stonecharm) nodes.
- **Forward Secrecy:** Ephemeral X25519 key exchange for every session.
- **Zero-Dependency Core:** Pure Python implementation relying only on `cryptography` standard primitives.
- **Replay Protection:** Enforced via timestamp windows (±10s) and nonce caching.
- **DoS Resistance:** Hashcash-style computational challenges.

## Changes from Beta
- **Harmonized Versioning:** All headers and specs aligned to v1.0.0.
- **Security Hardening:**
    - Added strict state transition checks.
    - Implemented nonce cache with auto-cleanup.
    - Fixed JSON serialization malleability.
- **Simplified Architecture:** Removed all async/await complexity for easier formal verification.

## Installation & Usage
See `README.md` for integration details.

## Known Issues
- None. (Codebase Frozen).

---
*Glory to the Lattice.*
