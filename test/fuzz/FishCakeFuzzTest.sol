// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/FishCakeFactory.sol";
import "../../src/FishCakeSmartAccount.sol";

contract FishCakeFuzzTest is Test {
    FishCakeFactory public factory;

    function setUp() public {
        // 1. 部署工厂合约
        factory = new FishCakeFactory();
    }

    /**
     * @notice 模糊测试：验证预计算地址与实际部署地址的绝对一致性
     * @param _owner 随机生成的地址
     * @param _salt 随机生成的盐值
     */
    function testFuzz_AddressConsistency(address _owner, uint256 _salt) public {
        // 排除地址为 0 的极端情况（虽然实际上可行，但通常 initialize 会限制）
        vm.assume(_owner != address(0));

        // 1. 获取预计算地址
        address predictedAddress = factory.getAddress(_owner, _salt);

        // 2. 执行实际部署
        address deployedAddress = factory.deployAccount(_owner, _salt);

        // 3. 断言：两者必须完全相等
        assertEq(
            predictedAddress,
            deployedAddress,
            "Predicted address should match actual deployed address"
        );

        // 4. 验证初始化状态
        FishCakeSmartAccount account = FishCakeSmartAccount(
            payable(deployedAddress)
        );
        assertEq(
            account.owner(),
            _owner,
            "Account owner should be the randomized owner"
        );
    }

    /**
     * @notice 模糊测试：验证部署冲突处理（同一 owner 和 salt 不能重复部署）
     */
    function testFuzz_RevertOnDuplicateDeployment(
        address _owner,
        uint256 _salt
    ) public {
        vm.assume(_owner != address(0));

        // 第一次部署
        factory.deployAccount(_owner, _salt);

        // 第二次尝试部署相同的地址应该 revert (CREATE2 限制)
        vm.expectRevert();
        factory.deployAccount(_owner, _salt);
    }
}
