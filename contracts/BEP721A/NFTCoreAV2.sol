//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./BEP721AURIStorage.sol";

abstract contract NFTCoreAV2 is BEP721AURIStorage {
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
        /// contains related NFT-specific metadata
        string[] metadata;
    }

    /// an array of NFTs
    NFT[] internal nfts;

    /// a mapping from an owner to the IDs owned for this particular NFT
    mapping (address => uint256[]) internal ownerNFTIds;

    /// returns an NFT given the ID
    function getNFT(uint256 _tokenId) public view returns (NFT memory) {
        require(_exists(_tokenId), "NFTCoreAV2: Specified NFT ID does not exist");
        return nfts[_tokenId - 1];
    }

    /// returns the IDs owned by the owner
    function getOwnerNFTIds(address _owner) public view returns (uint256[] memory) {
        return ownerNFTIds[_owner];
    }

    /// modified version of BEP721A's safeTransferFrom.
    /// changesOwnership using NFTCoreAV2-specific code and also changes `transferredAt`.
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        BEP721A.safeTransferFrom(from, to, tokenId);
        changeOwnership(tokenId);
        changeTransferredAt(tokenId);
    }

    /// change transferredAt for _nft when transferred.
    /// private function, so cannot be tampered with.
    function changeTransferredAt(uint256 _tokenId) private {
        require(_exists(_tokenId), "NFTCoreAV2: Specified NFT ID doesn't exist");
        NFT storage _nft = nfts[_tokenId - 1];
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
        require(_exists(_tokenId), "NFTCoreAV2: Specified NFT ID doesn't exist");
        // when atomicMatch is called, ownerOf is already the buyer.
        address _currentOwner = ownerOf(_tokenId);
        NFT storage _nft = nfts[_tokenId - 1];

        /**
         * Presumably at this point, _nft.owner is still the seller,
         * and _currentOwner is already the buyer. We will do two checks
         * to ensure that these are still the case. If they fail, then presumably the ID already belongs to the buyer,
         * and the _nft.owner is now the buyer (_currentOwner).
         */
        // here, this check should pass unless _nft.owner (which is still the seller) is already changed to _currentOwner (which is the buyer).
        require(_nft.owner != _currentOwner, "NFTCoreAV2: _nft.owner is no longer the seller.");
        // right now, we're implying that the seller (which is still the _nft.owner) still owns _tokenId.
        // if the seller doesn't own it anymore, we assume that the buyer (_currentOwner) already has it.
        require(checkOwnedId(_nft.owner, _tokenId) == true, "NFTCoreAV2: Seller doesn't own the NFT anymore.");

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
        // _ownerIds is now the buyer since _nft.owner is already switched to the buyer.
        // we will now push the ID to the buyer's owned IDs.
        _ownerIds.push(_tokenId);
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
    function burnNFT(uint256 tokenId) public virtual {
        // ensures that the NFT exists
        require(_exists(tokenId), "NFTCoreAV2: Specified NFT ID doesn't exist");
        // checks if caller is the owner, otherwise revert the tx
        require(nfts[tokenId - 1].owner == _msgSender(), "NFTCoreAV2: Caller is not the NFT's owner");
        // burns the NFT
        BEP721AURIStorage._burn(tokenId);

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
                /**
                 * @dev Removal of the NFT from the nfts array. This will be a simple delete and thus
                 * will leave a gap in the array with a string of "0" for the deleted value.
                 *
                 * Since the nfts array starts from 1 and increments up, we don't have to check for the value and instead just insert the tokenId and - 1.
                 *
                 * Although leaving a gap, this is the most cost-efficient way of removing an NFT from the array, 
                 * especially when a lot of them are minted already.
                 *
                 * Note at devs: If you are using the nfts array for querying/data purposes, please ignore the "0" values.
                 */
                delete nfts[tokenId - 1];
                emit NFTBurned(tokenId);
                break;
            }
        }
    }
}