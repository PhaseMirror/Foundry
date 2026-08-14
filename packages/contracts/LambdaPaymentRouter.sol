// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILambdaAssetRegistry.sol";

/// @notice ΛPaymentRouter routes ERC-20 payments for ΛProof/ΛGovernor-controlled flows.
/// - Only whitelisted tokens from LambdaAssetRegistry are allowed.
/// - Only authorized callers (e.g., ΛGovernor, domain contracts) can initiate payments.
/// - Holds no business logic about royalties, revenue splits, etc.
contract LambdaPaymentRouter is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ILambdaAssetRegistry public immutable assetRegistry;

    event PaymentExecuted(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        ILambdaAssetRegistry.RiskTier riskTier,
        bytes32 ltraceHash
    );

    constructor(address admin, address assetRegistry_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
        assetRegistry = ILambdaAssetRegistry(assetRegistry_);
    }

    /// @notice Execute a payment using a whitelisted token.
    /// @dev
    /// - Caller must have OPERATOR_ROLE (e.g., LambdaGovernor or domain contract).
    /// - Token must be allowed in LambdaAssetRegistry.
    /// - 'from' must have approved this router for 'amount'.
    /// - ltraceHash ties this transfer to an off-chain Λ-Trace decision.
    function pay(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes32 ltraceHash
    ) external onlyRole(OPERATOR_ROLE) {
        require(token != address(0), "invalid token");
        require(to != address(0), "invalid recipient");
        require(amount > 0, "amount=0");

        ILambdaAssetRegistry.AssetInfo memory info = assetRegistry.getAssetInfo(token);
        require(info.allowed, "asset_not_allowed");

        // Pull tokens from 'from' into 'to'
        bool ok = IERC20(token).transferFrom(from, to, amount);
        require(ok, "transfer failed");

        emit PaymentExecuted(token, from, to, amount, info.riskTier, ltraceHash);
    }
}
