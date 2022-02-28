//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./NBMonCore.sol";

contract NBMonMinting is NBMonCore {

    constructor() {
        _mintingAllowed = true;
    }

    bool public _mintingAllowed;

    modifier whenMintingAllowed() {
        require(_mintingAllowed, "NBMonMinting: Minting is currently disabled.");
        _;
    }

    // calls _mintEgg.
    function mintEgg(address _owner) public whenMintingAllowed onlyMinter {
        _mintEgg(_owner);
    }

    // mints an NBMonEgg (from breeding).
    function _mintEgg(address _owner) private {
        NBMonEgg memory _nbmonEgg = NBMonEgg(
            currentNBMonCount,
            _owner,
            block.timestamp
        );
        nbmonEggs.push(_nbmonEgg);
        ownerNBMonEggs[_owner].push(_nbmonEgg);
        _safeMint(_owner, currentNBMonCount);
        ownerNBMonEggIds[_owner].push(currentNBMonCount);
        emit NBMonEggMinted(currentNBMonCount, _owner);
        currentNBMonCount++;
    }

    // calls _mintNBMonFromEgg.
    function mintNBMonFromEgg(
        address _owner,
        uint256 _eggId,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves
    ) public whenMintingAllowed onlyMinter {
        _mintNBMonFromEgg(_owner, _eggId, _nbmonStats, _types, _potential, _passives, _inheritedPassives, _inheritedMoves);
    }

    // calls _mintNBMon.
    function mintNBMon(
        address _owner,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves
    ) public whenMintingAllowed onlyMinter {
        _mintNBMon(_owner, _nbmonStats, _types, _potential, _passives, _inheritedPassives, _inheritedMoves);
    }

     /**
     * @dev Mints an NBMon from minting events.
     */
    function _mintNBMon(
        address _owner,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves
    ) private {
        NBMon memory _nbmon = NBMon(
            currentNBMonCount,
            _owner,
            block.timestamp,
            block.timestamp,
            _nbmonStats,
            _types,
            _potential,
            _passives,
            _inheritedPassives,
            _inheritedMoves
        );
        nbmons.push(_nbmon);
        ownerNBMons[_owner].push(_nbmon);
        _safeMint(_owner, currentNBMonCount);
        ownerNBMonIds[_owner].push(currentNBMonCount);
        emit NBMonMinted(currentNBMonCount, _owner);
        currentNBMonCount++;
    }
    
    /**
     * @dev Mints an NBMon FROM AN EGG after it is hatchable (done by breeding). The egg will be burned.
     */
    function _mintNBMonFromEgg(
        address _owner,
        uint256 _eggId,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        string[] memory _inheritedPassives,
        string[] memory _inheritedMoves
    ) private {
        NBMon memory _nbmon = NBMon(
            _eggId,
            _owner,
            block.timestamp,
            block.timestamp,
            _nbmonStats,
            _types,
            _potential,
            _passives,
            _inheritedPassives,
            _inheritedMoves
        );
        burnNBMonEgg(_eggId);
        nbmons.push(_nbmon);
        ownerNBMons[_owner].push(_nbmon);
        _safeMint(_owner, _eggId);
        ownerNBMonIds[_owner].push(_eggId);
        emit NBMonMinted(_eggId, _owner);
    }
}