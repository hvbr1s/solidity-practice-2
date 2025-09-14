// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {console} from "forge-std/console.sol";

// specification
// - the contract is used to pay contractors weekly
// - a contractor can withdraw a fixed salary every week
// - if they do not withdraw for more than a week, they also withdraw undrawn salary
// - Example: less than 1 week withdraw: 0 salary
// -          more than 1 week withdraw, but less than 2 weeks: 1 week salary
// -          more than 2 weeks withdraw, but less than 3 weeks: 2 weeks salary
// -          etc.
// - if a contractor is deleted, they cannot withdraw anymore
// - no partial payments, if the contract doesn't have enough balance, the function will revert
// - with InsufficientBalance()
contract WeeklySalary is Ownable2Step {

    using SafeERC20 for ERC20;

    constructor(address tokenAddress) Ownable(msg.sender) {
        token = ERC20(tokenAddress);
    }

    struct Contractor {
        uint256 weeklySalary;
        uint256 lastWithdrawal;
    }

    mapping(address => Contractor) public contractors;

    ERC20 public immutable token;

    event ContractorCreated(address indexed contractor, uint256 weeklySalary);
    event ContractorDeleted(address indexed contractor);
    event Withdrawal(address indexed contractor, uint256 amount);

    error ContractorAlreadyExists();
    error InvalidContractorAddress();
    error InvalidWeeklySalary();
    error InsufficientBalance();

    function createContractor(address _contractor, uint256 _weeklySalary) external onlyOwner {
        if (_contractor == address(0)) {
            revert InvalidContractorAddress();
        }
        require(_weeklySalary != 0, InvalidWeeklySalary());
        if (contractors[_contractor].weeklySalary != 0) {
            revert ContractorAlreadyExists();
        }
        contractors[_contractor].weeklySalary = _weeklySalary;
        contractors[_contractor].lastWithdrawal = block.timestamp;
        emit ContractorCreated(_contractor, _weeklySalary);
    }

    function deleteContractor(address _contractor) external onlyOwner {
        if (_contractor == address(0)){
            revert InvalidContractorAddress();
        }
        if (contractors[_contractor].weeklySalary == 0){
            revert InvalidContractorAddress();
        }
        delete contractors[_contractor];
        emit ContractorDeleted(_contractor);
    }

    /*
     * @dev if the balance of the contract is not sufficient, the function will revert
     */
    function withdraw() external {
        if (contractors[msg.sender].weeklySalary == 0){
            revert InvalidContractorAddress();
        }
        uint timePassed = block.timestamp - contractors[msg.sender].lastWithdrawal;
        uint weeklySalariesOwed =  timePassed / 1 weeks;
        uint amountToTransfer = weeklySalariesOwed * contractors[msg.sender].weeklySalary;
        if (amountToTransfer > token.balanceOf(address(this))) {
            revert InsufficientBalance();
        }
        contractors[msg.sender].lastWithdrawal = block.timestamp;
        token.transfer(msg.sender, amountToTransfer);
        emit Withdrawal(msg.sender, amountToTransfer);
    }
}
