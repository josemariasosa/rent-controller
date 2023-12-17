// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/ICentauriTreasury.sol";
import "./interfaces/IProperty.sol";
import "./interfaces/IRentController.sol";
import "./utils/Treasurable.sol";
import "./utils/PayServices.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Governance Centauri DAO ⭐.
/// @author alpha-centauri.sats

import "hardhat/console.sol";

/// @notice Voters will vote for an object and a competition with 

contract Governance {

    enum LockPhase {
        Locked,
        Unlocking,
        Unlocked
    }

    using SafeERC20 for IERC20;

    struct LockPos {
        uint16 numberOfDays;
        uint256 lockedBalance;
        uint64 unlockingTs;
        uint256 votingPower;
        LockPhase lockPhase;
    }

    struct VotePos {
        string competition;
        string uniqueObject;

    }

    struct Voter {
        uint256 votingPower;
        uint256 balance;
        LockPos
    }

    mapping (address => Voter) name;

    IERC20 public immutable governanceToken;

    constructor(IERC20 _governanceToken) {
        governanceToken = _governanceToken;
    }

    function createLockPosition(uint256 _amount, uint32 _days) external {
        governanceToken.safeTransferFrom(msg.sender, address(this), _amount);


    }
    // function createVotePosition(uint256 _amount, )

    // uint8 public constant STRIKE_OUT = 3;

}