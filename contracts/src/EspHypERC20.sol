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
    uint256 public hookPayment;

    event MarketplaceSet(address marketplaceAddress);
    event TreasurySet(address treasuryAddress);
    event DestinationDomainIdSet(uint32 domainId);
    event HookPaymentAmountSet(uint256 hookPayment);

    error BridgeBackFailedWithUnknownReason();
    error OnlyEspHypERC20();
    error EspHypERC20BalanceCantCoverGasFees(uint256 contratBalance, uint256 hookPayment);

    constructor(uint8 __decimals, uint256 _scale, address _mailbox) HypERC20(__decimals, _scale, _mailbox) {
        _disableInitializers();
    }

    modifier onlyEspHypERC20() {
        if (msg.sender != address(this)) revert OnlyEspHypERC20();
        _;
    }

    function initializeV2(
        address _rariMarketplace,
        address payable _treasury,
        uint32 _destinationDomainId,
        uint256 _hookPayment
    ) external reinitializer(VERSION) {
        rariMarketplace = _rariMarketplace;
        emit MarketplaceSet(_rariMarketplace);

        treasury = _treasury;
        emit TreasurySet(_treasury);

        destinationDomainId = _destinationDomainId;
        emit DestinationDomainIdSet(_destinationDomainId);

        hookPayment = _hookPayment;
        emit HookPaymentAmountSet(_hookPayment);
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
            _mint(address(this), _amount);
            (bool result, bytes memory data) = address(this).call{value: hookPayment}(
                abi.encodeWithSignature("bridgeBack(bytes32,uint256)", _recipient.addressToBytes32(), _amount)
            );

            if (!result) {
                if (data.length > 0) {
                    assembly {
                        revert(add(data, 32), mload(data))
                    }
                } else {
                    revert BridgeBackFailedWithUnknownReason();
                }
            }
        }
    }

    function bridgeBack(bytes32 _recipient, uint256 _amount)
        external
        payable
        onlyEspHypERC20
        returns (bytes32 messageId)
    {
        if (address(this).balance < msg.value) {
            revert EspHypERC20BalanceCantCoverGasFees(address(this).balance, msg.value);
        }
        return _transferRemote(destinationDomainId, _recipient, _amount, msg.value);
    }

    receive() external payable {}
}
