// SPDX-License-Identifier: UNLICENSED
/**
 * RootContract Circuit Tests
 * Tests for MTPI core state transition circuit
 */

const path = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  getPoseidon,
  poseidon2,
  poseidon3,
  randomFieldElement,
  KNOWN_PRIMES,
  KNOWN_COMPOSITES,
  TestLogger
} = require("./test-helpers");

describe("RootContract Circuit", function() {
  this.timeout(100000);
  
  let circuit;
  let poseidon;
  const logger = new TestLogger("RootContract");

  before(async () => {
    const circuitPath = path.join(__dirname, "root.circom");
    circuit = await wasm_tester(circuitPath, {
      output: path.join(__dirname, ".cache"),
      recompile: true
    });
    poseidon = await getPoseidon();
    console.log("\n🧪 Testing RootContract Circuit\n");
  });

  after(() => {
    const success = logger.summary();
    if (!success) process.exit(1);
  });

  it("should accept valid state transition with prime index", async () => {
    try {
      const primeIndex = KNOWN_PRIMES[10]; // 31
      const identitySecret = randomFieldElement();
      const prevStateHash = randomFieldElement();
      const nonce = 1000n;
      const timestamp = 1300n; // drift = 300
      
      // Compute identity hash
      const identityHash = poseidon2(poseidon, primeIndex, identitySecret);
      
      // Compute new state hash
      const newStateHash = poseidon3(poseidon, prevStateHash, identityHash, nonce);
      
      // Compute expected proof hash
      const expectedProofHash = poseidon3(poseidon, prevStateHash, newStateHash, timestamp);
      
      const input = {
        stateHash: prevStateHash,
        primeIndex: primeIndex,
        timestamp: timestamp,
        newStateHash: newStateHash,
        prevStateHash: prevStateHash,
        nonce: nonce,
        identitySecret: identitySecret
      };
      
      const witness = await circuit.calculateWitness(input, true);
      await circuit.checkConstraints(witness);
      
      // Verify proof hash output
      await circuit.assertOut(witness, { proofHash: expectedProofHash });
      
      logger.success("Valid state transition with prime index");
    } catch (err) {
      logger.failure("Valid state transition with prime index", err);
    }
  });

  it("should reject composite primeIndex", async () => {
    try {
      const compositeIndex = KNOWN_COMPOSITES[3]; // 9
      const identitySecret = randomFieldElement();
      const prevStateHash = randomFieldElement();
      const nonce = 1000n;
      const timestamp = 1300n;
      
      const identityHash = poseidon2(poseidon, compositeIndex, identitySecret);
      const newStateHash = poseidon3(poseidon, prevStateHash, identityHash, nonce);
      
      const input = {
        stateHash: prevStateHash,
        primeIndex: compositeIndex,
        timestamp: timestamp,
        newStateHash: newStateHash,
        prevStateHash: prevStateHash,
        nonce: nonce,
        identitySecret: identitySecret
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected composite primeIndex");
      }
      
      logger.success("Reject composite primeIndex");
    } catch (err) {
      logger.failure("Reject composite primeIndex", err);
    }
  });

  it("should reject excessive drift (timestamp - nonce > 0.3Ξ)", async () => {
    try {
      const primeIndex = KNOWN_PRIMES[5]; // 13
      const identitySecret = randomFieldElement();
      const prevStateHash = randomFieldElement();
      const nonce = 1000n;
      const timestamp = 2000000000000000000n; // Excessive drift
      
      const identityHash = poseidon2(poseidon, primeIndex, identitySecret);
      const newStateHash = poseidon3(poseidon, prevStateHash, identityHash, nonce);
      
      const input = {
        stateHash: prevStateHash,
        primeIndex: primeIndex,
        timestamp: timestamp,
        newStateHash: newStateHash,
        prevStateHash: prevStateHash,
        nonce: nonce,
        identitySecret: identitySecret
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected excessive drift");
      }
      
      logger.success("Reject excessive drift");
    } catch (err) {
      logger.failure("Reject excessive drift", err);
    }
  });

  it("should reject stateHash != prevStateHash", async () => {
    try {
      const primeIndex = KNOWN_PRIMES[7]; // 19
      const identitySecret = randomFieldElement();
      const prevStateHash = randomFieldElement();
      const wrongStateHash = randomFieldElement(); // Different!
      const nonce = 1000n;
      const timestamp = 1300n;
      
      const identityHash = poseidon2(poseidon, primeIndex, identitySecret);
      const newStateHash = poseidon3(poseidon, prevStateHash, identityHash, nonce);
      
      const input = {
        stateHash: wrongStateHash, // Wrong!
        primeIndex: primeIndex,
        timestamp: timestamp,
        newStateHash: newStateHash,
        prevStateHash: prevStateHash,
        nonce: nonce,
        identitySecret: identitySecret
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected state hash mismatch");
      }
      
      logger.success("Reject state hash mismatch");
    } catch (err) {
      logger.failure("Reject state hash mismatch", err);
    }
  });

  it("should reject incorrect newStateHash", async () => {
    try {
      const primeIndex = KNOWN_PRIMES[8]; // 23
      const identitySecret = randomFieldElement();
      const prevStateHash = randomFieldElement();
      const nonce = 1000n;
      const timestamp = 1300n;
      const wrongNewStateHash = randomFieldElement(); // Wrong!
      
      const input = {
        stateHash: prevStateHash,
        primeIndex: primeIndex,
        timestamp: timestamp,
        newStateHash: wrongNewStateHash, // Wrong!
        prevStateHash: prevStateHash,
        nonce: nonce,
        identitySecret: identitySecret
      };
      
      let failed = false;
      try {
        await circuit.calculateWitness(input, true);
      } catch (err) {
        failed = true;
      }
      
      if (!failed) {
        throw new Error("Circuit should have rejected incorrect newStateHash");
      }
      
      logger.success("Reject incorrect newStateHash");
    } catch (err) {
      logger.failure("Reject incorrect newStateHash", err);
    }
  });

  it("should accept valid drift at boundary (exactly 0.3Ξ)", async () => {
    try {
      const primeIndex = KNOWN_PRIMES[12]; // 41
      const identitySecret = randomFieldElement();
      const prevStateHash = randomFieldElement();
      const nonce = 1000n;
      const timestamp = nonce + 300000000000000000n; // Exactly at bound
      
      const identityHash = poseidon2(poseidon, primeIndex, identitySecret);
      const newStateHash = poseidon3(poseidon, prevStateHash, identityHash, nonce);
      
      const input = {
        stateHash: prevStateHash,
        primeIndex: primeIndex,
        timestamp: timestamp,
        newStateHash: newStateHash,
        prevStateHash: prevStateHash,
        nonce: nonce,
        identitySecret: identitySecret
      };
      
      const witness = await circuit.calculateWitness(input, true);
      await circuit.checkConstraints(witness);
      
      logger.success("Accept valid drift at boundary");
    } catch (err) {
      logger.failure("Accept valid drift at boundary", err);
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
