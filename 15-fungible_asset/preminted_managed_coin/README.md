# 概述

这段代码展示了如何在 Move 语言中创建和初始化一个预铸币，并进行相关的测试。主要涉及到了创建命名对象、初始化可替代资产、铸造预定义的总供应量以及测试预期的行为。

# 快速开始

```bash
aptos move test 
```

# 详解
这段代码是一个 Move 语言的模块，用于创建一个预铸币的示例，该币种只具有转移和销毁的管理能力。以下是对代码的逐行解析：

1. **模块声明和导入**：
   ```move
   module example_addr::preminted_managed_coin {
       use aptos_framework::fungible_asset::{Self, Metadata};
       use aptos_framework::object::{Self, Object};
       use aptos_framework::primary_fungible_store;
       use example_addr::managed_fungible_asset;
       use std::signer;
       use std::string::utf8;
   ```
    - `module example_addr::preminted_managed_coin { ... }`：声明一个 Move 模块，命名为 `preminted_managed_coin`，位于 `example_addr` 命名空间下。
    - `use` 语句导入了所需的库和模块，包括 fungible_asset 模块的 `Self` 和 `Metadata`，object 模块的 `Self` 和 `Object`，primary_fungible_store 模块，managed_fungible_asset 模块，以及标准库中的 `signer` 和 `utf8`。

2. **常量声明**：
   ```move
   const ASSET_SYMBOL: vector<u8> = b"MEME";                    // 资产符号
   const PRE_MINTED_TOTAL_SUPPLY: u64 = 10000;                  // 预铸的总供应量
   ```
    - `ASSET_SYMBOL` 定义了币种的符号，类型为 `vector<u8>`，存储的是字节数组 `b"MEME"`。
    - `PRE_MINTED_TOTAL_SUPPLY` 定义了预铸的总供应量，类型为 `u64`，值为 `10000`。

3. **初始化函数 `init_module`**：
   ```move
   /// Initialize metadata object and store the refs.
   fun init_module(admin: &signer) {
       // 创建命名对象的引用
       let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
       
       // 初始化管理的可替代资产
       managed_fungible_asset::initialize(
           constructor_ref,
           1000000000,                                             // 最大供应量
           utf8(b"preminted coin"),                                // 名称
           utf8(ASSET_SYMBOL),                                     // 符号
           8,                                                      // 小数位数
           utf8(b"http://example.com/favicon.ico"),                // 图标 URI
           utf8(b"http://example.com"),                            // 项目链接 URI
           vector[false, true, true],                               // 参考标志向量（铸造、转移、销毁）
       );

       // 创建铸造引用，将预铸的可替代资产的固定供应量铸造到特定账户。
       // 此账户可以是任何账户，包括普通用户账户、资源账户、多重签名账户等。
       // 这里仅使用创建者账户作为概念验证的例子。
       let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
       let admin_primary_store = primary_fungible_store::ensure_primary_store_exists(
           signer::address_of(admin),
           get_metadata()
       );
       fungible_asset::mint_to(&mint_ref, admin_primary_store, PRE_MINTED_TOTAL_SUPPLY);
   }
   ```
    - `init_module` 函数用于初始化模块，创建并存储元数据对象的引用。
    - 使用 `object::create_named_object` 函数创建一个命名对象，并将其引用存储在 `constructor_ref` 中。
    - 调用 `managed_fungible_asset::initialize` 初始化可替代资产，传入名称、符号、最大供应量等参数。
    - 使用 `fungible_asset::generate_mint_ref` 创建一个铸造引用 `mint_ref`。
    - 调用 `primary_fungible_store::ensure_primary_store_exists` 确保存在主要的可替代资产存储，并将其存储在 `admin_primary_store` 中。
    - 最后，调用 `fungible_asset::mint_to` 将预定义的总供应量 `PRE_MINTED_TOTAL_SUPPLY` 铸造到主存储中。

4. **元数据获取函数 `get_metadata`**：
   ```move
   #[view]
   /// 返回在部署此模块时创建的元数据的地址。
   /// 此函数可作为离线应用的辅助函数。
   public fun get_metadata(): Object<Metadata> {
       let metadata_address = object::create_object_address(&@example_addr, ASSET_SYMBOL);
       object::address_to_object<Metadata>(metadata_address)
   }
   ```
    - `get_metadata` 函数使用 `object::create_object_address` 函数创建元数据对象的地址，并将其转换为 `Object<Metadata>` 类型。

