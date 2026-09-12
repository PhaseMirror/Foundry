// contracts/src/MultiplicityStablecoin.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MultiplicityStablecoin (MSC)
 * @dev The economic layer of the SUG DAO. Valuation and issuance are 
 *      directly tied to the Phase Mirror resonance coherence metric.
 */
contract MultiplicityStablecoin is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // The structural valuation factor (in basis points, 10000 = $1.00)
    uint256 public structuralValuation = 10000; 

    event ValuationUpdated(uint256 newValuation, uint256 resonanceMetric);

    constructor() ERC20("Multiplicity Stablecoin", "MSC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
    }

    /**
     * @dev Mints new MSC. Regulated by resonance thresholds.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Burns MSC to represent economic contraction or dissipation.
     */
    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }

    /**
     * @dev Updates the structural value of MSC based on the latest MQEM Resonance Coherence.
     * @param resonance The R(t) value scaled appropriately (e.g., basis points)
     */
    function updateValuation(uint256 resonance) external onlyRole(GOVERNANCE_ROLE) {
        // Simple valuation curve: Base + (Resonance Multiplier)
        // If resonance is 78%, structuralValuation increases
        structuralValuation = 10000 + (resonance * 10);
        emit ValuationUpdated(structuralValuation, resonance);
    }
}
