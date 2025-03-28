// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {FundMeDeploy} from "../../script/FundMeDeploy.s.sol";

contract FundMeTest is Test {
    FundMe fundme;

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether; // 1000000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

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

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.prank(fundme.getOwner()); // c: 200
        fundme.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundme).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundme).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }
}
