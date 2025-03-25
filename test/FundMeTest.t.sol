// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundme;

    function setUp() external {
        fundme = new FundMe(msg.sender);
    }

    function testMinimumUsdIs() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }
}
