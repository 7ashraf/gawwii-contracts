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
        bool isExternal;
        //should add reference to flight metadata

    }


    struct Airline {
        string name;
        string iataCode; // IATA code for the airline (e.g., "AA" for American Airlines)
        string metadataURI; // URI to off-chain metadata (e.g., logo, profile info, etc.)
        address airlineAddress;
        bool isAuthorized;
    }


    struct Ticket {
        uint256 ticketID;
        uint256 flightID;
        uint256 price;
        string class;

    }

    struct TicketMetadata {
        uint256 ticketId;
        bool isUsed;
        uint256 flightID;
        uint256 price;
        string classType;
        bytes32 hashedUserInfo;
        mapping(address => bool) checkedIn;
        bool isAvailable;
        string seatNumber;

    }


    mapping(uint256 => Flight) public flights;  // flightId => Flight
    //mapping(uint256 => TicketTemplate) public ticketTemplates;  // ticketId => TicketTemplate
    mapping(uint256 => bool) public ticketMinted;  // Tracks if a ticket has been minted
    mapping(address => Airline) public airlines;
    mapping(uint256 => string) private _tokenURIs;
    //mapping(uint256 => TicketMetadata) public ticketData;
    mapping(uint256 => mapping(uint256 => Ticket)) public flightTickets; //flight id => list of flight tickets => ticketId => to ticket struct
    mapping(uint256 => address) public ticketOwners; // Track ticket ownership
    mapping(uint256 => TicketMetadata) public ticketMetadata; // Track user-added metadata




    //event TemplateCreated(address indexed company, uint256 indexed templateId, string metadataURI, uint256 price);
    //event TicketMinted(address indexed buyer, uint256 indexed ticketId);
    event FlightCreated(
        uint256 indexed flightId,
        string indexed flightNumber, 
        string departure, 
        string destination, 
        uint256 date, 
        uint256 arrivalTime, 
        uint256 totalTickets, 
        uint256 availableTickets, 
        bool isActive, 
        bool shared, 
        address airlineAddress
    );
    event TicketPurchased(uint256 indexed flightID, uint256 indexed ticketID, address indexed buyer);
    
    event TicketModified(
        uint256 indexed tokenId,
        uint256 oldFlightID,
        uint256 newFlightID,
        address indexed user
    );

    event TicketCheckedIn(
        uint256 indexed ticketID,
        uint256 flightID,
        string seatNumber,
        address indexed user,
        bytes32 hashedUserInfo,
        address indexed airline

    );
    event TicketTransferred(
    uint256 indexed ticketId,
    uint256 indexed flightId,
    string seatNumber,
    address indexed from,
    address to,
    bytes32 newHashedUserInfo
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
        string[] memory seatNumbers,
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
            shared: true,
            isExternal: false
                     
        });

        // Initialize tickets
        for (uint256 i = 0; i < numberOfTickets; i++) {

            flightTickets[flightID][i] = Ticket({

                ticketID: i,//note can be set to a unique value so it is used as a token id also
                flightID: flightID,
                class: "Economy",
                price: 1


            });
            
        }

        emit FlightCreated(flightCounter, flightNumber, departure, destination, date, arrivalTime, numberOfTickets, numberOfTickets, true, true, msg.sender);
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
        uint256  seatNumber,
        bytes32 hashedUserInfo
    ) external payable {
        //note should be a struct for tickets listed, that is different from the tickets that are minted
        
        Ticket storage ticket = flightTickets[flightID][seatNumber];

        // require(ticket.isAvailable, "Ticket is not available");
        //require(msg.value == ticket.price, "Incorrect price");

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
        ticketMetadata.price = ticket.price;
        ticketMetadata.isUsed = false;
        // ticketMetadata.classType = ticket.classType;
        ticketMetadata.checkedIn[msg.sender] = false;



        // ticketMetadata[ticketID] = TicketMetadata({

        //     isUsed: false,
        //     flightID: flightID,
        //     hashedUserInfo: hashedUserInfo,
        //     seatNumber: ticket.seatNumber
            
        //     //classType: ticket.classType
        // });

        // Mark ticket as unavailable
        ticketMetadata.isAvailable = false;
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
        uint256 ticketId,
        string memory flightNumber,
        string memory departure,
        string memory destination,
        uint256 departureTime,
        uint256 arrivalTime,
        uint256 totalTickets,
        uint256 newFlightID
    ) external payable {
        // Verify ownership of the ticket
        require(ticketOwners[ticketId] == msg.sender, "You do not own this ticket");

        // Retrieve the current ticket metadata
        TicketMetadata storage ticketMetadata = ticketMetadata[ticketId];
        uint256 oldFlightID = ticketMetadata.flightID;
    uint256 flightID = findFlight(flightNumber, departure, destination, departureTime);

    if (flightID == 0) {
        // Step 2: Create flight if it doesn't exist
        flightCounter++;
        flightID = flightCounter;

        flights[flightID] = Flight({
            flightID: flightID,
            airlineAddress: msg.sender,
            flightNumber: flightNumber,
            departure: departure,
            destination: destination,
            departureTime: departureTime,
            totalTickets: totalTickets,
            availableTickets: totalTickets,
            arrivalTime: arrivalTime,
            isActive: true,
            shared: false,
            isExternal: true
        });


        emit FlightCreated(
            flightID, flightNumber, departure, destination, departureTime, 
            arrivalTime, totalTickets, totalTickets, true, false, msg.sender
        );
    } else {
        // Step 3: Handle existing flight
        Flight storage flight = flights[flightID];

        require(flight.isActive, "Flight is not active");
        // require(!flight.isExternal, "Cannot convert an inactive external flight");
    }

    // Step 4: Proceed to mint ticket for the user
    // require(ticket.isAvailable, "Ticket is not available");

    Ticket storage ticket = flightTickets[flightID][ticketId];


    // ticket.isAvailable = false;
    flights[flightID].availableTickets -= 1;

        // Update ticket metadata

        ticketMetadata.flightID = flightID;
        ticketMetadata.price = ticket.price;
        ticketMetadata.isUsed = false;
        // ticketMetadata.classType = ticket.classType;
        ticketMetadata.checkedIn[msg.sender] = false;




        // string memory oldSeatNumber = ticketMetadata.seatNumber;

        // Ensure the new flight and seat are available
        // Ticket storage newTicket = flightTickets[newFlightID][newSeatNumber];
        // require(newTicket.isAvailable, "The new seat is not available");
        // require(newTicket.price == msg.value, "Incorrect payment for the new seat");

        // Refund difference if applicable (if old ticket is more expensive)
        // // Ticket storage oldTicket = flightTickets[oldFlightID][oldSeatNumber];
        // if (oldTicket.price > newTicket.price) {
        //     payable(msg.sender).transfer(oldTicket.price - newTicket.price);
        // }

        // // Charge extra if applicable (if new ticket is more expensive)
        // if (newTicket.price > oldTicket.price) {
        //     require(msg.value >= newTicket.price - oldTicket.price, "Insufficient payment for new ticket");
        // }

        // Update the old seat availability
        
        // oldTicket.isAvailable = true;
        flights[oldFlightID].availableTickets += 1;

        // Update the new seat availability
        flights[newFlightID].availableTickets -= 1;

        // Update ticket metadata

        // Emit an event for ticket modification
        emit TicketModified(ticketId, oldFlightID, newFlightID, msg.sender);
    }



    // check in airling into a flight
    function checkInTicket(uint256 ticketId, string calldata _seatNumber) external {

        

        TicketMetadata storage ticketMetadata = ticketMetadata[ticketId];
        Ticket storage ticket = flightTickets[ticketMetadata.flightID][ticketMetadata.ticketId];
        require(ticketMetadata.isUsed == false, "Ticket has already been used");
        // require(ticket.isAvailable == true, "Ticket is not available");
        // require(ticket.isUsed == false, "Ticket has already been used");
        // require(ticketMetadata.checkedIn[msg.sender] == false, "You have already checked in");
        // Mark the ticket as used
        // ticketMetadata.isUsed = true;
        // ticket.isAvailable = false;
        // ticket.isUsed = true;
        // ticket.seatNumber = _seatNumber;
        ticketMetadata.seatNumber = _seatNumber;
        ticketMetadata.checkedIn[msg.sender] = true;

        address ticketOwner = ticketOwners[ticketId];


        // Emit an event for ticket check-in
        //emit TicketModified(ticketId, ticketMetadata.flightID, ticketMetadata.seatNumber, ticketMetadata.flightID, ticketMetadata.seatNumber, ticketOwner);

        emit TicketCheckedIn(ticketId, ticketMetadata.flightID, ticketMetadata.seatNumber, ticketOwner, ticketMetadata.hashedUserInfo, msg.sender);
    }


    function addExternalFlight(
    string memory flightNumber,
    string memory departure,
    string memory destination,
    uint256 departureTime,
    uint256 arrivalTime,
    uint256 numberOfSeats
) public onlyAuthorizedAirline returns (uint256) {
    flightCounter++;
    uint256 flightID = flightCounter;

    flights[flightID] = Flight({
        flightID: flightID,
        airlineAddress: msg.sender,
        flightNumber: flightNumber,
        departure: departure,
        destination: destination,
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        totalTickets: numberOfSeats,
        availableTickets: numberOfSeats,
        isActive: true,
        shared: true,
        isExternal: true
    });

    emit FlightCreated(
        flightID,
        flightNumber,
        departure,
        destination,
        departureTime,
        arrivalTime,
        numberOfSeats,
        numberOfSeats,
        true,
        true,
        msg.sender
    );

    return flightID;
}


