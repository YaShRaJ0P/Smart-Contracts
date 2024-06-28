// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Election Contract
/// @notice This contract allows for the creation and management of an election with candidates and voters.
/// @dev The contract uses OpenZeppelin's Counters library to manage candidate and voter IDs.
contract Election {
    using Counters for Counters.Counter;

    Counters.Counter private candidateId;
    Counters.Counter private voterId;

    address public organiser;

    /// @notice Structure to store information about a candidate
    /// @dev Each candidate has a unique ID, name, age, vote count, symbol, and address.
    struct Candidate { 
        uint16 candidateId;         // Unique ID of candidate
        string name;                // Name of candidate
        uint16 age;                 // Age of candidate in months
        uint32 votes;               // Vote count of candidate
        string symbol;              // Symbol of candidate
        address candidateAddress;   // Address of candidate
    } 

    /// @notice Structure to store information about a voter
    /// @dev Each voter has a unique ID, name, age, address, the candidate they voted for, and a flag indicating if they have voted.
    struct Voter { 
        uint32 voterId; // Unique ID for each voter
        string name;
        uint16 age; // Age in months 
        address voterAddress;
        address votedTo; // Address of the candidate the voter voted for
        bool hasVoted; // Whether the voter has voted or not
    }

    mapping(address => Candidate) public candidates;
    mapping(address => Voter) public voters;

    address[] private candidateAddressList;
    address[] private voterAddressList;

    /// @notice Event emitted when a new candidate is created
    /// @param candidateId The unique ID of the candidate
    /// @param name The name of the candidate
    /// @param age The age of the candidate in months
    /// @param symbol The symbol representing the candidate
    /// @param candidateAddress The address of the candidate
    event CandidateCreated(uint16 candidateId, string name, uint16 age, string symbol, address candidateAddress);
    
    /// @notice Event emitted when a new voter is created
    /// @param voterId The unique ID of the voter
    /// @param name The name of the voter
    /// @param age The age of the voter in months
    /// @param voterAddress The address of the voter
    event VoterCreated(uint32 voterId, string name, uint16 age, address voterAddress);
    
    /// @notice Event emitted when a voter casts a vote
    /// @param voter The address of the voter
    /// @param candidate The address of the candidate voted for
    event Voted(address voter, address candidate);
    
    /// @notice Event emitted when a voter changes their vote
    /// @param voter The address of the voter
    /// @param newCandidate The address of the new candidate voted for
    event VoteChanged(address voter, address newCandidate);

    /// @notice Constructor to set the organiser of the election
    constructor() { 
        organiser = msg.sender;
    }

    /// @notice Modifier to restrict access to the organiser
    modifier onlyOrganiser {
        require(msg.sender == organiser, "Only the organiser can perform this action.");
        _;
    }

    /// @notice Function to create a new candidate
    /// @dev Only the organiser can create a candidate. The candidate's address must be unique.
    /// @param _name The name of the candidate
    /// @param _age The age of the candidate in months
    /// @param _symbol The symbol representing the candidate
    /// @param _candidateAddress The address of the candidate
    function createCandidate(string memory _name, uint16 _age, string memory _symbol, address _candidateAddress) public onlyOrganiser {
        require(candidates[_candidateAddress].candidateId == 0, "Candidate already exists.");

        candidateId.increment();
        Candidate memory candidate = Candidate({
            candidateId: uint16(candidateId.current()),
            name: _name,
            age: _age,
            votes: 0,
            symbol: _symbol,
            candidateAddress: _candidateAddress
        });

        candidates[_candidateAddress] = candidate;
        candidateAddressList.push(_candidateAddress);

        emit CandidateCreated(uint16(candidateId.current()), _name, _age, _symbol, _candidateAddress);
    }

    /// @notice Function to get all candidates
    /// @return An array of all candidates
    function getAllCandidates() public view returns (Candidate[] memory) {
        uint numOfCandidates = candidateId.current();
        Candidate[] memory candidateArray = new Candidate[](numOfCandidates);

        for (uint i = 0; i < numOfCandidates; i++) {
            candidateArray[i] = candidates[candidateAddressList[i]];
        }
        return candidateArray;
    }

    /// @notice Function to create a new voter
    /// @dev Only the organiser can create a voter. The voter's address must be unique.
    /// @param _name The name of the voter
    /// @param _age The age of the voter in months
    /// @param _voterAddress The address of the voter
    function createVoter(string memory _name, uint16 _age, address _voterAddress) public onlyOrganiser {
        require(voters[_voterAddress].voterId == 0, "Voter already exists.");

        voterId.increment();
        Voter memory voter = Voter({
            voterId: uint32(voterId.current()),
            name: _name,
            age: _age,
            voterAddress: _voterAddress,
            votedTo: address(0),
            hasVoted: false
        });

        voters[_voterAddress] = voter;
        voterAddressList.push(_voterAddress);

        emit VoterCreated(uint32(voterId.current()), _name, _age, _voterAddress);
    }

    /// @notice Function for a voter to cast a vote
    /// @dev The voter must be registered and must not have voted before. The candidate must exist.
    /// @param _candidateAddress The address of the candidate to vote for
    function vote(address _candidateAddress) external {
        require(voters[msg.sender].voterId != 0, "You are not a registered voter.");
        require(candidates[_candidateAddress].candidateId != 0, "Candidate does not exist.");
        require(!voters[msg.sender].hasVoted, "You have already voted.");

        candidates[_candidateAddress].votes++;
        voters[msg.sender].votedTo = _candidateAddress; // Corrected here
        voters[msg.sender].hasVoted = true;

        emit Voted(msg.sender, _candidateAddress);
    }

    /// @notice Function for a voter to change their vote
    /// @dev The voter must be registered and must have voted before. The new candidate must exist.
    /// @param _newCandidateAddress The address of the new candidate to vote for
    function changeVote(address _newCandidateAddress) external {
        require(voters[msg.sender].voterId != 0, "You are not a registered voter.");
        require(candidates[_newCandidateAddress].candidateId != 0, "Candidate does not exist.");
        require(voters[msg.sender].hasVoted, "You have not voted yet.");

        candidates[voters[msg.sender].votedTo].votes--;
        candidates[_newCandidateAddress].votes++;
        voters[msg.sender].votedTo = _newCandidateAddress;

        emit VoteChanged(msg.sender, _newCandidateAddress);
    }
}
