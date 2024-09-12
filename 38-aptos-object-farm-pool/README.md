# 快速开始

```bash
aptos move test
```


# 解析

这段代码是用 Move 语言编写的，定义了一个智能合约模块 `farm_pool::farm_pool`。它涉及到一个质押池（Farm Pool）的创建、管理和操作，主要包括质押、取回质押、奖励分配等功能。以下是对这段代码的详细解析：

### 模块导入

```rust
module farm_pool::farm_pool {
    use std::option::{Self, none, Option};
    use std::signer;
    use std::string::utf8;
    use aptos_std::math64;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp::{Self, now_seconds};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
```

- `std::option::{Self, none, Option}`: 用于处理 `Option` 类型。
- `std::signer`: 引入签名者模块。
- `std::string::utf8`: 用于处理 UTF-8 字符串。
- `aptos_std::math64`: 提供 64 位整数的数学运算功能。
- `aptos_framework::account::{Self, SignerCapability}`: 处理账户和签名能力。
- `aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata}`: 处理可替代资产和其元数据。
- `aptos_framework::object::{Self, Object}`: 处理对象。
- `aptos_framework::primary_fungible_store`: 处理主代币存储。
- `aptos_framework::timestamp::{Self, now_seconds}`: 获取当前时间。
- `aptos_token_objects::collection`: 处理代币集合。
- `aptos_token_objects::token`: 处理代币操作。

### 常量和结构体定义

```rust
    const ErrMetadataType: u64 = 10;
    const ErrOwner: u64 = 11;

    struct FarmPool has key {
        stake_token_metadata: Object<Metadata>,
        reward_token_metadate: Object<Metadata>,
        reward_token_per_sec: u64,
        reward_per_token: u64,
        total_stake_amount: u64,
        last_update_time: u64,
        operator: address
    }

    struct FarmPoolRefs has key {
        extend_ref: object::ExtendRef
    }

    struct UserFarmInfo has key {
        farm_pool: Object<FarmPool>,
        index: u64,
        stake_amount: u64,
        deb: u64,
        unclaimed_reward: u64
    }

    struct UserFarmInfoRefs has key {
        extend_ref: object::ExtendRef,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        transfer_ref: object::TransferRef
    }

    struct ResourceAccountCap has key {
        cap: SignerCapability
    }

    const SEED: vector<u8> = b"farm pool";

    struct UserFarmInfoCollectionRef has key {
        mutator_ref: collection::MutatorRef
    }
```

- `ErrMetadataType` 和 `ErrOwner`: 错误码常量。
- `FarmPool` 结构体: 表示质押池，包含质押和奖励代币的元数据、每秒奖励代币、奖励率、总质押金额、最后更新时间和操作员地址。
- `FarmPoolRefs` 结构体: 包含 `ExtendRef` 用于扩展操作。
- `UserFarmInfo` 结构体: 表示用户的质押信息，包含质押池、索引、质押金额、债务和未领取奖励。
- `UserFarmInfoRefs` 结构体: 包含用于扩展、燃烧、变更和转移代币的引用。
- `ResourceAccountCap` 结构体: 存储账户的签名能力。
- `SEED` 常量: 用于创建资源账户的种子。
- `UserFarmInfoCollectionRef` 结构体: 包含集合的 `MutatorRef`。

### 初始化模块

```rust
    fun init_module(deployer: &signer) {
        let (signer, cap) = account::create_resource_account(
            deployer,
            SEED
        );
        move_to(
            &signer,
            ResourceAccountCap {
                cap
            }
        );
        let collection_cref = collection::create_unlimited_collection(
            &signer,
            utf8(b""),
            utf8(b"Staking Voucher"),
            none(),
            utf8(b"")
        );

        move_to(
            &signer,
            UserFarmInfoCollectionRef {
                mutator_ref: collection::generate_mutator_ref(&collection_cref)
            }
        );
    }
```

- `init_module` 函数：初始化模块，创建资源账户，并创建一个无限制的代币集合。将这些数据转移到相应的对象中。

### 其他函数

#### 地址和签名者

