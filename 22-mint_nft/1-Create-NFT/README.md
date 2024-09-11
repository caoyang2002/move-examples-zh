# 快速开始

## 初始化

```bash
aptos init --network testnet --private-key 0xYourAddress
```

## 测试

```bash
aptos move test
```

## 编译

```bash
 aptos move compile
```

## 发布

```bash
aptos move publish
```

# 详解

## 注释翻译

这个模块是我们 NFT Move 教程的第一部分。在这个模块中，我们将介绍如何创建一个NFT集合和一个NFT代币，并将代币铸造给接收者。

一般来说，有两种类型的NFT：
1. **事件票/证书**：这种 NFT 有一个基础代币，每个从基础代币生成的新NFT都有相同的代币数据ID和图片。它们通常用作证书。从基础代币创建的每个NFT被视为基础代币的一个印刷版本。例如，将这种NFT作为事件票使用：每个NFT都是一张票，并且具有如 `expiration_sec:u64`（过期时间）和 `is_ticket_used:bool`（票是否已使用）等属性。当我们铸造NFT时，可以设置事件票的过期时间，并将 `is_ticket_used` 设置为 `false`。当票被使用时，我们可以将 `is_ticket_used` 更新为 `true`。

2. **Pfp NFT**：这种NFT每个 Token 都有一个独特的 Token 数据 ID 和图片。通常没有这种 NFT 的印刷版本。大多数NFT市场上的NFT收藏品都是这种类型。它们通常是艺术品的所有权证明。

在本教程中，我们将介绍如何创建和铸造事件票NFT。

如何与此模块交互：
1. 创建一个账户。
   ```
   aptos init (这将创建一个默认账户)
   ```

2. 发布模块。
    - 确保您在正确的目录中。
      在目录 `aptos-core/aptos-move/move-examples/mint_nft/1-Create-NFT` 中运行以下命令。
    - 运行以下CLI命令以发布模块。
      ```
      aptos move publish --named-addresses mint_nft=[默认账户的地址]
      ```
      (如果您不知道默认账户的地址，请运行 `nano ~/.aptos/config.yaml` 查看所有地址。)

   示例输出：
   ```
   1-Create-NFT % aptos move publish --named-addresses mint_nft=a911e7374107ad434bbc5369289cf5855c3b1a2938a6bfce0776c1d296271cde
   编译中，可能需要一段时间来下载git依赖...
   包括依赖 AptosFramework
   包括依赖 AptosStdlib
   包括依赖 AptosToken
   包括依赖 MoveStdlib
   构建 Examples
   包大小 2770 字节
   您是否要提交一个交易，范围为 [1164400 - 1746600] Octas，燃料单价为 100 Octas？ [yes/no] >
   yes
   {
     "Result": {
       "transaction_hash": "0x576a2e9481e71b629335b98ea75c87d124e1b435e843e7a2ef8938ae21bebfa3",
       "gas_used": 11679,
       "gas_unit_price": 100,
       "sender": "a911e7374107ad434bbc5369289cf5855c3b1a2938a6bfce0776c1d296271cde",
       "sequence_number": 0,
       "success": true,
       "timestamp_us": 1669659103283876,
       "version": 12735152,
       "vm_status": "Executed successfully"
     }
   }
   ```
    - 检查我们刚刚发布的模块在Aptos Explorer上的状态。
      访问 https://explorer.aptoslabs.com/ 。在屏幕右上角，选择您使用的网络（devnet，testnet等）。通过在搜索框中输入 `transaction_hash` 来搜索此交易。（您需要自己执行上述步骤，并使用您自己唯一的交易哈希进行搜索。）
      我们可以在 `Changes` 标签下查看我们发布模块时所做的更改。

