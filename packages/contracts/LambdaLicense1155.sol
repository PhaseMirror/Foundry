// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ILambdaLTraceConsumer.sol";

/// @notice ERC-1155 for license grants tied to work
/// @dev Follows MTPI principles: Λ-Trace audit trail, no PII
contract LambdaLicense1155 is ERC1155, AccessControl, ILambdaLTraceConsumer {
    bytes32 public constant LICENSOR_ROLE = keccak256("LICENSOR_ROLE");

    struct LicenseData {
        bytes32 workHash;
        bytes32 primeIdHashLicensee;
        bytes32 licenseGrantUid; // EAS UID
        bytes32 licenseTemplateHash;
        uint64 startTime;
        uint64 endTime;
    }

    mapping(uint256 => LicenseData) public licenseOf;
    mapping(uint256 => mapping(bytes32 => bool)) private _ltraceLinked;

    event LicenseGranted(
        uint256 indexed tokenId,
        bytes32 indexed workHash,
        bytes32 indexed primeIdHashLicensee,
        bytes32 licenseGrantUid,
        bytes32 licenseTemplateHash,
        uint64 startTime,
        uint64 endTime
    );

    constructor() ERC1155("https://lambda.example/api/license/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LICENSOR_ROLE, msg.sender);
    }

    /// @notice Grant a license
    function grantLicense(
        address to,
        bytes32 workHash,
        bytes32 primeIdHashLicensee,
        bytes32 licenseGrantUid,
        bytes32 licenseTemplateHash,
        uint64 startTime,
        uint64 endTime,
        bytes32 ltraceHash
    ) external onlyRole(LICENSOR_ROLE) returns (uint256 tokenId) {
        tokenId = uint256(keccak256(abi.encodePacked(workHash, primeIdHashLicensee, licenseGrantUid)));
        _mint(to, tokenId, 1, "");

        licenseOf[tokenId] = LicenseData({
            workHash: workHash,
            primeIdHashLicensee: primeIdHashLicensee,
            licenseGrantUid: licenseGrantUid,
            licenseTemplateHash: licenseTemplateHash,
            startTime: startTime,
            endTime: endTime
        });

        _ltraceLinked[tokenId][ltraceHash] = true;
        emit LicenseGranted(tokenId, workHash, primeIdHashLicensee, licenseGrantUid, licenseTemplateHash, startTime, endTime);
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