```rust
    inline fun get_address(): address {
        account::create_resource_address(
            &@farm_pool,
            SEED
        )
    }

    inline fun get_signer(): &signer {
        &account::create_signer_with_capability(&borrow_global<ResourceAccountCap>(get_address()).cap)
    }
```

- `get_address`: 返回模块的资源地址。
- `get_signer`: 返回与模块关联的签名者。

#### 创建质押池

```rust
    public fun create(
        signer: &signer,
        stake_token_metadata: Object<Metadata>,
        reward_token_metadate: Object<Metadata>,
        fa: FungibleAsset,
        reward_token_per_sec: u64
    ): Object<FarmPool> {
        assert!(fungible_asset::metadata_from_asset(&fa) == reward_token_metadate, ErrMetadataType);
        let object_cref = object::create_object(get_address());
        move_to(
            &object::generate_signer(&object_cref),
            FarmPoolRefs {
                extend_ref: object::generate_extend_ref(&object_cref)
            }
        );

        move_to(
            &object::generate_signer(&object_cref),
            FarmPool {
                stake_token_metadata,
                reward_token_metadate,
                reward_token_per_sec,
                reward_per_token: 0,
                total_stake_amount: 0,
                last_update_time: now_seconds(),
                operator: signer::address_of(signer)
            }
        );

        primary_fungible_store::deposit(
            object::address_from_constructor_ref(&object_cref),
            fa
        );

        object::object_from_constructor_ref(&object_cref)
    }
```

- `create`: 创建一个新的质押池对象，并初始化其数据。将质押池对象和相关引用转移到合约中，同时将初始奖励代币存入主代币存储中。

#### 创建用户质押信息

```rust
    fun create_user_farm_info(farm_pool: Object<FarmPool>): Object<UserFarmInfo> acquires ResourceAccountCap {
        let object_cref = token::create_numbered_token(
            get_signer(),
            utf8(b"Staking Voucher"),
            utf8(b""),
            utf8(b"Staking Voucher #"),
            utf8(b""),
            none(),
            utf8(b""),
        );

        move_to(
            &object::generate_signer(&object_cref),
            UserFarmInfo {
                farm_pool,
                index: 0,
                stake_amount: 0,
                deb: 0,
                unclaimed_reward: 0
            }
        );

        move_to(
            &object::generate_signer(&object_cref),
            UserFarmInfoRefs {
                extend_ref: object::generate_extend_ref(&object_cref),
                burn_ref: token::generate_burn_ref(&object_cref),
                mutator_ref: token::generate_mutator_ref(&object_cref),
                transfer_ref: object::generate_transfer_ref(&object_cref),
            }
        );

        object::object_from_constructor_ref(&object_cref)
    }
```

- `create_user_farm_info`: 创建用户质押信息对象，并生成相关的引用。

#### 更新质押池的奖励信息

```rust
    fun update_pool_index(farm_pool_object: Object<FarmPool>) acquires FarmPool {
        let farm_pool = borrow_global_mut<FarmPool>(object::object_address(&farm_pool_object));
        let now = timestamp::now_seconds();
        let time = (now - farm_pool.last_update_time);
        if (time == 0) {
            return
        };
        let rewards = time * farm_pool.reward_token_per_sec;
        farm_pool.reward_per_token = farm_pool.reward_per_token + rewards / math64::max(
            farm_pool.total_stake_amount,
            0
        );
        update_farm_pool_last_time(farm_pool);
    }
```

- `update_pool_index`: 更新质押池的奖励信息，计算新的奖励每代币值，并更新质押池的最后更新时间。

#### 增加或减少质押金额

