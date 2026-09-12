// SPDX-License-Identifier: UNLICENSED
/**
 * DataPointerCircuit - FHIR Resource Pointer with Consent Linkage
 * 
 * PURPOSE:
 * Proves cryptographic pointer to clinical data (FHIR resource) with consent binding.
 * Enables privacy-preserving data access authorization without revealing resource details.
 * Links data access request to consent proof via consent_commitment.
 * 
 * INPUTS (Public - in fixed order):
 * 0. purpose_id: Clinical purpose code (must match consent purpose)
 * 1. scope_hash: Poseidon hash of resource scopes (must match consent scope)
 * 2. provider_pk: Requesting provider's public key/address
 * 3. pointer_commitment: Poseidon commitment to data location
 * 4. consent_commitment: Reference to associated consent proof (from ConsentCircuit)
 * 
 * INPUTS (Private):
 * - endpoint_hash: Field element representing canonicalized endpoint URL hash
 * - resource_type_code: Integer code for FHIR resource type
 *   (e.g., caller-defined mapping: 101=Patient, 102=Observation, 103=Condition)
 * - record_id_hash: Field element representing canonicalized record ID hash
 * 
 * CONSTRAINTS:
 * 1. Purpose bounds: purpose_id < 2^32
 * 2. Resource type bounds: resource_type_code < 2^16
 * 3. Pointer commitment structure:
 *    pointer_commitment = Poseidon(endpoint_hash, resource_type_code, record_id_hash)
 * 
 * SECURITY CONSIDERATIONS:
 * - Endpoint URL and record ID are hashed, not revealed
 * - Resource type is encoded as small integer (mapping defined by implementer)
 * - Consent linkage verified on-chain: consent_commitment must be valid
 * - scope_hash and purpose_id must match consent proof
 * - SET MEMBERSHIP NOT ENFORCED: pointer ∈ scope requires Merkle proof (future work)
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Privacy-preserving: resource location cryptographically hidden
 * - Consent-bound: pointer only valid with matching consent
 * - Auditable: pointer commitment is tamper-evident
 * - Zero-surveillance: no tracking of resource access patterns
 * - Granular access: pointer is to specific resource, not bulk data
 * - Non-coercive: patient controls consent, can revoke pointer validity
 * 
 * LIMITATIONS:
 * - This circuit does NOT enforce pointer ∈ scope membership
 * - Scope membership check requires Merkle tree proof (UNPROVEN in v1)
 * - On-chain verifier must check consent_commitment validity separately
 * - purpose_id and scope_hash must match between this proof and consent proof
 * 
 * WORKFLOW:
 * 1. Patient issues consent with purpose_id and scope_hash (ConsentCircuit)
 * 2. Provider requests specific resource (this circuit)
 * 3. Circuit proves pointer commitment without revealing resource location
 * 4. On-chain verifier checks:
 *    a. Consent proof is valid for (purpose_id, scope_hash, provider_pk)
 *    b. Pointer proof is valid with matching (purpose_id, scope_hash, consent_commitment)
 * 5. If both valid, data custodian releases resource to provider
 */

pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom"; // Num2Bits for small bounds

// Poseidon(3) wrapper
template Poseidon3() {
    signal input a;
    signal input b;
    signal input c;
    signal output out;
    component p = Poseidon(3);
    p.inputs[0] <== a;
    p.inputs[1] <== b;
    p.inputs[2] <== c;
    out <== p.out;
}

template DataPointerCircuit() {
    // Public
    signal input purpose_id;
    signal input scope_hash;
    signal input provider_pk;
    signal input pointer_commitment;
    signal input consent_commitment;

    // Private
    signal input endpoint_hash;
    signal input resource_type_code;  // expect < 2^16
    signal input record_id_hash;

    // Bound purpose_id to 32 bits
    component pbits = Num2Bits(32);
    pbits.in <== purpose_id;

    // Bound resource_type_code to 16 bits (caller provides mapping)
    component rbits = Num2Bits(16);
    rbits.in <== resource_type_code;

    // Recompute pointer commitment
    component h = Poseidon3();
    h.a <== endpoint_hash;
    h.b <== resource_type_code;
    h.c <== record_id_hash;

    // Enforce expected commitment
    h.out === pointer_commitment;

    // No further constraints; linkage to consent_commitment is checked on-chain
}

component main { public [purpose_id, scope_hash, provider_pk, pointer_commitment, consent_commitment] } = DataPointerCircuit();