3. 查看下面的 `delayed_mint_event_ticket()` 函数 - 在这一部分中，我们不会运行命令来铸造NFT，因为这个函数现在需要两个签名者，这在使用CLI命令时不切实际。在本教程的下一部分中，我们将介绍一种以编程方式为交易签名的方法，这样模块发布者就不需要手动签名交易，只需一个签名者（NFT接收者的签名者）即可对 `delayed_mint_event_ticket()` 函数进行签名。

## 代码解析

```rust
module mint_nft::create_nft {
    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_token::token;
    use aptos_token::token::TokenDataId;

    // 这个结构体存储了NFT集合的相关信息
    struct ModuleData has key {
        token_data_id: TokenDataId,
    }

    // 权限错误常量，表示签名者不是该模块的管理员
    const ENOT_AUTHORIZED: u64 = 1;

    // `init_module` 在发布模块时会自动调用。
    // 在这个函数中，我们创建了一个示例NFT集合和一个示例代币。
    fun init_module(source_account: &signer) {
        let collection_name = string::utf8(b"Collection name");
        let description = string::utf8(b"Description");
        let collection_uri = string::utf8(b"Collection uri");
        let token_name = string::utf8(b"Token name");
        let token_uri = string::utf8(b"Token uri");
        // 这意味着代币的供应量不会被追踪。
        let maximum_supply = 0;
        // 这个变量设置是否允许对集合描述、URI和最大值进行修改。
        // 这里，我们将它们全部设置为 false，这意味着不允许对任何 CollectionData 字段进行修改。
        let mutate_setting = vector<bool>[ false, false, false ];

        // 创建NFT集合。
        token::create_collection(source_account, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // 创建一个代币数据ID来指定要铸造的代币。
        let token_data_id = token::create_tokendata(
            source_account,
            collection_name,
            token_name,
            string::utf8(b""),
            0,
            token_uri,
            signer::address_of(source_account),
            1,
            0,
            // 这个变量设置是否允许对代币最大值、URI、版权费、描述和属性进行修改。
            // 这里我们通过将向量中的最后一个布尔值设置为 true 来启用对属性的修改。
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            // 我们可以使用属性映射来记录与代币相关的属性。
            // 在这个例子中，我们使用它来记录接收者的地址。
            // 当用户成功铸造代币时，我们将在 `mint_nft()` 函数中修改这个字段以记录用户的地址。
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );

        // 将代币数据ID存储在模块中，以便我们在铸造NFT和更新其属性版本时可以引用它。
        move_to(source_account, ModuleData {
            token_data_id,
        });
    }

    // 将NFT铸造给接收者。请注意，这里我们要求两个账户签名：模块所有者和接收者。
    // 这在生产环境中并不理想，因为我们不希望手动签署每个交易。
    // 一般来说，这也是不切实际/低效的，因为我们要么需要自己实现延迟执行，要么需要同时拥有两个签名。
    // 在本教程的第2部分中，我们将介绍“资源账户”的概念 - 这是一个由智能合约控制的账户，可以自动签署交易。
    // 资源账户在一般区块链术语中也称为 PDA 或智能合约账户。
    public entry fun delayed_mint_event_ticket(module_owner: &signer, receiver: &signer) acquires ModuleData {
        // 断言模块所有者签名者是该模块的所有者。
        assert!(signer::address_of(module_owner) == @mint_nft, error::permission_denied(ENOT_AUTHORIZED));

        // 将代币铸造给接收者。
        let module_data = borrow_global_mut<ModuleData>(@mint_nft);
        let token_id = token::mint_token(module_owner, module_data.token_data_id, 1);
        token::direct_transfer(module_owner, receiver, token_id, 1);

        // 修改代币属性以更新此代币的属性版本。
        // 请注意，这里我们重用相同的代币数据ID，并且仅更新属性版本。
        // 这是因为我们只是印刷相同代币的版本，而不是创建具有唯一名称和代币URI的代币。
        // 通过这种方式创建的代币将具有相同的代币数据ID，但具有不同的属性版本。
        let (creator_address, collection,