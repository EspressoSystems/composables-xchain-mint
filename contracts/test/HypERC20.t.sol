pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import "../src/EspHypERC20.sol";

contract HypERC20Test is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = espSourceConfig.destinationChainId;
    string public name = "Espresso Composables WETH";
    string public symbol = "ECWETH";
    uint8 public decimals = 18;

    address public deployer = espSourceConfig.deployer;
    address public recipient = address(1);
    address public hypERC20SourceToDestinationTokenAddress = vm.envAddress("SOURCE_TO_DESTINATION_TOKEN_ADDRESS");
    address public hypERC20DestinationToSourceTokenAddress = vm.envAddress("DESTINATION_TO_SOURCE_TOKEN_ADDRESS");
    address public treasury = vm.envAddress("TREASURY_ADDRESS");
    address public nftAddress = vm.envAddress("DESTINATION_NFT_ADDRESS");
    uint256 public hookPayment = vm.envUint("BRIDGE_BACK_PAYMENT_AMOUNT_WEI");
    uint32 public destinationDomainId = uint32(vm.envUint("SOURCE_CHAIN_ID"));

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    /**
     * @dev Test checks destination ERC20 token name and symbol
     */
    function testXChainVerifyHypNameAndSymbolDestinationErc20() public {
        vm.selectFork(destinationChain);
        EspHypERC20 hypERC20Token = EspHypERC20(payable(hypERC20SourceToDestinationTokenAddress));

        assertEq(hypERC20Token.symbol(), symbol);
        assertEq(hypERC20Token.name(), name);
        assertEq(hypERC20Token.decimals(), decimals);
    }

    /**
     * @dev Test checks source ERC20 token name and symbol
     */
    function testXChainVerifyHypNameAndSymbolSourceErc20() public {
        vm.selectFork(sourceChain);
        EspHypERC20 hypERC20Token = EspHypERC20(payable(hypERC20DestinationToSourceTokenAddress));

        assertEq(hypERC20Token.symbol(), symbol);
        assertEq(hypERC20Token.name(), name);
        assertEq(hypERC20Token.decimals(), decimals);
    }

    /**
     * @dev Test checks that NFT address, treasury, hookPayment amount and destination domain id are set.
     */
    function testXChainVerifyParamsSet() public {
        vm.selectFork(destinationChain);
        EspHypERC20 hypERC20Token = EspHypERC20(payable(hypERC20SourceToDestinationTokenAddress));

        assertEq(hypERC20Token.rariMarketplace(), nftAddress);
        assertEq(hypERC20Token.treasury(), treasury);
        assertEq(hypERC20Token.destinationDomainId(), destinationDomainId);
        assertEq(hypERC20Token.hookPayment(), hookPayment);
    }

    /**
     * @dev Test checks that bridgeBack() function called only by EspHypERC20 contract.
     */
    function testXChainBridgeBackOnlyEspHypERC20() public payable {
        vm.selectFork(destinationChain);
        EspHypERC20 hypERC20Token = EspHypERC20(payable(hypERC20SourceToDestinationTokenAddress));

        vm.expectRevert(abi.encodeWithSelector(EspHypERC20.OnlyEspHypERC20.selector));
        hypERC20Token.bridgeBack(recipient.addressToBytes32(), 0.01 ether);
    }

    /**
     * @dev Test initiate _transferRemote if all validation pass in bridgeBack() function.
     */
    function testXChainBridgeBackSucceed() public {
        vm.selectFork(destinationChain);
        EspHypERC20 hypERC20Token = EspHypERC20(payable(hypERC20SourceToDestinationTokenAddress));

        vm.prank(address(hypERC20Token));

        // We expect revert here because caller doesn't have the tokens in the EspHypERC20 and it's expected result.
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        hypERC20Token.bridgeBack{value: 0.01 ether}(recipient.addressToBytes32(), hookPayment);
    }
}
