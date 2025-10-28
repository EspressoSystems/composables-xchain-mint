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
import {EspHypERC20} from "../../src/EspHypERC20.sol";
import {ICREATE3Factory} from "../../src/ICREATE3Factory.sol";

contract DeployEspHypTokenScript is Script, Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    function run() public {
        bool isNative = vm.envBool("IS_NATIVE");
        uint32 remoteDomain = uint32(vm.envUint("REMOTE_DOMAIN"));
        bytes32 remoteTokenBytes = vm.envAddress("REMOTE_TOKEN").addressToBytes32();
        address owner = vm.envAddress("OWNER");
        address admin = vm.envAddress("ADMIN");
        uint256 scale = vm.envUint("SCALE");
        uint8 decimals = uint8(vm.envUint("DECIMALS"));
        bytes32 saltBytes = keccak256(bytes(vm.envString("SALT")));
        address factoryAddr = vm.envAddress("CREATE3_FACTORY_ADDRESS");
        ICREATE3Factory factory = ICREATE3Factory(factoryAddr);
        address mailbox = sourceConfig.mailbox; // Same on both

        // Deploy aggregation hook
        StaticAggregationHookFactory aggFactory = StaticAggregationHookFactory(sourceConfig.staticAggregationHookFactory);
        address[] memory hooksArr = new address[](2);
        hooksArr[0] = sourceConfig.interchainGasPaymaster;
        hooksArr[1] = sourceConfig.merkleTreeHook;
        address aggHook = aggFactory.deploy(hooksArr);

        // ISM (assume set, use env or config)
        address ism = vm.envAddress("ISM_ADDRESS"); // Assume set in .env as SOURCE_ISM_ADDRESS etc.

        uint256 nftPrice = vm.envUint("NFT_SALE_PRICE");
        address marketplace = vm.envAddress("MARKETPLACE_ADDRESS");
        address payable treasuryAddr = payable(vm.envAddress("TREASURY_ADDRESS"));
        uint256 hookPaymentAmt = vm.envUint("HOOK_PAYMENT");

        vm.startBroadcast();

        address impl;
        bytes memory initData;
        if (isNative) {
            EspHypNative espressoNativeTokenImplementation = new EspHypNative(scale, mailbox);
            impl = address(espressoNativeTokenImplementation);
            initData = abi.encodeWithSelector(
                EspHypNative.initializeV2.selector,
                nftPrice,
                remoteDomain
            );
        } else {
            EspHypERC20 espressoERC20TokenImplementation = new EspHypERC20(decimals, scale, mailbox);
            impl = address(espressoERC20TokenImplementation);
            initData = abi.encodeWithSelector(
                EspHypERC20.initializeV2.selector,
                aggHook,
                ism,
                owner
            );
        }

        bytes memory proxyCreationCode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(impl, admin, initData)
        );

        address token = factory.deploy(saltBytes, proxyCreationCode);

        // Upgrade and call initializeV2
        ProxyAdmin proxyAdminObj = ProxyAdmin(admin);
        bytes memory v2Data;
        if (isNative) {
            v2Data = abi.encodeWithSelector(
                EspHypNative.initializeV2.selector,
                nftPrice,
                remoteDomain
            );
        } else {
            v2Data = abi.encodeWithSelector(
                EspHypERC20.initializeV2.selector,
                marketplace,
                treasuryAddr,
                remoteDomain,
                hookPaymentAmt
            );
        }
        proxyAdminObj.upgradeAndCall(ITransparentUpgradeableProxy(token), address(impl), v2Data);

        // Enroll remote if set
        if (remoteTokenBytes != bytes32(0)) {
            if (isNative) {
                EspHypNative(payable(token)).enrollRemoteRouter(remoteDomain, remoteTokenBytes);
            } else {
                EspHypERC20(payable(token)).enrollRemoteRouter(remoteDomain, remoteTokenBytes);
            }
        }

        vm.stopBroadcast();
    }
}