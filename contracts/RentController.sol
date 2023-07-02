// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RentController {

    /// @notice It is immutable because if all of a sudden this changes, 
    /// all balances are wrong for the new local currency.
    IERC20 immutable public local;

    /// d'accord 🥐
    struct Accord {
        uint256 balanceEth;

        
    }

    constructor(IERC20 _localCurrency) {
        local = _localCurrency;

    }
}