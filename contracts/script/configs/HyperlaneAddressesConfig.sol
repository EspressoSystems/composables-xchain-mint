pragma solidity 0.8.30;

contract HyperlaneAddressesConfig {
    struct Config {
        address domainRoutingIsmFactory;
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

    struct EspConfig {
        address deployer;
        address sourceToDestinationEspTokenProxy;
        address sourceToDestinationEspTokenImplementation;
    }

    Config public sourceConfig = Config({
        staticMerkleRootMultisigIsmFactory: 0x5FbDB2315678afecb367f032d93F642f64180aa3,
        staticMessageIdMultisigIsmFactory: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512,
        staticAggregationIsmFactory: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,
        staticAggregationHookFactory: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9,
        domainRoutingIsmFactory: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9,
        staticMerkleRootWeightedMultisigIsmFactory: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707,
        staticMessageIdWeightedMultisigIsmFactory: 0x0165878A594ca255338adfa4d48449f69242Eb8F,
        proxyAdmin: 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853,
        mailbox: 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318,
        interchainAccountRouter: 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d,
        validatorAnnounce: 0x59b670e9fA9D0A427751Af201D676719a970857b,
        testRecipient: 0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1,
        merkleTreeHook: 0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE,
        interchainGasPaymaster: 0x0B306BF915C4d645ff596e518fAf3F9669b97016
    });

    EspConfig public espSourceConfig = EspConfig({
        deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        sourceToDestinationEspTokenProxy: 0x09635F643e140090A9A8Dcd712eD6285858ceBef,
        sourceToDestinationEspTokenImplementation: 0xf5059a5D33d5853360D16C683c16e67980206f36
    });

    /// @notice Addresses are the same.
    Config public destinationConfig = sourceConfig;
    EspConfig public espDestinationConfig = espSourceConfig;
}
