# 📑 FishCake Project Design Document

## 1. 项目愿景 (Executive Summary)

* **一句话描述**：FishCake 是一个基于 ERC-4337 v0.7.0 的多链智能账户系统，通过预言机实现自动化的 Gas 结算。
* **解决的痛点**：解决了用户在多链环境下地址不统一、以及“有代币无 Gas”无法发起交易的困境。

## 2. 问题陈述 (Problem Statement)

* **多链复杂性**：用户在不同链上地址不同，管理极其困难。
* **Gas 门槛**：新用户持有 USDC 等代币却因缺乏原生代币（如 ETH）而无法操作。
* **协议可持续性**：现有的代服（Sponsoring）模式依赖开发者持续注资，缺乏商业闭环。

## 3. 系统架构 (System Architecture)

### 3.1 核心组件

* **FishCakeFactory**: 利用 `CREATE2` 实现的确定性部署合约。
* **FishCakeSmartAccount**: 支持多种验签逻辑的模块化钱包。
* **FishCakeOraclePaymaster**: 核心盈利组件，负责代币结算与汇率换算。

### 3.2 业务流 (Workflow)

1. **用户发起**：用户签署一个 `PackedUserOperation`。
2. **验证阶段**：Paymaster 调用 Chainlink 预言机锁定汇率并检查用户代币余额。
3. **执行阶段**：EntryPoint 执行业务逻辑。
4. **结算阶段**：`postOp` 钩子根据实际 Gas 消耗扣除用户代币。

## 4. 技术实现细节 (Technical Implementation)

### 4.1 跨链一致性算法

我们通过以下公式确保地址在全链一致：

$$Address = hash(0xFF, deployer, salt, hash(bytecode))$$

### 4.2 动态汇率结算逻辑

Paymaster 结算公式采用了精密的精度对齐处理：

$$ActualTokenCost = \frac{ActualGasCost \times ETHPrice \times Markup}{10^{price\_decimals} \times 100}$$

*注： 由 Chainlink AggregatorV3 提供。*

### 4.3 ERC-4337 v0.7.0 适配

* **数据压缩**：使用 `PackedUserOperation` 结构，显著优化链上存储。
* **Gas 计费优化**：在 `_postOp` 中利用 `actualUserOpFeePerGas` 实现毫秒级的精准计费。

## 5. 安全与风险控制 (Security & Risk Management)

* **预言机卫士**：实现了时效性检查（Stale Price Check），超过预设时间的喂价将被拒绝。
* **权限分层**：管理权限（Owner）与协议权限（EntryPoint）严格分离，防止单点故障。
* **资金隔离**：用户代币通过 `safeTransferFrom` 划转，且 Paymaster 仅能扣除已授权的金额。

## 6. 创新点说明 (Innovation & Uniqueness)

* **标准前瞻性**：率先适配了 2024 年底发布的 v0.7.0 官方标准，而非市面上常见的 v0.6 教学代码。
* **商业闭环**：通过 10% 的 Markup 机制，使 Paymaster 从“烧钱工具”变为“盈利协议”。