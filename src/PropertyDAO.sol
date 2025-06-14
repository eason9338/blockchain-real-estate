// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ✅ 使用 OpenZeppelin 提供的 IERC20 定義

contract PropertyDAO is Ownable {
    address public manager;
    address public tokenAddress;

    mapping(address => uint256) public votes;
    mapping(address => bool) public hasVoted;
    address[] public voters;
    address[] public candidates;

    constructor(address _tokenAddress, address initialOwner) Ownable(initialOwner) {
        tokenAddress = _tokenAddress;
    }

    function proposeManager(address candidate) public {
        require(!isCandidate(candidate), "Already proposed");
        candidates.push(candidate);
    }

    function vote(address candidate) public {
        require(isCandidate(candidate), "Not a valid candidate");

        uint256 balance = IERC20(tokenAddress).balanceOf(msg.sender);
        require(balance > 0, "You have no voting power");

        require(!hasVoted[msg.sender], "You already voted");
        hasVoted[msg.sender] = true;
        voters.push(msg.sender);

        votes[candidate] += balance;
    }

    function finalize() public onlyOwner {
        address topCandidate;
        uint256 topVotes = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (votes[candidates[i]] > topVotes) {
                topVotes = votes[candidates[i]];
                topCandidate = candidates[i];
            }
        }

        manager = topCandidate;
        resetElection();
    }

    function resetElection() internal {
        for (uint i = 0; i < candidates.length; i++) {
            votes[candidates[i]] = 0;
        }

        for (uint i = 0; i < voters.length; i++) {
            hasVoted[voters[i]] = false;
        }

        delete voters;
        delete candidates;
    }

    function isCandidate(address c) internal view returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == c) return true;
        }
        return false;
    }

    function getCandidates() public view returns (address[] memory) {
        return candidates;
    }
}
