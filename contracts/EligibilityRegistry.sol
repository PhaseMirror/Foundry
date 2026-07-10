// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title EligibilityRegistry
/// @notice Verifies eligibility proofs and optionally consumes a per-code nullifier when attaching a claim digest.
contract EligibilityRegistry is Ownable {
    IGroth16Verifier public verifier; // eligibility.circom

    // Allowlist for payers
    mapping(address => bool) public payerAllowed;

    // Optional replay guard for claim tokens (eligibility_nullifier)
    mapping(bytes32 => bool) public consumed;

    event VerifierSet(address verifier);
    event PayerAllowed(address payer, bool allowed);
    event EligibilityProved(address indexed payer, uint16 cptCode, uint8 coverageClass, bytes32 costShareHash, bytes32 commitment);
    event ClaimSubmitted(bytes32 indexed claimDigest, address indexed payer, uint16 cptCode, uint8 coverageClass, bytes32 nullifier);

    error InvalidProof();
    error NotPayer();
    error AlreadyConsumed();

    constructor(address owner_) Ownable(owner_) {}

    function setVerifier(address v) external onlyOwner {
        verifier = IGroth16Verifier(v);
        emit VerifierSet(v);
    }

    function setPayer(address payer, bool allowed) external onlyOwner {
        payerAllowed[payer] = allowed;
        emit PayerAllowed(payer, allowed);
    }

    /// Public signals order must match circuit:
    /// [0]=payer_pk [1]=cpt_code [2]=coverage_class [3]=cost_share_hash [4]=eligibility_commitment [5]=eligibility_nullifier
    function proveEligibility(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[6] calldata pub
    ) public {
        // fixed-size pub (6) expected by generated verifier
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        address payer = address(uint160(pub[0]));
        if (!payerAllowed[payer]) revert NotPayer();

        emit EligibilityProved(
            payer,
            uint16(pub[1]),
            uint8(pub[2]),
            bytes32(pub[3]),
            bytes32(pub[4])
        );
    }

    /// Attach a claim digest; consumes the nullifier to prevent re-use if desired.
    function submitClaim(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[6] calldata pub,
        bytes32 claimDigest
    ) external {
        // Re-verify eligibility
        proveEligibility(pA, pB, pC, pub);

        bytes32 nullifier = bytes32(pub[5]);
        if (consumed[nullifier]) revert AlreadyConsumed();
        consumed[nullifier] = true;

        emit ClaimSubmitted(
            claimDigest,
            address(uint160(pub[0])),
            uint16(pub[1]),
            uint8(pub[2]),
            nullifier
        );
    }
}
