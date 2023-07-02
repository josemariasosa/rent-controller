// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.18;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// // Uncomment this line to use console.log
// // import "hardhat/console.sol";

// contract checkStamp {

//     uint64 public cleaningDuration;
//     uint64 public minStayDuration;
//     uint64 public maxAnticipationDuration;

//     error LessThanMinDuration();
//     error InvalidStartEndDates();
//     error InvalidStartDate();
//     error GreaterThanMaxAnticipation();

//     modifier checkTime(uint64 _start, uint64 _end) {
//         if (_start <= _end) { revert InvalidStartEndDates(); }
//         if (_start + minStayDuration < _end) { revert LessThanMinDuration(); }
//         if (_start < block.timestamp) { revert InvalidStartDate(); }
//         if (_start > block.timestamp + maxAnticipationDuration) {
//             revert GreaterThanMaxAnticipation();
//         }
//         _;
//     }

//     constructor(
//         uint64 _cleaningDuration,
//         uint64 _minStayDuration,
//         uint64 _maxAnticipationDuration
//     ) {
//         cleaningDuration = _cleaningDuration;
//         minStayDuration = _minStayDuration;
//         maxAnticipationDuration = _maxAnticipationDuration;
//     }
// }