// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IDilithiumVerifier} from "./IDilithiumVerifier.sol";

/// @title AnchorRegistry
/// @notice UAC State Anchor — blockchain-backed immutable operational record (ADR-PML-055).
/// @dev Periodically accepts a Merkle root of operational state and records it against the
///      submitting block number. Submission is gated to an allowlisted sidecar via ECDSA,
///      matching the `authorizedSidecars` pattern in AttestationRegistry.sol.
///      Dual-signing via Dilithium (ADR-PML-051) is supported through `submitRootWithDilithium`.
contract AnchorRegistry is IERC165 {
    using ECDSA for bytes32;

    mapping(address => bool) public authorizedSidecars;
    mapping(uint256 => bytes32) public rootAtBlock;
    bytes32[] public anchors;

    // ADR-PML-051: Dilithium public keys registered by sidecars.
    mapping(address => bytes) public dilithiumPublicKeys;
    IDilithiumVerifier public dilithiumVerifier;

    event SidecarAuthorized(address indexed sidecar, bool allowed);
    event AnchorSubmitted(bytes32 indexed root, uint256 timestamp, uint256 blockNumber);
    event AnchorSubmittedPQC(bytes32 indexed root, uint256 timestamp, uint256 blockNumber, bool hasDilithium);
    event DilithiumVerifierSet(address verifier);
    event DilithiumKeyRegistered(address indexed sidecar, bytes publicKey);

    error NotSidecar();
    error ZeroRoot();
    error InvalidDilithiumSignature();
    error InvalidDilithiumPublicKey();

    constructor(address initialSidecar, address initialDilithiumVerifier) {
        if (initialSidecar != address(0)) {
            authorizedSidecars[initialSidecar] = true;
            emit SidecarAuthorized(initialSidecar, true);
        }
        dilithiumVerifier = IDilithiumVerifier(initialDilithiumVerifier);
        emit DilithiumVerifierSet(initialDilithiumVerifier);
    }

    function setSidecar(address sidecar, bool allowed) external {
        authorizedSidecars[sidecar] = allowed;
        emit SidecarAuthorized(sidecar, allowed);
    }

    function setDilithiumVerifier(address verifier) external {
        dilithiumVerifier = IDilithiumVerifier(verifier);
        emit DilithiumVerifierSet(verifier);
    }

    function registerDilithiumKey(bytes calldata publicKey) external {
        if (!authorizedSidecars[msg.sender]) revert NotSidecar();
        dilithiumPublicKeys[msg.sender] = publicKey;
        emit DilithiumKeyRegistered(msg.sender, publicKey);
    }

    /// @notice Submits a daily/periodic state root to the chain (ECDSA only).
    /// @param root The SHA-256 Merkle root of all operational state categories.
    /// @param timestamp Wall-clock timestamp (seconds) asserted by the sidecar.
    /// @param signature ECDSA over keccak256(abi.encodePacked(root, timestamp)).
    function submitRoot(bytes32 root, uint256 timestamp, bytes calldata signature) external {
        if (root == bytes32(0)) revert ZeroRoot();

        bytes32 msgHash = keccak256(abi.encodePacked(root, timestamp));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address signer = ECDSA.recover(ethSignedHash, signature);
        if (!authorizedSidecars[signer]) revert NotSidecar();

        uint256 blockNumber = block.number;
        rootAtBlock[blockNumber] = root;
        anchors.push(root);

        emit AnchorSubmitted(root, timestamp, blockNumber);
    }

    /// @notice Submits a daily/periodic state root with optional Dilithium5 dual-signature.
    /// @param root The SHA-256 Merkle root of all operational state categories.
    /// @param timestamp Wall-clock timestamp (seconds) asserted by the sidecar.
    /// @param ecdsaSignature ECDSA over keccak256(abi.encodePacked(root, timestamp)).
    /// @param dilithiumSignature Dilithium5 detached signature over the same message hash (optional).
    function submitRootWithDilithium(
        bytes32 root,
        uint256 timestamp,
        bytes calldata ecdsaSignature,
        bytes calldata dilithiumSignature
    ) external {
        if (root == bytes32(0)) revert ZeroRoot();

        bytes32 msgHash = keccak256(abi.encodePacked(root, timestamp));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address signer = ECDSA.recover(ethSignedHash, ecdsaSignature);
        if (!authorizedSidecars[signer]) revert NotSidecar();

        // ADR-PML-051: verify Dilithium signature if provided.
        if (dilithiumSignature.length > 0) {
            if (address(dilithiumVerifier) == address(0)) revert InvalidDilithiumSignature();
            bytes memory storedPk = dilithiumPublicKeys[signer];
            if (storedPk.length == 0) revert InvalidDilithiumPublicKey();
            if (!dilithiumVerifier.verify(signer, msgHash, dilithiumSignature)) revert InvalidDilithiumSignature();
        }

        uint256 blockNumber = block.number;
        rootAtBlock[blockNumber] = root;
        anchors.push(root);

        emit AnchorSubmittedPQC(root, timestamp, blockNumber, dilithiumSignature.length > 0);
    }

    function latestRoot() external view returns (bytes32) {
        uint256 len = anchors.length;
        return len == 0 ? bytes32(0) : anchors[len - 1];
    }

    function anchorCount() external view returns (uint256) {
        return anchors.length;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
