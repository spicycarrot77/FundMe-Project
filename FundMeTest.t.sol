// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // Write tests here
    FundMe fundMe;
    address USER = makeAddr("user"); //this is a dummy sender of transaction
    uint256 num = 1;
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

   function setUp() external {
       // This function always runs first
    //    num = 2;
   //  fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
   DeployFundMe deployFundMe = new DeployFundMe();
   fundMe = deployFundMe.run();   //NOW ANYCHANGES TO DEPLOY FUNDME CONTRACT WILL BE REFLECTED HERE  
   vm.deal(USER, STARTING_BALANCE); //this keyword gives starting balance to user
   }

   function testMinUSD() external {
       // This is a test function
    //    console.log(num);
    //    assertEq(num, 2);
    assertEq(fundMe.MINIMUM_USD(), 5e18); //checking if minimum USD is equal to 5e18
   }


      function testOwner() external {
          // This is a test function
       //    console.log(num);
       //    assertEq(num, 2);
       console.log("Owner address: ", msg.sender);
       console.log("FundMe contract owner address: ", fundMe.i_owner());
       // Checking if the owner of the FundMe contract is the address that deployed it
       //assertEq(fundMe.i_owner(), msg.sender); 
       //this fails because in FundMe contract, owner is set to the address that deploys the contract
         //but here in the test, the contract is deployed by the test contract address therefore test is the owner, not msg.sender hence we should check the adress of the test contract
assertEq(fundMe.i_owner(), address(this)); //checking if owner is equal to the address of this contract
   }


   function testPriceFeedVersion() public{
       // This is a test function
    //    console.log(num);
    //    assertEq(num, 2);
    assertEq(fundMe.getVersion(), 4); //checking if price feed version is equal to 11155111
   }
   function testFundFailWithoutEnoughETH() public{
       // This is a test function
    //    console.log(num);
    //    assertEq(num, 2);
    vm.expectRevert(); //expecting the next line to fail otherwise the test fails
    fundMe.fund(); //funding without sending any ETH should fail(we are sending 0 eth)
   }

   function testFundUpdatesFundedDataStructures() public {
      vm.prank(USER); //THIS TELLS THAT THE NEXT TRANX WILL BE SENT BY USER
      fundMe.fund{value: SEND_VALUE}();
      uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
      assertEq(amountFunded, SEND_VALUE);
   }

   function testAddsFunderToArraysOfFunders() public {
     vm.prank(USER);
     fundMe.fund{value: SEND_VALUE}();
    address funder = fundMe.getFunder(0); //0 because we have only one funder
   assertEq( funder, USER);
   }

   modifier funder(){
      vm.prank(USER);
      fundMe.fund{value: SEND_VALUE}();
      _;
   }

   function testOnlyOwnerCanWithdraw() public funded {
      vm.prank(USER);
       vm.expectRevert(); 
       fundMe.withdraw();
   }

   function testWithDrawWithASingleFunder() public funded {
      //ARRANGE
      uint256 startingOwnerBalance = fundMe.i_owner().balance;
      uint256 startingFundMeBalance = address(fundMe).balance;

      //ACT
      vm.prank(fundMe.i_owner());
      fundMe.withdraw();

      //ASSERT
      uint256 endingOwnerBalance = fundMe.i_owner().balance;
      uint256 endingFundMeBalance = address(fundMe).balance;
      assertEq(endingFundMeBalance, 0);
      assertEq(
         startingFundMeBalance + startingOwnerBalance,
         endingOwnerBalance
      );
}

function testWithDrawFromMultipleFunders() public funded {
   //ARRANGE
   uint160 numberOfFunders = 10;
   uint160 startingFunderIndex = 1; //0 is USER
   for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      //vm.prank changes the msg.sender to the address passed in the parameter
      //we are using uint160 because address is a 20 byte value and uint160 is also a 20 byte value
      //if we use uint256, it will be converted to 32 byte value and then to address which will give an error
      address funder = address(i); //if you want numbers to generate addresses, use uint160
      vm.deal(funder, SEND_VALUE); //giving each funder some eth to fund the contract
      vm.prank(funder);
      fundMe.fund{value: SEND_VALUE}();
   }
   uint256 startingOwnerBalance = fundMe.i_owner().balance;
   uint256 startingFundMeBalance = address(fundMe).balance;

   //ACT
   vm.prank(fundMe.i_owner());
   fundMe.withdraw();

   //ASSERT
   uint256 endingOwnerBalance = fundMe.i_owner().balance;
   uint256 endingFundMeBalance = address(fundMe).balance;
   assertEq(endingFundMeBalance, 0);
   assertEq(
      startingFundMeBalance + startingOwnerBalance,
      endingOwnerBalance
   );

   //MAKE SURE THAT THE FUNDERS ARE RESET PROPERLY
   vm.expectRevert(); //expecting the next line to fail because there are no funders
   fundMe.getFunder(0);
   for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      address funder = address(i);
      assertEq(fundMe.getAddressToAmountFunded(funder), 0);
   }
}
}