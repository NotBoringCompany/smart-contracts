//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../BEP721A/BEP721A.sol";
import "../security/Context.sol";
import "../security/AccessControl.sol";

/**
 * @dev All marketplace-related functions. Only supports ERC/BEP721A (the more efficient version of ERC/BEP721).
 */
abstract contract MarketplaceCoreV2 is Context, AccessControl {
    /// check for supported BEP20 tokens used for payment in the marketplace
    mapping (address => bool) public paymentTokens;
    /// check for signatures that are no longer allowed for signing txs
    mapping (bytes => bool) public usedSignatures;

    /// the sales fee portion will be received here (our community treasury)
    address public nbExchequer;
    /// the team fee portion will be received here (team's wallet)
    address public teamWallet;


    /**
     * @dev We've divided the fee into two to be more transparent. 
     * Calculated in 100 basis points. 100 points = 1%.
     * @dev Total fee (in %) = (salesFee + devCut) / 100.
     */
    /// sales fee portion
    uint16 public salesFee;
    /// dev's cut
    uint16 public devCut;

    /**
     * @dev Sets the NBExchequer address to receive the sales fee portion.
     */
    function setNBExchequer(address _nbExchequer) public onlyAdmin {
        nbExchequer = _nbExchequer;
    }

    /**
     * @dev Sets the team wallet address to receive the team fee portion.
     */
    function setTeamWallet(address _teamWallet) public onlyAdmin {
        teamWallet = _teamWallet;
    }

    /**
     * @dev Sets the sales fee of transactions.
     */
    function setSalesFee(uint16 _salesFee) public onlyAdmin {
        salesFee = _salesFee;
    }

    /**
     * @dev Sets the dev cut of transactions.
     */
    function setDevCut(uint16 _devCut) public onlyAdmin {
        devCut = _devCut;
    }

    /**
     * @dev Sets the accepted payment tokens to be used in the marketplace.
     */
    function setPaymentTokens(address[] calldata _paymentTokens) public onlyAdmin {
        // realistically, we wouldn't add more than 256 tokens at once anyway
        for (uint8 i = 0; i < _paymentTokens.length; i++) {
            // if the token already exists in the list of accepted tokens, skip to the next iteration.
            if (paymentTokens[_paymentTokens[i]] == true) {
                continue;
            }
            paymentTokens[_paymentTokens[i]] = true;
        }
    }

    /**
     * @dev Removes payment tokens from the list of accepted payment tokens.
     */
    function removePaymentTokens(address[] calldata _paymentTokens) public onlyAdmin {
        for (uint8 i = 0; i < _paymentTokens.length; i++) {
            paymentTokens[_paymentTokens[i]] = false;
        }
    }
}