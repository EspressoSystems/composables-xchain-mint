pragma solidity 0.8.30;

import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";

contract EspressoERC20 is HypERC20 {

    constructor(
        uint8 _decimals,
        uint256 _scale,
        address _mailbox
    ) HypERC20(_decimals, _scale, _mailbox) {}
}
