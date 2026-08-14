// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ILambdaLTraceConsumer.sol";

/// @notice ERC-4907 rentable NFT for lab access with user/expires
/// @dev Follows MTPI principles: Λ-Trace audit trail, no PII
contract LambdaLabPass4907 is ERC721, AccessControl, ILambdaLTraceConsumer {
    bytes32 public constant LAB_ADMIN_ROLE = keccak256("LAB_ADMIN_ROLE");

    struct UserInfo {
        address user;
        uint64 expires;
    }

    struct LabPassData {
        bytes32 primeIdHashHolder;
        bytes32 labAccessGrantUid; // EAS UID
        bool active;
    }

    mapping(uint256 => UserInfo) private _users;
    mapping(uint256 => LabPassData) public labPassOf;
    mapping(uint256 => mapping(bytes32 => bool)) private _ltraceLinked;

    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    event LabPassIssued(uint256 indexed tokenId, bytes32 indexed primeIdHashHolder, bytes32 labAccessGrantUid);
    event LabPassRevoked(uint256 indexed tokenId);

    constructor() ERC721("Lambda Lab Pass", "LLAB") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LAB_ADMIN_ROLE, msg.sender);
    }

    /// @notice Issue a lab pass
    function issueLabPass(
        address to,
        bytes32 primeIdHashHolder,
        bytes32 labAccessGrantUid,
        bytes32 ltraceHash
    ) external onlyRole(LAB_ADMIN_ROLE) returns (uint256 tokenId) {
        tokenId = uint256(keccak256(abi.encodePacked(primeIdHashHolder, labAccessGrantUid)));
        _safeMint(to, tokenId);

        labPassOf[tokenId] = LabPassData({
            primeIdHashHolder: primeIdHashHolder,
            labAccessGrantUid: labAccessGrantUid,
            active: true
        });

        _ltraceLinked[tokenId][ltraceHash] = true;
        emit LabPassIssued(tokenId, primeIdHashHolder, labAccessGrantUid);
        emit LTraceLinked(ltraceHash, msg.sender, tokenId);
    }

    /// @notice Set user (ERC-4907)
    function setUser(uint256 tokenId, address user, uint64 expires) external {
        require(_isAuthorized(ownerOf(tokenId), msg.sender, tokenId), "Not authorized");
        _users[tokenId] = UserInfo(user, expires);
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice Get user (ERC-4907)
    function userOf(uint256 tokenId) external view returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        }
        return address(0);
    }

    /// @notice Get user expires (ERC-4907)
    function userExpires(uint256 tokenId) external view returns (uint256) {
        return _users[tokenId].expires;
    }

    /// @notice Revoke lab pass
    function revokeLabPass(uint256 tokenId) external onlyRole(LAB_ADMIN_ROLE) {
        labPassOf[tokenId].active = false;
        emit LabPassRevoked(tokenId);
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
        return interfaceId == 0xad092b5c || super.supportsInterface(interfaceId); // 0xad092b5c is ERC-4907
    }
}
