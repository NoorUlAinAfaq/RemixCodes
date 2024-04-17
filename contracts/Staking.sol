// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBEP20 {
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

contract StakingContract {
    address public owner;

    IBEP20 public token;
    bool public isPaused = false;
    uint256 public rewardBase = 1000; // 100% base reward
    //  uint256[] public stakeDurations = [30 days, 90 days, 180 days, 365 days];
    uint256[] public stakeDurations = [30, 90, 180, 365];
    uint256[] public rewardRates = [50, 66, 83, 125]; // 2%, 5%, 10%, 25% rewards for 1, 3, 6, and 12 months respectively

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        uint256 durationIndex; // Index to determine the reward tier
    }

    mapping(address => Stake) private stakers;

    event Staked(
        address indexed staker,
        uint256 amount,
        uint256 startTime,
        uint256 durationIndex
    );
    event Unstaked(
        address indexed staker,
        uint256 amount,
        uint256 endTime,
        uint256 reward
    );
    event instantUnstaked(
        address indexed staker,
        uint256 amount,
        uint256 endTime
    );
    event RewardClaimed(
        address indexed staker,
        uint256 amount,
        uint256 claimTime
    );
    event RewardRatesChanged(uint256[] newRates);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        token = IBEP20(_token);
    }

    function stake(uint256 _amount, uint256 _durationIndex) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            _durationIndex < stakeDurations.length,
            "Invalid duration index"
        );
        Stake storage staker = stakers[msg.sender];

        require(staker.amount == 0, "You have already staked VRL!!");

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );
        require(!isPaused, "Staking is paused!!");

        stakers[msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            durationIndex: _durationIndex
        });

        emit Staked(msg.sender, _amount, block.timestamp, _durationIndex);
    }

    function pauseStaking(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function instantUnstake() external {
        Stake storage staker = stakers[msg.sender];

        require(staker.amount > 0, "No staked amount to unstake");
        require(
            block.timestamp <=
                staker.startTime + stakeDurations[staker.durationIndex],
            "You already have a reward!!"
        );

        require(
            token.balanceOf(address(this)) > staker.amount,
            "Insufficient balance in staking contract"
        );
        require(
            token.transfer(msg.sender, staker.amount),
            "Token transfer failed"
        );

        emit instantUnstaked(msg.sender, staker.amount, block.timestamp);

        // Reset staker data
        delete stakers[msg.sender];
    }

    function unstake() external {
        Stake storage staker = stakers[msg.sender];

        require(staker.amount > 0, "No staked amount to unstake");
        require(
            block.timestamp >=
                staker.startTime + stakeDurations[staker.durationIndex],
            "Minimum stake period not met"
        );

        require(
            token.balanceOf(address(this)) > staker.amount,
            "Insufficient balance in staking contract"
        );

        uint256 stakingDuration = block.timestamp - staker.startTime;
        uint256 reward = (staker.amount *
            rewardRates[staker.durationIndex] *
            stakingDuration) / (30 days * rewardBase);

        require(
            token.transfer(msg.sender, staker.amount + reward),
            "Token transfer failed"
        );

        emit Unstaked(msg.sender, staker.amount, block.timestamp, reward);

        // Reset staker data
        delete stakers[msg.sender];
    }

    function claimReward() external {
        Stake storage staker = stakers[msg.sender];

        require(staker.amount > 0, "No staked amount to claim rewards");
        require(
            block.timestamp >=
                staker.lastClaimTime + stakeDurations[staker.durationIndex],
            "Minimum claim period not met"
        );

        require(
            token.balanceOf(address(this)) > staker.amount,
            "Insufficient balance in staking contract"
        );

        uint256 stakingDuration = block.timestamp - staker.lastClaimTime;
        uint256 reward = (staker.amount *
            rewardRates[staker.durationIndex] *
            stakingDuration) / (30 days * rewardBase);

        require(token.transfer(msg.sender, reward), "Token transfer failed");

        staker.lastClaimTime = block.timestamp;

        emit RewardClaimed(msg.sender, reward, block.timestamp);
    }

    function getPendingRewards(address _staker)
        external
        view
        returns (uint256)
    {
        Stake storage staker = stakers[_staker];

        if (staker.amount == 0) {
            return 0;
        }

        uint256 stakingDuration = block.timestamp - staker.lastClaimTime;
        uint256 pendingRewards = (staker.amount *
            rewardRates[staker.durationIndex] *
            stakingDuration) / (30 days * rewardBase);

        return pendingRewards;
    }

    function getStakedAmount(address _staker)
        external
        view
        returns (uint256 amount)
    {
        Stake storage staker = stakers[_staker];
        require(staker.amount > 0, "No staked amount for the address");
        return staker.amount;
    }

    function getLastStakedStartTime(address _staker)
        external
        view
        returns (uint256 time)
    {
        Stake storage staker = stakers[_staker];
        require(staker.amount > 0, "No staked amount for the address");
        return staker.startTime;
    }

    function getLastStakedClaimedTime(address _staker)
        external
        view
        returns (uint256 time)
    {
        Stake storage staker = stakers[_staker];
        require(staker.amount > 0, "No staked amount for the address");
        return staker.lastClaimTime;
    }

    function getRemainingTime(address _staker)
        external
        view
        returns (uint256 time)
    {
        Stake storage staker = stakers[_staker];
        require(staker.amount > 0, "No staked amount for the address");

        uint256 elapsedTime = 0;

        // Calculate the elapsed time since the start of the stake
        if (block.timestamp > staker.startTime) {
            elapsedTime = block.timestamp - staker.startTime;
        }

        // Calculate the remaining time until unstake is open
        uint256 lockedDuration = stakeDurations[staker.durationIndex];
        uint256 remainingTime = 0;
        if (elapsedTime < lockedDuration) {
            remainingTime = lockedDuration - elapsedTime;
        }

        // Calculate the exact date and time when the reward will be available to claim
        uint256 rewardAvailableTime = block.timestamp + remainingTime;

        return rewardAvailableTime;
    }

    function changeRewardRates(uint256[] memory _newRates) external onlyOwner {
        require(
            _newRates.length == stakeDurations.length,
            "Invalid rates length"
        );

        rewardRates = _newRates;

        emit RewardRatesChanged(_newRates);
    }

    function transferStuckBEP20(IBEP20 VRL) external onlyOwner {
        token.transfer(owner, VRL.balanceOf(address(this)));
    }

    function transferStuckBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
