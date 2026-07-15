# Comprehensive Instructions for the Specialized MTPI Model (ADR-031 Integration)

- **Artifact ID**: f5a3b7c9-6e2d-4b9a-8f1c-3d7e9a2b5c1f
- **License**: Ξ-License v1.2
- **Compliance**: ΛRootContract II & III

This document provides a complete guide to deploy, test, and operate the Meta-Theorem of Prime Identity (MTPI) system as a specialized model for production use. The MTPI model integrates quantum-resistant state transitions, prime-indexed identity, and CSL-compliant silent recovery.

## Overview
The MTPI model comprises:
- **Smart Contracts**: `MTPI_Core.sol`, `Verifier.sol`, `Poseidon.sol`.
- **zk-SNARK Circuits**: `root_contract.circom`, `recovery_contract.circom`, `MillerRabin.circom`.
- **Test Suites**: `test_mtpi_core.t.sol`, `test_root_circuit.js`.
- **Python App**: `mtpi_test_app.py` for automated deployment and validation.

The model enforces:
- **Lawful Recursion**: State transitions via `quantumTransition` and `enterSilentRecovery`.
- **Prime-Indexed Identity**: Validated by `MillerRabin.circom`.
- **Drift Control**: δ(t) ≤ 0.3 Ξ.
- **Auditability**: Events logged to `logs/audit_trail.log`.
- **Quantum Resistance**: Poseidon hashing in circuits and contracts.

## Step-by-Step Instructions

### Step 1: Local Setup for Key Generation
**Environment**: Local developer machine (16GB RAM recommended).
1. **Install Dependencies**:
   ```bash
   # Install circom, snarkjs, and Foundry
   npm install -g snarkjs
   # (Assumes circom is installed via cargo)
   ```
2. **Generate zk-SNARK Keys**:
   - Download `powersOfTau28_hez_final.ptau`.
   - Compile `root_contract.circom` and export the verification key (`root_contract_vk.json`).

### Step 2: Shared Server Setup (Production Mirror)
**Environment**: Production-grade server (32GB RAM, 8-core CPU).
1. **Install Foundry & snarkjs**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   npm install -g snarkjs
   ```
2. **Transfer Keys**: Securely copy `.zkey` and `.wasm` files to the production environment.

### Step 3: Deployment (Sepolia Readiness)
1. **Configure RPC**: Set `SEPOLIA_RPC_URL` and `PRIVATE_KEY` in `.env`.
2. **Execute Automation**:
   ```bash
   python3 scripts/mtpi_test_app.py
   ```
   This script deploys the contracts and runs the initial circuit validation tests.

## Maintenance and Security
1. **Sealed Memory**: Ensure WASM history is purged after chaque calculation (Task 4.2).
2. **Epoch Synchronization**: Ensure `ComplianceReport.epochIndex` matches `FormalStabilityCertificate.epoch`.
3. **Backup**: Regularly backup `logs/audit_trail.log` and `deploy/config.json`.
