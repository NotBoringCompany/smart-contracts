//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MintingCore.sol";
import "../security/ReentrancyGuard.sol";
import "../security/ECDSA.sol";
import "../BEP20/BEP20.sol";
import "../BEP20/SafeBEP20.sol";

contract GenesisNBMon is MintingCore, ReentrancyGuard {
    using SafeBEP20 for BEP20;

    constructor() BEP721A("Genesis NBMon", "G-NBMON") {
        setBaseURI("https://nbcompany.fra1.digitaloceanspaces.com/genesisNBMon/");
        _mintingAllowed = true;
        _hatchingAllowed = true;
        // 0.15 ETH
        publicMintingPrice = 0.15 * 10 ** 18;
        // 0.125 ETH
        whitelistedMintingPrice = 0.125 * 10 ** 18;
        generalMintLimit = 5;
        whitelistedMintLimit = 1;
        /// max supply = 5000 (370 + 4630)
        devMintLimit = 370;
        generalSupplyLimit = 4630;
    }

    // mints genesis eggs (for dev)
    function devMint(
        uint16 _amountToMint,
        string[] memory _stringMetadata,
        uint256[] memory _numericMetadata,
        bool[] memory _boolMetadata        
    ) external onlyMinter belowDevMintLimit(_amountToMint) whenMintingAllowed {
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
    ) external nonReentrant onlyMinter isWhitelisted(_addr) belowWhitelistedMintLimit(_amountToMint, _addr) belowGeneralSupplyLimit(_amountToMint) whenMintingAllowed {
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
    ) external nonReentrant onlyMinter belowMintLimit(_amountToMint, _addr) belowGeneralSupplyLimit(_amountToMint) whenMintingAllowed {
        Minter storage _minter = minterProfile[_addr];

        _mintGenesis(_addr, _amountToMint, _stringMetadata, _numericMetadata, _boolMetadata);
        _minter.amountMinted += _amountToMint;
    }

    /// mints _amountToMint amount of genesis eggs to _owner using the _safeMint method from BEP721A.
    function _mintGenesis(
        address _owner,
        uint16 _amountToMint,
        /// includes:
        // 1. nbmon stats (gender (0th index), rarity (1st index and so on), mutation, species, genus)
        // 2. types (first type, second type)
        // 3. passives (first passive, second passive)
        string[] memory _stringMetadata,
        /// includes:
        // 1. hatchingDuration (time it takes until it can hatch)
        // 2. potential (health, energy, attack, defense, sp attack, sp defense, speed)
        // 3. fertility points
        // 4. hatchedAt (if already hatched later on)
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
                false,
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
    event Hatched(address indexed _owner, uint256 indexed _nbmonId);

    modifier whenHatchingAllowed() {
        require(_hatchingAllowed, "GN1");
        _;
    }

    modifier whenHatchingNotAllowed() {
        require(!_hatchingAllowed, "GN2");
        _;
    }

    function allowHatching() external whenHatchingNotAllowed onlyAdmin {
        _hatchingAllowed = true;
        emit HatchingAllowed(_msgSender());
    }

    function disallowHatching() external whenHatchingAllowed onlyAdmin {
        _hatchingAllowed = false;
        emit HatchingNotAllowed(_msgSender());
    }

    bool public _hatchingAllowed;

    /// stats used to hatch the nbmon
    struct HatchingStats {
        bool exists;
        uint256 nbmonId;
        string[] stringMetadata;
        uint256[] numericMetadata;
        bool[] boolMetadata;
    }

    /// maps from a signature to the calculated hatching stats for that NBMon
    mapping (bytes => HatchingStats) private hatchingStats;

    /// checks if a certain signature contains a relevant hatching data. Does NOT check if signature is valid.
    function checkSigExists(bytes memory _signature) public view onlyAdmin returns (bool) {
        return hatchingStats[_signature].exists;
    }

    function checkSigExistsPvt(bytes memory _signature) private view returns (bool) {
        return hatchingStats[_signature].exists; 
    }
    
    /// given a signature, add hatching stats to be used for hatching an nbmon
    function addHatchingStats(
        uint256 _nbmonId,
        address _minter,
        uint256 _bornAt,
        string memory _txSalt,
        bytes memory _signature,
        string[] memory _stringMetadata,
        uint256[] memory _numericMetadata,
        bool[] memory _boolMetadata
    ) external onlyAdmin {
        sigMatch(_nbmonId, _minter, _bornAt, _txSalt, _signature);
        hatchingStats[_signature] = HatchingStats(true, _nbmonId, _stringMetadata, _numericMetadata, _boolMetadata);
    }

    /// functions to remove the hatching stats for a certain signature
    function removeHatchingStats(bytes memory _signature) external onlyAdmin {
        delete hatchingStats[_signature];
    }
    function removeHatchingStatsPvt(bytes memory _signature) private {
        delete hatchingStats[_signature];
    }

    /// generates a hash when hatching with the given parameters.
    function hatchingHash(
        uint256 _nbmonId,
        address _minter,
        uint256 _bornAt,
        string memory _txSalt
    ) public pure returns (bytes32) {
        return 
            keccak256(
                abi.encodePacked(
                    _nbmonId,
                    _minter,
                    _bornAt,
                    _txSalt
            )
        );
    }

    /// hatches an nbmon and updates its stats.
    function hatchFromEgg(bytes memory _signature) public nonReentrant whenHatchingAllowed {
        HatchingStats memory _hatchingStats = hatchingStats[_signature];
        require(checkSigExistsPvt(_signature) == true, "GN6");
        uint256 _nbmonId = _hatchingStats.nbmonId;
        nbmonHatchReq(_nbmonId);

        // once checks are all passed, we hatch and update the stats of the NBMon
        NFT storage _nbmon = nfts[_nbmonId];

        _nbmon.stringMetadata = _hatchingStats.stringMetadata;
        _nbmon.numericMetadata = _hatchingStats.numericMetadata;
        _nbmon.boolMetadata = _hatchingStats.boolMetadata;

        emit Hatched(_msgSender(), _nbmonId);

        /// remove the signature from the mapping.
        removeHatchingStatsPvt(_signature);
    }

    /// checks if certain requirements of the nbmon is met before hatching.
    function nbmonHatchReq(uint256 _nbmonId) private view {
        require(_exists(_nbmonId), "GN3");

        NFT memory _nbmon = nfts[_nbmonId];
        require(_nbmon.owner == _msgSender(), "GN4");
        require(_nbmon.boolMetadata[0] == true, "GN5");
        require(_nbmon.bornAt + _nbmon.numericMetadata[0] <= block.timestamp, "GN7");
    }

    /// checks if signature matches the minter's signature.
    function sigMatch(
        uint256 _nbmonId,
        address _minter,
        uint256 _bornAt,
        string memory _txSalt,
        bytes memory _signature
    ) private pure {
        // gets the hatching hash from the specified parameters
        bytes32 _hatchingHash = hatchingHash(
            _nbmonId,
            _minter,
            _bornAt,
            _txSalt
        );

        // gets the ethereum signed message
        bytes32 _ethSignedMsgHash = ECDSA.toEthSignedMessageHash(_hatchingHash);

        require(
            ECDSA.recover(_ethSignedMsgHash, _signature) == _minter,
            "GN8"
        );
    }

    /// withdraws balance from this contract to admin.
    /// Note: Please do NOT send unnecessary funds to this contract.
    /// This is used as a mechanism to transfer any balance that this contract has to admin.
    /// we will NOT be responsible for any funds transferred accidentally unless notified immediately.
    function withdrawFunds() external onlyAdmin {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /// withdraws tokens from this contract to admin.
    /// Note: Please do NOT send unnecessary tokens to this contract.
    /// This is used as a mechanism to transfer any tokens that this contract has to admin.
    /// we will NOT be responsible for any tokens transferred accidentally unless notified immediately.
    function withdrawTokens(address _tokenAddr, uint256 _amount) external onlyAdmin {
        BEP20 _token = BEP20(_tokenAddr);
        _token.transfer(_msgSender(), _amount);
    }
}