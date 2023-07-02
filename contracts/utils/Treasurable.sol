// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Treasurable {

    uint256 public createAccordPrice;
    uint256 public createAccordPriceEth;
 

    constructor(
        uint64 _createAccordPrice,
        uint64 _createAccordPriceEth
    ) {
        createAccordPrice = _createAccordPrice;
        createAccordPriceEth = _createAccordPriceEth;
    }
}