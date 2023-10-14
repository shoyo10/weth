// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import {WrapEth, IWEthEvent} from "../src/Weth.sol";

contract WrapEthTest is Test, IWEthEvent {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    WrapEth public weth;
    address public user1;

    function setUp() public {
        weth = new WrapEth();
        user1 = makeAddr("user1");
    }

    // deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
    function test_DepositUserGetEqualWETH() public {
        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        (bool success,) = address(weth).call{value: 0.5 ether}(abi.encodeWithSignature("deposit()"));
        require(success);
        assertEq(weth.balanceOf(user1), 0.5 ether);

        vm.stopPrank();
    }

    // deposit 應該將 msg.value 的 ether 轉入合約
    function test_DepositContraceGetEther() public {
        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        (bool success,) = address(weth).call{value: 0.5 ether}(abi.encodeWithSignature("deposit()"));
        require(success);
        assertEq(address(weth).balance, 0.5 ether);

        vm.stopPrank();
    }

    // deposit 應該要 emit Deposit event
    function test_DepositEmitDepositEvent() public {
        uint256 _amount = 0.5 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Deposit(user1, _amount);

        vm.recordLogs();

        (bool success,) = address(weth).call{value: _amount}(abi.encodeWithSignature("deposit()"));
        require(success);

        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        // topics[0] is the event signature
        assertEq(entries[0].topics.length, 2);
        assertEq(entries[0].topics[0], keccak256("Deposit(address,uint256)"));
        assertEq(address(uint160(uint256((entries[0].topics[1])))), user1);
        assertEq(abi.decode(entries[0].data, (uint256)), _amount);
    }

    // withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
    function test_WithdrawShouldBurnWEth() public {
        uint256 _depositAmount = 0.5 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        require(success);

        vm.stopPrank();

        // withdraw 0.2 ether
        uint256 _withdrawAmount = 0.2 ether;
        vm.startPrank(user1);

        weth.withdraw(_withdrawAmount);

        vm.stopPrank();

        assertEq(weth.balanceOf(user1), _depositAmount - _withdrawAmount);
    }

    // withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
    function test_WithdrawShouldRetuenEthToUser() public {
        uint256 _depositAmount = 0.5 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        require(success);

        vm.stopPrank();

        // withdraw 0.2 ether
        uint256 _withdrawAmount = 0.2 ether;
        vm.startPrank(user1);

        weth.withdraw(_withdrawAmount);

        vm.stopPrank();

        assertEq(user1.balance, 0.7 ether);
        assertEq(address(weth).balance, 0.3 ether);
    }

    // withdraw 應該要 emit Withdraw event
    function test_WithdrawEmiWithdrawEvent() public {
        uint256 _depositAmount = 0.5 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        require(success);

        vm.stopPrank();

        // withdraw 0.2 ether
        uint256 _withdrawAmount = 0.2 ether;
        vm.startPrank(user1);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(user1, _withdrawAmount);

        vm.recordLogs();
        weth.withdraw(_withdrawAmount);

        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        // topics[0] is the event signature
        assertEq(entries[0].topics.length, 2);
        assertEq(entries[0].topics[0], keccak256("Withdraw(address,uint256)"));
        assertEq(address(uint160(uint256((entries[0].topics[1])))), user1);
        assertEq(abi.decode(entries[0].data, (uint256)), _withdrawAmount);
    }

    // transfer 應該要將 erc20 token 轉給別人
    function test_TransferShouldTransferERC20ToOther() public {
        uint256 _depositAmount = 0.5 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        require(success);

        vm.stopPrank();

        // transfer 0.2 ether to user2
        address user2 = makeAddr("user2");
        uint256 _transferAmount = 0.2 ether;
        vm.startPrank(user1);

        success = weth.transfer(user2, _transferAmount);
        assertTrue(success);

        vm.stopPrank();

        assertEq(weth.balanceOf(user1), _depositAmount - _transferAmount);
        assertEq(weth.balanceOf(user2), _transferAmount);
    }

    // approve 應該要給他人 allowance
    function test_ApproveShouldGiveSomeoneAllowance() public {
        address spender = makeAddr("spender");
        uint256 _amount = 0.5 ether;

        vm.startPrank(user1);

        // approve
        bool success = weth.approve(spender, _amount);
        assertTrue(success);

        vm.stopPrank();

        assertEq(weth.allowance(user1, spender), _amount);
    }

    // transferFrom 應該要可以使用他人的 allowance
    function test_TransferFromShouldUseSomeoneAllowance() public {
        uint256 _depositAmount = 0.5 ether;
        address spender = makeAddr("spender");
        uint256 _allowAmount = 0.4 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        assertTrue(success);

        // approve
        success = weth.approve(spender, _allowAmount);
        assertTrue(success);

        vm.stopPrank();

        // transferFrom
        uint256 _transferAmount = 0.1 ether;
        address user3 = makeAddr("user3");

        vm.startPrank(spender);

        success = weth.transferFrom(user1, user3, _transferAmount);
        assertTrue(success);

        vm.stopPrank();

        assertEq(weth.balanceOf(user1), _depositAmount - _transferAmount);
        assertEq(weth.balanceOf(user3), _transferAmount);
    }

    // transferFrom 後應該要減除用完的 allowance
    function test_TransferFromShouldMinusAllowance() public {
        uint256 _depositAmount = 0.5 ether;
        address spender = makeAddr("spender");
        uint256 _allowAmount = 0.4 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        assertTrue(success);

        // approve
        success = weth.approve(spender, _allowAmount);
        assertTrue(success);

        vm.stopPrank();

        // transferFrom
        uint256 _transferAmount = 0.1 ether;
        address user3 = makeAddr("user3");
        vm.startPrank(spender);

        success = weth.transferFrom(user1, user3, _transferAmount);
        assertTrue(success);

        vm.stopPrank();

        assertEq(weth.allowance(user1, spender), _allowAmount - _transferAmount);
    }

    // transferFrom 應該要 emit Transfer event
    function test_TransferFromEmitTransferEvent() public {
        uint256 _depositAmount = 0.5 ether;
        address spender = makeAddr("spender");
        uint256 _allowAmount = 0.4 ether;

        vm.startPrank(user1);

        vm.deal(user1, 1 ether);
        // deposit 0.5 ether
        (bool success,) = address(weth).call{value: _depositAmount}(abi.encodeWithSignature("deposit()"));
        assertTrue(success);

        // approve
        success = weth.approve(spender, _allowAmount);
        assertTrue(success);

        vm.stopPrank();

        // transferFrom
        uint256 _transferAmount = 0.1 ether;
        address user3 = makeAddr("user3");
        vm.startPrank(spender);

        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user3, _transferAmount);

        vm.recordLogs();

        success = weth.transferFrom(user1, user3, _transferAmount);
        assertTrue(success);

        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        // topics[0] is the event signature
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(address(uint160(uint256((entries[0].topics[1])))), user1);
        assertEq(address(uint160(uint256((entries[0].topics[2])))), user3);
        assertEq(abi.decode(entries[0].data, (uint256)), _transferAmount);
    }

    // Approve 應該要 emit Approval event
    function test_ApproveEmitApproveEvent() public {
         address spender = makeAddr("spender");
        uint256 _amount = 0.5 ether;

        vm.startPrank(user1);

        vm.expectEmit(true, true, true, true);
        emit Approval(user1, spender, _amount);

        vm.recordLogs();

        // approve
        bool success = weth.approve(spender, _amount);
        assertTrue(success);

        vm.stopPrank();

        assertEq(weth.allowance(user1, spender), _amount);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        // topics[0] is the event signature
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[0].topics[0], keccak256("Approval(address,address,uint256)"));
        assertEq(address(uint160(uint256((entries[0].topics[1])))), user1);
        assertEq(address(uint160(uint256((entries[0].topics[2])))), spender);
        assertEq(abi.decode(entries[0].data, (uint256)), _amount);
    }
}
