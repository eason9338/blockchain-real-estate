pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PropertyDAO {
    address public manager;
    address public tokenAddress;

    mapping(address => uint256) public votes;
    address[] public candidates;

    constructor(address _tokenAddress) {
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

        votes[candidate] += balance;
    }

    function finalize() public {
        address topCandidate;
        uint256 topVotes = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (votes[candidates[i]] > topVotes) {
                topVotes = votes[candidates[i]];
                topCandidate = candidates[i];
            }
        }

        manager = topCandidate;
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
