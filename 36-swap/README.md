# 概述

`package_manager`

模块管理与流动性池相关的资源账户和权限，确保只有指定的友元模块可以访问和操作这些资源。它通过记录和管理模块创建的地址，以及提供获取资源账户签名器的功能来控制访问。

`liquidity_pool`

该模块提供了一种通用类型的流动性池，支持波动性代币对和稳定代币对。它在底层使用了可替代资产，并且需要一个单独的路由器和代币包装器来支持代币（与可替代资产的标准不同）。
交换费用与池的储备分开保留，因此不会复利。

对于波动性代币对，价格和储备可以使用常数乘积公式 k = x * y 计算。

对于稳定代币对，价格使用公式 k = x^3 * y + x * y^3 计算。

请注意，所有返回可替代资产的函数，例如交换、燃烧、领取费用等，都是仅限友元访问的，因为它们可能返回内部包装的可替代资产。路由器或其他模块应提供基于池的底层代币（无论是代币还是可替代资产）调用这些函数的接口。请参见 router.move 作为示例。

另一个重要的注意事项是，所有 LP 代币的转移都必须通过此模块进行调用。这是为了确保 LP 的费用能够正确更新。不支持 fungible_asset::transfer 和 primary_fungible_store::transfer。

`coin_wrapper`

该模块可以被包含在项目中，以启用将代币内部包装和解封为可替代资产的功能。

这使得项目只需在核心数据结构中存储和处理可替代资产，同时仍能够支持原生可替代资产和代币。请注意，包装的可替代资产仅限于内部使用，不应释放到用户账户之外。否则，这会在生态系统中创建多个冲突的特定代币版本。

工作流程如下：

1. 将 coin_wrapper 模块添加到项目中。
2. 为需要调用 wrap/unwrap 的核心模块添加友元声明。wrap/unwrap 是仅限友元访问的函数， 外部模块不能调用它们，以免泄露内部的可替代资产。
3. 在核心模块中添加处理代币的入口函数。这些函数将调用 wrap 创建内部可替代资产并存储它们。
4. 在核心模块中添加返回代币的入口函数。这些函数将从核心数据结构中提取内部可替代资产，将它们解封为代币，并返回代币给最终用户。

代币的可替代资产包装器具有与原始代币相同的名称、符号和小数位数。这使得存入/提取代币的账务处理和跟踪变得更容易。


`router`

该模块提供了一个流动性池的接口，支持代币和原生可替代资产。

一个流动性池包含两个代币，因此可以有三种不同的组合：
1. 两个原生可替代资产
2. 一个代币和一个原生可替代资产
3. 两个代币

对于每种组合，流动性池提供了用于交换、添加和移除流动性的不同函数。

用户提供的代币会被包装，而返回给用户的代币则通过使用 coin_wrapper 解封内部的可替代资产。


# 快速开始

```bash
aptos move test
```

# 解析

`coin_arapper.move`

这段代码是一个 Aptos 模块，名为 `swap::coin_wrapper`，它用于在项目中处理代币的包装和解包装操作。这个模块允许将原生代币（如 AptosCoin）封装成内部的可替代资产，并且从这些资产中解封回原始的代币。这样的设计通常用于在项目内处理代币而不直接暴露原生代币。以下是对这段代码的详细解析：

### 模块介绍

```rust
/// This module can be included in a project to enable internal wrapping and unwrapping of coins into fungible assets.
/// This allows the project to only have to store and process fungible assets in core data structures, while still be
/// able to support both native fungible assets and coins. Note that the wrapper fungible assets are INTERNAL ONLY and
/// are not meant to be released to user's accounts outside of the project. Othwerwise, this would create multiple
/// conflicting fungible asset versions of a specific coin in the ecosystem.
```

- **功能说明**：该模块提供了代币的包装和解包装功能。包装操作将代币转换为内部使用的可替代资产，而解包装操作则将这些资产转换回代币。包装和解包装的资产仅用于项目内部，不对外部账户开放，以避免系统内多个代币版本的冲突。

### 模块的导入和定义

```rust
module swap::coin_wrapper {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::fungible_asset::{Self, BurnRef, FungibleAsset, Metadata, MintRef};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::string_utils;
    use aptos_std::type_info;
    use std::string::{Self, String};
    use std::option;
    use std::signer;
    use swap::package_manager;
```

