// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// A Wrapped Token is a token that is wrapped around another token.
// You wrap a token by calling wrap() and it will mint you the wrapped token.
// You redeem the wrapped token by calling unwrap() and it will burn the wrapped token
// and transfer the underlying token to you.

// Override the name and symbol to be "Wrapped <name>" and "w<symbol>" of
// the underlying token that is being wrapped by this contract.
// You need to handle cases where the underlying token has no name or symbol or the function reverts
// In that case, you should return a default name and symbol of "Wrapped" and "w"
// If the decimals function does not exist, you should return 0 for decimals
// Example: Name = "RareSkills" -> Name = "Wrapped RareSkills"
// Example: Symbol = "RSK" -> Symbol = "wRSK"
// Example: Decimals = 18 -> Decimals = 18

contract TokenWrapper is ERC20 {

    IERC20Metadata internal immutable token;
    using SafeERC20 for IERC20Metadata;

    uint8 internal immutable decimalsInternal;
    address public underlyingToken;

    event Wrap(address indexed from, uint256 amount);
    event Unwrap(address indexed to, uint256 amount);

    constructor(address _token) ERC20(
      _getName(_token),
      _getSymbol(_token)
    ) {
       underlyingToken = _token;
       token = IERC20Metadata(_token);
       decimalsInternal = _getDecimals(_token);
    }

    function _getName(address _token) private view returns (string memory) {
        try IERC20Metadata(_token).name() returns (string memory tokenName) {
            return string.concat("Wrapped ", tokenName);
        } catch {
            return "Wrapped";
        }
    }

    function _getSymbol(address _token) private view returns (string memory) {
        try IERC20Metadata(_token).symbol() returns (string memory tokenSymbol) {
            return string.concat("w", tokenSymbol);
        } catch {
            return "w";
        }
    }

    function _getDecimals(address _token) private view returns (uint8) {
        try IERC20Metadata(_token).decimals() returns (uint8 tokenDecimals) {
            return tokenDecimals;
        } catch {
            return 0;
        }
    }

    function decimals() public view override returns (uint8) {
      return decimalsInternal;
    }


    /**
      * @notice Wraps the amount of tokens from the caller's account to the contract
      * @notice The tokens of the underlying are transferred from the caller's account to the contract
      * @param amount The amount of tokens to wrap
      */ 
    function wrap(uint256 amount) external {
      require(amount > 0, "Amount to wrap must not be zero!");
      require(IERC20(underlyingToken).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance!");

      IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount);

      _mint(msg.sender, amount);

      emit Wrap(msg.sender, amount);

    }

    /** 
      * @notice Unwraps the amount of tokens from the caller's account. Transfers the tokens of the underlying to the caller's account.
      * @notice the wrapped tokens are burned from the caller's account.
      * @param amount The amount of tokens to unwrap
      */ 
    function unwrap(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        IERC20(underlyingToken).transfer(msg.sender, amount);

        emit Unwrap(msg.sender, amount);
    }
}
