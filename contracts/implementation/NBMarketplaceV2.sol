//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../marketplace/MarketplaceCoreV2.sol";
import "../security/Pausable.sol";
import "../security/EDCSA.sol";

contract NBMarketplaceV2 is MarketplaceCoreV2, Pausable {

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

    /**
     * @dev Generates a hash when listing with the given parameters.
     */
    function listingHash(
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        SaleType _saleType,
        address _seller,
        address _buyer,
        uint256 _soldFor,
        uint256 _txSalt
    ) public pure returns (bytes32) {
        return 
            keccak256(
                abi.encodePacked(
                    _nftContract,
                    _tokenId,
                    _paymentToken,
                    _saleType,
                    _seller,
                    _buyer,
                    _soldFor,
                    _txSalt
                )
            );
    }

    function atomicMatch(
        address[4] calldata addresses,
        uint256[3] calldata values,
        SaleType _saleType
    )
}