```rust
    fun decrease_amount(user_farm_info_object: Object<UserFarmInfo>, amount: u64): u64 acquires UserFarmInfo, FarmPool {
        let user_farm_info = borrow_global_mut<UserFarmInfo>(object::object_address(&user_farm_info_object));
        update_pool_index(user_farm_info.farm_pool);
        let

 farm_pool = borrow_global_mut<FarmPool>(object::object_address(&user_farm_info.farm_pool));
        decrease_farm_pool_stake_amount(farm_pool, amount);
        let claimable_rewards = farm_pool.reward_per_token * user_farm_info.stake_amount;

        user_farm_info.unclaimed_reward = user_farm_info.unclaimed_reward + claimable_rewards - user_farm_info.deb;

        user_farm_info.stake_amount = user_farm_info.stake_amount - amount;

        user_farm_info.deb = farm_pool.reward_per_token * user_farm_info.stake_amount;

        user_farm_info.stake_amount
    }

    fun increase_amount(user_farm_info_object: Object<UserFarmInfo>, amount: u64): u64 acquires UserFarmInfo, FarmPool {
        let user_farm_info = borrow_global_mut<UserFarmInfo>(object::object_address(&user_farm_info_object)) ;
        update_pool_index(user_farm_info.farm_pool);

        let farm_pool = borrow_global_mut<FarmPool>(object::object_address(&user_farm_info.farm_pool));
        increase_farm_pool_stake_amount(farm_pool, amount);

        let claimable_rewards = farm_pool.reward_per_token * user_farm_info.stake_amount;

        user_farm_info.unclaimed_reward = user_farm_info.unclaimed_reward + claimable_rewards - user_farm_info.deb;

        user_farm_info.stake_amount = user_farm_info.stake_amount + amount;

        user_farm_info.deb = farm_pool.reward_per_token * user_farm_info.stake_amount;

        user_farm_info.stake_amount
    }
```

- `decrease_amount` 和 `increase_amount`: 更新用户质押信息的质押金额，并调整质押池的总质押金额及奖励信息。

#### 领取奖励

```rust
    public fun claim_rewards(
        sender: &signer,
        user_farm_info_object: Object<UserFarmInfo>
    ): FungibleAsset acquires FarmPool, UserFarmInfo, FarmPoolRefs, UserFarmInfoRefs {
        update_pool_index(get_user_farm_info_farm_pool(user_farm_info_object));
        let claimable_rewards = claimable_rewards(user_farm_info_object);
        let user_farm_info = assert_owner(user_farm_info_object, signer::address_of(sender));
        user_farm_info.deb = get_new_reward_per_token(user_farm_info.farm_pool) * user_farm_info.stake_amount;
        user_farm_info.unclaimed_reward = 0;
        let metadata = get_rewards_metadata_object(get_user_farm_info_farm_pool(user_farm_info_object));
        let fa = primary_fungible_store::withdraw(
            get_farm_pool_signer(user_farm_info_object),
            metadata,
            claimable_rewards
        );

        if (get_user_farm_info_stake_amount(user_farm_info_object) == 0) {
            let UserFarmInfo {
                farm_pool: _,
                index: _,
                stake_amount: _,
                deb: _,
                unclaimed_reward: _
            } = move_from<UserFarmInfo>(object::object_address(&user_farm_info_object));

            let UserFarmInfoRefs {
                extend_ref: _,
                mutator_ref: _,
                burn_ref,
                transfer_ref: _
            } = move_from<UserFarmInfoRefs>(object::object_address(&user_farm_info_object));

            token::burn(burn_ref);
        };
        fa
    }
```

- `claim_rewards`: 允许用户领取奖励，更新用户信息，提取奖励代币，并在用户没有质押金额时销毁用户质押信息对象。

### 其他功能

- **质押和取回质押**：处理质押（`stake`）和取回质押（`unstake`）功能，更新相应的信息。
- **设置奖励速率**（`set_reward_token_per_sec`）：允许操作员设置每秒奖励代币数。
- **添加奖励**（`add_reward`）：允许向质押池中添加奖励代币。
- **获取信息**：包括获取奖励和质押代币的元数据，获取用户质押信息中的质押金额等。

### 测试功能

```rust
    #[test_only]
    public fun init_for_test(sender: &signer) {
        init_module(sender)
    }
```

- `init_for_test`: 用于测试模块的初始化。

### 总结

这段代码定义了一个功能丰富的质押池模块，支持创建质押池、用户质押信息、质押和取回质押、领取奖励等操作。它通过处理代币、奖励和质押金额等方面，支持一个完整的质押和奖励系统。