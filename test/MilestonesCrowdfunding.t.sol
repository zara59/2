// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MilestoneCrowdfunding.sol";

contract MilestoneCrowdfundingTest is Test {
    MilestoneCrowdfunding campaign;

    address creator = address(1);
    address contributor = address(2);
    address stranger = address(3);

    uint256 goal = 10 ether;
    uint256 deadline;

    function setUp() public {
        deadline = block.timestamp + 7 days;

        uint256[] memory milestones = new uint256[](2);
        milestones[0] = 5 ether;
        milestones[1] = 5 ether;

        vm.startPrank(creator);

        campaign = new MilestoneCrowdfunding(goal, deadline, milestones);

        vm.stopPrank();

        vm.deal(contributor, 10 ether);
    }

    function test_contribute() public {
        vm.prank(contributor);
        campaign.contribute{value: 10 ether}();

        assertEq(campaign.totalRaised(), 10 ether);
        assertEq(campaign.contributions(contributor), 10 ether);
        assertTrue(campaign.goalReached());
    }

    function test_releaseMilestones() public {
        vm.prank(contributor);
        campaign.contribute{value: 10 ether}();

        uint256 creatorBefore = creator.balance;

        vm.prank(creator);
        campaign.releaseMilestone();

        assertEq(creator.balance, creatorBefore + 5 ether);
        assertEq(campaign.currentMilestone(), 1);

        vm.prank(creator);
        campaign.releaseMilestone();

        assertEq(campaign.currentMilestone(), 2);
    }

    function test_strangerCannotRelease() public {
        vm.prank(contributor);
        campaign.contribute{value: 10 ether}();

        vm.prank(stranger);

        vm.expectRevert(MilestoneCrowdfunding.NotCreator.selector);

        campaign.releaseMilestone();
    }

    function test_refundAfterDeadline() public {
        vm.prank(contributor);
        campaign.contribute{value: 1 ether}();

        vm.warp(deadline);

        uint256 balanceBefore = contributor.balance;

        vm.prank(contributor);
        campaign.refund();

        assertEq(contributor.balance, balanceBefore + 1 ether);
        assertEq(campaign.contributions(contributor), 0);
    }

    function test_cannotContributeAfterDeadline() public {
        vm.warp(deadline);

        vm.prank(contributor);

        vm.expectRevert(MilestoneCrowdfunding.CampaignEnded.selector);

        campaign.contribute{value: 1 ether}();
    }

    function test_cancelAllowsRefund() public {
        vm.prank(contributor);
        campaign.contribute{value: 1 ether}();

        vm.prank(creator);
        campaign.cancelCampaign();

        vm.prank(contributor);
        campaign.refund();

        assertEq(campaign.contributions(contributor), 0);
    }
}
