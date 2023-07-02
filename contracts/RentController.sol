// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RentController {

    /// @notice It is immutable because if all of a sudden this changes, 
    /// all balances are wrong for the new local currency.
    IERC20 immutable public local;

    /// d'accord 🥐
    struct Accord {

        /// Only three accounts are involved: owner, user, property.
        /// Should be immuble until -------
        address owner;
        address user;
        address property;

        /// @notice The most important dates in the Accord.
        uint64 startTimestamp;
        uint64 endTimestamp;

        uint8 dividedInto;
        uint256 rentAmount;

        /// -------

        /// The upfrontPayment should go to zero after `endTimestamp`
        /// Two currencies are needed.
        uint256 upfrontPaymentEth;
        uint256 upfrontPayment;

        /// @dev The accord balances should eventually go back to Zero.
        uint256 balanceEth;
        /// Of course `balance` is in `local` currency, as everything else.
        uint256 balance;
    }

    /// This mappings are HEAVY stuff, they should evenctually move off-chain.
    mapping(address => bytes32[]) public accordOwners;
    mapping(address => bytes32[]) public accordUser;
    mapping(address => bytes32[]) public accordProperty;

    mapping(bytes32 => Accord) public accords;
    EnumerableSet.Bytes32Set private accordsHashIds;

    constructor(IERC20 _localCurrency) {
        local = _localCurrency;

    }

    
    /// @param _dividedInto 6 if 6 months, 12 if 12, and so on.
    function proposeAccord(
        uint8 _dividedInto,
        uint64 _startTimestamp,
        uint64 _endTimestamp,
        uint256 _rentAmount,
        uint256 _upfrontPaymentEth,
        uint256 _upfrontPayment,
        string memory _accordSlug
    ) public {
        require(_dividedInto > 0);
        Accord memory _accord;
        _accord.owner = msg.sender;
        _accord.startTimestamp = _startTimestamp;
        _accord.endTimestamp = _endTimestamp;
        _accord.endTimestamp = _rentAmount;


        /// @notice The most important dates in the Accord.
        uint64 startTimestamp;
        uint64 endTimestamp;

        /// -------

        /// The upfrontPayment should go to zero after `endTimestamp`
        /// Two currencies are needed.
        uint256 upfrontPaymentEth;
        uint256 upfrontPayment;

        /// @dev The accord balances should eventually go back to Zero.
        uint256 balanceEth;
        /// Of course `balance` is in `local` currency, as everything else.
        uint256 balance;           
        )

    }
    

            bytes32 hash_id = keccak256(abi.encodePacked(_slug));
        require(!projectHashIds.contains(hash_id), "PROJECT_ID_ALREADY_EXISTS");
}