// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SprinklePayments
/// @notice Receives ETH on Robinhood Chain and emits events the backend listens to.
///         Funds accumulate and are swept by the owner to treasury.
contract SprinklePayments {
    address public owner;
    address public treasury;

    uint256 public constant CREDITS_PER_ETH = 100_000;

    event PaymentReceived(
        address indexed payer,
        uint256 amount,
        uint256 credits,
        string userId  // Sprinkle internal user ID, supplied in calldata
    );

    event Swept(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _treasury) {
        owner = msg.sender;
        treasury = _treasury;
    }

    /// @notice Pay for credits. Pass your Sprinkle user ID as userId.
    function pay(string calldata userId) external payable {
        require(msg.value > 0, "No ETH sent");
        uint256 credits = (msg.value * CREDITS_PER_ETH) / 1 ether;
        emit PaymentReceived(msg.sender, msg.value, credits, userId);
    }

    /// @notice Sweep accumulated ETH to treasury (owner only).
    function sweep() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Nothing to sweep");
        (bool ok, ) = treasury.call{value: bal}("");
        require(ok, "Sweep failed");
        emit Swept(treasury, bal);
    }

    /// @notice Update treasury address.
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /// @notice Transfer ownership.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    receive() external payable {
        // Direct transfers without userId are accepted but not credited
        emit PaymentReceived(msg.sender, msg.value, 0, "");
    }
}
