# 概述

通过多重签名账户管理币的创建和初始化过程

- 此模块演示了如何在Move语言中通过多重签名账户（`multisig_account`）来管理币的创建和操作。
- 使用了 `object` 模块来处理对象的创建和转移。
- 最后，通过 `managed_fungible_asset` 模块来初始化和管理可替代资产，确保其符合指定的多重签名要求和参数设置。

# 快速开始

```bash
aptos move test 
```

# 详解

1. **模块引用和导入**:
   ```move
   use aptos_framework::multisig_account;
   use aptos_framework::object;
   use aptos_framework::object::ObjectCore;
   use std::signer;
   use std::string::{Self, String};
   use example_addr::managed_fungible_asset;
   ```
    - `multisig_account` 和 `object` 是从 `aptos_framework` 库导入的模块，用于多重签名账户和对象相关的功能。
    - `signer` 和 `String` 是从标准库导入的，用于处理签名者和字符串操作。
    - `managed_fungible_asset` 是从 `example_addr` 中导入的模块，用于管理可替代资产的功能。

2. **函数定义**:
   ```move
   public entry fun initialize(
       creator: &signer,
       additional_owners: vector<address>,
       num_signature_required: u64,
       metadata_keys: vector<String>,
       metadata_values: vector<vector<u8>>,
       maximum_supply: u128,
       name: String,
       symbol: String,
       decimals: u8,
       icon_uri: String,
       project_uri: String,
       ref_flags: vector<bool>,
   )
   ```
    - `initialize` 函数是一个公共入口函数（`entry`），用于初始化多重签名账户和管理的可替代资产。
    - **参数**:
        - `creator`: 创建者的签名者引用。
        - `additional_owners`: 其他所有者的地址向量，用于创建多重签名账户。
        - `num_signature_required`: 需要的签名数，用于通过多重签名账户执行操作。
        - `metadata_keys` 和 `metadata_values`: 元数据的键和值向量，用于创建资产的元数据。
        - `maximum_supply`: 最大供应量，如果为 `0` 则表示没有最大限制。
        - `name` 和 `symbol`: 资产的名称和符号。
        - `decimals`: 小数位数，用于资产的显示和计算。
        - `icon_uri` 和 `project_uri`: 资产图标和项目链接的 URI。
        - `ref_flags`: 包含布尔值的向量，指定是否允许铸造、转移和销毁资产。

3. **函数实现**:
   ```move
   let multisig_address = multisig_account::get_next_multisig_account_address(signer::address_of(creator));
   // Customize those arguments as needed.
   multisig_account::create_with_owners(
       creator,
       additional_owners,
       num_signature_required,
       metadata_keys,
       metadata_values
   );
   ```
    - `multisig_address` 获取下一个多重签名账户的地址，根据创建者的地址计算。
    - `multisig_account::create_with_owners` 创建一个具有指定所有者的多重签名账户，参数根据函数的输入参数提供。

   ```move
   let constructor_ref = &object::create_named_object(creator, *string::bytes(&symbol));
   object::transfer(creator, object::object_from_constructor_ref<ObjectCore>(constructor_ref), multisig_address);
   ```
    - `constructor_ref` 创建一个命名对象的引用，用于后续的资产管理。
    - `object::transfer` 将创建的对象转移到多重签名账户的地址，确保资产的管理受到多重签名机制的保护。

   ```move
   managed_fungible_asset::initialize(
       constructor_ref,
       maximum_supply,
       name,
       symbol,
       decimals,
       icon_uri,
       project_uri,
       ref_flags
   );
   ```
    - `managed_fungible_asset::initialize` 使用先前创建的对象引用和提供的参数，初始化管理的可替代资产。


## 中文注释

```move
module example_addr::multisig_managed_coin {
    use aptos_framework::multisig_account;
    use aptos_framework::object;
    use aptos_framework::object::ObjectCore;
    use std::signer;
    use std::string::{Self, String};
    use example_addr::managed_fungible_asset;

    // 公共入口函数，用于初始化多重签名账户管理的可替代币
    public entry fun initialize(
        creator: &signer,                        // 创建者的签名者引用
        additional_owners: vector<address>,      // 其他所有者的地址向量
        num_signature_required: u64,             // 需要的签名数
        metadata_keys: vector<String>,           // 元数据的键向量
        metadata_values: vector<vector<u8>>,     // 元数据的值向量
        maximum_supply: u128,                    // 最大供应量
        name: String,                            // 币的名称
        symbol: String,                          // 币的符号
        decimals: u8,                            // 小数位数
        icon_uri: String,                        // 图标 URI
        project_uri: String,                     // 项目链接 URI
        ref_flags: vector<bool>,                 // 参考标志向量（用于铸造、转移、销毁等）
    ) {
        // 获取下一个多重签名账户的地址
        let multisig_address = multisig_account::get_next_multisig_account_address(signer::address_of(creator));

        // 根据提供的参数创建多重签名账户
        multisig_account::create_with_owners(
            creator,
            additional_owners,
            num_signature_required,
            metadata_keys,
            metadata_values
        );

        // 创建命名对象的引用，用于后续的资产管理
        let constructor_ref = &object::create_named_object(creator, *string::bytes(&symbol));

        // 将创建的对象转移到多重签名账户的地址，以确保资产受多重签名机制保护
        object::transfer(creator, object::object_from_constructor_ref<ObjectCore>(constructor_ref), multisig_address);

        // 初始化管理的可替代资产，使用提供的参数
        managed_fungible_asset::initialize(
            constructor_ref,
            maximum_supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
            ref_flags
        );
    }
}
```
  