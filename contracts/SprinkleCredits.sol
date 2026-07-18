// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SprinkleCredits
/// @notice On-chain credit ledger for Sprinkle platform on Robinhood Chain.
///         Users top-up by sending ETH → credits minted on-chain.
///         Backend signer deducts credits when services are consumed.
///         Source of truth for all billing — DB is a cache of on-chain state.
contract SprinkleCredits {

    address public owner;
    address public treasury;
    address public backendSigner; // only address that can call spend()

    uint256 public constant CREDITS_PER_ETH = 100_000;

    /// @notice On-chain credit balance per wallet address
    mapping(address => uint256) public creditBalance;

    /// @notice Tracks used topup txHashes to prevent double-claiming
    mapping(bytes32 => bool) public usedTxHash;

    // ── Events ────────────────────────────────────────────────────────────────

    event CreditsMinted(
        address indexed payer,
        uint256 ethAmount,
        uint256 credits,
        string userId,      // Sprinkle internal user ID
        uint256 newBalance
    );

    event CreditsSpent(
        address indexed user,
        uint256 credits,
        string service,     // "ai", "relay", "wallet", "domain", "key"
        uint256 newBalance,
        string requestId    // Sprinkle internal request ID for traceability
    );

    event CreditsGranted(
        address indexed user,
        uint256 credits,
        string reason,
        uint256 newBalance
    );

    event BackendSignerUpdated(address indexed newSigner);
    event Swept(address indexed to, uint256 amount);

    // ── Access control ────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyBackend() {
        require(msg.sender == backendSigner, "Not backend");
        _;
    }

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(address _treasury, address _backendSigner) {
        owner = msg.sender;
        treasury = _treasury;
        backendSigner = _backendSigner;
    }

    // ── User-facing ───────────────────────────────────────────────────────────

    /// @notice Send ETH to mint credits. Pass Sprinkle userId for backend linking.
    function pay(string calldata userId) external payable {
        require(msg.value > 0, "No ETH sent");
        uint256 credits = (msg.value * CREDITS_PER_ETH) / 1 ether;
        creditBalance[msg.sender] += credits;
        emit CreditsMinted(msg.sender, msg.value, credits, userId, creditBalance[msg.sender]);
    }

    // ── Backend-only ──────────────────────────────────────────────────────────

    /// @notice Deduct credits for service usage. Only callable by backend signer.
    /// @param user         Wallet address of the user
    /// @param credits      Credits to deduct
    /// @param service      Service name ("ai", "relay", "wallet", "domain", "key")
    /// @param requestId    Internal request/log ID for traceability
    function spend(
        address user,
        uint256 credits,
        string calldata service,
        string calldata requestId
    ) external onlyBackend {
        require(creditBalance[user] >= credits, "Insufficient credits");
        creditBalance[user] -= credits;
        emit CreditsSpent(user, credits, service, creditBalance[user], requestId);
    }

    /// @notice Grant free credits to a user (signup bonus, promotions, etc).
    ///         Only callable by backend signer. cSPRINK is non-transferable.
    function giveCredits(
        address user,
        uint256 credits,
        string calldata reason
    ) external onlyBackend {
        require(credits > 0, "Zero credits");
        creditBalance[user] += credits;
        emit CreditsGranted(user, credits, reason, creditBalance[user]);
    }

    /// @notice Batch-spend for multiple users in one tx (gas efficient).
    function spendBatch(
        address[] calldata users,
        uint256[] calldata credits,
        string[] calldata services,
        string[] calldata requestIds
    ) external onlyBackend {
        require(users.length == credits.length && credits.length == services.length, "Length mismatch");
        for (uint256 i = 0; i < users.length; i++) {
            if (creditBalance[users[i]] >= credits[i]) {
                creditBalance[users[i]] -= credits[i];
                emit CreditsSpent(users[i], credits[i], services[i], creditBalance[users[i]], requestIds[i]);
            }
        }
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    function setBackendSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Zero address");
        backendSigner = _signer;
        emit BackendSignerUpdated(_signer);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function sweep() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Nothing to sweep");
        (bool ok, ) = treasury.call{value: bal}("");
        require(ok, "Sweep failed");
        emit Swept(treasury, bal);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    /// @notice Accept plain ETH transfers (no credit minting — use pay() instead)
    receive() external payable {}
}