function purchaseExternalTicket(
    string memory flightNumber,
    string memory departure,
    string memory destination,
    uint256 departureTime,
    uint256 arrivalTime,
    uint256 totalTickets,
    bytes32 hashedUserInfo
) external payable {
    // Step 1: Check if flight already exists
    //no need, spurce of flights is airline backend
    uint256 flightID = findFlight(flightNumber, departure, destination, departureTime);

    if (flightID == 0) {
        // Step 2: Create flight if it doesn't exist
        flightCounter++;
        flightID = flightCounter;

        flights[flightID] = Flight({
            flightID: flightID,
            airlineAddress: msg.sender,
            flightNumber: flightNumber,
            departure: departure,
            destination: destination,
            departureTime: departureTime,
            totalTickets: totalTickets,
            availableTickets: totalTickets,
            arrivalTime: arrivalTime,
            isActive: true,
            shared: false,
            isExternal: true
        });


        emit FlightCreated(
            flightID, flightNumber, departure, destination, departureTime, 
            arrivalTime, totalTickets, totalTickets, true, false, msg.sender
        );
    } else {
        // Step 3: Handle existing flight
        Flight storage flight = flights[flightID];

        require(flight.isActive, "Flight is not active");
        require(!flight.isExternal, "Cannot convert an inactive external flight");
    }

    // Step 4: Proceed to mint ticket for the user
    // require(ticket.isAvailable, "Ticket is not available");

    uint256 tokenId = ticketCounter;
    _safeMint(msg.sender, tokenId);
    ticketCounter++;
    Ticket storage ticket = flightTickets[flightID][tokenId];


    ticketOwners[tokenId] = msg.sender;
    // ticket.isAvailable = false;
    flights[flightID].availableTickets -= 1;

        // Update ticket metadata

        TicketMetadata storage ticketMetadata = ticketMetadata[tokenId];
        ticketMetadata.ticketId = tokenId;
        ticketMetadata.hashedUserInfo = hashedUserInfo;
        ticketMetadata.flightID = flightID;
        ticketMetadata.price = ticket.price;
        // ticketMetadata.isUsed = false;
        // ticketMetadata.classType = ticket.classType;
        ticketMetadata.checkedIn[msg.sender] = false;




    emit TicketPurchased(flightID, tokenId, msg.sender);
}

