//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./BEP721AURIStorage.sol";

abstract contract NFTCoreA is BEP721AURIStorage {
    /**
     * @dev Instance of the NFT
     */
    struct NFT {
        /// name of the NFT. for example, NFT contract "Test" inheriting from this will 
        /// always have "Test" as the nftName.
        string nftName;
        uint256 tokenId;
        address owner;
        uint256 bornAt;
        /// changes when transferred (such as from buying/selling)
        uint256 transferredAt;
        /// checks if NFT is currently being sold.
        /// Note: only works for NBCompany's marketplace.
        bool onSale;
        /// contains address related metadata
        address[] addressMetadata;
        /// contains string related metadata
        string[] stringMetadata;
        /// contains numeric/value related metadata
        uint256[] numericMetadata;
        /// contains boolean related metadata
        bool[] boolMetadata;
        /// contains bytes related metadata
        bytes32[] bytesMetadata;
        /// checks if this NFT is currently on sale
    }

    /// a mapping from the token ID to the full profile of the NFT
    mapping (uint256 => NFT) internal nfts;
    /// a mapping from an owner to the IDs owned for this particular NFT
    mapping (address => uint256[]) internal ownerNFTIds;

    /// only usable in NBCompany's marketplace.
    /// a modifier to check if current token ID is currently being sold.
    /// Note: This modifier is used to restrict specific usecases if the NFT is being sold.
    /// This is to ensure that data execution is intact and wouldn't be deterred by miscalculations.
    /// For instance, if a seller decides to transfer tokenId to another user while being sold, the seller will change.
    /// This could cause issues to determine who the initial seller was as the data was already changed.
    /// Hence, we use this modifier to ensure that these would be restricted as much as possible.
    modifier notOnSale(uint256 tokenId) {
        require(!nfts[tokenId].onSale, "NFTC1");
        _;
    }

    /// returns an NFT given the ID
    function getNFT(uint256 _tokenId) external view returns (NFT memory) {
        require(_exists(_tokenId), "NFTC2");
        return nfts[_tokenId];
    }

    /// returns the IDs owned by the owner
    function getOwnerNFTIds(address _owner) external view returns (uint256[] memory) {
        return ownerNFTIds[_owner];
    }

    /// modified version of BEP721A's safeTransferFrom.
    /// changesOwnership using NFTCoreAV2-specific code and also changes `transferredAt`.
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override notOnSale(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
        changeOwnership(tokenId);
        changeTransferredAt(tokenId);
    }

    /// NOT advised. only inherited to override `notOnSale` modifier.
    /// @dev Please use the safer form `safeTransferFrom` to do these types of transfers.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override notOnSale(tokenId) {
        super.transferFrom(from, to, tokenId);
        changeOwnership(tokenId);
        changeTransferredAt(tokenId);
    }

    /// change transferredAt for _nft when transferred.
    /// private function, so cannot be tampered with.
    function changeTransferredAt(uint256 _tokenId) private {
        require(_exists(_tokenId), "NFTC3");
        NFT storage _nft = nfts[_tokenId];
        _nft.transferredAt = block.timestamp;

    }

    /**
     * @dev Used to change ownership of an NFT using NFTCoreAV2 code.
     * changeOwnership is used in safeTransferFrom, and ownership in BEP721A (which is the parent contract) is already changed.
     * This code is used for NFTCoreAV2's side of ownership change.
     *
     * Note: Function has no prerequisites apart from that the token does exist.
     * This is because we check the actual owner from `ownerOf`.
     * when using atomicMatch from NBMarketplace, ownerOf has already changed to the buyer. However,
     * the seller still has the ID in `ownerNFTIds`. 
     *
     * Thus, the purpose of this code is to make the seller lose the ID and to add it to the buyer's array of owned IDs.
     * On top of that, we will also change the NFT.owner.
     */
    function changeOwnership(uint256 _tokenId) private {
        require(_exists(_tokenId), "NFTC4");
        // when atomicMatch is called, ownerOf is already the buyer.
        address _currentOwner = ownerOf(_tokenId);
        NFT storage _nft = nfts[_tokenId];

        /**
         * Presumably at this point, _nft.owner is still the seller,
         * and _currentOwner is already the buyer. We will do two checks
         * to ensure that these are still the case. If they fail, then presumably the ID already belongs to the buyer,
         * and the _nft.owner is now the buyer (_currentOwner).
         */
        // here, this check should pass unless _nft.owner (which is still the seller) is already changed to _currentOwner (which is the buyer).
        require(_nft.owner != _currentOwner, "NFTC5");
        // right now, we're implying that the seller (which is still the _nft.owner) still owns _tokenId.
        // if the seller doesn't own it anymore, we assume that the buyer (_currentOwner) already has it.
        require(checkOwnedId(_nft.owner, _tokenId) == true, "NFTC6");

        /**
         * @dev If the checks pass, we now know that _nft.owner is still the seller, and _currentOwner is the buyer.
         */
        uint _nftIdIndex;
        // we get an instance of the IDs owned by the seller.
        uint256[] storage _ownerIds = ownerNFTIds[_nft.owner];

        // we loop through the seller's array of owned IDs.
        // since now we know that the seller still owns the ID, we will do some magic to remove the ID from the seller.
        // we switch the ID's index with the last ID's index on the array and pop it.
        // the formation of the array will however be altered.
        for (uint i = 0; i < _ownerIds.length; i++) {
            // once we find the index whose value matches the _tokenId, we store it in _nftIdIndex.
            if (_ownerIds[i] == _tokenId) {
                _nftIdIndex = i;
                // gets the last index of the array
                uint _lastNftIdIndex = _ownerIds.length - 1;
                // switching happens here.
                (
                    _ownerIds[_nftIdIndex], 
                    _ownerIds[_lastNftIdIndex]
                ) 
                = 
                (
                    _ownerIds[_lastNftIdIndex],
                    _ownerIds[_nftIdIndex]
                );
                // once switched, the last index/value (which is the _nftIdIndex) will be popped.
                _ownerIds.pop();
                break;
            }
        }
        // now that the switching is done and the ID is removed, we can switch the _nft.owner from the seller to the buyer.
        _nft.owner = _currentOwner;
        // we will now push the ID to the buyer's owned IDs.
        uint256[] storage _buyerOwnerIds = ownerNFTIds[_nft.owner];
        _buyerOwnerIds.push(_tokenId);
    }

    /// checks if an owner owns a particular ID.
    function checkOwnedId(address _owner, uint256 _tokenId) private view returns (bool) {
        bool exists = false;
        uint256[] memory _ownerIds = ownerNFTIds[_owner];
        // loops through the array of owned IDs.
        for (uint i = 0; i < _ownerIds.length; i++) {
            // if the owner owns the _tokenId, exists become true.
            if (_ownerIds[i] == _tokenId) {
                exists = true;
            }
        }
        return exists;
    } 


    string private baseTokenURI;
    /**
     * @dev Sets the Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
         return baseTokenURI;
    }
    
    /**
     * @dev Changes the current Base URI. 
     * Only callable by Admin or CEO of contract.
     */
    function setBaseURI(string memory newBaseURI) public onlyAdminOrCEO {
        baseTokenURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    event NFTMinted(
        uint256 indexed _tokenId,
        address _owner,
        uint256 _bornAt
    );

    event NFTBurned(
        uint256 indexed _tokenId
    );

    /**
     *@dev See {BEP721URIStorage-_burn}.
     */
    function burnNFT(uint256 tokenId) external virtual {
        // ensures that the NFT exists
        require(_exists(tokenId), "NFTC7");
        // checks if caller is the owner, otherwise revert the tx
        require(nfts[tokenId].owner == _msgSender(), "NFTC8");
        // burns the NFT
        super._burn(tokenId);

        /**
         * @dev The next few steps will be NFTCoreAV2-specific.
         * We will remove the ID from the owner's array of IDs by popping.
         * Array formation will be altered.
         */
        uint _nftIdIndex;
        uint256[] storage _ownerIds = ownerNFTIds[_msgSender()];
        // loops through the owner's array of owned IDs
        for (uint i = 0; i < _ownerIds.length; i++) {
            // if the "i"th index matches the tokenId, we insert this index into _nftIdIndex.
            if (_ownerIds[i] == tokenId) {
                _nftIdIndex = i;
                // we get the last index of the array
                uint _lastNftIdIndex = _ownerIds.length - 1;
                // switching happens here
                (
                    _ownerIds[_nftIdIndex], 
                    _ownerIds[_lastNftIdIndex]
                ) 
                = 
                (
                    _ownerIds[_lastNftIdIndex],
                    _ownerIds[_nftIdIndex]
                );
                // once the indexes are switched, we pop the last index (which is now the _nftIdIndex).
                _ownerIds.pop();
                
                /// delete will replace the values for this particular ID to "0".
                /// @dev if you are using the nfts[id] mapping, please ignore values that are "0".
                delete nfts[tokenId];
                emit NFTBurned(tokenId);
                break;
            }
        }
    }
}