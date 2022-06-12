//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../marketplace/MarketplaceCore.sol";
import "../BEP721A/NFTCoreA.sol";
import "../security/Pausable.sol";
import "../security/ECDSA.sol";
import "../security/ReentrancyGuard.sol";
import "../BEP20/BEP20.sol";
import "../BEP20/SafeBEP20.sol";

// marketplace contract which accepts NFTCoreA-based NFTs.
// this contract attempts to simplify gasless implementations as much as possible.
// Note: Tier-based incentives with fee reduction NOT IMPLEMENTED YET.
contract Marketplace is MarketplaceCore, Pausable, ReentrancyGuard {
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
        uint88 price;
        // starting price of nft at duration 0.
        // if sale type is fixed sale, starting price will be 0.
        // used only for timed auction or bid auction sales.
        uint88 startingPrice;
        // ending price of nft at end of sale.
        // if sale type is fixed sale or bid auction, ending price will be 0.
        uint88 endingPrice;
        // minimum bid required for the nft to be sellable.
        // Note: only used for bid auctions.
        // if the minimum reserve bid is not met by the end of the auction, the sale gets cancelled.
        uint88 minimumReserveBid;
    }

    // emitted when a sale is created.
    event SaleCreated(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        Sale _sale
    );

    // emitted whenever a bidder bids on a bid auction sale
    event Bid(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        address _bidder,
        uint88 _bid
    );

    // emitted when a sale gets sold
    event Sold(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        uint88 _soldFor,
        address _buyer
    );

    // emitted when a sale gets cancelled
    event SaleCancelled(
        address indexed _nftContract,
        uint256 indexed _tokenId
    );

    // emits the SaleCreated event when a user lists an item.
    function saleCreated(address _nftContract, uint256 _tokenId, Sale calldata _sale) public onlyAdmin whenMarketplaceOpen {
        emit SaleCreated(_nftContract, _tokenId, _sale);
    }

    // emits the Bid event when a bidder bids on an item.
    function bid(address _nftContract, uint256 _tokenId, address _bidder, uint88 _bid) public onlyAdmin whenMarketplaceOpen {
        emit Bid(_nftContract, _tokenId, _bidder, _bid);
    }

    function saleCancelled(address _nftContract, uint256 _tokenId) public onlyAdmin whenMarketplaceOpen {
        emit SaleCancelled(_nftContract, _tokenId);
    }

    /**
     * @dev Generates a hash when users want to list their item up for sale.
     */
    function listingHash(
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        SaleType _saleType,
        address _seller,
        uint88 _price,
        uint88 _startingPrice,
        uint88 _endingPrice,
        uint88 _minimumReserveBid,
        uint24 _duration,
        string memory _txSalt
    ) public pure returns (bytes32) {
        return 
            keccak256(
                abi.encodePacked(
                    _nftContract,
                    _tokenId,
                    _paymentToken,
                    _saleType,
                    _seller,
                    _price,
                    _startingPrice,
                    _endingPrice,
                    _minimumReserveBid,
                    _duration,
                    _txSalt
                )
            );
    }

    /**
     * @dev Generates a bid hash whenever a bidder bids on an item.
     */
    function bidHash(
        address _nftContract,
        uint256 _tokenId,
        address _bidder,
        uint88 _bid,
        string memory _bidSalt
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _nftContract,
                    _tokenId,
                    _bidder,
                    _bid,
                    _bidSalt
                )
            );
    }

    /**
     * @dev Called when a user purchases a FIXED PRICE or TIMED AUCTION sale item.
     * First checks if signature matches the seller's signature, then transfers NFT to the buyer and payment to the seller.
     */
    function atomicMatch(
        // nft contract, payment token and seller
        address[3] calldata addresses,
        uint256 _tokenId,
        SaleType _saleType,
        // price, starting price, ending price, minimum reserve bid and winning bid
        uint88[5] calldata uint88s,
        // duration and seconds passed
        uint24[2] calldata uint24s,
        string memory _txSalt,
        bytes calldata _signature
    ) public nonReentrant whenMarketplaceOpen returns (bool) {
        /// firstly, check if payment token specified is allowed
        require(paymentTokens[addresses[1]] == true, "Marketplace: Payment token not allowed.");
        // goes through 3 checks. if all succeeds, NFT gets transferred to the buyer and payment gets transferred to the seller.
        sigMatch(addresses, _tokenId, _saleType, uint88s, uint24s[0], _txSalt, _signature);

        // if sale type is bid auction, require winning bid to be greater than minimum reserve bid, otherwise tx reverts.
        if (_saleType == SaleType.BidAuction) {
            require(uint88s[4] >= uint88s[3], "Marketplace: Minimum reserve bid is not met");
        }
        // here, _currentNFTPrice will show 0 if sale type is fixed price (check is done in prePaymentCheck() function).
        // transfers() will also check for the sale type and require either price or currentNFTPrice to be greater than 0 depending on sale type, otherwise tx reverts.
        uint88 _currentNFTPrice = prePaymentCheck(addresses, _tokenId, _saleType, uint88s, uint24s);
        transfers(addresses, _tokenId, _saleType, uint88s, _currentNFTPrice, _signature);

        if (_saleType == SaleType.FixedPrice) {
            emit Sold(addresses[0], _tokenId, uint88s[0], _msgSender());
        } else if (_saleType == SaleType.TimedAuction) {
            emit Sold(addresses[0],_tokenId, _currentNFTPrice, _msgSender());
        } else if (_saleType == SaleType.BidAuction) {
            emit Sold(addresses[0], _tokenId, uint88s[4], _msgSender());
        }

        return true;
    }

    /**
     * @dev Checks if signature matches the seller's signature.
     * Note: Called by the buyer.
     */
    function sigMatch(
        // nft contract, payment token and seller
        address[3] calldata addresses,
        uint256 _tokenId,
        SaleType _saleType,
        // price, starting price, ending price, minimum reserve bid and winning bid (winning bid however won't be used here)
        uint88[5] calldata uint88s,
        uint24 _duration,
        string memory _txSalt,
        bytes calldata _signature
    ) internal view {
        require(!usedSignatures[_signature], "Marketplace: Signature used");

        // gets the listing hash from the specified parameters
        bytes32 _hash = listingHash(
            addresses[0],
            _tokenId,
            addresses[1],
            _saleType,
            addresses[2],
            uint88s[0],
            uint88s[1],
            uint88s[2],
            uint88s[3],
            _duration,
            _txSalt
        );

        // gets the ethereum signed message hash from _hash
        bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_hash);

        // recovers the address that signed _ethSignedMsgHash with _signature.
        // must return the seller's address, otherwise the tx reverts.
        require(
            ECDSA.recover(_ethSignedMsgHash, _signature) == addresses[2],
            "Marketplace: Invalid seller signature"
        );
    }

    /**
     * @dev Pre-payment checks to ensure that both seller and buyer meets several checks.
     * Note: Called by the buyer.
     * Returns the current NFT price if sale is timed auction sale, otherwise it returns 0.
     */
    function prePaymentCheck(
        // nft contract, payment token and seller
        address[3] calldata addresses,
        uint256 _tokenId,
        SaleType _saleType,
        // price, starting price, ending price, minimum reserve bid and winning bid (minimum reserve bid here won't be used)
        uint88[5] calldata uint88s,
        // duration and seconds passed
        uint24[2] calldata uint24s
    ) internal view returns (uint88) {
        // gets the contract-level instance of the NFT contract address and checks for NFT ownership
        NFTCoreA _nft = NFTCoreA(addresses[0]);
        require(
            _nft.ownerOf(_tokenId) == addresses[2],
            "Marketplace: Seller is currently not the owner of this NFT"
        );

        // gets the contract-level instance of the payment token and check for buyer's balance and allowance
        BEP20 paymentToken_ = BEP20(addresses[1]);
        uint88 _currentNFTPrice;

        // different pre payment check logic for fixed price and for timed auction sales
        if (_saleType == SaleType.FixedPrice) {
            // checks if buyer's balance is enough to pay for the NFT
            require(
                paymentToken_.balanceOf(_msgSender()) >= uint88s[0],
                "Marketplace: Buyer's balance is too low"
            );
            // checks if buyer has allowed marketplace contract to spend at least _currentNFTPrice on their behalf
            require(
                paymentToken_.allowance(_msgSender(), address(this)) >= uint88s[0],
                "Marketplace: Buyer's approval for marketplace contract is too low"
            );
            
            _currentNFTPrice = 0;

        } else if (_saleType == SaleType.TimedAuction) {
            // calculates the current price for timed auction sale
            _currentNFTPrice = calculateCurrentPrice(uint88s[1], uint88s[2], uint24s[0], uint24s[1]);
            // checks if buyer's balance is enough to pay for the NFT
            require(
                paymentToken_.balanceOf(_msgSender()) >= _currentNFTPrice,
                "Marketplace: Buyer's balance is too low"
            );
            // checks if buyer has allowed marketplace contract to spend at least _currentNFTPrice on their behalf
            require(
                paymentToken_.allowance(_msgSender(), address(this)) >= _currentNFTPrice,
                "Marketplace: Buyer's approval for marketplace contract is too low"
            );

        } else if (_saleType == SaleType.BidAuction) {
            // checks if buyer's balance is enough to pay for the NFT
            require(
                paymentToken_.balanceOf(_msgSender()) >= uint88s[4],
                "Marketplace: Buyer's balance is too low"
            );
            // checks if buyer has allowed marketplace contract to spend at least _currentNFTPrice on their behalf
            require(
                paymentToken_.allowance(_msgSender(), address(this)) >= uint88s[4],
                "Marketplace: Buyer's approval for marketplace contract is too low"
            );

            _currentNFTPrice = 0;
        }

        return _currentNFTPrice;
    }

    /**
     * @dev Third and final check for atomicMatch.
     * When all previous checks passes, this function gets called and will issue the NFT to the buyer and transfer the payment to the seller.
     */
    function transfers(
        // nft contract, payment token and seller
        address[3] calldata addresses,
        uint256 _tokenId,
        SaleType _saleType,
        // price, start price, ending price, minimum reserve bid and winning bid (start price, ending price and minimum reserve bid not used)
        uint88[5] calldata uint88s,
        // not included in uint88 array for simplicity purposes
        uint88 _currentNFTPrice,
        bytes calldata _signature
    ) internal {
        NFTCoreA _nft = NFTCoreA(addresses[0]);
        BEP20 paymentToken_ = BEP20(addresses[1]);
        uint88 _salesFee;
        uint88 _sellerCut;
        
        if (_saleType == SaleType.FixedPrice) {
            require(uint88s[0] > 0, "Marketplace: Price cannot be 0");
            // calculates the sales fee of the NFT
            _salesFee = uint88(salesFee * uint88s[0] / 10000);
            // calculates the seller's payment after _salesFee is added
            _sellerCut =  uint88s[0] - _salesFee;
        } else if (_saleType == SaleType.TimedAuction) {
            require(_currentNFTPrice > 0, "Marketplace: Current NFT price cannot be 0");
            _salesFee = uint88(salesFee * _currentNFTPrice / 10000);
            _sellerCut = _currentNFTPrice - _salesFee;
        } else if (_saleType == SaleType.BidAuction) {
            require(uint88s[4] > 0, "Marketplace: Winning bid cannot be 0");
            // calculates the sales fee from the winning bid
            _salesFee = uint88(salesFee * uint88s[4] / 10000);
            _sellerCut = uint88s[4] - _salesFee;
        }

        // transfers _sellerCut from buyer to seller (i.e. buyer pays seller)
        paymentToken_.safeTransferFrom(_msgSender(), addresses[2], _sellerCut);

        // omits signature from being able to be used again in the future
        usedSignatures[_signature] = true;

        // transfers _salesFee to the NBExchequer if not 0
        if (_salesFee > 0) {
            paymentToken_.safeTransferFrom(_msgSender(), nbExchequer, _salesFee);
        }

        // transfers NFT from seller to buyer
        _nft.safeTransferFrom(addresses[2], _msgSender(), _tokenId);
    }

    /**
     * @dev Calculates current price for timed auction sales after _secondsPassed seconds has passed.
     */
    function calculateCurrentPrice(
        uint88 _startingPrice,
        uint88 _endingPrice,
        // duration and secondsPassed are technically limited to uint24 (2^24 seconds)
        // however, to make type conversions work easier, it's set here to uint88 for calculation purposes
        uint88 _duration,
        uint88 _secondsPassed
    ) internal pure returns (uint88) {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            // starting price can be higher than ending price (and often is), so the delta can be negative.
            int88 _totalPriceChange = int88(_endingPrice) - int88(_startingPrice);
            int88 _currentPriceChange = _totalPriceChange * int88(_secondsPassed) / int88(_duration);
            int88 _currentPrice = int88(_startingPrice) + _currentPriceChange;

            return uint88(_currentPrice);
        }
    }

    /**
     * @dev Invalidates a signature that was in use (either by removing listing or purely by ignoring it in general).
     */
    function ignoreSignature(
        // nft contract, payment token and seller
        address[3] calldata addresses,
        uint256 _tokenId,
        SaleType _saleType,
        // price, starting price, ending price, minimum reserve bid and winning bid (winning bid not used here)
        uint88[5] calldata uint88s,
        uint24 _duration,
        string memory _txSalt,
        bytes calldata _signature
    ) public {
        // gets the listing hash from the specified parameters
        bytes32 _hash = listingHash(
            addresses[0],
            _tokenId,
            addresses[1],
            _saleType,
            addresses[2],
            uint88s[0],
            uint88s[1],
            uint88s[2],
            uint88s[3],
            _duration,
            _txSalt
        );

        // gets the ethereum signed message hash from _hash
        bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_hash);

        // recovers the address that signed _ethSignedMsgHash with _signature.
        // must return the seller's address, otherwise the tx reverts.
        require(
            ECDSA.recover(_ethSignedMsgHash, _signature) == addresses[2],
            "Marketplace: Invalid seller signature"
        );

        usedSignatures[_signature] = true; 
    }
}