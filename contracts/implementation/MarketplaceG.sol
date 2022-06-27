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
contract MarketplaceG is MarketplaceCore, Pausable, ReentrancyGuard {
    using SafeBEP20 for BEP20;

    // if false, cease all sale-related functions.
    bool public marketplaceOpen;

    event MarketplaceOpened(address _admin);
    event MarketplaceClosed(address _admin);

    modifier whenMarketplaceOpen() {
        require(marketplaceOpen, "Marketplace: Marketplace is closed.");
        _;
    }

    modifier whenMarketplaceClosed() {
        require(!marketplaceOpen, "Marketplace: Marketplace is open.");
        _;
    }

    function openMarketplace() public whenMarketplaceClosed onlyAdmin {
        marketplaceOpen = true;
        emit MarketplaceOpened(_msgSender());
    }

    function closeMarketplace() public whenMarketplaceOpen onlyAdmin {
        marketplaceOpen = false;
        emit MarketplaceClosed(_msgSender());
    }

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
        // price of the nft being sold, maxed out at 2^88 wei ~> 309,485,009 ETH
        // Note: if sale type is either timed or bid auction, price will be 0.
        // instead, timedAuctionSale/bidAuctionSale will have the relevant prices shown.
        uint88 price;
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

    event SaleCanceled(
        address indexed _nftContract,
        uint256 indexed _tokenId
    );

    /**
     * @dev Nested mappings which include the NFT contract for the address,
     * as this marketplace will be potentially used by several NFT contracts.
     */
    // maps from token ID to sale details
    mapping (address => mapping (uint256 => Sale)) public sales;
    // maps from token ID to bidding details.
    // Note: only used for bidding auctions.
    // if a bidder bids, the bid will get added to the array of bids.
    mapping (address => mapping (uint256 => Bids[])) public nftBids;

    // checks if address owns token id for a particular nft contract
    function _ownerOf(address _nftAddress, address _seller, uint256 _tokenId) private view returns (bool) {
        NFTCoreA _nftContract = NFTCoreA(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _seller);
    }

    /**
     * @dev Start of marketplace logic
     */
     
    // BUY LOGIC FOR the three types required

    /// gets the required sale info from _getSaleInfo depending on the sale type and adds the sale onto `sales`.
    function _addSale(
        address _nftContract,
        address _seller,
        uint256 _tokenId,
        uint24 _duration,
        uint88 _price,
        SaleType _saleType,
        uint88 _startingPrice,
        uint88 _endingPrice,
        uint88 _minimumReserveBid
    ) private {
        // check if the id is already on sale. if not, continue. if it's already on sale, revert.
        require(sales[_nftContract][_tokenId].startedAt == 0, "Specified ID is already on sale.");

        Sale memory _sale = _getSaleInfo(
            _seller,
            _tokenId,
            _duration,
            _price,
            _saleType,
            _startingPrice,
            _endingPrice,
            _minimumReserveBid
        );

        sales[_nftContract][_tokenId] = _sale;
        emit SaleCreated(_nftContract, _tokenId, _seller, _saleType, _startingPrice, block.timestamp, _duration);
    }

    /// remove a sale from `sales` and cancels it.
    /// Emits the SaleCanceled event.
    function _cancelSale(address _nftContract, uint256 _tokenId) private {
        Sale memory _sale = sales[_nftContract][_tokenId];
        // here, we can use almost any value from _sale if _sale does exist. otherwise, all values will be default.
        // startedAt is either 0 or the actual block.timestamp of when the ID is on sale, hence we can use this.
        require(_sale.startedAt > 0, "MarketplaceV2: Specified token ID isn't on sale. Cannot cancel");
        delete _sale;
        emit SaleCanceled(_nftContract, _tokenId);
    }

    /**
     * @dev Gets required sale info. Different sale types will result in different Sale values,
     * meaning that calculations here will tidy up some code.
     */
    function _getSaleInfo(
        address _seller,
        uint256 _tokenId,
        uint24 _duration,
        uint88 _price,
        SaleType _saleType,
        uint88 _startingPrice,
        uint88 _endingPrice,
        uint88 _minimumReserveBid
    ) private view returns (Sale memory _sale) {
        /// if sale type is fixed price, nullify all values for timed auction sale and bid auction sale,
        /// and return required values.
        if (_saleType == SaleType.FixedPrice) {
            TimedAuctionSale memory _timedAuctionSale = TimedAuctionSale(0, 0);
            Bids memory _bids = Bids(address(0), 0);
            BidAuctionSale memory _bidAuctionSale = BidAuctionSale(0, 0, _bids);
            _sale = Sale(_seller, _tokenId, _saleType, block.timestamp, _duration, _price, _timedAuctionSale, _bidAuctionSale);

            return _sale;

        /// if sale type is timed auction, nullify bid auction values and price value.
        /// return required values
        } else if (_saleType == SaleType.TimedAuction) {
            TimedAuctionSale memory _timedAuctionSale = TimedAuctionSale(_startingPrice, _endingPrice);
            Bids memory _bids = Bids(address(0), 0);
            BidAuctionSale memory _bidAuctionSale = BidAuctionSale(0, 0, _bids);
            _sale = Sale(_seller, _tokenId, _saleType, block.timestamp, _duration, 0, _timedAuctionSale, _bidAuctionSale);

            return _sale;

        /// if sale tyype is bid auction, nullify timed auction values and price value.
        /// return required values
        } else if (_saleType == SaleType.BidAuction) {
            TimedAuctionSale memory _timedAuctionSale = TimedAuctionSale(0, 0);
            Bids memory _bids = Bids(address(0), 0);
            BidAuctionSale memory _bidAuctionSale = BidAuctionSale(_startingPrice, _minimumReserveBid, _bids);
            _sale = Sale(_seller, _tokenId, _saleType, block.timestamp, _duration, 0, _timedAuctionSale, _bidAuctionSale);

            return _sale;
        }
    }

}