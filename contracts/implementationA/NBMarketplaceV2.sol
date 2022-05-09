//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../marketplace/MarketplaceCoreV2.sol";
import "../security/Pausable.sol";
import "../security/EDCSA.sol";
import "../security/ReentrancyGuard.sol";
import "../BEP20/BEP20.sol";

contract NBMarketplaceV2 is MarketplaceCoreV2, Pausable, ReentrancyGuard {

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
        /// _nftContract, _paymentToken, _seller, _buyer
        address[4] calldata _addresses,
        /// _tokenId, _soldFor, _txSalt
        uint256[3] calldata _values,
        SaleType _saleType,
        bytes calldata _signature
    ) public nonReentrant returns (bool) {
        /// check if payment token specified is allowed
        require(paymentTokens[_addresses[1]] == true, "NBMarketplaceV2: Token not accepted for payment.");
        /// check if signature is valid
        require(!usedSignatures[_signature], "NBMarketplaceV2: Signature already used.");

        /// gets the message hash from the specified parameters
        bytes32 _hash = listingHash(
            _addresses[0],
            _values[0],
            _addresses[1],
            _saleType,
            _addresses[2],
            _addresses[3],
            _values[1],
            _values[2]
        );

        /// gets the ethereum signed message
        bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_hash);

        ///checks if the recovered address matches the seller's address
        require(
            ECDSA.recover(_ethSignedMsgHash, _signature) == _addresses[2],
            "NBMarketplaceV2: Invalid seller signature."
        );

        /// checks for NFT ownership
        BEP721A _nft = BEP721A(_addresses[0]);
        require(
            _nft.ownerOf(_values[0]) == _addresses[2], 
            "NBMarketplaceV2: Seller is not the owner of this NFT."
        );

        /// checks if buyer's balance is enough to pay for the NFT
        BEP20 _paymentToken = BEP20(_addresses[1]);
        require(
            _paymentToken.balanceOf(_msgSender()) >= _values[1], 
            "NBMarketplaceV2: Buyer's balance is too low."
        );
        /// buyer needs to allow the contract to spend the payment amount
        require(
            _paymentToken.allowance(_msgSender(), address(this)) >= _values[1],
            "NBMarketplaceV2: Buyer's approval for marketplace contract is too low."
        );
        
        /// multiply the sales fee % to the NFT price
        uint256 _salesFee = salesFee / 10000 * _values[1];
        /// multiply the dev cut % to the NFT price
        uint256 _devCut = devCut / 10000 * _values[1];
        /// value to be transferred to the seller after successful purchase
        uint256 _sellerCut = _values[1] - _salesFee - _devCut;

        _paymentToken.safeTransferFrom(
            _msgSender(),
            addresses[]
        )
    }
}

