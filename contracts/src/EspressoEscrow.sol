// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IMailbox} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IMailbox.sol";
import {IMessageRecipient} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IMessageRecipient.sol";
import {
    IInterchainSecurityModule,
    ISpecifiesInterchainSecurityModule
} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IInterchainSecurityModule.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./mocks/MockERC721.sol";

contract EspressoEscrow is AccessControl, IMessageRecipient {//, ISpecifiesInterchainSecurityModule {
    using TypeCasts for address;
    bytes32 public constant MAILBOX = keccak256("MAILBOX");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    IMailbox public immutable mailbox;
    address public immutable rariMarketplace;
    IInterchainSecurityModule private immutable _ismEspressoTEEVerifier;

    mapping(bytes32 sender => bool allowed) public allowedSenders;
    mapping(uint32 source => bool allowed) public allowedSources;
    mapping(uint32 destination => bool allowed) public allowedDestinations;

    event AllowedSenderAdded(bytes32 sender);
    event AllowedSenderRemoved(bytes32 sender);
    event AllowedSourceAdded(uint32 source);
    event AllowedSourceRemoved(uint32 source);
    event AllowedDestinationAdded(uint32 destination);
    event AllowedDestinationRemoved(uint32 destination);

    error NotAllowedSourceSender(bytes32 sender);
    error NotAllowedSource(uint32 source);
    error NotAllowedDestination(uint32 destinationId);
    error XChainMintFailed();
    error WithdrawFailed();
    error NothingToWithdraw();

    constructor(
        address mailboxAddress_,
        uint32 sourceChainId_,
        uint32 destinationChainId_,
        address ismEspressoTEEVerifier_,
        address rariMarketplace_
    ) {
        mailbox = IMailbox(mailboxAddress_);
        rariMarketplace = rariMarketplace_;
        _ismEspressoTEEVerifier = IInterchainSecurityModule(ismEspressoTEEVerifier_);

        _grantRole(ADMIN, msg.sender);
        _grantRole(MAILBOX, mailboxAddress_);
        addAllowedSource(sourceChainId_);
        addAllowedDestination(destinationChainId_);
    }

    modifier onlyMailbox() {
        _checkRole(MAILBOX);
        _;
    }

    modifier onlyAdmin() {
        _checkRole(ADMIN);
        _;
    }

    modifier onlyAllowedSource(uint32 source) {
        if (!allowedSources[source]) {
            revert NotAllowedSource(source);
        }
        _;
    }

    modifier onlyAllowedDestination(uint32 destinationId) {
        if (!allowedDestinations[destinationId]) {
            revert NotAllowedDestination(destinationId);
        }
        _;
    }

    modifier onlyAllowedSourceSender(bytes32 sender) {
        if (!allowedSenders[sender]) {
            revert NotAllowedSourceSender(sender);
        }
        _;
    }

    function xChainMint(uint32 destinationId, address destination) onlyAllowedDestination(destinationId) public payable returns (bytes32) {
        // TODO move data encoding to the FE and pass data via function parameter
        bytes memory data = abi.encodeWithSelector(MockERC721(rariMarketplace).mint.selector, msg.sender);

        // TODO add metadata for the future espresso ISM validations.
        return mailbox.dispatch{value: msg.value}(destinationId, destination.addressToBytes32(), data);
    }


    function handle(uint32 source, bytes32 sender, bytes calldata body)
        external
        payable
        onlyMailbox
        onlyAllowedSource(source)
        onlyAllowedSourceSender(sender)
    {
        (bool success,) = rariMarketplace.call(body);

        if (!success) revert XChainMintFailed();
    }

    // TODO Temporary removed until we use our own ISMVerifier. If set not valid, it crash relayer service.
    // function interchainSecurityModule() external view returns (IInterchainSecurityModule) {
    //     return _ismEspressoTEEVerifier;
    // }

    receive() external payable {}

    // ADMIN FUNCTIONS

    function withdraw() external onlyAdmin {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();

        (bool success, ) = msg.sender.call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function addAllowedSender(bytes32 sender) public onlyAdmin {
        allowedSenders[sender] = true;
        emit AllowedSenderAdded(sender);
    }

    function removeAllowedSender(bytes32 sender) external onlyAdmin {
        allowedSenders[sender] = false;
        emit AllowedSenderRemoved(sender);
    }

    function addAllowedSource(uint32 source) public onlyAdmin {
        allowedSources[source] = true;
        emit AllowedSourceAdded(source);
    }

    function removeAllowedSource(uint32 source) external onlyAdmin {
        allowedSources[source] = false;
        emit AllowedSourceRemoved(source);
    }

    function addAllowedDestination(uint32 destination) public onlyAdmin {
        allowedDestinations[destination] = true;
        emit AllowedDestinationAdded(destination);
    }

    function removeAllowedDestination(uint32 destination) external onlyAdmin {
        allowedDestinations[destination] = false;
        emit AllowedDestinationRemoved(destination);
    }

}
