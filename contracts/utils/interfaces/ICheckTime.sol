// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICheckTime {
    function cleaningDuration() external view returns(uint64);
}