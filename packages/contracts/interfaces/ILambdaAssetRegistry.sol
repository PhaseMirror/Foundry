// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILambdaAssetRegistry {
    enum RiskTier {
        LOW,
        MEDIUM,
        HIGH
    }

    struct AssetInfo {
        bool allowed;             // whether this token is allowed for any ΛProof payment
        RiskTier riskTier;        // coarse risk classification
        bytes32 policyRefHash;    // hash of off-chain policy / legal doc
        bytes32 jurisdictionHash; // hash of jurisdiction/country code set, optional
    }

    event AssetRegistered(address indexed token, AssetInfo info);
    event AssetUpdated(address indexed token, AssetInfo info);
    event AssetDisabled(address indexed token);

    function getAssetInfo(address token) external view returns (AssetInfo memory);

    function isAssetAllowed(address token) external view returns (bool);

    function riskTierOf(address token) external view returns (RiskTier);
}
