//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../security/Strings.sol";
import "./NBMonMinting.sol";

/**
 * @dev This contract is used as a basis for the breeding logic for NBMonCore.
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
     * @dev breeds 2 NBMons to give off an egg. This egg will have no stats of the actual NBMon until it is allowed to be hatched (minted).
     */
    function breedNBMon(
        uint256 _maleId,
        uint256 _femaleId,
        address _owner
    ) public whenBreedingAllowed {
        NBMon memory _maleParent = nbmons[_maleId - 1];
        NBMon memory _femaleParent = nbmons[_femaleId - 1];

        // checks if caller/msg.sender owns both NBMons. Fails and reverts if requirement is not met.
        require(_maleParent.owner == _msgSender() && _femaleParent.owner == _msgSender(), "NBMonBreeding: Caller does not own both NBMons");

        // double checking that male parent and female parent have different genders 
        // most likely not required but is added just in case to save gas fees and revert the transaction here if requirement is not met
        require(keccak256(abi.encodePacked(_maleParent.nbmonStats[0])) == "male", "NBMonBreeding: Male parent is not a male gender");
        require(keccak256(abi.encodePacked(_femaleParent.nbmonStats[0])) == "female", "NBMonBreeding: Female parent is not a female gender");

        mintEgg(_owner);
    }

    /**
     * @dev Evolves from an egg and mints the actual NBMon with stats. 
     */
    function evolveFromEgg(
        uint256 _eggId,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves
    ) public {
        //checks if the owner owns the specified _eggId
        require(nbmonEggs[_eggId - 1].owner == _msgSender(), "NBMonBreeding: Owner does not own the specified egg ID");
        mintNBMonFromEgg(_msgSender(), _eggId, _nbmonStats, _types, _potential, _passives, _inheritedPassives, _inheritedMoves);
    }
}