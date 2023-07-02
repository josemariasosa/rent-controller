// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./utils/CheckTime.sol";
import "./interfaces/IRentController.sol";
import "./interfaces/IProperty.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Property is
    IProperty,
    AccessControl,
    CheckTime
{

    uint8 constant public MAX_RESERVATIONS = 10;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public treasury;

    IERC20 immutable public local;
    IRentController immutable public controller;

    uint256 public balance;
    uint256 public balanceEth;

    /// @notice Only fully-accepted accords.
    /// Only the operator or owner can create a reservation.
    struct Reservation {
        /// Only the owner can approve a reservation.
        bool approved;
        bool confirmed;
        bytes32 accordId;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    Reservation[] public reservations;

    modifier onlyController() {
        if (msg.sender != address(controller)) { revert Unauthorized(); }
        _;
    }

//     modifier uniqueAccordId(bytes32 _accordId) {
//         if (!_isUnique(_accordId)) { revert DuplicatedAccordId(); }
//         _;
//     }

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
        uint64 _cleaningDuration,
        uint64 _minStayDuration,
        uint64 _maxAnticipationDuration,
        address _operatorRole,
        address _treasuryRole
    ) CheckTime(_cleaningDuration, _minStayDuration, _maxAnticipationDuration) {
        local = _localCurrency;
        controller = _controller;
        treasury = _treasuryRole;

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operatorRole);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // /// @param _start timestamp in seconds.
    // /// @param _end timestamp in seconds.
    // function checkAvailability(
    //     uint64 _start,
    //     uint64 _end
    // ) public view check(_start, _end) returns (bool) {
    //     if (reservations.length >= MAX_RESERVATIONS) { revert ExceededMaxReservations(); }

    //     // uint64 _cleaningDuration = cleaningDuration;
    //     // for (uint i = 0; i < reservations.length; ++i) {
    //     //     Reservation memory _reservation = reservations[i];
    //     //     bool _available = _checkReservation(
    //     //         _reservation,
    //     //         _cleaningDuration,
    //     //         _startTimestamp,
    //     //         _endTimestamp
    //     //     );
    //     //     if (!_available) { return false; }
    //     // }
    //     return true;
    // }

    function createReservation(
        address _caller,
        bytes32 _accordId,
        uint64 _start,
        uint64 _end
    ) external onlyController onlyOperatorAdmin(_caller) {/// uniqueAccordId(_accordId) {
        // bool _available = checkAvailability(_start, _end);
        // if (!_available) { revert PropertyNotAvailable(_start, _end); }

        // Reservation memory _reservation;
        // _reservation.accordId = _accordId;
        // _reservation.startTimestamp = _start;
        // _reservation.endTimestamp = _end;
        
        // /// If the ADMIN creates a reservation, it's approved by default.
        // if (hasRole(ADMIN_ROLE, _caller)) {
        //     _reservation.approved = true;
        //     // _notifyAprovementToController(_accordId);
        // }

        // reservations.push(_reservation);
    }

//     /// @notice To confirm a reservation, the ADMIN must approve it.
//     /// @param _approved if false, then it will DELETE the reservation.
//     function approveOrRemoveReservation(
//         bool _approved,
//         bytes32 _accordId
//     ) public onlyRole(ADMIN_ROLE) {
//         // uint8 _index = _getIndex(_accordId);
//         // if (_approved) {
//         //     Reservation storage _reservation = reservations[_index];
//         //     _reservation.approved = true;
//         //     // _notifyAprovementToController(_accordId);
//         // } else {
//         //     _removeReservation(_index);
//         // }
//     }

//     /// *********************
//     /// * Private functions *
//     /// *********************

//     function _notifyAprovementToController(bytes32 _accordId) private {
//         controller.confirmApprovedByProperty(_accordId);
//     }

//     function _getIndex(bytes32 _accordId) private view returns (uint8) {
//         uint _total = reservations.length;
//         for (uint8 i = 0; i < _total; ++i) {
//             Reservation memory _reservation = reservations[i];
//             if (_reservation.accordId == _accordId) {
//                 return i;
//             }
//         }
//         revert AccordIdNotFound();
//     }

//     function _removeReservation(uint8 _index) private {
//         uint _length = reservations.length;
//         require(_index < _length, "Index out of bounds");

//         // Move the last element into the place of the element to be removed
//         reservations[_index] = reservations[_length - 1];
        
//         // Remove the last element
//         reservations.pop();
//     }

//     function _isUnique(bytes32 _accordId) private view returns (bool) {
//         uint _total = reservations.length;
//         for (uint i = 0; i < _total; ++i) {
//             Reservation memory _reservation = reservations[i];
//             if (_reservation.accordId == _accordId) {
//                 return false;
//             }
//         }
//         return true;
//     }

//     function _checkReservation(
//         Reservation memory _reservation,
//         uint64 _cleaningDuration,
//         uint64 _start,
//         uint64 _end
//     ) private pure returns (bool) {
//         bool _approved = _reservation.approved;
//         bool _fitBefore = _end + _cleaningDuration < _reservation.startTimestamp;
//         bool _fitAfter = _start > _reservation.endTimestamp + _cleaningDuration;

//         if (_approved) {
//             if (_fitBefore || _fitAfter) {
//                 return true;
//             } else {
//                 return false;
//             }
//         } else {
//             return true;
//         }
//     }
}