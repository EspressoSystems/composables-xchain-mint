// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {HypERC20} from "lib/hyperlane-monorepo/solidity/contracts/token/HypERC20.sol";
import {CallLib} from "lib/hyperlane-monorepo/solidity/contracts/middleware/libs/Call.sol";
import {InterchainAccountRouter} from "lib/hyperlane-monorepo/solidity/contracts/middleware/InterchainAccountRouter.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function icaTest() public {
        CallLib.Call memory call = CallLib.Call({to: bytes32(0), data: "hello", value: 0});
        CallLib.Call[] memory calls = new CallLib.Call[](1);
        calls[0] = call;
        uint32 rariDomain = 1380012617;
        try IInterchainAccountRouter(address(0x65dCf8F6b3f6a0ECEdf3d0bdCB036AEa47A1d615))
            .callRemote(rariDomain, calls)
        returns (bytes32) {}
        catch {}
    }
}

interface IInterchainAccountRouter {
    function callRemote(
        uint32 _destinationDomain,
        CallLib.Call[] calldata calls
    ) external returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address);
}
