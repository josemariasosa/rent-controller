// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IRentController {

    error Unauthorized();
    error NotEnoughBalance();
    error AccordIsFullyPayed();
    error DoNotOverPay();

    // function checkAvailability(uint64 _start, uint64 _end) external view returns (bool);
    // function createReservation(address _caller, uint64 _start, uint64 _end) external returns (bool);

    function confirmApprovedByProperty(bytes32 _accordId) external;
 
}