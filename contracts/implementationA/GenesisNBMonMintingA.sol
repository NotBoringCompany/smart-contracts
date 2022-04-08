//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./GenesisNBMonCoreA.sol";
import "../security/ReentrancyGuard.sol";

contract GenesisNBMonMintingA is GenesisNBMonCoreA, ReentrancyGuard {
    constructor() BEP721A("Genesis NBMon", "G-NBMON") {
        // this base URI will only be temporary. it will change during proper deployment.
        setBaseURI("https://marketplace.nbcompany.io/nbmons/genesis/");
        _mintingAllowed = true;
        // 0.15 ETH
        mintingPrice = 0.15 * 10 ** 18;
        mintLimit = 1;
        //total = 5000
        devMintLimit = 350;
        publicSupplyLimit = 4580;
        adoptionIncentivesSupplyLimit = 70;
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
    mapping (address => bool) public whitelisted;
    // checks how many NBMon eggs the address has minted. if it already reaches the limit, the address cannot mint anymore.
    mapping (address => uint16) public amountMinted;

    // sets the minting price for each Genesis Egg (in wei)
    uint256 public mintingPrice; 
    // limits the mint amount per person, regardless if whitelisted or not
    uint16 public mintLimit;
    // limits the amount the dev is able to mint.
    uint16 public devMintLimit;

    // limits the supply of the genesis NBMons that the public can mint.
    uint16 public publicSupplyLimit;
    // limits the supply of the genesis NBMons reserved for KOLs, influencers etc.
    uint16 public adoptionIncentivesSupplyLimit;

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

    // changes the minting price
    function changeMintingPrice(uint256 _mintingPrice) public onlyAdmin {
        mintingPrice = _mintingPrice;
    }
    
    // changes the mint limit
    function changeMintLimit(uint16 _mintLimit) public onlyAdmin {
        mintLimit = _mintLimit;
    }

    // a modifier for minting to ensure that the caller does not mint more than the specified mint limit
    modifier belowMintLimit(uint16 _amountToMint, address _to) {
        uint16 _totalToMint = amountMinted[_to] + _amountToMint;
        require(_totalToMint <= mintLimit, "GenesisNBMonMintingA: Mint limit per user exceeded.");
        _;
    }

    // a modifier for minting to ensure that the developer does not mint more than the specified dev mint limit
    modifier belowDevMintLimit(uint16 _amountToMint, address _dev) {
        uint16 _totalToMint = amountMinted[_dev] + _amountToMint;
        require(_totalToMint <= devMintLimit, "GenesisNBMonMintingA: Dev mint limit exceeded.");
        _;
    }

    // a modifier for minting to ensure that the amount to be minted is not more than the dev mint limit + adoption incentives supply limit
    modifier belowAdoptionIncentivesSupplyLimit(uint16 _amountToMint, address _dev) {
        uint16 _totalToMint = amountMinted[_dev] + _amountToMint;
        require(_totalToMint <= (devMintLimit + adoptionIncentivesSupplyLimit), "GenesisNBMonMintingA: Supply for dev mint + adoptionIncentives limit reached. Cannot mint more.");
        _;
    }

    // a modifier for minting to ensure that the current supply is less than the allowed supply limit for genesis NBMons
    modifier belowPublicSupplyLimit(uint16 _amountToMint) {
        uint16 _totalToMint = uint16(totalSupply()) + _amountToMint;
        require(_totalToMint <= publicSupplyLimit, "GenesisNBMonMintingA: Supply limit reached. Cannot mint more.");
        _;
    }

    // mints genesis eggs (for dev)
    function devGenesisEggMint(
        uint16 _amountToMint,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) public onlyMinter belowDevMintLimit(_amountToMint, _msgSender()) whenMintingAllowed {
        _mintGenesisEgg(_msgSender(), _amountToMint, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
        amountMinted[_msgSender()] += _amountToMint;
    }

    // mints genesis eggs to dev's address first, to be given to KOLs, influencers etc. for later
    function adoptionIncentivesGenesisEggMint(
        uint16 _amountToMint,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) public onlyMinter belowAdoptionIncentivesSupplyLimit(_amountToMint, _msgSender()) whenMintingAllowed {
        _mintGenesisEgg(_msgSender(), _amountToMint, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
        amountMinted[_msgSender()] += _amountToMint;
    }

    // mints a genesis egg (for whitelisted people.
    function whitelistedGenesisEggMint(
        address _owner,
        uint16 _amountToMint,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg 
    ) public nonReentrant onlyMinter isWhitelisted(_owner) belowMintLimit(_amountToMint, _owner) belowPublicSupplyLimit(_amountToMint) whenMintingAllowed {
        _mintGenesisEgg(_owner, _amountToMint, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
        amountMinted[_owner]++;
    }

    // mints a genesis egg (for public)
    function publicGenesisEggMint(
        address _owner,
        uint16 _amountToMint,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) public nonReentrant onlyMinter belowMintLimit(_amountToMint, _owner) belowPublicSupplyLimit(_amountToMint) whenMintingAllowed {
        _mintGenesisEgg(_owner, _amountToMint, _hatchingDuration, _nbmonStats, _types, _potential, _passives, _isEgg);
        amountMinted[_owner]++;
    }

    function _mintGenesisEgg(
        address _owner,
        uint16 _amountToMint,
        uint32 _hatchingDuration,
        string[] memory _nbmonStats,
        string[] memory _types,
        uint8[] memory _potential,
        string[] memory _passives,
        bool _isEgg
    ) private {
            uint i = currentGenesisNBMonCount;
            for (i; i < (currentGenesisNBMonCount + _amountToMint); i++) {
                GenesisNBMon memory _genesisNBMon = GenesisNBMon(
                i,
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
                genesisNBMons.push(_genesisNBMon);
                ownerGenesisNBMonIds[_owner].push(i);
                emit GenesisNBMonMinted(i, _owner);
            }
            _safeMint(_owner, _amountToMint);
            currentGenesisNBMonCount += _amountToMint;
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

    // withdraw funds to _to's wallet
    function withdrawFunds(address _to) public onlyAdmin {
        payable(_to).transfer(address(this).balance);
    }
}
