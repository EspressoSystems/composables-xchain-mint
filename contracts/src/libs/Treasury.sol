pragma solidity 0.8.30;

abstract contract Treasury {
    uint256 public constant ONE_HUNDRED_PERCENT = 10000; // 100%

    struct TreasuryConfig {
        address payable espresso;
        address payable partner;
        uint256 percentageEspresso;
    }

    TreasuryConfig internal treasury;

    error NotValidTreasuryPercentage();
    error ZeroAddress();

    event TreasurysSet(address main, address secondary, uint256 percentageEspresso);

    function _setTreasury(TreasuryConfig memory _treasury) internal {
        if (_treasury.espresso == address(0) || _treasury.partner == address(0)) revert ZeroAddress();
        if (_treasury.percentageEspresso > ONE_HUNDRED_PERCENT) revert NotValidTreasuryPercentage();

        treasury = _treasury;
        emit TreasurysSet(_treasury.espresso, _treasury.partner, _treasury.percentageEspresso);
    }

    function getTreasury() public view returns (address, address, uint256) {
        return (treasury.espresso, treasury.partner, treasury.percentageEspresso);
    }
}
