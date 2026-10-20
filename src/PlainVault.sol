// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title PlainVault
/// @notice Reference vault with plaintext ETH balances. It pins down the semantics that the
///         FHE-backed EncryptedVault must match (see docs/design.md).
/// @dev Withdrawals follow checks-effects-interactions and sit behind a reentrancy guard.
///      The owner can only pause deposits; there is no admin withdrawal path.
contract PlainVault {
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance(uint256 available, uint256 requested);
    error DepositsPaused();
    error NotOwner();
    error Reentrancy();
    error TransferFailed();

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event DepositsPausedSet(bool paused);

    address public immutable owner;
    bool public depositsPaused;

    mapping(address => uint256) private _balances;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert Reentrancy();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Credit `msg.value` to the caller.
    function deposit() external payable {
        if (depositsPaused) revert DepositsPaused();
        if (msg.value == 0) revert ZeroAmount();
        _balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Debit `amount` from the caller and send it as ETH.
    function withdraw(uint256 amount) external nonReentrant {
        _debit(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        // Balance is already debited and nonReentrant blocks re-entry, so the guard
        // resetting after the call is safe.
        // forge-lint: disable-next-line(reentrancy-eth)
        (bool ok,) = msg.sender.call{ value: amount }("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Move `amount` to `to` inside the vault. No ETH leaves the contract.
    function transfer(address to, uint256 amount) external {
        if (to == address(0)) revert ZeroAddress();
        _debit(msg.sender, amount);
        _balances[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }

    /// @notice Emergency switch for new deposits. Withdrawals and transfers stay open.
    function setDepositsPaused(bool paused) external onlyOwner {
        depositsPaused = paused;
        emit DepositsPausedSet(paused);
    }

    /// @notice Plaintext balance of `user`.
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /// @dev Shared debit path for withdraw and transfer: rejects zero amounts and overdrafts,
    ///      then lowers the balance. Keeps the overdraft check in one place for the FHE port.
    function _debit(address from, uint256 amount) private {
        if (amount == 0) revert ZeroAmount();
        uint256 balance = _balances[from];
        if (amount > balance) revert InsufficientBalance(balance, amount);

        unchecked {
            _balances[from] = balance - amount;
        }
    }
}
