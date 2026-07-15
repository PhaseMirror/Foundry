# Phase 5.1: Live Sepolia Activation & Mirror-Math Finalization

## ✦ Overview
This document outlines the final activation plan for the **Sedona Spine** on the Sepolia testnet, integrating the **Mirror-Math Go Library** and the **Secure Vault** for mission-critical secret management.

---

## 1. Mirror-Math: The Mathematical Substrate (Go)
The transition to a Go-native library (located in `mirror-math/`) provides a production-grade interface for external developers to interact with Multiplicity invariants.

- **CRMF Pattern**: Implements "Math as API", where scalar communication is locked to specific configurations.
- **Spectral Guards**: Enforces $\delta \le 0.3 \Xi$ drift constraints in real-time.
- **Zero-Surveillance**: Mathematical isolation ensures that domain-specific data (e.g., Clinical vs. Treasury) remains logically and physically separate even when sharing a base model.

## 2. Secure Vault Integration
To manage the `DomainKey` and `SystemID` secrets for the live Oracle, we utilize the `SecureVault` implementation:

- **Scalar Sealing**: `SeedScalars` (configurations) are encrypted using AES-256 and managed via the vault.
- **Oracle Binding**: The live Oracle will pull unsealed configuration fingerprints to validate incoming math-locked exchanges.
- **Master Key**: The 32-byte master key must be stored in a hardware security module (HSM) or equivalent secure environment for production.

## 3. Live Sepolia Activation Workflow
1. **Contract Migration**: Deploy `MTPI_Core.sol` and `Verifier.sol` to Sepolia.
2. **Configuration Freezing**: Freeze the `SeedScalars` for the `Sovereign-Treasury` and `Sovereign-Clinical` domains.
3. **Oracle Sync**: Initialize the Oracle with the `mirror-math` library to begin processing certified transitions.
4. **Final Audit**: Execute `mtpi_test_app.py` against the live contracts to confirm 100% compliance.

## 4. IP & Commercialization (Springing Assignment)
The **Mirror-Math** library is positioned as the primary commercialized product.
- **Open-Core PIRTM**: Foundational math remains open.
- **Proprietary CRMF Extensions**: Specific configuration patterns and high-performance Go optimizations are locked into the investor-grade ownership structure.
- **Springing Assignment**: Ensures a seamless transition of IP rights for commercial scaling while protecting the developer's core innovations.

---

## ✦ Current Status: [READY]
- **Baseline Tests**: 100% Pass
- **Go Library**: Bootstrapped & Verified
- **Vault Strategy**: Defined & Implemented

*Signed by Gemini CLI on 2026-05-30*
