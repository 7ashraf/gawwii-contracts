// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketFactory is ERC721 {
    uint256 public ticketCounter;
    uint256 public flightCounter;   // Counter for flight IDs



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


    struct Airline {
        string name;
        string iataCode; // IATA code for the airline (e.g., "AA" for American Airlines)
        string metadataURI; // URI to off-chain metadata (e.g., logo, profile info, etc.)
        address airlineAddress;
        bool isAuthorized;
    }




    // struct TicketTemplate {
    //     address company;
    //     string metadataURI;
    //     uint256 price;
    //     bool isMintable;
    //     uint256 flightId;

    // }

    struct Ticket {
        uint256 ticketID;
        uint256 flightID;
        uint256 seatNumber;
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
        uint256 seatNumber;
        uint256 price;
        // string classType;
        //string departureLocation;
        //string arrivalLocation;
        bytes32 hashedUserInfo;
        mapping(address => bool) checkedIn;


    }


    mapping(uint256 => Flight) public flights;  // ticketId => Flight
    //mapping(uint256 => TicketTemplate) public ticketTemplates;  // ticketId => TicketTemplate
    mapping(uint256 => bool) public ticketMinted;  // Tracks if a ticket has been minted
    mapping(address => Airline) public airlines;
    mapping(uint256 => string) private _tokenURIs;
    //mapping(uint256 => TicketMetadata) public ticketData;
    mapping(uint256 => mapping(uint256 => Ticket)) public flightTickets;
    mapping(uint256 => address) public ticketOwners; // Track ticket ownership
    mapping(uint256 => TicketMetadata) public ticketMetadata; // Track user-added metadata




    //event TemplateCreated(address indexed company, uint256 indexed templateId, string metadataURI, uint256 price);
    //event TicketMinted(address indexed buyer, uint256 indexed ticketId);
    event FlightCreated(uint256 indexed flightId, string flightNumber, string departure, string destination, uint256 date);
    event TicketPurchased(uint256 indexed flightID, uint256 indexed ticketID, address indexed buyer);
    event TicketModified(
        uint256 indexed tokenId,
        uint256 oldFlightID,
        uint256 oldSeatNumber,
        uint256 newFlightID,
        uint256 newSeatNumber,
        address indexed user
    );

        constructor() ERC721("AviationTicket", "AVT") {
        ticketCounter = 0;
    }

    modifier onlyAuthorized() {
        //require(msg.sender == owner() || msg.sender == address(this), "Not authorized");
        _;
    }

    modifier onlyAuthorizedAirline() {
        require(airlines[msg.sender].isAuthorized, "Not an authorized airline");
        _;
    }


    function registerAirline(
    address airlineAddress,
    string memory name,
    string memory iataCode,
    string memory metadataURI
) external {
    airlines[airlineAddress] = Airline({
        name: name,
        iataCode: iataCode,
        metadataURI: metadataURI,
        airlineAddress: airlineAddress,
        isAuthorized: true
    });
}




    // Create a new flight
    function createFlight(
        string memory flightNumber,
        string memory departure,
        string memory destination,
        uint256 date,
        uint256 numberOfTickets,
        uint256[] memory seatNumbers,
        // string[] memory classTypes,
        uint256 arrivalTime
    ) external returns (uint256) {
        
        flightCounter++;
        uint256 flightID = flightCounter;

        flights[flightID] = Flight({
            flightID: flightID,
            airlineAddress: msg.sender,
            flightNumber: flightNumber,
            departure: departure,
            destination: destination,
            departureTime: date,
            totalTickets: numberOfTickets,
            availableTickets: numberOfTickets,
            arrivalTime: arrivalTime, 
            isActive: true,
            shared: true
                     
        });

        // Initialize tickets
        for (uint256 i = 0; i < numberOfTickets; i++) {

            flightTickets[flightID][i] = Ticket({

                ticketID: i,//note can be set to a unique value so it is used as a token id also
                flightID: flightID,
                seatNumber: seatNumbers[i],
                //classType: classTypes[i],
                price: 1,
                isAvailable: true,
                isUsed: false


            });
            
        }

        emit FlightCreated(flightCounter, flightNumber, departure, destination, date);
        return flightCounter;
    }

    // Create a new ticket template
    // function createTicketTemplate(uint256 flightId, string memory metadataURI, uint256 price) external onlyAuthorized returns (uint256) {
    //     ticketCounter += 1;
    //     uint256 newTemplateId = ticketCounter;

    //     ticketTemplates[newTemplateId] = TicketTemplate({
    //         flightId: flightId,
    //         company: msg.sender,
    //         metadataURI: metadataURI,
    //         price: price,
    //         isMintable: true
    //     });

    //     emit TemplateCreated(msg.sender, newTemplateId, metadataURI, price);
    //     return newTemplateId;
    // }

    // Mint a ticket on-demand
    // function mintTicket(uint256 templateId) external payable {
    //     require(ticketTemplates[templateId].isMintable, "Ticket not available for minting");
    //     require(msg.value == ticketTemplates[templateId].price, "Incorrect payment amount");
    //     require(!ticketMinted[templateId], "Ticket already minted");

    //     ticketMinted[templateId] = true;
    //     _mint(msg.sender, templateId);

    //     payable(ticketTemplates[templateId].company).transfer(msg.value);  // Transfer funds to the company

    //     emit TicketMinted(msg.sender, templateId);
    // }

    // note instead of taking the ticket id is passed because tickets exist before minting
    function purchaseTicket(
        uint256 flightID,
        uint256 seatNumber,
        bytes32 hashedUserInfo
    ) external payable {
        //note should be a struct for tickets listed, that is different from the tickets that are minted
        
        Ticket storage ticket = flightTickets[flightID][seatNumber];

        require(ticket.isAvailable, "Ticket is not available");
        require(msg.value == ticket.price, "Incorrect price");

        // Mint NFT by transferring ownership to buyer
        // Mint NFT by assigning a unique token ID to the buyer
        uint256 tokenId = ticketCounter;
        _safeMint(msg.sender, tokenId);
        ticketCounter++; // Increment token ID for the next mint

        ticketOwners[tokenId] = msg.sender;


        

        // Store user metadata on-chain with ticket metadata
        TicketMetadata storage ticketMetadata = ticketMetadata[tokenId];
        ticketMetadata.ticketId = tokenId;
        ticketMetadata.hashedUserInfo = hashedUserInfo;
        ticketMetadata.flightID = flightID;
        ticketMetadata.seatNumber = seatNumber;
        ticketMetadata.price = ticket.price;
        ticketMetadata.isUsed = false;
        // ticketMetadata.classType = ticket.classType;
        ticketMetadata.checkedIn[msg.sender] = true;



        // ticketMetadata[ticketID] = TicketMetadata({

        //     isUsed: false,
        //     flightID: flightID,
        //     hashedUserInfo: hashedUserInfo,
        //     seatNumber: ticket.seatNumber
            
        //     //classType: ticket.classType
        // });

        // Mark ticket as unavailable
        ticket.isAvailable = false;
        flights[flightID].availableTickets -= 1;

        // Emit an event for ticket purchase
        emit TicketPurchased(flightID, tokenId, msg.sender);
    }

    function updateAirlineMetadata(
        address airlineAddress,
        string memory newMetadataURI
    ) external  {
        require(airlines[airlineAddress].isAuthorized, "Airline not authorized");
        airlines[airlineAddress].metadataURI = newMetadataURI;
    }


    function modifyTicket(
        uint256 oldTokenId,
        uint256 newFlightID,
        uint256 newSeatNumber
    ) external payable {
        // Verify ownership of the ticket
        require(ticketOwners[oldTokenId] == msg.sender, "You do not own this ticket");

        // Retrieve the current ticket metadata
        TicketMetadata storage ticketMetadata = ticketMetadata[oldTokenId];
        uint256 oldFlightID = ticketMetadata.flightID;
        uint256 oldSeatNumber = ticketMetadata.seatNumber;

        // Ensure the new flight and seat are available
        Ticket storage newTicket = flightTickets[newFlightID][newSeatNumber];
        require(newTicket.isAvailable, "The new seat is not available");
        require(newTicket.price == msg.value, "Incorrect payment for the new seat");

        // Refund difference if applicable (if old ticket is more expensive)
        Ticket storage oldTicket = flightTickets[oldFlightID][oldSeatNumber];
        if (oldTicket.price > newTicket.price) {
            payable(msg.sender).transfer(oldTicket.price - newTicket.price);
        }

        // Charge extra if applicable (if new ticket is more expensive)
        if (newTicket.price > oldTicket.price) {
            require(msg.value >= newTicket.price - oldTicket.price, "Insufficient payment for new ticket");
        }

        // Update the old seat availability
        oldTicket.isAvailable = true;
        flights[oldFlightID].availableTickets += 1;

        // Update the new seat availability
        newTicket.isAvailable = false;
        flights[newFlightID].availableTickets -= 1;

        // Update ticket metadata
        ticketMetadata.flightID = newFlightID;
        ticketMetadata.seatNumber = newSeatNumber;
        ticketMetadata.price = newTicket.price;

        // Emit an event for ticket modification
        emit TicketModified(oldTokenId, oldFlightID, oldSeatNumber, newFlightID, newSeatNumber, msg.sender);
    }



    // check in airling into a flight
    
}




//todo revocation system
//todo authorization and modifiers