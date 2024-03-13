// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/ITokenVoter.sol";
import "./VoterManager.sol";
import "./interface/ISurvey.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

contract TokenVoter is ITokenVoter, Initializable {

    address public baseToken;
    VoterManager public voterManager;
    address public admin;
    // surveyId to survey
    mapping(uint256 => ISurvey) public surveys;
    // user address to his voting power, voting power also hold info about deposited tokens
    mapping(address => uint256) public votingPower;

    // Disable initializing on implementation contract
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _baseToken, address _voterManager) external initializer {
        admin = _admin;
        baseToken = _baseToken;
        voterManager = VoterManager(_voterManager);
    }

    modifier OnlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function setVoterManager(address _voterManager) external OnlyAdmin {
         // no need for interface there is just one impl of VoterManager
        voterManager = VoterManager(_voterManager);
    }

    function addSurvey(address _survey) external OnlyAdmin {
        uint256 surveyId = ISurvey(_survey).surveyId();
        surveys[surveyId] = ISurvey(_survey);
    }

    // this should have some check if survey is not active
    function removeSurvey(uint256 surveyId) external OnlyAdmin {
        delete surveys[surveyId];
    }

    function vote(address voter, uint32 surveyId, bool voteDirection) external override {
        require(surveys[surveyId] != ISurvey(address(0)), "Survey not found");
        require(votingPower[voter] > 0, "Voting power must be greater than zero");

        ISurvey survey = surveys[surveyId];
        survey.vote(voter, voteDirection, votingPower[voter]);
    }

    function voteResult(uint256 surveyId) external view returns(ISurvey.VoteResult) {
        require(surveys[surveyId] != ISurvey(address(0)), "Survey not found");

        ISurvey survey = surveys[surveyId];
        return survey.voteResult();
    }

    function stake(address token, address voter, uint256 amount) external override {
        require(IERC20(token).balanceOf(voter) >= amount, "Balance too small");
        require(IERC20(token).allowance(voter, address(this)) >= amount, "Allowance not set");

        IERC20(token).transferFrom(voter, address(this), amount);
        votingPower[voter] += amount;
    }

    function unstake(address token, address voter, uint256 amount) external override {
        require(votingPower[voter] >= amount, "Unstake amount too big");

        IERC20(token).transfer(voter, amount);
        votingPower[voter] -= amount;
    }
}
