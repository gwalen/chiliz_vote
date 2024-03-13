// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/ISurvey.sol";
import "./interface/ITokenVoter.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

contract Survey is ISurvey, Initializable {

    uint256 private _surveyId;
    string public surveyName;
    uint256 public yesCount;
    uint256 public noCount;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    ITokenVoter owner;

    // vote address to bool -> check if user have already voted
    mapping(address => bool) voted;

    event Voted(address voter, bool voteDirection, uint256 voterPower);

    // Disable initializing on implementation contract
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, uint256 __surveyId, string memory _name, uint256 _startTimestamp, uint256 _endTimestamp) external initializer {
        owner = ITokenVoter(_owner);
        _surveyId = __surveyId;
        surveyName = _name;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    modifier OnlyOwner() {
        require(msg.sender == address(owner), "Only owner");
        _;
    }

    function surveyId() external view override returns (uint256) {
        return _surveyId;
    }

    function vote(address voter, bool voteDirection, uint256 votePower) external override {
        require(!voted[voter], "Already voted");
        require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp, "Voting is not active");

        voted[voter] = true;
        if(voteDirection) {
            yesCount += votePower;
        } else {
            noCount += votePower;
        }
    
        emit Voted(voter, voteDirection, votePower);
    }

    function voteResult() external view override returns(VoteResult) {
        require(block.timestamp < endTimestamp, "Vote is over");

        if(yesCount == noCount) {
            return VoteResult.DRAW;
        }

        return (yesCount > noCount ? VoteResult.YES : VoteResult.NO);
    }
}