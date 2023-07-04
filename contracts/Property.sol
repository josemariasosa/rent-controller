// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./utils/CheckTime.sol";
import "./utils/BasisPoint.sol";
import "./interfaces/IRentController.sol";
import "./interfaces/IProperty.sol";
import "./interfaces/ICentauriTreasury.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Property is
    IProperty,
    AccessControl,
    CheckTime,
    BasisPoint
{

    using EnumerableSet for EnumerableSet.Bytes32Set;

    uint8 constant public MAX_RESERVATIONS = 10;
    uint16 constant public MAX_RENT_FEE_BASIS_POINT = 1500;

    /// @notice the size of the Set is restricted by `MAX_RESERVATIONS`
    EnumerableSet.Bytes32Set private proposedHashIds;
    EnumerableSet.Bytes32Set private approvedHashIds;
    EnumerableSet.Bytes32Set private confirmedHashIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice var denominated in basis points
    uint16 public rentFee;

    ICentauriTreasury public treasury;
    IERC20 immutable public local;
    IRentController immutable public controller;

    uint256 public balanceEth;

    enum Status {
        Proposed,
        Approved,
        Confirmed,
        StrikeOut,
        Success
    }

    /// @notice Only fully-accepted accords.
    /// Only the operator or owner can create a reservation.
    struct Reservation {
        /// Only the owner can approve a reservation.
        Status status;
        bytes32 accordId;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    struct ReservationDetails {
        uint8 nextPeriod;
        uint8 currentPeriod;
        uint16 coveredPercent;
        uint16 nowPercent;
        uint256 dueAmount;
        uint256 payedAmount;
    }

    mapping(bytes32 => Reservation) public reservations;

    modifier onlyController() {
        if (msg.sender != address(controller)) { revert Unauthorized(); }
        _;
    }

    modifier onlyControllerAdmin() {
        if (msg.sender == address(controller) || hasRole(ADMIN_ROLE, msg.sender)) {
            _;
        } else {
            revert Unauthorized();
        }
    }

    modifier uniqueId(bytes32 _accordId) {
        if (!_isUnique(_accordId)) { revert DuplicatedAccordId(); }
        _;
    }

    modifier onlyOperatorAdmin(address _caller) {
        if (hasRole(OPERATOR_ROLE, _caller) || hasRole(ADMIN_ROLE, _caller)) {
            _;
        } else {
            revert Unauthorized();
        }
    }

    constructor(
        IERC20 _localCurrency,
        IRentController _controller,
        uint16 _rentFee,
        uint64 _cleaningDuration,
        uint64 _minStayDuration,
        uint64 _maxAnticipationDuration,
        address _operator,
        ICentauriTreasury _treasury
    )
        CheckTime(_cleaningDuration, _minStayDuration, _maxAnticipationDuration)
        BasisPoint(MAX_RENT_FEE_BASIS_POINT)
    {
        local = _localCurrency;
        controller = _controller;
        treasury = _treasury;
        rentFee = _rentFee;

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @param _until accord valid until timestamp in seconds.
    /// @param _start timestamp in seconds.
    /// @param _end timestamp in seconds.
    function checkAvailability(
        uint64 _until,
        uint64 _start,
        uint64 _end
    ) public view check(_until, _start, _end) returns (bool) {
        uint _length = approvedHashIds.length();
        if (_length >= MAX_RESERVATIONS) { revert ExceededMaxReservations(); }

        uint64 _cleaningDuration = cleaningDuration;
        for (uint i = 0; i < _length; ++i) {
            Reservation memory _reservation = reservations[approvedHashIds.at(i)];
            bool _available = _checkReservation(
                _reservation,
                _cleaningDuration,
                _start,
                _end
            );
            if (!_available) { return false; }
        }
        return true;
    }

    function createReservation(
        address _caller,
        bytes32 _accordId,
        uint64 _until,
        uint64 _start,
        uint64 _end
    ) external onlyController onlyOperatorAdmin(_caller) uniqueId(_accordId) {
        bool _available = checkAvailability(_until, _start, _end);
        if (!_available) { revert PropertyNotAvailable(_start, _end); }

        Reservation memory _reservation;
        _reservation.accordId = _accordId;
        _reservation.startTimestamp = _start;
        _reservation.endTimestamp = _end;
        
        /// If the ADMIN creates a reservation, it's approved by default.
        if (hasRole(ADMIN_ROLE, _caller)) {
            _reservation.status = Status.Approved;
            _notifyAprovementToController(_accordId);
        } else {
            _reservation.status = Status.Proposed;
        }

        reservations[_accordId] = _reservation;
    }

    /// @notice To confirm a reservation, the ADMIN must approve it.
    /// @param _approved if false, then it will DELETE the reservation.
    function approveOrRemoveReservation(
        bool _approved,
        bytes32 _accordId
    ) public onlyRole(ADMIN_ROLE) {
        /// Only for proposed accords.
        require(proposedHashIds.contains(_accordId));
        proposedHashIds.remove(_accordId);

        if (_approved) {
            Reservation storage _reservation = reservations[_accordId];
            _reservation.status = Status.Approved;
            approvedHashIds.add(_accordId);
            _notifyAprovementToController(_accordId);
        }
    }

    function confirmedByUser(bytes32 _accordId) public onlyController {
        Reservation storage _reservation = reservations[_accordId];

        require(_reservation.status == Status.Approved);
        _reservation.status = Status.Confirmed;

        approvedHashIds.remove(_accordId);
        confirmedHashIds.add(_accordId);
    }

    function getAvailableLocalBalance() public view returns (uint256) {
        return treasury.convertToAssets(treasury.balanceOf(address(this)));
    }

    function getReservationDetails(
        bytes32 _accordId
    ) public view returns (ReservationDetails memory) {
        (
            uint256 _payed,
            uint256 _due,
            uint16 _coveredPercent,
            uint8 _nextPeriod
        ) = controller.calculateDue(_accordId);

        (
            uint16 _nowPercent,
            uint8 _currentPeriod
        ) = controller.getNowPercentPeriod(_accordId);

        return ReservationDetails(
            _nextPeriod,
            _currentPeriod,
            _coveredPercent,
            _nowPercent,
            _due,
            _payed
        );
    }

    function calculateStrikes(bytes32 _accordId) public view returns (uint8) {
        return _calculateStrikes(getReservationDetails(_accordId));
    }

    function penalize(bytes32 _accordId) public onlyRole(OPERATOR_ROLE) {
        require(block.timestamp < reservations[_accordId].endTimestamp);
        require(reservations[_accordId].status == Status.Confirmed);
        uint8 _strikes = calculateStrikes(_accordId);

        if (_strikes == 0) { revert NoStrikes(); }
        if (_strikes >= controller.STRIKE_OUT()) {
            _triggerStrikeOut(_accordId, _strikes);
        } else {
            _softNoteStrikes(_accordId, _strikes);
        }
    }

    function terminate(bytes32 _accordId) external onlyControllerAdmin {
        _terminate(_accordId);
    }

    /// *********************
    /// * Private functions *
    /// *********************

    function _terminate(bytes32 _accordId) private {
        require(reservations[_accordId].endTimestamp <= block.timestamp);
        require(reservations[_accordId].status == Status.Confirmed);
        uint8 _strikes = calculateStrikes(_accordId);
        if (_strikes < controller.STRIKE_OUT()) {
             Reservation storage _reservation = reservations[_accordId];
            _reservation.status = Status.Success;

            _softNoteStrikes(_accordId, _strikes);
        } else {
            _triggerStrikeOut(_accordId, _strikes);
        }
    }

    function _triggerStrikeOut(bytes32 _accordId, uint8 _strikes) private {
        Reservation storage _reservation = reservations[_accordId];
        _reservation.status = Status.StrikeOut;

        controller.triggerStrikeOut(_accordId, _strikes);
    }

    function _softNoteStrikes(bytes32 _accordId, uint8 _strikes) private {
        controller.softNoteStrikes(_accordId, _strikes);
    }

    function _calculateStrikes(
        ReservationDetails memory _details
    ) private pure returns (uint8) {
        if (_details.nowPercent <= _details.coveredPercent) {
            return 0;
        } else {
            return _details.currentPeriod - _details.nextPeriod;
        }
    }

    function _notifyAprovementToController(bytes32 _accordId) private {
        controller.confirmApprovedByProperty(_accordId);
    }

    function _isUnique(bytes32 _accordId) private view returns (bool) {
        return proposedHashIds.contains(_accordId)
            || approvedHashIds.contains(_accordId)
            || confirmedHashIds.contains(_accordId);
    }

    /// @param _reservation should ONLY be approved reservations
    function _checkReservation(
        Reservation memory _reservation,
        uint64 _cleaningDuration,
        uint64 _start,
        uint64 _end
    ) private pure returns (bool) {
        bool _fitBefore = _end + _cleaningDuration < _reservation.startTimestamp;
        bool _fitAfter = _start > _reservation.endTimestamp + _cleaningDuration;
        if (_fitBefore || _fitAfter) { return true; }
        return false;
    }
}