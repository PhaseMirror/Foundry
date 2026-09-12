// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title ResearchRegistry
/// @notice Verifies research-consent proofs and emits donation events. No PHI stored. Budgets are enforced off-chain.
contract ResearchRegistry is Ownable {
    IGroth16Verifier public verifier; // research_consent.circom

    // Optional allowlist of study IDs
    mapping(uint32 => bool) public allowedStudy;

    // Replay protection per donation
    mapping(bytes32 => bool) public usedNullifier;

    event VerifierSet(address v);
    event StudyAllowed(uint32 studyId, bool allowed);

    event ResearchDonation(
        uint32 indexed studyId,
        bytes32 indexed anonymityBudgetHash,
        bytes32 researchCommitment,
        bytes32 donationNullifier,
        bytes32 dataDigest
    );

    error InvalidProof();
    error NotAllowedStudy();
    error Replay();

    constructor(address owner_) Ownable(owner_) {}

    function setVerifier(address v) external onlyOwner { verifier = IGroth16Verifier(v); emit VerifierSet(v); }

    function setStudy(uint32 studyId, bool allowed) external onlyOwner { allowedStudy[studyId] = allowed; emit StudyAllowed(studyId, allowed); }

    /// Public signals order must match circuit:
    /// [0]=study_id [1]=anonymity_budget_hash [2]=research_commitment [3]=donation_nullifier
    function submit(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[4] calldata pub,
        bytes32 dataDigest
    ) external {
        require(address(verifier) != address(0), "verifier-not-set");
        // fixed-size pub (4) expected by generated verifier
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        uint32 studyId = uint32(pub[0]);
        if (allowedStudy[studyId] == false) revert NotAllowedStudy();

        bytes32 nul = bytes32(pub[3]);
        if (usedNullifier[nul]) revert Replay();
        usedNullifier[nul] = true;

        emit ResearchDonation(
            studyId,
            bytes32(pub[1]),
            bytes32(pub[2]),
            nul,
            dataDigest
        );
    }
}
