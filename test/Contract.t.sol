// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/TicketFactory.sol";

// contract TicketFactoryTest is Test {
//     TicketFactory ticketFactory;

//     address airline = address(0xABCD);
//     address user = address(0x1234);

//     function setUp() public {
//         // Deploy the TicketFactory contract
//         ticketFactory = new TicketFactory();

//         // Register an airline
//         vm.prank(airline);
//         ticketFactory.registerAirline(airline, "AirlineName", "AA", "ipfs://metadataURI");
//     }

//     function testCreateFlight() public {
//         vm.prank(airline);
//         uint256 flightID = ticketFactory.createFlight(
//             "FL123",
//             "Cairo",
//             "Dubai",
//             block.timestamp + 1 days,
//             3,
//             new uint256 , // Example seat numbers
//             block.timestamp + 2 days
//         );

//         // Verify flight details
//         (string memory flightNumber, address airlineAddress, , string memory departure, , , , , bool isActive, ) = ticketFactory.flights(flightID);
//         assertEq(flightNumber, "FL123");
//         assertEq(airlineAddress, airline);
//         assertEq(departure, "Cairo");
//         assertEq(isActive, true);
//     }

//     function testPurchaseTicket() public {
//         // Create a flight
//         vm.prank(airline);
//         uint256 flightID = ticketFactory.createFlight(
//             "FL123",
//             "Cairo",
//             "Dubai",
//             block.timestamp + 1 days,
//             3,
//             new uint256 ,
//             block.timestamp + 2 days
//         );

//         // Purchase a ticket
//         bytes32 hashedUserInfo = keccak256(abi.encodePacked("User Info"));
//         vm.prank(user);
//         ticketFactory.purchaseTicket{value: 1 ether}(flightID, 0, hashedUserInfo);

//         // Verify ticket details
//         (uint256 ticketID, uint256 ticketFlightID, uint256 seatNumber, uint256 price, bool isAvailable, bool isUsed) = ticketFactory.flightTickets(flightID, 0);
//         assertEq(ticketID, 0);
//         assertEq(ticketFlightID, flightID);
//         assertEq(seatNumber, 0);
//         assertEq(isAvailable, false);
//         assertEq(isUsed, false);
//     }

//     function testModifyTicket() public {
//         // Create flights
//         vm.prank(airline);
//         uint256 flightID1 = ticketFactory.createFlight(
//             "FL123",
//             "Cairo",
//             "Dubai",
//             block.timestamp + 1 days,
//             3,
//             new uint256 ,
//             block.timestamp + 2 days
//         );

//         vm.prank(airline);
//         uint256 flightID2 = ticketFactory.createFlight(
//             "FL456",
//             "Dubai",
//             "London",
//             block.timestamp + 2 days,
//             3,
//             new uint256 ,
//             block.timestamp + 3 days
//         );

//         // Purchase a ticket for flight 1
//         bytes32 hashedUserInfo = keccak256(abi.encodePacked("User Info"));
//         vm.prank(user);
//         ticketFactory.purchaseTicket{value: 1 ether}(flightID1, 0, hashedUserInfo);

//         // Modify the ticket to flight 2
//         vm.prank(user);
//         ticketFactory.modifyTicket{value: 1 ether}(0, flightID2, 1);

//         // Verify modified ticket details
//         (uint256 ticketID, uint256 ticketFlightID, uint256 seatNumber, , bool isAvailable, ) = ticketFactory.flightTickets(flightID2, 1);
//         assertEq(ticketID, 0);
//         assertEq(ticketFlightID, flightID2);
//         assertEq(seatNumber, 1);
//         assertEq(isAvailable, false);
//     }

//     function testRevertIfNotAuthorizedAirline() public {
//         vm.expectRevert("Not an authorized airline");
//         ticketFactory.createFlight(
//             "FL999",
//             "Unknown",
//             "Nowhere",
//             block.timestamp + 1 days,
//             2,
//             new uint256 ,
//             block.timestamp + 2 days
//         );
//     }

//     function testRevertIfPurchaseUnavailableTicket() public {
//         vm.prank(airline);
//         uint256 flightID = ticketFactory.createFlight(
//             "FL123",
//             "Cairo",
//             "Dubai",
//             block.timestamp + 1 days,
//             3,
//             new uint256 ,
//             block.timestamp + 2 days
//         );

//         vm.prank(user);
//         ticketFactory.purchaseTicket{value: 1 ether}(flightID, 0, keccak256(abi.encodePacked("User Info")));

//         vm.expectRevert("Ticket is not available");
//         ticketFactory.purchaseTicket{value: 1 ether}(flightID, 0, keccak256(abi.encodePacked("User Info")));
//     }
// }
