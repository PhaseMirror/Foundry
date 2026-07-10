// SPDX-License-Identifier: UNLICENSED
/**
 * ConsentCircuit - Privacy-Preserving Clinical Consent Proof
 * 
 * PURPOSE:
 * Proves patient consent for a specific clinical purpose without revealing PHI.
 * Supports optional Merkle tree membership for consent registries.
 * Enables single-use consent via nullifiers to prevent double-spending.
 * 
 * CIRCUIT PARAMETERS:
 * - DEPTH: Merkle tree depth (default: 32 levels)
 * - USE_ROOT: If 1, enforce Merkle membership; if 0, skip membership check
 * 
 * INPUTS (Public - in fixed order):
 * 0. purpose_id: Clinical purpose code (e.g., treatment=1, research=2, billing=3)
 * 1. scope_hash: Poseidon hash of allowed resource scopes (FHIR resource types)
 * 2. provider_pk: Provider's public key/address (as field element)
 * 3. patient_pk: Patient's public key/address (as field element)
 * 4. expiry_epoch: Consent expiration timestamp (Unix epoch seconds)
 * 5. now_epoch: Current timestamp provided by client
 * 6. delta_bound: Maximum allowed clock drift between client/server
 * 7. consent_commitment: Poseidon commitment to consent details + secret
 * 8. consent_root: Merkle root of consent registry (0 if USE_ROOT==0)
 * 9. nullifier: Poseidon(consent_secret, provider_pk) - prevents double-use
 * 
 * INPUTS (Private):
 * - consent_secret: Secret randomness binding this consent
 * - pathElements[DEPTH]: Merkle proof sibling hashes
 * - pathIndices[DEPTH]: Merkle proof path directions (0=left, 1=right)
 * 
 * CONSTRAINTS:
 * 1. Purpose bounds: purpose_id < 2^32 (enforced via bit decomposition)
 * 2. Temporal validity: now_epoch ≤ expiry_epoch (consent not expired)
 * 3. Commitment structure:
 *    consent_commitment = Poseidon(
 *      Poseidon(purpose_id, scope_hash),
 *      Poseidon(provider_pk, patient_pk),
 *      Poseidon(expiry_epoch, delta_bound),
 *      consent_secret
 *    )
 * 4. Nullifier derivation: nullifier = Poseidon(consent_secret, provider_pk)
 * 5. Optional Merkle membership: If USE_ROOT==1, prove consent_commitment ∈ consent_root
 * 
 * SECURITY CONSIDERATIONS:
 * - No PHI in public signals: only hashes, codes, and public keys
 * - Nullifier prevents consent replay attacks per provider
 * - Temporal bounds prevent use of expired consents
 * - Merkle tree enables efficient consent registry without revealing all consents
 * - consent_secret known only to patient, not derivable from public signals
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-first: patient identity is cryptographically committed, not revealed
 * - Auditable: on-chain verifier can check proof without accessing PHI
 * - Non-coercive: patient controls consent_secret, can revoke by not proving
 * - Zero-surveillance: no tracking pixels, session IDs, or device fingerprints
 * - Supports Web4 consent receipts: nullifier acts as tamper-evident receipt
 */

pragma circom 2.1.6;

// NOTE: Adjust include paths per your build. These are standard circomlib names.
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";     // LessThan
include "../node_modules/circomlib/circuits/bitify.circom";          // Num2Bits

// Simple Poseidon-2 input hash helper
template Poseidon2() {
    signal input a;
    signal input b;
    signal output out;
    component p = Poseidon(2);
    p.inputs[0] <== a;
    p.inputs[1] <== b;
    out <== p.out;
}

