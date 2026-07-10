// SPDX-License-Identifier: UNLICENSED
/**
 * ConsentCircuit Tests
 * Tests for privacy-preserving clinical consent proof
 */

const path = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  getPoseidon,
  poseidon2,
  poseidon4,
  randomFieldElement,
  getCurrentEpoch,
  getFutureEpoch,
  TestLogger
} = require("./test-helpers");

describe("ConsentCircuit", function() {
  this.timeout(100000);
  
  let circuit;
  let poseidon;
  const logger = new TestLogger("ConsentCircuit");

  before(async () => {
    const circuitPath = path.join(__dirname, "consent.circom");
    circuit = await wasm_tester(circuitPath, {
      output: path.join(__dirname, ".cache"),
      recompile: true
    });
    poseidon = await getPoseidon();
    console.log("\n🧪 Testing ConsentCircuit\n");
  });

  after(() => {
    const success = logger.summary();
    if (!success) process.exit(1);
  });

  it("should accept valid consent not expired", async () => {
    try {
      const purpose_id = 1n; // Treatment
      const scope_hash = randomFieldElement();
      const provider_pk = randomFieldElement();
      const patient_pk = randomFieldElement();
      const now_epoch = getCurrentEpoch();
      const expiry_epoch = getFutureEpoch(86400); // 1 day ahead
      const delta_bound = 300n;
      const consent_secret = randomFieldElement();
      
      // Compute commitment components
      const hPS = poseidon2(poseidon, purpose_id, scope_hash);
      const hPP = poseidon2(poseidon, provider_pk, patient_pk);
      const hED = poseidon2(poseidon, expiry_epoch, delta_bound);
      
      // Compute full commitment
      const consent_commitment = poseidon4(poseidon, hPS, hPP, hED, consent_secret);
      
      // Compute nullifier
      const nullifier = poseidon2(poseidon, consent_secret, provider_pk);
      
      // Merkle path (unused when USE_ROOT=0)
      const pathElements = new Array(32).fill(0n);
      const pathIndices = new Array(32).fill(0n);
      
      const input = {
        purpose_id,
        scope_hash,
        provider_pk,
        patient_pk,
        expiry_epoch,
        now_epoch,
        delta_bound,
        consent_commitment,
        consent_root: 0n, // USE_ROOT=0
        nullifier,
        consent_secret,
        pathElements,
        pathIndices
      };
      
      const witness = await circuit.calculateWitness(input, true);
      await circuit.checkConstraints(witness);
      
      logger.success("Accept valid consent not expired");
    } catch (err) {
      logger.failure("Accept valid consent not expired", err);
    }
  });

  it("should reject expired consent", async () => {
    try {
      const purpose_id = 2n; // Research
      const scope_hash = randomFieldElement();
      const provider_pk = randomFieldElement();
      const patient_pk = randomFieldElement();
      const now_epoch = getCurrentEpoch();
      const expiry_epoch = now_epoch - 86400n; // Expired yesterday
      const delta_bound = 300n;
      const consent_secret = randomFieldElement();
      
      const hPS = poseidon2(poseidon, purpose_id, scope_hash);
      const hPP = poseidon2(poseidon, provider_pk, patient_pk);
      const hED = poseidon2(poseidon, expiry_epoch, delta_bound);
      const consent_commitment = poseidon4(poseidon, hPS, hPP, hED, consent_secret);
      const nullifier = poseidon2(poseidon, consent_secret, provider_pk);
      
      const pathElements = new Array(32).fill(0n);
      const pathIndices = new Array(32).fill(0n);
      
      const input = {
        purpose_id,
        scope_hash,
        provider_pk,
        patient_pk,
        expiry_epoch,
        now_epoch,
        delta_bound,
        consent_commitment,
        consent_root: 0n,
        nullifier,
        consent_secret,
        pathElements,
        pathIndices
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected expired consent");
      }
      
      logger.success("Reject expired consent");
    } catch (err) {
      logger.failure("Reject expired consent", err);
    }
  });

  it("should reject invalid commitment", async () => {
    try {
      const purpose_id = 3n; // Billing
      const scope_hash = randomFieldElement();
      const provider_pk = randomFieldElement();
      const patient_pk = randomFieldElement();
      const now_epoch = getCurrentEpoch();
      const expiry_epoch = getFutureEpoch(86400);
      const delta_bound = 300n;
      const consent_secret = randomFieldElement();
      
      // Compute correct commitment
      const hPS = poseidon2(poseidon, purpose_id, scope_hash);
      const hPP = poseidon2(poseidon, provider_pk, patient_pk);
      const hED = poseidon2(poseidon, expiry_epoch, delta_bound);
      const _correct_commitment = poseidon4(poseidon, hPS, hPP, hED, consent_secret);
      
      // Use wrong commitment
      const wrong_commitment = randomFieldElement();
      
      const nullifier = poseidon2(poseidon, consent_secret, provider_pk);
      const pathElements = new Array(32).fill(0n);
      const pathIndices = new Array(32).fill(0n);
      
      const input = {
        purpose_id,
        scope_hash,
        provider_pk,
        patient_pk,
        expiry_epoch,
        now_epoch,
        delta_bound,
        consent_commitment: wrong_commitment, // Wrong!
        consent_root: 0n,
        nullifier,
        consent_secret,
        pathElements,
        pathIndices
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected invalid commitment");
      }
      
      logger.success("Reject invalid commitment");
    } catch (err) {
      logger.failure("Reject invalid commitment", err);
    }
  });

  it("should reject invalid nullifier", async () => {
    try {
      const purpose_id = 1n;
      const scope_hash = randomFieldElement();
      const provider_pk = randomFieldElement();
      const patient_pk = randomFieldElement();
      const now_epoch = getCurrentEpoch();
      const expiry_epoch = getFutureEpoch(86400);
      const delta_bound = 300n;
      const consent_secret = randomFieldElement();
      
      const hPS = poseidon2(poseidon, purpose_id, scope_hash);
      const hPP = poseidon2(poseidon, provider_pk, patient_pk);
      const hED = poseidon2(poseidon, expiry_epoch, delta_bound);
      const consent_commitment = poseidon4(poseidon, hPS, hPP, hED, consent_secret);
      
      // Wrong nullifier
      const wrong_nullifier = randomFieldElement();
      
      const pathElements = new Array(32).fill(0n);
      const pathIndices = new Array(32).fill(0n);
      
      const input = {
        purpose_id,
        scope_hash,
        provider_pk,
        patient_pk,
        expiry_epoch,
        now_epoch,
        delta_bound,
        consent_commitment,
        consent_root: 0n,
        nullifier: wrong_nullifier, // Wrong!
        consent_secret,
        pathElements,
        pathIndices
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected invalid nullifier");
      }
      
      logger.success("Reject invalid nullifier");
    } catch (err) {
      logger.failure("Reject invalid nullifier", err);
    }
  });

  it("should accept consent at expiry boundary", async () => {
    try {
      const purpose_id = 1n;
      const scope_hash = randomFieldElement();
      const provider_pk = randomFieldElement();
      const patient_pk = randomFieldElement();
      const expiry_epoch = 2000000000n;
      const now_epoch = expiry_epoch; // Exactly at expiry
      const delta_bound = 300n;
      const consent_secret = randomFieldElement();
      
      const hPS = poseidon2(poseidon, purpose_id, scope_hash);
      const hPP = poseidon2(poseidon, provider_pk, patient_pk);
      const hED = poseidon2(poseidon, expiry_epoch, delta_bound);
      const consent_commitment = poseidon4(poseidon, hPS, hPP, hED, consent_secret);
      const nullifier = poseidon2(poseidon, consent_secret, provider_pk);
      
      const pathElements = new Array(32).fill(0n);
      const pathIndices = new Array(32).fill(0n);
      
      const input = {
        purpose_id,
        scope_hash,
        provider_pk,
        patient_pk,
        expiry_epoch,
        now_epoch,
        delta_bound,
        consent_commitment,
        consent_root: 0n,
        nullifier,
        consent_secret,
        pathElements,
        pathIndices
      };
      
      const witness = await circuit.calculateWitness(input, true);
      await circuit.checkConstraints(witness);
      
      logger.success("Accept consent at expiry boundary");
    } catch (err) {
      logger.failure("Accept consent at expiry boundary", err);
    }
  });
});

// If running standalone
if (require.main === module) {
  const Mocha = require('mocha');
  const mocha = new Mocha();
  mocha.addFile(__filename);
  mocha.run(failures => {
    process.exitCode = failures ? 1 : 0;
  });
}
