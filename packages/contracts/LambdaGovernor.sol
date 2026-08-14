// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ILambdaMembershipSBT {
    function balanceOf(address owner) external view returns (uint256);
    function getPrimeIdHashForAddress(address owner) external view returns (bytes32);
}

/// @notice ΛGovernor: Λ-Trace-gated governance.
/// - Only Membership SBT holders can propose and vote.
/// - Every proposal must be backed by a Λ-Trace + EAS evaluation.
/// - Executes arbitrary calls to whitelisted target contracts.
contract LambdaGovernor is AccessControl {
    using SafeCast for uint256;
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed,
        Canceled
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalCore {
        address proposer;
        uint64 startBlock;
        uint64 endBlock;
        uint64 forVotes;
        uint64 againstVotes;
        uint64 abstainVotes;
        bool executed;
        bool canceled;
    }

    struct GovernanceMeta {
        bytes32 workHash;
        bytes32 ltraceHash;
        bytes32 evaluationAttUid; // EAS ProposalEvaluationV1 UID
    }

    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    // proposalId => core data
    mapping(uint256 => ProposalCore) public proposals;
    // proposalId => meta
    mapping(uint256 => GovernanceMeta) public proposalMeta;
    // proposalId => calls
    mapping(uint256 => Call[]) public proposalCalls;
    // proposalId => primeIdHash => has voted
    mapping(uint256 => mapping(bytes32 => bool)) public hasVoted;

    ILambdaMembershipSBT public membership;
    uint256 public votingDelay;    // blocks
    uint256 public votingPeriod;   // blocks
    uint256 public quorumVotes;    // minimum FOR votes required
    uint256 public executionDelay; // blocks to wait after success before execution
    bool public paused;            // emergency pause flag
    mapping(address => bool) public allowedTargets;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        GovernanceMeta meta
    );

    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        VoteType voteType,
        uint8 weight
    );

    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event AllowedTargetSet(address indexed target, bool allowed);
    event QuorumChanged(uint256 oldQuorum, uint256 newQuorum);
    event ExecutionDelayChanged(uint256 oldDelay, uint256 newDelay);
    event PausedStateChanged(bool paused);

    constructor(
        address membershipSbt,
        uint256 votingDelayBlocks,
        uint256 votingPeriodBlocks,
        uint256 quorumVotesRaw
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        membership = ILambdaMembershipSBT(membershipSbt);
        votingDelay = votingDelayBlocks;
        votingPeriod = votingPeriodBlocks;
        quorumVotes = quorumVotesRaw;
        executionDelay = 0; // No delay by default
        paused = false;
    }

    modifier onlyMember() {
        require(membership.balanceOf(msg.sender) > 0, "not member");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "governance paused");
        _;
    }

    function setAllowedTarget(address target, bool allowed) external onlyRole(ADMIN_ROLE) {
        allowedTargets[target] = allowed;
        emit AllowedTargetSet(target, allowed);
    }

    function setQuorumVotes(uint256 newQuorum) external onlyRole(ADMIN_ROLE) {
        uint256 oldQuorum = quorumVotes;
        quorumVotes = newQuorum;
        emit QuorumChanged(oldQuorum, newQuorum);
    }

    function setVotingWindow(uint256 delayBlocks, uint256 periodBlocks) external onlyRole(ADMIN_ROLE) {
        votingDelay = delayBlocks;
        votingPeriod = periodBlocks;
    }

    function setExecutionDelay(uint256 delayBlocks) external onlyRole(ADMIN_ROLE) {
        uint256 oldDelay = executionDelay;
        executionDelay = delayBlocks;
        emit ExecutionDelayChanged(oldDelay, delayBlocks);
    }

    function setPaused(bool _paused) external onlyRole(ADMIN_ROLE) {
        paused = _paused;
        emit PausedStateChanged(_paused);
    }

    function _hashProposal(
        Call[] memory calls,
        string memory description,
        GovernanceMeta memory meta
    ) internal pure returns (uint256) {
        // Include meta.workHash and meta.ltraceHash into the proposalId computation
        return uint256(
            keccak256(
                abi.encode(
                    calls,
                    keccak256(bytes(description)),
                    meta.workHash,
                    meta.ltraceHash
                )
            )
        );
    }

    function propose(
        Call[] memory calls,
        string memory description,
        GovernanceMeta memory meta
    ) external onlyMember whenNotPaused returns (uint256 proposalId) {
        require(calls.length > 0, "no calls");

        // Basic sanity: workHash and ltraceHash must be non-zero
        require(meta.workHash != bytes32(0), "workHash required");
        require(meta.ltraceHash != bytes32(0), "ltraceHash required");

        // TODO: (optional) verify evaluationAttUid against EAS on-chain

        // All targets must be on the allowed list
        for (uint256 i = 0; i < calls.length; i++) {
            require(allowedTargets[calls[i].target], "target not allowed");
        }

        proposalId = _hashProposal(calls, description, meta);
        ProposalCore storage p = proposals[proposalId];
        require(p.startBlock == 0, "proposal exists");

        uint64 start = (block.number + votingDelay).toUint64();
        uint64 end = (block.number + votingDelay + votingPeriod).toUint64();

        proposals[proposalId] = ProposalCore({
            proposer: msg.sender,
            startBlock: start,
            endBlock: end,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            canceled: false
        });

        proposalMeta[proposalId] = meta;

        // Persist calls
        for (uint256 i = 0; i < calls.length; i++) {
            proposalCalls[proposalId].push(calls[i]);
        }

        emit ProposalCreated(proposalId, msg.sender, meta);
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        ProposalCore memory p = proposals[proposalId];
        if (p.startBlock == 0) {
            revert("proposal not found");
        }
        if (p.canceled) return ProposalState.Canceled;
        if (p.executed) return ProposalState.Executed;

        if (block.number < p.startBlock) return ProposalState.Pending;
        if (block.number <= p.endBlock) return ProposalState.Active;

        // Voting period over
        if (p.forVotes + p.againstVotes + p.abstainVotes < quorumVotes) {
            return ProposalState.Defeated; // no quorum
        }
        if (p.forVotes <= p.againstVotes) {
            return ProposalState.Defeated;
        }

        return ProposalState.Succeeded;
    }

    function castVote(uint256 proposalId, VoteType voteType) external onlyMember {
        ProposalCore storage p = proposals[proposalId];
        require(p.startBlock != 0, "proposal not found");

        ProposalState s = state(proposalId);
        require(s == ProposalState.Active, "voting closed");

        // Resolve primeIdHash from membership SBT
        bytes32 primeIdHash = membership.getPrimeIdHashForAddress(msg.sender);
        require(primeIdHash != bytes32(0), "no primeIdHash");

        require(!hasVoted[proposalId][primeIdHash], "already voted");
        hasVoted[proposalId][primeIdHash] = true;

        // weight = 1 per member for now (1p1v)
        uint8 weight = 1;

        if (voteType == VoteType.For) {
            p.forVotes += weight;
        } else if (voteType == VoteType.Against) {
            p.againstVotes += weight;
        } else {
            p.abstainVotes += weight;
        }

        emit VoteCast(proposalId, msg.sender, voteType, weight);
    }

    function cancel(uint256 proposalId) external {
        ProposalCore storage p = proposals[proposalId];
        require(p.startBlock != 0, "proposal not found");
        require(msg.sender == p.proposer || hasRole(ADMIN_ROLE, msg.sender), "not auth");

        ProposalState s = state(proposalId);
        require(s == ProposalState.Pending || s == ProposalState.Active, "cannot cancel");

        p.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function execute(uint256 proposalId) external payable whenNotPaused {
        ProposalCore storage p = proposals[proposalId];
        require(p.startBlock != 0, "proposal not found");

        ProposalState s = state(proposalId);
        require(s == ProposalState.Succeeded, "proposal not succeeded");
        require(!p.executed, "already executed");

        // Enforce execution delay (timelock)
        require(block.number >= p.endBlock + executionDelay, "execution delay not met");

        p.executed = true;

        Call[] storage calls = proposalCalls[proposalId];

        for (uint256 i = 0; i < calls.length; i++) {
            Call memory c = calls[i];
            c.target.functionCallWithValue(c.data, c.value);
        }

        emit ProposalExecuted(proposalId);
    }

    function getProposalCalls(uint256 proposalId) external view returns (Call[] memory) {
        return proposalCalls[proposalId];
    }
}
