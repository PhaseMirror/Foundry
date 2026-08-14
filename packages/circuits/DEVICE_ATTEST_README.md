# Device Attestation Circuit and Registry

This document explains the device telemetry attestation circuit and on-chain registry.

## Overview

The device attestation system allows IoT devices and secure enclaves to submit privacy-preserving telemetry proofs on-chain. The system ensures:

1. **Authenticity**: Only devices with allowlisted `device_root` (secure boot hash) can submit
2. **Privacy**: Raw metric values remain private; only bounds are committed publicly
3. **Replay Protection**: Each proof uses a unique nullifier to prevent double-submission
4. **Timestamp Validation**: Prevents stale or future-dated telemetry

## Circuit: `device_attest.circom`

### Public Signals (in order)
- `device_root` (field): Secure boot or firmware root hash
- `metric_bounds_commitment` (field): Poseidon(sample_digest, fold(min_i, max_i))
- `timestamp_epoch` (uint64): Unix timestamp in seconds
- `telemetry_commitment` (field): Poseidon(device_root, metric_bounds_commitment, timestamp_epoch)
- `telemetry_nullifier` (field): Poseidon(device_secret, telemetry_commitment)

### Private Witness
- `device_secret`: Secret bound to device wallet or secure enclave
- `sample_digest`: Hash of raw sample window (keeps raw data private)
- `metrics[N]`: Array of metric values
- `min_bounds[N]`: Minimum bounds for each metric
- `max_bounds[N]`: Maximum bounds for each metric

### Parameters
- `N`: Number of metrics (default: 4)
- `BW`: Bit width for each metric value (default: 32)

To change these parameters, instantiate with different values:
```circom
component main { public [...] } = DeviceAttestCircuit(8, 64); // 8 metrics, 64-bit
```

### Constraints
1. Each metric must satisfy: `min_bounds[i] <= metrics[i] <= max_bounds[i]`
2. `metric_bounds_commitment = Poseidon(sample_digest, fold(min_i, max_i))`
   - Where `fold` iteratively applies `Poseidon(fold_prev, min_i, max_i)`
3. `telemetry_commitment = Poseidon(device_root, metric_bounds_commitment, timestamp_epoch)`
4. `telemetry_nullifier = Poseidon(device_secret, telemetry_commitment)`
5. `timestamp_epoch` must fit in 64 bits

## Contract: `DeviceRegistry.sol`

### Key Features
- **Verifier Integration**: Uses Groth16 verifier for the device_attest circuit
- **Root Allowlist**: Owner can allowlist/denylist device roots
- **Drift Protection**: Enforces max timestamp drift vs `block.timestamp` (default 600s)
- **Replay Guard**: Tracks used nullifiers to prevent resubmission

### Functions

#### Owner Functions
- `setVerifier(address v)`: Set the Groth16 verifier contract
- `allowRoot(bytes32 root, bool allowed)`: Allowlist or denylist a device root
- `setMaxDrift(uint64 seconds_)`: Update max acceptable timestamp drift

#### Public Functions
- `submit(pA, pB, pC, pub)`: Submit a telemetry proof
  - Validates proof via verifier
  - Checks device_root is allowlisted
  - Checks timestamp drift
  - Prevents replay via nullifier
  - Emits `Telemetry` event with all public signals

### Events
- `VerifierSet(address v)`
- `RootAllowed(bytes32 root, bool allowed)`
- `MaxDriftSet(uint64 seconds_)`
- `Telemetry(bytes32 indexed deviceRoot, bytes32 indexed boundsCommitment, uint64 timestampEpoch, bytes32 telemetryCommitment, bytes32 nullifier)`

### Errors
- `InvalidProof()`: Proof verification failed or wrong number of public signals
- `NotAllowedRoot()`: Device root is not allowlisted
- `ExcessiveDrift()`: Timestamp too far from block timestamp
- `Replay()`: Nullifier already used

## Usage Example

