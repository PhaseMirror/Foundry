// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "./utils/Ownable.sol";

contract PolicyRegistry is Ownable {
    /// @dev Set initial owner to deployer.
    constructor() Ownable(msg.sender) {}

    event PolicyAdded(uint32 indexed version, bytes32 policyHash);
    event Frozen();

    mapping(uint32 => bytes32) public versionHash; // version → poseidon hash of canonical policy JSON
    uint32 public latest;
    bool public frozen;

    function add(uint32 version, bytes32 policyHash) external onlyOwner {
        require(!frozen, "frozen");
        require(version > latest, "version not monotonic");
        versionHash[version] = policyHash;
        latest = version;
        emit PolicyAdded(version, policyHash);
    }

    function freeze() external onlyOwner { frozen = true; emit Frozen(); }
}
