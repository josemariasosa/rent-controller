// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IProperty.sol";
import "./interfaces/IRentController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RentController is IRentController {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice It is immutable because if all of a sudden this changes, 
    /// all balances are wrong for the new local currency.
    IERC20 immutable public local;

    /// d'accord 🥐
    struct AccordImmutable {
        /// @notice the Accord Id is unique and it is generated by the slug.
        bytes32 id;

        /// Only three accounts are involved: owner, user, property.
        /// Should be immuble until -------
        address owner;
        address user;
        address property;

        /// @notice The most important dates in the Accord.
        uint64 startTimestamp;
        uint64 endTimestamp;

        /// 6 if 6 months, 12 if 12, and so on.
        uint8 dividedInto;
        uint256 rentAmount;

        /// Two currencies are needed.
        uint256 upfrontPaymentEth;
        uint256 upfrontPayment;
    }

    struct AccordMutable {
        /// @dev The accord balances should eventually go back to Zero.
        uint256 balanceEth;

        /// Of course `balance` is in `local` currency, as everything else.
        uint256 balance;

        bool approvedByUser;
        bool approvedByProperty;
    }

    // // /// This mappings are HEAVY stuff, they should evenctually move off-chain.
    // // mapping(address => bytes32[]) public accordOwners;
    // // mapping(address => bytes32[]) public accordUser;
    // // mapping(address => bytes32[]) public accordProperty;

    mapping(bytes32 => AccordImmutable) public accordsData;
    mapping(bytes32 => AccordMutable) public accords;
    EnumerableSet.Bytes32Set private accordsHashIds;

    modifier onlyProperty(bytes32 _accordId) {
        AccordImmutable memory _accord = accordsData[_accordId];
        if (msg.sender != _accord.property) { revert Unauthorized(); }
        _;
    }

    constructor(IERC20 _localCurrency) {
        local = _localCurrency;
    }

    function getUniqueHashId(string memory _accordSlug) public view returns (bytes32) {
        bytes32 hash_id = keccak256(abi.encodePacked(_accordSlug));
        require(!accordsHashIds.contains(hash_id), "ACCORD_ID_ALREADY_EXISTS");
        return hash_id;
    }

    /// @param _dividedInto 6 if 6 months, 12 if 12, and so on.
    function proposeAccord(
        uint8 _dividedInto,
        uint64 _start,
        uint64 _end,
        uint256 _rentAmount,
        uint256 _upfrontPaymentEth,
        uint256 _upfrontPayment,
        IProperty _property,
        string memory _accordSlug
    ) public {
        require(_dividedInto > 0);

        AccordImmutable memory _data;
        bytes32 hash_id = getUniqueHashId(_accordSlug);
        _data.id = hash_id;
        _data.owner = msg.sender;

        /// If property is not available, next line will revert.
        _property.createReservation(msg.sender, hash_id, _start, _end);
        _data.property = address(_property);

        _data.startTimestamp = _start;
        _data.endTimestamp = _end;
        _data.rentAmount = _rentAmount;
        _data.dividedInto = _dividedInto;
        _data.upfrontPaymentEth = _upfrontPaymentEth;
        _data.upfrontPayment = _upfrontPayment;

        accordsHashIds.add(hash_id);
        // accordOwners[msg.sender].push(hash_id);
        accordsData[hash_id] = _data;
    }

    function confirmApprovedByProperty(bytes32 _accordId) public onlyProperty(_accordId) {
        AccordMutable storage _accord = accords[_accordId];
        _accord.approvedByProperty = true;
    }
}