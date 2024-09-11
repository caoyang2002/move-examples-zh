# 有错误

# 快速开始

```bash
aptos move test
```

# 解析

这段代码是 Move 语言的一个模块，它是关于 NFT（非同质化代币）的 Move 教程的最后一部分。在这个部分中，我们完善了智能合约，使其准备好投入生产。具体来说，我们将：

- 添加一个 `TokenMintingEvent`，以便我们可以发出一个自定义事件，追踪从这个模块铸造的代币；
- 引入证明挑战的概念，以及如何使用它来防止机器人垃圾信息；
- 添加单元测试，确保我们的代码按预期工作。

### 概念：签名验证

我们出于多种原因使用签名验证。例如，在 `aptos_framework::account::rotate_authentication_key()` 中，我们要求用户提供两个签名，证明他们有意并且有能力旋转账户的认证密钥。

在这个教程中，我们出于不同的原因使用它：我们希望确保只有来自我们认证的后端的 `mint_event_ticket()` 请求被处理。因为我们正在验证签名是否与指定的公钥匹配，只有来自具有相应私钥的后端的请求才能铸造 NFT。所有其他请求将因 `EINVALID_PROOF_KNOWLEDGE` 而失败。这确保了一个人不能通过向这个智能合约发送垃圾信息来滥用并大量铸造 NFT，因为他们没有通过签名验证步骤。

### 概念：事件
事件在交易执行期间被发出。每个 Move 模块可以定义自己的事件，并选择在模块执行时何时发出事件。在这个模块中，我们添加了一个自定义的 `TokenMintingEvent` 来追踪铸造的 token_data_id 和 token 接收者的地址。
有关事件的更多信息，请访问：https://aptos.dev/concepts/events/。

### Move 单元测试
我们添加了一些单元测试，以确保我们的代码按预期工作。有关如何编写 Move 单元测试的更多信息，请访问：https://aptos.dev/move/book/unit-testing。

### 如何与这个模块交互
1. 在 Move.toml 文件中配置管理员账户名地址。
   转到 `Move.toml` 并将 `admin_addr = "0xbeef"` 替换为我们在第三部分创建的管理员地址。

2. 在资源账户下发布模块。
    - 2.a 确保你在正确的目录中。
      在目录 `aptos-core/aptos-move/move-examples/mint_nft/4-Getting-Production-Ready` 中运行以下命令。
    - 2.b 运行以下 CLI 命令在资源账户下发布模块。
   ```
   aptos move create-resource-account-and-publish-package --seed [seed] --address-name mint_nft --profile default --named-addresses source_addr=[default account's address]
   ```

3. 使用有效签名调用 `mint_event_ticket()` 来铸造代币。
    - 3.a 生成一对密钥来验证签名。
   ```
   aptos key generate --key-type ed25519 --output-file output.key
   ```
    - 3.b 更新 `ModuleData` 中存储的公钥。
   ```
   aptos move run --function-id [resource account's address]::create_nft_getting_production_ready::set_public_key --args hex:[public key we just generated] --profile admin
   ```
   （要找到我们刚刚生成的公钥，请运行 `nano output.key.pub`。）
   示例输出：
   ```
   4-Getting-Production-Ready % aptos move run --function-id f634035fea40e23c5ed8817f7e996d96372dd5dbd64e853fb3c108817d92dcb4::create_nft_getting_production_ready::set_public_key --args hex:5C0637A3865FCA80550502BC30C8E7B4CCA7C8AB3B4FFECEFC8C43F7D0D44DEE --profile admin
   是否希望提交一个交易范围 [35200 - 52800] Octas 在每个 gas 单位价格为 100 Octas？[yes/no] >
   yes
   {
     "Result": {
       "transaction_hash": "0xd4ee713cca364dabd544d5f66252ceaa0b3ef3f0449209900495bffecd27926a",
       "gas_used": 352,
       "gas_unit_price": 100,
       "sender": "f42bcdc1fb9b8d4c0ac9e54568a53c8515d3d9afd7936484a923b0d7854e134f",
       "sequence_number": 1,
       "success": true,
       "timestamp_us": 1669672770777276,
       "version": 13023905,
       "vm_status": "Executed successfully"
     }
   }
   ```
    - 3.c 生成有效的签名。
      打开文件 `aptos-core/aptos-move/e2e-move-tests/src/tests/mint_nft.rs`。
      在函数 `generate_nft_tutorial_part4_signature` 中，将 `resource_address`、`nft_receiver`、`admin_private_key` 和 `receiver_account_sequence_number` 变量更改为实际值。
      你可以通过运行 `nano output.key` 找到 `admin_private_key`，通过在 Aptos Explorer 的 `Info` 标签下查找接收者的地址来找到 `receiver_account_sequence_number`。
      确保你在正确的目录中。
      在目录 `aptos-core/aptos-move/e2e-move-tests` 中运行以下命令。
   ```
   Run `cargo test generate_nft_tutorial_part4_signature -- --nocapture` 来生成我们将在下一步使用的有效的签名。
   ```
    - 3.d 使用我们在上一步生成的签名调用 `mint_event_ticket()`。
   ```
   aptos move run --function-id [resource account's address]::create_nft_getting_production_ready::mint_event_ticket --args hex:[signature generated in last step] --profile nft-receiver
   ```
   示例输出：
   ```
   4-Getting-Production-Ready % aptos move run --function-id f634035fea40e23c5ed8817f7e996d96372dd5dbd64e853fb3c108817d92dcb4::create_nft_getting_production_ready::mint_event_ticket --args hex:fc833512ad1c575850569d14f5e434b929a19eb491c08df9f6b91584a13551bdb95830081a429f148fddcb9ba201cf72a357957849046da0d60675ed034f580 --profile nft-receiver
   是否希望提交一个交易范围 [600800 - 901200] Octas 在每个 gas 单位价格为 100 Octas？[yes/no] >
   yes
   {
     "Result": {
       "transaction_hash": "0x2cbc5f7444c381476bb69bfb40bb8f396875c0121d97b75e7b9b156ebef15f84",
       "gas_used": 6073,
       "gas_unit_price": 100,
       "sender": "7d69283af198b1265d17a305ff0cca6da1bcee64d499ce5b35b659098b3a82dc",
       "sequence_number": 4,
       "success": true,
       "timestamp_us": 1669673918958986,
       "version": 13046985,
       "vm_status": "Executed successfully"
     }
   }
   ```
   ///
   /// 这是本 NFT 教程的结束！恭喜你坚持到最后。如果你有任何问题/反馈，请通过在 GitHub 上提出 issue/功能请求告诉我们 : )
   module mint_nft::create_nft_getting_production_ready {
   use std::error;
   use std::signer;
   use std::string::{Self, String};
   use std::vector;
   use aptos_framework::account;
   use aptos_framework::event;
   use aptos_framework::timestamp;
   use aptos_std::ed25519;
   use aptos_token::token::{Self, TokenDataId};
   use aptos_framework::resource_account;
   #[test_only]
   use aptos_framework::account::create_account_for_test;
   use aptos_std::ed25519::ValidatedPublicKey;

   #[event]
   // 这个结构体在铸造代币事件中存储 token 接收者的地址和 token_data_id
   struct TokenMinting has drop, store {
   token_receiver_address: address,
   token_data_id: TokenDataId,
   }

   // 这个结构体存储了 NFT 集合的相关信
···