// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    // Mapping to store NFTs listed for sale
    mapping(address => mapping(uint256 => Listing)) public listings;

    // Event for listing an NFT for sale
    event NFTListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);

    // Event for the sale of an NFT
    event NFTSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);

    // Event for cancelling a listing
    event ListingCancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);

    // Function to list an NFT for sale
    function listNFT(address nftContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        
        // Make sure the sender is the owner of the NFT
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Only the owner can list the NFT");

        // Approve the marketplace to transfer the NFT
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace must be approved to transfer NFT"
        );

        listings[nftContract][tokenId] = Listing(msg.sender, price);

        emit NFTListed(msg.sender, nftContract, tokenId, price);
    }

    // Function to buy an NFT
    function buyNFT(address nftContract, uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.price > 0, "NFT not listed for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        // Remove the listing
        delete listings[nftContract][tokenId];

        // Transfer funds to the seller
        payable(listing.seller).transfer(listing.price);

        // Transfer the NFT to the buyer
        IERC721(nftContract).safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit NFTSold(msg.sender, nftContract, tokenId, listing.price);
    }

    // Function to cancel a listing
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Only the seller can cancel the listing");

        // Remove the listing
        delete listings[nftContract][tokenId];

        emit ListingCancelled(msg.sender, nftContract, tokenId);
    }

    // View function to check if an NFT is listed for sale
    function isListed(address nftContract, uint256 tokenId) external view returns (bool) {
        return listings[nftContract][tokenId].price > 0;
    }
}
