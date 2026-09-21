// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MilestoneCrowdfunding {
    address public immutable creator;
    uint256 public immutable goal;
    uint256 public immutable deadline;

    uint256 public totalRaised;
    uint256 public currentMilestone;

    bool public goalReached;
    bool public cancelled;

    uint256[] public milestoneTargets;
    mapping(address => uint256) public contributions;

    error NotCreator();
    error CampaignEnded();
    error CampaignNotEnded();
    error InvalidGoal();
    error InvalidDeadline();
    error InvalidMilestones();
    error InvalidAmount();
    error GoalNotReached();
    error MilestoneNotReady();
    error AlreadyCancelled();
    error NothingToRefund();
    error TransferFailed();
    error Reentrancy();
    error GoalReached();

    event ContributionReceived(
        address indexed contributor,
        uint256 amount,
        uint256 totalRaised
    );

    event MilestoneReleased(uint256 indexed milestone, uint256 amount);

    event Refunded(address indexed contributor, uint256 amount);

    event CampaignCancelled();

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private reentrancyStatus = NOT_ENTERED;

    modifier nonReentrant() {
        if (reentrancyStatus == ENTERED) revert Reentrancy();
        reentrancyStatus = ENTERED;
        _;
        reentrancyStatus = NOT_ENTERED;
    }

    modifier onlyCreator() {
        if (msg.sender != creator) revert NotCreator();
        _;
    }

    constructor(
        uint256 _goal,
        uint256 _deadline,
        uint256[] memory _milestoneTargets
    ) {
        if (_goal == 0) revert InvalidGoal();
        if (_deadline <= block.timestamp) revert InvalidDeadline();
        if (_milestoneTargets.length == 0) revert InvalidMilestones();

        uint256 totalTargets;

        for (uint256 i = 0; i < _milestoneTargets.length; i++) {
            if (_milestoneTargets[i] == 0) revert InvalidMilestones();
            totalTargets += _milestoneTargets[i];
        }

        if (totalTargets != _goal) revert InvalidMilestones();

        creator = msg.sender;
        goal = _goal;
        deadline = _deadline;
        milestoneTargets = _milestoneTargets;
    }

    function contribute() external payable {
        if (block.timestamp >= deadline) revert CampaignEnded();
        if (msg.value == 0) revert InvalidAmount();

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        if (totalRaised >= goal) {
            goalReached = true;
        }

        emit ContributionReceived(msg.sender, msg.value, totalRaised);
    }

    function releaseMilestone() external onlyCreator nonReentrant {
        if (!goalReached) revert GoalNotReached();

        if (currentMilestone >= milestoneTargets.length) {
            revert MilestoneNotReady();
        }

        uint256 amount = milestoneTargets[currentMilestone];

        currentMilestone++;

        (bool success, ) = payable(creator).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit MilestoneReleased(currentMilestone - 1, amount);
    }

    function cancelCampaign() external onlyCreator {
        if (cancelled) revert AlreadyCancelled();
        if (block.timestamp >= deadline) revert CampaignEnded();

        cancelled = true;

        emit CampaignCancelled();
    }

    function refund() external nonReentrant {
        if (!cancelled && block.timestamp < deadline) {
            revert CampaignNotEnded();
        }

        if (goalReached && !cancelled) {
            revert GoalReached();
        }

        uint256 amount = contributions[msg.sender];

        if (amount == 0) revert NothingToRefund();

        contributions[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Refunded(msg.sender, amount);
    }

    function milestoneCount() external view returns (uint256) {
        return milestoneTargets.length;
    }

    function getMilestoneTarget(uint256 index) external view returns (uint256) {
        return milestoneTargets[index];
    }
}
