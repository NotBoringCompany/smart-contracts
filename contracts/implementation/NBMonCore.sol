//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../BEP721/NFTCore.sol";
import "../security/Ownable.sol";

/**
 * @dev Base contract for NBMon which contains all functionality and methods related with our Realm Hunter game and
 * any others that are spinoffs with the same IPs
 */
contract NBMonCore is NFTCore {
    constructor() BEP721("NBMon", "NBMON") {
        // sets URI of NBMons (the chain before "nbmon" is dependant on which blockchain this contract is deployed in).
        setBaseURI("https://marketplace.nbcompany.io/bscTestnet/nbmon/");
    }

    /**
     * @dev Instance of an NBMon with detailed stats instantiated as a struct
     */
    struct NBMon {
        // tokenId for NBMon
        uint256 nbmonId;
        // current owner for NBMon, alternatively use BEP721.ownerOf.
        address owner;
        // when minted through minting events, this will be bornAt. Otherwise, this refers to the time that the NBMon is minted after the egg is hatched.
        uint256 hatchedAt;
        // timestamp of when NBMon was transferred to current owner (when selling in marketplace, transferring from wallet etc)
        uint256 transferredAt;
        // contains gender, rarity, mutation, species, evolveDuration, genera and fertility
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
    }

    /**
     * @dev Instance of an NBMon Egg. NBMon Eggs are essentially NBMons before they hatch and evolve to an adult NBMon.
     */
    struct NBMonEgg {
        uint256 eggId;
        address owner;
        uint256 bornAt;
    }

    NBMon[] internal nbmons;
    NBMonEgg[] public nbmonEggs;

    // mapping from owner address to array of IDs of the NBMons the owner owns
    mapping(address => uint256[]) internal ownerNBMonIds;
    // mapping from owner address to list of NBMons owned;
    mapping(address => NBMon[]) internal ownerNBMons;

    // mapping from owner address to array of IDs of the NBMons the owner owns
    mapping(address => uint256[]) internal ownerNBMonEggIds;
    // mapping from owner address to list of NBMons owned;
    mapping(address => NBMonEgg[]) internal ownerNBMonEggs;
    
    // checks the current NBMon supply for enumeration. Starts at 1 when contract is deployed.
    uint256 public currentNBMonCount = 1;

    event NBMonMinted(uint256 indexed _nbmonId, address indexed _owner);
    event NBMonBurned(uint256 indexed _nbmonId);

    event NBMonEggMinted(uint256 indexed _eggId, address indexed _owner);
    event NBMonEggBurned(uint256 indexed _eggId);

    // returns a single NBMon given an ID
    function getNBMon(uint256 _nbmonId) public view returns (NBMon memory) {
        require(_exists(_nbmonId), "NBMonCore: NBMon with the specified ID does not exist");
        return nbmons[_nbmonId - 1];
    }

    // returns all NBMons owned by the owner
    function getAllNBMonsOfOwner(address _owner) public view returns (NBMon[] memory) {
        return ownerNBMons[_owner];
    }

    // returns the NBMon IDs of the owner's NBMons
    function getOwnerNBMonIds(address _owner) public view returns (uint256[] memory) {
        return ownerNBMonIds[_owner];
    }

    // burns and deletes the NBMon from circulating supply
    function burnNBMon(uint256 _nbmonId) public {
        require(_exists(_nbmonId), "NBMonCore: Burning non-existant NBMon");
        require(nbmons[_nbmonId - 1].owner == _msgSender(), "NBMonCore: Owner does not own specified NBMon.");
        _burn(_nbmonId);

        emit NBMonBurned(_nbmonId);
    }

    // returns a single NBMon Egg given an ID
    function getNBMonEgg(uint256 _eggId) public view returns (NBMonEgg memory) {
        require(_exists(_eggId), "NBMonEggCore: NBMon Egg with the specified ID does not exist");
        return nbmonEggs[_eggId - 1];
    }

    // returns all NBMon Eggs owned by the owner
    function getAllNBMonEggsOfOwner(address _owner) public view returns (NBMonEgg[] memory) {
        return ownerNBMonEggs[_owner];
    }

    // returns the NBMon Egg IDs of the owner's NBMons
    function getOwnerNBMonEggIds(address _owner) public view returns (uint256[] memory) {
        return ownerNBMonEggIds[_owner];
    }

    // burns and deletes the NBMon Egg from circulating supply
    function burnNBMonEgg(uint256 _eggId) public {
        require(_exists(_eggId), "NBMonEggCore: Burning non-existant NBMon Egg");
        require(nbmonEggs[_eggId - 1].owner == _msgSender(), "NBMonEggCore: Owner does not own specified NBMon Egg.");
        _burn(_eggId);

        emit NBMonEggBurned(_eggId);
    }

    /**
     * @dev Singular purpose functions designed to make reading code easier for front-end
     * Otherwise not needed since getNBMon and getAllNBMonsOfOwner and getNBMon contains complete information at once
     */
    function getNbmonStats(uint256 _nbmonId) public view returns (string[] memory) {
        return nbmons[_nbmonId - 1].nbmonStats;
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
}