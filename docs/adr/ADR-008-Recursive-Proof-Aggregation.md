# ADR-008: Recursive Proof Aggregation (Batch ZK Proofs)

## Status
Accepted

## Context
The Universal Atomic Calculator (UAC) architecture enforces a strict 5,087-constraint R1CS budget per individual FeMoco run proof (`attestation.circom`). As throughput demands scale (enabled by predictive thermal load management), verifying individual proofs on-chain per run limits scalability and incurs prohibitive gas costs.

To maintain the constraint budget per simulation while amortizing verification costs, we require a recursive batching sidecar that aggregates multiple $N$ individual proofs into a single verifiable proof.

## Decision
We will introduce a "Layer 2" sidecar to perform batch recursive aggregation using **Halo2 (Rust)** on the BN254 curve.

1. **Base Layer Constraints**: `attestation.circom` remains locked at 5,087 constraints.
2. **Sidecar Aggregation**: The sidecar accumulates $N$ individual Groth16 proofs and their public inputs.
3. **Halo2 Recursion Circuit**:
   - The circuit will internally verify the $N$ constituent Groth16 pairings.
   - It will reconstruct the Merkle root of the batch from the underlying pre-image metadata (`BatchRunData`).
   - The public input (Instance) to the Halo2 circuit will solely be the `batchMerkleRoot`.
4. **On-Chain L1 Contract**: `AttestationRegistry.sol` provides `submitBatchAttestation` to verify the single recursive Halo2 proof. To guarantee Data Availability, the sidecar posts the raw `BatchRunData[]` array on-chain, and the EVM reconstructs and matches the `batchMerkleRoot`.
5. **Formal Verification**: The state-transition bounds of the batching strategy are modeled in `Contracts.lean` (`submitBatchAttestation`), proving the zero-sorry invariant that nullifier updates across a batch preserve the replay protection semantic.

## Consequences
- **Positive**: We achieve $O(1)$ on-chain verification gas relative to the batch size.
- **Positive**: The 5,087-constraint invariant of the L1 Sedona Spine is preserved.
- **Negative**: Adds Rust/Halo2 proving complexity to the sidecar deployment.

## Public Input Structure (Halo2 Circuit)
The circuit will expose exactly 1 public input (instance column):
- `batchMerkleRoot`: A 256-bit scalar (split into limbs or passed as native BN254 scalar if within field capacity) representing the Keccak256 or Poseidon root of the `BatchRunData[]` list.
