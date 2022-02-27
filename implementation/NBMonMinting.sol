//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./NBMonCore.sol";

/**
 * @dev Base contract used for minting NBMons. 
 */
contract NBMonMinting is NBMonCore {

    bool public _mintingAllowed;

    modifier whenMintingAllowed() {
        require(_mintingAllowed, "NBMonMinting: Minting is currently disabled.");
        _;
    }

    constructor() {
        _mintingAllowed = true;
    }

    // calls _mintNBMon.
    function mintNBMon(
        address _owner,
        uint32[] memory _nbmonStats,
        uint8[] memory _types,
        uint8[] memory _potential,
        uint16[] memory _passives,
        uint8[] memory _inheritedPassives,
        uint8[] memory _inheritedMoves
    ) public whenMintingAllowed onlyMinter {
        _mintNBMon(_owner, _nbmonStats, _types, _potential, _passives, _inheritedPassives, _inheritedMoves);
    }

     /**
     * @dev Mints an NBMon.
     * Calculations will be done from our backend.
     */
    function _mintNBMon(
        address _owner,
        uint32[] memory _nbmonStats,
        uint8[] memory _types,
        uint8[] memory _potential,
        uint16[] memory _passives,
        uint8[] memory _inheritedPassives,
        uint8[] memory _inheritedMoves
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
            _inheritedMoves,
            false
        );
        nbmons.push(_nbmon);
        ownerNBMons[_owner].push(_nbmon);
        _safeMint(_owner, currentNBMonCount);
        ownerNBMonIds[_owner].push(currentNBMonCount);
        currentNBMonCount++;
        ownerNBMonCount[_owner]++;
        emit NBMonMinted(currentNBMonCount, _owner);

    }
}