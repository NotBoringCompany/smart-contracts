// //SPDX-License-Identifier: MIT

// pragma solidity ^0.8.13;

// import "./IBEP721Receiver.sol";

// /**
//  * @dev Implementation of the {IERC721Receiver} interface.
//  *
//  * Accepts all token transfers.
//  * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
//  */
// contract BEP721Receiver is IBEP721Receiver {
//     /**
//      * @dev See {IERC721Receiver-onERC721Received}.
//      *
//      * Always returns `IERC721Receiver.onERC721Received.selector`.
//      */
//     function onBEP721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
//         return this.onBEP721Received.selector;
//     }
// }