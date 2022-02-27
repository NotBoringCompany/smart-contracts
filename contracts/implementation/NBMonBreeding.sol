//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../security/Strings.sol";
import "./NBMonMinting.sol";

/**
 * @dev This contract is used as a basis for the breeding logic for NBMonCore.
 * This contract does NOT have any of the advanced features yet (e.g. using artifacts to boost certain stats when breeding).
 * Note: Some of the values/variables here are hard-coded based on current logic from the different .txt files. Should there be any change:
 * a new breeding contract will replace this since it will NOT affect the main NBMonCore contract. 
 */
contract NBMonBreeding is NBMonMinting {
    /// @dev Emitted when breeding is set to 'allowed'. Triggered by _owner. 
    event BreedingAllowed(address _owner);
    /// @dev Emitted when breeding is set to 'not allowed'. Triggered by _owner.
    event BreedingNotAllowed(address _owner);

    bool public _breedingAllowed;

    constructor() {
        // allows breeding during contract deployment.
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
     * @dev breeds 2 NBMons to give birth to an offspring
     * _maleId NEEDS to be a male and _femaleId needs to be a female for simplicity sake (from current gender logic)
     * this requirement will be implemented in the frontend
     * Note: All calculations will be done in the backend
     */
    function breedNBMon(
        uint256 _maleId,
        uint256 _femaleId,
        address _owner,
        uint32[] memory _nbmonStats,
        uint8[] memory _types,
        uint8[] memory _potential,
        uint16[] memory _passives,
        uint8[] memory _inheritedPassives,
        uint8[] memory _inheritedMoves
    ) public whenBreedingAllowed {
        NBMon memory _maleParent = nbmons[_maleId - 1];
        NBMon memory _femaleParent = nbmons[_femaleId - 1];

        // checks if caller/msg.sender owns both NBMons. Fails and reverts if requirement is not met.
        require(_maleParent.owner == _msgSender() && _femaleParent.owner == _msgSender(), "NBMonBreeding: Caller does not own both NBMons");

        // double checking that male parent and female parent have different genders 
        // most likely not required but is added just in case to save gas fees and revert the transaction here if requirement is not met
        require(_maleParent.nbmonStats[0] != _femaleParent.nbmonStats[0], "NBMonBreeding: Gender needs to be different");
        require(_maleParent.nbmonStats[0] == 1, "NBMonBreeding: Male parent is not a male gender");
        require(_femaleParent.nbmonStats[0] == 2, "NBMonBreeding: Female parent is not a female gender");

        mintNBMon(_owner, _nbmonStats, _types, _potential, _passives, _inheritedPassives, _inheritedMoves, true);
    }

    /**
     * @dev Evolves 
     */
    function evolveFromEgg(uint256 _nbmonId) public {
        
    }
}