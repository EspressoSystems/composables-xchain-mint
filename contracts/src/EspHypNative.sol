pragma solidity 0.8.30;

import "./hyperlane/HypNative.sol";
import "../src/libs/SaleTimeAndPrice.sol";

contract EspHypNative is HypNative, SaleTimeAndPrice {
    uint8 public constant VERSION = 2;

    // The Hyperlane domain ID of the destination chain.
    uint32 public destinationDomainId;

    event DestinationDomainIdSet(uint32 domainId);

    error UseInitiateCrossChainNftPurchaseFunction();
    error NftPriceExceedsMsgValue(uint256 nftPrice, uint256 msgValue);

    constructor(uint256 _scale, address _mailbox, uint256 _startSale, uint256 _nftSalePrice)
        HypNative(_scale, _mailbox)
        SaleTimeAndPrice(_startSale, _nftSalePrice)
    {
        _disableInitializers;
    }

    /**
     * @notice Initializes the Hyperlane router
     * @param _hook The post-dispatch hook contract.
     *    @param _interchainSecurityModule The interchain security module contract.
     *    @param _owner The this contract.
     *    @param _nftSalePrice The NFT sale price in Wei.
     *    @param _destinationDomainId The Hyperlane domain ID of the destination chain.
     */
    function initializeV3(
        address _hook,
        address _interchainSecurityModule,
        address _owner,
        uint256 _nftSalePrice,
        uint32 _destinationDomainId,
        uint256 _startSale
    ) public initializer {
        _MailboxClient_initialize(_hook, _interchainSecurityModule, _owner);
        _initializeV2(_nftSalePrice, _destinationDomainId, _startSale);
    }

    function initializeV2(uint256 _nftSalePrice, uint32 _destinationDomainId, uint256 _startSale)
        external
        reinitializer(VERSION)
        onlyOwner
    {
        destinationDomainId = _destinationDomainId;
        emit DestinationDomainIdSet(_destinationDomainId);
        _setSaleTimelines(_startSale);
        _setPrice(_nftSalePrice);
    }

    function setSalePrice(uint256 _nftSalePrice) external onlyOwner {
        _setPrice(_nftSalePrice);
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
     *     NOTE: `msg.value` will be greater than `nftSalePriceWei`, since it includes funds to cover cross-chain gas payment.
     *        The post-dispatch IGP hook handles cross-chain gas payment errors, so there is no need to check here if the user has supplied
     *        sufficient cross-chain gas funds.
     *     @param _recipient The address of the recipient on the destination chain; this MUST be the user's address on the destination chain.
     */
    function initiateCrossChainNftPurchase(bytes32 _recipient)
        external
        payable
        whenSaleOpen
        returns (bytes32 messageId)
    {
        if (msg.value < nftSalePriceWei) {
            revert NftPriceExceedsMsgValue(nftSalePriceWei, msg.value);
        }

        uint256 hookPayment = msg.value - nftSalePriceWei;

        return _transferRemote(destinationDomainId, _recipient, nftSalePriceWei, hookPayment);
    }

    function _initializeV2(uint256 _nftSalePrice, uint32 _destinationDomainId, uint256 _startSale) internal {
        _initializeV2(_nftSalePrice, _destinationDomainId, _startSale);
    }
}
