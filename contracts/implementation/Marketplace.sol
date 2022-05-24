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
     * item gets sold when someone buys it
     *
     * 3. bid auction (price will keep increasing from its starting price each bid)
     * highest bidder (chosen either by the seller or when the time runs out) wins the auction
     */
    enum SaleType {
        FixedPrice,
        TimedAuction,
        BidAuction
    }

    /// represents a sale order.
    struct Order {
        // the seller who initiated the sale order
        address seller;
        // if the NFT is still on sale:
        // if it's a fixed price sale, buyer will be null.
        // if it's either timed or bid auction, buyer will be the current winner or null.
        address buyer;
        // the id of the NFT up for sale
        uint256 tokenId;
        // type of sale
        SaleType saleType;
    }

    event Sold(
        /// _nftContract, _paymentToken, _seller, _buyer 
        address[] indexed _addresses,
        /// _tokenId, _soldFor
        uint256[] indexed _values,
        SaleType _saleType
    );

    /**
     * @dev Generates a hash when listing with the given parameters.
     */
    function listingHash(
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        SaleType _saleType,
        address _seller,
        uint256 _price,
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
                    _txSalt
                )
            );
    }
}