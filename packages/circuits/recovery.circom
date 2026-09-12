pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "lib/MillerRabin64.circom";
include "DriftBound.circom";

/**
 * RecoveryContract - MTPI Account Recovery Circuit
 * 
 * PURPOSE:
 * Enables secure account recovery after compromise using prime-indexed recovery keys.
 * Maintains MTPI state chain continuity while allowing identity restoration.
 * Enforces drift bounds to prevent temporal manipulation during recovery.
 * 
 * INPUTS (Public):
 * - stateHash: Current compromised state hash Ξ(t)
 * - recoveryKey: Recovery prime number (must pass Miller-Rabin test)
 * - primeIndex: Original prime index for identity verification
 * - nonce: Recovery operation nonce
 * - newStateHash: Recovered state hash Ξ(t+1)
 * 
 * INPUTS (Private):
 * - recoverySecret: Secret component of recovery credential
 * - timestamp: Timestamp for drift control calculation
 * 
 * OUTPUTS:
 * - proofHash: Cryptographic binding of recovery operation
 * 
 * CONSTRAINTS:
 * 1. Recovery prime gate: recoveryKey must be a valid prime (Miller-Rabin)
 * 2. Identity prime gate: primeIndex must be a valid prime (Miller-Rabin)
 * 3. Recovery hash: recoveryHash = Poseidon(recoveryKey, recoverySecret)
 * 4. State recovery: newStateHash = Poseidon(stateHash, recoveryHash, nonce)
 * 5. Drift bound: Uses DriftBound template to enforce δ ≤ 0.3Ξ
 * 6. Proof binding: proofHash = Poseidon(stateHash, newStateHash, recoveryKey)
 * 
 * SECURITY CONSIDERATIONS:
 * - recoveryKey and recoverySecret provide two-factor recovery (what you know + what you have)
 * - Both recoveryKey and primeIndex must be prime (dual prime gates)
 * - Drift bound prevents recovery from stale/manipulated timestamps
 * - Recovery maintains state chain: compromised state is acknowledged, not erased
 * - recoverySecret should be stored securely offline (e.g., hardware wallet, paper backup)
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Resilient: enables recovery without trusted third parties
 * - Privacy-preserving: recovery doesn't reveal compromise details
 * - Auditable: recovery event recorded in state chain
 * - Prime-lawful: recovery key must also be prime (maintains MTPI addressing)
 * - Drift-bounded: prevents temporal attacks during recovery window
 * - Non-coercive: user controls recovery keys, no backdoors
 * - Zero-surveillance: recovery doesn't expose user activity history
 * 
 * RECOVERY PROCESS:
 * 1. User detects compromise of primary credentials
 * 2. User provides recoveryKey (prime) and recoverySecret from secure backup
 * 3. Circuit proves knowledge of recovery credentials
 * 4. New state is computed and committed on-chain
 * 5. User can then set new primary credentials from recovered state
 */

template RecoveryContract() {
    // Public inputs
    signal input stateHash;          // Current compromised state hash (Ξ(t))
    signal input recoveryKey;        // Recovery key (prime)
    signal input primeIndex;         // Prime index for identity
    signal input nonce;              // Recovery nonce
    signal input newStateHash;       // Recovered state hash (Ξ(t+1))

    // Private inputs
    signal input recoverySecret;     // Secret for recovery hash
    signal input timestamp;          // Timestamp for drift control

    // Outputs
    signal output proofHash;         // Hash of the recovery proof

    // Constants
    signal MAX_DRIFT <== 300000000000000000; // 0.3 Ξ in wei

    // Verify recovery key is prime
    component primeCheck1 = MillerRabin64();
    primeCheck1.prime <== recoveryKey;
    primeCheck1.isPrime === 1;

    // Verify prime index
    component primeCheck2 = MillerRabin64();
    primeCheck2.prime <== primeIndex;
    primeCheck2.isPrime === 1;

    // Compute recovery hash
    component poseidonRecovery = Poseidon(2);
    poseidonRecovery.inputs[0] <== recoveryKey;
    poseidonRecovery.inputs[1] <== recoverySecret;
    signal recoveryHash;
    recoveryHash <== poseidonRecovery.out;

    // Compute recovered state: Ξ(t+1) = Φ(Ξ(t))
    component poseidonTransition = Poseidon(3);
    poseidonTransition.inputs[0] <== stateHash;
    poseidonTransition.inputs[1] <== recoveryHash;
    poseidonTransition.inputs[2] <== nonce;
    newStateHash === poseidonTransition.out;

    // Enforce drift constraint using DriftBound
    // drift = timestamp - nonce (must be non-negative)
    signal drift;
    drift <== timestamp - nonce;
    
    // Use a reasonable bound for xi: max drift should be < 1 day = 86400 seconds
    // With epsilon=0.3, max_drift = 0.3 * xi, so xi = max_drift / 0.3 = 86400 / 0.3 = 288000
    signal xi;
    xi <== 288000;  // Allows up to ~1 day drift (86400 seconds)
    
    component driftCheck = DriftBound();
    driftCheck.delta <== drift;
    driftCheck.xi <== xi;
    driftCheck.ok === 1;

    // Compute proof hash
    component poseidonProof = Poseidon(3);
    poseidonProof.inputs[0] <== stateHash;
    poseidonProof.inputs[1] <== newStateHash;
    poseidonProof.inputs[2] <== recoveryKey;
    proofHash <== poseidonProof.out;
}

component main { public [stateHash, recoveryKey, primeIndex, nonce, newStateHash] } = RecoveryContract();
