import { ethers } from "hardhat";
import { readFileSync } from "fs";

async function main() {
  const contractAddress = process.env.ZMT_VERIFIER_ADDRESS;
  if (!contractAddress) throw new Error("ZMT_VERIFIER_ADDRESS not set");

  const receiptBytes = readFileSync("artifacts/stark_receipt.bin");
  // Assuming the journal is stored separately or extracted from the receipt struct locally.
  const journalBytes = readFileSync("artifacts/stark_journal.bin"); 

  const ZmtVerifier = await ethers.getContractAt("ZmtVerifier", contractAddress);
  
  console.log("Submitting STARK receipt to Sepolia...");
  const tx = await ZmtVerifier.verifyHSNormBound(receiptBytes, journalBytes);
  console.log("Transaction sent! Hash:", tx.hash);

  const receipt = await tx.wait();
  console.log("Transaction mined in block:", receipt.blockNumber);
  
  const verifiedNorm = await ZmtVerifier.latestHsNormSq();
  console.log("Blockchain confirms HS-norm (scaled):", verifiedNorm.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
