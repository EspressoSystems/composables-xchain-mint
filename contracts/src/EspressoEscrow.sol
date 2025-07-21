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

    /**
     * @dev Default destination is the instance of EspressoEscrow on destination chain with the same address.
     */
    bytes32 public immutable defaultDestionation;
    IMailbox public immutable mailbox;
    uint32 public immutable destinationChainId;
    address public immutable rariMarketplace;
    IInterchainSecurityModule private immutable _ismEspressoTEEVerifier;

    mapping(bytes32 sender => bool allowed) public allowedSenders;
    mapping(uint32 origin => bool allowed) public allowedOrigins;

    event AllowedSenderAdded(bytes32 sender);
    event AllowedSenderRemoved(bytes32 sender);
    event AllowedOriginAdded(uint32 origin);
    event AllowedOriginRemoved(uint32 origin);

    error NotAllowedSourceSender(bytes32 sender);
    error NotAllowedOrigin(uint32 origin);

    constructor(
        address mailboxAddress_,
        uint32 originChainId_,
        uint32 destinationChainId_,
        address ismEspressoTEEVerifier_,
        address rariMarketplace_
    ) {
        mailbox = IMailbox(mailboxAddress_);
        rariMarketplace = rariMarketplace_;
        defaultDestionation = _addressToBytes32(address(this));
        destinationChainId = destinationChainId_;
        _ismEspressoTEEVerifier = IInterchainSecurityModule(ismEspressoTEEVerifier_);

        _grantRole(ADMIN, msg.sender);
        _grantRole(MAILBOX, mailboxAddress_);
        addAllowedSender(defaultDestionation);
        addAllowedOrigin(originChainId_);
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

    modifier onlyAllowedSourceSender(bytes32 sender) {
        if (!allowedSenders[sender]) {
            revert NotAllowedSourceSender(sender);
        }
        _;
    }

    function xChainMint() public returns (bytes32) {
        bytes memory data = abi.encodeWithSelector(MockERC721(rariMarketplace).mint.selector, msg.sender);

        // TODO add metadata for the future espresso ISM validations.
        return mailbox.dispatch(destinationChainId, defaultDestionation, data);
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

    // ADMIN FUNCTIONS

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
}
