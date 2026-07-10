// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ILambdaAssetRegistry.sol";

contract LambdaAssetRegistry is ILambdaAssetRegistry, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => AssetInfo) private _assets;

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function registerAsset(address token, AssetInfo calldata info)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(token != address(0), "invalid token");
        require(info.allowed, "must be allowed");
        require(_assets[token].policyRefHash == bytes32(0), "asset exists");

        _assets[token] = info;
        emit AssetRegistered(token, info);
    }

    function updateAsset(address token, AssetInfo calldata info)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(token != address(0), "invalid token");
        require(_assets[token].policyRefHash != bytes32(0), "asset missing");

        _assets[token] = info;
        emit AssetUpdated(token, info);
    }

    function disableAsset(address token) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "invalid token");
        AssetInfo storage existing = _assets[token];
        require(existing.policyRefHash != bytes32(0), "asset missing");

        existing.allowed = false;
        emit AssetDisabled(token);
    }

    function getAssetInfo(address token)
        external
        view
        override
        returns (AssetInfo memory)
    {
        return _assets[token];
    }

    function isAssetAllowed(address token)
        external
        view
        override
        returns (bool)
    {
        return _assets[token].allowed;
    }

    function riskTierOf(address token)
        external
        view
        override
        returns (RiskTier)
    {
        return _assets[token].riskTier;
    }
}
