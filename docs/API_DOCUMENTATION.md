# Enhanced Building Material Procurement - API Documentation

## Contract Overview

**Contract Name:** `EnhancedBuildingMaterialProcurement`
**License:** MIT
**Solidity Version:** ^0.8.24
**Inherits:** SepoliaConfig (Zama fhEVM)

## Table of Contents

1. [Enums](#enums)
2. [Structures](#structures)
3. [State Variables](#state-variables)
4. [Events](#events)
5. [Modifiers](#modifiers)
6. [Core Functions](#core-functions)
7. [View Functions](#view-functions)
8. [Admin Functions](#admin-functions)

---

## Enums

### MaterialType

Enumeration of supported building materials.

```solidity
enum MaterialType {
    CEMENT,      // 0
    STEEL,       // 1
    CONCRETE,    // 2
    BRICK,       // 3
    LUMBER,      // 4
    INSULATION   // 5
}
```

### ProcurementStatus

Current state of a procurement process.

```solidity
enum ProcurementStatus {
    OPEN,                    // 0 - Accepting bids
    EVALUATION,              // 1 - Evaluating bids
    DECRYPTION_REQUESTED,    // 2 - Waiting for Gateway callback
    DECRYPTION_FAILED,       // 3 - Decryption timeout/error
    AWARDED,                 // 4 - Winner selected
    CLOSED,                  // 5 - Closed without award
    REFUNDED                 // 6 - Emergency refund processed
}
```

---

## Structures

### MaterialSpec

Specification for requested materials.

```solidity
struct MaterialSpec {
    MaterialType materialType;           // Type of material
    euint32 encryptedQuantity;          // FHE-encrypted quantity
    euint32 encryptedQualityGrade;      // FHE-encrypted quality (1-100)
    string specifications;               // Detailed requirements
    uint256 deadline;                    // Submission deadline (timestamp)
}
```

### SupplierBid

Supplier's bid information.

```solidity
struct SupplierBid {
    euint64 encryptedPrice;             // FHE-encrypted bid price
    euint32 encryptedDeliveryTime;      // FHE-encrypted delivery time (days)
    euint32 encryptedQualityScore;      // FHE-encrypted quality score (0-100)
    euint64 obfuscatedPrice;            // Privacy-protected price for comparisons
    bool hasSubmitted;                   // Bid submission flag
    uint256 timestamp;                   // Submission timestamp
    uint256 bidDeposit;                  // ETH deposit amount
    string certifications;               // Supplier certifications
    bool depositRefunded;                // Refund processed flag
}
```

### Procurement

Complete procurement information.

```solidity
struct Procurement {
    MaterialSpec materialSpec;           // Material specifications
    ProcurementStatus status;            // Current status
    address requester;                   // Procurement creator
    uint256 startTime;                   // Start timestamp
    uint256 endTime;                     // End timestamp
    address[] suppliers;                 // List of bidding suppliers
    address winningSupplier;             // Awarded supplier
    uint256 revealedWinningPrice;        // Decrypted winning price
    uint256 decryptionRequestId;         // Gateway request ID
    uint256 decryptionRequestTime;       // Decryption request timestamp
    bool completed;                      // Completion flag
    uint256 randomSeed;                  // Privacy protection seed
}
```

---

## State Variables

### Public Variables

```solidity
address public owner;                                    // Contract owner
uint32 public procurementId;                            // Current procurement counter

// Timing constants
uint256 public constant PROCUREMENT_DURATION = 7 days;
uint256 public constant DECRYPTION_TIMEOUT = 2 hours;
uint256 public constant MAX_PROCUREMENT_DURATION = 90 days;

// Privacy protection
uint256 public constant MIN_RANDOM_MULTIPLIER = 1000;
uint256 public constant MAX_RANDOM_MULTIPLIER = 10000;
```

### Mappings

```solidity
mapping(uint32 => Procurement) public procurements;                      // Procurement by ID
mapping(uint32 => mapping(address => SupplierBid)) public supplierBids; // Bids by procurement & supplier
mapping(address => bool) public authorizedSuppliers;                     // Authorized supplier registry
mapping(address => uint256) public supplierReputation;                   // Supplier reputation (0-100)
```

---

## Events

### ProcurementCreated

Emitted when a new procurement is created.

```solidity
event ProcurementCreated(
    uint32 indexed procurementId,
    MaterialType indexed materialType,
    address indexed requester,
    uint256 deadline
);
```

### BidSubmitted

Emitted when a supplier submits a bid.

```solidity
event BidSubmitted(
    uint32 indexed procurementId,
    address indexed supplier,
    uint256 timestamp,
    uint256 deposit
);
```

### DecryptionRequested

Emitted when decryption is requested from Gateway.

```solidity
event DecryptionRequested(
    uint32 indexed procurementId,
    uint256 requestId,
    uint256 timestamp
);
```

### DecryptionCompleted

Emitted when Gateway callback completes successfully.

```solidity
event DecryptionCompleted(
    uint32 indexed procurementId,
    uint256 requestId
);
```

### DecryptionFailed

Emitted when decryption times out or fails.

```solidity
event DecryptionFailed(
    uint32 indexed procurementId,
    uint256 requestId,
    string reason
);
```

### ProcurementAwarded

Emitted when a procurement is awarded to a supplier.

```solidity
event ProcurementAwarded(
    uint32 indexed procurementId,
    address indexed winningSupplier,
    uint256 winningPrice
);
```

### RefundProcessed

Emitted when a supplier deposit is refunded.

```solidity
event RefundProcessed(
    uint32 indexed procurementId,
    address indexed supplier,
    uint256 amount,
    string reason
);
```

### SupplierAuthorized

Emitted when a supplier is authorized.

```solidity
event SupplierAuthorized(address indexed supplier);
```

### ReputationUpdated

Emitted when supplier reputation is updated.

```solidity
event ReputationUpdated(address indexed supplier, uint256 newReputation);
```

### EmergencyRefundExecuted

Emitted when emergency refund is triggered.

```solidity
event EmergencyRefundExecuted(uint32 indexed procurementId, string reason);
```

---

## Modifiers

### onlyOwner

Restricts function access to contract owner.

```solidity
modifier onlyOwner()
```

**Reverts:** "Not authorized"

### onlyAuthorizedSupplier

Restricts function access to authorized suppliers.

```solidity
modifier onlyAuthorizedSupplier()
```

**Reverts:** "Not authorized supplier"

### procurementExists

Validates procurement ID exists.

```solidity
modifier procurementExists(uint32 _procurementId)
```

**Reverts:** "Invalid procurement ID"

### onlyDuringBiddingPeriod

Ensures function called during bidding window.

```solidity
modifier onlyDuringBiddingPeriod(uint32 _procurementId)
```

**Reverts:** "Not during bidding period"

---

## Core Functions

### authorizeSupplier

Authorize a supplier to participate in bidding.

```solidity
function authorizeSupplier(address supplier) external onlyOwner
```

**Parameters:**
- `supplier` (address): Address to authorize

**Requirements:**
- Caller must be owner
- Supplier address must be valid (non-zero)
- Supplier must not already be authorized

**Effects:**
- Adds supplier to authorized list
- Sets initial reputation to 50
- Emits `SupplierAuthorized` event

**Example:**
```javascript
await contract.authorizeSupplier("0x1234...");
```

---

### createProcurement

Create a new material procurement request.

```solidity
function createProcurement(
    MaterialType _materialType,
    uint32 _quantity,
    uint32 _qualityGrade,
    string memory _specifications,
    uint256 _duration
) external returns (uint32)
```

**Parameters:**
- `_materialType` (MaterialType): Type of material needed
- `_quantity` (uint32): Required quantity (must be > 0)
- `_qualityGrade` (uint32): Quality requirement (1-100)
- `_specifications` (string): Detailed specifications
- `_duration` (uint256): Custom duration in seconds (0 = default 7 days)

**Returns:**
- `uint32`: New procurement ID

**Requirements:**
- Quantity must be positive
- Quality grade must be 1-100
- Specifications must not be empty
- Duration must be 1 hour to 90 days
- No timestamp overflow

**Effects:**
- Increments procurement counter
- Creates new procurement with encrypted specs
- Generates random seed for privacy
- Sets status to OPEN
- Emits `ProcurementCreated` event

**Gas Cost:** ~200,000 + encryption costs

**Example:**
```javascript
const tx = await contract.createProcurement(
    1,  // STEEL
    1000,  // quantity
    85,  // quality grade
    "High-grade construction steel, corrosion-resistant",
    7 * 24 * 60 * 60  // 7 days
);
const receipt = await tx.wait();
const procurementId = receipt.events[0].args.procurementId;
```

---

### submitBid

Submit an encrypted bid for a procurement.

```solidity
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
```

**Parameters:**
- `_procurementId` (uint32): Procurement to bid on
- `_price` (uint64): Bid price (will be encrypted)
- `_deliveryTime` (uint32): Delivery time in days
- `_qualityScore` (uint32): Quality score (0-100)
- `_certifications` (string): Supplier certifications

**Payable:** Requires minimum 0.01 ETH deposit

**Requirements:**
- Caller must be authorized supplier
- Procurement must exist and be OPEN
- Must be within bidding period
- Supplier hasn't already submitted bid
- Quality score must be 0-100
- Price and delivery time must be positive
- Deposit must be >= 0.01 ETH

**Effects:**
- Encrypts bid data with FHE
- Creates obfuscated price for privacy
- Stores bid with deposit
- Adds supplier to bidders list
- Emits `BidSubmitted` event

**Gas Cost:** ~300,000 + FHE encryption costs

**Example:**
```javascript
const tx = await contract.submitBid(
    procurementId,
    50000,  // price
    30,  // delivery time (days)
    90,  // quality score
    "ISO 9001:2015, ISO 14001:2015",
    { value: ethers.utils.parseEther("0.01") }
);
```

---

### evaluateBids

Initiate bid evaluation process.

```solidity
function evaluateBids(uint32 _procurementId) external
    procurementExists(_procurementId)
```

**Parameters:**
- `_procurementId` (uint32): Procurement to evaluate

**Requirements:**
- Caller must be requester or owner
- Bidding period must have ended
- Status must be OPEN (not already evaluated)
- Procurement must exist

**Effects:**
- Changes status to EVALUATION then DECRYPTION_REQUESTED
- Performs FHE comparison of obfuscated prices
- Selects best supplier (lowest price)
- Requests Gateway decryption
- Stores decryption request ID and timestamp
- Emits `DecryptionRequested` event

**Gas Cost:** ~100,000 + (50,000 × number of suppliers) + FHE comparison costs

**Example:**
```javascript
const tx = await contract.evaluateBids(procurementId);
// Wait for Gateway callback to complete award
```

---

### processAwardCallback

Gateway callback to finalize procurement award.

```solidity
function processAwardCallback(
    uint256 requestId,
    bytes memory cleartexts,
    bytes memory decryptionProof
) external
```

**Parameters:**
- `requestId` (uint256): Decryption request ID
- `cleartexts` (bytes): ABI-encoded decrypted price
- `decryptionProof` (bytes): Cryptographic proof

**Requirements:**
- Called by Gateway infrastructure
- Valid signature verification
- Request ID must match pending procurement
- Status must be DECRYPTION_REQUESTED

**Effects:**
- Verifies cryptographic proof
- Decodes winning price
- Updates procurement status to AWARDED
- Increases winner reputation by 5
- Refunds winner's deposit
- Emits `DecryptionCompleted` and `ProcurementAwarded` events

**Note:** This function is called automatically by the Gateway; users should not call it directly.

---

### handleDecryptionTimeout

Process timeout if Gateway callback doesn't arrive.

```solidity
function handleDecryptionTimeout(uint32 _procurementId) external
    procurementExists(_procurementId)
```

**Parameters:**
- `_procurementId` (uint32): Procurement with timeout

**Requirements:**
- Status must be DECRYPTION_REQUESTED
- Timeout period (2 hours) must have elapsed
- Procurement must exist

**Effects:**
- Changes status to DECRYPTION_FAILED
- Initiates refund to all suppliers
- Emits `DecryptionFailed` and `RefundProcessed` events

**Gas Cost:** ~50,000 × number of suppliers

**Example:**
```javascript
// If Gateway callback hasn't arrived after 2+ hours
const tx = await contract.handleDecryptionTimeout(procurementId);
```

---

### emergencyRefund

Owner-controlled emergency refund mechanism.

```solidity
function emergencyRefund(
    uint32 _procurementId,
    string memory _reason
) external onlyOwner procurementExists(_procurementId)
```

**Parameters:**
- `_procurementId` (uint32): Procurement to refund
- `_reason` (string): Reason for emergency refund

**Requirements:**
- Caller must be owner
- Status must not be AWARDED or already REFUNDED
- Procurement must exist

**Effects:**
- Changes status to REFUNDED
- Refunds all supplier deposits
- Emits `EmergencyRefundExecuted` and `RefundProcessed` events

**Gas Cost:** ~50,000 × number of suppliers

**Example:**
```javascript
await contract.emergencyRefund(
    procurementId,
    "Technical issue with evaluation process"
);
```

---

## View Functions

### getProcurementInfo

Get comprehensive procurement information.

```solidity
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
```

**Example:**
```javascript
const info = await contract.getProcurementInfo(procurementId);
console.log(`Status: ${info.status}, Suppliers: ${info.supplierCount}`);
```

---

### getSupplierBidStatus

Get supplier's bid information.

```solidity
function getSupplierBidStatus(uint32 _procurementId, address supplier) external view
    procurementExists(_procurementId)
    returns (
        bool hasSubmitted,
        uint256 timestamp,
        string memory certifications,
        uint256 deposit,
        bool depositRefunded
    )
```

**Example:**
```javascript
const bidStatus = await contract.getSupplierBidStatus(procurementId, supplierAddress);
console.log(`Submitted: ${bidStatus.hasSubmitted}, Deposit: ${bidStatus.deposit}`);
```

---

### getSupplierReputation

Get supplier's reputation score.

```solidity
function getSupplierReputation(address supplier) external view returns (uint256)
```

**Returns:** Reputation score (0-100)

---

### isSupplierAuthorized

Check if supplier is authorized.

```solidity
function isSupplierAuthorized(address supplier) external view returns (bool)
```

**Returns:** True if authorized

---

### getDecryptionStatus

Get decryption request status.

```solidity
function getDecryptionStatus(uint32 _procurementId) external view
    procurementExists(_procurementId)
    returns (
        bool requested,
        uint256 requestId,
        uint256 requestTime,
        bool timedOut
    )
```

**Returns:**
- `requested`: Whether decryption was requested
- `requestId`: Gateway request ID
- `requestTime`: Request timestamp
- `timedOut`: Whether timeout period elapsed

**Example:**
```javascript
const status = await contract.getDecryptionStatus(procurementId);
if (status.timedOut) {
    console.log("Can trigger timeout refund");
}
```

---

### getActiveProcurements

Get list of all open procurements.

```solidity
function getActiveProcurements() external view returns (uint32[] memory)
```

**Returns:** Array of procurement IDs with OPEN status

**Example:**
```javascript
const activeProcurements = await contract.getActiveProcurements();
for (const id of activeProcurements) {
    const info = await contract.getProcurementInfo(id);
    console.log(`Procurement ${id}: ${info.specifications}`);
}
```

---

### estimateHCUCost

Estimate Homomorphic Computation Unit cost.

```solidity
function estimateHCUCost(uint256 supplierCount) external pure returns (uint256)
```

**Parameters:**
- `supplierCount` (uint256): Number of expected suppliers

**Returns:** Estimated HCU cost

**Formula:**
```
HCU = (supplierCount × 100) + ((supplierCount - 1) × 200) + 500
```

**Example:**
```javascript
const hcuCost = await contract.estimateHCUCost(10);
console.log(`Estimated HCU for 10 suppliers: ${hcuCost}`);
```

---

## Admin Functions

### updateSupplierReputation

Update supplier's reputation score.

```solidity
function updateSupplierReputation(address supplier, uint256 newReputation) external onlyOwner
```

**Parameters:**
- `supplier` (address): Supplier address
- `newReputation` (uint256): New reputation (0-100)

**Requirements:**
- Caller must be owner
- Supplier must be authorized
- Reputation must be 0-100

---

### emergencyCloseProcurement

Emergency close a procurement without award.

```solidity
function emergencyCloseProcurement(uint32 _procurementId) external onlyOwner
    procurementExists(_procurementId)
```

**Parameters:**
- `_procurementId` (uint32): Procurement to close

**Effects:**
- Sets status to CLOSED
- Does not process refunds (use `emergencyRefund` for that)

---

## Usage Examples

### Complete Procurement Flow

```javascript
// 1. Owner authorizes supplier
await contract.connect(owner).authorizeSupplier(supplierAddress);

// 2. User creates procurement
const tx1 = await contract.connect(requester).createProcurement(
    1,  // STEEL
    1000,
    85,
    "Construction steel",
    7 * 24 * 60 * 60
);
const receipt1 = await tx1.wait();
const procurementId = receipt1.events[0].args.procurementId;

// 3. Suppliers submit bids
await contract.connect(supplier1).submitBid(
    procurementId,
    50000,
    30,
    90,
    "ISO 9001",
    { value: ethers.utils.parseEther("0.01") }
);

await contract.connect(supplier2).submitBid(
    procurementId,
    48000,
    35,
    85,
    "ISO 9001, ISO 14001",
    { value: ethers.utils.parseEther("0.01") }
);

// 4. Wait for bidding period to end
await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
await ethers.provider.send("evm_mine");

// 5. Evaluate bids
await contract.connect(requester).evaluateBids(procurementId);

// 6. Gateway automatically calls back (simulated in tests)
// processAwardCallback() is called by Gateway

// 7. Check result
const info = await contract.getProcurementInfo(procurementId);
console.log(`Winner: ${info.winningSupplier}`);
console.log(`Price: ${info.winningPrice}`);
```

### Handling Timeout

```javascript
// If Gateway doesn't callback within 2 hours
const status = await contract.getDecryptionStatus(procurementId);
if (status.timedOut) {
    await contract.handleDecryptionTimeout(procurementId);
    console.log("All suppliers refunded due to timeout");
}
```

---

## Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| "Not authorized" | Caller is not owner | Call from owner account |
| "Not authorized supplier" | Caller not in authorized list | Get authorization first |
| "Invalid procurement ID" | Procurement doesn't exist | Check procurement ID |
| "Not during bidding period" | Outside bid window | Wait for or check timing |
| "Bid already submitted" | Supplier already bid | Cannot bid twice |
| "Procurement not open" | Wrong status | Check procurement status |
| "Quality score must be 0-100" | Invalid quality value | Use 0-100 range |
| "Insufficient bid deposit" | Deposit < 0.01 ETH | Send at least 0.01 ETH |
| "Bidding period not ended" | Trying to evaluate early | Wait for end time |
| "Already evaluated" | Evaluation already started | Check status |
| "Invalid request ID" | Unknown callback request | Gateway issue |
| "Timeout not reached" | Trying to trigger timeout early | Wait 2 hours |

---

## Constants Reference

| Constant | Value | Description |
|----------|-------|-------------|
| PROCUREMENT_DURATION | 7 days | Default procurement duration |
| DECRYPTION_TIMEOUT | 2 hours | Gateway callback timeout |
| MAX_PROCUREMENT_DURATION | 90 days | Maximum allowed duration |
| MIN_RANDOM_MULTIPLIER | 1000 | Privacy multiplier minimum |
| MAX_RANDOM_MULTIPLIER | 10000 | Privacy multiplier maximum |

---

## Security Best Practices

1. **Always authorize suppliers before they can bid**
2. **Monitor decryption status and handle timeouts**
3. **Verify events for audit trail**
4. **Use appropriate bid deposits to discourage spam**
5. **Keep specifications detailed and clear**
6. **Monitor Gateway uptime before evaluating**
7. **Have emergency refund procedures ready**

---

## Support & Resources

- **Architecture Documentation**: See `ARCHITECTURE.md`
- **Test Suite**: See `test/` directory
- **fhEVM Documentation**: https://docs.zama.ai/fhevm
- **Gateway Integration**: Contact Zama support
