//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../BEP721A/BEP721A.sol";
import "../security/Context.sol";
import "../security/AccessControl.sol";

/**
 * @dev All marketplace-related functions. Only supports ERC/BEP721A (the more efficient version of ERC/BEP721).
 */
abstract contract MarketplaceCoreV2 is Context, AccessControl {
    // /**
    //  * @dev Represents an NFT sale containing the details. 
    //  */
    // struct Sale {
    //     /**
    //      * @dev contains three types of sales.
    //      * 1. fixed price (price is fixed for the entire duration of the sale)
    //      * 
    //      * 2. timed auction (price will either increase or decrease over the duration of the sale)
    //      * item gets sold when someone buys it
    //      *
    //      * 3. bid auction (price will keep increasing from its starting price each bid)
    //      * highest bidder (chosen either by the seller or when the time runs out) wins the auction
    //      */
    //     string saleType;
    //     // person who's selling the NFT
    //     address seller;
    //     // seller can reserve this NFT to another address (only applicable to fixed price sales)
    //     address reservedTo;

    //     /**
    //      * @dev Prices are measured in WEI. Max price is set at 2e+80 wei.
    //      */
    //     // only applicable to fixed price sales.
    //     uint80 price;
    //     // price at the start of the auction. only applicable to timed or bid auctions.
    //     uint80 startingPrice;
    //     // price at the end of the auction. only applicable to timed or bid auctions.
    //     // triggered when there's a buyer for this NFT.
    //     uint80 endingPrice;

    //     // minimum bid required to sell the NFT. only applicable to bid auctions.
    //     // if the current bid is below this and the duration has ended, the sale gets cancelled.
    //     uint80 minimumReserveBid;
    //     // timestamp of sale start
    //     uint256 start;
    //     // duration for the sale to be live. max duration is 2e+24 seconds (which is around 6.3 months)
    //     uint24 duration;
    // }

    // /// sales fee for specific NFT sales (a 10000 value represents a 100% fee).
    // uint16 public salesFee;
    // /// developer's cut on top of the sales fee for specific NFT sales (a 10000 value represents a 100% fee).
    // uint16 public devCut;

    // /**
    //  * @dev Nested mapping. Maps from the specific NFT contract to the NFT ID which returns the details of the ID on sale.
    //  */
    // mapping (address => mapping (uint256 => Sale)) public sales;

    // event SaleCreated(
    //     address indexed _nftContract,
    //     uint256 indexed _tokenId,
    //     string _saleType,
    //     address _seller,
    //     address _reservedTo,
    //     uint80 _price,
    //     uint80 _startingPrice,
    //     uint80 _endingPrice,
    //     uint80 _minimumReserveBid,
    //     uint256 _start,
    //     uint24 _duration
    // );

    // event Sold(
    //     address indexed _nftContract,
    //     uint256 indexed _tokenId,
    //     string _saleType,
    //     address _seller,
    //     address _buyer,
    //     // price at which the NFT is sold at
    //     uint80 _soldFor
    // );

    // event SaleCancelled(
    //     address indexed _nftContract,
    //     uint256 indexed _tokenId
    // );

    // /// checks if _claimant owns _tokenId.
    // function _owns(address _nftAddress, address _claimant, uint256 _tokenId) internal view returns (bool) {
    //     BEP721A _nftContract = _getNftContract(_nftAddress);
    //     return _nftContract.ownerOf(_tokenId) == _claimant;
    // }

    // /// gets an instance of the nft contract
    // function _getNftContract(address _nftContract) internal pure returns (BEP721A) {
    //     return BEP721A(_nftContract);
    // }
    
    /// check for supported BEP20 tokens used for payment in the marketplace
    mapping (address => bool) public paymentTokens;
    /// check for signatures that are no longer allowed for signing txs
    mapping (bytes => bool) public usedSignatures;

    /// the sales fee portion will be received here (our community treasury)
    address public nbExchequer;
    /// the team fee portion will be received here (team's wallet)
    address public teamWallet;


    /**
     * @dev We've divided the fee into two to be more transparent. 
     * Calculated in 100 basis points. 100 points = 1%.
     * @dev Total fee (in %) = (salesFee + devCut) / 100.
     */
    /// sales fee portion
    uint16 public salesFee;
    /// dev's cut
    uint16 public devCut;

    /**
     * @dev Sets the NBExchequer address to receive the sales fee portion.
     */
    function setNBExchequer(address _nbExchequer) public onlyAdmin {
        nbExchequer = _nbExchequer;
    }

    /**
     * @dev Sets the team wallet address to receive the team fee portion.
     */
    function setTeamWallet(address _teamWallet) public onlyAdmin {
        teamWallet = _teamWallet;
    }

    /**
     * @dev Sets the sales fee of transactions.
     */
    function setSalesFee(uint16 _salesFee) public onlyAdmin {
        salesFee = _salesFee;
    }

    /**
     * @dev Sets the dev cut of transactions.
     */
    function setDevCut(uint16 _devCut) public onlyAdmin {
        devCut = _devCut;
    }

    /**
     * @dev Sets the accepted payment tokens to be used in the marketplace.
     */
    function setPaymentTokens(address[] calldata _paymentTokens) public onlyAdmin {
        // realistically, we wouldn't add more than 256 tokens at once anyway
        for (uint8 i = 0; i < _paymentTokens.length; i++) {
            // if the token already exists in the list of accepted tokens, skip to the next iteration.
            if (paymentTokens[_paymentTokens[i]] == true) {
                continue;
            }
            paymentTokens[_paymentTokens[i]] = true;
        }
    }

    /**
     * @dev Removes payment tokens from the list of accepted payment tokens.
     */
    function removePaymentTokens(address[] calldata _paymentTokens) public onlyAdmin {
        for (uint8 i = 0; i < _paymentTokens.length; i++) {
            paymentTokens[_paymentTokens[i]] = false;
        }
    }
}