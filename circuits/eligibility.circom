// SPDX-License-Identifier: UNLICENSED
/**
 * EligibilityCircuit - Privacy-Preserving Insurance Eligibility Proof
 * 
 * PURPOSE:
 * Proves insurance coverage eligibility for a procedure without revealing
 * member identity or full plan details. Prevents duplicate claim tokens via nullifiers.
 * 
 * INPUTS (Public - in fixed order):
 * 0. payer_pk: Insurance payer's public key/address (uint160→uint256 as field)
 * 1. cpt_code: Current Procedural Terminology code for procedure
 * 2. coverage_class: Coverage tier/class (0-7, e.g., gold=0, silver=1, bronze=2)
 * 3. cost_share_hash: Poseidon hash of cost-sharing details (deductible, copay, coinsurance)
 * 4. eligibility_commitment: Poseidon commitment to eligibility credential
 * 5. eligibility_nullifier: Per-procedure nullifier to prevent duplicate claims
 * 
 * INPUTS (Private):
 * - member_secret: Member-held secret scalar (identity commitment)
 * 
 * CONSTRAINTS:
 * 1. CPT bounds: cpt_code < 2^16
 * 2. Coverage tier bounds: coverage_class < 2^8
 * 3. Eligibility commitment structure:
 *    eligibility_commitment = Poseidon(
 *      Poseidon(payer_pk, cpt_code, coverage_class),
 *      Poseidon(cost_share_hash, member_secret)
 *    )
 * 4. Nullifier derivation: eligibility_nullifier = Poseidon(member_secret, cpt_code)
 * 
 * SECURITY CONSIDERATIONS:
 * - No PHI in public signals: only plan codes and commitments
 * - member_secret links to patient but is never revealed
 * - Nullifier is per-procedure: prevents duplicate claim token issuance
 * - cost_share_hash hides exact out-of-pocket amounts
 * - Payer can verify eligibility without learning member identity
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-preserving: member identity is cryptographically committed
 * - Auditable: eligibility can be verified on-chain without PHI access
 * - Non-coercive: member controls secret, can choose not to claim
 * - Zero-surveillance: no cross-payer tracking of member claims
 * - Supports Web4 eligibility receipts: nullifier prevents replay
 * - Fair: coverage_class and cost_share_hash are verifiable but private
 */

pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";      // Num2Bits

// Poseidon helpers
template P2() { signal input a; signal input b; signal output out; component p = Poseidon(2); p.inputs[0] <== a; p.inputs[1] <== b; out <== p.out; }

template P3() { signal input a; signal input b; signal input c; signal output out; component p = Poseidon(3); p.inputs[0] <== a; p.inputs[1] <== b; p.inputs[2] <== c; out <== p.out; }

template EligibilityCircuit() {
    // Public
    signal input payer_pk;
    signal input cpt_code;
    signal input coverage_class;
    signal input cost_share_hash;
    signal input eligibility_commitment;
    signal input eligibility_nullifier;

    // Private
    signal input member_secret;

    // Bounds for small integers
    component cptBits = Num2Bits(16); cptBits.in <== cpt_code;
    component tierBits = Num2Bits(8); tierBits.in <== coverage_class;

    // commitment tree
    component hPCC = P3(); hPCC.a <== payer_pk; hPCC.b <== cpt_code; hPCC.c <== coverage_class;
    component hCHS = P2(); hCHS.a <== cost_share_hash; hCHS.b <== member_secret;

    component hC = P2();
    hC.a <== hPCC.out;
    hC.b <== hCHS.out;

    // enforce commitment
    hC.out === eligibility_commitment;

    // nullifier per code
    component hN = P2();
    hN.a <== member_secret;
    hN.b <== cpt_code;
    hN.out === eligibility_nullifier;
}

component main { public [payer_pk, cpt_code, coverage_class, cost_share_hash, eligibility_commitment, eligibility_nullifier] } = EligibilityCircuit();
