pragma solidity 0.8.30;

abstract contract SaleTimeAndPrice {
    uint256 public startSale;
    uint256 public endSale;

    // The NFT sale price in Wei
    uint256 public nftSalePrice;

    error StartDateInPastNotAllowed(uint256 startSale, uint256 currentTime);
    error SaleFinishedOrNotStarted(uint256 startSale, uint256 endSale, uint256 currentTime);

    event SaleTimelinesSet(uint256 startSale, uint256 endSale);
    event NftSalePriceSet(uint256 price);

    modifier whenSaleOpen() {
        if (!isSaleOpen()) revert SaleFinishedOrNotStarted(startSale, endSale, block.timestamp);
        _;
    }

    constructor(uint256 _startSale, uint256 _nftSalePrice) {
        _setSaleTimelines(_startSale);
        _setPrice(_nftSalePrice);
    }

    function _setSaleTimelines(uint256 _startSale) internal {
        if (_startSale > block.timestamp) revert StartDateInPastNotAllowed(_startSale, block.timestamp);

        startSale = _startSale;
        endSale = startSale + 3 weeks;
        emit SaleTimelinesSet(startSale, endSale);
    }

    function _setPrice(uint256 _nftSalePrice) internal {
        nftSalePrice = _nftSalePrice;
        emit NftSalePriceSet(_nftSalePrice);
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= startSale && block.timestamp <= endSale;
    }
}
