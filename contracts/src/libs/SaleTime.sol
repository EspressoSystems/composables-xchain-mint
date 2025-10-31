pragma solidity 0.8.30;

abstract contract SaleTime {
    uint256 public startSale;
    uint256 public endSale;

    error StartDateInPastNotAllowed(uint256 startSale, uint256 currentTime);
    error SaleFinishedOrNotStarted(uint256 startSale, uint256 endSale, uint256 currentTime);

    event SaleTimelinesSet(uint256 startSale, uint256 endSale);

    modifier whenSaleOpen() {
        if (!isSaleOpen()) revert SaleFinishedOrNotStarted(startSale, endSale, block.timestamp);
        _;
    }

    constructor(uint256 _startSale) {
        _setSaleTimelines(_startSale);
    }

    function _setSaleTimelines(uint256 _startSale) internal {
        if (_startSale > block.timestamp) revert StartDateInPastNotAllowed(_startSale, block.timestamp);

        startSale = _startSale;
        endSale = startSale + 3 weeks;
        emit SaleTimelinesSet(startSale, endSale);
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= startSale && block.timestamp <= endSale;
    }
}
