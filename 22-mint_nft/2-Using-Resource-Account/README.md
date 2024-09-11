# 快速开始
```bash
aptos move test
```

# 解析

```move
/// 这个模块是我们NFT Move教程的第二部分，建立在第一部分的基础上。在本部分教程中，我们引入了资源账户的概念，并在之前的教程之上添加了一个资源账户。
///
/// 概念：资源账户
/// 资源账户是开发人员用于独立于用户管理的账户管理资源的特性，特别是用于发布模块和自动签署交易。
/// 在这个模块中，我们使用资源账户来发布这个模块，并为代币铸造和转账交易程序化签署。
///
/// 如何与这个模块交互：
/// 1. 创建一个nft-receiver账户（除了我们在上一部分创建的源账户之外）。我们将在本教程中使用这个账户接收NFT。
/// aptos init --profile nft-receiver
///
/// 2. 在资源账户下发布模块。
/// - 2.a 确保你在正确的目录中。
/// 在目录 `aptos-core/aptos-move/move-examples/mint_nft/2-Using-Resource-Account` 中运行以下命令
/// - 2.b 运行以下CLI命令在资源账户下发布模块。
/// aptos move create-resource-account-and-publish-package --seed [seed] --address-name mint_nft --profile default --named-addresses source_addr=[default account's address]
///
/// 示例输出：
    /*
    2-Using-Resource-Account % aptos move create-resource-account-and-publish-package --seed 1235 --address-name mint_nft --profile default --named-addresses source_addr=a911e7374107ad434bbc5369289cf5855c3b1a2938a6bfce0776c1d296271cde
    编译中，下载git依赖可能需要一点时间...
    INCLUDING DEPENDENCY AptosFramework
    INCLUDING DEPENDENCY AptosStdlib
    INCLUDING DEPENDENCY AptosToken
    INCLUDING DEPENDENCY MoveStdlib
    BUILDING Examples
    是否希望在资源账户的地址 3ad2cce668ed2186da580b95796ffe8534566583363cd3b03547bec9542662dc 下发布此包？[yes/no] >
    yes
    包大小 2928 字节
    是否希望提交一个交易范围 [1371100 - 2056600] Octas 在每个gas单位价格为 100 Octas？[yes/no] >
    yes
    {
      "Result": "Success"
    }
    */
///
/// 3. 查看我们新添加的关于资源账户的代码。
/// - 3.a 在 2.b 中，我们使用CLI命令 `create-resource-account-and-publish-package` 在资源账户的地址下发布了这个模块。
/// 在资源账户下发布模块意味着我们将无法更新该模块，模块将是不可变的和自治的。
/// 这带来了一个挑战：
/// 如果我们想要更新这个模块的配置怎么办？在本教程的下一部分，我们将介绍如何添加一个管理员账户和管理员函数
/// 来更新这个模块的配置，而不影响使用资源账户所带来的自动性和免疫力。
/// - 3.b 在 `init_module` 中，我们将资源账户的签名能力存储在 `ModuleData` 中以供后续使用。
/// - 3.c 在 `mint_event_ticket` 中，我们通过调用 `account::create_signer_with_capability(&module_data.signer_cap)` 创建一个资源签名者，以程序化签署 `token::mint_token()` 和 `token::direct_transfer()` 函数。
/// 如果我们没有为这个模块使用资源账户，我们将需要手动签署那些交易。
///
/// 4. 向nft-receiver账户铸造一个NFT
/// - 4.a 运行以下命令
/// aptos move run --function-id [resource account's address]::create_nft_with_resource_account::mint_event_ticket --profile nft-receiver
///
/// 示例输出：
    /*
    2-Using-Resource-Account % aptos move run --function-id 55328567ff8aa7d242951af7fc1872746fbeeb89dfed0e1ee2ff71b9bf4469d6::create_nft_with_resource_account::mint_event_ticket --profile nft-receiver
    是否希望提交一个交易范围 [502900 - 754300] Octas 在每个gas单位价格为 100 Octas？[yes/no] >
    yes
    {
      "Result": {
        "transaction_hash": "0x720c06eafe77ff385dffcf31c6217839aab3185b65972d6900adbcc3838a4425",
        "gas_used": 5029,
        "gas_unit_price": 100,
        "sender": "7d69283af198b1265d17a305ff0cca6da1bcee64d499ce5b35b659098b3a82dc",
        "sequence_number": 1,
        "success": true,
        "timestamp_us": 1669662022240704,
        "version": 12784585,
        "vm_status": "Executed successfully"
      }
    }
    */
/// - 4.b 通过在 https://explorer.aptoslabs.com/ 上搜索交易哈希值来查看交易。
module mint_nft::create_nft_with_resource_account {
    use std::string;
    use std::vector;

    use aptos_token::token;
    use std::signer;
    use std::string::String;
    use aptos_token::token::TokenDataId;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::resource_account;
    use aptos_framework::account;

    // 这个结构体存储了NFT集合的相关信
```