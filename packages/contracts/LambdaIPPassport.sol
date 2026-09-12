// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ILambdaLTraceConsumer.sol";

/// @notice NFT representing an IP/project passport for tracking work provenance
/// @dev Follows MTPI principles: links to Λ-Trace for audit trail, zero PII
contract LambdaIPPassport is ERC721, AccessControl, ILambdaLTraceConsumer {
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    struct IPPassportData {
        bytes32 primeIdHashOwner;
        bytes32 workHash;
        bytes32 proposalEvaluationUid; // EAS UID
        bool active;
    }

    mapping(uint256 => IPPassportData) public passportOf;
    mapping(uint256 => mapping(bytes32 => bool)) private _ltraceLinked;

    event PassportIssued(
        uint256 indexed tokenId,
        bytes32 indexed primeIdHashOwner,
        bytes32 workHash,
        bytes32 proposalEvaluationUid
    );
    event PassportRevoked(uint256 indexed tokenId);

    constructor() ERC721("Lambda IP Passport", "LIP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CURATOR_ROLE, msg.sender);
    }

    /// @notice Issue a new IP passport
    function issuePassport(
        address to,
        bytes32 primeIdHashOwner,
        bytes32 workHash,
        bytes32 proposalEvaluationUid,
        bytes32 ltraceHash
    ) external onlyRole(CURATOR_ROLE) returns (uint256 tokenId) {
        tokenId = uint256(keccak256(abi.encodePacked(workHash, proposalEvaluationUid)));
        _safeMint(to, tokenId);

        passportOf[tokenId] = IPPassportData({
            primeIdHashOwner: primeIdHashOwner,
            workHash: workHash,
            proposalEvaluationUid: proposalEvaluationUid,
            active: true
        });

        _ltraceLinked[tokenId][ltraceHash] = true;
        emit PassportIssued(tokenId, primeIdHashOwner, workHash, proposalEvaluationUid);
        emit LTraceLinked(ltraceHash, msg.sender, tokenId);
    }

    /// @notice Revoke passport
    function revokePassport(uint256 tokenId) external onlyRole(CURATOR_ROLE) {
        passportOf[tokenId].active = false;
        emit PassportRevoked(tokenId);
    }

    /// @notice Check if Λ-Trace is linked to token
    function hasLTrace(uint256 tokenId, bytes32 ltraceHash) external view returns (bool) {
        return _ltraceLinked[tokenId][ltraceHash];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
