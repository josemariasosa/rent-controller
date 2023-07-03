// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IPausable.sol";

abstract contract Pausable is IPausable {

    bool public paused;

    modifier notPaused() {
        if (!paused) { revert ContractPaused(); }
        _;
    }

    constructor() {}

    /// *********************
    /// * Virtual functions *
    /// *********************

    function updateContractPause(bool _isPaused) public virtual;
}