# ΛProof Contracts

On-chain ΛProof verifiers and related MTPI contracts for zero-knowledge proof verification on Ethereum-compatible networks.

## Overview

This directory contains Solidity smart contracts that implement the on-chain verification side of the ΛProof pattern:

- **Verifier contracts** – Generated from zk circuits, these verify ΛProof proofs on-chain
- **MTPI Core contracts** – Core protocol logic for prime-indexed identity and state management
- **ΛRootContract** – Foundational contract enforcing lawful recursion and entropy bounds
- **CSL contracts** – Conscious Sovereignty Layer for ethical, consent-bound execution
- **Registry contracts** – On-chain registries for attestations, devices, policies, and governance

## Key Contracts

- `MTPI_Core.sol` – Main protocol contract
- `verifier/` – Circuit-specific verifier contracts
- `Poseidon.sol` – Hash function for identity commitments
- `Recovery.sol` – Silent recovery and drift control
- `Governance.sol` – Protocol governance and access control

## Verification Flow

All ΛProof contracts follow the standard verification flow:

1. Proof generated locally by the user
2. Proof verified locally before submission
3. Proof submitted on-chain for final verification
4. State transition executed only if proof is valid

This ensures that users always know if their proof will succeed before paying gas fees.
