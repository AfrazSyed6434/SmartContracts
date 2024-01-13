// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {VotingSystem} from "../src/VotingSystem.sol";

contract TokenSaleTest is Test {
    VotingSystem public votingSystem;

    function setUp() public {
        votingSystem = new VotingSystem();
    }

    function test_addCandidate() public {
        votingSystem.addCandidate(address(2));
        assertEq(votingSystem.isCandidate(address(2)), true);
    }

    function test_addCandidateWithSentinelAddress() public {
        vm.expectRevert("Invalid candidate address");
        votingSystem.addCandidate(address(0x1));
    }

    function test_addCandidateAfterElectionStart() public {
        votingSystem.startElection();
        vm.expectRevert("Cannot perform action at current state");
        votingSystem.addCandidate(address(2));
    }

    function test_addCandidateMultipleTimes() public {
        votingSystem.addCandidate(address(2));
        vm.expectRevert("Candidate already exists");
        votingSystem.addCandidate(address(2));
    }

    function test_addMultipleCandidates() public {
        setupCandidates();
        assertEq(votingSystem.isCandidate(address(2)), true);
        assertEq(votingSystem.isCandidate(address(3)), true);
        assertEq(votingSystem.isCandidate(address(4)), true);
    }

    function test_registerToVote() public {
        vm.startBroadcast(address(2));
        votingSystem.registerToVote();
        assertEq(votingSystem.getIfRegistered(), true);
        vm.stopBroadcast();
    }

    function test_registerMultipleTimes() public {
        vm.startBroadcast(address(2));
        votingSystem.registerToVote();
        vm.expectRevert("You are already registered");
        votingSystem.registerToVote();
        vm.stopBroadcast();
    }

    function test_registerMultipleVoters() public {
        vm.prank(address(2));
        votingSystem.registerToVote();
        vm.prank(address(3));
        votingSystem.registerToVote();
        vm.prank(address(4));
        votingSystem.registerToVote();

        vm.prank(address(2));
        assertEq(votingSystem.getIfRegistered(), true);
        vm.prank(address(3));
        assertEq(votingSystem.getIfRegistered(), true);
        vm.prank(address(4));
        assertEq(votingSystem.getIfRegistered(), true);
    }

    function test_vote() public {
        votingSystem.addCandidate(address(2));
        votingSystem.startElection();
        vm.startBroadcast(address(3));
        votingSystem.registerToVote();
        votingSystem.vote(address(2));
        assertEq(votingSystem.getIfVoted(), true);
        vm.stopBroadcast();
    }

    function test_voteUnregisteredCandidate() public {
        votingSystem.addCandidate(address(2));
        votingSystem.startElection();
        vm.startBroadcast(address(3));
        vm.expectRevert("You are not a registered voter");
        votingSystem.vote(address(2));
        vm.stopBroadcast();
    }

    function test_correctWinner() public {
        setupCandidates();
        votingSystem.startElection();

        registerAndVote(address(5), address(2));
        registerAndVote(address(6), address(3));
        registerAndVote(address(7), address(4));
        registerAndVote(address(8), address(2));
        registerAndVote(address(9), address(3));
        registerAndVote(address(10), address(2));

        votingSystem.endElection();

        address[] memory expectedWinner = new address[](1);
        expectedWinner[0] = address(2);
        

        // Compare the actual winners with the expected winners
        assertEq(votingSystem.getWinner(), expectedWinner);
    }
    function test_multipleWinner()public{
        setupCandidates();
        votingSystem.startElection();

        registerAndVote(address(5), address(2));
        registerAndVote(address(6), address(3));
        registerAndVote(address(7), address(2));
        registerAndVote(address(8), address(2));
        registerAndVote(address(9), address(3));
        registerAndVote(address(10), address(3));

        votingSystem.endElection();
        
        address[] memory expectedWinner = new address[](2);
        expectedWinner[0] = address(2);
        expectedWinner[1] = address(3);
        

        // Compare the actual winners with the expected winners
        assertArraysEq(votingSystem.getWinner(), expectedWinner);
    }
    
    // Helper function to compare two address arrays
    function assertArraysEq(address[] memory a, address[] memory b) internal {
        assertEq(a.length, b.length, "Array lengths do not match");

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i], "Array elements do not match");
        }
    }

    function setupCandidates() public {
        votingSystem.addCandidate(address(2));
        votingSystem.addCandidate(address(3));
        votingSystem.addCandidate(address(4));
    }

    function registerAndVote(address _voter, address _candidate) public {
        vm.startBroadcast(_voter);
        votingSystem.registerToVote();
        votingSystem.vote(_candidate);
        vm.stopBroadcast();
    }
}
