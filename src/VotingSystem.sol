// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
Design Choices:

The VotingSystem contract is designed as a decentralized voting system on the Ethereum blockchain. It employs the Ethereum Virtual Machine (EVM) and is implemented in Solidity. The contract follows a modular and upgradeable structure, utilizing OpenZeppelin's Ownable and ReentrancyGuard contracts to manage ownership and prevent reentrancy attacks, respectively.

The contract incorporates an enum, VotingState, to represent the different stages of the voting process, including Registration, InProgress, and Ended. This design choice ensures a well-defined lifecycle for the election, enhancing transparency and security.

To store candidate information, a mapping (candidates) is utilized, where each candidate is linked to the next in a linked list. This approach enables efficient candidate addition and removal while maintaining data integrity. Additionally, a sentinel address is employed to mark the end of the linked list.

The Voter struct stores essential information about each voter, including registration status and whether they have cast their vote. This struct is utilized within a mapping (voters) to manage voter-specific data efficiently.

Events are used extensively to log crucial actions, including the addition and removal of candidates, the start and end of the election, voter registration, and casting of votes. This ensures transparency and provides an auditable trail of key activities on the blockchain.

Security Considerations:

The contract incorporates various security measures to mitigate potential risks. The onlyBeforeState, onlyDuringState, and onlyRegisteredVoter modifiers are employed to enforce state-dependent restrictions and validate the eligibility of voters for specific actions. These modifiers enhance the contract's security by preventing unauthorized operations during inappropriate states and ensuring that only registered voters can participate.

The use of OpenZeppelin's ReentrancyGuard helps protect against reentrancy attacks, a common vulnerability in smart contracts. By using this guard, the contract ensures that external calls are completed before processing further operations, preventing recursive calls that may exploit vulnerabilities.

The contract adheres to the principle of least privilege by restricting certain functions, such as candidate addition and removal, to the contract owner. This minimizes the attack surface and prevents unauthorized modifications to the candidate list during critical phases of the election.

Careful consideration is given to handling state transitions, ensuring that the contract state progresses in a secure and controlled manner. This prevents unexpected changes in the contract's behavior and mitigates the risk of manipulation during the election process.

*/

contract VotingSystem is Ownable, ReentrancyGuard {
    address internal constant SENTINEL_ADDRESS = address(0x1);

    enum VotingState { Registration, InProgress, Ended }
    VotingState public votingState;

    // mapping(address => bool) public registeredVoters;
    mapping(address => address) public candidates;
    mapping(address => Voter) public voters;
    mapping(address => uint256) public votes;

    struct Voter {
        bool registered;
        bool hasVoted;
    }

    event CandidateAdded(address indexed candidate);
    event CandidateRemoved(address indexed candidate);
    event ElectionStarted();
    event ElectionEnded();
    event Voted(address indexed voter, address indexed candidate);
    event VoterRegistered(address indexed voter);

    modifier onlyDuringState(VotingState _state) {
        require(votingState == _state, "Invalid voting state");
        _;
    }
    
    modifier onlyBeforeState(VotingState _state) {
        require(votingState < _state, "Cannot perform action at current state");
        _;
    }

    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].registered, "You are not a registered voter");
        _;
    }

    constructor() Ownable(msg.sender) {
        candidates[SENTINEL_ADDRESS] = SENTINEL_ADDRESS;
        votingState = VotingState.Registration;
    }

    function registerToVote() external onlyBeforeState(VotingState.Ended) {
        require(!voters[msg.sender].registered, "You are already registered");
        voters[msg.sender].registered = true;
        emit VoterRegistered(msg.sender);
    }

    function addCandidate(address _candidate) external onlyOwner onlyBeforeState(VotingState.InProgress) {
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

    function removeCandidate(address _candidate) external onlyOwner onlyBeforeState(VotingState.InProgress) {
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
        emit CandidateRemoved(_candidate);
    }

    function startElection() external onlyOwner onlyBeforeState(VotingState.InProgress) {
        votingState = VotingState.InProgress;
        emit ElectionStarted();
    }

    function endElection() external onlyOwner onlyDuringState(VotingState.InProgress) {
        votingState = VotingState.Ended;
        emit ElectionEnded();
    }

    function vote(address _candidate) external nonReentrant onlyDuringState(VotingState.InProgress) onlyRegisteredVoter {
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
        require(votingState == VotingState.Ended, "Election has not ended yet");

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
