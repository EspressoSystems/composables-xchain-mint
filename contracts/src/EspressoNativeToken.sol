pragma solidity 0.8.30;

import {TokenRouter} from "@hyperlane-core/solidity/contracts/token/libs/TokenRouter.sol";
import {FungibleTokenRouter} from "@hyperlane-core/solidity/contracts/token/libs/FungibleTokenRouter.sol";
import {TokenMessage} from "@hyperlane-core/solidity/contracts/token/libs/TokenMessage.sol";
import "./mocks/MockERC721.sol";
import "./hyperlane/HypNative.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


contract EspressoNativeToken is HypNative {

    constructor(
        uint256 _scale,
        address _mailbox
    ) HypNative(_scale, _mailbox) {}

    function _transferFromSender(
        uint256
    ) internal view virtual override returns (bytes memory) {
        return abi.encodeWithSelector(MockERC721.mint.selector, msg.sender);
    }
}
