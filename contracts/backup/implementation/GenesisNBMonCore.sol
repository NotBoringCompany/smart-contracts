// //SPDX-License-Identifier: MIT

// pragma solidity ^0.8.13;

// import "../BEP721/NFTCore.sol";

// /**
//  * @dev The first and rarest generation of NBMons that will ever be minted. Only 4500 of these will exist. They are NOT breedable and have a higher chance to be more powerful than their ordinary NBMon counterparts. 
//  * Note: This contract does NOT have the newer, gas-efficient ERC721A standard which mints huge batches at almost the same price as minting only one. That version will be on a separate contract.
//  * Most of the contract will have the same logic as NBMonCore.sol. Please refer to that contract to understand the variables and methods used.
//  */
// abstract contract GenesisNBMonCore is NFTCore {
//     /**
//      * @dev Instance of a genesis NBMon.
//      */
//     struct GenesisNBMon {
//         uint256 nbmonId;
//         address owner;
//         uint256 hatchedAt;
//         // void if deemed unnecessary as we will most likely only use OpenSea for transfers (buying/selling)
//         uint256 transferredAt;
//         uint32 hatchingDuration;
//         // gender, rarity, mutation, species, genera, fertility
//         string[] nbmonStats;
//         string[] types;
//         uint8[] potential;
//         string[] passives;
//         bool isEgg;
//     }

//     GenesisNBMon[] internal genesisNBMons;

//     // mapping from owner address to array of IDs of the genesis NBMons the owner owns
//     mapping(address => uint256[]) internal ownerGenesisNBMonIds;
    
//     // checks the current genesis NBMon supply for enumeration. Starts at 1 when contract is deployed.
//     uint256 internal currentGenesisNBMonCount = 1;

//     // function to change currentGenesisNBMonCount. 
//     // NOT advised. refrain from using this unless really necessary.
//     function changeCurrentCount(uint256 _count) public onlyAdmin {
//         currentGenesisNBMonCount = _count;
//     }

//     event GenesisNBMonMinted(uint256 indexed _nbmonId, address indexed _owner);
//     event GenesisNBMonBurned(uint256 indexed _nbmonId);

//     // returns a genesis NBMon given an ID
//     function getGenesisNBMon(uint256 _nbmonId) public view returns (GenesisNBMon memory) {
//         require(_exists(_nbmonId), "NBMonCore: NBMon with the specified ID does not exist");
//         return genesisNBMons[_nbmonId - 1];
//     }

//     // returns the genesis NBMon IDs of the owner's NBMons
//     function getOwnerGenesisNBMonIds(address _owner) public view returns (uint256[] memory) {
//         return ownerGenesisNBMonIds[_owner];
//     }

//     // burns and deletes the genesis NBMon from circulating supply
//     function burnNBMon(uint256 _nbmonId) public {
//         // ensures that genesis nbmon exists
//         require(_exists(_nbmonId), "NBMonCore: Burning non-existant NBMon");
//         // checks if the caller of the function owns the specified _nbmonId
//         require(genesisNBMons[_nbmonId - 1].owner == _msgSender(), "NBMonCore: Owner does not own specified NBMon.");
//         // burns the genesis nbmon
//         BEP721URIStorage._burn(_nbmonId);

//         /**
//          * @dev removal of genesis NBMon ID from owner's list of owned NBMons (ownerNBMonIds).
//          * Note: Array formation will however be altered.
//          */

//         // find the index of _nbmonId from the array
//         uint256 _nbmonIdIndex;
//         for (uint i = 0; i < ownerGenesisNBMonIds[_msgSender()].length; i++) {
//             // if the "i"th index of the array contains _nbmonId, add to _nbmonIdIndex and finish the loop
//             if (ownerGenesisNBMonIds[_msgSender()][i] == _nbmonId) {
//                 _nbmonIdIndex = i;
//                 break;
//             }
//         }
//         // then swap the last index's genesis NBMon Id with the current index
//         uint256 _lastNbmonIdIndex = ownerGenesisNBMonIds[_msgSender()].length - 1;
//         (ownerGenesisNBMonIds[_msgSender()][_nbmonIdIndex], ownerGenesisNBMonIds[_msgSender()][_lastNbmonIdIndex]) = (ownerGenesisNBMonIds[_msgSender()][_lastNbmonIdIndex], ownerGenesisNBMonIds[_msgSender()][_nbmonIdIndex]);

//         //delete the last item (which is the NBMon Id to be burnt)
//         ownerGenesisNBMonIds[_msgSender()].pop();

//         /**
//          * @dev Removal of NBMon from nbmons array. This will only be a simple delete and therefore will leave a gap in the array with a string of "0".
//          *
//          * Since the nbmons array starts from 1 and gets incremented by 1, we do not need to check for the index of the _nbmonId in the array.
//          *
//          * Although leaving a gap, this is the most cost-efficient way of deleting an element from an array, especially when the nbmons array becomes too large in length when there are 
//          * a lot of NBMons minted already.
//          *
//          * Note: @dev When calculating this in the backend, ensure only to load NBMons that do NOT have a string of "0" from the nbmons array. This means that they are removed and burned.
//          */
//         delete genesisNBMons[_nbmonId - 1];
        
//         emit GenesisNBMonBurned(_nbmonId);
//     }

// }