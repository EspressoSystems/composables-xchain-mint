pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";

import "../src/mocks/MockERC721.sol";

contract EspressoEscrowTest is Test, HyperlaneAddressesConfig {
    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);

    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public recipient = address(1);
    address public hypERC20TokenAddress = 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    /**
     * @dev Test checks destination token name and symbol
     */
    function testXChainVerifyHypNameAnSymbol() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20TokenAddress));

        assertEq(hypERC20Token.symbol(), "ECWETH");
        assertEq(hypERC20Token.name(), "Espresso Composables WETH");
        assertEq(hypERC20Token.decimals(), 18);
    }
}
