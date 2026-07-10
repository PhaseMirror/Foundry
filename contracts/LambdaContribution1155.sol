// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ILambdaLTraceConsumer.sol";

/// @notice ERC-1155 for contribution records linked to projects
/// @dev Follows MTPI principles: Λ-Trace audit trail, no PII
contract LambdaContribution1155 is ERC1155, AccessControl, ILambdaLTraceConsumer {
    bytes32 public constant RECORDER_ROLE = keccak256("RECORDER_ROLE");

    struct ContributionData {
        bytes32 projectPassportIdHash;
        bytes32 primeIdHashContributor;
        bytes32 contributionRecordUid; // EAS UID
        uint8 roleEnum;
    }

    mapping(uint256 => ContributionData) public contributionOf;
    mapping(uint256 => mapping(bytes32 => bool)) private _ltraceLinked;

    event ContributionRecorded(
        uint256 indexed tokenId,
        bytes32 indexed projectPassportIdHash,
        bytes32 indexed primeIdHashContributor,
        bytes32 contributionRecordUid,
        uint8 roleEnum
    );

    constructor() ERC1155("https://lambda.example/api/contribution/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RECORDER_ROLE, msg.sender);
    }

    /// @notice Record a contribution
    function recordContribution(
        address to,
        bytes32 projectPassportIdHash,
        bytes32 primeIdHashContributor,
        bytes32 contributionRecordUid,
        uint8 roleEnum,
        bytes32 ltraceHash
    ) external onlyRole(RECORDER_ROLE) returns (uint256 tokenId) {
        tokenId = uint256(keccak256(abi.encodePacked(projectPassportIdHash, primeIdHashContributor, contributionRecordUid)));
        _mint(to, tokenId, 1, "");

        contributionOf[tokenId] = ContributionData({
            projectPassportIdHash: projectPassportIdHash,
            primeIdHashContributor: primeIdHashContributor,
            contributionRecordUid: contributionRecordUid,
            roleEnum: roleEnum
        });

        _ltraceLinked[tokenId][ltraceHash] = true;
        emit ContributionRecorded(tokenId, projectPassportIdHash, primeIdHashContributor, contributionRecordUid, roleEnum);
        emit LTraceLinked(ltraceHash, msg.sender, tokenId);
    }

    /// @notice Check if Λ-Trace is linked to token
    function hasLTrace(uint256 tokenId, bytes32 ltraceHash) external view returns (bool) {
        return _ltraceLinked[tokenId][ltraceHash];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
