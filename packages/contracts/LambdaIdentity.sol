// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Soulbound identity NFT following MTPI principles.
/// @dev Each prime identity gets one token. Token is bound to an ERC-6551 account (TBA).
///      No surveillance: only stores Poseidon-hashed prime identity commitments.
contract LambdaIdentity is ERC721, Ownable {
    // primeIdHash => tokenId
    mapping(bytes32 => uint256) public primeIdToTokenId;
    mapping(uint256 => bool) public soulbound;

    event IdentityMinted(address indexed to, uint256 indexed tokenId, bytes32 indexed primeIdHash);

    constructor() ERC721("Lambda Identity", "LID") Ownable(msg.sender) {}

    /// @notice Mint a new soulbound identity NFT
    /// @param to Recipient address (typically their TBA)
    /// @param primeIdHash Poseidon hash of the prime identity
    function mintIdentity(address to, bytes32 primeIdHash) external onlyOwner returns (uint256 tokenId) {
        require(primeIdToTokenId[primeIdHash] == 0, "primeId already used");
        
        tokenId = uint256(keccak256(abi.encodePacked(primeIdHash, block.timestamp)));
        _safeMint(to, tokenId);
        
        primeIdToTokenId[primeIdHash] = tokenId;
        soulbound[tokenId] = true;
        
        emit IdentityMinted(to, tokenId, primeIdHash);
    }

    /// @notice Enforce soulbound semantics - override transfers
    function _update(address to, uint256 tokenId, address auth) 
        internal 
        virtual 
        override 
        returns (address) 
    {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0))
        // Block transfers if soulbound
        if (from != address(0) && soulbound[tokenId]) {
            revert("Token is soulbound");
        }
        
        return super._update(to, tokenId, auth);
    }
}
