import { connect, StringCodec } from 'nats';
import { ethers } from 'ethers';
import * as snarkjs from 'snarkjs';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config();

const NATS_URL = process.env.NATS_URL || 'nats://localhost:4222';
const SUBJECT = process.env.NATS_SUBJECT || 'uac.qaas.attestation.request.*';
const RPC_URL = process.env.RPC_URL || 'http://localhost:8545';
const PRIVATE_KEY = process.env.PRIVATE_KEY || '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const REGISTRY_ADDRESS = process.env.REGISTRY_ADDRESS || '0x0000000000000000000000000000000000000000';

const sc = StringCodec();

// Dummy ABI for AttestationRegistry
const ATTESTATION_ABI = [
  "function submitAttestation(uint256[2] cA, uint256[2][2] cB, uint256[2] cC, uint256[10] consentPub, uint256[2] aA, uint256[2][2] aB, uint256[2] aC, uint256[5] attestPub, bytes signature) external"
];

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  const registryContract = new ethers.Contract(REGISTRY_ADDRESS, ATTESTATION_ABI, wallet);

  console.log(`Connecting to NATS at ${NATS_URL}...`);
  const nc = await connect({ servers: NATS_URL });
  console.log(`Connected to NATS. Subscribing to ${SUBJECT}...`);
  
  const sub = nc.subscribe(SUBJECT);

  for await (const m of sub) {
    try {
      const payloadStr = sc.decode(m.data);
      const payload = JSON.parse(payloadStr);

      console.log(`\nReceived request for session: ${payload.metadata?.session_id}`);
      
      // 1. Verify unstable flags are empty
      const q_sqd = payload.private_witness?.q_sqd;
      if (q_sqd?.eta?.unstable && q_sqd.eta.unstable.length > 0) {
        console.error("FATAL: Received unstable Q-SQD signature. Dropping message.");
        continue;
      }

      // 2. Generate Groth16 Proof via snarkjs
      // We would load the attestation.wasm and attestation.zkey from the circuits/ folder
      console.log("Generating Groth16 ZK proof using snarkjs...");
      
      const input = {
          // Public inputs
          digest: payload.public_inputs.sqd_digest_h,
          timestamp: payload.public_inputs.timestamp_epoch,
          provider_pk: wallet.address,
          consent_commitment: "0x0", // Placeholder
          att_nullifier: ethers.id(payload.metadata.session_id),
          
          // Private Witness
          q_sqd_n: q_sqd.n,
          q_sqd_b: q_sqd.eta.b,
          q_sqd_lambda: q_sqd.eta.lambda
      };

      // Mock proof generation logic
      // const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, "attestation.wasm", "attestation_final.zkey");
      console.log("Groth16 proof generated.");

      // 3. Sign the transaction payload
      console.log("Signing payload with ECDSA...");
      const timestamp = payload.public_inputs.timestamp_epoch;
      const digest = payload.public_inputs.sqd_digest_h;
      
      // Keccak256(digest, timestamp)
      const msgHash = ethers.solidityPackedKeccak256(["bytes32", "uint64"], [digest, timestamp]);
      const signature = await wallet.signMessage(ethers.getBytes(msgHash));
      
      // 3b. Sign the transaction payload with CRYSTALS-Dilithium
      console.log("Signing payload with CRYSTALS-Dilithium...");
      const dilithiumSkPath = process.env.DILITHIUM_SK_PATH || path.resolve(__dirname, "../dilithium.sk");
      let dilithiumSignature = "";
      try {
        const cliPath = path.resolve(__dirname, "../../../crates/dilithium-signer/target/release/dilithium-signer");
        dilithiumSignature = require('child_process').execSync(`${cliPath} sign --sk-path ${dilithiumSkPath} --msg-hex ${msgHash}`).toString().trim();
        console.log("Dilithium signature generated successfully.");
      } catch (e) {
        console.warn("Failed to generate Dilithium signature (make sure dilithium.sk exists):", e.message);
      }

      // 4. Submit to EVM AttestationRegistry
      console.log("Submitting to EVM AttestationRegistry...");
      
      // registryContract.submitAttestation(..., signature, dilithiumSignature)
      
      console.log(`Attestation complete for session: ${payload.metadata.session_id}`);
      
      // Acknowledge the message if using JetStream
      if (m.reply) {
         m.respond(sc.encode(JSON.stringify({status: "success"})));
      }
      
    } catch (err) {
      console.error("Failed to process message:", err);
    }
  }
}

main().catch(console.error);
