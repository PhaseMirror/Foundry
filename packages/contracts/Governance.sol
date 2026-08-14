// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./interfaces/IVerifier.sol";
import "./MTPI_Core.sol";
import {Ownable} from "./utils/Ownable.sol";
import "./interfaces/IGovernance.sol";

/// @title Governance
/// @notice Minimal governance parameters and allowlist holder, matching Governance.json ABI.
contract Governance is Ownable, IGovernance {
    // references
    MTPI_Core public mtpiCore;
    IVerifier public rootVerifier;

    // params
    uint256 public epsilon;          // drift budget
    uint256 public minPrimeIndex;    // prime gate floor
    bytes32 public constitutionHash; // Ξ-Constitution anchor

    // actors
    mapping(address => bool) public lawfulActors;

    // events
    event GovernanceParamsUpdated(uint256 epsilon, uint256 minPrimeIndex, bytes32 constitutionHash);
    event LawfulActorSet(address actor, bool allowed);

    constructor(address core_, address rootVerifier_) Ownable(msg.sender) {
        require(core_ != address(0) && rootVerifier_ != address(0), "zero");
        mtpiCore = MTPI_Core(core_);
        rootVerifier = IVerifier(rootVerifier_);
    }

    function setMtpiCore(address core_) external onlyOwner {
        require(core_ != address(0), "zero");
        mtpiCore = MTPI_Core(core_);
    }

    function setRootVerifier(address v_) external onlyOwner {
        require(v_ != address(0), "zero");
        rootVerifier = IVerifier(v_);
    }

    function setParams(uint256 _epsilon, uint256 _minPrimeIndex, bytes32 _constitutionHash) external onlyOwner {
        epsilon = _epsilon;
        minPrimeIndex = _minPrimeIndex;
        constitutionHash = _constitutionHash;
        emit GovernanceParamsUpdated(epsilon, minPrimeIndex, constitutionHash);
    }

    function setLawfulActor(address who, bool ok) external onlyOwner {
        lawfulActors[who] = ok;
        emit LawfulActorSet(who, ok);
    }

    // IGovernance view
    function isApproved(address actor) external view override returns (bool) {
        return lawfulActors[actor];
    }

    function validateTransition(
        bytes32 /*proofHash*/,
        uint256 primeIndex,
        uint16 driftBps
    ) external view override returns (bool ok) {
        if (!lawfulActors[msg.sender]) return false;
        if (driftBps > uint16(epsilon)) return false;
        if (primeIndex < minPrimeIndex) return false;
        if (!_cheapPrimeGate(primeIndex)) return false;
        return true;
    }

    function _cheapPrimeGate(uint256 n) internal pure returns (bool) {
        if (n < 2) return false;
        if (n == 2) return true;
        if (n % 2 == 0) return false;
        return true;
    }
}
