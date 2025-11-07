pragma solidity 0.8.30;

import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";

contract EspHypNativeSpec is HypNative {
    constructor(uint256 nft_sale_price, uint256 _scale, address _mailbox) HypNative(_scale, _mailbox) {
        // Set contract constants
        NFT_SALE_PRICE = nft_sale_price;
    }

    // The NFT sale price in Wei
    uint256 NFT_SALE_PRICE;

    // The Hyperlane domain ID of the destination chain.
    uint32 DESTINATION_DOMAIN_ID;

    /**
     * @dev Entry point for a cross-chain NFT purchase.
     *     NOTE: `msg.value` will be greater than `nftSalePriceWei`, since it includes funds to cover cross-chain gas payment.
     *        The post-dispatch IGP hook handles cross-chain gas payment errors, so there is no need to check here if the user has supplied
     *        sufficient cross-chain gas funds.
     *     @param _recipient The address of the recipient on the destination chain; this MUST be the user's address on the destination chain.
     */
    function initiateCrossChainNFTPurchase(bytes32 _recipient) external payable returns (bytes32 messageId) {
        return _transferRemote(DESTINATION_DOMAIN_ID, _recipient, NFT_SALE_PRICE, msg.value);
    }

    function transferRemote(uint32, bytes32, uint256) external payable override returns (bytes32) {
        revert("Use `initiateCrossChainNFTPurchase` function instead");
    }
}