// Merkle check with Poseidon(2). Path index must be 0/1 bits.
template MerkleVerify(DEPTH) {
    signal input leaf;
    signal input root;
    signal input pathElements[DEPTH];
    signal input pathIndices[DEPTH];   // 0 = leaf on left, 1 = leaf on right

    var i;
    signal cur[DEPTH + 1];
    cur[0] <== leaf;

    component hL[DEPTH];
    component hR[DEPTH];

    for (i = 0; i < DEPTH; i++) {
        // enforce bitness of index
        pathIndices[i] * (1 - pathIndices[i]) === 0;

        hL[i] = Poseidon2();
        hR[i] = Poseidon2();
        // left = (idx==0 ? cur : pathElements[i])
        // right = (idx==0 ? pathElements[i] : cur)
        hL[i].a <== cur[i];
        hL[i].b <== pathElements[i];
        hR[i].a <== pathElements[i];
        hR[i].b <== cur[i];

        // cur = idx*hR + (1-idx)*hL
        cur[i + 1] <== pathIndices[i] * hR[i].out + (1 - pathIndices[i]) * hL[i].out;
    }

    // enforce final root match
    cur[DEPTH] === root;
}

// ConsentCircuit
// Parameters:
//  - DEPTH: Merkle tree depth
//  - USE_ROOT: if 1, enforce Merkle membership; if 0, require consent_root == 0 and skip membership
// Public signals order (match on-chain expectation):
// 0 purpose_id
// 1 scope_hash
// 2 provider_pk
// 3 patient_pk
// 4 expiry_epoch
// 5 now_epoch
// 6 delta_bound
// 7 consent_commitment
// 8 consent_root
// 9 nullifier

template ConsentCircuit(DEPTH, USE_ROOT) {
    // Public inputs
    signal input purpose_id;        // uint32 bound enforced via bit decomposition
    signal input scope_hash;
    signal input provider_pk;
    signal input patient_pk;
    signal input expiry_epoch;      // epoch seconds
    signal input now_epoch;         // epoch seconds supplied by client
    signal input delta_bound;       // allowed client/server drift bound (audited off-chain)
    signal input consent_commitment;
    signal input consent_root;      // 0 if USE_ROOT == 0; valid Merkle root if USE_ROOT == 1
    signal input nullifier;         // Poseidon(consent_secret, provider_pk)

    // Private witness
    signal input consent_secret;
    // Merkle path (ignored if USE_ROOT == 0)
    signal input pathElements[DEPTH];
    signal input pathIndices[DEPTH];

    // 1) purpose_id < 2^32
    component pbits = Num2Bits(32);
    pbits.in <== purpose_id;

    // 2) expiry check: now_epoch <= expiry_epoch
    // LessThan implements a < b. Use expiry+1 to simulate <=
    signal expiry_plus1;
    expiry_plus1 <== expiry_epoch + 1;
    component lt = LessThan(64);
    lt.in[0] <== now_epoch;
    lt.in[1] <== expiry_plus1;
    lt.out === 1;

    // 3) commitment = Poseidon( h(purpose,scope), h(provider,patient), h(expiry,delta), consent_secret )
    component hPS = Poseidon2();
    component hPP = Poseidon2();
    component hED = Poseidon2();
    hPS.a <== purpose_id;  hPS.b <== scope_hash;
    hPP.a <== provider_pk; hPP.b <== patient_pk;
    hED.a <== expiry_epoch; hED.b <== delta_bound;

    component h1 = Poseidon(4);
    h1.inputs[0] <== hPS.out;
    h1.inputs[1] <== hPP.out;
    h1.inputs[2] <== hED.out;
    h1.inputs[3] <== consent_secret;

    // enforce commitment
    h1.out === consent_commitment;

    // 4) nullifier = Poseidon(consent_secret, provider_pk)
    component hN = Poseidon2();
    hN.a <== consent_secret;
    hN.b <== provider_pk;
    hN.out === nullifier;

    // 5) optional Merkle membership
    if (USE_ROOT == 1) {
        component merkle = MerkleVerify(DEPTH);
        merkle.leaf <== consent_commitment;
        merkle.root <== consent_root;
        var i;
        for (i = 0; i < DEPTH; i++) {
            merkle.pathElements[i] <== pathElements[i];
            merkle.pathIndices[i] <== pathIndices[i];
        }
    } else {
        // lock root to 0 when not used
        consent_root === 0;
    }
}

component main { public [purpose_id, scope_hash, provider_pk, patient_pk, expiry_epoch, now_epoch, delta_bound, consent_commitment, consent_root, nullifier] } = ConsentCircuit(32, 0);

