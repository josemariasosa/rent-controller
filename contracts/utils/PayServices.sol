// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


enum ServiceType {
    AwaysGo,
    OnceEverySecs,

    /// Only One time payment
    BeforeTimestamp
}

struct Service {
    bytes32 serviceId;
    uint256 amount;
    uint64 onceEvery;

    /// A new payment is made every time.
    ServiceType serviceType;
}
contract PayServices {
    constructor(
    ) {
    }
}