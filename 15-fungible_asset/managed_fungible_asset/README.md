# 概述

该模块提供了一个管理型可替代资产，允许元数据对象的所有者铸造、转账和销毁 fungible 资产。

# 快速开始

```bash
aptos move test
```

# 详解

### 主要结构和功能

1. **模块定义**
    - 整个代码位于一个名为 `aptos_framework` 的模块中，通过 `module aptos_framework` 开始。

2. **数据结构定义**
    - **Metadata**：元数据对象，用来描述资产的信息。
    - **FungibleStore**：fungible存储，用来存储fungible资产。
    - **FungibleAsset**：fungible资产，通过 `aptos_framework::fungible_asset` 模块管理。

3. **函数和方法定义**
    - **initialize**：初始化函数，用来设置资产的基本信息。
    - **mint_to_primary_stores**：向主要fungible存储（主要账户）增发资产。
    - **set_primary_stores_frozen_status**：设置主要fungible存储的冻结状态。
    - **transfer_between_primary_stores**：在主要fungible存储之间进行资产转移。
    - **withdraw_from_primary_stores**：从主要fungible存储中提取资产。
    - **deposit_to_primary_stores**：向主要fungible存储存入资产。
    - **burn_from_primary_stores**：销毁主要fungible存储中的资产。
    - **set_frozen_status**：设置fungible存储的冻结状态。
    - **withdraw**：从fungible存储中提取资产。
    - **deposit**：向fungible存储存入资产。

4. **权限控制**
    - 使用 `signer` 类型的参数来验证调用者是否有权限执行特定操作，如 `admin: &signer`。

5. **辅助函数**
    - **authorized_borrow_refs**：验证并借用资产所有者的管理引用。
    - **authorized_borrow_mint_ref**、**authorized_borrow_transfer_ref**、**authorized_borrow_burn_ref**：分别验证并借用MintRef、TransferRef和BurnRef。
    - **create_test_mfa**：测试用的辅助函数，创建一个测试用的MFA对象。

6. **测试函数**
    - **test_basic_flow**：测试基本流程，包括资产发行、冻结、转移、提取、存入和销毁等操作。
    - **test_permission_denied**：测试权限被拒绝的情况，验证了权限控制的有效性。

### Move语言特性

- **权限管理**：通过 `signer` 类型和相关的权限验证函数来管理操作权限。
- **资源管理**：使用 `acquires` 关键字和 `ManagingRefs` 结构来管理资源的借用和释放。
- **异常处理**：通过 `assert!` 宏来处理异常情况，如无效的参数或权限拒绝。

### 测试和调试

- 代码中包含了测试函数，使用了 `#[test]` 和 `#[expected_failure]` 注解来定义测试用例，测试了不同情况下的合约行为和异常处理。

## 中文注释

