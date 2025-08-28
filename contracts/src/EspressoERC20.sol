pragma solidity 0.8.30;
import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";

contract EspressoERC20 is HypERC20 {
    address public rariMarketplace;
    address payable public treasury;

    event MarketplaceSet(address marketplaceAddress);
    event TreasurySet(address treasuryAddress);

    error EspressoERC20Initiated();

    constructor(
        uint8 __decimals,
        uint256 _scale,
        address _mailbox
    ) HypERC20(__decimals, _scale, _mailbox) {}

    function setUp(address marketplaceAddress, address payable treasuryAddress) external virtual {
        if (rariMarketplace != address(0) || treasury != address(0)) revert EspressoERC20Initiated();

        rariMarketplace = marketplaceAddress;
        emit MarketplaceSet(marketplaceAddress);

        treasury = treasuryAddress;
        emit TreasurySet(treasuryAddress);
    }

    /**
     * @dev Mints `_amount` of token to `_recipient` balance.
     * Sends bridged tokens to the recipient if NFT mint failed, send to treasury if success.
     * @inheritdoc HypERC20
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual override {
        (bool success,) = rariMarketplace.call(_data);

        if (success) {
            _mint(treasury, _amount);
        } else {
            _mint(_recipient, _amount);
        }
    }
}
