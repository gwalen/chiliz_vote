// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./interface/ITokenVoter.sol";
import "./interface/ISurvey.sol";
import "./TokenVoterUpgradeableBeacon.sol";

contract VoterManager is UUPSUpgradeable {
    address public admin;

    // token address to tokenVoter proxy address
    mapping(address => address) public tokenVoters;

    event Stake(address token, address user, uint256 amount);
    event Unstake(address token, address user, uint256 amount);

    modifier OnlyAdmin() {
        require(msg.sender == admin, "Only admin"); // TODO: typed errors
        _;
    }

    // Disable initializing on implementation contract
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin) external initializer {
        // Init inherited contract
        __UUPSUpgradeable_init();
        admin = _admin;
    }

    // Makes sure only the admin can upgrade, called from upgradeTo(..)
    function _authorizeUpgrade(address newImplementation) internal override OnlyAdmin {}

    function addTokenVoter(address token,address tokenVoter) external OnlyAdmin {
        require(tokenVoters[token] == address(0), "Token voter already exists");
        tokenVoters[token] = tokenVoter;
    }

    function stake(address token, uint256 amount) external {
        ITokenVoter tokenVoter = ITokenVoter(tokenVoters[token]);
        tokenVoter.stake(token, msg.sender, amount);
        emit Stake(token, msg.sender, amount);
    }

    function unstake(address token, uint256 amount) external {
        ITokenVoter tokenVoter = ITokenVoter(tokenVoters[token]);
        tokenVoter.unstake(token, msg.sender, amount);
        emit Unstake(token, msg.sender, amount);
    }

    function vote(address token, uint32 surveyId, bool voteDirection) external {
        ITokenVoter tokenVoter = ITokenVoter(tokenVoters[token]);
        tokenVoter.vote(msg.sender, surveyId, voteDirection);
    }

    function voteResult(
        address token,
        uint256 surveyId
    ) external view returns (ISurvey.VoteResult) {
        ITokenVoter tokenVoter = ITokenVoter(tokenVoters[token]);
        return tokenVoter.voteResult(surveyId);
    }

}
