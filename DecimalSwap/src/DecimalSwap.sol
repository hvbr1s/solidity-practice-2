// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// tokenA and tokenB are stablecoins, so they have the same value, but different
// decimals. This contract allows users to trade one token for another at equal rate
// after correcting for the decimals difference 
contract DecimalSwap {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable tokenA;
    IERC20Metadata public immutable tokenB;

    constructor(address tokenA_, address tokenB_) {
        tokenA = IERC20Metadata(tokenA_);
        tokenB = IERC20Metadata(tokenB_);
    }

    function swapAtoB(uint256 amountIn) external {
        require(tokenA.balanceOf(msg.sender) >= amountIn, "Not enough tokens for swap");
        require(tokenA.allowance(msg.sender, address(this)) >= amountIn, "Not enough balance");
        
        uint amountOut = (amountIn * 10**tokenB.decimals() / 10**tokenA.decimals());
        require(tokenB.balanceOf(address(this)) >= amountOut, "Not enough liquidity for token out");

        (bool tokenPullSuccess) = tokenA.transferFrom(msg.sender, address(this), amountIn);
        if (!tokenPullSuccess){
            revert();
        }
        (bool tokenPushSuccess) = tokenB.transfer(msg.sender, amountOut);
        if (!tokenPushSuccess){
            revert();
        }
        
    }

    function swapBtoA(uint256 amountIn) external {
        require(tokenB.balanceOf(msg.sender) >= amountIn, "Not enough tokens for swap");
        require(tokenB.allowance(msg.sender, address(this)) >= amountIn, "Not enough balance");
        
        uint amountOut = (amountIn * 10**tokenA.decimals() / 10**tokenB.decimals());
        require(tokenA.balanceOf(address(this)) >= amountOut, "Not enough liquidity for token out");

        (bool tokenPullSuccess) = tokenB.transferFrom(msg.sender, address(this), amountIn);
        if (!tokenPullSuccess){
            revert();
        }
        (bool tokenPushSuccess) = tokenA.transfer(msg.sender, amountOut);
        if (!tokenPushSuccess){
            revert();
        }
    }
}
