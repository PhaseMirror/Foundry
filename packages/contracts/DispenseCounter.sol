// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title DispenseCounter
/// @notice Prevents double spend of a prescription fill using a per‑fill nullifier.
/// Also checks expiry, prescriber allowlist, and binds the pharmacy to msg.sender.
contract DispenseCounter is Ownable {
    IGroth16Verifier public verifier; // prescription.circom

    mapping(address => bool) public prescriberAllowed;
    mapping(address => bool) public pharmacyAllowed;

    mapping(bytes32 => bool) public spent; // dispense_nullifier -> used

    event VerifierSet(address v);
    event PrescriberAllowed(address prescriber, bool allowed);
    event PharmacyAllowed(address pharmacy, bool allowed);
    event Dispensed(bytes32 indexed rxCommitment, uint8 fillIndex, address indexed pharmacy, uint64 ts);

    error InvalidProof();
    error NotPrescriber();
    error NotPharmacy();
    error Expired();
    error Replay();

    constructor(address owner_) Ownable(owner_) {}

    function setVerifier(address v) external onlyOwner { verifier = IGroth16Verifier(v); emit VerifierSet(v); }
    function setPrescriber(address a, bool allowed) external onlyOwner { prescriberAllowed[a]=allowed; emit PrescriberAllowed(a, allowed); }
    function setPharmacy(address a, bool allowed) external onlyOwner { pharmacyAllowed[a]=allowed; emit PharmacyAllowed(a, allowed); }

    /// Public signals (same order as circuit):
    /// [0]=drug_code [1]=max_fills [2]=fills_used [3]=dosage_hash [4]=expiry_epoch
    /// [5]=prescriber_pk [6]=pharmacy_pk [7]=rx_commitment [8]=dispense_nullifier
    function dispense(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[9] calldata pub
    ) external {
        // fixed-size pub (9) expected by generated verifier
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        address prescriber = address(uint160(pub[5]));
        if (!prescriberAllowed[prescriber]) revert NotPrescriber();

        address pharmacy = address(uint160(pub[6]));
        if (pharmacy != msg.sender || !pharmacyAllowed[pharmacy]) revert NotPharmacy();

        // time check off‑circuit
        if (block.timestamp > pub[4]) revert Expired();

        // prevent double spend
        bytes32 nullifier = bytes32(pub[8]);
        if (spent[nullifier]) revert Replay();
        spent[nullifier] = true;

        // fill index is pub[2] + 1
        emit Dispensed(bytes32(pub[7]), uint8(pub[2] + 1), pharmacy, uint64(block.timestamp));
    }
}
