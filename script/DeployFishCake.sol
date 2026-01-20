// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {FishCakeFactory} from "../src/FishCakeFactory.sol";
import {FishCakePaymaster} from "../src/FishCakePaymaster.sol";

contract DeployFishCake is Script {
    function run() external {
        // 从环境变量中读取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署工厂合约
        FishCakeFactory factory = new FishCakeFactory();
        console.log("Factory deployed at:", address(factory));

        // 2. 部署 Paymaster
        FishCakePaymaster paymaster = new FishCakePaymaster();
        console.log("Paymaster deployed at:", address(paymaster));

        // 3. 为 Paymaster 存入 Gas 费 (以 Sepolia 测试网为例，存入 0.1 ETH)
        // 注意：这是存入 EntryPoint 给 Paymaster 使用的额度
        paymaster.deposit{value: 0.1 ether}();
        console.log("Paymaster deposited 0.1 ETH to EntryPoint");

        // 4. 将部署者地址加入白名单（方便后续测试）
        paymaster.setWhitelist(deployerAddress, true);
        console.log("Deployer whitelisted in Paymaster");

        vm.stopBroadcast();
    }
}
