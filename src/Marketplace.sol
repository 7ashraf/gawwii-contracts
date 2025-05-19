// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./TicketFactory.sol";

contract Marketplace {
    TicketFactory public ticketFactory;
    address public feeRecipient;
    uint256 public feePercentage; // Basis points (e.g., 500 = 5%)

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event TicketListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event TicketSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event TicketDelisted(uint256 indexed tokenId, address indexed seller);

    constructor() {
    }
    
    function initialize(TicketFactory _ticketFactory) external {
        require(address(ticketFactory) == address(0), "Already initialized");
        ticketFactory = _ticketFactory;
        // feeRecipient = _feeRecipient;
        // feePercentage = _feePercentage;
    }

    modifier onlyTicketOwner(uint256 tokenId) {
        // require(
        //     IERC721(address(ticketFactory)).ownerOf(tokenId) == msg.sender ,
        //     "Not ticket owner"
        // );
        _;
    }

    function listTicketForResale(
        uint256 tokenId,
        address owner,
        uint256 price
    ) external  {
        // require(price > 0, "Price must be > 0");
        
        // Verify current metadata matches
        bytes32 storedHash = ticketFactory.getHashedUserInfo(tokenId);
        // require(storedHash == currentHashedUserInfo, "Invalid user info");

        listings[address(ticketFactory)][tokenId] = Listing(
            owner,
            price
        );

        emit TicketListed(owner, tokenId, price);
    }

    function buyTicket(
        uint256 tokenId,
        address to,
        bytes32 newHashedUserInfo
    ) external payable {
        Listing storage listing = listings[address(ticketFactory)][tokenId];
        // require(listing.price > 0, "Ticket not listed");
        // require(msg.value == listing.price, "Incorrect payment");

        // Verify listing integrity
        // bytes32 storedHash = ticketFactory.getHashedUserInfo(tokenId);
        // require(storedHash == listing.hashedUserInfo, "Ticket metadata modified");

        // Calculate fees
        // uint256 fee = (msg.value * feePercentage) / 10000;
        // uint256 sellerProceeds = msg.value - fee;

        // Transfer funds
        // payable(listing.seller).transfer(sellerProceeds);
        // payable(feeRecipient).transfer(fee);

        // Transfer ticket and update metadata
        ticketFactory.transferTicket(listing.seller, tokenId, to, newHashedUserInfo);

        emit TicketSold(tokenId, listing.seller, to, listing.price);
        delete listings[address(ticketFactory)][tokenId];
    }

    function delistTicket(uint256 tokenId) external onlyTicketOwner(tokenId) {
        delete listings[address(ticketFactory)][tokenId];
        emit TicketDelisted(tokenId, msg.sender);//should be ticket owner instead of admin
    }

    function getListing(uint256 tokenId) external view returns (Listing memory) {
        return listings[address(ticketFactory)][tokenId];
    }
}