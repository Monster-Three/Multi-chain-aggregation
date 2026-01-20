// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FishCakeFactory} from "../../src/FishCakeFactory.sol";
import {FishCakeSmartAccount, UserOperation} from "../../src/FishCakeSmartAccount.sol";
import {FishCakePaymaster} from "../../src/FishCakePaymaster.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract FishCakeTest is Test {
    using MessageHashUtils for bytes32;

    FishCakeFactory factory;
    FishCakePaymaster paymaster;
    address owner;
    uint256 ownerKey;
    address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function setUp() public {
        // 1. 初始化角色
        (owner, ownerKey) = makeAddrAndKey("owner");

        // 2. 部署合约
        factory = new FishCakeFactory();
        paymaster = new FishCakePaymaster();

        // 3. 准备 Paymaster：存款并加白名单
        vm.deal(address(paymaster), 10 ether);
        paymaster.deposit{value: 1 ether}();
        paymaster.setWhitelist(factory.getAddress(owner, 123), true);
    }

    function testFullUserOpFlow() public {
        uint256 salt = 123;
        address predictedAddr = factory.getAddress(owner, salt);

        // 1. 构造 UserOperation
        UserOperation memory userOp = UserOperation({
            sender: predictedAddr,
            nonce: 0,
            // 第一次调用需要 initCode 来部署钱包
            initCode: abi.encodePacked(
                address(factory),
                abi.encodeWithSelector(
                    factory.deployAccount.selector,
                    owner,
                    salt
                )
            ),
            callData: abi.encodeWithSelector(
                FishCakeSmartAccount.execute.selector,
                address(0x123),
                0,
                ""
            ),
            callGasLimit: 100000,
            verificationGasLimit: 500000,
            preVerificationGas: 50000,
            maxFeePerGas: 1 gwei,
            maxPriorityFeePerGas: 1 gwei,
            paymasterAndData: abi.encodePacked(address(paymaster)), // 指定 Paymaster
            signature: ""
        });

        // 2. 计算 UserOp Hash (模仿 EntryPoint 的逻辑)
        bytes32 userOpHash = keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        userOp.sender,
                        userOp.nonce,
                        keccak256(userOp.initCode),
                        keccak256(userOp.callData),
                        userOp.callGasLimit,
                        userOp.verificationGasLimit,
                        userOp.preVerificationGas,
                        userOp.maxFeePerGas,
                        userOp.maxPriorityFeePerGas,
                        keccak256(userOp.paymasterAndData)
                    )
                ),
                entryPoint,
                block.chainid
            )
        );

        // 3. 用户签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerKey,
            userOpHash.toEthSignedMessageHash()
        );
        userOp.signature = abi.encodePacked(r, s, v);

        // 4. 模拟 EntryPoint 调用 validateUserOp
        // 在实际网络中，这一步由 Bundler 触发 EntryPoint 完成
        vm.prank(entryPoint);
        uint256 validationData = FishCakeSmartAccount(payable(predictedAddr))
            .validateUserOp(userOp, userOpHash, 0);

        assertEq(validationData, 0, "Validation should pass");
    }
}