### 1. Build the Circuit
```bash
# Ensure PTau file is available
pnpm tsx scripts/fetch-ptau.mjs

# Build circuits (includes device_attest)
pnpm tsx scripts/build-circuits.mjs

# Sync keys to web app
pnpm tsx scripts/sync-keys.mjs
```

### 2. Generate a Proof (TypeScript)
```typescript
import { groth16 } from "snarkjs";
import { buildPoseidon } from "circomlibjs";

const poseidon = await buildPoseidon();

// Device parameters
const deviceSecret = 12345n;
const deviceRoot = poseidon([deviceSecret, 9999n]); // Example root

// Sample telemetry: 4 metrics
const metrics = [100, 75, 1024, 50];
const minBounds = [50, 0, 512, 0];
const maxBounds = [150, 100, 2048, 100];

// Compute sample digest (hash of raw sample window)
const sampleDigest = poseidon([...metrics]);

// Compute fold of bounds
let foldB = 0n;
for (let i = 0; i < 4; i++) {
  foldB = poseidon([foldB, BigInt(minBounds[i]), BigInt(maxBounds[i])]);
}

// Compute commitments
const metricBoundsCommitment = poseidon([sampleDigest, foldB]);
const timestampEpoch = BigInt(Math.floor(Date.now() / 1000));
const telemetryCommitment = poseidon([deviceRoot, metricBoundsCommitment, timestampEpoch]);
const telemetryNullifier = poseidon([deviceSecret, telemetryCommitment]);

// Generate proof
const input = {
  // Public
  device_root: deviceRoot.toString(),
  metric_bounds_commitment: metricBoundsCommitment.toString(),
  timestamp_epoch: timestampEpoch.toString(),
  telemetry_commitment: telemetryCommitment.toString(),
  telemetry_nullifier: telemetryNullifier.toString(),
  // Private
  device_secret: deviceSecret.toString(),
  sample_digest: sampleDigest.toString(),
  metrics: metrics.map(m => m.toString()),
  min_bounds: minBounds.map(m => m.toString()),
  max_bounds: maxBounds.map(m => m.toString())
};

const { proof, publicSignals } = await groth16.fullProve(
  input,
  "keys/device_attest_js/device_attest.wasm",
  "keys/device_attest.zkey"
);
```

### 3. Submit On-Chain
```typescript
// Deploy and configure registry
const registry = await DeviceRegistry.deploy(ownerAddress);
await registry.setVerifier(verifierAddress);
await registry.allowRoot(deviceRoot, true);

// Format proof for on-chain submission
const proofArgs = [
  [proof.pi_a[0], proof.pi_a[1]],
  [[proof.pi_b[0][1], proof.pi_b[0][0]], [proof.pi_b[1][1], proof.pi_b[1][0]]],
  [proof.pi_c[0], proof.pi_c[1]],
  publicSignals
];

// Submit
await registry.submit(...proofArgs);

// Second submission with same nullifier will revert with Replay()
await expect(registry.submit(...proofArgs)).to.be.revertedWithCustomError(
  registry,
  "Replay"
);
```

## Security Considerations

### ⚠️ IMPORTANT: Off-Circuit Signature Verification

**The device signature over `sample_digest` is NOT verified in-circuit.** This keeps proving time low but means:

- The circuit proves bounds constraints on metrics
- The circuit binds to `device_root` and derives correct commitments
- **BUT**: Authenticity of the sample data is UNPROVEN until signature verification runs

**Required Integration**: The wallet or relay MUST verify the device's ECDSA signature over:
```
ECDSA_verify(device_public_key, sample_digest, signature)
```

This signature check ensures the device actually generated the sample. Without it, anyone who knows a valid `device_root` and `device_secret` could submit fake telemetry.

### Deployment Checklist
1. ✅ Deploy DeviceRegistry contract
2. ✅ Deploy and set Groth16 verifier for device_attest circuit
3. ✅ Allowlist valid device roots (secure boot hashes)
4. ✅ Implement device signature verification in wallet/relay
5. ✅ Configure reasonable drift bound (default 600s)
6. ✅ Monitor Telemetry events for anomalies

