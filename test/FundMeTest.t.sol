// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {FundMeDeploy} from "../script/FundMeDeploy.s.sol";

contract FundMeTest is Test {
    FundMe fundme;

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether; // 1000000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        FundMeDeploy fundmedeploy = new FundMeDeploy();
        fundme = fundmedeploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsdIs() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIs() public view {
        assertEq(fundme.i_owner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        if (block.chainid == 11155111) {
            uint256 version = fundme.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundme.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line, should revert!
        // assert(This tx fails/reverts)
        fundme.fund(); // send 0 value of eth
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be from USER
        fundme.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }
}
