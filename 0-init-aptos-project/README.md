# 快速开始

步骤一：创建 aptos 项目

```bash
aptos move init --name your_project_name
```

步骤二：通过指定的网络·创建 Aptos 私钥

```bash
aptos init --network testnet # testnet / mainnet / devnet
```

Step 3: to edit your `Move.toml` file
步骤三：编辑你的 `Move.toml` 文件

> 在 `.aptos/config.yaml` 中查看你的账户地址，然后在 `Move.toml` 中的 `[address]` 下输入这个地址

例如：

> `create` 这个名称是账户地址的别名，这个名称是自定义的。

```toml
[addresses]
creator="0aa63268ee3a8866da86277747d8254189f5e40d9b93947ed36f27d910cc2005"
```

步骤 4：创建 Move 智能合约，例如 `main.move`

```move
module creator::hello {
    #[test_only]
    use std::string;
    #[test_only]
    use std::debug::print;

    #[test]
    fun test() {
        let hello = string::utf8(b"hello_world");
        print(&hello);
    }
}
```

步骤 4：运行测试

```bash
aptos move test # 默认使用 move v1
# 使用 move-v2
aptos move test --move-2
```

步骤 5：将智能合约编译为二进制文件

```bash
aptos move compile
```

步骤 6：将智能合约部署到 Aptos 区块链

```bash
aptos move publish
```