## Testing

Complete test suites are available in `packages/mtpi-contracts/test/device_attest.spec.ts`:

1. **Generate Verifier Contract**: After building the circuit, generate the Solidity verifier:
   ```bash
   snarkjs zkey export solidityverifier circuits/out/device_attest.zkey contracts/verifier/DeviceAttestVerifier.sol
   ```
  Note: A snarkJS-generated Groth16 Solidity verifier is provided at `contracts/verifier/DeviceAttestVerifier.sol` (generated from the circuit zkey). For local quick runs the deploy script still supports a mock fallback when `USE_MOCK_VERIFIER=1` is set.

2. **Deploy Infrastructure**: Use the integrated deployment script:
   ```bash
   # Local deployment with mock verifier
   USE_MOCK_VERIFIER=1 pnpm run deploy:local
   
   # Testnet deployment with real verifier
   pnpm run deploy:sepolia
   ```
   
   The deployment script automatically:
   - Deploys DeviceAttestVerifier (or uses mock)
   - Deploys DeviceRegistry with owner address
   - Wires registry to verifier
   - Exports ABIs to packages/mtpi-contracts/src/abi/
   - Saves deployment addresses to packages/mtpi-contracts/deployments/{network}.json

3. **Use Relay API**: The relay server includes a device attestation endpoint:
   ```bash
   # Start relay server
   cd apps/relay
   pnpm run start
   ```
   
   Submit proofs via POST to `/device-attest`:
   ```typescript
   const response = await fetch('http://localhost:8787/device-attest', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({
       proof: { pi_a, pi_b, pi_c },
       publicSignals: [deviceRoot, boundsCommitment, timestamp, commitment, nullifier],
       deviceSignature: '0x...', // Optional but recommended
       sampleDigest: '0x...'     // Required if signature provided
     })
   });
   ```
   
   The relay handler:
   - Validates proof format and public signals count
   - Logs a warning if device signature is not provided
   - Validates signature if provided (requires implementation of device key lookup)
   - Formats proof for on-chain submission (requires deployment config)

4. **Integrate Signature Verification**: The relay handler includes placeholders for signature verification. To enable:
   - Implement `lookupDevicePublicKey(deviceRoot)` to retrieve device keys from allowlist
   - Uncomment signature verification code in `apps/relay/src/handlers/deviceAttest.ts`
   - Configure device public keys in registry or separate key management system

5. **Configure On-Chain Submission**: Update relay handler with deployment config:
   ```typescript
   // In apps/relay/src/handlers/deviceAttest.ts
   const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
   const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
   const registry = new ethers.Contract(
     process.env.DEVICE_REGISTRY_ADDRESS!, // From deployment JSON
     DeviceRegistryABI,
     wallet
   );
   ```

6. **Monitor and Audit**: Track on-chain Telemetry events for anomaly detection

7. **Scale Parameters**: For more metrics or higher precision, rebuild with larger N or BW

## Testing

Complete test suites are available in `packages/mtpi-contracts/test/device_attest.spec.ts`:

**Circuit Tests** (require built artifacts):
- Valid proof generation with Poseidon commitments
- Rejection of out-of-bounds metrics
- Rejection of invalid bounds constraints

**Contract Tests** (work with mock verifier):
- Deployment and ownership
- Verifier configuration
- Device root allowlisting
- Valid proof submission and event emission
- Replay attack prevention
- Timestamp drift validation
- Invalid proof rejection

**Integration Test**:
- Full end-to-end flow from proof generation to on-chain submission
- Demonstrates proper proof format conversion
- Tests replay protection in integrated scenario

Run tests:
```bash
# Circuit tests (requires built artifacts)
pnpm test packages/mtpi-contracts/test/device_attest.spec.ts

# Contract tests only (works with mock verifier)
pnpm -F @mtpi/mtpi-contracts test
```

## License

SPDX-License-Identifier: MIT
