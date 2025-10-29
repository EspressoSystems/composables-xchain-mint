// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/src/Script.sol";
import "forge-std/src/Test.sol";
import "../../script/configs/HyperlaneAddressesConfig.sol";
import {StaticAggregationHookFactory} from "@hyperlane-core/solidity/contracts/hooks/aggregation/StaticAggregationHookFactory.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {EspHypNative} from "../../src/EspHypNative.sol";
import {ICREATE3Factory} from "../../src/ICREATE3Factory.sol";

contract DeployEspHypNativeScript is Script, Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    function run() public {
        uint32 remoteDomain = uint32(vm.envUint("REMOTE_DOMAIN"));
        bytes32 remoteTokenBytes = vm.envAddress("REMOTE_TOKEN").addressToBytes32();
        address owner = vm.envAddress("OWNER");
        address admin = vm.envAddress("ADMIN");
        uint256 scale = vm.envUint("SCALE");
        bytes32 saltBytes = keccak256(bytes(vm.envString("SALT")));
        address factoryAddr = vm.envAddress("CREATE3_FACTORY_ADDRESS");
        ICREATE3Factory factory = ICREATE3Factory(factoryAddr);
        address mailbox = sourceConfig.mailbox; // Same on both
        // Deploy aggregation hook
        StaticAggregationHookFactory aggFactory =
            StaticAggregationHookFactory(sourceConfig.staticAggregationHookFactory);
        address[] memory hooksArr = new address[](2);
        hooksArr[0] = sourceConfig.interchainGasPaymaster;
        hooksArr[1] = sourceConfig.merkleTreeHook;
        address aggHook = aggFactory.deploy(hooksArr);
        // ISM
        address ism = vm.envAddress("ISM_ADDRESS");
        uint256 nftPrice = vm.envUint("NFT_SALE_PRICE");

        vm.startBroadcast();

        EspHypNative espressoNativeTokenImplementation = new EspHypNative(scale, mailbox);
        address impl = address(espressoNativeTokenImplementation);

        // Correct initData: call base initialize
        bytes memory initData = abi.encodeWithSelector(EspHypNative.initializeV2.selector, aggHook, ism, owner);

        bytes memory proxyCreationCode =
            abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(impl, admin, initData));

        address token = factory.deploy(saltBytes, proxyCreationCode);

        // Upgrade and call initializeV2
        ProxyAdmin proxyAdminObj = ProxyAdmin(admin);
        bytes memory v2Data = abi.encodeWithSelector(EspHypNative.initializeV2.selector, nftPrice, remoteDomain);
        proxyAdminObj.upgradeAndCall(ITransparentUpgradeableProxy(token), impl, v2Data);

        // Enroll remote if set
        if (remoteTokenBytes != bytes32(0)) {
            EspHypNative(payable(token)).enrollRemoteRouter(remoteDomain, remoteTokenBytes);
        }

        vm.stopBroadcast();
    }
}
