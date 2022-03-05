//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./NBMonCore.sol";

/**
 * @dev Contract used for NBMon minting logic
 */
abstract contract NBMonMinting is NBMonCore {

    /// @dev Emitted when breeding is set to 'allowed'. Triggered by _owner. 
    event MintingAllowed(address _owner);
    /// @dev Emitted when breeding is set to 'not allowed'. Triggered by _owner.
    event MintingNotAllowed(address _owner);

    bool public _mintingAllowed;

    modifier whenMintingAllowed() {
        require(_mintingAllowed, "NBMonMinting: Minting enabled.");
        _;
    }

    modifier whenMintingNotAllowed() {
        require(!_mintingAllowed, "NBMonMinting: Minting disabled.");
        _;
    }

    function allowMinting() public whenMintingNotAllowed onlyAdmin {
        _mintingAllowed = true;
        emit MintingAllowed(_msgSender());
    }

    function disallowMinting() public whenMintingAllowed onlyAdmin {
        _mintingAllowed = false;
        emit MintingNotAllowed(_msgSender());
    }


    

    // calls _mintNBMon.
    function mintNBMon(
        uint256[] memory _parents,
        address _owner,
        bool[] memory _access,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves,
        bool _isEgg
    ) public whenMintingAllowed onlyMinter {
        _mintNBMon(_parents, _owner, _access, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _inheritedPassives, _inheritedMoves, _isEgg);
    }

     /**
     * @dev Mints an NBMon, either from minting events or from breeding. If through breeding, the stats will be empty and isEgg will be set to true until it can hatch.
     */
    function _mintNBMon(
        uint256[] memory _parents,
        address _owner,
        bool[] memory _access,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves,
        bool _isEgg
    ) private {
        NBMon memory _nbmon = NBMon(
            currentNBMonCount,
            _parents,
            _owner,
            _access,
            block.timestamp,
            block.timestamp,
            _hatchingDuration,
            _nbmonStats,
            _types,
            _potential,
            _passives,
            _inheritedPassives,
            _inheritedMoves,
            _isEgg
        );
        _safeMint(_owner, currentNBMonCount);
        nbmons.push(_nbmon);
        ownerNBMonIds[_owner].push(currentNBMonCount);
        emit NBMonMinted(currentNBMonCount, _owner);
        currentNBMonCount++;
    }  
}