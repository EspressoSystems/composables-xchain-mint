// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {HypERC20} from "lib/hyperlane-monorepo/solidity/contracts/token/HypERC20.sol";
import {CallLib} from "lib/hyperlane-monorepo/solidity/contracts/middleware/libs/Call.sol";
import {InterchainAccountRouter} from "lib/hyperlane-monorepo/solidity/contracts/middleware/InterchainAccountRouter.sol";
import {TypeCasts} from "lib/hyperlane-monorepo/solidity/contracts/libs/TypeCasts.sol";
import {IInterchainGasPaymaster} from "lib/hyperlane-monorepo/solidity/contracts/interfaces/IInterchainGasPaymaster.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function icaTest() public payable {

        //  InterchainAccountRouter(address(0x68B1D87F95878fE05B998F19b66F4baba5De1aed)).enrollRemoteRouterAndIsm(1380012617, TypeCasts.addressToBytes32(address(0x68B1D87F95878fE05B998F19b66F4baba5De1aed)),  TypeCasts.addressToBytes32(address(0x9A676e781A523b5d0C0e43731313A708CB607508)));

        CallLib.Call memory call = CallLib.Call({to: bytes32(bytes20(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720)), data: "hello", value: 0});
        CallLib.Call[] memory calls = new CallLib.Call[](1);
        calls[0] = call;
        uint32 rariDomain = 1380012617;
        address routerAddress = 0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8;
        IInterchainGasPaymaster gasPaymaster = IInterchainGasPaymaster(0x457cCf29090fe5A24c19c1bc95F492168C0EaFdb);
        uint256 gasPayment = gasPaymaster.quoteGasPayment(rariDomain, 1000);
        IInterchainAccountRouter(routerAddress).callRemote{value: 200000}(rariDomain, calls);
    }

    /**
     * @notice Registers a remote InterchainAccountRouter and ISM on a given destination domain.
     * @param _icaRouter The address of the local InterchainAccountRouter contract.
     * @param _destinationDomain The Hyperlane domain ID of the remote chain.
     * @param _remoteRouter The address of the remote InterchainAccountRouter.
     * @param _remoteIsm The address of the remote InterchainSecurityModule (ISM).
     */
    function registerIcaRouter(
        address _icaRouter,
        uint32 _destinationDomain,
        address _remoteRouter,
        address _remoteIsm
    ) private {
        // Convert addresses to bytes32 for the Enroll API.
        bytes32 routerKey = TypeCasts.addressToBytes32(_remoteRouter);
        bytes32 ismKey = TypeCasts.addressToBytes32(_remoteIsm);

        // Call the Hyperlane InterchainAccountRouter to enroll the router and ISM.
        InterchainAccountRouter(_icaRouter).enrollRemoteRouterAndIsm(
            _destinationDomain,
            routerKey,
            ismKey
        );
    }
}


interface IInterchainAccountRouter {
    function callRemote(
        uint32 _destinationDomain,
        CallLib.Call[] calldata calls
    ) external payable returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address);
}