- **导入模块**：引入了一些 Aptos 框架中的模块和标准库，主要用于账户操作、代币操作、可替代资产操作等。
- **`package_manager`**: 从 `swap` 包中引入的模块，用于管理包地址。

### 数据结构定义

```rust
    struct FungibleAssetData has store {
        burn_ref: BurnRef,
        metadata: Object<Metadata>,
        mint_ref: MintRef,
    }

    struct WrapperAccount has key {
        signer_cap: SignerCapability,
        coin_to_fungible_asset: SmartTable<String, FungibleAssetData>,
        fungible_asset_to_coin: SmartTable<Object<Metadata>, String>,
    }
```

- **`FungibleAssetData`**：存储每个代币包装资产的数据，包括 `burn_ref`（用于解包装时燃烧资产的引用）、`metadata`（代币的元数据对象）、`mint_ref`（用于包装时铸造资产的引用）。
- **`WrapperAccount`**：跟踪所有代币包装资产的资源账户，包含签名能力 (`signer_cap`)、代币到可替代资产的映射 (`coin_to_fungible_asset`) 和可替代资产到代币的映射 (`fungible_asset_to_coin`)。

### 初始化函数

```rust
    public entry fun initialize() {
        if (is_initialized()) {
            return
        };

        let swap_signer = &package_manager::get_signer();
        let (coin_wrapper_signer, signer_cap) = account::create_resource_account(swap_signer, COIN_WRAPPER_NAME);
        package_manager::add_address(string::utf8(COIN_WRAPPER_NAME), signer::address_of(&coin_wrapper_signer));
        move_to(&coin_wrapper_signer, WrapperAccount {
            signer_cap,
            coin_to_fungible_asset: smart_table::new(),
            fungible_asset_to_coin: smart_table::new(),
        });
    }
```

- **`initialize`**：初始化包装账户。如果已经初始化，则返回；否则，创建一个资源账户来存储所有的代币和包装资产，并将其地址添加到包管理器中。

### 查询函数

```rust
    #[view]
    public fun is_initialized(): bool {
        package_manager::address_exists(string::utf8(COIN_WRAPPER_NAME))
    }

    #[view]
    public fun wrapper_address(): address {
        package_manager::get_address(string::utf8(COIN_WRAPPER_NAME))
    }

    #[view]
    public fun is_supported<CoinType>(): bool acquires WrapperAccount {
        let coin_type = type_info::type_name<CoinType>();
        smart_table::contains(&wrapper_account().coin_to_fungible_asset, coin_type)
    }

    #[view]
    public fun is_wrapper(metadata: Object<Metadata>): bool acquires WrapperAccount {
        smart_table::contains(&wrapper_account().fungible_asset_to_coin, metadata)
    }

    #[view]
    public fun get_coin_type(metadata: Object<Metadata>): String acquires WrapperAccount {
        *smart_table::borrow(&wrapper_account().fungible_asset_to_coin, metadata)
    }

    #[view]
    public fun get_wrapper<CoinType>(): Object<Metadata> acquires WrapperAccount {
        fungible_asset_data<CoinType>().metadata
    }

    #[view]
    public fun get_original(fungible_asset: Object<Metadata>): String acquires WrapperAccount {
        if (is_wrapper(fungible_asset)) {
            get_coin_type(fungible_asset)
        } else {
            format_fungible_asset(fungible_asset)
        }
    }

    #[view]
    public fun format_fungible_asset(fungible_asset: Object<Metadata>): String {
        let fa_address = object::object_address(&fungible_asset);
        let fa_address_str = string_utils::to_string(&fa_address);
        string::sub_string(&fa_address_str, 1, string::length(&fa_address_str))
    }
```

- **`is_initialized`**：检查包装账户是否已初始化。
- **`wrapper_address`**：返回存储所有代币的资源账户地址。
- **`is_supported`**：检查某种代币类型是否已被包装。
- **`is_wrapper`**：检查给定的可替代资产是否是包装资产。
- **`get_coin_type`**：返回包装资产的原始代币类型。
- **`get_wrapper`**：返回某种代币类型的包装资产。
- **`get_original`**：返回代币的原始类型或其自身（如果是原生资产）。
- **`format_fungible_asset`**：格式化并返回可替代资产的地址字符串。

