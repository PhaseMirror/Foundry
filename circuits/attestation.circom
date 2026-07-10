// SPDX-License-Identifier: UNLICENSED
/**
 * AttestationCircuit - Clinical Data Attestation with Receipt Proof
 * 
 * PURPOSE:
 * Proves patient possession of a receipt secret linked to a clinical attestation
 * (e.g., FHIR Bundle digest) without revealing the receipt secret itself.
 * Links to consent framework via consent_commitment.
 * 
 * INPUTS (Public - in fixed order):
 * 0. attestation_digest: Poseidon hash of FHIR Bundle or clinical document
 * 1. provider_pk: Provider's public key/address (as field element, uint160→uint256)
 * 2. timestamp_epoch: Attestation timestamp (Unix epoch seconds)
 * 3. consent_commitment: Reference to associated consent proof
 * 4. attestation_nullifier: Poseidon(receipt_secret, attestation_digest)
 * 
 * INPUTS (Private):
 * - receipt_secret: Secret scalar held by patient, issued with attestation
 * 
 * CONSTRAINTS:
 * 1. Timestamp bounds: timestamp_epoch < 2^64 (enforced via bit decomposition)
 * 2. Nullifier derivation: attestation_nullifier = Poseidon(receipt_secret, attestation_digest)
 * 
 * SECURITY CONSIDERATIONS:
 * - Signature verification (ECDSA) happens on-chain, not in-circuit
 * - Consent validity checked separately via consent proof circuit
 * - This circuit only proves possession of receipt_secret, not authorization
 * - No PHI in public signals: only hashes and addresses
 * - receipt_secret acts as bearer token for attestation access
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-preserving: receipt_secret never revealed, only commitment
 * - Linkable to consent: consent_commitment binds this to authorization
 * - Auditable: on-chain verifier validates proof structure
 * - Non-coercive: patient can choose not to prove (no forced disclosure)
 * - Zero-surveillance: no behavioral tracking or device fingerprinting
 * 
 * NOTES:
 * - ECDSA signature on attestation_digest verified on-chain (not in ZK)
 * - Consent must be verified separately via ConsentCircuit
 * - This circuit establishes cryptographic link between patient and attestation
 * - receipt_secret should be derived deterministically or stored securely
 */

pragma circom 2.1.6;
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom"; // Num2Bits

// Poseidon(2)
template Poseidon2() {
    signal input a;
    signal input b;
    signal output out;
    component p = Poseidon(2);
    p.inputs[0] <== a;
    p.inputs[1] <== b;
    out <== p.out;
}

template AttestationCircuit() {
    // Public inputs
    signal input attestation_digest;
    signal input provider_pk;
    signal input timestamp_epoch;
    signal input consent_commitment;
    signal input attestation_nullifier;

    // Private input
    signal input receipt_secret;

    // Bounds
    component tbits = Num2Bits(64); // timestamp bound
    tbits.in <== timestamp_epoch;

    // Nullifier = Poseidon(receipt_secret, attestation_digest)
    component hN = Poseidon2();
    hN.a <== receipt_secret;
    hN.b <== attestation_digest;
    hN.out === attestation_nullifier;
}

component main { public [attestation_digest, provider_pk, timestamp_epoch, consent_commitment, attestation_nullifier] } = AttestationCircuit();
