export const FACTORY_ADDRESS = "0x..."; // 部署后的 Factory 地址
export const PAYMASTER_ADDRESS = "0x..."; // 部署后的 Paymaster 地址
export const ENTRY_POINT_ADDRESS = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";

// 从编译后的 JSON 中拷贝出的 ABI
export const FACTORY_ABI = [
    "function getAddress(address owner, uint256 salt) view returns (address)",
    "function deployAccount(address owner, uint256 salt) external returns (address)"
];

export const ACCOUNT_ABI = [
    "function execute(address dest, uint256 value, bytes func) external",
    "function owner() view returns (address)"
];