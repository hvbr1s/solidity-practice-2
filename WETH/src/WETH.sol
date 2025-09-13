// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20("Wrapped Ether", "WETH") {

    event Deposit(address indexed dest, uint256 amount);
    event Withdrawal(address indexed source, uint256 amount);

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

  function deposit() public payable {
      _mint(msg.sender, msg.value);
      emit Deposit(msg.sender, msg.value);
  }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }
}