```move
/// 该模块提供了一个管理型可替代资产，允许元数据对象的所有者铸造、转账和销毁 fungible 资产。
///
/// 该模块提供的功能包括：
/// 1. 作为元数据对象的所有者向 fungible 存储铸造 fungible 资产。
/// 2. 作为元数据对象的所有者在 fungible 存储之间转账 fungible 资产，忽略 `frozen` 字段。
/// 3. 作为元数据对象的所有者从 fungible 存储销毁 fungible 资产。
/// 4. 作为元数据对象的所有者从 fungible 存储提取合并后的 fungible 资产。
/// 5. 将 fungible 资产存入 fungible 存储。
module example_addr::managed_fungible_asset {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata, FungibleStore, FungibleAsset};
    use aptos_framework::object::{Self, Object, ConstructorRef};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::String;
    use std::option;

    /// 仅 fungible 资产元数据的所有者可以进行更改。
    const ERR_NOT_OWNER: u64 = 1;
    /// ref_flags 的长度不为 3。
    const ERR_INVALID_REF_FLAGS_LENGTH: u64 = 2;
    /// 两个向量的长度不相等。
    const ERR_VECTORS_LENGTH_MISMATCH: u64 = 3;
    /// MintRef 错误。
    const ERR_MINT_REF: u64 = 4;
    /// TransferRef 错误。
    const ERR_TRANSFER_REF: u64 = 5;
    /// BurnRef 错误。
    const ERR_BURN_REF: u64 = 6;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// 持有引用以控制 fungible 资产的铸造、转账和销毁。
    struct ManagingRefs has key {
        mint_ref: Option<MintRef>,
        transfer_ref: Option<TransferRef>,
        burn_ref: Option<BurnRef>,
    }

    /// 初始化元数据对象并存储指定的引用。
    public fun initialize(
        constructor_ref: &ConstructorRef,
        maximum_supply: u128,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        ref_flags: vector<bool>,
    ) {
        assert!(vector::length(&ref_flags) == 3, error::invalid_argument(ERR_INVALID_REF_FLAGS_LENGTH));
        let supply = if (maximum_supply != 0) {
            option::some(maximum_supply)
        } else {
            option::none()
        };
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
        );

        // 可选地创建铸造/销毁/转账引用，以允许创建者管理 fungible 资产。
        let mint_ref = if (*vector::borrow(&ref_flags, 0)) {
            option::some(fungible_asset::generate_mint_ref(constructor_ref))
        } else {
            option::none()
        };
        let transfer_ref = if (*vector::borrow(&ref_flags, 1)) {
            option::some(fungible_asset::generate_transfer_ref(constructor_ref))
        } else {
            option::none()
        };
        let burn_ref = if (*vector::borrow(&ref_flags, 2)) {
            option::some(fungible_asset::generate_burn_ref(constructor_ref))
        } else {
            option::none()
        };
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagingRefs { mint_ref, transfer_ref, burn_ref }
        )
    }

    /// 作为元数据对象的所有者，向多个账户的主要 fungible 存储铸造 fungible 资产。
    public entry fun mint_to_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        to: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let receiver_primary_stores = vector::map(
            to,
            |addr| primary_fungible_store::ensure_primary_store_exists(addr, asset)
        );
        mint(admin, asset, receiver_primary_stores, amounts);
    }

    /// 作为元数据对象的所有者，向多个 fungible 存储铸造 fungible 资产。
    public entry fun mint(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>,
    ) acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(length == vector::length(&amounts), error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH));
        let mint_ref = authorized_borrow_mint_ref(admin, asset);
        let i = 0;
        while (i < length) {
            fungible_asset::mint_to(mint_ref, *vector::borrow(&stores, i), *vector::borrow(&amounts, i));
            i = i + 1;
        }
    }

    /// 作为元数据对象的所有者，在 fungible 存储之间转账 fungible 资产，忽略 `frozen` 字段。
    public entry fun transfer_between_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        from: vector<address>,
        to: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let sender_primary_stores = vector::map(
            from,
            |addr| primary_fungible_store::primary_store(addr, asset)
        );
        let receiver_primary_stores = vector::map(
            to,
            |addr| primary_fungible_store::ensure_primary_store_exists(addr, asset)
        );
        transfer(admin, asset, sender_primary_stores, receiver_primary_stores, amounts);
    }

    /// 作为元数据对象的所有者，在 fungible 存储之间转账 fungible 资产，忽略 `frozen` 字段。
    public entry fun transfer(
        admin: &signer,
        asset: Object<Metadata>,
        sender_stores: vector<Object<FungibleStore>>,
        receiver_stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>,
    ) acquires ManagingRefs {
        let length = vector::length(&sender_stores);
        assert!(length == vector::length(&receiver_stores), error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH));
        assert!(length == vector::length(&amounts), error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH));
        let transfer_ref = authorized_borrow_transfer_ref(admin, asset);
        let i = 0;
        while (i < length) {
            fungible_asset::transfer_with_ref(
                transfer_ref,
                *vector::borrow(&sender_stores, i),
                *vector::borrow(&receiver_stores, i),
                *vector::borrow(&amounts, i)
            );
            i = i + 1;
        }
    }

    /// 作为元数据对象的所有者，从多个账户的主要 fungible 存储销毁 fungible 资产。
    public entry fun burn_from_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        from: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let primary_stores = vector::map(
            from,
            |addr| primary_fungible_store::primary_store(addr, asset)
        );
        burn(admin, asset, primary_stores, amounts);
    }

    /// 作为元数据对象的所有者，从 fungible 存储销毁 fungible 资产。
    public entry fun burn(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(length == vector::length(&amounts), error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH));
        let burn_ref = authorized_borrow_burn_ref(admin, asset);
        let i = 0;
        while (i < length) {
            fungible_asset::burn_from(burn_ref, *vector::borrow(&stores, i), *vector::borrow(&amounts, i));
            i = i + 1;
        };
    }

    /// 作为元数据对象的所有者，冻结/解冻多个账户的主要 fungible 存储，使其无法转账或接收 fungible 资产。
    public entry fun set_primary_stores_frozen_status(
        admin: &signer,
        asset: Object<Metadata>,
        accounts: vector<address>,
        frozen: bool
    ) acquires ManagingRefs {
        let primary_stores = vector::map(accounts, |acct| {
            primary_fungible_store::ensure_primary_store_exists(acct, asset)
        });
        set_frozen_status(admin, asset, primary_stores, frozen);
    }

    /// 作为元数据对象的所有者，冻结/解冻 fungible 存储，使其无法转账或接收 fungible 资产。
    public entry fun set_frozen_status(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        frozen: bool
    ) acquires ManagingRefs {
        let transfer_ref = authorized_borrow_transfer_ref(admin, asset);
        vector::for_each(stores, |store| {
            fungible_asset::set_frozen_flag(transfer_ref, store, frozen);
        });
    }

    /// 作为元数据对象的所有者，从多个账户的主要 fungible 存储提取 fungible 资产，合并后返回。
    public fun withdraw_from_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        from: vector<address>,
        amounts: vector<u64>
    ): FungibleAsset acquires ManagingRefs {
        let primary_stores = vector::map(
            from,
            |addr| primary_fungible_store::primary_store(addr, asset)
        );
        withdraw(admin, asset, primary_stores, amounts)
    }

    /// 作为元数据对象的所有者，从 fungible 存储提取 fungible 资产，合并后返回。
    public fun withdraw(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ): FungibleAsset acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(length == vector::length(&amounts), error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH));
        let transfer_ref = authorized_borrow_transfer_ref(admin, asset);
        let i = 0;
        let sum = fungible_asset::zero(asset);
        while (i < length) {
            let fa = fungible_asset::withdraw_with_ref(
                transfer_ref,
                *vector::borrow(&stores, i),
                *vector::borrow(&amounts, i)
            );
            fungible_asset::merge(&mut sum, fa);
            i = i + 1;
        };
        sum
    }

    /// 作为元数据对象的所有者，向多个账户的主要 fungible 存储存入 fungible 资产，从给定的 fungible 资产中取出。
    public fun deposit_to_primary_stores(
        admin: &signer,
        fa: &mut FungibleAsset,
        from: vector<address>,
        amounts: vector<u64>,
    ) acquires ManagingRefs {
        let primary_stores = vector::map(
            from,
            |addr| primary_fungible_store::ensure_primary_store_exists(addr, fungible_asset::asset_metadata(fa))
        );
        deposit(admin, fa, primary_stores, amounts);
    }

    /// 作为元数据对象的所有者，向 fungible 存储存入 fungible 资产，从给定的 fungible 资产中取出。
    public fun deposit(
        admin: &signer,
        fa: &mut FungibleAsset,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(length == vector::length(&amounts), error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH));
        let transfer_ref = authorized_borrow_transfer_ref(admin, fungible_asset::asset_metadata(fa));
        let i = 0;
        while (i < length) {
            let split_fa = fungible_asset::extract(fa, *vector::borrow(&amounts, i));
            fungible_asset::deposit_with_ref(
                transfer_ref,
                *vector::borrow(&stores, i),
                split_fa,
            );
            i = i + 1;
        };
    }

    /// 借用 `metadata` 的不可变引用。
    /// 验证签名者是否为元数据对象的所有者。
    inline fun authorized_borrow_refs(
        owner: &signer,
        asset: Object<Metadata>,
    ): &ManagingRefs acquires ManagingRefs {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ERR_NOT_OWNER));
        borrow_global<ManagingRefs>(object::object_address(&asset))
    }

    /// 检查并借用 `MintRef`。
    inline fun authorized_borrow_mint_ref(
        owner: &signer,
        asset: Object<Metadata>,
    ): &MintRef acquires ManagingRefs {
        let refs = authorized_borrow_refs(owner, asset);
        assert!(option::is_some(&refs.mint_ref), error::not_found(ERR_MINT_REF));
        option::borrow(&refs.mint_ref)
    }

    /// 检查并借用 `TransferRef`。
    inline fun authorized_borrow_transfer_ref(
        owner: &signer,
        asset: Object<Metadata>,
    ): &TransferRef acquires ManagingRefs {
        let refs = authorized_borrow_refs(owner, asset);
        assert!(option::is_some(&refs.transfer_ref), error::not_found(ERR_TRANSFER_REF));
        option::borrow(&refs.transfer_ref)
    }

    /// 检查并借用 `BurnRef`。
    inline fun authorized_borrow_burn_ref(
        owner: &signer,
        asset: Object<Metadata>,
    ): &BurnRef acquires ManagingRefs {
        let refs = authorized_borrow_refs(owner, asset);
        assert!(option::is_some(&refs.mint_ref), error::not_found(ERR_BURN_REF));
        option::borrow(&refs.burn_ref)
    }

    /// 测试辅助函数：创建一个测试用的 MFA（Managed Fungible Asset）对象。
    #[test_only]
    use aptos_framework::object::object_from_constructor_ref;
    #[test_only]
    use std::string::utf8;
    use std::vector;
    use std::option::Option;

    #[test_only]
    fun create_test_mfa(creator: &signer): Object<Metadata> {
        let constructor_ref = &object::create_named_object(creator, b"APT");
        initialize(
            constructor_ref,
            0,
            utf8(b"Aptos Token"), /* name */
            utf8(b"APT"), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com"), /* project */
            vector[true, true, true]
        );
        object_from_constructor_ref<Metadata>(constructor_ref)
    }

    /// 测试基本流程。
    #[test(creator = @example_addr)]
    fun test_basic_flow(
        creator: &signer,
    ) acquires ManagingRefs {
        let metadata = create_test_mfa(creator);
        let creator_address = signer::address_of(creator);
        let aaron_address = @0xface;

        mint_to_primary_stores(creator, metadata, vector[creator_address, aaron_address], vector[100, 50]);
        assert!(primary_fungible_store::balance(creator_address, metadata) == 100, 1);
        assert!(primary_fungible_store::balance(aaron_address, metadata) == 50, 2);

        set_primary_stores_frozen_status(creator, metadata, vector[creator_address, aaron_address], true);
        assert!(primary_fungible_store::is_frozen(creator_address, metadata), 3);
        assert!(primary_fungible_store::is_frozen(aaron_address, metadata), 4);

        transfer_between_primary_stores(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            vector[aaron_address, creator_address],
            vector[10, 5]
        );
        assert!(primary_fungible_store::balance(creator_address, metadata) == 95, 5);
        assert!(primary_fungible_store::balance(aaron_address, metadata) == 55, 6);

        set_primary_stores_frozen_status(creator, metadata, vector[creator_address, aaron_address], false);
        assert!(!primary_fungible_store::is_frozen(creator_address, metadata), 7);
        assert!(!primary_fungible_store::is_frozen(aaron_address, metadata), 8);

        let fa = withdraw_from_primary_stores(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            vector[25, 15]
        );
        assert!(fungible_asset::amount(&fa) == 40, 9);
        deposit_to_primary_stores(creator, &mut fa, vector[creator_address, aaron_address], vector[30, 10]);
        fungible_asset::destroy_zero(fa);

        burn_from_primary_stores(creator, metadata, vector[creator_address, aaron_address], vector[100, 50]);
        assert!(primary_fungible_store::balance(creator_address, metadata) == 0, 10);
        assert!(primary_fungible_store::balance(aaron_address, metadata) == 0, 11);
    }

    /// 测试权限被拒绝的情况。
    #[test(creator = @example_addr, aaron = @0xface)]
    #[expected_failure(abort_code = 0x50001, location = Self)]
    fun test_permission_denied(
        creator: &signer,
        aaron: &signer
    ) acquires ManagingRefs {
        let metadata = create_test_mfa(creator);
        let creator_address = signer::address_of(creator);
        mint_to_primary_stores(aaron, metadata, vector[creator_address], vector[100]);
    }
}

```