//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../BEP721/NFTCore.sol";

/**
 * @dev NBMonEgg is a placeholder for all offspring that are hatched from breeding two NBMons. After a certain duration, the eggs will be able to be converted to 
 * adult NBMons. This will destroy the egg and mint a new NBMon.
 */
contract NBMonEggCore is NFTCore {
    constructor() BEP721("NBMon Egg", "NBMONEGG") {
        setBaseURI("https://marketplace.nbcompany.io/bscTestnet/nbmon/egg/");
    }

    /**
     * @dev Instance of an NBMon egg
     */
    struct NBMonEgg {
        // token ID for the egg
        uint256 eggId;
        // owner of the egg
        address owner;
        // timestamp of when egg is minted
        uint256 bornAt;
    }

    NBMonEgg[] public nbmonEggs;

    // mapping from owner address to array of IDs of the NBMons the owner owns
    mapping(address => uint256[]) internal ownerNBMonEggIds;
    // mapping from owner address to list of NBMons owned;
    mapping(address => NBMonEgg[]) internal ownerNBMonEggs;

    event NBMonEggMinted(uint256 indexed _eggId, address indexed _owner);
    event NBMonEggBurned(uint256 indexed _eggId);

    // returns a single NBMon Egg given an ID
    function getNBMonEgg(uint256 _eggId) public view returns (NBMonEgg memory) {
        require(_exists(_eggId), "NBMonCore: NBMon with the specified ID does not exist");
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
        require(_exists(_eggId), "NBMonCore: Burning non-existant NBMon");
        require(nbmonEggs[_eggId - 1].owner == _msgSender(), "NBMonCore: Owner does not own specified NBMon.");
        _burn(_eggId);

        emit NBMonEggBurned(_eggId);
    }
}