import hre from "hardhat";

async function main() {
  console.log("==================================================");
  console.log(" MSC Pilot Grant Distribution — Triad Governance  ");
  console.log(" Network: Sepolia Testnet                         ");
  console.log("==================================================\n");

  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();
  
  console.log(`Authenticated Authority: ${deployer.address}`);
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`Authority ETH Balance: ${ethers.formatEther(balance)} ETH\n`);

  // Target MSC Governance Contract Address (Environment or Fallback)
  const mscAddress = process.env.MSC_TOKEN_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  if (mscAddress === "0x0000000000000000000000000000000000000000") {
    console.warn("WARNING: MSC_TOKEN_ADDRESS not set in environment. Running in dry-run mode.");
  }

  // Load the MSC contract abstraction (assuming a standard ERC20 / Governance Token interface)
  const MSC = await ethers.getContractFactory("MultiplicitySovereignCore");
  const mscToken = MSC.attach(mscAddress);

  // The 27 target participant addresses for the pilot Triad governance cycle
  // (Placeholder array to be populated with live recruiter addresses)
  const triadParticipants = [
    // TODO: Populate with the 27 live audited addresses
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222",
    "0x3333333333333333333333333333333333333333"
  ];

  if (triadParticipants.length !== 27 && mscAddress !== "0x0000000000000000000000000000000000000000") {
      console.warn(`NOTICE: Expected 27 addresses for Triad initialization, but found ${triadParticipants.length}.`);
  }

  // Define the pilot grant payload per participant (e.g., 100 MSC tokens)
  const grantAmount = ethers.parseUnits("100", 18); 

  console.log(`Initiating batch transfer of ${ethers.formatUnits(grantAmount, 18)} MSC per participant...`);
  
  let successCount = 0;
  for (let i = 0; i < triadParticipants.length; i++) {
    const participant = triadParticipants[i];
    console.log(`[${i + 1}/${triadParticipants.length}] Transferring to ${participant}...`);
    
    if (mscAddress !== "0x0000000000000000000000000000000000000000") {
      try {
        const tx = await mscToken.transfer(participant, grantAmount);
        await tx.wait(1); // Wait for 1 confirmation
        console.log(`   ✓ Tx Hash: ${tx.hash}`);
        successCount++;
      } catch (e) {
        console.error(`   ✗ FAILED transfer to ${participant}:`, e);
      }
    } else {
      console.log(`   (Dry Run) Transfer simulated.`);
      successCount++;
    }
  }

  console.log("\n==================================================");
  console.log(` Distribution Complete. Successful Grants: ${successCount}/${triadParticipants.length}`);
  console.log("==================================================");
}

main().catch((error) => {
  console.error("Fatal error during distribution:", error);
  process.exitCode = 1;
});
