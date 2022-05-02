//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../BEP721/NFTCore.sol";

/**
 * @dev Base contract for NBMon which contains all functionality and methods related with our Realm Hunter game and
 * any others that are spinoffs with the same IPs.
 * NBMonCore does NOT use BEP721Enumerable, rather has its own version of enumeration.
 */
abstract contract NBMonCore is NFTCore {
    /**
     * @dev Instance of an NBMon with detailed stats instantiated as a struct
     */
    struct NBMon {
        // tokenId for NBMon
        uint256 nbmonId;
        
        // shows parents of NBMon (only through breeding)
        uint256[] parents;

        // current owner for NBMon, alternatively use BEP721.ownerOf.
        address owner;

        // access[0] checks for tradability (marketplace access), access[1] checks for breedability (ability to breed)
        bool[] access;

        // when minted through minting events, this will be bornAt. Otherwise, this refers to the time that the NBMon is minted after the egg is hatched.
        uint256 hatchedAt;

        // timestamp of when NBMon was transferred to current owner (when selling in marketplace, transferring from wallet etc)
        uint256 transferredAt;

        // time (in seconds) it takes to hatch from the egg (depends on rarity). If minted through an event (no egg), then hatchingDuration will be 0.
        uint32 hatchingDuration;

        // contains gender, rarity, mutation, species, genera and fertility
        // check '../gamestats/genders.txt' for more info.
        // check '../gamestats/rarity.txt' for more info.
        // check '../gamestats/mutation.txt' for more info.
        // check '../gamestats/species.txt' for more info.
        // check '../gamestats/genera.txt' for more info.
        // check '../gamestats/fertility.txt' for more info
        string[] nbmonStats;

        // Each NBMon can have up to two types. types are predetermined depending on the genus.
        // more on types at '../gamestats/types.txt'
        string[] types;

        /// @dev contains all of the potential of the NBMon
        /// including health pool, energy, attack, defense, special attack, special defense, speed
        /// check '../gamestats/potential.txt' for more info.
        uint8[] potential;

        /// @dev contains the passives of the NBMon
        // when minted, it will pick 2 of the available passives.
        // all available passives are found in '../gamestats/passives.txt'
        string[] passives;

        // only used for breeding to inherit 2 passives from the passive set of the parent NBMons
        // if minted, it will be an empty array
        // check '../gamestats/passives.txt' for more info
        string[] inheritedPassives;

        // only used for breeding to inherit 2 moves from the move set of the parent NBMons
        // if minted, it will be an empty array
        // check '../gamestats/moveset.txt' for more info
        string[] inheritedMoves;

        // equals true if the NBMon is still in its egg form. An egg will be hatchable within a certain amount of days (depending on rarity).
        // once hatched, isEgg will be set to false and all other stats will be filled.
        bool isEgg; 
    }

    NBMon[] internal nbmons;

    // mapping from owner address to array of IDs of the NBMons the owner owns
    mapping(address => uint256[]) internal ownerNBMonIds;
    
    // checks the current NBMon supply for enumeration. Starts at 1 when contract is deployed.
    uint256 internal currentNBMonCount = 1;

    event NBMonMinted(uint256 indexed _nbmonId, address indexed _owner);
    event NBMonBurned(uint256 indexed _nbmonId);


    // returns an NBMon given an ID
    function getNBMon(uint256 _nbmonId) public view returns (NBMon memory) {
        require(_exists(_nbmonId), "NBMonCore: NBMon with the specified ID does not exist");
        return nbmons[_nbmonId - 1];
    }

    // returns the NBMon IDs of the owner's NBMons
    function getOwnerNBMonIds(address _owner) public view returns (uint256[] memory) {
        return ownerNBMonIds[_owner];
    }

    // burns and deletes the NBMon from circulating supply
    function burnNBMon(uint256 _nbmonId) public {
        // ensures that nbmon exists
        require(_exists(_nbmonId), "NBMonCore: Burning non-existant NBMon");
        // checks if the caller of the function owns the specified _nbmonId
        require(nbmons[_nbmonId - 1].owner == _msgSender(), "NBMonCore: Owner does not own specified NBMon.");
        // burns the nbmon
        BEP721URIStorage._burn(_nbmonId);

        /**
         * @dev removal of NBMon ID from owner's list of owned NBMons (ownerNBMonIds).
         * Note: Array formation will however be altered.
         */

        // find the index of _nbmonId from the array
        uint256 _nbmonIdIndex;
        for (uint i = 0; i < ownerNBMonIds[_msgSender()].length; i++) {
            // if the "i"th index of the array contains _nbmonId, add to _nbmonIdIndex and finish the loop
            if (ownerNBMonIds[_msgSender()][i] == _nbmonId) {
                _nbmonIdIndex = i;
                break;
            }
        }
        // then swap the last index's NBMon Id with the current index
        uint256 _lastNbmonIdIndex = ownerNBMonIds[_msgSender()].length - 1;
        (ownerNBMonIds[_msgSender()][_nbmonIdIndex], ownerNBMonIds[_msgSender()][_lastNbmonIdIndex]) = (ownerNBMonIds[_msgSender()][_lastNbmonIdIndex], ownerNBMonIds[_msgSender()][_nbmonIdIndex]);

        //delete the last item (which is the NBMon Id to be burnt)
        ownerNBMonIds[_msgSender()].pop();

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
        delete nbmons[_nbmonId - 1];
        
        emit NBMonBurned(_nbmonId);
    }

    /**
     * @dev Singular purpose functions designed to make reading code easier for front-end
     * Otherwise not needed since getNBMon can be used.
     */
    function getNbmonStats(uint256 _nbmonId) public view returns (string[] memory) {
        return nbmons[_nbmonId - 1].nbmonStats;
    }
    function getAccess(uint256 _nbmonId) public view returns (bool[] memory) {
        return nbmons[_nbmonId - 1].access;
    }
    function getParents(uint256 _nbmonId) public view returns (uint256[] memory) {
        return nbmons[_nbmonId - 1].parents;
    }
    function getHatchingDuration(uint256 _nbmonId) public view returns (uint32) {
        return nbmons[_nbmonId - 1].hatchingDuration;
    }
    function getHatchedAt(uint256 _nbmonId) public view returns (uint256) {
        return nbmons[_nbmonId - 1].hatchedAt;
    }
    function getTransferredAt(uint256 _nbmonId) public view returns (uint256) {
        return nbmons[_nbmonId - 1].transferredAt;
    }
    function getTypes(uint256 _nbmonId) public view returns (string[] memory) {
        return nbmons[_nbmonId - 1].types;
    }
    function getPotential(uint256 _nbmonId) public view returns (uint8[] memory) {
        return nbmons[_nbmonId - 1].potential;
    }
    function getPassives(uint256 _nbmonId) public view returns (string[] memory) {
        return nbmons[_nbmonId - 1].passives;
    }
    function getInheritedPassives(uint256 _nbmonId) public view returns (string[] memory) {
        return nbmons[_nbmonId - 1].inheritedPassives;
    }
    function getInheritedMoves(uint256 _nbmonId) public view returns (string[] memory) {
        return nbmons[_nbmonId - 1].inheritedMoves;
    }

    function getIsEgg(uint256 _nbmonId) public view returns (bool) {
        return nbmons[_nbmonId - 1].isEgg;
    }
}