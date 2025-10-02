pragma solidity 0.8.30;

import {TokenRouter} from "@hyperlane-core/solidity/contracts/token/libs/TokenRouter.sol";
import {FungibleTokenRouter} from "@hyperlane-core/solidity/contracts/token/libs/FungibleTokenRouter.sol";
import {TokenMessage} from "@hyperlane-core/solidity/contracts/token/libs/TokenMessage.sol";
import "./hyperlane/HypNative.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract EspHypNative is HypNative {
    uint8 public constant VERSION = 2;

    // The NFT sale price in Wei
    uint256 public nftSalePrice;

    // The Hyperlane domain ID of the destination chain.
    uint32 public destinationDomainId;

    event NftSalePriceSet(uint256 price);
    event DestinationDomainIdSet(uint32 domainId);

    error UseInitiateCrossChainNftPurchaseFunction();
    error NftPriceExceedsMsgValue(uint256 nftPrice, uint256 msgValue);

    constructor(uint256 _scale, address _mailbox) HypNative(_scale, _mailbox) {
        _disableInitializers;
    }

    function initializeV2(uint256 _nftSalePrice, uint32 _destinationDomainId) external reinitializer(VERSION) {
        nftSalePrice = _nftSalePrice;
        emit NftSalePriceSet(_nftSalePrice);

        destinationDomainId = _destinationDomainId;
        emit DestinationDomainIdSet(_destinationDomainId);
    }

    function transferRemote(uint32, bytes32, uint256) external payable override returns (bytes32) {
        revert UseInitiateCrossChainNftPurchaseFunction();
    }

    function transferRemote(uint32, bytes32, uint256, bytes calldata, address)
        external
        payable
        override
        returns (bytes32)
    {
        revert UseInitiateCrossChainNftPurchaseFunction();
    }

    function _transferFromSender(uint256) internal view virtual override returns (bytes memory) {
        return bytes(""); // no metadata
    }

    /**
     * @dev Entry point for a cross-chain NFT purchase.
     *     NOTE: `msg.value` will be greater than `nftSalePrice`, since it includes funds to cover cross-chain gas payment.
     *        The post-dispatch IGP hook handles cross-chain gas payment errors, so there is no need to check here if the user has supplied
     *        sufficient cross-chain gas funds.
     *     @param _recipient The address of the recipient on the destination chain; this MUST be the user's address on the destination chain.
     */
    function initiateCrossChainNftPurchase(bytes32 _recipient) external payable returns (bytes32 messageId) {
        if (msg.value < nftSalePrice) revert NftPriceExceedsMsgValue(nftSalePrice, msg.value);

        uint256 hookPayment = msg.value - nftSalePrice;

        return _transferRemote(destinationDomainId, _recipient, nftSalePrice, hookPayment);
    }
}
