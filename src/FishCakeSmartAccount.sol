// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// ERC-4337 核心接口
interface IAccount {
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);
}

// UserOperation 结构体定义
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

contract FishCakeSmartAccount is Initializable, IAccount {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public owner;
    address public constant ENTRY_POINT =
        0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789; // 官方 EntryPoint 地址

    modifier onlyEntryPoint() {
        require(msg.sender == ENTRY_POINT, "Only EntryPoint can call");
        _;
    }

    function initialize(address _owner) external initializer {
        owner = _owner;
    }

    // 实现 ERC-4337 核心验证逻辑
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override onlyEntryPoint returns (uint256 validationData) {
        // 1. 验证签名是否来自 owner
        address signer = userOpHash.toEthSignedMessageHash().recover(
            userOp.signature
        );
        if (owner != signer) {
            return 1; // 验证失败（SIG_VALIDATION_FAILED）
        }

        // 2. 支付缺少的 Gas 费用给 EntryPoint
        if (missingAccountFunds > 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds
            }("");
            require(success, "Transfer to EntryPoint failed");
        }

        return 0; // 验证成功
    }

    // 处理实际业务逻辑的函数
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external onlyEntryPoint {
        (bool success, ) = dest.call{value: value}(func);
        require(success, "Execution failed");
    }

    receive() external payable {}
}
