//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../security/Strings.sol";
import "./NBMonMinting.sol";

/**
 * @dev This contract is used as a basis for breeding logic. Inherits from NBMonMinting (contract for minting based logic), which inherits from NBMonCore (everything to do with NBMons). 
 */
contract NBMonBreeding is NBMonMinting {

    /// @dev Emitted when breeding is set to 'allowed'. Triggered by _owner. 
    event BreedingAllowed(address _owner);
    /// @dev Emitted when breeding is set to 'not allowed'. Triggered by _owner.
    event BreedingNotAllowed(address _owner);

    bool public _breedingAllowed;

    constructor() BEP721("NBMon", "NBMON") {
        setBaseURI("https://marketplace.nbcompany.io/nbmons/");
        _mintingAllowed = true;
        _breedingAllowed = true;
    }

    // modifier for functions that require _breedingAllowed to be true to continue.
    modifier whenBreedingAllowed() {
        require(_breedingAllowed, "NBMonBreedingExtended: Breeding allowed");
        _;
    }

    // modifier for functions that require _breedingAllowed to be false to continue.
    modifier whenBreedingNotAllowed() {
        require(!_breedingAllowed, "NBMonBreeding: Breeding not allowed");
        _;
    }

    // allows breeding when breeding is currently disallowed.
    function allowBreeding() public whenBreedingNotAllowed onlyAdmin {
        _breedingAllowed = true;
        emit BreedingAllowed(_msgSender());
    }

    // disallows breeding when breeding is currently allowed.
    function disallowBreeding() public whenBreedingAllowed onlyAdmin {
        _breedingAllowed = false;
        emit BreedingNotAllowed(_msgSender());
    }

    /**
     * @dev breeds 2 NBMons to give off an egg. This egg will have no stats of the actual NBMon until it is allowed to be hatched.
     */
    function breedNBMon(
        uint256 _maleId,
        uint256 _femaleId,
        // rarity will determine the hatching duration. therefore, the user will know what rarity the nbmon has.
        uint32 _hatchingDuration,
        // will only contain rarity. other stats within nbmonStats will be empty for now.
        string[] memory _nbmonStats,
        string memory _maleFertilityAfter,
        string memory _femaleFertilityAfter
    ) public whenBreedingAllowed whenMintingAllowed {
        NBMon storage _maleParent = nbmons[_maleId - 1];
        NBMon storage _femaleParent = nbmons[_femaleId - 1];

        // checks if caller/msg.sender owns both NBMons. Fails and reverts if requirement is not met.
        require(_maleParent.owner == _msgSender() && _femaleParent.owner == _msgSender(), "NBMonBreeding: Caller does not own both NBMons");

        // double checking that male parent and female parent have different genders 
        // most likely not required but is added just in case to save gas fees and revert the transaction here if requirement is not met
        require(keccak256(abi.encodePacked(_maleParent.nbmonStats[0])) == keccak256(abi.encodePacked("male")), "NBMonBreeding: Male parent is not a male gender");
        require(keccak256(abi.encodePacked(_femaleParent.nbmonStats[0])) == keccak256(abi.encodePacked("female")), "NBMonBreeding: Female parent is not a female gender");

        /**
         * @dev Reduces fertility points of both parents to mint the NBMon egg.
         */
        _maleParent.nbmonStats[6] = _maleFertilityAfter;
        _femaleParent.nbmonStats[6] = _femaleFertilityAfter;

        // create an instance of the parents array
        uint256[] memory _parents = new uint256[](2);
        _parents[0] = _maleId;
        _parents[1] = _femaleId;

        
        // mints an nbmon in the form of an egg (isEgg == true). instantiates multiple empty arrays since they will only be added when hatched.
        mintNBMon(_parents, _msgSender(), _hatchingDuration, _nbmonStats, new string[](0), new uint8[](0), new string[](0), new string[](0), new string[](0), true);
    }

    /**
     * @dev Hatches from an egg and mints the actual NBMon with stats. 
     */
    function hatchFromEgg(
        uint256 _nbmonId,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves
    ) public {
        NBMon storage _nbmon = nbmons[_nbmonId];

        require(_nbmon.owner == _msgSender(), "NBMonBreeding: Caller does not own specified NBMon.");
        require(_nbmon.hatchedAt + _nbmon.hatchingDuration >= block.timestamp, "NBMonBreeding: Egg is not ready to hatch yet.");

        // updates all the stats of the NBMon
        _nbmon.hatchedAt = block.timestamp;
        _nbmon.nbmonStats = _nbmonStats;
        _nbmon.types = _types;
        _nbmon.potential = _potential;
        _nbmon.passives = _passives;
        _nbmon.inheritedPassives = _inheritedPassives;
        _nbmon.inheritedMoves = _inheritedMoves;
        _nbmon.isEgg = false;
    }
}