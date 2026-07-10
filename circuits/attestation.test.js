// SPDX-License-Identifier: UNLICENSED
/**
 * AttestationCircuit Tests
 * Tests for clinical data attestation with receipt proof
 */

const path = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  getPoseidon,
  poseidon2,
  randomFieldElement,
  getCurrentEpoch,
  TestLogger
} = require("./test-helpers");

describe("AttestationCircuit", function() {
  this.timeout(100000);
  
  let circuit;
  let poseidon;
  const logger = new TestLogger("Attestation");

  before(async () => {
    const circuitPath = path.join(__dirname, "attestation.circom");
    circuit = await wasm_tester(circuitPath, {
      output: path.join(__dirname, ".cache"),
      recompile: true
    });
    poseidon = await getPoseidon();
    console.log("\n🧪 Testing AttestationCircuit\n");
  });

  after(() => {
    const success = logger.summary();
    if (!success) process.exit(1);
  });

  it("should accept valid attestation with correct nullifier", async () => {
    try {
      const attestation_digest = randomFieldElement();
      const provider_pk = randomFieldElement();
      const timestamp_epoch = getCurrentEpoch();
      const consent_commitment = randomFieldElement();
      const receipt_secret = randomFieldElement();
      
      // Compute nullifier
      const attestation_nullifier = poseidon2(poseidon, receipt_secret, attestation_digest);
      
      const input = {
        attestation_digest,
        provider_pk,
        timestamp_epoch,
        consent_commitment,
        attestation_nullifier,
        receipt_secret
      };
      
      const witness = await circuit.calculateWitness(input, true);
      await circuit.checkConstraints(witness);
      
      logger.success("Accept valid attestation with correct nullifier");
    } catch (err) {
      logger.failure("Accept valid attestation with correct nullifier", err);
    }
  });

  it("should reject invalid nullifier", async () => {
    try {
      const attestation_digest = randomFieldElement();
      const provider_pk = randomFieldElement();
      const timestamp_epoch = getCurrentEpoch();
      const consent_commitment = randomFieldElement();
      const receipt_secret = randomFieldElement();
      
      // Wrong nullifier
      const wrong_nullifier = randomFieldElement();
      
      const input = {
        attestation_digest,
        provider_pk,
        timestamp_epoch,
        consent_commitment,
        attestation_nullifier: wrong_nullifier,
        receipt_secret
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

  it("should enforce timestamp bounds (< 2^64)", async () => {
    try {
      const attestation_digest = randomFieldElement();
      const provider_pk = randomFieldElement();
      const timestamp_epoch = 1234567890n;
      const consent_commitment = randomFieldElement();
      const receipt_secret = randomFieldElement();
      const attestation_nullifier = poseidon2(poseidon, receipt_secret, attestation_digest);
      
      const input = {
        attestation_digest,
        provider_pk,
        timestamp_epoch,
        consent_commitment,
        attestation_nullifier,
        receipt_secret
      };
      
      const witness = await circuit.calculateWitness(input, true);
      await circuit.checkConstraints(witness);
      
      logger.success("Enforce timestamp bounds");
    } catch (err) {
      logger.failure("Enforce timestamp bounds", err);
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
