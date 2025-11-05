pragma solidity 0.8.30;

import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import "../src/libs/Treasury.sol";
import "./EspNFT.sol";

contract EspHypERC20 is HypERC20, Treasury {
    using TypeCasts for address;

    uint8 public constant VERSION = 2;

    address public rariMarketplace;

    // The Hyperlane domain ID of the destination chain.
    uint32 public destinationDomainId;
    uint256 public hookPayment;

    event MarketplaceSet(address marketplaceAddress);
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
        uint32 _destinationDomainId,
        uint256 _hookPayment,
        TreasuryConfig memory _treasury
    ) external reinitializer(VERSION) {
        rariMarketplace = _rariMarketplace;
        emit MarketplaceSet(_rariMarketplace);

        destinationDomainId = _destinationDomainId;
        emit DestinationDomainIdSet(_destinationDomainId);

        hookPayment = _hookPayment;
        emit HookPaymentAmountSet(_hookPayment);

        _setTreasury(_treasury);
    }

    /**
     * @dev Mints `_amount` of token to `treasury` balance and Mints NFT on `_recipient`.
     * Sends bridged tokens to the treasury if NFT mint successed. Mints NFT on _recipient address
     * Sends bridged tokens back to the recipient on source chain if NFT mint failed via low level bridgeBack() call.
     * Detailed flow:
     * 1. We have some amount of ETH on a synthetic ERC20 token.
     * 2. If the NFT mint fails, we mint a synthetic on the address(this).
     * 3. Call _transferRemote via self external call bridgeBack with updated msg.value.
     * 4. _transferRemote will do the verification that msg.value can cover gas fees, including minting back.
     * It will properly initiate bridging back native ETH on the source chain.
     * @inheritdoc HypERC20
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata // no external metadata
    ) internal virtual override {
        (bool success,) = rariMarketplace.call(abi.encodeWithSelector(EspNFT.mint.selector, _recipient));
        if (success) {
            _treasuryMint(_amount);
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

    function _treasuryMint(uint256 _amount) internal {
        uint256 mainAmount = _amount * treasury.percentageEspresso / ONE_HUNDRED_PERCENT;
        _mint(treasury.espresso, mainAmount);

        if (treasury.percentageEspresso != ONE_HUNDRED_PERCENT) {
            _mint(treasury.partner, _amount - mainAmount);
        }
    }

    /**
     * @dev Send bridged tokens back to the source chain in case NFT mint failed.
     */
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

    /**
     * Allows to receive ETH and pay gas fees during bridgeBack() execution
     */
    receive() external payable {}
}
