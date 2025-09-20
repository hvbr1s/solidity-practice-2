// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Crowdfunding {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline;
    uint256 public totalContributed;

    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event CancelContribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed beneficiary, uint256 amount);

    error CannotAcceptZeroAmount();
    error ContributionFailed();
    error CampaignHasEnded();
    error CampaignIsStillOngoing();
    error ContributionExceedsFundingGoal();


    constructor(address token_, address beneficiary_, uint256 fundingGoal_, uint256 deadline_) {
        require(beneficiary_ != address(0), "Beneficiary address cannot be 0");
        require(fundingGoal_ != 0, "Funding goal must be greater than 0");
        require(token_ != address(0), "Token address cannot be 0");
        require(block.timestamp < deadline_, "Deadline must be in the future");
        token = IERC20(token_);
        beneficiary = beneficiary_;
        fundingGoal = fundingGoal_;
        deadline = deadline_;
    }

    /*
     * @notice a contribution can be made if the deadline is not reached.
     * @param amount the amount of tokens to contribute.
     */
    function contribute(uint256 amount) external {
        if (amount == 0){
            revert CannotAcceptZeroAmount();
        }
        require(block.timestamp < deadline, "Contribution period over");
        if ((totalContributed + amount) > fundingGoal){
            revert ContributionExceedsFundingGoal();
        }        
        else {
            bool k = token.transferFrom(msg.sender, address(this), amount);
            if (k){
                totalContributed += amount;
                contributions[msg.sender] += amount;
                emit Contribution(msg.sender, amount);
            } else{
                revert ContributionFailed();
            }
        }
    }

    /*
     * @notice a contribution can be cancelled if the goal is not reached. Returns the tokens to the contributor.
     */ 
    function cancelContribution() external {
        require(totalContributed < fundingGoal, "Cannot cancel after goal reached");
        uint amountToRefund = contributions[msg.sender];
        require(amountToRefund > 0, "You have not contributed to this campaign");
        contributions[msg.sender] = 0;
        totalContributed -= amountToRefund;
        IERC20(token).transfer(msg.sender, amountToRefund);
        emit CancelContribution(msg.sender, amountToRefund);
    }

    /*
     * @notice the beneficiary can withdraw the funds if the goal is reached.
     */
    function withdraw() external {  
        require(msg.sender == beneficiary, "Only beneficiary can withdraw");
        require(block.timestamp > deadline, "Funding period not over");
        require(totalContributed >= fundingGoal, "Funding goal not reached");
        uint amountToWithdraw = token.balanceOf(address(this));
        bool ok = token.transfer(beneficiary, amountToWithdraw);
        if (ok){
            emit Withdrawal(beneficiary, amountToWithdraw);
        } else {
            revert();
        }
    }
}
