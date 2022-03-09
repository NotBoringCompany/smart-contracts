//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../BEP721/NFTCore.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// unlike NBMonBreeding, this uses Counters.Counter which already has an inbuilt counting/counter system from Open Zeppelin.
contract NBCOpenSeaTest is NFTCore {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    constructor() BEP721("NBC OpenSea Test", "NBCOT") {
        setBaseURI("https://marketplace.nbcompany.io/test/opensea/nbcot/");
    }

    function mintTo(address _to) public returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(_to, newItemId);
        return newItemId;
    }
}