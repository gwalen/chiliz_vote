// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/ITokenVoter.sol";
import "./TokenVoterUpgradeableBeacon.sol";
import "./TokenVoter.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract TokenVoterFactory {
    address public admin;
    // beacon can not be changed after initialization (all beacon proxies refer to this address)
    TokenVoterUpgradeableBeacon immutable beacon;
    // token address to tokenVoter proxy address
    mapping(address => address) public tokenVotersByTokens;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _beacon) {
        admin = _admin;
        beacon = TokenVoterUpgradeableBeacon(_beacon);
    }

    function createTokenVoter(address baseToken, address voterManager) external onlyAdmin {
        require(tokenVotersByTokens[baseToken] == address(0), "Token voter for token already initialized");
        BeaconProxy newTokenVoterProxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(TokenVoter(address(0)).initialize.selector, admin, baseToken, voterManager)
        );
        tokenVotersByTokens[baseToken] = address(newTokenVoterProxy);
    }

}