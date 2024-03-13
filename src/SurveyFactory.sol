// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/ISurvey.sol";
import "./SurveyUpgradeableBeacon.sol";
import "./Survey.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract SurveyFactory {
    address public admin;
    // beacon can not be changed after initialization (all beacon proxies refer to this address)
    SurveyUpgradeableBeacon immutable beacon;
    // surveyId to survey proxy address
    mapping(uint256 => address) public surveysByTokens;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _beacon) {
        admin = _admin;
        beacon = SurveyUpgradeableBeacon(_beacon);
    }

    function createSurvey(
        uint256 surveyId,
        string memory name,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external onlyAdmin {
        require(surveysByTokens[surveyId] == address(0), "Token voter for token already initialized");

        BeaconProxy newSurveyProxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                Survey(address(0)).initialize.selector,
                admin,
                surveyId,
                name,
                startTimestamp,
                endTimestamp
            )
        );
        surveysByTokens[surveyId] = address(newSurveyProxy);
    }
}