// Helper function to find an existing flight
function findFlight(
    string memory flightNumber,
    string memory departure,
    string memory destination,
    uint256 departureTime
) internal view returns (uint256) {
    for (uint256 i = 1; i <= flightCounter; i++) {
        Flight storage flight = flights[i];
        if (
            keccak256(abi.encodePacked(flight.flightNumber)) == keccak256(abi.encodePacked(flightNumber)) &&
            keccak256(abi.encodePacked(flight.departure)) == keccak256(abi.encodePacked(departure)) &&
            keccak256(abi.encodePacked(flight.destination)) == keccak256(abi.encodePacked(destination)) &&
            flight.departureTime == departureTime
        ) {
            return i;
        }
    }
    return 0;
}


//should get hashed user info from mapping

function transferTicket(
    uint256 ticketId,
    address to,
    bytes32 newHashedUserInfo
) external {
    // Check if sender is the owner of the ticket
    //require(ownerOf(ticketId) == msg.sender, "You are not the owner of this ticket");
    require(to != address(0), "Cannot transfer to zero address");
    
    // Get the current ticket metadata
    TicketMetadata storage metadata = ticketMetadata[ticketId];
    // require(!metadata.isUsed, "Cannot transfer used ticket");
    
    // Get the ticket information
    Ticket storage ticket = flightTickets[metadata.flightID][metadata.ticketId];
    // require(!ticket.isUsed, "Cannot transfer used ticket");

    // Transfer the NFT
    _transfer(msg.sender, to, ticketId);
    
    // Update ticket ownership mapping
    ticketOwners[ticketId] = to;

    
    
    // Update the hashed user information in metadata
    metadata.hashedUserInfo = newHashedUserInfo;
    
    // Reset check-in status for the new owner
    metadata.checkedIn[msg.sender] = false;
    
    // Emit transfer event
    emit TicketTransferred(
        ticketId,   
        metadata.flightID,
        metadata.seatNumber,
        msg.sender,
        to,
        newHashedUserInfo
    );
}

function getHashedUserInfo(uint256 tokenId) public view returns (bytes32) {
    return ticketMetadata[tokenId].hashedUserInfo;
}


}




//todo revocation system
//todo authorization and modifiers
//todo use only ticket or ticketmeatada