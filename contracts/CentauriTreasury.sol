// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title Centauri Treasury 🪐 vault contract.
/// @author alpha-centauri.sats 🛰️

import "./interfaces/ICentauriTreasury.sol";
import "./interfaces/IRentController.sol";
import "./utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/// @notice The treasury only works with the ERC20 "local currency"

contract CentauriTreasury is
    ICentauriTreasury,
    ERC4626,
    Pausable,
    AccessControl
{
    using SafeERC20 for IERC20;

    uint16 public constant ONE_HUNDRED = 10_000;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IRentController public controller;

    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    constructor(
        address _operator,
        IERC20 _local,
        string memory _centName,
        string memory _centSymbol
    )
        ERC4626(_local)
        ERC20(_centName, _centSymbol)
    {
        if (address(_local) == address(0) || _operator == address(0)) {
            revert InvalidZeroAddress();
        }

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

    // *******************
    // * Admin functions *
    // *******************

    function initializeController(
        IRentController _controller
    ) external onlyRole(ADMIN_ROLE) {
        if (address(controller) != address(0)) { revert ContractAlreadyInitialized(); }
        if (address(_controller) == address(0)) { revert InvalidZeroAddress(); }

        controller = _controller;

        // // Get fully operational for the first time.
        // updateContractOperation(true);

        // emit ContractInitialized(
        //     address(_stakingManager),
        //     address(_liquidityPool),
        //     msg.sender
        // );
    }

    function updateController(
        IRentController _controller
    ) external onlyRole(ADMIN_ROLE) {
        if (address(_controller) == address(0)) { revert InvalidZeroAddress(); }
        if (address(controller) == address(0)) { revert ContractNotInitialized(); }
        controller = _controller;

        // emit NewManagerUpdate(address(_controller), msg.sender);
    }


    function updateContractPause(
        bool _isPaused
    ) public override onlyRole(ADMIN_ROLE) {
        if (_isPaused && (address(controller) == address(0))) {
            revert ContractNotInitialized();
        }
        paused = _isPaused;

        // emit ContractUpdateOperation(_isPaused, msg.sender);
    }

    function getCentPrice() public view returns (uint256) {
        uint256 ONE_CENTAURI = 1 ether;
        return convertToAssets(ONE_CENTAURI);
    }

    // ************************
    // * Controller functions *
    // ************************

    function payRent(
        uint256 _amount,
        address _owner,
        address _property,
        uint16 _propertyRentFee
    ) public onlyController {
        uint256 shares = previewDeposit(_amount);
        (uint256 _forOwner, uint256 _forProperty) = calculateRent(
            shares,
            _propertyRentFee
        );

        IERC20(asset()).safeTransferFrom(address(controller), address(this), _amount);
        _mint(_owner, _forOwner);
        _mint(_property, _forProperty);
    }

    function calculateRent(
        uint256 _amount,
        uint16 _propertyRentFee
    ) internal pure returns (uint256 _forOwner, uint256 _forProperty) {
        _forProperty = _amount * uint(_propertyRentFee) / uint(ONE_HUNDRED);
        _forOwner = _amount - _forProperty;
    }

    // // ******************
    // // * Core functions *
    // // ******************

    // /// @dev Same as ERC-4626, but adding evaluation of min deposit amount.
    // function deposit(
    //     uint256 _assets,
    //     address _receiver
    // ) public override onlyFullyOperational returns (uint256) {
    //     if (_assets < minDepositAmount) { revert LessThanMinDeposit(); }
    //     require(_assets <= maxDeposit(_receiver), "ERC4626: deposit more than max");

    //     uint256 shares = previewDeposit(_assets);
    //     _deposit(msg.sender, _receiver, _assets, shares);

    //     return shares;
    // }

    // function mint(
    //     uint256 _shares,
    //     address _receiver
    // ) public override onlyFullyOperational returns (uint256) {
    //     uint256 assets = previewMint(_shares);
    //     if (assets < minDepositAmount) { revert LessThanMinDeposit(); }
    //     require(_shares <= maxMint(_receiver), "ERC4626: mint more than max");
    //     _deposit(msg.sender, _receiver, assets, _shares);

    //     return assets;
    // }

    // /// @notice Delay-unstake process starts from either the withdraw or redeem function.
    // /// After the cooling period, funds can be collected using completeDelayUnstake().
    // /// @dev Starts the delay-unstake.
    // function withdraw(
    //     uint256 _assets,
    //     address _receiver,
    //     address _owner
    // ) public override onlyFullyOperational returns (uint256) {
    //     if (_assets == 0) { revert InvalidZeroAmount(); }
    //     require(_assets <= maxWithdraw(_owner), "ERC4626: withdraw more than max");

    //     uint256 shares = previewWithdraw(_assets);
    //     _withdraw(msg.sender, _receiver, _owner, _assets, shares);

    //     return shares;
    // }

    // /// @notice The redeem fn starts the release of tokens from the Aurora Plus contract.
    // /// @dev Starts the delay-unstake.
    // function redeem(
    //     uint256 _shares,
    //     address _receiver,
    //     address _owner
    // ) public override onlyFullyOperational returns (uint256) {
    //     if (_shares == 0) { revert InvalidZeroAmount(); }
    //     require(_shares <= maxRedeem(_owner), "ERC4626: redeem more than max");

    //     uint256 assets = previewRedeem(_shares);
    //     _withdraw(msg.sender, _receiver, _owner, assets, _shares);

    //     return assets;
    // }

    // /// @notice It can only be called after the withdraw/redeem of the stAUR and the
    // /// waiting period.
    // function completeDelayUnstake(
    //     uint256 _assets,
    //     address _receiver
    // ) public {
    //     // The transfer is settled only if the msg.sender has enough available funds in
    //     // the manager contract.
    //     IStakingManager(stakingManager).transferAurora(_receiver, msg.sender, _assets);

    //     emit Withdraw(msg.sender, _receiver, msg.sender, _assets, 0);
    // }

    // // **********************
    // // * Treasury functions *
    // // **********************

    // function mintFee(address _treasury, uint256 _fee) public onlyManager {
    //     _mint(_treasury, _fee);
    // }

//     // *********************
//     // * Private functions *
//     // *********************

//     function _deposit(
//         address _caller,
//         address _receiver,
//         uint256 _assets,
//         uint256 _shares
//     ) internal override {
//         IERC20 auroraToken = IERC20(asset());
//         IStakingManager manager = IStakingManager(stakingManager);
//         auroraToken.safeTransferFrom(_caller, address(this), _assets);
//         ILiquidityPool _pool = liquidityPool;

//         // FLOW 1: Use the stAUR in the Liquidity Pool.
//         if (_pool.isStAurBalanceAvailable(_shares)) {
//             auroraToken.safeIncreaseAllowance(address(_pool), _assets);
//             _pool.transferStAur(_receiver, _shares, _assets);

//         // FLOW 2: Stake with the depositor to mint more stAUR.
//         } else {
//             address depositor = manager.nextDepositor();
//             auroraToken.safeIncreaseAllowance(depositor, _assets);
//             IDepositor(depositor).stake(_assets);
//             manager.setNextDepositor();
//             _mint(_receiver, _shares);
//         }

//         emit Deposit(_caller, _receiver, _assets, _shares);
//     }

//     function _withdraw(
//         address _caller,
//         address _receiver,
//         address _owner,
//         uint256 _assets,
//         uint256 _shares
//     ) internal override {
//         if (_caller != _owner) {
//             _spendAllowance(_owner, _caller, _shares);
//         }

//         _burn(_owner, _shares);
//         IStakingManager(stakingManager).createWithdrawOrder(_assets, _receiver);

//         emit Withdraw(msg.sender, _receiver, _owner, _shares, _assets);
//     }
}