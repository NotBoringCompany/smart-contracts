//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../marketplace/MarketplaceCore.sol";
import "../BEP721A/NFTCoreA.sol";
import "../security/Pausable.sol";
import "../security/ECDSA.sol";
import "../security/ReentrancyGuard.sol";
import "../BEP20/BEP20.sol";
import "../BEP20/SafeBEP20.sol";

/// marketplace contract which currently accepts NFTCoreA inherited contracts.
/// this version will NOT focus on gasless implementations and instead will require users to pay gas everytime.
contract Marketplace is MarketplaceCore, Pausable, ReentrancyGuard {
    using SafeBEP20 for BEP20;

    /**
     * @dev contains three types of sales.
     * 1. fixed price (price is fixed for the entire duration of the sale)
     * 
     * 2. timed auction (price will either increase or decrease over the duration of the sale)
     * item gets sold when someone bids (i.e. it gets bought)
     *
     * 3. bid auction (price will keep increasing from its starting price each bid)
     * highest bidder (chosen either by the seller or when the time runs out) wins the auction
     */
    enum SaleType{
        FixedPrice,
        TimedAuction,
        BidAuction
    }

    enum PriceTrend {
        Inclining,
        Declining
    }

    // represents a sale order.
    struct Sale {
        // the seller who initiated the sale
        address seller;
        // id of the nft being sold
        uint256 tokenId;
        // the type of sale
        SaleType saleType;
        // timestamp of when sale was initiated
        uint256 startedAt;
        // duration of sale
        // Note: max duration is 2^24 seconds ~> 6.38 months
        uint24 duration;
        // if sale type is timed auction, this will contain the relevant info
        TimedAuctionSale timedAuctionSale;
        // if sale type is bid auction, this will contain the relevant info
        BidAuctionSale bidAuctionSale;
    }

    // represents a timed auction sale
    struct TimedAuctionSale {
        /// Note: both starting and ending prices are maxed at 2^88 wei ~> 309,485,009 ETH
        /// starting and ending price CANNOT be the same (or else it is essentially a fixed price sale)
        // price at the start of the auction
        uint88 startingPrice;
        // price at the end of the auction (if no one bids)
        uint88 endingPrice;
        // inclining price/declining price. useful for readability purposes.
        PriceTrend priceTrend;
    }

    // represents a bid auction sale
    struct BidAuctionSale {
        // price at the start of the auction
        uint88 startingPrice;
        // minimum bid required for the item to be sellable.
        // Note: if the minimumReserveBid is not met by the end of the auction, the seller will be unable to sell it to the highest bidder.
        uint88 minimumReserveBid;
        // the current auction's list of bids
        Bids bids;
    }

    // represents a bid auction's current bids
    struct Bids {
        // address of the bidder
        address bidder;
        // amount the bidder bids
        uint88 bid;
    }

    event SaleCreated(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        address _seller,
        SaleType _saleType,
        uint88 _startingPrice,
        uint256 _startedAt,
        uint88 _duration
    );

    event Bid (
        address indexed _nftContract,
        uint256 indexed _tokenId,
        address _bidder,
        uint88 _bid
    );

    event Sold(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        uint88 _soldFor,
        address _buyer
    );

    mapping (address => mapping (uint256 => Sale)) public sales;





}