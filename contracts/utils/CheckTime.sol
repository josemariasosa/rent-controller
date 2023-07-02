// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract CheckTime {

    /// @notice One day to allow
    uint64 public constant MIN_VALIDITY_DURATION = 60 * 60 * 24;

    /// @notice cleaningDuration MUST include all posible delays between rents
    uint64 public cleaningDuration;
    uint64 public minStayDuration;
    uint64 public maxAnticipationDuration;

    error LessThanMinDuration();
    error InvalidUntilStartDates();
    error InvalidStartEndDates();
    error InvalidStartDate();
    error GreaterThanMaxAnticipation();

    /// @param _validUntil can be the same as _start
    modifier check(uint64 _validUntil, uint64 _start, uint64 _end) {
        if (_start <= _end) { revert InvalidStartEndDates(); }

        /// If are equal then it is valid!
        if (_validUntil > _start) { revert InvalidUntilStartDates(); }
        if (_start + minStayDuration < _end) { revert LessThanMinDuration(); }

        uint64 _realStart = _validUntil + MIN_VALIDITY_DURATION;
        if (_realStart < block.timestamp) {
            revert InvalidStartDate();
        }
        if (_realStart > block.timestamp + maxAnticipationDuration) {
            revert GreaterThanMaxAnticipation();
        }
        _;
    }

    constructor(
        uint64 _cleaningDuration,
        uint64 _minStayDuration,
        uint64 _maxAnticipationDuration
    ) {
        cleaningDuration = _cleaningDuration;
        minStayDuration = _minStayDuration;
        maxAnticipationDuration = _maxAnticipationDuration;
    }
}