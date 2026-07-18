// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SprinkleDataRegistry
/// @notice On-chain proof-of-existence registry for Sprinkle platform data.
///         Stores keccak256 hashes of messages, files, and tasks — not the content itself.
///         Content stays in the private database; the hash on-chain is the immutable proof.
contract SprinkleDataRegistry {

    address public owner;
    address public backendSigner;

    struct Record {
        bool exists;
        uint256 timestamp;
        string meta; // service, file name, etc.
    }

    /// user => messageHash => record
    mapping(address => mapping(bytes32 => Record)) public messages;
    /// user => fileHash => record
    mapping(address => mapping(bytes32 => Record)) public files;
    /// user => taskId => record
    mapping(address => mapping(bytes32 => Record)) public tasks;

    // ── Events ────────────────────────────────────────────────────────────────

    event MessageAnchored(
        address indexed user,
        bytes32 indexed sessionId,
        bytes32 messageHash,
        string service,
        uint256 timestamp
    );

    event FileAnchored(
        address indexed user,
        bytes32 fileHash,
        string name,
        uint256 timestamp
    );

    event TaskAnchored(
        address indexed user,
        bytes32 indexed taskId,
        bytes32 promptHash,
        uint256 timestamp
    );

    event BackendSignerUpdated(address indexed newSigner);

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

    constructor(address _backendSigner) {
        owner = msg.sender;
        backendSigner = _backendSigner;
    }

    // ── Backend writes ────────────────────────────────────────────────────────

    /// @notice Anchor a chat message hash. Called after every AI response.
    function anchorMessage(
        address user,
        bytes32 sessionId,
        bytes32 messageHash,
        string calldata service
    ) external onlyBackend {
        messages[user][messageHash] = Record(true, block.timestamp, service);
        emit MessageAnchored(user, sessionId, messageHash, service, block.timestamp);
    }

    /// @notice Anchor a file hash. Called when user uploads a file.
    function anchorFile(
        address user,
        bytes32 fileHash,
        string calldata name
    ) external onlyBackend {
        files[user][fileHash] = Record(true, block.timestamp, name);
        emit FileAnchored(user, fileHash, name, block.timestamp);
    }

    /// @notice Anchor a task. Called when a task completes.
    function anchorTask(
        address user,
        bytes32 taskId,
        bytes32 promptHash
    ) external onlyBackend {
        tasks[user][taskId] = Record(true, block.timestamp, "");
        emit TaskAnchored(user, taskId, promptHash, block.timestamp);
    }

    // ── Public views ──────────────────────────────────────────────────────────

    function verifyMessage(
        address user,
        bytes32 messageHash
    ) external view returns (bool exists, uint256 timestamp, string memory service) {
        Record memory r = messages[user][messageHash];
        return (r.exists, r.timestamp, r.meta);
    }

    function verifyFile(
        address user,
        bytes32 fileHash
    ) external view returns (bool exists, uint256 timestamp, string memory name) {
        Record memory r = files[user][fileHash];
        return (r.exists, r.timestamp, r.meta);
    }

    function verifyTask(
        address user,
        bytes32 taskId
    ) external view returns (bool exists, uint256 timestamp) {
        Record memory r = tasks[user][taskId];
        return (r.exists, r.timestamp);
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    function setBackendSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Zero address");
        backendSigner = _signer;
        emit BackendSignerUpdated(_signer);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}
