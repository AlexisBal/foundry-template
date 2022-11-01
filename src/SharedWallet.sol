// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SharedWallet is AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Roles definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /// @notice Error codes
    error InsufficientAllowance(address withdrawer, uint256 amountToWithdraw);
    error InsufficientBalance(uint256 amountToWithdraw, uint256 balance);
    error NotAllowedToWithdraw(address withdrawer);
    error InsufficientDeposit(address depositor);
    error IsNotAdmin(address caller);
    error TransferFailed(address receiver, uint256 amount);

    /// @notice Events
    event ETHDeposited(address indexed depositor, uint256 amount);
    event ETHWithdrawed(address indexed withdrawer, uint256 amount);
    event ERC20Withdrawed(address indexed withdrawer, address indexed tokenAddress, uint256 amount);

    /// @notice Allowance for each token for each wallet address
    mapping (address => mapping(address => uint256)) public allowances;

    /// @notice The constructor
    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAWER_ROLE, msg.sender);
    }

    /// @notice Returns the Ether balance of the contract
    /// @return balance The Ether balance of the contract
    function getBalance() public view returns (uint256 balance) {
        balance = address(this).balance;
    }

    /// @notice Deposit funds into the contract
    /// @dev The `payable` modifier allows this function to receive Ether.
    /// @dev The `nonReentrant` modifier protects this function from reentrancy attacks.
    function deposit() public payable nonReentrant {
        /// @dev The `msg.value` variable contains the amount of Ether sent with the transaction.
        /// @dev Checks that the amount of Ether sent with the transaction is greater than 0.
        if (msg.value == 0) {
            revert InsufficientDeposit(msg.sender);
        }
        /// @dev Emits an event to notify the client.
        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraw ERC20 funds from the contract
    /// @param _tokenAddress The address of the ERC20 token to withdraw
    /// @param _amount The amount of ERC20 tokens to withdraw
    /// @dev The `nonReentrant` modifier protects this function from reentrancy attacks.
    function withdrawERC20(IERC20 _tokenAddress, uint256 _amount) external nonReentrant {
        /// @dev Checks if the caller has the `WITHDRAWER_ROLE`.
        if (!hasRole(WITHDRAWER_ROLE, msg.sender)) {
            revert NotAllowedToWithdraw(msg.sender);
        }
        /// @dev Checks if the caller has enough allowance to withdraw the requested amount.
        if (allowances[msg.sender][address(_tokenAddress)] < _amount) {
            revert InsufficientAllowance(msg.sender, _amount);
        }
        /// @dev Checks if the contract has enough balance to withdraw the requested amount.
        if (_tokenAddress.balanceOf(address(this)) < _amount) {
            revert InsufficientBalance(_amount, _tokenAddress.balanceOf(address(this)));
        }
        /// @dev Updates the caller's allowance.
        allowances[msg.sender][address(_tokenAddress)] -= _amount;
        /// @dev Transfers the requested amount of ERC20 tokens to the caller.
        _tokenAddress.safeTransfer(msg.sender, _amount);
        /// @dev Emits an event to notify the client.
        emit ERC20Withdrawed(msg.sender, address(_tokenAddress), _amount);
    }

    /// @notice Withdraw ETH funds from the contract
    /// @param _amount The amount of ETH to withdraw
    /// @dev The `nonReentrant` modifier protects this function from reentrancy attacks.
    function withdrawETH(uint256 _amount) public nonReentrant {
        /// @dev Checks if the caller has the `WITHDRAWER_ROLE`.
        if (!hasRole(WITHDRAWER_ROLE, msg.sender)) {
            revert NotAllowedToWithdraw(msg.sender);
        }
        /// @dev Checks if the caller has enough allowance to withdraw the requested amount.
        if (allowances[msg.sender][address(0)] < _amount) {
            revert InsufficientAllowance(msg.sender, _amount);
        }
        /// @dev Checks if the contract has enough balance to withdraw the requested amount.
        if (address(this).balance < _amount) {
            revert InsufficientBalance(_amount, address(this).balance);
        }
        /// @dev Updates the caller's allowance.
        allowances[msg.sender][address(0)] -= _amount;
        /// @dev Transfers the requested amount of ETH to the caller.
        (bool sent,) = payable(msg.sender).call{value: _amount}("");
        if (!sent) {
            revert TransferFailed(msg.sender, _amount);
        }
        /// @dev Emits an event to notify the client.
        emit ETHWithdrawed(msg.sender, _amount);
    }

    /// @notice Allow a user to withdraw funds from the contract
    /// @param _userAddress The address of the user to allow to withdraw funds
    /// @param _tokenAddress The amount of funds to allow the user to withdraw
    /// @param _amount The amount of funds the user can withdraw
    function setAllowance(address _userAddress, address _tokenAddress, uint256 _amount) external {
        /// @dev Checks if the caller has the `ADMIN_ROLE`.
        if (!hasRole(ADMIN_ROLE, msg.sender)) {
            revert IsNotAdmin(msg.sender);
        }
        /// @dev Updates the allowance for the specified user.
        allowances[_userAddress][_tokenAddress] = _amount;
    }

    /// @notice Allow users to withdraw funds from the contract
    /// @param _usersAddress The users addresses allowed to withdraw funds
    /// @param _tokensAddress The amounts of funds to allow the user to withdraw
    /// @param _amounts The amounts of funds the user can withdraw
    function setAllowanceBatch(address[] calldata  _usersAddress, address[] calldata _tokensAddress, uint256[] calldata _amounts) external {
        /// @dev Checks if the caller has the `ADMIN_ROLE`.
        if (!hasRole(ADMIN_ROLE, msg.sender)) {
            revert IsNotAdmin(msg.sender);
        }
        /// @dev Updates the allowances for each user.
        for (uint256 i = 0; i < _usersAddress.length; ++i) {
            allowances[_usersAddress[i]][_tokensAddress[i]] = _amounts[i];
        }
    }

    /// @dev The 'deposit' function is called when the contract receives Ether.
    /// @dev Function to receive Ether. msg.data must be empty
    receive() external payable {
        deposit();
    }

    /// @dev The 'deposit' function is called when the contract receives Ether.
    /// @dev Fallback function is called when msg.data is not empty
    fallback() external payable {
        deposit();
    }
}