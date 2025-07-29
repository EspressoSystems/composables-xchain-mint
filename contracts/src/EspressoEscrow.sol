// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IMailbox} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IMailbox.sol";
import {IMessageRecipient} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IMessageRecipient.sol";
import {
    IInterchainSecurityModule,
    ISpecifiesInterchainSecurityModule
} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IInterchainSecurityModule.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./mocks/MockERC721.sol";

contract EspressoEscrow is AccessControl, IMessageRecipient, ISpecifiesInterchainSecurityModule {
    bytes32 public constant MAILBOX = keccak256("MAILBOX");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    IMailbox public immutable mailbox;
    address public immutable rariMarketplace;
    IInterchainSecurityModule private immutable _ismEspressoTEEVerifier;

    mapping(bytes32 sender => bool allowed) public allowedSenders;
    mapping(uint32 origin => bool allowed) public allowedOrigins;
    mapping(uint32 destination => bool allowed) public allowedDestinations;

    event AllowedSenderAdded(bytes32 sender);
    event AllowedSenderRemoved(bytes32 sender);
    event AllowedOriginAdded(uint32 origin);
    event AllowedOriginRemoved(uint32 origin);
    event AllowedDestinationAdded(uint32 destination);
    event AllowedDestinationRemoved(uint32 destination);

    error NotAllowedSourceSender(bytes32 sender);
    error NotAllowedOrigin(uint32 origin);
    error NotAllowedDestination(uint32 destinationId);
    error WithdrawFailed();
    error NothingToWithdraw();

    constructor(
        address mailboxAddress_,
        uint32 originChainId_,
        uint32 destinationChainId_,
        address ismEspressoTEEVerifier_,
        address rariMarketplace_
    ) {
        mailbox = IMailbox(mailboxAddress_);
        rariMarketplace = rariMarketplace_;
        _ismEspressoTEEVerifier = IInterchainSecurityModule(ismEspressoTEEVerifier_);

        _grantRole(ADMIN, msg.sender);
        _grantRole(MAILBOX, mailboxAddress_);
        addAllowedOrigin(originChainId_);
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

    modifier onlyAllowedOrigin(uint32 origin) {
        if (!allowedOrigins[origin]) {
            revert NotAllowedOrigin(origin);
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
        return mailbox.dispatch{value: msg.value}(destinationId, _addressToBytes32(destination), data);
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }


    function handle(uint32 origin, bytes32 sender, bytes calldata body)
        external
        payable
        onlyMailbox
        onlyAllowedOrigin(origin)
        onlyAllowedSourceSender(sender)
    {
        (bool success,) = rariMarketplace.call(body);

        require(success, "XChainMint failed");
    }

    function interchainSecurityModule() external view returns (IInterchainSecurityModule) {
        return _ismEspressoTEEVerifier;
    }

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

    function addAllowedOrigin(uint32 origin) public onlyAdmin {
        allowedOrigins[origin] = true;
        emit AllowedOriginAdded(origin);
    }

    function removeAllowedOrigin(uint32 origin) external onlyAdmin {
        allowedOrigins[origin] = false;
        emit AllowedOriginRemoved(origin);
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
