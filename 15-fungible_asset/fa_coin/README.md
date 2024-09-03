# 概述

定义了一个 FACoin 模块，它结合了 managed_fungible_asset 和 coin_example 功能，实现了管理型可替代资产的创建、铸造、转账、销毁、冻结和解冻等操作。模块在部署时会创建一个硬编码的可替代资产，供应配置包括名称、符号和小数位数。模块使用了 Aptos 智能合约框架的各种库和类型，确保了安全和功能性

# 快速开始

```bash
aptos move test
```


# 详解

定义了一个 FACoin 模块，它结合了 managed_fungible_asset 和 coin_example 功能，实现了管理型可替代资产的创建、铸造、转账、销毁、冻结和解冻等操作。模块在部署时会创建一个硬编码的可替代资产，供应配置包括名称、符号和小数位数。模块使用了 Aptos 智能合约框架的各种库和类型，确保了安全和功能性

# 中文注释

```move
/// FACoin 模块是一个组合了 managed_fungible_asset 和 coin_example 功能的 2 合 1 模块。
/// 当部署时，部署者将创建一个新的管理型可替代资产，其中包含硬编码的供应配置、名称、符号和小数位数。
/// 资产的地址可以通过 get_metadata() 函数获取。作为简化版本，该模块仅处理主要存储。
module FACoin::fa_coin {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata, FungibleAsset};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::utf8;
    use std::option;

    /// 仅有 fungible 资产元数据所有者可以进行更改。
    const ENOT_OWNER: u64 = 1;

    /// 资产的符号。
    const ASSET_SYMBOL: vector<u8> = b"FA";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// 持有引用以控制 fungible 资产的铸造、转账和销毁。
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    /// 初始化元数据对象并存储引用。
    // :!:>initialize
    /// 初始化模块，创建管理的可替代资产并存储相关引用。
    fun init_module(admin: &signer) {
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"FA Coin"), // 名称
            utf8(ASSET_SYMBOL), // 符号
            8, // 小数位数
            utf8(b"http://example.com/favicon.ico"), // 图标
            utf8(b"http://example.com"), // 项目链接
        );

        // 创建铸造/销毁/转账引用，以便创建者可以管理 fungible 资产。
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        )// <:!:initialize
    }

    #[view]
    /// 返回在部署时创建的管理型 fungible 资产的地址。
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@FACoin, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }

    // :!:>mint
    /// 作为元数据对象的所有者进行铸造操作。
    public entry fun mint(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }// <:!:mint

    /// 作为元数据对象的所有者进行转账操作，忽略 `frozen` 字段。
    public entry fun transfer(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::transfer_with_ref(transfer_ref, from_wallet, to_wallet, amount);
    }

    /// 作为元数据对象的所有者进行销毁 fungible 资产操作。
    public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let burn_ref = &authorized_borrow_refs(admin, asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    /// 冻结一个账户，使其无法转账或接收 fungible 资产。
    public entry fun freeze_account(admin: &signer, account: address) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, asset);
        fungible_asset::set_frozen_flag(transfer_ref, wallet, true);
    }

    /// 解冻一个账户，使其可以转账或接收 fungible 资产。
    public entry fun unfreeze_account(admin: &signer, account: address) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, asset);
        fungible_asset::set_frozen_flag(transfer_ref, wallet, false);
    }

    /// 作为元数据对象的所有者进行提现操作，忽略 `frozen` 字段。
    public fun withdraw(admin: &signer, amount: u64, from: address): FungibleAsset acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::withdraw_with_ref(transfer_ref, from_wallet, amount)
    }

    /// 作为元数据对象的所有者进行存款操作，忽略 `frozen` 字段。
    public fun deposit(admin: &signer, to: address, fa: FungibleAsset) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::deposit_with_ref(transfer_ref, to_wallet, fa);
    }

    /// 借用 `metadata` 的引用以授权访问铸造、转账和销毁引用。
    /// 这会验证签名者是否为元数据对象的所有者。
    inline fun authorized_borrow_refs(
        owner: &signer,
        asset: Object<Metadata>,
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    #[test(creator = @FACoin)]
    fun test_basic_flow(
        creator: &signer,
    ) acquires ManagedFungibleAsset {
        init_module(creator);
        let creator_address = signer::address_of(creator);
        let aaron_address = @0xface;

        mint(creator, creator_address, 100);
        let asset = get_metadata();
        assert!(primary_fungible_store::balance(creator_address, asset) == 100, 4);
        freeze_account(creator, creator_address);
        assert!(primary_fungible_store::is_frozen(creator_address, asset), 5);
        transfer(creator, creator_address, aaron_address, 10);
        assert!(primary_fungible_store::balance(aaron_address, asset) == 10, 6);

        unfreeze_account(creator, creator_address);
        assert!(!primary_fungible_store::is_frozen(creator_address, asset), 7);
        burn(creator, creator_address, 90);
    }

    #[test(creator = @FACoin, aaron = @0xface)]
    #[expected_failure(abort_code = 0x50001, location = Self)]
    fun test_permission_denied(
        creator: &signer,
        aaron: &signer
    ) acquires ManagedFungibleAsset {
        init_module(creator);
        let creator_address = signer::address_of(creator);
        mint(aaron, creator_address, 100);
    }
}

```