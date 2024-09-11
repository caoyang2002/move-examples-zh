# 概述

这个模块展示了如何在区块链上实现一个共享账户的管理系统，可以用于处理NFT的版税分发。它包括创建共享账户、分发代币、以及相关的测试功能。这种模块可以在实际应用中用于管理和分发基于区块链的经济激励。

# 快速开始

```bash
aptos move test
```

# 解析

这段代码是一个示例模块，用于演示如何在区块链环境中创建和管理一个共享账户，用于分发NFT（非同质化代币）版税。该代码主要包括以下几个功能：初始化共享账户、分发代币、以及测试相关功能。下面是对代码的详细解析：

### 模块说明

```rust
module shared_account::SharedAccount {
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::coin;
```

- `module shared_account::SharedAccount { ... }` 定义了一个模块 `SharedAccount`，它包含了所有相关的功能和数据结构。
- `use` 语句导入了必要的库和模块，包括错误处理、签名、向量操作、账户管理和代币管理。

### 数据结构定义

```rust
    struct Share has store {
        share_holder: address,
        num_shares: u64,
    }

    struct SharedAccount has key {
        share_record: vector<Share>,
        total_shares: u64,
        signer_capability: account::SignerCapability,
    }

    struct SharedAccountEvent has key {
        resource_addr: address,
    }
```

- `Share` 结构体用于记录一个账户地址及其持有的股份数量。
- `SharedAccount` 结构体是共享账户的核心，包括股份记录、总股份数量和签名能力。
- `SharedAccountEvent` 结构体用于记录与共享账户相关的事件，保存了账户的资源地址。

### 错误常量定义

```rust
    const EACCOUNT_NOT_FOUND: u64 = 0;
    const ERESOURCE_DNE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
```

- 定义了几个常量用于错误处理：账户未找到、资源不存在、余额不足。

### 初始化共享账户

```rust
    public entry fun initialize(source: &signer, seed: vector<u8>, addresses: vector<address>, numerators: vector<u64>) {
        let total = 0;
        let share_record = vector::empty<Share>();

        vector::enumerate_ref(&addresses, |i, addr|{
            let addr = *addr;
            let num_shares = *vector::borrow(&numerators, i);

            // make sure that the account exists, so when we call disperse() it wouldn't fail
            // because one of the accounts does not exist
            assert!(account::exists_at(addr), error::invalid_argument(EACCOUNT_NOT_FOUND));

            vector::push_back(&mut share_record, Share { share_holder: addr, num_shares });
            total = total + num_shares;
        });

        let (resource_signer, resource_signer_cap) = account::create_resource_account(source, seed);

        move_to(
            &resource_signer,
            SharedAccount {
                share_record,
                total_shares: total,
                signer_capability: resource_signer_cap,
            }
        );

        move_to(source, SharedAccountEvent {
            resource_addr: signer::address_of(&resource_signer)
        });
    }
```

- `initialize` 函数用于创建和初始化一个共享账户。
- 它接受签名者 `source`、一个种子 `seed`、账户地址 `addresses` 和相应的股份数 `numerators`。
- 该函数首先确保所有地址存在，然后创建一个资源账户并将共享账户数据移到该资源账户中。
- 同时，将共享账户事件记录在源账户中。

### 分发代币

```rust
    public entry fun disperse<CoinType>(resource_addr: address) acquires SharedAccount {
        assert!(exists<SharedAccount>(resource_addr), error::invalid_argument(ERESOURCE_DNE));

        let total_balance = coin::balance<CoinType>(resource_addr);
        assert!(total_balance > 0, error::out_of_range(EINSUFFICIENT_BALANCE));

        let shared_account = borrow_global<SharedAccount>(resource_addr);
        let resource_signer = account::create_signer_with_capability(&shared_account.signer_capability);

        vector::for_each_ref(&shared_account.share_record, |shared_record|{
            let shared_record: &Share = shared_record;
            let current_amount = shared_record.num_shares * total_balance / shared_account.total_shares;
            coin::transfer<CoinType>(&resource_signer, shared_record.share_holder, current_amount);
        });
    }
```

- `disperse` 函数用于将共享账户中的所有代币分发给指定的地址。
- 它首先检查共享账户是否存在，获取账户中的总余额，并确保余额大于零。
- 然后，根据股份比例将代币分配给每个持股者。

### 测试功能

```rust
    #[test_only]
    public fun set_up(user: signer, test_user1: signer, test_user2: signer) : address acquires SharedAccountEvent {
        let addresses = vector::empty<address>();
        let numerators = vector::empty<u64>();
        let seed = x"01";
        let user_addr = signer::address_of(&user);
        let user_addr1 = signer::address_of(&test_user1);
        let user_addr2 = signer::address_of(&test_user2);

        aptos_framework::aptos_account::create_account(user_addr);
        aptos_framework::aptos_account::create_account(user_addr1);
        aptos_framework::aptos_account::create_account(user_addr2);

        vector::push_back(&mut addresses, user_addr1);
        vector::push_back(&mut addresses, user_addr2);

        vector::push_back(&mut numerators, 1);
        vector::push_back(&mut numerators, 4);

        initialize(&user, seed, addresses, numerators);

        assert!(exists<SharedAccountEvent>(user_addr), error::not_found(EACCOUNT_NOT_FOUND));
        borrow_global<SharedAccountEvent>(user_addr).resource_addr
    }

    #[test(user = @0x1111, test_user1 = @0x1112, test_user2 = @0x1113, core_framework = @aptos_framework)]
    public entry fun test_disperse(user: signer, test_user1: signer, test_user2: signer, core_framework: signer) acquires SharedAccount, SharedAccountEvent {
        use aptos_framework::aptos_coin::{Self, AptosCoin};
        let user_addr1 = signer::address_of(&test_user1);
        let user_addr2 = signer::address_of(&test_user2);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&core_framework);
        let resource_addr = set_up(user, test_user1, test_user2);

        let shared_account = borrow_global<SharedAccount>(resource_addr);
        let resource_signer = account::create_signer_with_capability(&shared_account.signer_capability);
        coin::register<AptosCoin>(&resource_signer);
        coin::deposit(resource_addr, coin::mint(1000, &mint_cap));
        disperse<AptosCoin>(resource_addr);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);
        coin::destroy_burn_cap<AptosCoin>(burn_cap);

        assert!(coin::balance<AptosCoin>(user_addr1) == 200, 0);
        assert!(coin::balance<AptosCoin>(user_addr2) == 800, 1);
    }

    #[test(user = @0x1111, test_user1 = @0x1112, test_user2 = @0x1113)]
    #[expected_failure]
    public entry fun test_disperse_insufficient_balance(user: signer, test_user1: signer, test_user2: signer) acquires SharedAccount, SharedAccountEvent {
        use aptos_framework::aptos_coin::AptosCoin;
        let resource_addr = set_up(user, test_user1, test_user2);
        let shared_account = borrow_global<SharedAccount>(resource_addr);
        let resource_signer = account::create_signer_with_capability(&shared_account.signer_capability);
        coin::register<AptosCoin>(&resource_signer);
        disperse<AptosCoin>(resource_addr);
    }
}
```

- `set_up` 函数用于测试前的准备工作，包括创建用户账户、初始化共享账户等。
- `test_disperse` 函数测试了 `disperse` 函数的正确性，验证代币是否按比例分发。
- `test_disperse_insufficient_balance` 函数用于测试在余额不足的情况下 `disperse` 函数是否正确处理。

