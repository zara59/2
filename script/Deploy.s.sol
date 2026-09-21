// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MilestoneCrowdfunding.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        uint256 goal = 100 ether;
        uint256 deadline = block.timestamp + 30 days;

        uint256[] memory milestones = new uint256[](3);
        milestones[0] = 40 ether;
        milestones[1] = 30 ether;
        milestones[2] = 30 ether;

        MilestoneCrowdfunding campaign = new MilestoneCrowdfunding(
            goal,
            deadline,
            milestones
        );

        console2.log("Campaign deployed at:", address(campaign));

        vm.stopBroadcast();
    }
}
