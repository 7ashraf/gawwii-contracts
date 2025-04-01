// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TicketFactory.sol";
contract Marketplace {
    uint256 ticketCounter = 0;
    uint256 flightCounter = 0;   // Counter for flight IDs

    struct Listing {
        address seller;
        uint256 price;
    }

    struct Ticket {
        uint256 ticketID;
        uint256 flightID;
        string seatNumber;
        //string classType;
        uint256 price;
        bool isAvailable;
        bool isUsed;
        //note should add reference to ticket metadata, and flight metadata

    }

    struct TicketMetadata {
        uint256 ticketId;
        bool isUsed;
        uint256 flightID;
        string seatNumber;
        uint256 price;
        // string classType;
        //string departureLocation;
        //string arrivalLocation;
        bytes32 hashedUserInfo;
        mapping(address => bool) checkedIn;


    }

    struct Flight{

        string flightNumber;
        address airlineAddress; // Reference to the airline in the registry
        uint256 flightID;
        string departure;
        string destination;
        uint256 departureTime;
        uint256 arrivalTime;
        uint256 totalTickets; // Total number of tickets available
        uint256 availableTickets;
        bool isActive;
        bool shared;
        //should add reference to flight metadata

    }

    mapping(address => mapping(uint256 => Listing)) public listings;  // tokenAddress => tokenId => Listing
    mapping(uint256 => address) public ticketOwners; // Track ticket ownership
    mapping(uint256 => Flight) public flights;  // ticketId => Flight
    mapping(uint256 => mapping(uint256 => Ticket)) public flightTickets;
    mapping(uint256 => TicketMetadata) public ticketMetadata; // Track user-added metadata

    event TicketListed(address indexed seller, address indexed tokenAddress, uint256 indexed tokenId, uint256 price);
    event TicketSold(address indexed buyer, address indexed tokenAddress, uint256 indexed tokenId, uint256 price);
    event TicketDelisted(address indexed seller, address indexed tokenAddress, uint256 indexed tokenId);
    event TicketPurchased(uint256 indexed flightID, uint256 indexed ticketID, address indexed buyer);

    // List a ticket for resale
    function listTicketForResale(address tokenAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721Enumerable tokenContract = IERC721Enumerable(tokenAddress);

        // Ensure the sender owns the ticket
        //require(tokenContract.ownerOf(tokenId) == msg.sender, "Only owner can list");

        // Approve the marketplace to transfer the token
        require(tokenContract.getApproved(tokenId) == address(this), "Approve marketplace to transfer");

        listings[tokenAddress][tokenId] = Listing(msg.sender, price);
        emit TicketListed(msg.sender, tokenAddress, tokenId, price);
    }

    // Buy a listed ticket
    function buyTicket(address tokenAddress, uint256 tokenId) external payable {
        Listing storage listing = listings[tokenAddress][tokenId];
        require(listing.price > 0, "Ticket not listed for sale");
        
        require(msg.value == listing.price, "Incorrect price");

        // Transfer payment to the seller
        payable(listing.seller).transfer(msg.value);

        // Transfer the ticket to the buyer
        IERC721Enumerable(tokenAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit TicketSold(msg.sender, tokenAddress, tokenId, listing.price);
        delete listings[tokenAddress][tokenId];
    }

        //note instead of taking the ticket id is passed because tickets exist before minting
        //note I think ticket id is redundunt, user does not all tickets, all tickets are resmebled by a single ticket which represents a flight 
    // function purchaseTicket(
    //     uint256 flightID,
    //     uint256 ticketID,
    //     bytes32 hashedUserInfo
    // ) external payable {
        
    //     Ticket storage ticket = flightTickets[flightID][ticketID];

    //     require(ticket.isAvailable, "Ticket is not available");
    //     require(msg.value == ticket.price, "Incorrect price");

    //     // Mint NFT by transferring ownership to buyer
    //     ticketOwners[ticketID] = msg.sender;
    //     // Mint NFT by assigning a unique token ID to the buyer
    //     uint256 tokenId = ticketCounter;
    //     //_safeMint(msg.sender, tokenId);
    //     ticketCounter++; // Increment token ID for the next mint

        

    //     // Store user metadata on-chain with ticket metadata
    //     TicketMetadata storage ticketMetadata = ticketMetadata[ticketID];
    //     ticketMetadata.ticketId = tokenId;
    //     ticketMetadata.hashedUserInfo = hashedUserInfo;
    //     ticketMetadata.flightID = flightID;
    //     ticketMetadata.seatNumber = ticket.seatNumber;
    //     ticketMetadata.price = ticket.price;
    //     ticketMetadata.isUsed = false;
    //     // ticketMetadata.classType = ticket.classType;
    //     // ticketMetadata.departureLocation = flights[flightID].departure;
    //     // ticketMetadata.arrivalLocation = flights[flightID].destination;
    //     ticketMetadata.checkedIn[msg.sender] = true;



    //     // ticketMetadata[ticketID] = TicketMetadata({

    //     //     isUsed: false,
    //     //     flightID: flightID,
    //     //     hashedUserInfo: hashedUserInfo,
    //     //     seatNumber: ticket.seatNumber
            
    //     //     //classType: ticket.classType
    //     // });

    //     // Mark ticket as unavailable
    //     ticket.isAvailable = false;
    //     flights[flightID].availableTickets -= 1;

    //     // Emit an event for ticket purchase
    //     emit TicketPurchased(flightID, ticketID, msg.sender);
    // }


    // Delist a ticket from resale
    function delistTicket(address tokenAddress, uint256 tokenId) external {
        Listing storage listing = listings[tokenAddress][tokenId];
        require(listing.seller == msg.sender, "Only seller can delist");

        emit TicketDelisted(msg.sender, tokenAddress, tokenId);
        delete listings[tokenAddress][tokenId];
    }

    // View listing details
    function getListing(address tokenAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[tokenAddress][tokenId];
    }
}
