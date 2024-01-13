// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import "src/mock/MockToken.sol";
import {Test, console2} from "forge-std/Test.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSigWallet;
    MockToken public tokenA;

    function setUp() public {
        tokenA = new MockToken("TokenA", "TKA");
        address[] memory owners = new address[](4);
        owners[0] = address(2);
        owners[1] = address(3);
        owners[2] = address(4);
        owners[3] = address(5);
        multiSigWallet = new MultiSigWallet(owners, 3);
    }

    function test_addOwnerFlow() public {
        uint txId=createAddOwnerTx(address(6),address(2));
        assertEq(multiSigWallet.getOwners().length, 4);
        approveTx(txId,address(3));
        
        vm.startBroadcast(address(4));
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Execution(txId);
        multiSigWallet.confirmTransaction(txId);
        vm.stopBroadcast();

        assertEq(multiSigWallet.getOwners().length, 5);
    }

    function test_removeOwnerFlow() public {
        uint txId=createRemoveOwnerTx(address(2),address(2));
        assertEq(multiSigWallet.getOwners().length, 4);
        approveTx(txId,address(3));
        
        vm.startBroadcast(address(4));
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Execution(txId);
        multiSigWallet.confirmTransaction(txId);
        vm.stopBroadcast();
        
        assertEq(multiSigWallet.getOwners().length, 3);
    }
    function test_tokenTranferTx() public {
        tokenA.mint(address(multiSigWallet),1000);
        uint txId=createTokenTransferTx(address(243),100,address(2));
        assertEq(tokenA.balanceOf(address(243)), 0);

        approveTx(txId,address(3));
        
        vm.startBroadcast(address(4));
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Execution(txId);
        multiSigWallet.confirmTransaction(txId);
        vm.stopBroadcast();
        
        assertEq(tokenA.balanceOf(address(243)), 100);
    }

    function test_tokenTransferNotEnoughConfirmations() public{
        tokenA.mint(address(multiSigWallet),1000);
        uint txId=createTokenTransferTx(address(243),100,address(2));
        assertEq(tokenA.balanceOf(address(243)), 0);
        
        
        vm.startBroadcast(address(4));
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Confirmation(address(4),txId);
        multiSigWallet.confirmTransaction(txId);
        multiSigWallet.executeTransaction(txId);
        
        vm.stopBroadcast();
        
        assertEq(tokenA.balanceOf(address(243)), 0);
    }
    function test_revokeApprovalFlow() public{
        tokenA.mint(address(multiSigWallet),1000);
        uint txId=createTokenTransferTx(address(243),100,address(2));
        assertEq(tokenA.balanceOf(address(243)), 0);
        
        approveTx(txId,address(3));
        
        assertEq(multiSigWallet.getConfirmationCount(txId), 2);

        vm.startBroadcast(address(3));
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Revocation(address(3),txId);
        multiSigWallet.revokeConfirmation(txId);
        vm.stopBroadcast();
        
        assertEq(multiSigWallet.getConfirmationCount(txId), 1);
    }
    function test_getTransactionCount() public{
        tokenA.mint(address(multiSigWallet),1000);
        uint txId=createTokenTransferTx(address(243),100,address(2));
        assertEq(tokenA.balanceOf(address(243)), 0);
        
        approveTx(txId,address(3));
        approveTx(txId,address(4));
        
        assertEq(multiSigWallet.getConfirmationCount(txId), 3);
        assertEq(multiSigWallet.getTransactionCount(true,true), 1);
        assertEq(multiSigWallet.getTransactionCount(true,false), 0);
        assertEq(multiSigWallet.getTransactionCount(false,true), 1);
        assertEq(multiSigWallet.getTransactionCount(false,false), 0);
    }
    function test_getOwners() public{
        address[] memory owners = multiSigWallet.getOwners();
        assertEq(owners.length, 4);
        assertEq(owners[0], address(2));
        assertEq(owners[1], address(3));
        assertEq(owners[2], address(4));
        assertEq(owners[3], address(5));
    }
    function createTokenTransferTx(address _to,uint256 _amount,address _creator) internal returns (uint txId) {
        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            _to,
            _amount
        );
        uint txCount = multiSigWallet.transactionCount();
        vm.startBroadcast(_creator);
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Submission(txCount);
        txId = multiSigWallet.submitTransaction(
            address(tokenA),
            0,
            data
        );
        vm.stopBroadcast();
    }

    function createRemoveOwnerTx(address _owner,address _creator) internal returns (uint txId) {
        bytes memory data = abi.encodeWithSignature(
            "removeOwner(address)",
            _owner
        );
        uint txCount = multiSigWallet.transactionCount();
        vm.startBroadcast(_creator);
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Submission(txCount);
        txId = multiSigWallet.submitTransaction(
            address(multiSigWallet),
            0,
            data
        );
        vm.stopBroadcast();
    }

    function createAddOwnerTx(address _newOwner,address _creator) internal returns (uint txId) {
        bytes memory data = abi.encodeWithSignature(
            "addOwner(address)",
            _newOwner
        );
        uint txCount = multiSigWallet.transactionCount();
        vm.startBroadcast(_creator);
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Submission(txCount);
        txId = multiSigWallet.submitTransaction(
            address(multiSigWallet),
            0,
            data
        );
        vm.stopBroadcast();
    }
    function approveTx(uint _txId,address _approver) internal {
        vm.startBroadcast(_approver);
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Confirmation(_approver,_txId);
        multiSigWallet.confirmTransaction(_txId);
        vm.stopBroadcast();
    }
}
