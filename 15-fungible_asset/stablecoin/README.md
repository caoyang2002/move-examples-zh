# 简介

本模块提供了一个管理稳定币的参考实现，具有以下功能：

1. 可升级的智能合约。该模块可以进行升级，以更新现有功能或添加新功能。
2. 稳定币的铸造和销毁。该模块允许用户铸造和销毁稳定币。铸造者角色需要铸造或销毁。
3. 账户的拒绝列表管理。该模块允许所有者将账户列入拒绝列表（冻结）和取消列入拒绝列表。列入拒绝列表的账户无法转账或继续铸造。
4. 合约的暂停和恢复。所有者可以暂停合约以停止所有的铸造/销毁/转账操作，并且可以恢复合约以恢复这些操作。

# 部署

目前仅在开发网络上可用，因为需要符合 [AIP 73](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-73.md)的要求。

1. 使用 `aptos init --profile devnet` 创建开发网络配置文件（选择 devnet 作为网络）。
2. 要部署，请运行 `aptos move publish --named-addresses stablecoin=devnet,master_minter=devnet,minter=devnet,pauser=devnet,denylister=devnet --profile devnet`。
3. 要铸造稳定币，请运行 `aptos move run --function-id devnet::usdk::mint --args address:0x8115e523937721388acbd77027da45b1c88a6313f99615c4da4c6a32ab161b1a u64:100000000 --profile devnet`。请将 0x8115e523937721388acbd77027da45b1c88a6313f99615c4da4c6a32ab161b1a 替换为接收地址。
4. 或者，您可以访问 https://explorer.aptoslabs.com/account/0x75f3f12f2f634ba33aefda0f2cd29119fdf9caa4fa288ac6e369f54e0611289a/modules/run/usdk/mint?network=devnet 。确保将 0x75f3f12f2f634ba33aefda0f2cd29119fdf9caa4fa288ac6e369f54e0611289a 替换为您的开发网络账户地址。

# 运行测试

```bash
aptos move test
```

# Introduction
This module offers a reference implementation of a managed stablecoin with the following functionalities:
1. Upgradable smart contract. The module can be upgraded to update existing functionalities or add new ones.
2. Minting and burning of stablecoins. The module allows users to mint and burn stablecoins. Minter role is required to mint or burn
3. Denylisting of accounts. The module allows the owner to denylist (freeze) and undenylist accounts.
denylist accounts cannot transfer or get minted more.
4. Pausing and unpausing of the contract. The owner can pause the contract to stop all mint/burn/transfer and unpause it to resume.

# Deployment
Currently only available in devnet due to requirement of AIP 73[https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-73.md].

1. Create a devnet profile with aptos init --profile devnet (select devnet for network)
2. To deploy, run aptos move publish --named-addresses stablecoin=devnet,master_minter=devnet,minter=devnet,pauser=devnet,denylister=devnet --profile devnet
3. To mint, run aptos move run --function-id devnet::usdk::mint --args address:0x8115e523937721388acbd77027da45b1c88a6313f99615c4da4c6a32ab161b1a u64:100000000  --profile devnet
Replace 0x8115e523937721388acbd77027da45b1c88a6313f99615c4da4c6a32ab161b1a with the receiving address
4. Alternatively you can go to https://explorer.aptoslabs.com/account/0x75f3f12f2f634ba33aefda0f2cd29119fdf9caa4fa288ac6e369f54e0611289a/modules/run/usdk/mint?network=devnet
Make sure to replace 0x75f3f12f2f634ba33aefda0f2cd29119fdf9caa4fa288ac6e369f54e0611289a with your devnet account address.

# Running tests
aptos move test
