# 🍰 FishCake - Multi-chain Account Abstraction Wallet

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFC107.svg)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ERC-4337](https://img.shields.io/badge/Standard-ERC--4337-blue)](https://eips.ethereum.org/EIPS/eip-4337)

**FishCake** 是一个基于 **ERC-4337 (Account Abstraction)** 标准构建的下一代智能合约钱包。它通过工厂合约实现确定性地址生成，并配合自定义 Paymaster 实现白名单用户的 **Gas-Free** 交互体验，旨在打破多链资产管理的门槛。



---

## 🌟 核心特性 (Key Features)

- **🚀 零成本上手 (Gasless UX)**：集成自定义 Paymaster，允许项目方为特定用户代付 Gas 费用。
- **🏗️ 确定性部署 (CREATE2)**：无论在哪个链上，用户都能通过相同的 `Owner` 和 `Salt` 获得一致的钱包地址。
- **🔐 安全加固**：
  - 基于 OpenZeppelin 的工业级签名验证。
  - 严格的权限控制，仅限官方 `EntryPoint` 触发敏感操作。
- **⛓️ 多链愿景**：一套逻辑，全链通用。支持所有兼容 EVM 的 L2（Optimism, Arbitrum, Polygon, Sepolia 等）。

---

## 🛠️ 项目架构 (Architecture)

项目采用全栈架构，实现了端到端的 AA 交互：

1.  **Smart Contracts (Foundry)**:
    - `FishCakeSmartAccount.sol`: 核心钱包逻辑，处理 UserOp 验证与签名恢复。
    - `FishCakeFactory.sol`: 利用 `CREATE2` 实现的钱包部署器。
    - `FishCakePaymaster.sol`: 负责支付逻辑，支持链上白名单管理。
2.  **Frontend (React + Ethers.js)**:
    - 预计算智能钱包地址。
    - 构造并签名符合 ERC-4337 标准的 `UserOperation`。
    - 与 Bundler 节点通讯完成交易发送。

---

## 🚀 快速开始 (Quick Start)

### 1. 智能合约开发 (Smart Contracts)

```bash
# 编译合约
forge build

# 运行集成测试 (包含签名验证逻辑)
forge test -vvv
