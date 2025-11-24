// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import { Test } from "forge-std/Test.sol";
import { EnhancedBuildingMaterialProcurement } from "../contracts/EnhancedBuildingMaterialProcurement.sol";

/**
 * @title Test Suite for Enhanced Building Material Procurement
 * @notice Comprehensive tests covering all functionality including Gateway callbacks, refunds, and privacy features
 */
contract EnhancedProcurementTest is Test {
    EnhancedBuildingMaterialProcurement public procurement;

    address public owner;
    address public requester;
    address public supplier1;
    address public supplier2;
    address public supplier3;

    uint256 constant BID_DEPOSIT = 0.01 ether;
    uint256 constant PROCUREMENT_DURATION = 7 days;

    event ProcurementCreated(
        uint32 indexed procurementId,
        EnhancedBuildingMaterialProcurement.MaterialType indexed materialType,
        address indexed requester,
        uint256 deadline
    );

    event BidSubmitted(
        uint32 indexed procurementId,
        address indexed supplier,
        uint256 timestamp,
        uint256 deposit
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

    function setUp() public {
        owner = address(this);
        requester = makeAddr("requester");
        supplier1 = makeAddr("supplier1");
        supplier2 = makeAddr("supplier2");
        supplier3 = makeAddr("supplier3");

        // Fund accounts
        vm.deal(requester, 100 ether);
        vm.deal(supplier1, 100 ether);
        vm.deal(supplier2, 100 ether);
        vm.deal(supplier3, 100 ether);

        procurement = new EnhancedBuildingMaterialProcurement();
    }

    // ==================== Authorization Tests ====================

    function testAuthorizeSupplier() public {
        vm.expectEmit(true, false, false, false);
        emit EnhancedBuildingMaterialProcurement.SupplierAuthorized(supplier1);

        procurement.authorizeSupplier(supplier1);

        assertTrue(procurement.isSupplierAuthorized(supplier1));
        assertEq(procurement.getSupplierReputation(supplier1), 50);
    }

    function testCannotAuthorizeZeroAddress() public {
        vm.expectRevert("Invalid supplier address");
        procurement.authorizeSupplier(address(0));
    }

    function testCannotAuthorizeTwice() public {
        procurement.authorizeSupplier(supplier1);

        vm.expectRevert("Supplier already authorized");
        procurement.authorizeSupplier(supplier1);
    }

    function testOnlyOwnerCanAuthorize() public {
        vm.prank(supplier1);
        vm.expectRevert("Not authorized");
        procurement.authorizeSupplier(supplier2);
    }

    // ==================== Procurement Creation Tests ====================

    function testCreateProcurement() public {
        vm.startPrank(requester);

        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "High-grade construction steel",
            0
        );

        assertEq(procurementId, 1);

        (
            EnhancedBuildingMaterialProcurement.MaterialType materialType,
            string memory specs,
            EnhancedBuildingMaterialProcurement.ProcurementStatus status,
            address req,
            uint256 startTime,
            uint256 endTime,
            ,,,
        ) = procurement.getProcurementInfo(procurementId);

        assertEq(uint(materialType), uint(EnhancedBuildingMaterialProcurement.MaterialType.STEEL));
        assertEq(specs, "High-grade construction steel");
        assertEq(uint(status), uint(EnhancedBuildingMaterialProcurement.ProcurementStatus.OPEN));
        assertEq(req, requester);
        assertEq(endTime - startTime, PROCUREMENT_DURATION);

        vm.stopPrank();
    }

    function testCannotCreateWithZeroQuantity() public {
        vm.prank(requester);
        vm.expectRevert("Quantity must be positive");
        procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.CEMENT,
            0,
            50,
            "Test",
            0
        );
    }

    function testCannotCreateWithInvalidQuality() public {
        vm.prank(requester);
        vm.expectRevert("Quality grade must be 1-100");
        procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.CEMENT,
            100,
            0,
            "Test",
            0
        );

        vm.prank(requester);
        vm.expectRevert("Quality grade must be 1-100");
        procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.CEMENT,
            100,
            101,
            "Test",
            0
        );
    }

    function testCannotCreateWithEmptySpecifications() public {
        vm.prank(requester);
        vm.expectRevert("Specifications required");
        procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.CEMENT,
            100,
            50,
            "",
            0
        );
    }

    function testCustomDuration() public {
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            14 days
        );

        (,,,, uint256 startTime, uint256 endTime,,,,) = procurement.getProcurementInfo(procurementId);
        assertEq(endTime - startTime, 14 days);
    }

    // ==================== Bid Submission Tests ====================

    function testSubmitBid() public {
        // Setup
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        // Submit bid
        vm.prank(supplier1);
        vm.expectEmit(true, true, false, false);
        emit BidSubmitted(procurementId, supplier1, block.timestamp, BID_DEPOSIT);

        procurement.submitBid{value: BID_DEPOSIT}(
            procurementId,
            50000,
            30,
            90,
            "ISO 9001"
        );

        // Verify bid status
        (
            bool hasSubmitted,
            uint256 timestamp,
            string memory certs,
            uint256 deposit,
            bool refunded
        ) = procurement.getSupplierBidStatus(procurementId, supplier1);

        assertTrue(hasSubmitted);
        assertGt(timestamp, 0);
        assertEq(certs, "ISO 9001");
        assertEq(deposit, BID_DEPOSIT);
        assertFalse(refunded);
    }

    function testCannotBidWithoutAuthorization() public {
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.prank(supplier1);
        vm.expectRevert("Not authorized supplier");
        procurement.submitBid{value: BID_DEPOSIT}(
            procurementId,
            50000,
            30,
            90,
            "ISO 9001"
        );
    }

    function testCannotBidTwice() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.startPrank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.expectRevert("Bid already submitted");
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 45000, 25, 95, "ISO 9001");
        vm.stopPrank();
    }

    function testCannotBidWithInsufficientDeposit() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.prank(supplier1);
        vm.expectRevert("Insufficient bid deposit");
        procurement.submitBid{value: 0.001 ether}(procurementId, 50000, 30, 90, "ISO 9001");
    }

    function testCannotBidAfterDeadline() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        // Fast forward past deadline
        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);

        vm.prank(supplier1);
        vm.expectRevert("Not during bidding period");
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");
    }

    // ==================== Evaluation Tests ====================

    function testEvaluateBids() public {
        // Setup procurement with multiple bids
        procurement.authorizeSupplier(supplier1);
        procurement.authorizeSupplier(supplier2);

        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        // Submit bids
        vm.prank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.prank(supplier2);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 48000, 35, 85, "ISO 9001");

        // Fast forward past deadline
        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);

        // Evaluate
        vm.prank(requester);
        procurement.evaluateBids(procurementId);

        (,, EnhancedBuildingMaterialProcurement.ProcurementStatus status,,,,,,,) =
            procurement.getProcurementInfo(procurementId);

        assertEq(uint(status), uint(EnhancedBuildingMaterialProcurement.ProcurementStatus.DECRYPTION_REQUESTED));
    }

    function testCannotEvaluateBeforeDeadline() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.prank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.prank(requester);
        vm.expectRevert("Bidding period not ended");
        procurement.evaluateBids(procurementId);
    }

    function testOnlyRequesterOrOwnerCanEvaluate() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);

        vm.prank(supplier1);
        vm.expectRevert("Not authorized to evaluate");
        procurement.evaluateBids(procurementId);
    }

    // ==================== Timeout & Refund Tests ====================

    function testDecryptionTimeout() public {
        // Setup and evaluate
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.prank(supplier1);
        uint256 initialBalance = supplier1.balance;
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);
        vm.prank(requester);
        procurement.evaluateBids(procurementId);

        // Fast forward past decryption timeout
        vm.warp(block.timestamp + 2 hours + 1);

        // Trigger timeout refund
        procurement.handleDecryptionTimeout(procurementId);

        (,, EnhancedBuildingMaterialProcurement.ProcurementStatus status,,,,,,,) =
            procurement.getProcurementInfo(procurementId);

        assertEq(uint(status), uint(EnhancedBuildingMaterialProcurement.ProcurementStatus.DECRYPTION_FAILED));

        // Verify refund
        (,,,, bool refunded) = procurement.getSupplierBidStatus(procurementId, supplier1);
        assertTrue(refunded);
        assertEq(supplier1.balance, initialBalance);
    }

    function testCannotTriggerTimeoutEarly() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        vm.prank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);
        vm.prank(requester);
        procurement.evaluateBids(procurementId);

        // Try to trigger timeout too early
        vm.warp(block.timestamp + 1 hours);
        vm.expectRevert("Timeout not reached");
        procurement.handleDecryptionTimeout(procurementId);
    }

    function testEmergencyRefund() public {
        // Setup
        procurement.authorizeSupplier(supplier1);
        procurement.authorizeSupplier(supplier2);

        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        uint256 balance1 = supplier1.balance;
        uint256 balance2 = supplier2.balance;

        vm.prank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.prank(supplier2);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 48000, 35, 85, "ISO 9001");

        // Emergency refund
        procurement.emergencyRefund(procurementId, "Technical issue");

        // Verify status and refunds
        (,, EnhancedBuildingMaterialProcurement.ProcurementStatus status,,,,,,,) =
            procurement.getProcurementInfo(procurementId);

        assertEq(uint(status), uint(EnhancedBuildingMaterialProcurement.ProcurementStatus.REFUNDED));
        assertEq(supplier1.balance, balance1);
        assertEq(supplier2.balance, balance2);
    }

    // ==================== View Function Tests ====================

    function testGetActiveProcurements() public {
        vm.startPrank(requester);

        procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test 1",
            0
        );

        procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.CEMENT,
            500,
            70,
            "Test 2",
            0
        );

        vm.stopPrank();

        uint32[] memory active = procurement.getActiveProcurements();
        assertEq(active.length, 2);
        assertEq(active[0], 1);
        assertEq(active[1], 2);
    }

    function testGetDecryptionStatus() public {
        procurement.authorizeSupplier(supplier1);
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        (bool requested,,,) = procurement.getDecryptionStatus(procurementId);
        assertFalse(requested);

        // Submit bid and evaluate
        vm.prank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);
        vm.prank(requester);
        procurement.evaluateBids(procurementId);

        (requested,, uint256 requestTime, bool timedOut) = procurement.getDecryptionStatus(procurementId);
        assertTrue(requested);
        assertGt(requestTime, 0);
        assertFalse(timedOut);
    }

    function testEstimateHCUCost() public view {
        uint256 cost5 = procurement.estimateHCUCost(5);
        uint256 cost10 = procurement.estimateHCUCost(10);

        assertGt(cost10, cost5);
        assertEq(cost5, (5 * 100) + (4 * 200) + 500); // 500 + 800 + 500 = 1800
    }

    // ==================== Admin Function Tests ====================

    function testUpdateSupplierReputation() public {
        procurement.authorizeSupplier(supplier1);

        procurement.updateSupplierReputation(supplier1, 75);
        assertEq(procurement.getSupplierReputation(supplier1), 75);
    }

    function testCannotUpdateUnauthorizedSupplier() public {
        vm.expectRevert("Supplier not authorized");
        procurement.updateSupplierReputation(supplier1, 75);
    }

    function testEmergencyClose() public {
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "Test",
            0
        );

        procurement.emergencyCloseProcurement(procurementId);

        (,, EnhancedBuildingMaterialProcurement.ProcurementStatus status,,,,,,,) =
            procurement.getProcurementInfo(procurementId);

        assertEq(uint(status), uint(EnhancedBuildingMaterialProcurement.ProcurementStatus.CLOSED));
    }

    // ==================== Integration Tests ====================

    function testFullProcurementFlow() public {
        // 1. Authorize suppliers
        procurement.authorizeSupplier(supplier1);
        procurement.authorizeSupplier(supplier2);

        // 2. Create procurement
        vm.prank(requester);
        uint32 procurementId = procurement.createProcurement(
            EnhancedBuildingMaterialProcurement.MaterialType.STEEL,
            1000,
            85,
            "High-grade steel",
            0
        );

        // 3. Submit bids
        vm.prank(supplier1);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 50000, 30, 90, "ISO 9001");

        vm.prank(supplier2);
        procurement.submitBid{value: BID_DEPOSIT}(procurementId, 48000, 35, 85, "ISO 14001");

        // 4. Wait for deadline
        vm.warp(block.timestamp + PROCUREMENT_DURATION + 1);

        // 5. Evaluate
        vm.prank(requester);
        procurement.evaluateBids(procurementId);

        // Verify decryption requested
        (bool requested,,,) = procurement.getDecryptionStatus(procurementId);
        assertTrue(requested);
    }

    receive() external payable {}
}
