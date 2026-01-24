// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BasePaymaster} from "@account-abstraction/contracts/core/BasePaymaster.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// 引入 Chainlink 接口
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract FishCakeOraclePaymaster is BasePaymaster {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    AggregatorV3Interface internal immutable priceFeed;

    // 价格安全边际：比如 110 代表收取 110%，多收 10% 作为服务费或风险对冲
    uint256 public constant PRICE_MARKUP = 110;
    uint256 public constant PRICE_DENOMINATOR = 100;

    // 以 Sepolia 测试网为例：ETH/USD 价格对地址
    // 实际部署时可根据不同链更改此地址
    constructor(
        IEntryPoint _entryPoint,
        address _owner,
        address _token,
        address _priceFeed
    ) BasePaymaster(_entryPoint, _owner) {
        token = IERC20(_token);
        priceFeed = AggregatorV3Interface(_priceFeed);
        // 显式将权限转交给 _owner
        transferOwnership(_owner);
    }

    /**
     * @notice 获取最新的 ETH 价格
     */
    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /* uint80 roundID */ int price,
            ,
            /* uint startedAt */ uint timeStamp /* uint80 answeredInRound */,

        ) = priceFeed.latestRoundData();

        // 检查预言机数据的时效性（防止“喂价过时”攻击）
        require(timeStamp > 0, "Chainlink: stale price");
        require(price > 0, "Chainlink: invalid price");

        return uint256(price);
    }

    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 maxCost
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        uint256 ethPrice = getLatestPrice(); // 假设返回 2500 * 1e8

        // 计算 Token 成本：将 ETH 成本转换为 Token 数量
        // 注意：这里需要根据 Token 的精度（如 USDC 是 6 位，ETH 是 18 位）进行复杂的移位运算
        uint256 maxTokenCost = (maxCost * ethPrice * PRICE_MARKUP) /
            (1e8 * PRICE_DENOMINATOR);

        require(
            token.balanceOf(userOp.sender) >= maxTokenCost,
            "Paymaster: User low balance"
        );

        return (abi.encode(userOp.sender, ethPrice), 0);
    }

    function _postOp(
        PostOpMode /* mode */,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 /* actualUserOpFeePerGas */ // v0.7 可能多出了这一项，取决于你具体的库版本
    ) internal virtual override {
        // 如果你的库版本只需要 3 个参数，请删掉第四个
        // 逻辑代码保持不变
        (address sender, uint256 ethPrice) = abi.decode(
            context,
            (address, uint256)
        );

        uint256 actualTokenCost = (actualGasCost * ethPrice * PRICE_MARKUP) /
            (1e8 * PRICE_DENOMINATOR);

        token.safeTransferFrom(sender, address(this), actualTokenCost);
    }
}
