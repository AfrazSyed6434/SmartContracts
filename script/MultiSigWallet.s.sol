// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {Script, console2} from "forge-std/Script.sol";


contract MultiSigWalletScript is Script {
    MultiSigWallet public multiSigWallet;
    function setUp() public {}
    
    function run() public {
        uint256 deployerPrvKey = vm.envUint("PK1");
        address[] memory owners = new address[](4);        
        owners[0] = address(vm.envAddress("ADDR1"));
        owners[1] = address(vm.envAddress("ADDR2"));
        owners[2] = address(vm.envAddress("ADDR3"));
        owners[3] = address(vm.envAddress("ADDR4"));

        vm.startBroadcast(deployerPrvKey);
        multiSigWallet = new MultiSigWallet( owners,3);
        vm.stopBroadcast();

        require(multiSigWallet.getOwners().length == 4, "MultiSigWalletScript: owners length is not 4");
        
        uint256 txId = createAddOwnerTx(address(vm.envAddress("ADDR5")),vm.envUint("PK2"));
        approveTx(txId,vm.envUint("PK3"));
        approveTx(txId,vm.envUint("PK4"));
        
        require(multiSigWallet.getOwners().length == 5, "MultiSigWalletScript: owners length is not 5");

    
    }
    function createAddOwnerTx(address _newOwner, uint256 _creatorPrvKey) public returns (uint256 txId) {
       bytes memory data = abi.encodeWithSignature(
            "addOwner(address)",
            _newOwner
        );
        uint txCount = multiSigWallet.transactionCount();
        vm.startBroadcast(_creatorPrvKey);
        vm.expectEmit(address(multiSigWallet));
        emit MultiSigWallet.Submission(txCount);
        txId = multiSigWallet.submitTransaction(
            address(multiSigWallet),
            0,
            data
        );
        vm.stopBroadcast();
    }
    
    function approveTx(uint _txId,uint256 _approverPrvkey) internal {
        vm.startBroadcast(_approverPrvkey);
        multiSigWallet.confirmTransaction(_txId);
        vm.stopBroadcast();
    }
}
