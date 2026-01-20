import { ethers } from "ethers";

// 1. 配置参数
const ENTRY_POINT_ADDRESS = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";
const FACTORY_ADDRESS = "你的工厂合约地址";
const PAYMASTER_ADDRESS = "你的Paymaster地址";
const BUNDLER_RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/你的API_KEY"; // 或者是 Stackup 的 URL

async function sendAACompute() {
    const provider = new ethers.JsonRpcProvider(BUNDLER_RPC_URL);
    const ownerWallet = new ethers.Wallet("用户私钥", provider);

    // 2. 预计算智能钱包地址 (调用 Factory 的 getAddress)
    const factory = new ethers.Contract(FACTORY_ADDRESS, ["function getAddress(address,uint256) view returns (address)"], provider);
    const salt = 123;
    const smartAccountAddress = await factory.getAddress(ownerWallet.address, salt);
    console.log("Smart Account Address:", smartAccountAddress);

    // 3. 构造 UserOperation
    // 注意：实际开发中通常使用 SDK (如 userop.js) 自动填充 nonce 和 gas 估算
    const userOp = {
        sender: smartAccountAddress,
        nonce: "0x0", // 需要通过入门点合约查询真实 nonce
        initCode: "0x", // 如果已部署则为 0x
        callData: "0x...", // 你想执行的动作：如 execute(dest, value, func)
        callGasLimit: ethers.toBeHex(100000),
        verificationGasLimit: ethers.toBeHex(500000),
        preVerificationGas: ethers.toBeHex(50000),
        maxFeePerGas: ethers.toBeHex(ethers.parseUnits('10', 'gwei')),
        maxPriorityFeePerGas: ethers.toBeHex(ethers.parseUnits('1', 'gwei')),
        paymasterAndData: PAYMASTER_ADDRESS, // 告知 Bundler 使用 Paymaster
        signature: "0x"
    };

    // 4. 计算 UserOp Hash (与我们在 Solidity 测试中写的逻辑一致)
    const userOpHash = await calculateUserOpHash(userOp, ENTRY_POINT_ADDRESS, 11155111); // 11155111 是 Sepolia ID

    // 5. 签名
    const signature = await ownerWallet.signMessage(ethers.getBytes(userOpHash));
    userOp.signature = signature;

    // 6. 发送给 Bundler
    // ERC-4337 标准 RPC 方法是 eth_sendUserOperation
    const res = await provider.send("eth_sendUserOperation", [userOp, ENTRY_POINT_ADDRESS]);
    console.log("UserOp Hash from Bundler:", res);
}

// 辅助函数：手动计算 UserOp Hash
async function calculateUserOpHash(userOp, entryPoint, chainId) {
    // 按照 ERC-4337 标准对结构体进行打包哈希
    // 建议实际生产环境直接使用 SDK 以免计算偏移报错
}