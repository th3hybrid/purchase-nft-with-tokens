// SPDX-License-Identifier:MIt

pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {AirplaneNft} from "src/AirplaneNft.sol";
import {AceToken} from "src/AceToken.sol";
import {DeployAirplaneNft} from "script/DeployAirplaneNft.s.sol";

contract AirplaneNftTest is Test {
    AirplaneNft airplaneNft;
    DeployAirplaneNft deployer;
    AceToken aceToken;

    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    uint256 public constant STARTING_BALANCE = 10e18;
    uint256 public constant SEND_VALUE = 1e16;
    uint256 public constant TOKEN_AMOUNT = 500 * 1e18;
    uint256 private constant PRICE = 250 * 1e18;

    function setUp() public {
        deployer = new DeployAirplaneNft();
        (airplaneNft, aceToken) = deployer.run();
        vm.deal(bob, STARTING_BALANCE);
        vm.deal(alice, STARTING_BALANCE);

        vm.prank(msg.sender);
        aceToken.transfer(bob, TOKEN_AMOUNT);
    }

    function testCanUseToken() public view {
        assertEq(aceToken.balanceOf(bob), TOKEN_AMOUNT);
        assertEq(aceToken.balanceOf(alice), 0);
    }

    function testCannotMintWithoutAce() public {
        //arrange/act
        vm.expectRevert(AirplaneNft.AirplaneNft__NotEnoughTokens.selector);
        vm.prank(alice);
        airplaneNft.mintNFTWithAce();
    }

    function testCannotMintwithInsufficientAceAllocation() public {
        //arrange/act
        vm.prank(bob);
        aceToken.approve(address(airplaneNft), 200 * 1e18);
        vm.expectRevert();
        vm.prank(bob);
        airplaneNft.mintNFTWithAce();
    }

    function testMustReApproveAfterSpending() public {
        //arrange/act
        vm.prank(bob);
        aceToken.approve(address(airplaneNft), PRICE);
        vm.prank(bob);
        airplaneNft.mintNFTWithAce();

        vm.expectRevert();
        vm.prank(bob);
        airplaneNft.mintNFTWithAce();
    }

    function testCanMintwithAce() public {
        //arrange/act
        uint256 startingOwnerBalance = aceToken.balanceOf(
            airplaneNft.getOwner()
        );
        vm.prank(bob);
        aceToken.approve(address(airplaneNft), PRICE);
        vm.prank(bob);
        airplaneNft.mintNFTWithAce();
        uint256 endingOwnerBalance = aceToken.balanceOf(airplaneNft.getOwner());
        //assert
        assertEq(airplaneNft.ownerOf(0), bob);
        assertEq(aceToken.balanceOf(bob), PRICE);
        assertEq(startingOwnerBalance + PRICE, endingOwnerBalance);
    }

    function testCanFlowProperlyWithEthAndAce() public {
        //arrange/act
        vm.prank(bob);
        aceToken.approve(address(airplaneNft), PRICE);
        vm.prank(bob);
        airplaneNft.mintNFTWithAce();
        vm.prank(alice);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        //assert
        assertEq(airplaneNft.ownerOf(0), bob);
        assertEq(airplaneNft.ownerOf(1), alice);
    }

    function testCanMintWithEth() public {
        //arrange
        vm.prank(bob);
        //act
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        //assert
        assertEq(airplaneNft.ownerOf(0), bob);
    }

    function testCantMintWithoutPaying() public {
        //arrange
        vm.expectRevert(AirplaneNft.AirplaneNft__SendMoreEth.selector);
        vm.prank(bob);
        //act
        airplaneNft.mintNFTWithEth{value: 0}();
        //assert
    }

    function testNftCanBeTransferred() public {
        //arrange
        vm.prank(bob);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();

        //act
        vm.prank(bob);
        airplaneNft.transferFrom(bob, alice, 0);

        //assert
        assertEq(airplaneNft.ownerOf(0), alice);
    }

    function testTokenCounterIncrements() public {
        //arrange/act
        vm.prank(bob);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        vm.prank(alice);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        //assert
        assertEq(airplaneNft.ownerOf(0), bob);
        assertEq(airplaneNft.ownerOf(1), alice);
    }

    function testTokenIdReturnsCorrectUri() public {
        //arrange/act
        string
            memory expectedUri = "https://ipfs.io/ipfs/QmaA83SY1dd7BsnNwRx8GocGFu9pbcRbzmNnyNN5oT4quW?filename=airplane.json";
        vm.prank(bob);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        vm.prank(alice);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        //assert
        assertEq(airplaneNft.tokenURI(0), expectedUri);
        assertEq(airplaneNft.tokenURI(1), expectedUri);
    }

    function testOnlyOwnerCanWithdraw() public {
        //arrange/act
        vm.prank(bob);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        vm.expectRevert(AirplaneNft.AirplaneNft__NotOwner.selector);
        vm.prank(alice);
        airplaneNft.withdraw();
    }

    function testOwnerCanWithdraw() public {
        //arrange/act
        vm.prank(bob);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();

        uint256 startingOwnerBalance = airplaneNft.getOwner().balance;
        uint256 startingAirplaneNftBalance = address(airplaneNft).balance;

        vm.prank(airplaneNft.getOwner());
        airplaneNft.withdraw();
        //assert
        uint256 endingOwnerBalance = airplaneNft.getOwner().balance;
        uint256 endingAirplaneNftBalance = address(airplaneNft).balance;
        assertEq(endingAirplaneNftBalance, 0);
        assertEq(
            startingAirplaneNftBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testCannotWithdrawIfNoEth() public {
        //arrange
        address owner = airplaneNft.getOwner();
        //act
        vm.expectRevert(AirplaneNft.AirplaneNft__InsufficientBalance.selector);
        vm.prank(owner);
        airplaneNft.withdraw();
    }

    /* function testWithdrawalFailed() public {
        //arrange/act
        address owner = airplaneNft.getOwner();
        vm.prank(bob);
        airplaneNft.mintNFTWithEth{value: SEND_VALUE}();
        vm.expectRevert(AirplaneNft.AirplaneNft__NotOwner.selector);
        vm.prank(owner);
        airplaneNft.withdraw();
    }*/

    function testDoesNotReturnUriForUnmintedNft() public view {
        string memory unMintedNft = airplaneNft.tokenURI(4);
        assertEq(unMintedNft, "");
    }
}

//arrange
//act
//assert
