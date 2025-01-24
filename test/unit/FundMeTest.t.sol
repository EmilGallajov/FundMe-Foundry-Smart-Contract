// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant USER_SEND = 0.1 ether; // 1e17
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;    
    function setUp() external {
        // it is us, us -> FundMeTest -> FundMe, us=fundMe
        // This FundMe contract owner is FundMeTest, not us!
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // this will give fake ether to USER for staring balance 
    }

    function testMinimumDollarIsFive() public {
        // I think this is gas efficient than the traditional if-else statement
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
        console.log("Minimum USD is 5");
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner()); // debug makes easy:D
        console.log(address(this));
        assertEq(fundMe.i_owner(), msg.sender);
        // msg.sender is us, the owner is FundMeTest. We need to assign address like address(this) 
        // msg.sender address is assigned by the foundry by default
        // msg.sender represents an Externally Owned Account (EOA) that Foundry uses for test transactions.        
    }

    function testPriceFeedVersionIsAccurate() public {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // this is foundry cheatcode. After it, the next line should revert!
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //next tx will be sent from USER
        fundMe.fund{value: USER_SEND}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, USER_SEND);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); //next tx will be sent from USER
        fundMe.fund{value: USER_SEND}();    
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: USER_SEND}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); //next tx will be sent from USER
        vm.expectRevert(); // this is foundry cheatcode. After it, the next line should revert!
        fundMe.withdraw();  
    }
    
    function testWithdrawWithSingleFunder() public funded{
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        uint256 gasStarted = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnded = gasleft();
        console.log("Gas used: ", (gasStarted - gasEnded)*tx.gasprice);
        
        // assert 
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;        
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunder() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), USER_SEND);
            fundMe.fund{value: USER_SEND}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;        

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);

    }

    function testWithdrawWithMultipleFunderCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), USER_SEND);
            fundMe.fund{value: USER_SEND}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;        

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }


    
}   