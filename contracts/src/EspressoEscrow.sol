// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IMailbox} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IMailbox.sol";
import {IMessageRecipient} from "@hyperlane-core-7.1.8/solidity/contracts/interfaces/IMessageRecipient.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./mocks/MockERC721.sol";

contract EspressoEscrow is AccessControl {
    bytes32 public constant MAILBOX_CALLER = keccak256("MAILBOX_CALLER");

    /**
     * @dev Default destination is the instance of EspressoEscrow on destination chain with the same address.
     */
    bytes32 public immutable defaultDestionation;
    IMailbox public immutable mailbox;
    uint32 public immutable destinationChainId;
    address public immutable rariMarketplace;

    mapping(bytes32 sender => bool allowed) public allowedSenders;

    error NotAllowedSourceSender(bytes32 sender);

    constructor(address mailboxAddress_, uint32 destinationChainId_, address rariMarketplace_) {
        mailbox = IMailbox(mailboxAddress_);
        _grantRole(MAILBOX_CALLER, mailboxAddress_);
        rariMarketplace = rariMarketplace_;
        defaultDestionation = _addressToBytes32(address(this));
        destinationChainId = destinationChainId_;
    }

    modifier onlyMailbox() {
        _checkRole(MAILBOX_CALLER);
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
        onlyMailbox
        onlyAllowedSourceSender(sender)
    {
        // TODO check origin chain
        (bool success,) = rariMarketplace.call(body);

        require(success, "XChainMint failed");
    }
}
