pragma solidity ^0.8.13;

contract HyperlaneAddressesConfig {
    struct Config {
        address domainRoutingIsmFactory;
        address interchainAccountIsm;
        address interchainAccountRouter;
        address interchainGasPaymaster;
        address mailbox;
        address merkleTreeHook;
        address proxyAdmin;
        address staticAggregationHookFactory;
        address staticAggregationIsmFactory;
        address staticMerkleRootMultisigIsmFactory;
        address staticMerkleRootWeightedMultisigIsmFactory;
        address staticMessageIdMultisigIsmFactory;
        address staticMessageIdWeightedMultisigIsmFactory;
        address testRecipient;
        address validatorAnnounce;
    }

    Config public sourceConfig = Config({
        domainRoutingIsmFactory: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9,
        interchainAccountIsm: 0x3Aa5ebB10DC797CAC828524e59A333d0A371443c,
        interchainAccountRouter: 0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44,
        interchainGasPaymaster: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1,
        mailbox: 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318,
        merkleTreeHook: 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e,
        proxyAdmin: 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853,
        staticAggregationHookFactory: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9,
        staticAggregationIsmFactory: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,
        staticMerkleRootMultisigIsmFactory: 0x5FbDB2315678afecb367f032d93F642f64180aa3,
        staticMerkleRootWeightedMultisigIsmFactory: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707,
        staticMessageIdMultisigIsmFactory: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512,
        staticMessageIdWeightedMultisigIsmFactory: 0x0165878A594ca255338adfa4d48449f69242Eb8F,
        testRecipient: 0x4A679253410272dd5232B3Ff7cF5dbB88f295319,
        validatorAnnounce: 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f
    });

    /// @notice Addresses are the same.
    Config public destinationConfig = sourceConfig;
}
