// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IssueDAO is Ownable {
    address public tokenAddress;

    struct Proposal {
        string content;
        uint256 votesFor;
        uint256 votesAgainst;
        bool finalized;
        bool passed;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalCreated(uint256 proposalId, string content);
    event Voted(
        uint256 proposalId,
        address voter,
        bool support,
        uint256 weight
    );
    event ProposalFinalized(uint256 proposalId, bool passed);
    event ProposalExecuted(uint256 proposalId);

    constructor(
        address _tokenAddress,
        address initialOwner
    ) Ownable(initialOwner) {
        tokenAddress = _tokenAddress;
    }

    function createProposal(string memory _content) public onlyOwner {
        proposals.push(
            Proposal({
                content: _content,
                votesFor: 0,
                votesAgainst: 0,
                finalized: false,
                passed: false,
                executed: false
            })
        );

        emit ProposalCreated(proposals.length - 1, _content);
    }

    function vote(uint256 proposalId, bool support) public {
        require(proposalId < proposals.length, "Invalid proposalId");
        require(!hasVoted[msg.sender][proposalId], "Already voted");

        uint256 weight = IERC20(tokenAddress).balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            proposals[proposalId].votesFor += weight;
        } else {
            proposals[proposalId].votesAgainst += weight;
        }

        hasVoted[msg.sender][proposalId] = true;
        emit Voted(proposalId, msg.sender, support, weight);
    }

    // ✅ 開票函式：結算結果（任何人可叫用，也可以限制 onlyOwner）
    function finalizeProposal(uint256 proposalId) public onlyOwner {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        require(!p.finalized, "Already finalized");

        p.passed = p.votesFor > p.votesAgainst;
        p.finalized = true;

        emit ProposalFinalized(proposalId, p.passed);
    }

    // ✅ 執行函式：僅對通過的提案允許進行進一步治理操作
    function executeProposal(uint256 proposalId) public onlyOwner {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        require(p.finalized, "Proposal not finalized");
        require(p.passed, "Proposal not passed");
        require(!p.executed, "Already executed");

        p.executed = true;

        // ✅ 在此處加入實際執行邏輯，例如更新治理狀態、撥款等等

        emit ProposalExecuted(proposalId);
    }

    function getProposal(
        uint256 proposalId
    )
        public
        view
        returns (
            string memory content,
            uint256 votesFor,
            uint256 votesAgainst,
            bool finalized,
            bool passed,
            bool executed
        )
    {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        return (
            p.content,
            p.votesFor,
            p.votesAgainst,
            p.finalized,
            p.passed,
            p.executed
        );
    }

    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }
}
