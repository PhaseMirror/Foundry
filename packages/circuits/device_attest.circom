// SPDX-License-Identifier: UNLICENSED
/**
 * DeviceAttestCircuit - Privacy-Preserving Device Telemetry Attestation
 * 
 * PURPOSE:
 * Proves device telemetry metrics fall within approved bounds without revealing
 * exact values. Supports secure boot attestation and range-proof style telemetry.
 * Enables privacy-preserving device health monitoring.
 * 
 * CIRCUIT PARAMETERS:
 * - N: Number of metrics to attest (default: 4)
 * - BW: Bit width for each metric value (default: 32 bits)
 * 
 * INPUTS (Public - in fixed order):
 * 0. device_root: Secure boot or firmware root hash (field element)
 * 1. metric_bounds_commitment: Poseidon commitment to metric ranges
 * 2. timestamp_epoch: Attestation timestamp (Unix epoch seconds)
 * 3. telemetry_commitment: Overall telemetry commitment
 * 4. telemetry_nullifier: Per-device nullifier for attestation
 * 
 * INPUTS (Private):
 * - device_secret: Secret bound to device wallet or secure enclave
 * - sample_digest: Hash of raw telemetry sample window (not public)
 * - metrics[N]: Array of N raw metric values (e.g., [temp, cpu, mem, battery])
 * - min_bounds[N]: Array of N minimum acceptable values per metric
 * - max_bounds[N]: Array of N maximum acceptable values per metric
 * 
 * CONSTRAINTS:
 * 1. Timestamp bounds: timestamp_epoch < 2^64
 * 2. Metric range checks: For all i ∈ [0, N):
 *    - metrics[i] < 2^BW (bit width enforcement)
 *    - min_bounds[i] ≤ metrics[i] ≤ max_bounds[i] (range proof)
 * 3. Bounds folding: foldB = iterative Poseidon(prev, min_i, max_i) over all metrics
 * 4. Metric commitment: metric_bounds_commitment = Poseidon(sample_digest, foldB)
 * 5. Telemetry commitment: telemetry_commitment = Poseidon(
 *      device_root,
 *      metric_bounds_commitment,
 *      timestamp_epoch
 *    )
 * 6. Nullifier: telemetry_nullifier = Poseidon(device_secret, telemetry_commitment)
 * 
 * SECURITY CONSIDERATIONS:
 * - Exact metric values are private, only range compliance is proven
 * - device_root enables firmware/bootloader attestation chain
 * - device_secret binds attestation to specific device identity
 * - sample_digest provides non-repudiation without revealing raw data
 * - Range proofs prevent manipulation while preserving privacy
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-preserving telemetry: exact values not revealed
 * - Device sovereignty: device controls device_secret
 * - Auditable: compliance with bounds can be verified on-chain
 * - Zero-surveillance: no device fingerprinting beyond device_root
 * - Secure boot: device_root enables trusted execution verification
 * - Anti-coercion: device can refuse attestation by not providing proof
 * - Fair monitoring: bounds are transparent, not hidden surveillance
 * 
 * USE CASES:
 * - Medical device safety monitoring (temp, pressure, battery within safe range)
 * - IoT sensor attestation (environmental readings within calibrated bounds)
 * - Secure enclave health checks (CPU temp, memory usage acceptable)
 * - Wearable device fitness tracking (heart rate, steps within plausible range)
 */

pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom"; // LessThan

// Helpers
template P2(){ signal input a; signal input b; signal output out; component p = Poseidon(2); p.inputs[0] <== a; p.inputs[1] <== b; out <== p.out; }
template P3(){ signal input a; signal input b; signal input c; signal output out; component p = Poseidon(3); p.inputs[0] <== a; p.inputs[1] <== b; p.inputs[2] <== c; out <== p.out; }

// Parameterized by number of metrics N and the bit width BW for each value
template DeviceAttestCircuit(N, BW){
    // Public
    signal input device_root;
    signal input metric_bounds_commitment;
    signal input timestamp_epoch;
    signal input telemetry_commitment;
    signal input telemetry_nullifier;

    // Private
    signal input device_secret;
    signal input sample_digest;
    signal input metrics[N];
    signal input min_bounds[N];
    signal input max_bounds[N];

    // Bounds for timestamp
    component tbits = Num2Bits(64); tbits.in <== timestamp_epoch;

    // Fold bounds and enforce per-metric constraints
    var i;
    signal foldB[N + 1];
    foldB[0] <== 0; // seed
    
    component mb[N];
    component lo[N];
    component hi[N];
    component le1[N];
    component le2[N];
    component f[N];
    
    for (i = 0; i < N; i++){
        // Enforce bit-width for values
        mb[i] = Num2Bits(BW); mb[i].in <== metrics[i];
        lo[i] = Num2Bits(BW); lo[i].in <== min_bounds[i];
        hi[i] = Num2Bits(BW); hi[i].in <== max_bounds[i];

        // min <= metric
        le1[i] = LessThan(BW+1);
        le1[i].in[0] <== min_bounds[i];
        le1[i].in[1] <== metrics[i] + 1;
        le1[i].out === 1;

        // metric <= max
        le2[i] = LessThan(BW+1);
        le2[i].in[0] <== metrics[i];
        le2[i].in[1] <== max_bounds[i] + 1;
        le2[i].out === 1;

        // fold: foldB = Poseidon(foldB, min_i, max_i)
        f[i] = P3();
        f[i].a <== foldB[i];
        f[i].b <== min_bounds[i];
        f[i].c <== max_bounds[i];
        foldB[i + 1] <== f[i].out;
    }

    // metric_bounds_commitment = Poseidon(sample_digest, foldB)
    component cmt = P2();
    cmt.a <== sample_digest;
    cmt.b <== foldB[N];
    cmt.out === metric_bounds_commitment;

    // telemetry_commitment = Poseidon(device_root, metric_bounds_commitment, timestamp_epoch)
    component tele = P3();
    tele.a <== device_root;
    tele.b <== metric_bounds_commitment;
    tele.c <== timestamp_epoch;
    tele.out === telemetry_commitment;

    // telemetry_nullifier = Poseidon(device_secret, telemetry_commitment)
    component nul = P2();
    nul.a <== device_secret;
    nul.b <== telemetry_commitment;
    nul.out === telemetry_nullifier;
}

// Example default: 4 metrics, 32-bit width
component main { public [device_root, metric_bounds_commitment, timestamp_epoch, telemetry_commitment, telemetry_nullifier] } = DeviceAttestCircuit(4, 32);
