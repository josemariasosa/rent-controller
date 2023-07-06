// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IRentController {

    error AccordIsFullyPayed();
    error AlreadyOut();
    error DoNotOverPay();
    error InvalidLength();
    error NotEnoughBalance();
    error Unauthorized();
    error WaitForTheProperty();

    // function checkAvailability(uint64 _start, uint64 _end) external view returns (bool);
    // function createReservation(address _caller, uint64 _start, uint64 _end) external returns (bool);

    function confirmApprovedByProperty(bytes32 _accordId) external;

    function calculateDue(bytes32 _accordId) external view returns (uint256 _payed, uint256 _due, uint16 _coveredPercent, uint8 _nextPeriod);
    function getNowPercentPeriod(bytes32 _accordId) external view returns (uint16 _nowPercent, uint8 _currentPeriod);
    function triggerStrikeOut(bytes32 _accordId, uint8 _strikes) external;
    function softNoteStrikes(bytes32 _accordId, uint8 _strikes) external;

    function calculateAvailableUpfrontAmount(bytes32 _accordId) external view returns (uint256 _propertyAmount, uint256 _propertyAmountEth);
    
    function propertyWithdrawUpfront(
        bytes32 _accordId,
        address _property,
        uint256 _propertyAmount,
        uint256 _propertyAmountEth) external;

    function STRIKE_OUT() external view returns (uint8);
}