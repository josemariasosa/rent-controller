// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface ICentauriTreasury is IERC4626 {
    error InvalidZeroAddress();
    error ContractAlreadyInitialized();
    error ContractNotInitialized();

    function payRent(
        uint256 _amount,
        address _owner,
        address _property,
        uint16 _propertyRentFee
    ) external;
}