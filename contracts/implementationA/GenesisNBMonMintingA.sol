//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./GenesisNBMonCoreA.sol";

contract GenesisNBMonMintingA is GenesisNBMonCoreA {
    constructor() BEP721A("Genesis NBMon", "G-NBMON") {
        // this base URI will only be temporary. it will change during proper deployment.
        setBaseURI("https://marketplace.nbcompany.io/nbmons/genesis/");
        _mintingAllowed = true;
        mintLimit = 1;
        supplyLimit = 5000;
    }

    /// @dev Emitted when breeding is set to 'allowed'. Triggered by _owner. 
    event MintingAllowed(address _owner);
    /// @dev Emitted when breeding is set to 'not allowed'. Triggered by _owner.
    event MintingNotAllowed(address _owner);

    bool public _mintingAllowed;

    modifier whenMintingAllowed() {
        require(_mintingAllowed, "GenesisNBMonMintingA: Minting enabled.");
        _;
    }

    modifier whenMintingNotAllowed() {
        require(!_mintingAllowed, "GenesisNBMonMintingA: Minting disabled.");
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

    // checks whether a given address is whitelisted to mint a Genesis NBMon
    mapping (address => bool) whitelisted;
    // checks how many NBMon eggs the address has minted. if it already reaches the limit, the address cannot mint anymore.
    mapping (address => uint8) amountMinted;

    // limits the mint amount per person, regardless if whitelisted or not
    uint8 public mintLimit;

    // limits the supply of the genesis NBMons. Cannot mint more than this amount ever.
    uint16 public supplyLimit;

    // admin only function to whitelist an address
    function whitelistAddress(address _to) public onlyAdmin {
        whitelisted[_to] = true;
    }

    function removeWhitelistAddress(address _to) public onlyAdmin {
        whitelisted[_to] = false;
    }

    // a modifier for minting to ensure the caller is either whitelisted or the minter
    modifier isWhitelisted(address _to) {
        require(whitelisted[_to] == true , "GenesisNBMonMintingA: _to is not whitelisted.");
        _;
    }
    
    // changes the mint limit
    function changeMintLimit(uint8 _mintLimit) public onlyAdmin {
        mintLimit = _mintLimit;
    }

    // a modifier for minting to ensure that the caller does not mint more than the specified mint limit
    modifier belowMintLimit(address _to) {
        require(amountMinted[_to] < mintLimit, "GenesisNBMonMintingA: Mint limit per user exceeded. Cannot mint more.");
        _;
    }

    // a modifier for minting to ensure that the current supply is less than the allowed supply limit for genesis NBMons
    modifier belowSupplyLimit() {
        require(totalSupply() < supplyLimit, "GenesisNBMonMintingA: Supply limit reached. Cannot mint more.");
        _;
    }

    // mints a genesis egg (for whitelisted people)
    function whitelistedGenesisEggMint(
        address _owner,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) public onlyMinter isWhitelisted(_owner) belowMintLimit(_owner) belowSupplyLimit whenMintingAllowed {
        _mintGenesisEgg(_owner, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
        amountMinted[_owner]++;
    }

    // mints a genesis egg (for public)
    function _publicGenesisEggMint(
        address _owner,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) public onlyMinter belowMintLimit(_owner) belowSupplyLimit whenMintingAllowed {
        _mintGenesisEgg(_owner, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
        amountMinted[_owner]++;
    }

    function _mintGenesisEgg(
        address _owner,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) private {
        GenesisNBMon memory _genesisNBMon = GenesisNBMon(
            currentGenesisNBMonCount,
            _owner,
            block.timestamp,
            block.timestamp,
            _hatchingDuration,
            _nbmonStats,
            _types,
            _potential,
            _passives,
            _isEgg
        );
        _safeMint(_owner, 1);
        genesisNBMons.push(_genesisNBMon);
        ownerGenesisNBMonIds[_owner].push(currentGenesisNBMonCount);
        emit GenesisNBMonMinted(currentGenesisNBMonCount, _owner);
        currentGenesisNBMonCount++;
    }

    function hatchFromEgg(
        uint256 _nbmonId,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives
    ) public {
        require(_exists(_nbmonId), "GenensisNBMonMinting: Specified NBMon does not exist");
        GenesisNBMon storage _genesisNBMon = genesisNBMons[_nbmonId - 1];
        
        require(_genesisNBMon.owner == _msgSender(), "GenesisNBMonMinting: Owner does not own specified NBMon");
        require(_genesisNBMon.isEgg == true, "GenesisNBMonMinting: NBMon is not an egg anymore");
        require(_genesisNBMon.hatchedAt + _genesisNBMon.hatchingDuration <= block.timestamp, "GenesisNBMonMinting: Egg is not ready to hatch yet");

        //updates all the stats of the genesis NBMon
        _genesisNBMon.hatchedAt = block.timestamp;
        _genesisNBMon.nbmonStats = _nbmonStats;
        _genesisNBMon.types = _types;
        _genesisNBMon.potential = _potential;
        _genesisNBMon.passives = _passives;
        _genesisNBMon.isEgg = false;
    }
}