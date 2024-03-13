// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/ITokenVoter.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";


contract TokenVoterUpgradeableBeacon is UpgradeableBeacon {

    constructor(address implementation_, address initialOwner) UpgradeableBeacon(implementation_, initialOwner) {
    }
}