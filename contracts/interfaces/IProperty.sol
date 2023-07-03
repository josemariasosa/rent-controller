// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IProperty {

    error PropertyNotAvailable(uint64 _start, uint64 _end);
    error InvalidIndex();
    error DuplicatedAccordId();
    error Unauthorized();
    error AccordIdNotFound();
    error ExceededMaxReservations();

    // function checkAvailability(uint64 _start, uint64 _end) external view returns (bool);
    function createReservation(address _caller, bytes32 _accordId, uint64 _until, uint64 _start, uint64 _end) external;

    function confirmedByUser(bytes32 _accordId) external;

    function rentFee() external view returns(uint16);
 
}