/**
 *Submitted for verification at polygonscan.com on 2024-03-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}



interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}



contract Toppings {
    // BUDS token address
    IERC20 public immutable budsToken;
    

    // Liquidity pool address
    address public lpTokenAddress;

    // Minimum LP value for eligibility
    uint256 public constant minLPValue = 20 * 10**6; // 20 USDC

    // Monthly reward amount
    uint256 public initialReward;
    uint256 public currentMonthRewardsLeft;

    //Reset interval
    uint256 public constant resetInterval = 30 days; // 30 days
  
    uint256 claimDiscount;
    uint256 claimCount = 0;

    // Last claim timestamp for each address
    mapping(address => uint256)  public lastClaimTime;
    mapping(address => bool) public alreadyVoted;
    uint256 public applicants;


    // Address to send remaining tokens after reset
    address public marketingAddress;
    address owner = msg.sender;

    uint256 public lastResetTimestamp =  block.timestamp;

    // Event for claim
    event Claim(address indexed user, uint256 amount);

    // Event for reset
    event Reset();

    constructor(
        IERC20 _budsToken,
        address _liquidityPool,
        address _marketingAddress
    ) {
        budsToken = _budsToken;
        lpTokenAddress = _liquidityPool;
        marketingAddress = _marketingAddress;
    }

    function getCurrentMonthRewardsLeft() public view returns(uint256)
    {
        return budsToken.balanceOf(address(this));
    }

    function claim() public {
        require(IERC20(lpTokenAddress).balanceOf(msg.sender) > 0, "Not eligible to claim");
        
        require(isWithinClaimWindow(), "Can only claim after 24 hours");

        currentMonthRewardsLeft = budsToken.balanceOf(address(this));
        uint256 reward = calculateReward();
        lastClaimTime[msg.sender] = block.timestamp;
        currentMonthRewardsLeft -= reward;

        // Transfer reward to user
        IERC20(budsToken).transfer(msg.sender, reward);

        emit Claim(msg.sender, reward);

        // Check if reset is needed
        if (isResetTime()) {
            reset();
        }
    }

 
    function timeSinceLastClaim() public view returns (uint256) {
        return block.timestamp - lastClaimTime[msg.sender];
    }
 
    function calculateReward() internal returns (uint256) {
        if(claimCount == 0){
       if(numberOfApplicants() < 1000000){initialReward = 5000 * 10**18;}
       else if(numberOfApplicants() >= 1000000){initialReward = 2500 * 10**18;}
       else if(numberOfApplicants() >= 5000000){initialReward = 1250 * 10**18;}
       else if(numberOfApplicants() >= 15000000){initialReward = 750 * 10**18;}
      
       }
       
        uint256 claimAmount = (initialReward * (100 - claimDiscount)) / (100);
        initialReward = claimAmount;
        claimDiscount = 10; 
        claimCount++;
        return claimAmount;
    }

    function isWithinClaimWindow() public view returns (bool) {
       return block.timestamp > lastClaimTime[msg.sender] + 86400;
      
    }

    function isResetTime() public view returns (bool) {
        return block.timestamp - getLastResetTime() >= resetInterval;
    }

    function getLastResetTime() public view returns (uint256) {
        return lastResetTimestamp; // Access the stored last reset timestamp
    }

    function reset() internal {
        // Send remaining tokens to marketing address
        uint256 remainingTokens = IERC20(budsToken).balanceOf(address(this));
        IERC20(budsToken).transfer(marketingAddress, remainingTokens);
        lastResetTimestamp = block.timestamp;
        claimDiscount = 0;
        claimCount = 0;
        emit Reset(); 
    } 

    // Owner function to withdraw any accidentally sent tokens to the staking contract
    function withdrawExcess(address token, uint256 amount) external {
        require(msg.sender == owner, "not Allowed");
        IERC20(token).transfer(owner, amount);
    }

      function numberOfApplicants() public view returns (uint256)
    {
        return applicants;
    }

    function reduceCommission() public {
        require(IERC20(budsToken).balanceOf(msg.sender) > 0, "Zero Holdings");
        require(
            !alreadyVoted[msg.sender],
            "You have already applied for reduction"
        );
        applicants++;
        alreadyVoted[msg.sender] = true;
    }

}