// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {EspNFT} from "../../../src/EspNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract UpdateOwnershipsScript is Script {
    address newOwnerAddress = vm.envAddress("HYPERLANE_ESPRESSO_ADMIN");

    address proxyAdminAddress = vm.envAddress("SOURCE_PROXY_ADMIN_ADDRESS");
    address mailboxAddress = vm.envAddress("SOURCE_MAILBOX_ADDRESS");
    address testRecipientAddress = vm.envAddress("TEST_RECIPIENT_ADDRESS");
    address interchainGasPaymasterAddress = vm.envAddress("IGP_ADDRESS");

    // ESP contract change ownership. Warp Route native and synthetic upgradeable tokens.
    // No need to update proxy owner because owner of main proxy admin contract updated below.
    address espNativeAddress = vm.envAddress("SOURCE_TO_DESTINATION_TOKEN_ADDRESS");
    address espErc20Address = vm.envAddress("DESTINATION_TO_SOURCE_TOKEN_ADDRESS");
    // Same address for 2 chains
    address espNftAddress = vm.envAddress("SOURCE_NFT_ADDRESS");

    function run() public {
        vm.startBroadcast();

        Ownable espNative = Ownable(espNativeAddress);
        espNative.transferOwnership(newOwnerAddress);

        Ownable espErc20 = Ownable(espErc20Address);
        espErc20.transferOwnership(newOwnerAddress);

        Ownable mailbox = Ownable(mailboxAddress);
        mailbox.transferOwnership(newOwnerAddress);

        Ownable testRecipient = Ownable(testRecipientAddress);
        testRecipient.transferOwnership(newOwnerAddress);

        Ownable interchainGasPaymaster = Ownable(interchainGasPaymasterAddress);
        interchainGasPaymaster.transferOwnership(newOwnerAddress);

        Ownable proxyAdmin = Ownable(proxyAdminAddress);
        proxyAdmin.transferOwnership(newOwnerAddress);

        EspNFT espNft = EspNFT(espNftAddress);
        espNft.grantRole(espNft.DEFAULT_ADMIN_ROLE(), newOwnerAddress);
        espNft.renounceRole(espNft.DEFAULT_ADMIN_ROLE(), msg.sender);

        vm.stopBroadcast();
    }
}
