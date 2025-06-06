// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

import {CallLib} from "lib/hyperlane-monorepo/solidity/contracts/middleware/libs/Call.sol";
import {InterchainAccountRouter} from "lib/hyperlane-monorepo/solidity/contracts/middleware/InterchainAccountRouter.sol";
import {TypeCasts} from "lib/hyperlane-monorepo/solidity/contracts/libs/TypeCasts.sol";
import {IInterchainGasPaymaster} from "lib/hyperlane-monorepo/solidity/contracts/interfaces/IInterchainGasPaymaster.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_ICA() public {
        vm.startPrank(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        InterchainAccountRouter(address(0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8)).enrollRemoteRouterAndIsm(
            1380012617,
            TypeCasts.addressToBytes32(address(0x68B1D87F95878fE05B998F19b66F4baba5De1aed)),
            TypeCasts.addressToBytes32(address(0x9A676e781A523b5d0C0e43731313A708CB607508))
        );

        IInterchainGasPaymaster gasPaymaster = IInterchainGasPaymaster(0x457cCf29090fe5A24c19c1bc95F492168C0EaFdb);

        uint256 gasPayment = gasPaymaster.quoteGasPayment(1380012617, 50_000);
        uint256 gasPayment2 =
            InterchainAccountRouter(address(0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8)).quoteGasPayment(1380012617);

        counter.icaTest{value: gasPayment + gasPayment2}();
    }
}

interface IInterchainAccountRouter {
    function callRemote(uint32 _destinationDomain, CallLib.Call[] calldata calls) external payable returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner) external view returns (address);
}

// contract AnvilTest is Test {
//     Counter public counter;

//     function setUp() public {
//         counter = new Counter();
//         counter.setNumber(0);
//     }

//     function test_ICA() public {
//         counter.icaTest();
//     }
// }
