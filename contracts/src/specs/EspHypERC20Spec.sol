pragma solidity 0.8.30;

import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";

contract EspHypERC20Spec is HypERC20 {
    constructor(uint8 __decimals, uint256 _scale, address _mailbox) HypERC20(__decimals, _scale, _mailbox) {}
}
