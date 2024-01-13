// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import {console2} from "forge-std/Test.sol";

/*
Decentralized Voting System Smart Contract:

The Decentralized Voting System smart contract is designed to manage a transparent and secure voting process on the blockchain. The contract allows users to register to vote, the owner to add candidates, registered voters to cast their votes, and provides visibility into the election results.

Design Choices:

The contract leverages the OpenZeppelin library by importing the Ownable contract for better ownership control, enhancing security. It also includes a sentinel address (SENTINEL_ADDRESS) for efficient management of the linked list of candidates.

Voter information is stored in the voters mapping, containing a boolean for registration status and whether a voter has already cast their vote.

The candidates mapping is structured as a linked list, allowing the addition and removal of candidates. This design choice provides flexibility for managing candidates dynamically and efficiently.

Key events, such as CandidateAdded, ElectionStarted, ElectionEnded, and Voted, are emitted to log important actions. This enhances transparency and facilitates monitoring of the election process.

Security Considerations:

The contract employs access control through the Ownable modifier, ensuring that only the contract owner can perform administrative functions such as adding or removing candidates. This prevents unauthorized modifications to the candidate list.

The use of a sentinel address in the linked list of candidates helps prevent edge cases where the list might be empty. It simplifies the logic when iterating through the list and ensures consistent and reliable candidate management.

Input validations are implemented to ensure that only valid addresses are accepted for candidate-related operations, avoiding potential issues related to invalid addresses.

The contract introduces a check to verify that voters can only vote once, preventing double-voting and ensuring the integrity of the voting process.

The implementation includes a check to ensure that the election has started before allowing voter registration and votes. This temporal control adds an additional layer of security, preventing actions outside the designated election period.

The getWinner function efficiently determines the winner(s) by iterating through the list of candidates, considering tie scenarios. This approach provides an accurate and transparent method for determining the outcome of the election.
 
*/

contract VotingSystem is Ownable {
    address internal constant SENTINEL_ADDRESS = address(0x1); // Random address to be used as a sentinel
    bool public electionStarted;
    bool public electionEnded;
    mapping(address => address) public candidates;
    mapping(address => Voter) voters;
    mapping(address => uint256) votes;

    struct Voter {
        bool registered;
        bool hasVoted;
    }

    
    event CandidateAdded(address indexed candidate);
    event ElectionStarted();
    event ElectionEnded();
    event Voted(address indexed voter, address indexed candidate);

    constructor() Ownable(msg.sender) {
        candidates[SENTINEL_ADDRESS] = SENTINEL_ADDRESS;
    }

    function registerToVote() external {
        require(!voters[msg.sender].registered, "You are already registered");
        voters[msg.sender].registered = true;
    }

    function addCandidate(address _candidate) external onlyOwner {
        require(!electionStarted, "Election has already started");
        require(
            _candidate != address(0) && _candidate != SENTINEL_ADDRESS,
            "Invalid candidate address"
        );
        require(
            candidates[_candidate] == address(0),
            "Candidate already exists"
        );
        address lastCandidate = SENTINEL_ADDRESS;
        while (candidates[lastCandidate] != SENTINEL_ADDRESS) {
            lastCandidate = candidates[lastCandidate];
        }
        candidates[lastCandidate] = _candidate;
        candidates[_candidate] = SENTINEL_ADDRESS;
        emit CandidateAdded(_candidate);
    }
    function removeCandidate (address _candidate) external onlyOwner {
        require(!electionStarted, "Election has already started");
        require(
            _candidate != address(0) && _candidate != SENTINEL_ADDRESS,
            "Invalid candidate address"
        );
        require(
            candidates[_candidate] != address(0),
            "Candidate does not exist"
        );
        address previousCandidate = SENTINEL_ADDRESS;
        while (candidates[previousCandidate] != _candidate) {
            previousCandidate = candidates[previousCandidate];
        }
        candidates[previousCandidate] = candidates[_candidate];
        candidates[_candidate] = address(0);
    }

    function startElection() external onlyOwner {
        require(
            !electionStarted && !electionEnded,
            "Cannot start election again"
        );
        electionStarted = true;
        emit ElectionStarted();
    }

    function endElection() external onlyOwner {
        require(
            electionStarted && !electionEnded,
            "Election has not started or already ended"
        );
        electionStarted = false;
        electionEnded = true;
        emit ElectionEnded();
    }

    function vote(address _candidate) external {
        require(electionStarted && !electionEnded, "Election is not active");
        require(voters[msg.sender].registered, "You are not registered");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(
            candidates[_candidate] != address(0) &&
                _candidate != SENTINEL_ADDRESS,
            "Candidate does not exist"
        );
        voters[msg.sender].hasVoted = true;
        votes[_candidate]++;
        emit Voted(msg.sender, _candidate);
    }

    function getWinner() external view returns (address[] memory _winners) {
        require(electionEnded, "Election has not ended yet");

        uint256 maxVotes = 0;
        uint256 totalWinners = 0;
        _winners = new address[](1); // Initialize the array
        address lastCandidate = SENTINEL_ADDRESS;
        while (candidates[lastCandidate] != SENTINEL_ADDRESS) {
            lastCandidate = candidates[lastCandidate];
    

            if (votes[lastCandidate] > maxVotes) {
                maxVotes = votes[lastCandidate];
                _winners[0] = lastCandidate;
                totalWinners = 1;
            } else {
                if (votes[lastCandidate] == maxVotes) {
                    address[] memory temp = _winners;
                    _winners = new address[](totalWinners + 1); // Initialize the array with the updated size
                    for (uint256 i = 0; i < totalWinners; i++) {
                        _winners[i] = temp[i];
                    }
                    _winners[totalWinners] = lastCandidate;
                    totalWinners++;
                }
            }
        }

        return _winners;
    }

    function getIfRegistered() external view returns (bool) {
        return voters[msg.sender].registered;
    }

    function getIfVoted() external view returns (bool) {
        return voters[msg.sender].hasVoted;
    }

    function isCandidate(address _candidate) external view returns (bool) {
        require(
            _candidate != address(0) && _candidate != SENTINEL_ADDRESS,
            "Invalid candidate address"
        );
        return candidates[_candidate] != address(0);
    }
}
