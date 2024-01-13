// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/TokenSwap.sol";
import {VotingSystem} from "../src/VotingSystem.sol";


contract VotingSystemScript is Script {
    VotingSystem public votingSystem;
    function setUp() public {}
    
    function run() public {
        uint256 deployerPrvKey = vm.envUint("PK1");
        vm.startBroadcast(deployerPrvKey);
        
        votingSystem = new VotingSystem();
        addCandidates();
        votingSystem.startElection();

        vm.stopBroadcast();

        registerAndVote(vm.envUint("PK2"),address(2));
        registerAndVote(vm.envUint("PK3"),address(3));
        registerAndVote(vm.envUint("PK4"),address(2));
        registerAndVote(vm.envUint("PK5"),address(3));
        registerAndVote(vm.envUint("PK6"),address(2));
        registerAndVote(vm.envUint("PK7"),address(4));

        vm.startBroadcast(deployerPrvKey);
        votingSystem.endElection();
        vm.stopBroadcast();


    }
    function addCandidates() public {
        votingSystem.addCandidate(address(2));
        votingSystem.addCandidate(address(3));
        votingSystem.addCandidate(address(4));
    }
    function registerAndVote(uint256 _voterPrvKey,address _candidate) public {
        vm.startBroadcast(_voterPrvKey);
        votingSystem.registerToVote();
        votingSystem.vote(_candidate);
        vm.stopBroadcast();
    }
    
}
