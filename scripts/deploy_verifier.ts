import { ethers } from "hardhat";
import { readFileSync } from "fs";

async function main() {
  // Sepolia RISC Zero verifier address
  const verifierAddress = "0x..."; 
  // Fetch from Cargo RISC Zero build artifacts
  const imageId = "0x" + readFileSync("artifacts/image_id.txt", "utf8").trim();

  console.log("Deploying ZmtVerifier with ImageID:", imageId);

  const ZmtVerifier = await ethers.getContractFactory("ZmtVerifier");
  const contract = await ZmtVerifier.deploy(verifierAddress, imageId);
  await contract.waitForDeployment();

  console.log("ZmtVerifier successfully deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