### 内部包装和解包装

```rust
    public(friend) fun wrap<CoinType>(coins: Coin<CoinType>): FungibleAsset acquires WrapperAccount {
        create_fungible_asset<CoinType>();
        let amount = coin::value(&coins);
        aptos_account::deposit_coins(wrapper_address(), coins);
        let mint_ref = &fungible_asset_data<CoinType>().mint_ref;
        fungible_asset::mint(mint_ref, amount)
    }

    public(friend) fun unwrap<CoinType>(fa: FungibleAsset): Coin<CoinType> acquires WrapperAccount {
        let amount = fungible_asset::amount(&fa);
        let burn_ref = &fungible_asset_data<CoinType>().burn_ref;
        fungible_asset::burn(burn_ref, fa);
        let wrapper_signer = &account::create_signer_with_capability(&wrapper_account().signer_cap);
        coin::withdraw(wrapper_signer, amount)
    }

    public(friend) fun create_fungible_asset<CoinType>(): Object<Metadata> acquires WrapperAccount {
        let coin_type = type_info::type_name<CoinType>();
        let wrapper_account = mut_wrapper_account();
        let coin_to_fungible_asset = &mut wrapper_account.coin_to_fungible_asset;
        let wrapper_signer = &account::create_signer_with_capability(&wrapper_account.signer_cap);
        if (!smart_table::contains(coin_to_fungible_asset, coin_type)) {
            let metadata_constructor_ref = &object::create_named_object(wrapper_signer, *string::bytes(&coin_type));
            primary_fungible_store::create_primary_store_enabled_fungible_asset(
                metadata_constructor_ref,
                option::none(),
                coin::name<CoinType>(),
                coin::symbol<CoinType>(),
                coin::decimals<CoinType>(),
                string::utf8(b""),
                string::utf8(b""),
            );

            let mint_ref = fungible_asset::generate_mint_ref(metadata_constructor_ref);
            let burn_ref = fungible_asset::generate_burn_ref(metadata_constructor_ref);
            let metadata = object::object_from_constructor_ref<Metadata>(metadata_constructor_ref);
            smart_table::add(coin_to_fungible_asset, coin_type, FungibleAssetData {
                metadata,
                mint_ref,
                burn_ref,
            });
            smart_table::add(&mut wrapper_account.fungible_asset_to_coin, metadata, coin_type);
        };
        smart_table::borrow(coin_to_fungible_asset, coin_type).metadata
    }
```

- **`wrap`**：将代币包装成可替代资产，并将代币存入主资源账户。首先确保对应的可替代资产已经创建，然后铸造可替代资产。
- **`

unwrap`**：将可替代资产解封为代币，首先燃烧可替代资产，然后从主资源账户中提取相应数量的代币。
- **`create_fungible_asset`**：为指定的代币类型创建一个可替代资产包装器，如果包装器不存在，则创建新的包装器并存储相关数据。

### 辅助函数

```rust
    inline fun fungible_asset_data<CoinType>(): &FungibleAssetData acquires WrapperAccount {
        let coin_type = type_info::type_name<CoinType>();
        smart_table::borrow(&wrapper_account().coin_to_fungible_asset, coin_type)
    }

    inline fun wrapper_account(): &WrapperAccount acquires WrapperAccount {
        borrow_global<WrapperAccount>(wrapper_address())
    }

    inline fun mut_wrapper_account(): &mut WrapperAccount acquires WrapperAccount {
        borrow_global_mut<WrapperAccount>(wrapper_address())
    }

    #[test_only]
    friend swap::coin_wrapper_tests;
```

- **`fungible_asset_data`**：借用指定代币类型的可替代资产数据。
- **`wrapper_account`**：借用主资源账户的不可变引用。
- **`mut_wrapper_account`**：借用主资源账户的可变引用。
- **`swap::coin_wrapper_tests`**：引入测试模块以便进行模块测试（仅限测试）。

### 总结

该模块的设计目的是通过将代币包装为可替代资产来处理代币，以便在项目内更高效地管理代币，同时避免将代币直接暴露给外部账户。模块包括初始化包装账户、检查包装状态、包装和解包装代币等功能。所有的包装和解包装操作都是项目内部的，因此通过友元模块 `swap::router` 和 `swap::coin_wrapper_tests` 来保护这些操作。
