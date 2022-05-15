//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../BEP721A/NFTCoreA.sol";

/**
 * @dev The first and rarest generation of NBMons that will ever be minted. Only 4500 of these will exist. They are NOT breedable and have a higher chance to be more powerful than their ordinary NBMon counterparts. 
 * Note: This contract does NOT have the newer, gas-efficient ERC721A standard which mints huge batches at almost the same price as minting only one. That version will be on a separate contract.
 * Most of the contract will have the same logic as NBMonCore.sol. Please refer to that contract to understand the variables and methods used.
 *
 * Uses NFTCoreA which inherits from BEP721A for cheaper batch minting.
 */
abstract contract GenesisNBMonCoreA is NFTCoreA {
    /**
     * @dev Instance of a genesis NBMon.
     */
    struct GenesisNBMon {
        uint256 nbmonId;
        address owner;
        uint256 hatchedAt;
        // void if deemed unnecessary as we will most likely only use OpenSea for transfers (buying/selling)
        uint256 transferredAt;
        uint32 hatchingDuration;
        // gender, rarity, mutation, species, genera, fertility
        string[] nbmonStats;
        string[] types;
        uint8[] potential;
        string[] passives;
        bool isEgg;
    }

    GenesisNBMon[] internal genesisNBMons;

    // mapping from owner address to array of IDs of the genesis NBMons the owner owns
    mapping(address => uint256[]) internal ownerGenesisNBMonIds;
    
    // checks the current genesis NBMon supply for enumeration. Starts at 1 when contract is deployed.
    uint256 public currentGenesisNBMonCount = 1;

    // function to change currentGenesisNBMonCount. 
    // NOT advised. refrain from using this unless really necessary.
    function changeCurrentCount(uint256 _count) public onlyAdmin {
        currentGenesisNBMonCount = _count;
    }

    event GenesisNBMonMinted(uint256 indexed _nbmonId, address indexed _owner);
    event GenesisNBMonBurned(uint256 indexed _nbmonId);

    // returns a genesis NBMon given an ID
    function getGenesisNBMon(uint256 _nbmonId) public view returns (GenesisNBMon memory) {
        require(_exists(_nbmonId), "GenesisNBMonCoreA: NBMon with the specified ID does not exist");
        return genesisNBMons[_nbmonId - 1];
    }

    // returns the genesis NBMon IDs of the owner's NBMons
    function getOwnerGenesisNBMonIds(address _owner) public view returns (uint256[] memory) {
        return ownerGenesisNBMonIds[_owner];
    }

    /// calls safeTransferFrom from BEP721A and changes ownership (using changeOwnership) afterwards for the GenesisNBMonCore part of the logic.
    function safeTransferFrom(address from, address to, uint256 nbmonId) public virtual override {
        super.safeTransferFrom(from, to, nbmonId);
        changeOwnership(nbmonId);
    }

    /// changes ownership of the nbmon. public function, but doesn't allow any unauthorized changes
    /// since it checks ownerOf after atomicMatch in NBMarketplaceV2 gets called.
    function changeOwnership(uint256 _nbmonId) private {
        require(_exists(_nbmonId), "GenesisNBMonCoreA: NBMon doesn't exist.");
        // when atomicMatch (from NBMarketplaceV2) is called, the owner of this _nbmonId (from BEP721A) has actually changed. however, ownerGenesisNBMonIds still isn't updated.
        // ownerOf returns the actual owner now (which is the buyer).
        address _currentOwner = ownerOf(_nbmonId);
        GenesisNBMon storage _genesisNBMon = genesisNBMons[_nbmonId - 1];
        // _genesisNBMon.owner will still return the seller, so this logic should work unless it already has changed to the buyer.
        require(_genesisNBMon.owner != _currentOwner, "GenesisNBMonCoreA: Cannot change to the same owner.");

        uint _nbmonIdIndex;

        /// loops through the seller's array of owned NBMon IDs.
        /// since the array hasn't been updated to remove the seller's nbmonId from the array and add it to the buyer's, we will use the following logic:
        /// switch the nbmonId's index with the last index on the array and pop it.
        for (uint i = 0; i < ownerGenesisNBMonIds[_genesisNBMon.owner].length; i++) {
            // if the loop has found the _nbmonId, this will the _nbmonIdIndex. 
            if (ownerGenesisNBMonIds[_genesisNBMon.owner][i] == _nbmonId) {
                _nbmonIdIndex = i;
                // find the last nbmon index to switch with the current nbmonIdIndex.
                uint256 _lastNbmonIdIndex = ownerGenesisNBMonIds[_genesisNBMon.owner].length - 1;
                // switching happens here
                (
                    ownerGenesisNBMonIds[_genesisNBMon.owner][_nbmonIdIndex],
                    ownerGenesisNBMonIds[_genesisNBMon.owner][_lastNbmonIdIndex]
                ) 
                =
                (
                    ownerGenesisNBMonIds[_genesisNBMon.owner][_lastNbmonIdIndex],
                    ownerGenesisNBMonIds[_genesisNBMon.owner][_nbmonIdIndex]
                );
                // once switched, the last index (which is now the _nbmonIdIndex) gets popped.
                ownerGenesisNBMonIds[_genesisNBMon.owner].pop();
                break;
            }
        }
        // we now replace the owner with the _currentOwner (which is the buyer).
        _genesisNBMon.owner = _currentOwner;
        // the seller will now no longer have the _nbmonId but the buyer.
        ownerGenesisNBMonIds[_currentOwner].push(_nbmonId);
    }
 
    // burns and deletes the genesis NBMon from circulating supply
    function burnNBMon(uint256 _nbmonId) public {
        // ensures that genesis nbmon exists
        require(_exists(_nbmonId), "GenesisNBMonCoreA: Burning non-existant NBMon");
        // checks if the caller of the function owns the specified _nbmonId
        require(genesisNBMons[_nbmonId - 1].owner == _msgSender(), "GenesisNBMonCoreA: Owner does not own specified NBMon.");
        // burns the genesis nbmon
        BEP721AURIStorage._burn(_nbmonId);

        /**
         * @dev removal of genesis NBMon ID from owner's list of owned NBMons (ownerNBMonIds).
         * Note: Array formation will however be altered.
         */

        // find the index of _nbmonId from the array
        uint256 _nbmonIdIndex;
        for (uint i = 0; i < ownerGenesisNBMonIds[_msgSender()].length; i++) {
            // if the "i"th index of the array contains _nbmonId, add to _nbmonIdIndex and finish the loop
            if (ownerGenesisNBMonIds[_msgSender()][i] == _nbmonId) {
                _nbmonIdIndex = i;
                // then swap the last index's genesis NBMon Id with the current index
                uint256 _lastNbmonIdIndex = ownerGenesisNBMonIds[_msgSender()].length - 1;
                (
                    ownerGenesisNBMonIds[_msgSender()][_nbmonIdIndex], 
                    ownerGenesisNBMonIds[_msgSender()][_lastNbmonIdIndex]
                ) 
                = 
                (
                    ownerGenesisNBMonIds[_msgSender()][_lastNbmonIdIndex], 
                    ownerGenesisNBMonIds[_msgSender()][_nbmonIdIndex]
                );

                //delete the last item (which is the NBMon Id to be burnt)
                ownerGenesisNBMonIds[_msgSender()].pop();

                /**
                * @dev Removal of NBMon from nbmons array. This will only be a simple delete and therefore will leave a gap in the array with a string of "0".
                *
                * Since the nbmons array starts from 1 and gets incremented by 1, we do not need to check for the index of the _nbmonId in the array.
                *
                * Although leaving a gap, this is the most cost-efficient way of deleting an element from an array, especially when the nbmons array becomes too large in length when there are 
                * a lot of NBMons minted already.
                *
                * Note: @dev When calculating this in the backend, ensure only to load NBMons that do NOT have a string of "0" from the nbmons array. This means that they are removed and burned.
                */
                delete genesisNBMons[_nbmonId - 1];
                
                emit GenesisNBMonBurned(_nbmonId);
                break;
            }
        }
    }
}