//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../BEP721A/NFTCoreA.sol";

abstract contract MintingCore is NFTCoreA {
    /// @dev Emitted when minting is set to 'allowed'. Triggered by _owner. 
    event MintingAllowed(address _owner);
    /// @dev Emitted when minting is set to 'not allowed'. Triggered by _owner.
    event MintingNotAllowed(address _owner);

    bool public _mintingAllowed;

    modifier whenMintingAllowed() {
        require(_mintingAllowed, "MC1");
        _;
    }

    modifier whenMintingNotAllowed() {
        require(!_mintingAllowed, "MC2");
        _;
    }

    function allowMinting() external whenMintingNotAllowed onlyAdmin {
        _mintingAllowed = true;
        emit MintingAllowed(_msgSender());
    }

    function disallowMinting() external whenMintingAllowed onlyAdmin {
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
    // Note: includes adoption incentives supply limit
    uint16 public devMintLimit;
    // max genesis NBMons supply that the general minters can mint
    // (public + whitelisted)
    // NOT changeable once deployed
    uint16 public generalSupplyLimit;
    // max supply of total mintable NBMons
    uint16 public maxSupply;

    // updates the max supply
    function updateMaxSupply() external onlyAdmin {
        maxSupply = devMintLimit + generalSupplyLimit;
    }

    // changes the public minting price
    function changePublicMintingPrice(uint256 _price) external onlyAdmin {
        publicMintingPrice = _price;
    }

    // changes the whitelisted minting price
    function changeWhitelistedMintingPrice(uint256 _price) external onlyAdmin {
        whitelistedMintingPrice = _price;
    }

    // changes the general mint limit
    function changeGeneralMintLimit(uint16 _limit) external onlyAdmin {
        generalMintLimit = _limit;
    }

    // changes the whitelisted mint limit
    function changeWhitelistedMintLimit(uint8 _limit) external onlyAdmin {
        whitelistedMintLimit = _limit;
    }

    // changes the dev mint limit. Note: Cannot exceed 7.5% of total supply. 
    // can be lowered to give more general mint limit to both public & whitelisted.
    function changeDevMintLimit(uint16 _limit) external onlyAdmin {
        require(_limit <= (maxSupply * 75 / 1000), "MC3");
        devMintLimit = _limit;
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

    /// can add multiple minters with their own profiles to minterProfile.
    /// @dev allows anyone to register their own profile if not registered already (even those that are not theirs).
    /// since anyone can mint, even adding a wallet address that's not theirs will help that particular address
    /// Note: this function will get called when a user registers their wallet if they want to mint (required). (if not registered by someone already)
    /// for whitelisting version, please check `whitelistAddress` or `whitelistAddresses`. requires admin to whitelist.
    /// @dev for whitelisting version, please check `whitelistAddress` or `whitelistAddresses`. requires admin to whitelist.
    function addMinters(address[] memory _addrs) external {
        for (uint i = 0; i < _addrs.length; i++) {
            // if this address already has a profile, skip to the next address
            if (minterProfile[_addrs[i]].addr == address(0)) {
                minterProfile[_addrs[i]] = Minter(_addrs[i], false, false, 0);
            }
        }
    }

    /// gets a minter's profile
    function getMinterProfile(address _addr) external view returns (Minter memory) {
        return minterProfile[_addr];
    }

    /// checks if address has a profile
    function profileRegistered(address _addr) external view returns (bool) {
        return minterProfile[_addr].addr != address(0);
    }

    /// can whitelist multiple addresses at once.
    /// requires the user(s) to not be whitelisted yet and to not be blacklisted.
    /// if one of the addresses does not have a profile yet, we can create it for them.
    function whitelistAddresses(address[] memory _addrs) external onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            // creates a profile for the minter if not registered already and whitelist them
            if (minterProfile[_addrs[i]].addr == address(0)) {
                minterProfile[_addrs[i]] = Minter(_addrs[i], true, false, 0);
            // if profile already exists, ensure that the user is not blacklisted and not whitelisted already.
            } else {
                Minter storage _minter = minterProfile[_addrs[i]];
                if (
                    minterProfile[_addrs[i]].blacklisted == false &&
                    minterProfile[_addrs[i]].whitelisted == false
                ) {
                    _minter.whitelisted = true;
                }
            }
        }
    }

    /// removes multiple minters' whitelist roles.
    /// Note: does NOT check if _addr != address(0) since default whitelisted values for 0 addresses are set to false.
    function removeWhitelists(address[] memory _addrs) external onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            Minter storage _minter = minterProfile[_addrs[i]];
            if (_minter.whitelisted == true) {
                _minter.whitelisted = false;
            }
        }
    }

    /// blacklists multiple addresses from being able to get whitelisted or mint.
    /// if one of the addresses is not registered yet, we can create the profile immediately and issue the blacklist.
    function blacklistAddresses(address[] memory _addrs) external onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            // if the address is not registered yet (== address(0)), we can create the profile for them.
            if (minterProfile[_addrs[i]].addr == address(0)) {
                minterProfile[_addrs[i]] = Minter(_addrs[i], false, true, 0);
            // if the address is already registered, simply blacklist the address
            // requires the address to not already be blacklisted.
            // if the address was whitelisted, they will get unwhitelisted.
            } else {
                Minter storage _toBlacklist = minterProfile[_addrs[i]];
                require(_toBlacklist.blacklisted == false, "MC9");
                _toBlacklist.blacklisted = true;
                if (_toBlacklist.whitelisted == true) {
                    _toBlacklist.whitelisted == false;
                }
            }
        }
    }

    /// removes multiple minters' blacklists.
    /// Note: does NOT check if _addr != address(0) since default whitelisted values for 0 addresses are set to false.
    function removeBlacklists(address[] memory _addrs) external onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            Minter storage _minter = minterProfile[_addrs[i]];
            if (_minter.blacklisted == true) {
                _minter.blacklisted = false;
            }
        }
    }

    /// checks if a minter is whitelisted
    function checkWhitelisted(address _addr) public view returns (bool) {
        return minterProfile[_addr].whitelisted;
    }

    /// checks if a minter is blacklisted
    function checkBlacklisted(address _addr) public view returns (bool) {
        return minterProfile[_addr].blacklisted;
    }

    /// checks how many NBMons the minter has minted
    function checkAmountMinted(address _addr) external view returns (uint16) {
        return minterProfile[_addr].amountMinted;
    }

    // ensures that the minter is whitelisted
    modifier isWhitelisted(address _addr) {
        require(checkWhitelisted(_addr), "MC11");
        _;
    }

    // ensures that the minter is not blacklisted
    modifier isNotBlacklisted(address _addr) {
        require(!checkBlacklisted(_addr), "MC12");
        _;
    }

    // ensures that a whitelisted minter cannot mint more than the whitelisted mint limit.
    // assumes that the user is already whitelisted (will be checked using the isWhitelisted modifier).
    // includes a check to ensure that the user hasn't minted at all:
    // since whitelisted users mint before the rest, their amountMinted should start at 0.
    // therefore, the whitelistedMintLimit checks if the amount they want to mint + amountMinted (0) <= whitelisted limit, else it fails.
    modifier belowWhitelistedMintLimit(uint16 _amountToMint, address _addr) {
        uint16 _totalToMint = minterProfile[_addr].amountMinted + _amountToMint;
        require(_totalToMint <= whitelistedMintLimit, "MC13");
        _;
    }

    // ensures that a minter cannot mint more than the mint limit.
    // if the user is whitelisted, this also gets counted towards the amountMinted.
    modifier belowMintLimit(uint16 _amountToMint, address _addr) {
        uint16 _totalToMint = minterProfile[_addr].amountMinted + _amountToMint;
        require(_totalToMint <= generalMintLimit, "MC14");
        _;
    }

    // ensures that the dev cannot mint more than the dev's mint limit.
    modifier belowDevMintLimit(uint16 _amountToMint) {
        uint16 _totalToMint = minterProfile[minter].amountMinted + _amountToMint;
        require(_totalToMint <= devMintLimit, "MC15");
        _;
    }

    // ensures that minters cannot mint more than the general supply. Once generalSupplyLimit has reached, minting is closed.
    modifier belowGeneralSupplyLimit(uint16 _amountToMint) {
        uint16 _totalToMint = uint16(totalSupply()) + _amountToMint;
        require(_totalToMint <= generalSupplyLimit, "MC17");
        _;
    }
}