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

/// @title Rent Controller Captain ⭐.
/// @author alpha-centauri.sats

contract RentController is IRentController, Treasurable, PayServices {

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeERC20 for IERC20;

    uint16 public constant ONE_HUNDRED = 10_000;

    uint8 public constant STRIKE_OUT = 3;

    /// @notice hard refers if the user has more than 1 strike after endTimestamp.
    /// [hardBasisPoint, softBasisPoint]
    mapping(uint8 => uint16[2]) public hardSoftPenalization;

    /// @notice It is immutable because if all of a sudden this changes, 
    /// all balances are wrong for the new local currency.
    IERC20 immutable public local;

    ICentauriTreasury public treasury;

    /// Valid total balance in this contract.
    uint256 public totalBalance;
    uint256 public totalBalanceEth;

    /// d'accord 🥐
    struct AccordImmutable {

        /// 6 if 6 months, 12 if 12, and so on.
        uint8 dividedInto;

        /// @notice the Accord Id is unique and it is generated by the slug.
        bytes32 id;

        /// @notice The most important dates in the Accord.
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint64 validUntil;

        uint256 rentAmount;

        /// Two currencies are needed. This payment will be held by the contract until
        /// the contract is finished with `endTimestamp` or a `propertyStrikeOut`.
        uint256 upfrontPaymentEth;
        uint256 upfrontPayment;

        /// Only three accounts are involved: owner, user, property.
        address owner;
        address user;
        IProperty property;
    }

    struct AccordMutable {
        bool propertyStrikeOut;

        /// if both bools are false, then the upfrontPayment remains in accord balance.
        bool userWithdrawUpfront;
        bool propertyWithdrawUpfront;

        /// @dev if propertyStrikeOut is true, strikes is immutable.
        uint8 strikes;

        /// @dev The accord balances should eventually go back to Zero.
        uint256 balanceEth;

        /// Of course `balance` is in `local` currency, as everything else.
        uint256 balance;

        // All approves are given before the rent
        bool approvedByUser;
        bool approvedByProperty;
    }

    // // /// This mappings are HEAVY stuff, they should evenctually move off-chain.
    // // mapping(address => bytes32[]) public accordOwners;
    // // mapping(address => bytes32[]) public accordUser;
    // // mapping(address => bytes32[]) public accordProperty;

    mapping(bytes32 => AccordImmutable) public accordsData;
    mapping(bytes32 => AccordMutable) public accords;

    /// User payments - all go to treasury
    mapping(bytes32 => mapping(uint8 => uint256)) public userPayments;
    
    /// @notice TODO: keep this growing with every new accord???
    EnumerableSet.Bytes32Set private accordsHashIds;

    modifier onlyProperty(bytes32 _accordId) {
        IProperty _property = accordsData[_accordId].property;
        if (msg.sender != address(_property)) { revert Unauthorized(); }
        _;
    }

    modifier onlyUser(bytes32 _accordId) {
        if (msg.sender != accordsData[_accordId].user) { revert Unauthorized(); }
        _;
    }

    /// @param _hardSoft looks like [[3000, 1500], [6000, 2000]]
    ///                              [1rs strike]  [2nd strike]
    /// by policy: Strike Out equals [ONE_HUNDRED, ONE_HUNDRED]
    constructor(
        uint64 _createAccordPrice,
        uint64 _createAccordPriceEth,
        IERC20 _localCurrency,
        ICentauriTreasury _treasury,
        uint16[2][] memory _hardSoft
    ) Treasurable(_createAccordPrice, _createAccordPriceEth) {
        local = _localCurrency;
        treasury = _treasury;

        if ((_hardSoft.length + 1) != STRIKE_OUT) { revert InvalidLength(); }
        for (uint8 i = 0; i < STRIKE_OUT; ++i) {
            uint16 _hard = _hardSoft[i][0];
            uint16 _soft = _hardSoft[i][1];
            require(_hard >= _soft);
            hardSoftPenalization[i+1] = [_hard, _soft];
        }
        hardSoftPenalization[STRIKE_OUT] = [ONE_HUNDRED, ONE_HUNDRED];
    }

    function getUniqueHashId(string memory _accordSlug) public view returns (bytes32) {
        bytes32 hash_id = keccak256(abi.encodePacked(_accordSlug));
        require(!accordsHashIds.contains(hash_id), "ACCORD_ID_ALREADY_EXISTS");
        return hash_id;
    }

    /// @param _dividedInto 6 if 6 months, 12 if 12, and so on.
    function proposeAccord(
        uint8 _dividedInto,
        uint64 _validUntil,
        uint64 _start,
        uint64 _end,
        uint256 _rentAmount,
        uint256 _upfrontPaymentEth,
        uint256 _upfrontPayment,
        IProperty _property,
        address _user,
        string memory _accordSlug
    ) external {
        /// TODO: pay tribute to the treasury to allow proposeAccord.
        require(_dividedInto >= STRIKE_OUT);

        AccordImmutable memory _data;
        bytes32 hash_id = getUniqueHashId(_accordSlug);
        _data.id = hash_id;
        _data.owner = msg.sender;

        /// If property is not available, next line will revert.
        _property.createReservation(msg.sender, hash_id, _validUntil, _start, _end);
        _data.property = _property;
        _data.user = _user;

        _data.startTimestamp = _start;
        _data.endTimestamp = _end;
        _data.validUntil = _validUntil;
        _data.rentAmount = _rentAmount;
        _data.dividedInto = _dividedInto;
        _data.upfrontPaymentEth = _upfrontPaymentEth;
        _data.upfrontPayment = _upfrontPayment;

        accordsHashIds.add(hash_id);
        // accordOwners[msg.sender].push(hash_id);
        accordsData[hash_id] = _data;
    }

    /// @param _amount denominated in local
    function acceptAccord(bytes32 _accordId, uint256 _amount) external payable {
        AccordImmutable memory _data = accordsData[_accordId];
        require(block.timestamp < _data.validUntil);

        AccordMutable memory _accord = accords[_accordId];
        if (msg.sender != _data.user) { revert Unauthorized(); }
        require(_accord.approvedByProperty);
        require(_amount >= _data.upfrontPayment);
        require(msg.value >= _data.upfrontPaymentEth);

        // The amounts for this values are initialized here
        _accord.balance = _amount;
        _accord.balanceEth = msg.value;
        _accord.approvedByUser = true;

        totalBalance += _amount;
        totalBalanceEth += msg.value;

        /// Storage.
        accords[_accordId] = _accord;

        local.safeTransferFrom(msg.sender, address(this), _amount);
        _data.property.confirmedByUser(_accordId);
    }

    /// @param _periodsToPay how many period (monthds, weeks) the user want to pay
    function payKey(
        bytes32 _accordId,
        uint8 _periodsToPay,
        uint256 _amount
    ) external onlyUser(_accordId) {
        require(_periodsToPay > 0);
        AccordImmutable memory _data = accordsData[_accordId];
        AccordMutable memory _accord = accords[_accordId];

        require(block.timestamp < _data.endTimestamp);

        (, uint256 _due, , uint8 _nextPeriod) = _calculateDue(_data);

        if (_due == 0) { revert AccordIsFullyPayed(); }

        uint256 _currentBalance = _accord.balance;
        uint256 _lastBalance = _currentBalance + _amount;
        _accord.balance = _lastBalance;

        uint256 toPay = _periodsToPay * _data.rentAmount;
        if (toPay > (_lastBalance - _data.upfrontPayment)) { revert NotEnoughBalance(); }

        if (toPay > _due) { revert DoNotOverPay(); }

        uint256 forTreasury;
        for (uint8 i = _nextPeriod; i < (_nextPeriod + _periodsToPay); ++i) {
            userPayments[_accordId][i] = _data.rentAmount;
            _accord.balance -= _data.rentAmount;
            totalBalance -= _data.rentAmount;
            forTreasury += _data.rentAmount;
        }

        /// Storage
        accords[_accordId] = _accord;

        local.safeTransferFrom(msg.sender, address(this), _amount);
        local.safeIncreaseAllowance(address(treasury), forTreasury);
        treasury.payRent(forTreasury, _data.owner, address(_data.property), _data.property.rentFee());
    }

    /// @notice The User must wait for the cleaning period in order to allow the property
    /// to visit and assert the place.
    /// @dev Important to remember that `_calculateAvailableUpfrontAmount` works only
    /// after the `Status.Confirmed` is closed with: `StrikeOut` or `Success`.
    function userTerminate(bytes32 _accordId) external onlyUser(_accordId) {
        AccordImmutable memory _data = accordsData[_accordId];
        if (block.timestamp < _data.endTimestamp + _data.property.cleaningDuration()) {
            revert WaitForTheProperty();
        }

        /// Check with revert if the accord status is not "Confirmed", which at this
        /// point is the expected `Status`.
        _data.property.terminate(_accordId);

        AccordMutable memory _accord = accords[_accordId];
        (
            uint256 _userAmount,
            uint256 _userAmountEth,
            ,
        ) = _calculateAvailableUpfrontAmount(_data, _accord);

        if (_userAmount > 0 || _userAmountEth > 0) {
            _userWithdrawUpfront(_accordId, _data.user, _userAmount, _userAmountEth);
        }
    }

    /// **********************
    /// * Property functions *
    /// **********************

    function confirmApprovedByProperty(
        bytes32 _accordId
    ) public onlyProperty(_accordId) {
        AccordMutable storage _accord = accords[_accordId];
        _accord.approvedByProperty = true;
    }

    /// 1/2 More or equal to the amount stored in `STRIKE_OUT`. It's OUT!
    function triggerStrikeOut(
        bytes32 _accordId,
        uint8 _strikes
    ) external onlyProperty(_accordId) {
        AccordMutable memory _accord = accords[_accordId];
        if (_accord.propertyStrikeOut) { revert AlreadyOut(); }

        _accord.propertyStrikeOut = true;
        _accord.strikes = _strikes;

        /// Storage
        accords[_accordId] = _accord;
    }

    /// 2/2 The property decides to penalize the user or wait until the end
    /// of the contract. It's a BALL!
    function softNoteStrikes(
        bytes32 _accordId,
        uint8 _strikes
    ) external onlyProperty(_accordId) {
        AccordMutable memory _accord = accords[_accordId];
        if (_accord.propertyStrikeOut) { revert AlreadyOut(); }

        _accord.strikes = _strikes;

        /// Storage
        accords[_accordId] = _accord;
    }

    function calculateAvailableUpfrontAmount(
        bytes32 _accordId
    ) public onlyProperty(_accordId) view returns (
        // TODO: should i return them?
        // uint256 _userAmount,
        // uint256 _userAmountEth,
        uint256 _propertyAmount,
        uint256 _propertyAmountEth
    ) {
        AccordImmutable memory _data = accordsData[_accordId];
        AccordMutable memory _accord = accords[_accordId];
        (
            ,,
            _propertyAmount,
            _propertyAmountEth
        ) = _calculateAvailableUpfrontAmount(_data, _accord);
    }

    /// @notice this is done after the last Status has achieved (StrikeOut or Success).
    function propertyWithdrawUpfront(
        bytes32 _accordId,
        address _property,
        uint256 _propertyAmount,
        uint256 _propertyAmountEth
    ) public onlyProperty(_accordId) {
        _userWithdrawUpfront(
            _accordId,
            _property,
            _propertyAmount,
            _propertyAmountEth
        );
    }

    /// ******************
    /// * View functions *
    /// ******************

    function calculateDue(bytes32 _accordId) public view returns (
        uint256 _payed,
        uint256 _due,
        uint16 _coveredPercent,
        uint8 _nextPeriod
    ) {
        AccordImmutable memory _data = accordsData[_accordId];
        return _calculateDue(_data);
    }

    function getNowPercentPeriod(bytes32 _accordId) public view returns(
        uint16 _nowPercent,
        uint8 _currentPeriod
    ) {
        AccordImmutable memory _data = accordsData[_accordId];
        _nowPercent = _getNowPercent(_data);

        /// TODO: TEST
        _currentPeriod = uint8(
            (uint(_nowPercent) * uint(_data.dividedInto)) / uint(ONE_HUNDRED)
        );
    }

    /// *********************
    /// * Private functions *
    /// *********************

    /// @notice ASSUME that the status is the correct to avoid multiple checks.
    function _calculateAvailableUpfrontAmount(
        AccordImmutable memory _data,
        AccordMutable memory _accord
    ) private view returns (
        uint256 _userAmount,
        uint256 _userAmountEth,
        uint256 _propertyAmount,
        uint256 _propertyAmountEth
    ) {
        /// soft = 1; hard = 0;
        uint8 _hardSoft;
        if (!_accord.propertyStrikeOut) { _hardSoft = 1; }

        uint16 _penalization = _getPenalizationPercent(_accord.strikes, _hardSoft);

        _propertyAmount = _getPenalization(_data.upfrontPayment, _penalization);
        _propertyAmountEth = _getPenalization(_data.upfrontPaymentEth, _penalization);
        _userAmount = _data.upfrontPayment - _propertyAmount;
        _userAmountEth = _data.upfrontPaymentEth - _propertyAmountEth;

        if (_accord.userWithdrawUpfront) { _userAmount = 0; _userAmountEth = 0; }
        if (_accord.propertyWithdrawUpfront) { _propertyAmount = 0; _propertyAmountEth = 0; }
    }

    /// @notice the result of the penalization goes to the property
    function _getPenalization(
        uint256 _amount,
        uint16 _penalization
    ) private pure returns (uint256) {
        return (_amount * uint256(_penalization)) / uint256(ONE_HUNDRED);
    }

    function _getPenalizationPercent(
        uint8 _strikes,
        uint8 _hardSoft
    ) private view returns (uint16) {
        if (_strikes == 0) {
            return 0;
        } else if (_strikes < STRIKE_OUT) {
            return hardSoftPenalization[_strikes][_hardSoft];
        } else {
            return hardSoftPenalization[STRIKE_OUT][_hardSoft];
        }
    }




    /// During the validity of the contract, or until a property strike-out,
    /// ALL OF THE upfront payment should remain in the `_accord.balance`.
    function _userWithdrawUpfront(
        bytes32 _accordId,
        address _user,
        uint256 _amount,
        uint256 _amountEth
    ) private {
        AccordMutable memory _accord = accords[_accordId];

        _accord.userWithdrawUpfront = true;

        /// ERC20 transfer
        if (_amount > 0) {
            _accord.balance -= _amount;
            totalBalance -= _amount;
            local.safeTransfer(_user, _amount);

        }

        if (_amountEth > 0) {
            _accord.balanceEth -= _amountEth;
            totalBalanceEth -= _amountEth;
            payable(_user).transfer(_amountEth);
        }

        /// Storage
        accords[_accordId] = _accord;
    }

    function _calculateDue(
        AccordImmutable memory _data
    ) private view returns (
        uint256 _payed,
        uint256 _due,
        uint16 _coveredPercent,
        uint8 _nextPeriod
    ) {
        uint256 totalToPay = uint256(_data.dividedInto) * _data.rentAmount;
        (_payed, _coveredPercent, _nextPeriod) = _getTotalPayed(_data);
        _due = totalToPay - _payed;
        return (_payed, _due, _coveredPercent, _nextPeriod);
    }

    function _getNowPercent(AccordImmutable memory _data) private view returns (uint16) {
        if (block.timestamp < _data.startTimestamp) {
            return 0;
        } else if (block.timestamp >= _data.startTimestamp && block.timestamp < _data.endTimestamp) {
            uint _numerator = uint(ONE_HUNDRED) * uint(block.timestamp - _data.startTimestamp);
            uint _denominator = uint(_data.endTimestamp - _data.startTimestamp);
            uint _res = _numerator / _denominator;
            return uint16(_res);
        } else {
            return ONE_HUNDRED;
        }
    }

    function _getCoveredPercent(
        AccordImmutable memory _data,
        uint256 _payed
    ) private pure returns (uint16) {
        uint totalToPay = uint(_data.dividedInto) * _data.rentAmount;
        uint _res = (_payed * uint(ONE_HUNDRED)) / totalToPay;
        return uint16(_res);
    }

    function _getTotalPayed(
        AccordImmutable memory _data
    ) private view returns (uint256 _payed, uint16 _coveredPercent, uint8 _nextPeriod) {
        uint8 periods = _data.dividedInto;
        uint8 _period;
        for (uint8 i = 0; i < periods; ++i) {
            uint256 _payedDuringPeriod = userPayments[_data.id][i];

            /// userPayments is being filled in order.
            if (_payedDuringPeriod == 0) {
                _coveredPercent = _getCoveredPercent(_data, _payed);
                return (_payed, _coveredPercent, _period);
            }
            _payed += _payedDuringPeriod;
            ++_period;
        }
        _coveredPercent = _getCoveredPercent(_data, _payed);
        return (_payed, _coveredPercent, _period);
    }

}