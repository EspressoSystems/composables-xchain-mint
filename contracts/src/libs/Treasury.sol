pragma solidity 0.8.30;

abstract contract Treasury {
    uint256 constant ONE_HUNDRED_PERCENT = 100;

    struct TreasuryStruct {
        address payable main;
        address payable secondary;
        uint256 percentageMain;
    }

    TreasuryStruct internal treasury;

    error NotValidTreasuryPercentage();
    error ZeroAddress();

    event TreasurysSet(address main, address secondary, uint256 percentageMain);

    function _setTreasury(TreasuryStruct memory _treasury) internal {
        if (_treasury.main == address(0) || _treasury.secondary == address(0)) revert ZeroAddress();
        if (_treasury.percentageMain > ONE_HUNDRED_PERCENT) revert NotValidTreasuryPercentage();

        treasury = _treasury;
        emit TreasurysSet(_treasury.main, _treasury.secondary, _treasury.percentageMain);
    }

    function getTreasury() public view returns (address, address, uint256) {
        return (treasury.main, treasury.secondary, treasury.percentageMain);
    }
}
