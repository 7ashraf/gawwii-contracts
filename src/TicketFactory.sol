// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@thirdweb-dev/contracts/eip/interface/IERC721Supply.sol";
// import "@thirdweb-dev/contracts/eip/ERC721A.sol";
// import "@thirdweb-dev/contracts/base/ERC721Base.sol";



contract TicketFactory is ERC721Enumerable {
    uint256 public ticketCounter;
    uint256 public flightCounter;   // Counter for flight IDs


    address adminWallet = 0xcc3DcD86d470Eb14FbB83Fd614d16A103314271E;



    struct Flight{

        string flightNumber;
        address airlineAddress; // Reference to the airline in the registry
        uint256 flightId;
        string departure;
        string destination;
        string departureTime;
        string arrivalTime;
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
        address owner;
        uint256 ticketId;
        uint256 flightId;
        uint256 price;
        string class;
        bool isUsed;
        bytes32 hashedUserInfo;
        bool checkedIn;
        string seatNumber;
        bool isActive;
        bool isAvailable;
    }

 


    mapping(uint256 => Flight) public flights;  // flightId => Flight
    mapping(uint256 => bool) public ticketMinted;  // Tracks if a ticket has been minted
    mapping(address => Airline) public airlines;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => mapping(uint256 => Ticket)) public flightTickets; //flight id => list of flight tickets => ticketId => to ticket struct
    mapping(uint256 => address) public ticketOwners; // Track ticket ownership
    mapping(uint256 => Ticket) public ticketMetadata; // Track user-added metadata




    //event TemplateCreated(address indexed company, uint256 indexed templateId, string metadataURI, uint256 price);
    //event TicketMinted(address indexed buyer, uint256 indexed ticketId);
    event FlightCreated(
        uint256 indexed flightId,
        string indexed flightNumber, 
        string departure, 
        string destination, 
        string departureTime, 
        string  arrivalTime, 
        uint256 totalTickets, 
        uint256 availableTickets, 
        bool isActive, 
        bool shared, 
        address airlineAddress
    );
    event TicketPurchased(uint256 indexed flightId, uint256 indexed ticketId, address indexed buyer);
    
    event TicketModified(
        uint256 indexed tokenId,
        uint256 oldFlightID,
        uint256 newFlightID,
        address indexed user
    );

    event TicketCheckedIn(
        uint256 indexed ticketId,
        uint256 flightId,
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
        ) external
        {
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
        string memory date,
        uint256 numberOfTickets,
        string[] memory seatNumbers,
        // string[] memory classTypes,
        string memory arrivalTime
    ) external returns (uint256) {
        
        flightCounter++;
        uint256 flightId = flightCounter;

        flights[flightId] = Flight({
            flightId: flightId,
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

            // flightTickets[flightId][i] = Ticket({

            //     ticketId: i,//note can be set to a unique value so it is used as a token id also
            //     flightId: flightId,
            //     class: "Economy",
            //     price: 1
            // });
            
        }

        emit FlightCreated(flightCounter, flightNumber, departure, destination, date, arrivalTime, numberOfTickets, numberOfTickets, true, true, msg.sender);
        return flightCounter;
    }

    

    // note instead of taking the ticket id is passed because tickets exist before minting
    function purchaseTicket(
        uint256 flightId,
        address to,
        bytes32 hashedUserInfo
    ) external payable {
        //note should be a struct for tickets listed, that is different from the tickets that are minted
        
        // Ticket storage ticket = flightTickets[flightId][seatNumber];

        // require(ticket.isAvailable, "Ticket is not available");
        //require(msg.value == ticket.price, "Incorrect price");

        // Mint NFT by transferring ownership to buyer
        // Mint NFT by assigning a unique token ID to the buyer
        uint256 tokenId = ticketCounter;
        _safeMint(to, 1);
        ticketCounter++; // Increment token ID for the next mint

        ticketOwners[tokenId] = to;


        

        // Store user metadata on-chain with ticket metadata
        Ticket storage ticketMetadata = ticketMetadata[tokenId];
        ticketMetadata.ticketId = tokenId;
        ticketMetadata.hashedUserInfo = hashedUserInfo;
        ticketMetadata.flightId = flightId;
        ticketMetadata.price = ticketMetadata.price;
        ticketMetadata.isUsed = false;
        ticketMetadata.checkedIn = false;




        // Mark ticket as unavailable
        ticketMetadata.isAvailable = false;
        flights[flightId].availableTickets -= 1;

        // Emit an event for ticket purchase
        emit TicketPurchased(flightId, tokenId, msg.sender);
    }

    function updateAirlineMetadata(
        address airlineAddress,
        string memory newMetadataURI
    ) external  {
        require(airlines[airlineAddress].isAuthorized, "Airline not authorized");
        airlines[airlineAddress].metadataURI = newMetadataURI;
    }

    function modifyTicket(uint256 ticketId, uint256 newFlightId) onlyAuthorized() external {
        // Verify ownership of the ticket
        // require(ticketOwners[ticketId] == msg.sender, "You do not own this ticket");

        // Retrieve the current ticket metadata
        Ticket storage ticketMetadata = ticketMetadata[ticketId];
        uint256 oldFlightId = ticketMetadata.flightId;

        // Ensure the new flight is available
        Flight storage newFlight = flights[newFlightId];
        require(newFlight.isActive, "Flight is not active");

        // Update the old flight availability
        flights[oldFlightId].availableTickets += 1;

        // Update the new flight availability
        flights[newFlightId].availableTickets -= 1;

        // Update ticket metadata
        ticketMetadata.flightId = newFlightId;

        // Emit an event for ticket modification
        //false msg.sender
        emit TicketModified(ticketId, oldFlightId, newFlightId, msg.sender);

    }


    // needs huge refactoring

    function modifyTicket(
        uint256 ticketId,
        string memory flightNumber,
        string memory departure,
        string memory destination,
        string memory departureTime,
        string memory arrivalTime,
        uint256 totalTickets
    ) onlyAuthorized() external payable {
        // Verify ownership of the ticket
        // require(ticketOwners[ticketId] == msg.sender, "You do not own this ticket");

        // Retrieve the current ticket metadata
        Ticket storage ticketMetadata = ticketMetadata[ticketId];
        uint256 oldFlightID = ticketMetadata.flightId;
        uint256 flightId = findFlight(flightNumber, departure, destination, departureTime);

    if (flightId == 0) {
        // Step 2: Create flight if it doesn't exist
        flightCounter++;
        flightId = flightCounter;

        flights[flightId] = Flight({
            flightId: flightId,
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
            flightId, flightNumber, departure, destination, departureTime, 
            arrivalTime, totalTickets, totalTickets, true, false, msg.sender
        );
    } else {
        // Step 3: Handle existing flight
        Flight storage flight = flights[flightId];

        require(flight.isActive, "Flight is not active");
        // require(!flight.isExternal, "Cannot convert an inactive external flight");
    }

    // Step 4: Proceed to mint ticket for the user
    // require(ticket.isAvailable, "Ticket is not available");

    Ticket storage ticket = flightTickets[flightId][ticketId];


    // ticket.isAvailable = false;
    flights[flightId].availableTickets -= 1;

        // Update ticket metadata

        ticketMetadata.flightId = flightId;   
        ticketMetadata.price = ticket.price;
        ticketMetadata.isUsed = false;
        // ticketMetadata.classType = ticket.classType;
        // ticketMetadata.checkedIn[msg.sender] = false;




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
        flights[flightId].availableTickets -= 1;

        // Update ticket metadata

        // Emit an event for ticket modification
        emit TicketModified(ticketId, oldFlightID, flightId, msg.sender);
    }



    // check in airling into a flight
    function checkInTicket(uint256 ticketId, string calldata _seatNumber) external {

        

        Ticket storage ticketMetadata = ticketMetadata[ticketId];
        Ticket storage ticket = flightTickets[ticketMetadata.flightId][ticketMetadata.ticketId];
        require(ticketMetadata.isUsed == false, "Ticket has already been used");
        require(ticketMetadata.checkedIn == false, "You have already checked in");
        // require(ticket.isAvailable == true, "Ticket is not available");
        // require(ticket.isUsed == false, "Ticket has already been used");
        // require(ticketMetadata.checkedIn[msg.sender] == false, "You have already checked in");
        // Mark the ticket as used
        // ticketMetadata.isUsed = true;
        // ticket.isAvailable = false;
        // ticket.isUsed = true;
        // ticket.seatNumber = _seatNumber;
        ticketMetadata.seatNumber = _seatNumber;
        ticketMetadata.checkedIn = true;

        address ticketOwner = ticketOwners[ticketId];


        // Emit an event for ticket check-in
        //emit TicketModified(ticketId, ticketMetadata.flightId, ticketMetadata.seatNumber, ticketMetadata.flightId, ticketMetadata.seatNumber, ticketOwner);

        emit TicketCheckedIn(ticketId, ticketMetadata.flightId, ticketMetadata.seatNumber, ticketOwner, ticketMetadata.hashedUserInfo, msg.sender);
    }


    function addExternalFlight(
        string memory flightNumber,
        string memory departure,
        string memory destination,
        string memory departureTime,
        string memory arrivalTime,
        uint256 numberOfSeats
     ) public onlyAuthorizedAirline returns (uint256) {
        flightCounter++;
        uint256 flightId = flightCounter;

        flights[flightId] = Flight({
            flightId: flightId,
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
            flightId,
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

        return flightId;
    }


function purchaseExternalTicket(
    string memory flightNumber,
    string memory departure,
    string memory destination,
    string memory departureTime,
    string memory arrivalTime,
    uint256 totalTickets,
    bytes32 hashedUserInfo,
    address to
    ) external payable returns (uint256) {
    // Step 1: Check if flight already exists
    //no need, spurce of flights is airline backend
    uint256 flightId = findFlight(flightNumber, departure, destination, departureTime);

    if (flightId == 0) {
        // Step 2: Create flight if it doesn't exist
        flightCounter++;
        flightId = flightCounter;

        flights[flightId] = Flight({
            flightId: flightId,
            airlineAddress: msg.sender,// wtf
            flightNumber: flightNumber,
            departure: departure,
            destination: destination,
            departureTime: departureTime,
            totalTickets: totalTickets,
            availableTickets: totalTickets,
            arrivalTime: arrivalTime,
            isActive: true,
            shared: true,
            isExternal: true
        });


        emit FlightCreated(
            flightId, flightNumber, departure, destination, departureTime, 
            arrivalTime, totalTickets, totalTickets, true, false, msg.sender
        );
    } else {
        // Step 3: Handle existing flight
        Flight storage flight = flights[flightId];

        require(flight.isActive, "Flight is not active");
        // require(!flight.isExternal, "Cannot convert an inactive external flight");
    }

    // Step 4: Proceed to mint ticket for the user
    // require(ticket.isAvailable, "Ticket is not available");

    uint256 tokenId = ticketCounter;
    _safeMint(to, tokenId);
    // approve(adminWallet, tokenId);
    // setApprovalForAll(adminWallet, true);
    ticketCounter++;
    Ticket storage ticket = flightTickets[flightId][tokenId];


    ticketOwners[tokenId] = to;
    // ticket.isAvailable = false;
    flights[flightId].availableTickets -= 1;

        // Update ticket metadata

        Ticket storage ticketMetadata = ticketMetadata[tokenId];
        ticketMetadata.ticketId = tokenId;
        ticketMetadata.hashedUserInfo = hashedUserInfo;
        ticketMetadata.flightId = flightId;
        ticketMetadata.price = ticket.price;
        // ticketMetadata.isUsed = false;
        // ticketMetadata.classType = ticket.classType;
        ticketMetadata.checkedIn = false;


    


    emit TicketPurchased(flightId, tokenId, to);
    return tokenId;
}

// Helper function to find an existing flight
function findFlight(
    string memory flightNumber,
    string memory departure,
    string memory destination,
    string memory departureTime
) internal view returns (uint256) {
    for (uint256 i = 1; i <= flightCounter; i++) {
        Flight storage flight = flights[i];
        if (
            keccak256(abi.encodePacked(flight.flightNumber)) == keccak256(abi.encodePacked(flightNumber)) &&
            keccak256(abi.encodePacked(flight.departure)) == keccak256(abi.encodePacked(departure)) &&
            keccak256(abi.encodePacked(flight.destination)) == keccak256(abi.encodePacked(destination)) &&
            keccak256(abi.encodePacked(flight.departureTime)) == keccak256(abi.encodePacked(departureTime)) &&
            flight.isActive
        ) {
            return i;
        }
    }
    return 0;
}


//should get hashed user info from mapping

function transferTicket(
    address from,
    uint256 ticketId,
    address to,
    bytes32 newHashedUserInfo
    ) external {
    // Check if sender is the owner of the ticket
    //require(ownerOf(ticketId) == msg.sender, "You are not the owner of this ticket");
    require(to != address(0), "Cannot transfer to zero address");
    
    // Get the current ticket metadata
    Ticket storage metadata = ticketMetadata[ticketId];
    // require(!metadata.isUsed, "Cannot transfer used ticket");
    
    // Get the ticket information
    Ticket storage ticket = flightTickets[metadata.flightId][metadata.ticketId];
    // require(!ticket.isUsed, "Cannot transfer used ticket");

    // Transfer the NFT
    _transfer(from, to, ticketId);
    
    // Update ticket ownership mapping
    ticketOwners[ticketId] = to;

    
    
    // Update the hashed user information in metadata
    metadata.hashedUserInfo = newHashedUserInfo;
    
    // Reset check-in status for the new owner
    metadata.checkedIn = false;//wtf
    
    // Emit transfer event
    emit TicketTransferred(
        ticketId,   
        metadata.flightId,
        metadata.seatNumber,
        from,
        to,
        newHashedUserInfo
    );
}

    function getHashedUserInfo(uint256 tokenId) public view returns (bytes32) {
        return ticketMetadata[tokenId].hashedUserInfo;
    }

    function setAdmin (address _adminWallet) public /*onlyOwner*/ {
        adminWallet = _adminWallet;
    }


    function myInsecureApprove(address to, uint256 ticketId) public{
        address owner = ticketMetadata[ticketId].owner;
        // require(to != owner, "Cannot approve self");
        // require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");
        // rquire msg.sender is admoin 
        _approve(to, ticketId);
    }



    
}




//todo revocation system
//todo authorization and modifiers
//todo use only ticket or ticketmeatada