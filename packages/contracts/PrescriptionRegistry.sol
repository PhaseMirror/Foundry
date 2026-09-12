// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title PrescriptionRegistry
/// @notice Stateless verifier + event for validated prescriptions. No PHI stored.
contract PrescriptionRegistry is Ownable {
    IGroth16Verifier public verifier; // prescription.circom

    // Allowlist prescribers
    mapping(address => bool) public prescriberAllowed;
    event VerifierSet(address v);
    event PrescriberAllowed(address prescriber, bool allowed);
    event PrescriptionProved(bytes32 indexed rxCommitment, address indexed prescriber, uint64 expiryEpoch);

    error InvalidProof();
    error NotPrescriber();

    constructor(address owner_) Ownable(owner_) {}

    function setVerifier(address v) external onlyOwner { verifier = IGroth16Verifier(v); emit VerifierSet(v); }
    function setPrescriber(address addr, bool allowed) external onlyOwner { prescriberAllowed[addr]=allowed; emit PrescriberAllowed(addr, allowed); }

    /// Public signals order must match circuit:
    /// [0]=drug_code [1]=max_fills [2]=fills_used [3]=dosage_hash [4]=expiry_epoch
    /// [5]=prescriber_pk [6]=pharmacy_pk [7]=rx_commitment [8]=dispense_nullifier
    function prove(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[9] calldata pub
    ) external {
        // fixed-size pub (9) expected by generated verifier
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        address prescriber = address(uint160(pub[5]));
        if (!prescriberAllowed[prescriber]) revert NotPrescriber();

        emit PrescriptionProved(bytes32(pub[7]), prescriber, uint64(pub[4]));
    }
}
