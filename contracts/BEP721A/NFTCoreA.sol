//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./BEP721AURIStorage.sol";

abstract contract NFTCoreA is BEP721AURIStorage {
    string private baseTokenURI;
    /**
     * @dev Sets the Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
         return baseTokenURI;
    }
    
    /**
     * @dev Changes the current Base URI. 
     * Only callable by Admin or CEO of contract.
     */
    function setBaseURI(string memory newBaseURI) public onlyAdminOrCEO {
        baseTokenURI = newBaseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(BEP721AURIStorage) returns (string memory) {
        return BEP721AURIStorage.tokenURI(tokenId);
    }

    /**
     *@dev See {BEP721URIStorage-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override(BEP721AURIStorage) {
        BEP721AURIStorage._burn(tokenId);
    }
}