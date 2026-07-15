# Specification: Federated Trust and Identity

## 1. Overview
This document defines the identity standards and trust mechanisms for the Phase Mirror federation network.

## 2. Identity Requirements (Phase-In Horizon: 90 Days)

### 2.1 Minimum Credential Standard: ML-DSA-65
To ensure long-term security against quantum-computing vectors, all network participants (third-party agents and aggregators) **must** adopt ML-DSA-65 as their primary identity credential standard.

- **Standard:** ML-DSA-65 (NIST FIPS 204)
- **Identity Framework:** SPIFFE/SVID
- **Status:** REQUIRED for new participants; MANDATORY UPGRADE for existing participants.

### 2.2 Transitional Mechanism: HMAC-Based Trust
Existing trust relationships established via HMAC (nonce binding) are valid for a transitional period of **180 days** from 2026-04-22.

- **Status:** DEPRECATED
- **Deprecation Horizon:** 2026-10-19

## 3. Enforcement
The `org-scan` Lambda and federation aggregator will begin rejecting non-ML-DSA-65 credentials after the deprecation horizon.
Evidence of identity standard compliance is a mandatory field in the `agent-registry.json`.
