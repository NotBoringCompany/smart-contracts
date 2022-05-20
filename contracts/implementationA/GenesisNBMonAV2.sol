//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../BEP721A/NFTCoreAV2.sol";
import "../security/ReentrancyGuard.sol";
import "../security/ECDSA.sol";

contract GenesisNBMonAV2 is NFTCoreAV2, ReentrancyGuard {
    constructor() BEP721A("Genesis NBMon", "G-NBMON") {
        setBaseURI("https://nbcompany.fra1.digitaloceanspaces.com/genesisNBMon/");
        _mintingAllowed = true;
        // 0.15 ETH
        publicMintingPrice = 0.15 * 10 ** 18;
        // 0.125 ETH
        whitelistedMintingPrice = 0.125 * 10 ** 18;
        generalMintLimit = 5;
        whitelistedMintLimit = 1;
        /// max supply = 5000 (300 + 4630 + 70)
        devMintLimit = 300;
        generalSupplyLimit = 4630;
        adoptionIncentivesSupplyLimit = 70;
    }

    /// @dev Emitted when minting is set to 'allowed'. Triggered by _owner. 
    event MintingAllowed(address _owner);
    /// @dev Emitted when minting is set to 'not allowed'. Triggered by _owner.
    event MintingNotAllowed(address _owner);

    bool public _mintingAllowed;

    modifier whenMintingAllowed() {
        require(_mintingAllowed, "GenesisNBMonAV2: Minting enabled.");
        _;
    }

    modifier whenMintingNotAllowed() {
        require(!_mintingAllowed, "GenesisNBMonAV2: Minting disabled.");
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

    /**
     * @dev Key relevant information for minting. Includes price and limits.
     */
    // minting price for non-whitelisted minters
    uint256 public publicMintingPrice;
    // minting price for whitelisted minters
    uint256 public whitelistedMintingPrice;
    // max amount anyone can mint, regardless if whitelisted or not.
    uint16 public generalMintLimit;
    // max amount a whitelisted minter can mint
    uint8 public whitelistedMintLimit;
    // max amount the dev can mint
    // NOT changeable once deployed
    uint16 public devMintLimit;

    /// Note: max supply = generalSupplyLimit + devMintLimit + adoptionIncentivesSupplyLimit
    // max genesis NBMons supply that the general minters can mint
    // (public + whitelisted)
    // NOT changeable once deployed
    uint16 public generalSupplyLimit;
    // max genesis NBMons supply that can be minted for KOLs, influencers etc
    // NOT changeable once deployed
    uint16 public adoptionIncentivesSupplyLimit;

    // changes the public minting price
    function changePublicMintingPrice(uint256 _price) public onlyAdmin {
        publicMintingPrice = _price;
    }

    // changes the whitelisted minting price
    function changeWhitelistedMintingPrice(uint256 _price) public onlyAdmin {
        whitelistedMintingPrice = _price;
    }

    // changes the general mint limit
    function changeGeneralMintLimit(uint16 _limit) public onlyAdmin {
        generalMintLimit = _limit;
    }

    // changes the whitelisted mint limit
    function changeWhitelistedMintLimit(uint8 _limit) public onlyAdmin {
        whitelistedMintLimit = _limit;
    }

    /**
     * @dev Represents a minter's profile. Includes relevant information needed for minting.
     */
    struct Minter {
        // address of the minter
        address addr;
        // if whitelisted, minter is eligible for whitelistedMint.
        // else, minter is only eligible for publicMint.
        bool whitelisted;
        // if the minter is blacklisted, they are no longer eligible to mint.
        bool blacklisted;
        // checks the amount that the minter has minted already.
        uint16 amountMinted;
    }

    // mapping from a minter's address to the full profile of the minter
    mapping (address => Minter) internal minterProfile;

    /// adds a single minter with their own profile to minterProfile. 
    /// @dev allows anyone to register their own profile if not registered already (even those that are not theirs).
    /// since anyone can mint, even adding a wallet address that's not theirs will help that particular address.
    /// Note: this function will get called when a user registers their wallet if they want to mint. (if not registered by someone already)
    /// for whitelisting version, please check `whitelistAddress` or `whitelistAddresses`. requires admin to whitelist.
    function addMinter(address _addr) public {
        // ensures that minter profile doesn't already exist for this address
        require(minterProfile[_addr].addr == address(0), "GenesisNBMonAV2: Minter profile already exists");
        
        Minter memory _minter = Minter(_addr, false, false, 0);
        minterProfile[_addr] = _minter;
    }

    /// adds multiple minters with their own profiles to minterProfile.
    /// @dev allows anyone to register multiple addresses (even those that are not theirs) if not registered already.
    /// @dev for whitelisting version, please check `whitelistAddress` or `whitelistAddresses`. requires admin to whitelist.
    function addMinters(address[] memory _addrs) public {
        for (uint i = 0; i < _addrs.length; i++) {
            // if this address already has a profile, skip to the next address
            if (minterProfile[_addrs[i]].addr == address(0)) {
                Minter memory _minter = Minter(_addrs[i], false, false, 0);
                minterProfile[_addrs[i]] = _minter;
            }
        }
    }

    /// gets a minter's profile
    function getMinterProfile(address _addr) public view returns (Minter memory) {
        return minterProfile[_addr];
    }

    /// whitelists a single address.
    /// requires the user to not be whitelisted yet and to not be blacklisted.
    /// if address does not have a profile yet, we can create it for them.
    function whitelistAddress(address _addr) public onlyAdmin {
        // creates a profile for the minter if not registered already and whitelist them
        if (minterProfile[_addr].addr == address(0)) {
            Minter memory _minter = Minter(_addr, true, false, 0);
            minterProfile[_addr] = _minter;
        // if profile already exists, ensure that the user is not blacklisted and not whitelisted already.
        } else {
            require(minterProfile[_addr].blacklisted == false, "GenesisNBMonAV2: Minter is blacklisted");
            require(minterProfile[_addr].whitelisted == false, "GenesisNBMonAV2: Minter is already whitelisted");
            
            Minter storage _minter = minterProfile[_addr];
            _minter.whitelisted = true;
        }
    }

    /// whitelists multiple addresses at once.
    /// requires the user(s) to have their profiles registered, to not be whitelisted yet and to not be blacklisted.
    /// if one of the addresses does not have a profile yet, we can create it for them.
    function whitelistAddresses(address[] memory _addrs) public onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            // creates a profile for the minter if not registered already and whitelist them
            if (minterProfile[_addrs[i]].addr == address(0)) {
                Minter memory _minter = Minter(_addrs[i], true, false, 0);
                minterProfile[_addrs[i]] = _minter;
            // if profile already exists, ensure that the user is not blacklisted and not whitelisted already.
            } else {
                if (
                    minterProfile[_addrs[i]].blacklisted == false &&
                    minterProfile[_addrs[i]].whitelisted == false
                ) 
                {
                    Minter storage _minter = minterProfile[_addrs[i]];
                    _minter.whitelisted = true;
                }
            }
        }
    }

    /// blacklists an address from being able to get whitelisted or mint.
    /// if the address is not registered yet, we can create the profile immediately and issue the blacklist.
    function blacklistAddress(address _addr) public onlyAdmin {
        Minter storage _toBlacklist = minterProfile[_addr];
        // if the address is not registered yet (== address(0)), we create a profile for them.
        if (_toBlacklist.addr == address(0)) {
            addMinter(_addr);
            _toBlacklist.blacklisted = true;
        // if the address is already registered, simply blacklist the address.
        // requires the address to not already be blacklisted.
        // if the address was whitelisted, they will get unwhitelisted.
        } else {
            require(_toBlacklist.blacklisted == false, "GenesisNBMonAV2: Minter already blacklisted");
            _toBlacklist.blacklisted = true;
            if (_toBlacklist.whitelisted == true) {
                _toBlacklist.whitelisted == false;
            }
        }
    }

    /// blacklists multiple addresses from being able to get whitelisted or mint.
    /// if one of the addresses is not registered yet, we can create the profile immediately and issue the blacklist.
    function blacklistAddresses(address[] memory _addrs) public onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            Minter storage _toBlacklist = minterProfile[_addrs[i]];
            // if the address is not registered yet (== address(0)), we can create the profile for them.
            if (_toBlacklist.addr == address(0)) {
                addMinter(_addrs[i]);
                _toBlacklist.blacklisted = true;
            // if the address is already registered, simply blacklist the address
            // requires the address to not already be blacklisted.
            // if the address was whitelisted, they will get unwhitelisted.
            } else {
                require(_toBlacklist.blacklisted == false, "GenesisNBMonAV2: Minter already blacklisted");
                _toBlacklist.blacklisted = true;
                if (_toBlacklist.whitelisted == true) {
                    _toBlacklist.whitelisted == false;
                }
            }
        }
    }

    /// checks if a minter is whitelisted
    function checkWhitelisted(address _addr) public view returns (bool) {
        Minter memory _minter = minterProfile[_addr];
        return _minter.whitelisted;
    }

    /// checks if a minter is blacklisted
    function checkBlacklisted(address _addr) public view returns (bool) {
        Minter memory _minter = minterProfile[_addr];
        return _minter.blacklisted;
    }

    /// checks how many NBMons the minter has minted
    function checkAmountMinted(address _addr) public view returns (uint16) {
        Minter memory _minter = minterProfile[_addr];
        return _minter.amountMinted;
    }

    // ensures that the minter is whitelisted
    modifier isWhitelisted(address _addr) {
        require(checkWhitelisted(_addr), "GenesisNBMonAV2: Minter is not whitelisted.");
        _;
    }

    // ensures that the minter is not blacklisted
    modifier isNotBlacklisted(address _addr) {
        require(!checkBlacklisted(_addr), "GenesisNBMonAV2: Minter is blacklisted.");
        _;
    }

    // ensures that a whitelisted minter cannot mint more than the whitelisted mint limit.
    // assumes that the user is already whitelisted (will be checked using the isWhitelisted modifier).
    // includes a check to ensure that the user hasn't minted at all:
    // since whitelisted users mint before the rest, their amountMinted should start at 0.
    // therefore, the whitelistedMintLimit checks if the amount they want to mint + amountMinted (0) <= whitelisted limit, else it fails.
    modifier belowWhitelistedMintLimit(uint16 _amountToMint, address _addr) {
        Minter memory _minter = minterProfile[_addr];
        uint16 _totalToMint = _minter.amountMinted + _amountToMint;
        require(_totalToMint <= whitelistedMintLimit, "GenesisNBMonAV2: Whitelisted mint limit per address exceeded.");
        _;
    }

    // ensures that a minter cannot mint more than the mint limit.
    // if the user is whitelisted, this also gets counted towards the amountMinted.
    modifier belowMintLimit(uint16 _amountToMint, address _addr) {
        Minter memory _minter = minterProfile[_addr];
        uint16 _totalToMint = _minter.amountMinted + _amountToMint;
        require(_totalToMint <= generalMintLimit, "GenesisNBMonAV2: Mint limit per address exceeded");
        _;
    }

    // ensures that the dev cannot mint more than the dev's mint limit.
    modifier belowDevMintLimit(uint16 _amountToMint) {
        // dev is minter in AccessControl.sol.
        Minter memory _dev = minterProfile[minter];
        uint16 _totalToMint = _dev.amountMinted + _amountToMint;
        require(_totalToMint <= devMintLimit, "GenesisNBMonAV2: Dev mint limit exceeded.");
        _;
    }

    // ensures that the dev cannot mint more than the adoption incentives supply limit.
    // since the dev mints for the adoption incentives section, the requirement is changed.
    modifier belowAdoptionIncentivesSupplyLimit(uint16 _amountToMint) {
        // dev is minter in AccessControl.sol.
        Minter memory _dev = minterProfile[minter];
        uint16 _totalToMint = _dev.amountMinted + _amountToMint;
        // here, we ensure that the _totalToMint doesn't exceed the dev's minting limit + the adoption incentives supply limit.
        require(_totalToMint <= (devMintLimit + adoptionIncentivesSupplyLimit), "GenesisNBMonAV2: Adoption incentives mint limit exceeded.");
        _;
    }

    // ensures that minters cannot mint more than the general supply. Once generalSupplyLimit has reached, minting is closed.
    modifier belowGeneralSupplyLimit(uint16 _amountToMint) {
        uint16 _totalToMint = uint16(totalSupply()) + _amountToMint;
        require(_totalToMint <= generalSupplyLimit, "GenesisNBMonAV2: Supply limit reached. Minting no longer possible.");
        _;
    }

    // mints genesis eggs (for dev)
    function devMint(
        uint16 _amountToMint,
        string[] memory _stringMetadata,
        uint256[] memory _numericMetadata,
        bool[] memory _boolMetadata        
    ) public onlyMinter belowDevMintLimit(_amountToMint) whenMintingAllowed {
        Minter storage _dev = minterProfile[_msgSender()];

        _mintGenesis(_msgSender(), _amountToMint, _stringMetadata, _numericMetadata, _boolMetadata);
        _dev.amountMinted += _amountToMint;
    }

    // mints adoption incentives eggs (dev mints them)
    function adoptionIncentivesMint(
        uint16 _amountToMint,
        string[] memory _stringMetadata,
        uint256[] memory _numericMetadata,
        bool[] memory _boolMetadata
    ) public onlyMinter belowAdoptionIncentivesSupplyLimit(_amountToMint) whenMintingAllowed {
        Minter storage _dev = minterProfile[_msgSender()];

        _mintGenesis(_msgSender(), _amountToMint, _stringMetadata, _numericMetadata, _boolMetadata);
        _dev.amountMinted += _amountToMint;
    }

    /// mints a genesis egg for whitelisted minters.
    function whitelistedMint(
        address _addr,
        uint16 _amountToMint,
        string[] memory _stringMetadata,
        uint256[] memory _numericMetadata,
        bool[] memory _boolMetadata
    ) public nonReentrant onlyMinter isWhitelisted(_addr) belowWhitelistedMintLimit(_amountToMint, _addr) belowGeneralSupplyLimit(_amountToMint) whenMintingAllowed {
        Minter storage _minter = minterProfile[_addr];

        _mintGenesis(_addr, _amountToMint, _stringMetadata, _numericMetadata, _boolMetadata);
        _minter.amountMinted += _amountToMint;
    }

    /// mints a genesis egg for minters.
    function publicMint(
        address _addr,
        uint16 _amountToMint,
        string[] memory _stringMetadata,
        uint256[] memory _numericMetadata,
        bool[] memory _boolMetadata
    ) public nonReentrant onlyMinter belowMintLimit(_amountToMint, _addr) belowGeneralSupplyLimit(_amountToMint) whenMintingAllowed {
        Minter storage _minter = minterProfile[_addr];

        _mintGenesis(_addr, _amountToMint, _stringMetadata, _numericMetadata, _boolMetadata);
        _minter.amountMinted += _amountToMint;
    }

    /// mints _amountToMint amount of genesis eggs to _owner using the _safeMint method from BEP721A.
    function _mintGenesis(
        address _owner,
        uint16 _amountToMint,
        /// includes:
        // 1. nbmonStats array (gender, rarity, mutation, species, genus, fertility)
        // 2. types array (first type, second type)
        // 3. passives array (first passive, second passive)
        string[] memory _stringMetadata,
        /// includes:
        // 1. hatchingDuration (time it takes until it can hatch)
        // 2. potential array (health, energy, attack, defense, sp attack, sp defense, speed)
        uint256[] memory _numericMetadata,
        /// includes:
        // 1. isEgg (if nbmon is still an egg or not)
        bool[] memory _boolMetadata
    ) private {
        uint i = _currentIndex;
        for (i; i < (_currentIndex + _amountToMint); i++) {
            NFT memory _genesisNBMon = NFT(
                "Genesis NBMon",
                i,
                _owner,
                block.timestamp,
                block.timestamp,
                new address[](0),
                _stringMetadata,
                _numericMetadata,
                _boolMetadata,
                new bytes32[](0)
            );

            nfts[i] = _genesisNBMon;
            ownerNFTIds[_owner].push(i);
            emit NFTMinted(i, _owner, block.timestamp);
        }
        _safeMint(_owner, _amountToMint);
    }

    /**
     * @dev Start of hatching logic
     */

    event HatchingAllowed(address _owner);
    event HatchingNotAllowed(address _owner);

    modifier whenHatchingAllowed() {
        require(_hatchingAllowed, "GenesisNBMonMintingA: Hatching enabled.");
        _;
    }

    modifier whenHatchingNotAllowed() {
        require(!_hatchingAllowed, "GenesisNBMonMintingA: Hatching disabled.");
        _;
    }

    function allowHatching() public whenHatchingNotAllowed onlyAdmin {
        _hatchingAllowed = true;
        emit HatchingAllowed(_msgSender());
    }

    function disallowHatching() public whenHatchingAllowed onlyAdmin {
        _hatchingAllowed = false;
        emit HatchingNotAllowed(_msgSender());
    }

    bool public _hatchingAllowed;

    /// checks if a minting signature was already used.
    mapping (bytes => bool) internal usedMintingSignature;

    /// generates a hash when minting with the given parameters.
    function mintingHash(
        uint256 _nbmonId,
        address _minter,
        uint256 _bornAt,
        /// nbmonStats array as a string
        string memory _nbmonStats,
        string memory _txSalt
    ) public pure returns (bytes32) {
        return 
            keccak256(
                abi.encodePacked(
                    _nbmonId,
                    _minter,
                    _bornAt,
                    _nbmonStats,
                    _txSalt
            )
        );
    }

    /// hatches an nbmon and updates its stats.
    function hatchFromEgg(
        uint256 _nbmonId,
        address _minter,
        uint256 _bornAt,
        string[] calldata _stringMetadata,
        uint256[] calldata _numericMetadata,
        bool[] calldata _boolMetadata,
        string calldata _txSalt,
        bytes calldata _signature
    ) public nonReentrant whenHatchingAllowed {
        sigMatch(_nbmonId, _minter, _bornAt, _stringMetadata[0], _txSalt, _signature);
        nbmonCheck(_nbmonId);

        // once checks are all passed, we hatch and update the stats of the NBMon
        NFT storage _nbmon = nfts[_nbmonId];

        _nbmon.bornAt = block.timestamp;
        _nbmon.stringMetadata = _stringMetadata;
        _nbmon.numericMetadata = _numericMetadata;
        _nbmon.boolMetadata = _boolMetadata;

        usedMintingSignature[_signature] = true;
    }

    /// checks if certain requirements of the nbmon is met before hatching.
    function nbmonCheck(uint256 _nbmonId) internal view {
        require(_exists(_nbmonId), "GenesisNBMonAV2: Specified NBMon ID doesn't exist");

        NFT memory _nbmon = nfts[_nbmonId];
        require(_nbmon.owner == _msgSender(), "GenesisNBMonAV2: Caller is not owner of specified NBMon.");
        require(_nbmon.boolMetadata[0] == true, "GenesisNBMonAV2: NBMon is already hatched/not an egg anymore.");
        require(_nbmon.bornAt + _nbmon.numericMetadata[0] <= block.timestamp, "GenesisNBMonAV2: Egg is not ready to hatch yet.");
    }

    /// checks if signature matches the minter's signature.
    function sigMatch(
        uint256 _nbmonId,
        address _minter,
        uint256 _bornAt,
        /// nbmonStats array as a string
        string calldata _nbmonStats,
        string calldata _txSalt,
        bytes calldata _signature
    ) internal view {
        // ensures that signature hasn't been used already
        require(!usedMintingSignature[_signature], "GenesisNBMonAV2: Signature already used.");

        // gets the minting hash from the specified parameters
        bytes32 _mintingHash = mintingHash(
            _nbmonId,
            _minter,
            _bornAt,
            _nbmonStats,
            _txSalt
        );

        // gets the ethereum signed message
        bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_mintingHash);

        require(
            ECDSA.recover(_ethSignedMsgHash, _signature) == _minter,
            "GenesisNBMonAV2: Invalid minter signature."
        );
    }
}