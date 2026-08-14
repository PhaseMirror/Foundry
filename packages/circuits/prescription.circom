// SPDX-License-Identifier: UNLICENSED
/**
 * PrescriptionCircuit - Privacy-Preserving e-Prescription Dispense Proof
 * 
 * PURPOSE:
 * Proves valid prescription dispense authorization without revealing PHI.
 * Enforces fill limits and prevents double-dispensing via nullifiers.
 * Supports multi-fill prescriptions with per-fill tracking.
 * 
 * INPUTS (Public - in fixed order):
 * 0. drug_code: Standardized drug identifier (e.g., RXNorm, CVX code)
 * 1. max_fills: Maximum number of allowed dispenses
 * 2. fills_used: Current count of completed dispenses
 * 3. dosage_hash: Poseidon hash of dosage instructions (strength, frequency, duration)
 * 4. expiry_epoch: Prescription expiration timestamp (Unix epoch seconds)
 * 5. prescriber_pk: Prescribing provider's public key/address
 * 6. pharmacy_pk: Dispensing pharmacy's public key/address
 * 7. rx_commitment: Poseidon commitment to prescription details + secrets
 * 8. dispense_nullifier: Per-fill nullifier to prevent double-dispensing
 * 
 * INPUTS (Private):
 * - rx_secret: Prescription credential secret (issued with prescription)
 * - patient_secret: Patient's secret component (enables multi-provider unlinkability)
 * 
 * CONSTRAINTS:
 * 1. Drug code bounds: drug_code < 2^32
 * 2. Fill bounds: max_fills < 2^8, fills_used < 2^8
 * 3. Fill limit: (fills_used + 1) ≤ max_fills
 * 4. Prescription commitment structure:
 *    rx_commitment = Poseidon(
 *      Poseidon(drug_code, dosage_hash),
 *      Poseidon(max_fills, expiry_epoch),
 *      Poseidon(prescriber_pk, Poseidon(patient_secret, rx_secret))
 *    )
 * 5. Dispense nullifier: dispense_nullifier = Poseidon(
 *      Poseidon(patient_secret, rx_secret),
 *      pharmacy_pk,
 *      fills_used + 1
 *    )
 * 
 * SECURITY CONSIDERATIONS:
 * - No PHI in public signals: only drug codes, counts, and hashes
 * - Nullifier is per-pharmacy per-fill: prevents double-dispensing at same pharmacy
 * - rx_secret and patient_secret jointly protect prescription
 * - Expiry check must be performed on-chain (not in circuit)
 * - dosage_hash hides specific dosing instructions
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-first: patient identity cryptographically separated from prescription
 * - Auditable: on-chain verifier checks proof without accessing PHI
 * - Non-coercive: patient controls secrets, can choose not to fill
 * - Zero-surveillance: no tracking of patient fill patterns across pharmacies
 * - Supports Web4 prescription receipts: nullifier acts as tamper-evident token
 * - Anti-abuse: fill limits enforced cryptographically
 */

pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";      // Num2Bits
include "../node_modules/circomlib/circuits/comparators.circom"; // LessThan

// Poseidon helpers
template P2() { signal input a; signal input b; signal output out; component p = Poseidon(2); p.inputs[0] <== a; p.inputs[1] <== b; out <== p.out; }

template PrescriptionCircuit() {
    // Public
    signal input drug_code;
    signal input max_fills;
    signal input fills_used;
    signal input dosage_hash;
    signal input expiry_epoch;
    signal input prescriber_pk;
    signal input pharmacy_pk;
    signal input rx_commitment;
    signal input dispense_nullifier;

    // Private
    signal input rx_secret;
    signal input patient_secret;

    // Bounds
    component dBits = Num2Bits(32); dBits.in <== drug_code;
    component mfBits = Num2Bits(8); mfBits.in <== max_fills;
    component fuBits = Num2Bits(8); fuBits.in <== fills_used;

    // fills_used + 1 <= max_fills
    signal nextFill; nextFill <== fills_used + 1;
    component lt = LessThan(16);
    lt.in[0] <== nextFill;
    lt.in[1] <== max_fills + 1; // implement <=
    lt.out === 1;

    // h(patient_secret, rx_secret)
    component hPS = P2(); hPS.a <== patient_secret; hPS.b <== rx_secret;

    // commitment tree
    component hDD = P2(); hDD.a <== drug_code; hDD.b <== dosage_hash;
    component hME = P2(); hME.a <== max_fills; hME.b <== expiry_epoch;
    component hPR = P2(); hPR.a <== prescriber_pk; hPR.b <== hPS.out;

    component h1 = Poseidon(3);
    h1.inputs[0] <== hDD.out;
    h1.inputs[1] <== hME.out;
    h1.inputs[2] <== hPR.out;

    // enforce commitment
    h1.out === rx_commitment;

    // nullifier per fill and pharmacy
    component hN = Poseidon(3);
    hN.inputs[0] <== hPS.out;
    hN.inputs[1] <== pharmacy_pk;
    hN.inputs[2] <== nextFill;
    hN.out === dispense_nullifier;
}

component main { public [drug_code, max_fills, fills_used, dosage_hash, expiry_epoch, prescriber_pk, pharmacy_pk, rx_commitment, dispense_nullifier] } = PrescriptionCircuit();
