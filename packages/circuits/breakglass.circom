// SPDX-License-Identifier: UNLICENSED
/**
 * BreakGlassCircuit - Emergency Override Access Proof
 * 
 * PURPOSE:
 * Proves authorized emergency access override with cryptographic auditability.
 * Implements "break-glass" pattern for urgent care scenarios where normal
 * consent workflows cannot be completed. Creates tamper-evident audit trail.
 * 
 * INPUTS (Public - in fixed order):
 * 0. reason_code: Policy-defined emergency reason code (e.g., 1=cardiac, 2=trauma, 3=stroke)
 * 1. provider_pk: Emergency provider's public key/address
 * 2. timebound: Epoch timestamp until which override is valid
 * 3. case_commitment: Poseidon commitment to incident details
 * 4. bg_nullifier: Nullifier binding provider to this specific case
 * 
 * INPUTS (Private):
 * - incident_id_hash: Hashed incident/case identifier (no PHI)
 * - bg_secret: Per-case secret held by provider or patient wallet
 * 
 * CONSTRAINTS:
 * 1. Reason bounds: reason_code < 2^16
 * 2. Timebound bounds: timebound < 2^64
 * 3. Case commitment: case_commitment = Poseidon(incident_id_hash, reason_code, timebound)
 * 4. Nullifier derivation: bg_nullifier = Poseidon(
 *      Poseidon(bg_secret, provider_pk),
 *      case_commitment
 *    )
 * 
 * SECURITY CONSIDERATIONS:
 * - Emergency access must be audited: nullifier creates immutable record
 * - Timebound limits scope of override (not indefinite access)
 * - reason_code must map to approved emergency scenarios (checked on-chain)
 * - incident_id_hash provides case linkage without revealing PHI
 * - bg_secret can be issued to authorized override personnel only
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Emergency-safe: enables urgent care while maintaining privacy
 * - Auditable: all break-glass events cryptographically logged
 * - Time-limited: override expires automatically via timebound
 * - Accountable: provider_pk and nullifier enable after-action review
 * - Non-coercive: patient can review break-glass audit log
 * - Zero-surveillance: incident_id_hash prevents case tracking
 * - Lawful: reason_code binds to policy compliance rules
 * 
 * NOTES:
 * - Break-glass events should trigger patient notification
 * - Timebound enforcement must be checked on-chain at verification time
 * - reason_code must reference documented emergency policy
 * - Consider multi-signature requirements for high-risk reason codes
 */

pragma circom 2.1.6;
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template P2() { signal input a; signal input b; signal output out; component p = Poseidon(2); p.inputs[0] <== a; p.inputs[1] <== b; out <== p.out; }

template P3() { signal input a; signal input b; signal input c; signal output out; component p = Poseidon(3); p.inputs[0] <== a; p.inputs[1] <== b; p.inputs[2] <== c; out <== p.out; }

template BreakGlassCircuit() {
    // Public inputs
    signal input reason_code;
    signal input provider_pk;
    signal input timebound;
    signal input case_commitment;
    signal input bg_nullifier;

    // Private inputs
    signal input incident_id_hash;
    signal input bg_secret;

    // Bounds
    component rbits = Num2Bits(16); rbits.in <== reason_code;
    component tbits = Num2Bits(64); tbits.in <== timebound;

    // case_commitment = H(incident_id_hash, reason_code, timebound)
    component hC = P3();
    hC.a <== incident_id_hash;
    hC.b <== reason_code;
    hC.c <== timebound;
    hC.out === case_commitment;

    // bg_nullifier = H(bg_secret, provider_pk, case_commitment)
    component hN1 = P2();
    hN1.a <== bg_secret;
    hN1.b <== provider_pk;

    component hN = P2();
    hN.a <== hN1.out;
    hN.b <== case_commitment;

    hN.out === bg_nullifier;
}

component main { public [reason_code, provider_pk, timebound, case_commitment, bg_nullifier] } = BreakGlassCircuit();
