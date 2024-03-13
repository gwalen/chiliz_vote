// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ISurvey.sol";

interface ITokenVoter {
    
    function vote(address voter, uint32 surveyId, bool voteDirection) external;

    function voteResult(uint256 surveyId) external view returns(ISurvey.VoteResult);

    function stake(address token, address voter, uint256 amount) external;
    
    function unstake(address token, address voter, uint256 amount) external;

}
