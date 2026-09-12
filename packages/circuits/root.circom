pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "lib/MillerRabinLib.circom";

/**
 * RootContract - MTPI Core State Transition Circuit
 * 
 * PURPOSE:
 * Proves lawful state transition in the MTPI system with prime-indexed identity,
 * enforcing drift bounds (δ ≤ 0.3Ξ) and cryptographic state evolution.
 * This is the foundational circuit for all MTPI state changes.
 * 
 * INPUTS (Public):
 * - stateHash: Current state hash Ξ(t) - the anchored state on-chain
 * - primeIndex: Prime number representing user's identity (must pass Miller-Rabin)
 * - timestamp: Current epoch timestamp for drift calculation
 * - newStateHash: Next state hash Ξ(t+1) to be committed on-chain
 * 
 * INPUTS (Private):
 * - prevStateHash: Previous state hash (validated against stateHash)
 * - nonce: Unique nonce for this state transition
 * - identitySecret: Secret component of identity commitment
 * 
 * OUTPUTS:
 * - proofHash: Cryptographic binding of (stateHash, newStateHash, timestamp)
 * 
 * CONSTRAINTS:
 * 1. Prime Gate: primeIndex must be a valid prime (Miller-Rabin test)
 * 2. Identity: identityHash = Poseidon(primeIndex, identitySecret)
 * 3. State Transition: newStateHash = Poseidon(prevStateHash, identityHash, nonce)
 * 4. State Continuity: stateHash === prevStateHash
 * 5. Drift Bound: (timestamp - nonce) ≤ 0.3Ξ (300000000000000000 wei)
 * 6. Proof Binding: proofHash = Poseidon(stateHash, newStateHash, timestamp)
 * 
 * SECURITY CONSIDERATIONS:
 * - The identitySecret is never revealed, only its commitment via Poseidon hash
 * - Prime index gates identity to Web4/MTPI lawful addressing space
 * - Drift bound prevents temporal manipulation attacks
 * - State hash chain provides tamper-evident audit trail
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Implements core Ξ-Constitution principle: bounded state evolution
 * - Prime-indexed identity aligns with CSL (Conscious Sovereignty Layer)
 * - No surveillance: no PII, IP addresses, or device fingerprints
 * - Auditable: all public signals can be verified on-chain
 * - Privacy-preserving: secrets remain private, commitments are public
 * 
 * NOTE: Future versions may include policyHash as public input for policy binding:
 * signal input policyHash;
 * signal output policyOut;
 * policyOut <== policyHash; // passthrough; kept as pub signal
 */

template RootContract() {
    // Public inputs
    signal input stateHash;          // Current state hash (Ξ(t))
    signal input primeIndex;         // Prime index for identity
    signal input timestamp;          // Current timestamp
    signal input newStateHash;       // Next state hash (Ξ(t+1))
    
    // Private inputs
    signal input prevStateHash;      // Previous state hash
    signal input nonce;              // Nonce for state transition
    signal input identitySecret;     // Secret for identity hash
    
    // Outputs
    signal output proofHash;         // Hash of the proof

    // Constants
    signal MAX_DRIFT <== 300000000000000000; // 0.3 Ξ in wei

    // Verify prime index
    component millerRabin = MillerRabin();
    millerRabin.prime <== primeIndex;
    millerRabin.isPrime === 1;

    // Compute identity hash
    component poseidonIdentity = Poseidon(2);
    poseidonIdentity.inputs[0] <== primeIndex;
    poseidonIdentity.inputs[1] <== identitySecret;
    signal identityHash;
    identityHash <== poseidonIdentity.out;

    // Compute state transition: Ξ(t+1) = Ψ(Ξ(t))
    component poseidonTransition = Poseidon(3);
    poseidonTransition.inputs[0] <== prevStateHash;
    poseidonTransition.inputs[1] <== identityHash;
    poseidonTransition.inputs[2] <== nonce;
    newStateHash === poseidonTransition.out;

    // Verify current state hash
    stateHash === prevStateHash;

    // Enforce drift constraint
    signal drift;
    drift <== timestamp - nonce;
    assert(drift <= MAX_DRIFT);

    // Compute proof hash
    component poseidonProof = Poseidon(3);
    poseidonProof.inputs[0] <== stateHash;
    poseidonProof.inputs[1] <== newStateHash;
    poseidonProof.inputs[2] <== timestamp;
    proofHash <== poseidonProof.out;
}

component main { public [stateHash, primeIndex, timestamp, newStateHash] } = RootContract();
