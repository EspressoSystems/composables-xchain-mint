// <ai_context>
// This script deploys ProxyAdmin using CREATE3 for deterministic address.
// </ai_context>
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;
import "forge-std/src/Script.sol";
import "forge-std/src/console.sol";
import {ProxyAdmin} from "@openzeppelin-contracts-v5/proxy/transparent/ProxyAdmin.sol";
import {ICREATE3Factory} from "../../src/ICREATE3Factory.sol";

contract DeployProxyAdminScript is Script {
    function run() public {
        address factoryAddr = vm.envAddress("CREATE3_FACTORY_ADDRESS");
        ICREATE3Factory factory = ICREATE3Factory(factoryAddr);
        bytes32 saltBytes = keccak256(bytes(vm.envString("SALT")));
        address owner = vm.envAddress("OWNER");
        bytes memory creationCode = abi.encodePacked(type(ProxyAdmin).creationCode, abi.encode(owner));
        vm.startBroadcast();
        address deployed = factory.deploy(saltBytes, creationCode);
        vm.stopBroadcast();
        console.log("ProxyAdmin deployed at: %s", deployed);
    }
}
