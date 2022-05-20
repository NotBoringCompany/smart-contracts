// //SPDX-License-Identifier: MIT

// pragma solidity ^0.8.13;

// import "./GenesisNBMonCore.sol";

// contract GenesisNBMonMinting is GenesisNBMonCore {
//     constructor() BEP721("Genesis NBMon", "G-NBMON") {
//         // this base URI will only be temporary. it will change during proper deployment.
//         setBaseURI("https://marketplace.nbcompany.io/nbmons/genesis/");
//         _mintingAllowed = true;
//     }

//     /// @dev Emitted when breeding is set to 'allowed'. Triggered by _owner. 
//     event MintingAllowed(address _owner);
//     /// @dev Emitted when breeding is set to 'not allowed'. Triggered by _owner.
//     event MintingNotAllowed(address _owner);

//     bool public _mintingAllowed;

//     modifier whenMintingAllowed() {
//         require(_mintingAllowed, "NBMonMinting: Minting enabled.");
//         _;
//     }

//     modifier whenMintingNotAllowed() {
//         require(!_mintingAllowed, "NBMonMinting: Minting disabled.");
//         _;
//     }

//     function allowMinting() public whenMintingNotAllowed onlyAdmin {
//         _mintingAllowed = true;
//         emit MintingAllowed(_msgSender());
//     }

//     function disallowMinting() public whenMintingAllowed onlyAdmin {
//         _mintingAllowed = false;
//         emit MintingNotAllowed(_msgSender());
//     }

//     function mintGenesisNBMon(
//         address _owner,
//         uint32 _hatchingDuration,
//         string[] memory _nbmonStats,
//         string[] memory _types,
//         uint8[] memory _potential,
//         string[] memory _passives,
//         bool _isEgg
//     ) public onlyMinter whenMintingAllowed {
//         _mintGenesisNBMon(_owner, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
//     }
//     function _mintGenesisNBMon(
//         address _owner,
//         uint32 _hatchingDuration,
//         string[] memory _nbmonStats,
//         string[] memory _types,
//         uint8[] memory _potential,
//         string[] memory _passives,
//         bool _isEgg
//     ) private {
//         GenesisNBMon memory _genesisNBMon = GenesisNBMon(
//             currentGenesisNBMonCount,
//             _owner,
//             block.timestamp,
//             block.timestamp,
//             _hatchingDuration,
//             _nbmonStats,
//             _types,
//             _potential,
//             _passives,
//             _isEgg
//         );
//         _safeMint(_owner, currentGenesisNBMonCount);
//         genesisNBMons.push(_genesisNBMon);
//         ownerGenesisNBMonIds[_owner].push(currentGenesisNBMonCount);
//         emit GenesisNBMonMinted(currentGenesisNBMonCount, _owner);
//         currentGenesisNBMonCount++;
//     }

//     function hatchFromEgg(
//         uint256 _nbmonId,
//         string[] memory _nbmonStats,
//         string[] memory _types,
//         uint8[] memory _potential,
//         string[] memory _passives
//     ) public {
//         require(_exists(_nbmonId), "GenensisNBMonMinting: Specified NBMon does not exist");
//         GenesisNBMon storage _genesisNBMon = genesisNBMons[_nbmonId - 1];
        
//         require(_genesisNBMon.owner == _msgSender(), "GenesisNBMonMinting: Owner does not own specified NBMon");
//         require(_genesisNBMon.isEgg == true, "GenesisNBMonMinting: NBMon is not an egg anymore");
//         require(_genesisNBMon.hatchedAt + _genesisNBMon.hatchingDuration <= block.timestamp, "GenesisNBMonMinting: Egg is not ready to hatch yet");

//         //updates all the stats of the genesis NBMon
//         _genesisNBMon.hatchedAt = block.timestamp;
//         _genesisNBMon.nbmonStats = _nbmonStats;
//         _genesisNBMon.types = _types;
//         _genesisNBMon.potential = _potential;
//         _genesisNBMon.passives = _passives;
//         _genesisNBMon.isEgg = false;
//     }
// }