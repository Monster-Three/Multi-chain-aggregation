// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev 必须定义 UserOperation 结构体，否则编译器无法识别该类型
 */
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

// ERC-4337 定义的 Paymaster 接口
interface IPaymaster {
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);
}

contract FishCakePaymaster is IPaymaster, Ownable {
    address public constant ENTRY_POINT =
        0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    mapping(address => bool) public isWhitelisted;

    constructor() Ownable(msg.sender) {}

    function setWhitelist(address _user, bool _status) external onlyOwner {
        isWhitelisted[_user] = _status;
    }

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /* userOpHash */, // 去掉变量名，保留类型
        uint256 /* maxCost */ // 也可以用注释标记原名，方便阅读
    )
        external
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        require(msg.sender == ENTRY_POINT, "Only EntryPoint");

        // 仅使用了 userOp.sender，所以 userOp 的名字必须保留
        if (isWhitelisted[userOp.sender]) {
            return ("", 0);
        }
        return ("", 1);
    }

    function deposit() external payable {
        (bool success, ) = ENTRY_POINT.call{value: msg.value}(
            abi.encodeWithSignature("depositTo(address)", address(this))
        );
        require(success, "Deposit failed");
    }
}
