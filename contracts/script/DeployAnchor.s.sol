// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../AnchorContract.sol";

contract DeployAnchor is Script {
    function run() external {
        // Read the deployer private key from the environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Use a mock verifier address for testnet deployment until the actual
        // Circom Verifier.sol is compiled and deployed.
        // Also provide a genesis state hash for the Bindu.
        address mockVerifier = address(0x1234567890123456789012345678901234567890);
        bytes32 genesisState = keccak256(abi.encodePacked("BINDU_GENESIS_STATE"));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the AnchorContract
        AnchorContract anchor = new AnchorContract(mockVerifier, genesisState);

        vm.stopBroadcast();

        // Output the deployed address so it can be registered in the Materia Commons
        console.log("PhaseMirror AnchorContract deployed to:", address(anchor));
    }
}
