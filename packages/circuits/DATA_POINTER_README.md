# FHIR Data Pointer System

This directory contains the data pointer circuit and related infrastructure for privacy-preserving clinical data access.

## Overview

The FHIR Data Pointer system enables zero-knowledge proofs that link clinical data access requests to consent proofs without revealing Protected Health Information (PHI).

## Components

### 1. Circuit: `data_pointer.circom`

Zero-knowledge circuit that proves knowledge of:
- FHIR endpoint hash
- Resource type code (e.g., 101=Patient, 102=Observation)
- Record ID hash

**Public Signals (5):**
0. `purpose_id` - Data access purpose identifier (32-bit)
1. `scope_hash` - Consent scope hash
2. `provider_pk` - Provider public key
3. `pointer_commitment` - Poseidon(endpoint_hash, resource_type_code, record_id_hash)
4. `consent_commitment` - Links to consent circuit

**Private Witness:**
- `endpoint_hash` - Canonicalized endpoint URL hash
- `resource_type_code` - FHIR resource type code (16-bit)
- `record_id_hash` - Canonicalized record ID hash

### 2. Contract: `DataPointerRegistry.sol`

On-chain verifier that:
- Validates both consent and data-pointer proofs
- Enforces cross-proof linkage (purpose, scope, provider must match)
- Checks consent commitment equality
- Guards against revoked consents
- Emits audit events (no PHI stored)

### 3. Relay Handler: `apps/relay/src/handlers/fhirProxy.ts`

Off-chain handler that:
- Verifies proofs locally
- Validates pointer commitment against provided preimages
- Fetches FHIR data from EHR endpoint
- Returns opaque payload without logging PHI

## Usage

### Build Circuit

```bash
# Fetch Powers of Tau file (required once)
pnpm tsx scripts/fetch-ptau.mjs

# Build all circuits including data_pointer
pnpm tsx scripts/build-circuits.mjs

# Sync keys to web app
pnpm tsx scripts/sync-keys.mjs
```

### Deploy Contract

```solidity
// Deploy verifiers first
address consentVerifier = ...;
address pointerVerifier = ...;
address consentRegistry = ...; // or address(0) if not using revocation

// Deploy registry
DataPointerRegistry registry = new DataPointerRegistry(
    consentVerifier,
    pointerVerifier,
    consentRegistry
);
```

### Submit Proof via Relay

```typescript
// POST to /fhir-proxy
{
  "ehrUrl": "https://ehr.example.com/fhir/Observation/123",
  "resourceType": "Observation",
  "resourceId": "123",
  "endpoint_hash": "<decimal bigint>",
  "resource_type_code": 102,
  "record_id_hash": "<decimal bigint>",
  "consent": {
    "proof": { "pi_a": [...], "pi_b": [...], "pi_c": [...] },
    "pub": [/* 10 consent public signals */]
  },
  "pointer": {
    "proof": { "pi_a": [...], "pi_b": [...], "pi_c": [...] },
    "pub": [/* 5 pointer public signals */]
  },
  "bearerToken": "<optional OAuth2 token>"
}
```

## Security Notes

### ✅ Implemented
- Zero-knowledge proof of data pointer
- Cross-proof linkage validation
- No PHI in logs or on-chain storage
- Revocation checking support
- Bit-bounded inputs (purpose_id: 32-bit, resource_type_code: 16-bit)

### ⚠️ Limitations (UNPROVEN)
- **Scope membership**: Pointer ∈ scope not enforced in circuit. Requires follow-up Merkle proof circuit.
- **Canonicalization**: URL and ID canonicalization must be consistent across provider, client, and relay. No enforcement.

### 🔒 Required for Production
1. Add scope Merkle membership proof to circuit
2. Define and enforce canonicalization rules
3. Add access control to DataPointerRegistry admin functions
4. Implement rate limiting and DDoS protection on relay
5. Add audit logging for relay (without PHI)
6. Define resource type code mapping standard

## Canonicalization Guidelines (To Be Formalized)

### Endpoint URLs
- Normalize scheme (https only)
- Lowercase hostname
- Remove default ports (443)
- Normalize path separators
- Remove query parameters and fragments

### Record IDs
- Trim whitespace
- Normalize case per FHIR spec
- Remove version indicators if applicable

**Example:**
```
Raw: "https://EHR.Example.com:443/fhir/Patient/ABC-123?version=2"
Canonical: "https://ehr.example.com/fhir/Patient/ABC-123"
```

## Testing

```bash
# Run relay tests
cd apps/relay
pnpm test

# Note: Full integration test requires built circuit keys
```

## References

- [HL7 FHIR Specification](https://www.hl7.org/fhir/)
- [Circom Documentation](https://docs.circom.io/)
- [Groth16 Proofs](https://eprint.iacr.org/2016/260.pdf)
