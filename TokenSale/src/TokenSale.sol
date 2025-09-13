// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// the token should have a maximum supply of 100,000,000 tokens
// the token contract should have 10 decimals
// the price of one token should be 0.001 ether
// tokens should not exist until someone buys them using `buyTokens`
// users should also be able to buy tokens by sending ether to the contract
// then the contract calculates the amount of tokens to mint
contract TokenSale is ERC20("TokenSale", "TS") {
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 10;
    uint256 public constant PRICE_PER_UNIT = 0.001 ether / 10**10;
    uint256 public currentSupply;

    event TokenPurchase(address indexed source, uint256 amount);

    error MaxSupplyReached();

    receive() external payable {
        buyTokens();
    }

    fallback() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        uint256 amount = msg.value / PRICE_PER_UNIT;
        require((currentSupply + amount) < MAX_SUPPLY, MaxSupplyReached());
        _mint(msg.sender, amount);
        emit TokenPurchase(msg.sender, amount);
        
    }

    function decimals() public pure override returns (uint8) {
        return 10;
    }
}
