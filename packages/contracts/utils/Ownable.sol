// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable as OpenZeppelinOwnable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Local Ownable shim
/// @notice Wraps the repository's customized OpenZeppelin Ownable to allow explicit owner assignment.
abstract contract Ownable is OpenZeppelinOwnable {
    constructor(address initialOwner) OpenZeppelinOwnable(initialOwner) {
        require(initialOwner != address(0), "Ownable: initial owner is zero");
    }
}
