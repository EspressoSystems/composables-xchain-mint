pragma solidity 0.8.30;

abstract contract SaleTimeAndPrice {
    uint256 public constant MIN_PRICE_WEI = 1000; // 0,000001 ETH
    uint256 public startSale;
    uint256 public endSale;
    uint256 public nftSalePriceWei;

    error StartDateInPastNotAllowed(uint256 startSale, uint256 currentTime);
    error EndDateLessThanStartDateNotAllowed(uint256 startSale, uint256 currentTime);
    error SaleFinishedOrNotStarted(uint256 startSale, uint256 endSale, uint256 currentTime);
    error LowPriceInWei(uint256 minPriceWei, uint256 nftSalePriceWei);

    event SaleTimelinesSet(uint256 startSale, uint256 endSale);
    event NftSalePriceSet(uint256 price);

    modifier whenSaleOpen() {
        if (!isSaleOpen()) revert SaleFinishedOrNotStarted(startSale, endSale, block.timestamp);
        _;
    }

    constructor(uint256 _startSale, uint256 _endSale, uint256 _nftSalePriceWei) {
        _setSaleTimelines(_startSale, _endSale);
        _setPrice(_nftSalePriceWei);
    }

    function _setSaleTimelines(uint256 _startSale, uint256 _endSale) internal {
        if (_startSale < block.timestamp) revert StartDateInPastNotAllowed(_startSale, block.timestamp);
        if (_endSale <= _startSale) revert EndDateLessThanStartDateNotAllowed(_startSale, _endSale);

        startSale = _startSale;
        endSale = _endSale;
        emit SaleTimelinesSet(startSale, endSale);
    }

    function _setPrice(uint256 _nftSalePriceWei) internal {
        if (_nftSalePriceWei < MIN_PRICE_WEI) revert LowPriceInWei(MIN_PRICE_WEI, _nftSalePriceWei);
        nftSalePriceWei = _nftSalePriceWei;
        emit NftSalePriceSet(_nftSalePriceWei);
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= startSale && block.timestamp <= endSale;
    }
}
