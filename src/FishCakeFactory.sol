// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FishCakeSmartAccount} from "./FishCakeSmartAccount.sol";

/**
 * @title FishCakeFactory
 * @dev 利用 CREATE2 实现多链地址一致性
 */

//我们利用了 CREATE2 实现了全链身份统一，用户完全不需要感知链的差异。
contract FishCakeFactory {
    event AccountDeployed(
        address indexed account,
        address indexed owner,
        uint256 salt
    );

    /**
     * @dev 部署合约
     * @param _owner 用户（通常是其 EOA 地址或 Passkey 关联地址）
     * @param _salt 随机盐值，同一用户在不同链使用相同的 salt 即可获得相同地址
     */
    function deployAccount(
        address _owner,
        uint256 _salt
    ) external returns (address) {
        // 1. 生成初始化代码的哈希
        bytes memory bytecode = type(FishCakeSmartAccount).creationCode;

        // 2. 使用 create2 部署
        address addr;
        // 将owner纳入salt，以防止抢跑（Front-run）风险
        bytes32 finalSalt = keccak256(abi.encodePacked(_owner, _salt));

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), finalSalt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        // 3. 初始化账户所有权
        FishCakeSmartAccount(payable(addr)).initialize(_owner);

        emit AccountDeployed(addr, _owner, _salt);
        return addr;
    }

    /**
     * @dev 离线预计算地址 (前端非常需要这个功能)
     * @param _salt 传入与部署时相同的 salt
     */
    function getAddress(
        address _owner,
        uint256 _salt
    ) public view returns (address) {
        // 1. 将 owner 和用户传入的随机 salt 混合，生成一个最终的 salt
        // 这样即便不同用户传入相同的 _salt，最终的 finalSalt 也会因为 owner 不同而不同
        bytes32 finalSalt = keccak256(abi.encodePacked(_owner, _salt));

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this), // 必须是 factory 地址
                finalSalt, // 使用混合后的 salt
                keccak256(type(FishCakeSmartAccount).creationCode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}
