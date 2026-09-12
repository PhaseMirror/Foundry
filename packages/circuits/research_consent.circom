// SPDX-License-Identifier: UNLICENSED
/**
 * ResearchConsentCircuit - Privacy-Preserving Research Data Donation Proof
 * 
 * PURPOSE:
 * Proves participant consent for research data donation with anonymity budget tracking.
 * Enables privacy-preserving research participation while preventing exact replay.
 * Supports periodic/repeated donations via period_salt mechanism.
 * 
 * INPUTS (Public - in fixed order):
 * 0. study_id: Research study identifier (small integer)
 * 1. anonymity_budget_hash: Poseidon hash of privacy budget/policy tuple
 * 2. research_commitment: Poseidon commitment to study participation
 * 3. donation_nullifier: Per-period nullifier to prevent exact replay
 * 
 * INPUTS (Private):
 * - participant_secret: Participant-held secret scalar (identity commitment)
 * - period_salt: Per-period or per-donation salt (enables repeated participation)
 * 
 * CONSTRAINTS:
 * 1. Study ID bounds: study_id < 2^32
 * 2. Research commitment structure:
 *    research_commitment = Poseidon(study_id, anonymity_budget_hash, participant_secret)
 * 3. Donation nullifier derivation:
 *    donation_nullifier = Poseidon(
 *      participant_secret,
 *      Poseidon(study_id, period_salt)
 *    )
 * 
 * SECURITY CONSIDERATIONS:
 * - No PHI in public signals: only study codes and hashes
 * - anonymity_budget_hash defines privacy guarantees (k-anonymity, ℓ-diversity, etc.)
 * - Nullifier changes per period, allowing repeated participation
 * - participant_secret prevents cross-study linkability
 * - Budget accounting done off-chain, nullifier prevents on-chain replay only
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-first: participant identity never revealed, even to researchers
 * - Auditable: research ethics committees can verify compliance
 * - Non-coercive: participant controls secret, can withdraw by not proving
 * - Zero-surveillance: no cross-study participant tracking
 * - Ethical: anonymity budget makes privacy guarantees explicit
 * - Transparent: study_id and budget_hash are public, enabling informed consent
 * - Fair data donation: participant retains control via secret
 * 
 * ANONYMITY BUDGET:
 * - Defines privacy guarantees for this study (e.g., k=100, ℓ=5, ε=0.1)
 * - Tracked off-chain by study coordinator
 * - Committed via anonymity_budget_hash for verifiability
 * - Enforced through data aggregation and differential privacy
 * 
 * PERIOD MECHANISM:
 * - period_salt allows same participant to donate multiple times
 * - Each period gets unique nullifier, preventing exact replay
 * - Supports longitudinal studies with multiple data collection windows
 * - period_salt can be time-based, consent-based, or protocol-defined
 */

pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom"; // Num2Bits

template P2(){ signal input a; signal input b; signal output out; component p = Poseidon(2); p.inputs[0] <== a; p.inputs[1] <== b; out <== p.out; }

template P3(){ signal input a; signal input b; signal input c; signal output out; component p = Poseidon(3); p.inputs[0] <== a; p.inputs[1] <== b; p.inputs[2] <== c; out <== p.out; }

template ResearchConsentCircuit(){
    // Public
    signal input study_id;
    signal input anonymity_budget_hash;
    signal input research_commitment;
    signal input donation_nullifier;

    // Private
    signal input participant_secret;
    signal input period_salt;

    // Bound study_id to 32 bits
    component sBits = Num2Bits(32); sBits.in <== study_id;

    // research_commitment = H(study_id, anonymity_budget_hash, participant_secret)
    component cmt = P3();
    cmt.a <== study_id;
    cmt.b <== anonymity_budget_hash;
    cmt.c <== participant_secret;
    cmt.out === research_commitment;

    // donation_nullifier = H(participant_secret, H(study_id, period_salt))
    component inner = P2();
    inner.a <== study_id;
    inner.b <== period_salt;

    component nul = P2();
    nul.a <== participant_secret;
    nul.b <== inner.out;
    nul.out === donation_nullifier;
}

component main { public [study_id, anonymity_budget_hash, research_commitment, donation_nullifier] } = ResearchConsentCircuit();
