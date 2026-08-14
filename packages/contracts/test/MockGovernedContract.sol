// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Mock contract for testing LambdaGovernor execution
contract MockGovernedContract {
    uint256 public value;
    address public lastCaller;

    event ValueSet(uint256 newValue, address caller);

    function setValue(uint256 _value) external {
        value = _value;
        lastCaller = msg.sender;
        emit ValueSet(_value, msg.sender);
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}
