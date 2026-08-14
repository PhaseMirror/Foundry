// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ILambdaLTraceConsumer.sol";

/// @notice SBT representing ΛProof membership gated by Λ-Trace + EAS
/// @dev Follows MTPI principles: attestations are linked via EAS UIDs, no PII stored
contract LambdaMembershipSBT is ERC721Enumerable, AccessControl, ILambdaLTraceConsumer {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct MembershipData {
        bytes32 primeIdHash;
        bytes32 membershipAttestationUid; // EAS UID
        uint8 tier;
        bool active;
    }

    mapping(uint256 => MembershipData) public membershipOf;
    // tokenId => ltraceHash => linked?
    mapping(uint256 => mapping(bytes32 => bool)) private _ltraceLinked;

    event MembershipIssued(
        uint256 indexed tokenId,
        bytes32 indexed primeIdHash,
        bytes32 membershipAttestationUid,
        uint8 tier
    );
    event MembershipRevoked(uint256 indexed tokenId);

    constructor() ERC721("Lambda Membership", "LMEM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    /// @notice Issue a new membership SBT
    function issueMembership(
        address to,
        bytes32 primeIdHash,
        bytes32 membershipAttestationUid,
        uint8 tier,
        bytes32 ltraceHash
    ) external onlyRole(ISSUER_ROLE) returns (uint256 tokenId) {
        tokenId = uint256(keccak256(abi.encodePacked(primeIdHash, membershipAttestationUid)));
        _safeMint(to, tokenId);

        membershipOf[tokenId] = MembershipData({
            primeIdHash: primeIdHash,
            membershipAttestationUid: membershipAttestationUid,
            tier: tier,
            active: true
        });

        _ltraceLinked[tokenId][ltraceHash] = true;
        emit MembershipIssued(tokenId, primeIdHash, membershipAttestationUid, tier);
        emit LTraceLinked(ltraceHash, msg.sender, tokenId);
    }

    /// @notice Revoke membership
    function revokeMembership(uint256 tokenId) external onlyRole(ISSUER_ROLE) {
        membershipOf[tokenId].active = false;
        emit MembershipRevoked(tokenId);
    }

    /// @notice Check if Λ-Trace is linked to token
    function hasLTrace(uint256 tokenId, bytes32 ltraceHash) external view returns (bool) {
        return _ltraceLinked[tokenId][ltraceHash];
    }

    /// @notice Get primeIdHash for an address (assumes one token per address)
    /// @dev Returns the primeIdHash of the first token owned by the address
    /// @dev Returns bytes32(0) if address has no membership
    function getPrimeIdHashForAddress(address owner) external view returns (bytes32) {
        uint256 balance = balanceOf(owner);
        if (balance == 0) {
            return bytes32(0);
        }
        // Get the first token ID for this owner
        // Note: In practice, each address should only have one SBT
        uint256 tokenId = tokenOfOwnerByIndex(owner, 0);
        return membershipOf[tokenId].primeIdHash;
    }

    /// @notice Enforce soulbound semantics
    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0)) {
            revert("Token is soulbound");
        }
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
