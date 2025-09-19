pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";

contract HypERC20Test is Test {
    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);
    string public name = "Espresso Composables WETH";
    string public symbol = "ECWETH";
    uint8 public decimals = 18;

    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public recipient = address(1);
    address public hypERC20SourceToDestinationTokenAddress = vm.envAddress("SOURCE_TO_DESTINATION_TOKEN_ADDRESS");
    address public hypERC20DestinationToSourceTokenAddress = vm.envAddress("DESTINATION_TO_SOURCE_TOKEN_ADDRESS");

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    /**
     * @dev Test checks destination ERC20 token name and symbol
     */
    function testXChainVerifyHypNameAndSymbolDestinationErc20() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20SourceToDestinationTokenAddress));

        assertEq(hypERC20Token.symbol(), symbol);
        assertEq(hypERC20Token.name(), name);
        assertEq(hypERC20Token.decimals(), decimals);
    }

    /**
     * @dev Test checks source ERC20 token name and symbol
     */
    function testXChainVerifyHypNameAndSymbolSourceErc20() public {
        vm.selectFork(sourceChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20DestinationToSourceTokenAddress));

        assertEq(hypERC20Token.symbol(), symbol);
        assertEq(hypERC20Token.name(), name);
        assertEq(hypERC20Token.decimals(), decimals);
    }
}