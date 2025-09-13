// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Splitter {

    using SafeERC20 for IERC20;

    IERC20 internal immutable token;

    error InsufficientBalance();
    error InsufficientApproval();
    error ArrayLengthMismatch();

    function split(IERC20 token, address[] calldata recipients, uint256[] calldata amounts) external {
        uint n = recipients.length;
        if (n != amounts.length){
            revert ArrayLengthMismatch();
        }
        uint256 total;
        for (uint256 i; i < n; ) {
            total += amounts[i];
            unchecked {++i;}
        }
        require(token.balanceOf(msg.sender) >= total, InsufficientBalance());
        require(token.allowance(msg.sender, address(this)) >= total, InsufficientApproval());
        for (uint256 i; i < n; ){
            token.safeTransferFrom(msg.sender, recipients[i], amounts[i]);
            unchecked {++i;}
        }
    }
}
