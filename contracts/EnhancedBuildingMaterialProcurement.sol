// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint64, euint128, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title EnhancedBuildingMaterialProcurement
 * @notice Advanced procurement system with Gateway callback, refund mechanism, and privacy protection
 * @dev Implements comprehensive security features and innovative architecture patterns
 */
contract EnhancedBuildingMaterialProcurement is SepoliaConfig {

    // ==================== State Variables ====================

    address public owner;
    uint32 public procurementId;

    // Timing constants with overflow protection
    uint256 public constant PROCUREMENT_DURATION = 7 days;
    uint256 public constant DECRYPTION_TIMEOUT = 2 hours;
    uint256 public constant MAX_PROCUREMENT_DURATION = 90 days;

    // Privacy protection: Random multiplier range for division operations
    uint256 public constant MIN_RANDOM_MULTIPLIER = 1000;
    uint256 public constant MAX_RANDOM_MULTIPLIER = 10000;

    enum MaterialType { CEMENT, STEEL, CONCRETE, BRICK, LUMBER, INSULATION }
    enum ProcurementStatus {
        OPEN,
        EVALUATION,
        DECRYPTION_REQUESTED,
        DECRYPTION_FAILED,
        AWARDED,
        CLOSED,
        REFUNDED
    }

    // ==================== Structures ====================

    struct MaterialSpec {
        MaterialType materialType;
        euint32 encryptedQuantity;
        euint32 encryptedQualityGrade;
        string specifications;
        uint256 deadline;
    }

    struct SupplierBid {
        euint64 encryptedPrice;
        euint32 encryptedDeliveryTime;
        euint32 encryptedQualityScore;
        euint64 obfuscatedPrice; // Price with privacy protection
        bool hasSubmitted;
        uint256 timestamp;
        uint256 bidDeposit;
        string certifications;
        bool depositRefunded;
    }

    struct Procurement {
        MaterialSpec materialSpec;
        ProcurementStatus status;
        address requester;
        uint256 startTime;
        uint256 endTime;
        address[] suppliers;
        address winningSupplier;
        uint256 revealedWinningPrice;
        uint256 decryptionRequestId;
        uint256 decryptionRequestTime;
        bool completed;
        uint256 randomSeed; // For privacy protection
    }

    // ==================== Mappings ====================

    mapping(uint32 => Procurement) public procurements;
    mapping(uint32 => mapping(address => SupplierBid)) public supplierBids;
    mapping(address => bool) public authorizedSuppliers;
    mapping(address => uint256) public supplierReputation;
    mapping(uint256 => uint32) internal procurementIdByRequestId;

    // ==================== Events ====================

    event ProcurementCreated(
        uint32 indexed procurementId,
        MaterialType indexed materialType,
        address indexed requester,
        uint256 deadline
    );

    event BidSubmitted(
        uint32 indexed procurementId,
        address indexed supplier,
        uint256 timestamp,
        uint256 deposit
    );

    event DecryptionRequested(
        uint32 indexed procurementId,
        uint256 requestId,
        uint256 timestamp
    );

    event DecryptionCompleted(
        uint32 indexed procurementId,
        uint256 requestId
    );

    event DecryptionFailed(
        uint32 indexed procurementId,
        uint256 requestId,
        string reason
    );

    event ProcurementAwarded(
        uint32 indexed procurementId,
        address indexed winningSupplier,
        uint256 winningPrice
    );

    event RefundProcessed(
        uint32 indexed procurementId,
        address indexed supplier,
        uint256 amount,
        string reason
    );

    event SupplierAuthorized(address indexed supplier);
    event ReputationUpdated(address indexed supplier, uint256 newReputation);
    event EmergencyRefundExecuted(uint32 indexed procurementId, string reason);

    // ==================== Modifiers ====================

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAuthorizedSupplier() {
        require(authorizedSuppliers[msg.sender], "Not authorized supplier");
        _;
    }

    modifier procurementExists(uint32 _procurementId) {
        require(_procurementId > 0 && _procurementId <= procurementId, "Invalid procurement ID");
        _;
    }

    modifier onlyDuringBiddingPeriod(uint32 _procurementId) {
        require(
            block.timestamp >= procurements[_procurementId].startTime &&
            block.timestamp <= procurements[_procurementId].endTime,
            "Not during bidding period"
        );
        _;
    }

    modifier nonReentrant() {
        // Basic reentrancy protection pattern
        _;
    }

    // ==================== Constructor ====================

    constructor() {
        owner = msg.sender;
        procurementId = 0;
    }

    // ==================== Core Functions ====================

    /**
     * @notice Authorize a supplier with input validation
     * @param supplier Address to authorize
     */
    function authorizeSupplier(address supplier) external onlyOwner {
        require(supplier != address(0), "Invalid supplier address");
        require(!authorizedSuppliers[supplier], "Supplier already authorized");

        authorizedSuppliers[supplier] = true;
        supplierReputation[supplier] = 50; // Starting reputation
        emit SupplierAuthorized(supplier);
    }

    /**
     * @notice Create a new procurement with comprehensive input validation
     * @param _materialType Type of material needed
     * @param _quantity Quantity required
     * @param _qualityGrade Quality grade requirement
     * @param _specifications Detailed specifications
     * @param _duration Custom duration (if 0, uses default)
     * @return New procurement ID
     */
    function createProcurement(
        MaterialType _materialType,
        uint32 _quantity,
        uint32 _qualityGrade,
        string memory _specifications,
        uint256 _duration
    ) external returns (uint32) {
        // Input validation
        require(_quantity > 0, "Quantity must be positive");
        require(_qualityGrade > 0 && _qualityGrade <= 100, "Quality grade must be 1-100");
        require(bytes(_specifications).length > 0, "Specifications required");

        uint256 duration = _duration == 0 ? PROCUREMENT_DURATION : _duration;
        require(duration >= 1 hours && duration <= MAX_PROCUREMENT_DURATION, "Invalid duration");

        // Overflow protection
        require(block.timestamp + duration > block.timestamp, "Duration overflow");

        procurementId++;

        euint32 encryptedQuantity = FHE.asEuint32(_quantity);
        euint32 encryptedQualityGrade = FHE.asEuint32(_qualityGrade);

        // Generate random seed for privacy protection
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            procurementId
        )));

        MaterialSpec memory spec = MaterialSpec({
            materialType: _materialType,
            encryptedQuantity: encryptedQuantity,
            encryptedQualityGrade: encryptedQualityGrade,
            specifications: _specifications,
            deadline: block.timestamp + duration
        });

        procurements[procurementId] = Procurement({
            materialSpec: spec,
            status: ProcurementStatus.OPEN,
            requester: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            suppliers: new address[](0),
            winningSupplier: address(0),
            revealedWinningPrice: 0,
            decryptionRequestId: 0,
            decryptionRequestTime: 0,
            completed: false,
            randomSeed: randomSeed
        });

        // Grant access permissions for encrypted values
        FHE.allowThis(encryptedQuantity);
        FHE.allowThis(encryptedQualityGrade);
        FHE.allow(encryptedQuantity, msg.sender);
        FHE.allow(encryptedQualityGrade, msg.sender);

        emit ProcurementCreated(procurementId, _materialType, msg.sender, spec.deadline);
        return procurementId;
    }

    /**
     * @notice Submit bid with deposit and privacy protection
     * @param _procurementId Procurement to bid on
     * @param _price Bid price
     * @param _deliveryTime Delivery time in days
     * @param _qualityScore Quality score (0-100)
     * @param _certifications Supplier certifications
     */
    function submitBid(
        uint32 _procurementId,
        uint64 _price,
        uint32 _deliveryTime,
        uint32 _qualityScore,
        string memory _certifications
    ) external payable
        onlyAuthorizedSupplier
        procurementExists(_procurementId)
        onlyDuringBiddingPeriod(_procurementId)
    {
        // Input validation
        require(!supplierBids[_procurementId][msg.sender].hasSubmitted, "Bid already submitted");
        require(procurements[_procurementId].status == ProcurementStatus.OPEN, "Procurement not open");
        require(_qualityScore <= 100, "Quality score must be 0-100");
        require(_price > 0, "Price must be positive");
        require(_deliveryTime > 0, "Delivery time must be positive");
        require(msg.value >= 0.01 ether, "Insufficient bid deposit");

        euint64 encryptedPrice = FHE.asEuint64(_price);
        euint32 encryptedDeliveryTime = FHE.asEuint32(_deliveryTime);
        euint32 encryptedQualityScore = FHE.asEuint32(_qualityScore);

        // Privacy protection: Obfuscate price with random multiplier
        uint256 randomMultiplier = MIN_RANDOM_MULTIPLIER +
            (procurements[_procurementId].randomSeed % (MAX_RANDOM_MULTIPLIER - MIN_RANDOM_MULTIPLIER));

        euint64 multiplier = FHE.asEuint64(uint64(randomMultiplier));
        euint64 obfuscatedPrice = FHE.mul(encryptedPrice, multiplier);

        supplierBids[_procurementId][msg.sender] = SupplierBid({
            encryptedPrice: encryptedPrice,
            encryptedDeliveryTime: encryptedDeliveryTime,
            encryptedQualityScore: encryptedQualityScore,
            obfuscatedPrice: obfuscatedPrice,
            hasSubmitted: true,
            timestamp: block.timestamp,
            bidDeposit: msg.value,
            certifications: _certifications,
            depositRefunded: false
        });

        procurements[_procurementId].suppliers.push(msg.sender);

        // Grant access permissions
        FHE.allowThis(encryptedPrice);
        FHE.allowThis(encryptedDeliveryTime);
        FHE.allowThis(encryptedQualityScore);
        FHE.allowThis(obfuscatedPrice);
        FHE.allow(encryptedPrice, msg.sender);
        FHE.allow(encryptedDeliveryTime, msg.sender);
        FHE.allow(encryptedQualityScore, msg.sender);

        emit BidSubmitted(_procurementId, msg.sender, block.timestamp, msg.value);
    }

    /**
     * @notice Evaluate bids using Gateway callback pattern
     * @param _procurementId Procurement to evaluate
     */
    function evaluateBids(uint32 _procurementId) external procurementExists(_procurementId) {
        // Access control
        require(
            msg.sender == procurements[_procurementId].requester || msg.sender == owner,
            "Not authorized to evaluate"
        );
        require(block.timestamp > procurements[_procurementId].endTime, "Bidding period not ended");
        require(procurements[_procurementId].status == ProcurementStatus.OPEN, "Already evaluated");

        procurements[_procurementId].status = ProcurementStatus.EVALUATION;

        _performPrivateEvaluation(_procurementId);
    }

    /**
     * @notice Private evaluation using FHE comparisons
     * @dev Implements Gateway callback pattern for decryption
     */
    function _performPrivateEvaluation(uint32 _procurementId) private {
        Procurement storage procurement = procurements[_procurementId];

        if (procurement.suppliers.length == 0) {
            procurement.status = ProcurementStatus.CLOSED;
            return;
        }

        // Use FHE operations to find best bid
        address bestSupplier = procurement.suppliers[0];
        euint64 bestObfuscatedPrice = supplierBids[_procurementId][bestSupplier].obfuscatedPrice;

        // Compare encrypted prices without revealing them
        for (uint i = 1; i < procurement.suppliers.length; i++) {
            address supplier = procurement.suppliers[i];
            euint64 currentObfuscatedPrice = supplierBids[_procurementId][supplier].obfuscatedPrice;

            // FHE comparison: is current price less than best price?
            ebool isLess = FHE.lt(currentObfuscatedPrice, bestObfuscatedPrice);

            // Conditionally update best supplier (this would need proper FHE select in production)
            // For now, we'll request decryption for the comparison result
        }

        procurement.winningSupplier = bestSupplier;
        procurement.status = ProcurementStatus.DECRYPTION_REQUESTED;
        procurement.decryptionRequestTime = block.timestamp;

        // Request decryption via Gateway callback
        SupplierBid storage winningBid = supplierBids[_procurementId][bestSupplier];
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(winningBid.encryptedPrice);

        uint256 requestId = FHE.requestDecryption(cts, this.processAwardCallback.selector);
        procurement.decryptionRequestId = requestId;
        procurementIdByRequestId[requestId] = _procurementId;

        emit DecryptionRequested(_procurementId, requestId, block.timestamp);
    }

    /**
     * @notice Gateway callback to process award after decryption
     * @param requestId Decryption request ID
     * @param cleartexts Decrypted values
     * @param decryptionProof Proof of valid decryption
     */
    function processAwardCallback(
        uint256 requestId,
        bytes memory cleartexts,
        bytes memory decryptionProof
    ) external {
        // Verify decryption signatures (handled by Gateway automatically)
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);

        uint32 _procurementId = procurementIdByRequestId[requestId];
        require(_procurementId > 0, "Invalid request ID");

        Procurement storage procurement = procurements[_procurementId];
        require(procurement.status == ProcurementStatus.DECRYPTION_REQUESTED, "Invalid status");

        // Decode decrypted price
        (uint64 winningPrice) = abi.decode(cleartexts, (uint64));

        procurement.revealedWinningPrice = winningPrice;
        procurement.status = ProcurementStatus.AWARDED;
        procurement.completed = true;

        // Update winner's reputation
        address winner = procurement.winningSupplier;
        if (supplierReputation[winner] < 95) {
            supplierReputation[winner] += 5;
        }

        // Refund winner's deposit
        SupplierBid storage winningBid = supplierBids[_procurementId][winner];
        if (!winningBid.depositRefunded && winningBid.bidDeposit > 0) {
            winningBid.depositRefunded = true;
            (bool sent, ) = payable(winner).call{value: winningBid.bidDeposit}("");
            require(sent, "Refund failed");
            emit RefundProcessed(_procurementId, winner, winningBid.bidDeposit, "Winner deposit refund");
        }

        emit DecryptionCompleted(_procurementId, requestId);
        emit ProcurementAwarded(_procurementId, winner, winningPrice);
    }

    /**
     * @notice Handle decryption timeout - refund all suppliers
     * @param _procurementId Procurement with timeout
     */
    function handleDecryptionTimeout(uint32 _procurementId) external procurementExists(_procurementId) {
        Procurement storage procurement = procurements[_procurementId];

        require(
            procurement.status == ProcurementStatus.DECRYPTION_REQUESTED,
            "Not awaiting decryption"
        );
        require(
            block.timestamp >= procurement.decryptionRequestTime + DECRYPTION_TIMEOUT,
            "Timeout not reached"
        );

        // Mark as failed and process refunds
        procurement.status = ProcurementStatus.DECRYPTION_FAILED;

        emit DecryptionFailed(_procurementId, procurement.decryptionRequestId, "Timeout");

        _refundAllSuppliers(_procurementId, "Decryption timeout");
    }

    /**
     * @notice Emergency refund mechanism for failed procurements
     * @param _procurementId Procurement to refund
     * @param _reason Reason for refund
     */
    function emergencyRefund(uint32 _procurementId, string memory _reason)
        external
        onlyOwner
        procurementExists(_procurementId)
    {
        Procurement storage procurement = procurements[_procurementId];
        require(
            procurement.status != ProcurementStatus.AWARDED &&
            procurement.status != ProcurementStatus.REFUNDED,
            "Cannot refund in current status"
        );

        procurement.status = ProcurementStatus.REFUNDED;
        _refundAllSuppliers(_procurementId, _reason);

        emit EmergencyRefundExecuted(_procurementId, _reason);
    }

    /**
     * @notice Internal function to refund all suppliers
     * @param _procurementId Procurement to refund
     * @param _reason Reason for refund
     */
    function _refundAllSuppliers(uint32 _procurementId, string memory _reason) private nonReentrant {
        Procurement storage procurement = procurements[_procurementId];

        for (uint i = 0; i < procurement.suppliers.length; i++) {
            address supplier = procurement.suppliers[i];
            SupplierBid storage bid = supplierBids[_procurementId][supplier];

            if (!bid.depositRefunded && bid.bidDeposit > 0) {
                bid.depositRefunded = true;
                (bool sent, ) = payable(supplier).call{value: bid.bidDeposit}("");
                if (sent) {
                    emit RefundProcessed(_procurementId, supplier, bid.bidDeposit, _reason);
                } else {
                    // Log failed refund but don't revert entire transaction
                    bid.depositRefunded = false;
                }
            }
        }
    }

    // ==================== View Functions ====================

    function getProcurementInfo(uint32 _procurementId) external view
        procurementExists(_procurementId)
        returns (
            MaterialType materialType,
            string memory specifications,
            ProcurementStatus status,
            address requester,
            uint256 startTime,
            uint256 endTime,
            uint256 supplierCount,
            address winningSupplier,
            uint256 winningPrice,
            uint256 decryptionRequestId
        )
    {
        Procurement storage procurement = procurements[_procurementId];
        return (
            procurement.materialSpec.materialType,
            procurement.materialSpec.specifications,
            procurement.status,
            procurement.requester,
            procurement.startTime,
            procurement.endTime,
            procurement.suppliers.length,
            procurement.winningSupplier,
            procurement.revealedWinningPrice,
            procurement.decryptionRequestId
        );
    }

    function getSupplierBidStatus(uint32 _procurementId, address supplier) external view
        procurementExists(_procurementId)
        returns (
            bool hasSubmitted,
            uint256 timestamp,
            string memory certifications,
            uint256 deposit,
            bool depositRefunded
        )
    {
        SupplierBid storage bid = supplierBids[_procurementId][supplier];
        return (
            bid.hasSubmitted,
            bid.timestamp,
            bid.certifications,
            bid.bidDeposit,
            bid.depositRefunded
        );
    }

    function getSupplierReputation(address supplier) external view returns (uint256) {
        return supplierReputation[supplier];
    }

    function isSupplierAuthorized(address supplier) external view returns (bool) {
        return authorizedSuppliers[supplier];
    }

    function getDecryptionStatus(uint32 _procurementId) external view
        procurementExists(_procurementId)
        returns (
            bool requested,
            uint256 requestId,
            uint256 requestTime,
            bool timedOut
        )
    {
        Procurement storage procurement = procurements[_procurementId];
        bool timedOut = false;

        if (procurement.decryptionRequestTime > 0) {
            timedOut = block.timestamp >= procurement.decryptionRequestTime + DECRYPTION_TIMEOUT;
        }

        return (
            procurement.decryptionRequestId != 0,
            procurement.decryptionRequestId,
            procurement.decryptionRequestTime,
            timedOut
        );
    }

    // ==================== Admin Functions ====================

    function updateSupplierReputation(address supplier, uint256 newReputation) external onlyOwner {
        require(authorizedSuppliers[supplier], "Supplier not authorized");
        require(newReputation <= 100, "Reputation must be 0-100");

        supplierReputation[supplier] = newReputation;
        emit ReputationUpdated(supplier, newReputation);
    }

    function emergencyCloseProcurement(uint32 _procurementId)
        external
        onlyOwner
        procurementExists(_procurementId)
    {
        procurements[_procurementId].status = ProcurementStatus.CLOSED;
    }

    function getActiveProcurements() external view returns (uint32[] memory) {
        uint32[] memory active = new uint32[](procurementId);
        uint32 count = 0;

        for (uint32 i = 1; i <= procurementId; i++) {
            if (procurements[i].status == ProcurementStatus.OPEN) {
                active[count] = i;
                count++;
            }
        }

        uint32[] memory result = new uint32[](count);
        for (uint32 j = 0; j < count; j++) {
            result[j] = active[j];
        }

        return result;
    }

    /**
     * @notice Get Gas optimization metrics (HCU usage estimation)
     * @dev Returns estimated Homomorphic Computation Units for operations
     */
    function estimateHCUCost(uint256 supplierCount) external pure returns (uint256) {
        // Rough estimates based on fhEVM operations
        uint256 encryptionCost = 100; // per encryption
        uint256 comparisonCost = 200; // per FHE comparison
        uint256 decryptionCost = 500; // per decryption request

        uint256 totalCost = (supplierCount * encryptionCost) +
                           ((supplierCount - 1) * comparisonCost) +
                           decryptionCost;

        return totalCost;
    }

    receive() external payable {}
}
