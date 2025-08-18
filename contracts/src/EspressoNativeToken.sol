pragma solidity 0.8.30;

import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";

contract EspressoNativeToken is HypNative {
    event TransaferOnUpgrade();

    constructor(
        uint256 _scale,
        address _mailbox
    ) HypNative(_scale, _mailbox) {}

    function transferRemoteUpgrade(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external payable returns (bytes32 messageId) {
        emit TransaferOnUpgrade();
        require(msg.value >= _amount, "EspressoNative: amount exceeds msg.value");
        uint256 _hookPayment = msg.value - _amount;
        return _transferRemote(_destination, _recipient, _amount, _hookPayment);
    }
}
