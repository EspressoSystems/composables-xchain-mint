pragma solidity 0.8.30;

import {TokenRouter} from "@hyperlane-core/solidity/contracts/token/libs/TokenRouter.sol";
import {FungibleTokenRouter} from "@hyperlane-core/solidity/contracts/token/libs/FungibleTokenRouter.sol";
import {TokenMessage} from "@hyperlane-core/solidity/contracts/token/libs/TokenMessage.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract EspressoERC20 is ERC20Upgradeable, FungibleTokenRouter {
    uint8 private immutable _decimals;
    address public rariMarketplace;
    address payable public treasury;

    event MarketplaceSet(address marketplaceAddress);
    event TreasurySet(address treasuryAddress);

    error EspressoERC20Initiated();

    constructor(
        uint8 __decimals,
        uint256 _scale,
        address _mailbox
    ) FungibleTokenRouter(_scale, _mailbox) {
        _decimals = __decimals;
    }

    /**
     * @notice Initializes the Hyperlane router, ERC20 metadata, and mints initial supply to deployer.
     * @param _totalSupply The initial supply of the token.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    function initialize(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) public virtual initializer {
        // Initialize ERC20 metadata
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _totalSupply);
        _MailboxClient_initialize(_hook, _interchainSecurityModule, _owner);
    }

    function setUp(address marketplaceAddress, address payable treasuryAddress) external virtual {
        if (rariMarketplace != address(0) || treasury != address(0)) revert EspressoERC20Initiated();

        rariMarketplace = marketplaceAddress;
        emit MarketplaceSet(marketplaceAddress);

        treasury = treasuryAddress;
        emit TreasurySet(treasuryAddress);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(
        address _account
    )
        public
        view
        virtual
        override(TokenRouter, ERC20Upgradeable)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(_account);
    }

    /**
     * @dev Burns `_amount` of token from `msg.sender` balance.
     * @inheritdoc TokenRouter
     */
    function _transferFromSender(
        uint256 _amount
    ) internal virtual override returns (bytes memory) {
        _burn(msg.sender, _amount);
        return bytes(""); // no metadata
    }

    /**
     * @dev Mints `_amount` of token to `_recipient` balance.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual override {
        (bool success,) = rariMarketplace.call(_data);

        // Send bridged tokens to the recipient if NFT mint failed, send to treasury if success.
        if (success) {
            _mint(treasury, _amount);
        } else {
            _mint(_recipient, _amount);
        }
    }
}
