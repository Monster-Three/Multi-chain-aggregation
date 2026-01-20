import React, { useState } from 'react';
import { FishCakeHelper } from './utils/aa-helper';

function App() {
    const [smartAddr, setSmartAddr] = useState("");

    const handlePredictAddress = async () => {
        const owner = "0x..."; // 用户的 EOA 地址 (来自 MetaMask)
        const salt = 123;
        const addr = await FishCakeHelper.getSmartAccountAddress(owner, salt);
        setSmartAddr(addr);
    };

    return (
        <div>
            <h1>FishCake 智能钱包控制台</h1>
            <button onClick={handlePredictAddress}>预计算我的钱包地址</button>
            {smartAddr && <p>你的钱包地址将是: {smartAddr}</p>}
        </div>
    );
}

export default App;