# 🍰 FishCake - Multi-chain Account Abstraction Wallet

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFC107.svg)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ERC-4337](https://img.shields.io/badge/Standard-ERC--4337-blue)](https://eips.ethereum.org/EIPS/eip-4337)

**FishCake** 是一款基于 **ERC-4337 (Account Abstraction)** 标准构建的全栈多链智能钱包方案。它不仅实现了确定性地址部署（CREATE2），还通过自定义 Paymaster 逻辑，为 DApp 用户提供了极简的“零 Gas”交互体验。

---

## 🏗️ 交互流程 (Workflow)

为了让评委理解 FishCake 的底层工作流，本项目实现了以下闭环：



1. **用户侧 (Frontend)**: 通过 EOA 签名构造 `UserOperation`。
2. **中间层 (Bundler)**: 将 UserOp 打包并提交至 `EntryPoint`。
3. **合约侧 (Smart Account)**: 验证签名并执行业务逻辑。
4. **资助侧 (Paymaster)**: 检查白名单并为符合条件的用户支付 Gas 费用。

---

## 🌟 核心特性 (Key Features)

- **🚀 极致体验 (Gasless UX)**：内置 Paymaster 白名单机制，用户无需持有原生 Token 即可交互。
- **🏗️ 跨链身份一致性 (CREATE2)**：采用统一的 Salt 派生逻辑，确保用户在 Sepolia, Arbitrum, Polygon 等多链拥有相同的合约地址。
- **🔐 模块化安全**：
  - **ECDSA 验证**: 使用 OpenZeppelin 标准库处理 `userOpHash` 验证。
  - **权限控制**: 仅限全局 `EntryPoint (0x5FF1...)` 触发验证逻辑，防止伪造调用。
- **📦 开发者友好**: 提供预计算地址接口，实现“先充值，后部署”的极简流程。

---

## 🛠️ 技术栈 (Tech Stack)

| 层级 | 技术/工具 | 描述 |
| :--- | :--- | :--- |
| **Contracts** | Solidity, Foundry | 核心协议开发与高性能测试 |
| **Frontend** | React, Ethers.js | 用户界面与 UserOp 构建 |
| **AA Infra** | ERC-4337 EntryPoint | 官方统一入口合约 (v0.6) |
| **Libraries** | OpenZeppelin | 工业级加密与权限模块 |

---

## 🚀 快速启动 (Development)

### 1. 合约环境 (Smart Contracts)
```bash
# 1. 安装 Foundry
curl -L [https://sw.foundry.sh](https://sw.foundry.sh) | bash

# 2. 编译并生成 ABI
forge build

# 3. 运行集成测试 (验证签名哈希算法)
forge test -vvv