pragma solidity 0.8.30;

import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import "./mocks/MockERC721.sol";

contract EspHypERC20 is HypERC20 {
    using TypeCasts for address;

    uint8 public constant VERSION = 2;
    address public rariMarketplace;
    address payable public treasury;

    // The Hyperlane domain ID of the destination chain.
    uint32 public destinationDomainId;
    uint256 public hookPayment = 0.001 ether;

    event MarketplaceSet(address marketplaceAddress);
    event TreasurySet(address treasuryAddress);
    event DestinationDomainIdSet(uint32 domainId);

    error BridgeBackFailed();

    constructor(uint8 __decimals, uint256 _scale, address _mailbox) HypERC20(__decimals, _scale, _mailbox) {
        _disableInitializers();
    }

    function initializeV2(address _rariMarketplace, address payable _treasury, uint32 _destinationDomainId)
        external
        reinitializer(VERSION)
    {
        rariMarketplace = _rariMarketplace;
        emit MarketplaceSet(_rariMarketplace);

        treasury = _treasury;
        emit TreasurySet(_treasury);

        destinationDomainId = _destinationDomainId;
        emit DestinationDomainIdSet(_destinationDomainId);
    }

    /**
     * @dev Mints `_amount` of token to `_recipient` balance.
     * Sends bridged tokens to the recipient if NFT mint failed, send to treasury if success.
     * @inheritdoc HypERC20
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata // no external metadata
    ) internal virtual override {
        (bool success,) = rariMarketplace.call(abi.encodeWithSelector(MockERC721.mint.selector, _recipient));
        if (success) {
            _mint(treasury, _amount);
        } else {
            _mint(msg.sender, _amount);

            (bool result,) = address(this).call{value: hookPayment}(
                abi.encodeWithSignature("bridgeBack(bytes32,uint256)", _recipient.addressToBytes32(), _amount)
            );
            if (!result) revert BridgeBackFailed();
        }
    }

    function bridgeBack(bytes32 _recipient, uint256 _amount) public payable returns (bytes32 messageId) {
        return _transferRemote(destinationDomainId, _recipient, _amount, msg.value);
    }

    receive() external payable {}
}
