// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ISurvey {

    enum VoteResult {
        YES,
        NO,
        DRAW
    }

    function surveyId() external view returns(uint256);

    function vote(address voter, bool voteDirection, uint256 votePower) external;

    function voteResult() external view returns(VoteResult);

}