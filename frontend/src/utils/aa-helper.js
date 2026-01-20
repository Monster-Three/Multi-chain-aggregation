import { ethers } from "ethers";
import { FACTORY_ADDRESS, FACTORY_ABI, ACCOUNT_ABI } from "../constants";

/**
 * 助手类：处理 FishCake 智能钱包逻辑
 */
export const FishCakeHelper = {
    
    // 1. 获取 Provider (连接到 Bundler 或节点)
    getProvider: () => {
        const rpcUrl = process.env.REACT_APP_RPC_URL; 
        return new ethers.JsonRpcProvider(rpcUrl);
    },

    // 2. 预计算智能钱包地址
    getSmartAccountAddress: async (ownerAddress, salt) => {
        const provider = FishCakeHelper.getProvider();
        const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);
        try {
            const address = await factory.getAddress(ownerAddress, salt);
            return address;
        } catch (error) {
            console.error("计算地址失败:", error);
            throw error;
        }
    },

    // 3. 构建转账的 CallData
    // 假设你想让智能钱包转账给某个目标地址
    encodeExecuteData: (dest, value, data) => {
        const iface = new ethers.Interface(ACCOUNT_ABI);
        return iface.encodeFunctionData("execute", [dest, value, data]);
    },

    // 4. 计算 UserOp Hash (简化版原理演示)
    // 提示：生产环境强烈建议使用 userop.js 等库自动完成
    calculateUserOpHash: (userOp, entryPoint, chainId) => {
        // 这里需要严格按照 ERC-4337 的 abi.encode 逻辑
        // 初学者建议先掌握简单的合约读取，UserOp 签名建议配合 SDK
        console.log("正在为 EntryPoint:", entryPoint, "计算哈希...");
        return ethers.keccak256(ethers.toUtf8Bytes("demo-hash")); 
    }
};