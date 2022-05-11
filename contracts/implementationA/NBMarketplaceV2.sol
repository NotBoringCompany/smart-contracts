//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../marketplace/MarketplaceCoreV2.sol";
import "../security/Pausable.sol";
import "../security/EDCSA.sol";
import "../security/ReentrancyGuard.sol";
import "../BEP20/BEP20.sol";
import "../BEP20/SafeBEP20.sol";

contract NBMarketplaceV2 is MarketplaceCoreV2, Pausable, ReentrancyGuard {
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

    enum SigError {
        InvalidSellerSig,
        UsedSig,
        NoErr
    }

    function _throwSigError(SigError error) private pure {
        if (error == SigError.NoErr) {
            return;
        } else if (error == SigError.InvalidSellerSig) {
            revert("NBMarketplaceV2: Invalid seller signature.");
        } else if (error == SigError.UsedSig) {
            revert("NBMarketplaceV2: Signature already used.");
        }
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

    function atomicMatch(
        /// _nftContract, _paymentToken, _seller, _buyer
        address[4] calldata _addresses,
        /// _tokenId, _soldFor,
        uint256[2] calldata _values,
        string memory _txSalt,
        SaleType _saleType,
        bytes calldata _signature
    ) public nonReentrant returns (bool) {
        /// check if payment token specified is allowed
        require(paymentTokens[_addresses[1]] == true, "NBMarketplaceV2: Token not accepted for payment.");
    
        sigMatch(_addresses, _values, _txSalt, _saleType, _signature);

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

        /// transfers _sellerCut from buyer to seller (i.e. buyer pays the seller)
        _paymentToken.safeTransferFrom(_msgSender(),_addresses[2],_sellerCut);

        /// omits signature from being able to be used in the future
        usedSignatures[_signature] == true;

        /// transfers _salesFee if not 0
        if (_salesFee > 0) {
            _paymentToken.safeTransferFrom(_msgSender(), nbExchequer, _salesFee);
        }

        /// transfers _devCut if not 0
        if (_devCut > 0) {
            _paymentToken.safeTransferFrom(_msgSender(), admin, _devCut);
        }

        /// transfers _nft from seller to buyer
        _nft.safeTransferFrom(_addresses[2], _msgSender(), _values[0]);

        /// used for events
        address[] memory addresses_ = new address[](4);
        addresses_[0] = _addresses[0];
        addresses_[1] = _addresses[1];
        addresses_[2] = _addresses[2];
        addresses_[3] = _addresses[3];

        uint256[] memory values_ = new uint256[](2);
        values_[0] = _values[0];
        values_[1] = _values[1];

        emit Sold(
            addresses_,
            values_,
            _saleType
        );
        return true;
    }

    /**
     * @dev Checks if signature matches the seller's signature.
     */
    function sigMatch(
        /// _nftContract, _paymentToken, _seller, _buyer
        address[4] calldata _addresses,
        /// _tokenId, _soldFor,
        uint256[2] calldata _values,
        string memory _txSalt,
        SaleType _saleType,
        bytes calldata _signature
    ) internal view returns (bool, SigError) {
        if (!usedSignatures[_signature]) {
            /// gets the message hash from the specified parameters
            bytes32 _hash = listingHash(
                _addresses[0],
                _values[0],
                _addresses[1],
                _saleType,
                _addresses[2],
                _values[1],
                _txSalt
            );

            /// gets the ethereum signed message
            bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_hash);

            if (ECDSA.recover(_ethSignedMsgHash, _signature) == _addresses[2]) {
                _throwSigError(SigError.NoErr);
                return (true, SigError.NoErr);
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function ignoreSignature(
        /// _nftContract, _paymentToken, _seller, _buyer
        address[4] calldata _addresses,
        /// _tokenId, _soldFor
        uint256[2] calldata _values,
        string memory _txSalt,
        SaleType _saleType,
        bytes calldata _signature
    ) public {
        bytes32 _hash = listingHash(
            _addresses[0],
            _values[0],
            _addresses[1],
            _saleType,
            _addresses[2],
            _values[1],
            _txSalt
        );

        bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_hash);

        require(
            ECDSA.recover(_ethSignedMsgHash, _signature) == _msgSender(), 
            "NBMarketplaceV2: Invalid seller signature."
        );

        usedSignatures[_signature] = true;
    }
}
