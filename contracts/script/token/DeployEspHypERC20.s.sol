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
import {EspHypERC20} from "../../src/EspHypERC20.sol";
import {ICREATE3Factory} from "../../src/ICREATE3Factory.sol";

contract DeployEspHypERC20Script is Script, Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    function run() public {
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
        // ISM
        address ism = vm.envAddress("ISM_ADDRESS");
        address marketplaceAddress = vm.envAddress("MARKETPLACE_ADDRESS");
        address payable treasuryAddress = payable(vm.envAddress("TREASURY_ADDRESS"));
        uint256 hookPayment = vm.envUint("HOOK_PAYMENT");
        uint256 gasFeesDeposit = vm.envUint("GAS_FEES_DEPOSIT_WEI");

        vm.startBroadcast();

        EspHypERC20 espressoERC20TokenImplementation = new EspHypERC20(decimals, scale, mailbox);
        address impl = address(espressoERC20TokenImplementation);

        // Correct initData: call base initialize
        bytes memory initData = abi.encodeWithSelector(
            EspHypERC20.initializeV2.selector,
            aggHook,
            ism,
            owner
        );

        bytes memory proxyCreationCode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(impl, admin, initData)
        );

        address token = factory.deploy(saltBytes, proxyCreationCode);

        // Upgrade and call initializeV2
        ProxyAdmin proxyAdminObj = ProxyAdmin(admin);
        bytes memory v2Data = abi.encodeWithSelector(
            EspHypERC20.initializeV2.selector,
            marketplaceAddress,
            treasuryAddress,
            remoteDomain,
            hookPayment
        );
        proxyAdminObj.upgradeAndCall(ITransparentUpgradeableProxy(token), impl, v2Data);

        // Top up for gas fees
        (bool success,) = token.call{value: gasFeesDeposit}("");
        require(success, "ETH EspHypERC20 transfer failed");

        // Enroll remote if set
        if (remoteTokenBytes != bytes32(0)) {
            EspHypERC20(payable(token)).enrollRemoteRouter(remoteDomain, remoteTokenBytes);
        }

        vm.stopBroadcast();
    }
}