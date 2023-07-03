// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BasisPoint {

    uint16 public constant ONE_HUNDRED = 10_000;

    uint64 public maxValidBasisPoint;

    error InvalidMaxValid();
    error InvalidFeeAmount(uint16 _basisPoint);

    modifier checkBasisPoints(uint16 _basisPoint) {
        if (_basisPoint > maxValidBasisPoint) {
            revert InvalidFeeAmount(_basisPoint);
        }
        _;
    }

    constructor(
        uint16 _maxValidBasisPoint
    ) {
        if (_maxValidBasisPoint > ONE_HUNDRED) { revert InvalidMaxValid(); }
        maxValidBasisPoint = _maxValidBasisPoint;
    }
}