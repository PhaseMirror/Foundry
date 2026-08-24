import { expect } from "chai";
import { ethers } from "hardhat";

describe("Vector A: Red Team Adversarial Audit — Circuit Breakers & Invariant Gating", () => {
  let registry: any;
  let mockConsentVerifier: any;
  let mockAttestVerifier: any;
  let mockBatchVerifier: any;
  let mockDilithiumVerifier: any;
  let deployer: any, authorizedAgent: any, rogueSigner: any, sidecar: any;

  const POSEIDON2_SEAL = ethers.keccak256(ethers.toUtf8Bytes("canonical_crmf_validity_seal_0x1"));
  const NULLIFIER_1 = ethers.keccak256(ethers.toUtf8Bytes("nullifier_step_42_nonce_1"));
  const NULLIFIER_2 = ethers.keccak256(ethers.toUtf8Bytes("nullifier_step_42_nonce_2"));

  beforeEach(async () => {
    [deployer, authorizedAgent, rogueSigner, sidecar] = await ethers.getSigners();

    // 1. Deploy Mocks for Verifiers
    const MockVerifier = await ethers.getContractFactory("MockVerifier");
    mockConsentVerifier = await MockVerifier.deploy();
    mockAttestVerifier = await MockVerifier.deploy();
    mockBatchVerifier = await MockVerifier.deploy();

    const DilithiumVerifier = await ethers.getContractFactory("DilithiumVerifier");
    mockDilithiumVerifier = await DilithiumVerifier.deploy();

    // 2. Deploy AttestationRegistry
    const AttestationRegistry = await ethers.getContractFactory("AttestationRegistry");
    registry = await AttestationRegistry.deploy(
      await mockConsentVerifier.getAddress(),
      await mockAttestVerifier.getAddress(),
      await mockBatchVerifier.getAddress(),
      ethers.ZeroAddress, // ConsentRegistryView
      await mockDilithiumVerifier.getAddress()
    );

    // 3. Configure authorized provider and sidecar whitelist
    await registry.setProvider(authorizedAgent.address, true);
    await registry.setSidecar(sidecar.address, true);

    // 4. Register mock 2592-byte Dilithium5 (ML-DSA-87) public key for authorizedAgent
    const dummyPk = new Uint8Array(2592).fill(0xaa);
    await registry.connect(authorizedAgent).registerDilithiumKey(dummyPk);

  });

  describe("Attack Vector 1: Concurrent Nullifier Collisions & Replay Exploits", () => {
    it("should successfully attest state on initial valid nullifier submission", async () => {
      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await authorizedAgent.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = authorizedAgent.address;
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, authorizedAgent.address, timestamp, ethers.ZeroHash, NULLIFIER_1];

      await expect(
        registry.connect(authorizedAgent).submitAttestation(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature
        )
      ).to.emit(registry, "Attested");
    });

    it("should strictly REVERT on duplicate nullifier submission (Anti-Replay Invariant)", async () => {
      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await authorizedAgent.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = authorizedAgent.address;
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, authorizedAgent.address, timestamp, ethers.ZeroHash, NULLIFIER_1];

      // Initial execution succeeds
      await registry.connect(authorizedAgent).submitAttestation(
        cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature
      );

      // Replay attempt with identical nullifier MUST revert
      await expect(
        registry.connect(authorizedAgent).submitAttestation(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature
        )
      ).to.be.revertedWithCustomError(registry, "Replay");
    });
  });

  describe("Attack Vector 2: Post-Quantum Dilithium5 Forgery & Key Perturbation", () => {
    it("should reject forged or corrupted Dilithium5 detached signatures", async () => {
      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await authorizedAgent.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = authorizedAgent.address;
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, authorizedAgent.address, timestamp, ethers.ZeroHash, NULLIFIER_2];

      // Corrupted 4627-byte Dilithium5 (ML-DSA-87) signature
      const corruptedSig = new Uint8Array(4627).fill(0xff);

      await expect(
        registry.connect(authorizedAgent).submitAttestationWithDilithium(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature, corruptedSig
        )
      ).to.be.revertedWithCustomError(registry, "InvalidDilithiumSignature");
    });

    it("should reject Dilithium submission from provider with unregistered public key", async () => {
      // Authorize rogueSigner in provider mapping but DO NOT register Dilithium key
      await registry.setProvider(rogueSigner.address, true);

      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await rogueSigner.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = rogueSigner.address;
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, rogueSigner.address, timestamp, ethers.ZeroHash, NULLIFIER_2];

      const dummySig = new Uint8Array(4627).fill(0x11);


      await expect(
        registry.connect(rogueSigner).submitAttestationWithDilithium(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature, dummySig
        )
      ).to.be.revertedWithCustomError(registry, "InvalidDilithiumPublicKey");
    });
  });

  describe("Attack Vector 3: Unauthorized Signer & Public Signal Mismatch", () => {
    it("should revert if signer is not an authorized provider", async () => {
      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await rogueSigner.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = rogueSigner.address;
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, rogueSigner.address, timestamp, ethers.ZeroHash, NULLIFIER_2];

      await expect(
        registry.connect(rogueSigner).submitAttestation(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature
        )
      ).to.be.revertedWithCustomError(registry, "NotProvider");
    });

    it("should revert if public signals between consent and attestation proofs diverge", async () => {
      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await authorizedAgent.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = rogueSigner.address; // Intentionally mismatched provider
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, authorizedAgent.address, timestamp, ethers.ZeroHash, NULLIFIER_2];

      await expect(
        registry.connect(authorizedAgent).submitAttestation(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature
        )
      ).to.be.revertedWithCustomError(registry, "Mismatch");
    });
  });

  describe("Attack Vector 4: Fail-Closed Circuit Breaker Interlock (L0_HALT)", () => {
    it("should reject triggerL0Halt from unauthorized caller", async () => {
      const reason = ethers.keccak256(ethers.toUtf8Bytes("Unauthorized halt attempt"));
      await expect(
        registry.connect(rogueSigner).triggerL0Halt(reason)
      ).to.be.revertedWithCustomError(registry, "NotProvider");
    });

    it("should successfully trigger L0_HALT and lock cluster-wide state mutations", async () => {
      const reason = ethers.keccak256(ethers.toUtf8Bytes("PM001_SPECTRAL_RADIUS_BREACH"));
      
      // Sidecar triggers constitutional halt
      await expect(registry.connect(sidecar).triggerL0Halt(reason))
        .to.emit(registry, "GovernanceHalt")
        .withArgs(sidecar.address, reason);

      expect(await registry.isL0Halted()).to.equal(true);

      // Attempting any subsequent attestation MUST revert under onlySafeMode
      const timestamp = Math.floor(Date.now() / 1000);
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [POSEIDON2_SEAL, timestamp]);
      const signature = await authorizedAgent.signMessage(ethers.getBytes(msgHash));

      const cA = [0, 0], cB = [[0, 0], [0, 0]], cC = [0, 0];
      const consentPub = new Array(10).fill(0);
      consentPub[2] = authorizedAgent.address;
      consentPub[7] = ethers.ZeroHash;

      const aA = [0, 0], aB = [[0, 0], [0, 0]], aC = [0, 0];
      const attestPub = [POSEIDON2_SEAL, authorizedAgent.address, timestamp, ethers.ZeroHash, NULLIFIER_2];

      await expect(
        registry.connect(authorizedAgent).submitAttestation(
          cA, cB, cC, consentPub, aA, aB, aC, attestPub, signature
        )
      ).to.be.revertedWith("L0_HALT: Protocol suspended by Phase Mirror");
    });
  });
});