5. **测试函数 `test_basic_flow`**：
   ```move
   #[test_only]
   use std::option;

   #[test(creator = @example_addr)]
   #[expected_failure(abort_code = 0x60004, location = example_addr::managed_fungible_asset)]
   fun test_basic_flow(creator: &signer) {
       init_module(creator);
       let creator_address = signer::address_of(creator);
       let metadata = get_metadata();

       // 断言检查预期的总供应量
       assert!(option::destroy_some(fungible_asset::supply(metadata)) == (PRE_MINTED_TOTAL_SUPPLY as u128), 1);
       
       // 尝试在禁止铸造的情况下铸造到主存储中，预期失败
       managed_fungible_asset::mint_to_primary_stores(creator, metadata, vector[creator_address], vector[100]);
   }
   ```
    - `test_basic_flow` 是一个测试函数，标记为 `#[test(creator = @example_addr)]`，表示它是一个单元测试，创建者为 `example_addr`。
    - 使用 `init_module(creator)` 初始化模块。
    - 获取创建者的地址并获取元数据。
    - 使用 `assert!` 断言检查预期的总供应量是否与 `PRE_MINTED_TOTAL_SUPPLY` 相符。
    - 调用 `managed_fungible_asset::mint_to_primary_stores` 尝试在禁止铸造的情况下向主存储铸造资产，预期该操作失败，因为预铸币没有铸造权限。


## 中文注释

```bash
```move
/// 本模块展示了如何发行仅具有“转移”和“销毁”管理能力的预铸币的示例。
/// 它利用了`managed_fungible_asset`模块，在预铸了预定义的总供应量后，仅存储了`TransferRef`和`BurnRef`。
/// 初始化后，由于此可替代资产的`MintRef`已不存在，总供应量不会再增加。
/// 可以根据需要修改`init_module()`中的代码来定制管理引用。
module example_addr::preminted_managed_coin {
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use example_addr::managed_fungible_asset;
    use std::signer;
    use std::string::utf8;

    const ASSET_SYMBOL: vector<u8> = b"MEME";                    // 资产符号
    const PRE_MINTED_TOTAL_SUPPLY: u64 = 10000;                  // 预铸的总供应量

    /// 初始化元数据对象并存储引用。
    fun init_module(admin: &signer) {
        // 创建命名对象的引用
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        
        // 初始化管理的可替代资产
        managed_fungible_asset::initialize(
            constructor_ref,
            1000000000,                                             // 最大供应量
            utf8(b"preminted coin"),                                // 名称
            utf8(ASSET_SYMBOL),                                     // 符号
            8,                                                      // 小数位数
            utf8(b"http://example.com/favicon.ico"),                // 图标 URI
            utf8(b"http://example.com"),                            // 项目链接 URI
            vector[false, true, true],                               // 参考标志向量（铸造、转移、销毁）
        );

        // 创建铸造引用，将预铸的可替代资产的固定供应量铸造到特定账户。
        // 此账户可以是任何账户，包括普通用户账户、资源账户、多重签名账户等。
        // 这里仅使用创建者账户作为概念验证的例子。
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let admin_primary_store = primary_fungible_store::ensure_primary_store_exists(
            signer::address_of(admin),
            get_metadata()
        );
        fungible_asset::mint_to(&mint_ref, admin_primary_store, PRE_MINTED_TOTAL_SUPPLY);
    }

    #[view]
    /// 返回在部署此模块时创建的元数据的地址。
    /// 此函数可作为离线应用的辅助函数。
    public fun get_metadata(): Object<Metadata> {
        let metadata_address = object::create_object_address(&@example_addr, ASSET_SYMBOL);
        object::address_to_object<Metadata>(metadata_address)
    }

    #[test_only]
    use std::option;

    #[test(creator = @example_addr)]
    #[expected_failure(abort_code = 0x60004, location = example_addr::managed_fungible_asset)]
    fun test_basic_flow(creator: &signer) {
        init_module(creator);
        let creator_address = signer::address_of(creator);
        let metadata = get_metadata();

        // 断言检查预期的总供应量
        assert!(option::destroy_some(fungible_asset::supply(metadata)) == (PRE_MINTED_TOTAL_SUPPLY as u128), 1);
        
        // 尝试在禁止铸造的情况下铸造到主存储中，预期失败
        managed_fungible_asset::mint_to_primary_stores(creator, metadata, vector[creator_address], vector[100]);
    }
}
``` 

```