// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TicketFactory.sol";

contract TicketFactoryTest is Test {
    TicketFactory public ticketFactory;
    address public admin = address(0x123);

    address public alice = address(1);
    address public bob = address(2);
    bytes32 public constant HASHED_INFO = keccak256(abi.encodePacked("user@email.com"));

    event TicketCheckedIn(uint256 indexed tokenId, uint256 indexed flightId, string seat, address indexed user, bytes32 hashedInfo, address checkedInBy);
    event TicketTransferred(uint256 indexed tokenId, uint256 indexed flightId, string seat, address indexed from, address to, bytes32 hashedInfo);

    function setUp() public {
        ticketFactory = new TicketFactory();
        ticketFactory.setAdmin(admin);

    }

    /* PurchaseExternalTicket Tests */
    // function testPurchaseExternalCreatesNewFlight() public {
    //     vm.prank(alice);
    //     uint256 tokenId = ticketFactory.purchaseExternalTicket(
    //         "FL123", "JFK", "LAX", 1680000000, 1680003600, 100, HASHED_INFO
    //     );

    //     // Verify flight creation
    //     (,,,,,,,uint256 totalTickets, uint256 availableTickets,,,) = ticketFactory.flights(1);
    //     assertEq(totalTickets, 100);
    //     assertEq(availableTickets, 99);
        
    //     // Verify ticket minting
    //     assertEq(ticketFactory.ownerOf(tokenId), alice);
    // }

    // function testPurchaseExternalExistingFlight() public {
    //     // First purchase creates flight
    //     ticketFactory.purchaseExternalTicket(
    //         "FL123", "JFK", "LAX", 1680000000, 1680003600, 100, HASHED_INFO
    //     );

    //     // Second purchase uses existing flight
    //     vm.prank(bob);
    //     uint256 tokenId = ticketFactory.purchaseExternalTicket(
    //         "FL123", "JFK", "LAX", 1680000000, 1680003600, 100, HASHED_INFO
    //     );

    //     (,,,,,,,, uint256 availableTickets,,,) = ticketFactory.flights(1);
    //     assertEq(availableTickets, 98);
    //     assertEq(ticketFactory.ownerOf(tokenId), bob);
    // }

    /* CheckInTicket Tests */
    // function testCheckInTicket() public {
    //     uint256 tokenId = _mintTicket(alice);
        
    //     vm.prank(alice);
    //     ticketFactory.checkInTicket(tokenId, "A12");
    //     // emit TicketCheckedIn(tokenId, 1, "A12", alice, HASHED_INFO, alice);

        
    //     // Verify check-in through event
    //     vm.expectEmit(true, true, true, true);
    // }

    // function testCheckInTwiceFails() public {
    //     uint256 tokenId = _mintTicket(alice);
        
    //     vm.prank(alice);
    //     ticketFactory.checkInTicket(tokenId, "A12");

    //     vm.expectRevert();
    //     vm.prank(alice);
    //     ticketFactory.checkInTicket(tokenId, "B34");
    // }

    /* ModifyTicket Tests */
    // function testModifyCreatesNewFlight() public {
    //     uint256 tokenId = _mintTicket(alice);
        
    //     vm.prank(alice);
    //     ticketFactory.modifyTicket(
    //         tokenId, 
    //         "FL456", "SFO", "ORD", 1680000000, 1680003600, 200, 0
    //     );

    //     // Verify new flight creation
    //     (,,,,,,uint256 totalTickets,,,,,) = ticketFactory.flights(2);
    //     assertEq(totalTickets, 200);
    // }

    // function testModifyUpdatesAvailability() public {
    //     uint256 tokenId = _mintTicket(alice);
    //     uint256 originalFlight = 1;
        
    //     vm.prank(alice);
    //     ticketFactory.modifyTicket(
    //         tokenId, 
    //         "FL456", "SFO", "ORD", 1680000000, 1680003600, 200, 0
    //     );

    //     (,,,,,,, uint256 originalAvail,,,,) = ticketFactory.flights(originalFlight);
    //     (,,,,,,, uint256 newAvail,,,,) = ticketFactory.flights(2);
    //     assertEq(originalAvail, 100); // Original flight regains ticket
    //     assertEq(newAvail, 199);      // New flight loses ticket
    // }

    /* TransferTicket Tests */
    function testAdminCanTransferTokens() public {
        // Admin mints a token to Alice
        vm.prank(admin);
        uint256 tokenId = ticketFactory.purchaseExternalTicket("FL123", "JFK", "LAX", "1680000000", "2025", 100, HASHED_INFO, alice);

        // Admin transfers the token from Alice to Bob
        vm.prank(admin);
        ticketFactory.transferTicket(alice, tokenId, bob, HASHED_INFO);

        // Check if Bob is the new owner of the token
        assertEq(ticketFactory.ownerOf(tokenId), bob);

        // Verify transfer through event
        // vm.expectEmit(true, true, true, true);
        emit TicketTransferred(tokenId, 1, "", alice, bob, HASHED_INFO);
    }

    // function testTransferNonOwnerFails() public {
    //     uint256 tokenId = _mintTicket(alice);
        
    //     vm.expectRevert();
    //     vm.prank(bob);
    //     ticketFactory.transferTicket(tokenId, bob, HASHED_INFO);
    // }

    /* Helper Functions */
    // function _mintTicket(address user) internal returns (uint256) {
    //     vm.prank(user);
    //     return ticketFactory.purchaseExternalTicket(
    //         "FL123", "JFK", "LAX", 1680000000, 1680003600, 100, HASHED_INFO
    //     );
    // }
}