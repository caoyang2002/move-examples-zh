# 概述

创建和管理共享资源账户，并允许其他账户使用这些资源的签名能力。

# 快速开始

## 使用私钥创建账户

```bash
aptos init --network testnet --private-key 0xyour...private...key
```

## 测试

```bash
aptos move test
```

## 编译和部署

```bash
aptos move compile
aptos move publish
```

# 详解

## 中文注释

```move
/// 这是一个用于在多个账户之间共享单一资源账户的框架。 
/// 它创建一个资源账户，并允许其他指定的账户生成该资源账户的签名者。
/// 具体来说，创建者可以添加和移除能够访问该资源账户签名者的新账户。
module common_account::common_account {
    use std::error;
    use std::signer;

    use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::account::{Self, SignerCapability};

    /// 错误码：未找到管理资源的权限
    const ENO_MANAGEMENT_RESOURCE_FOUND: u64 = 1;
    /// 错误码：未找到共享账户
    const ENO_ACCOUNT_RESOURCE_FOUND: u64 = 2;
    /// 错误码：未找到管理权限的能力
    const ENO_CAPABILITY_FOUND: u64 = 3;
    /// 错误码：未提供能力
    const ENO_CAPABILITY_OFFERED: u64 = 4;
    /// 错误码：签名者不是管理员
    const ENOT_ADMIN: u64 = 5;
    /// 错误码：在能力中找到了与预期不同的地址
    const EUNEXPECTED_PARALLEL_ACCOUNT: u64 = 6;

    /// 包含生成共享账户签名者的签名能力。
    struct CommonAccount has key {
        signer_cap: SignerCapability, // 签名能力
    }

    struct Empty has drop, store {}

    /// 包含管理账户的元数据，特别是管理方面。
    struct Management has key {
        /// 能够添加和移除可以控制该账户的实体。
        admin: address, // 管理员地址
        /// 定义具有可用但未声明的能力控制该账户的实体的 ACL。
        unclaimed_capabilities: SimpleMap<address, Empty>, // 未声明的能力映射
    }

    /// 可撤销的能力，存储在用户账户上。
    struct Capability has drop, key {
        common_account: address, // 共享账户地址
    }

    /// 创建一个新的共享账户，创建一个资源账户并存储能力。
    public entry fun create(sender: &signer, seed: vector<u8>) {
        let (resource_signer, signer_cap) = account::create_resource_account(sender, seed);

        move_to(
            &resource_signer,
            Management {
                admin: signer::address_of(sender),
                unclaimed_capabilities: simple_map::create(),
            },
        );

        move_to(&resource_signer, CommonAccount { signer_cap });
    }

    /// 将其他账户添加到可以领取此共享账户能力的账户列表中。
    public entry fun add_account(
        sender: &signer,
        common_account: address,
        other: address,
    ) acquires Management {
        let management = assert_is_admin(sender, common_account);
        simple_map::add(&mut management.unclaimed_capabilities, other, Empty {});
    }

    /// 从管理组中移除一个账户。
    public entry fun remove_account(
        admin: &signer,
        common_account: address,
        other: address,
    ) acquires Capability, Management {
        let management = assert_is_admin(admin, common_account);
        if (simple_map::contains_key(&management.unclaimed_capabilities, &other)) {
            simple_map::remove(&mut management.unclaimed_capabilities, &other);
        } else {
            assert!(exists<Capability>(other), error::not_found(ENO_CAPABILITY_FOUND));
            move_from<Capability>(other);
        }
    }

    /// 获取使用共享账户签名能力的能力。
    public entry fun acquire_capability(
        sender: &signer,
        common_account: address,
    ) acquires Management {
        let sender_addr = signer::address_of(sender);

        let management = borrow_management(common_account);
        assert!(
            simple_map::contains_key(&management.unclaimed_capabilities, &sender_addr),
            error::not_found(ENO_CAPABILITY_OFFERED),
        );
        simple_map::remove(&mut management.unclaimed_capabilities, &sender_addr);

        move_to(sender, Capability { common_account });
    }

    /// 如果权限允许，生成共享账户的签名者。
    public fun acquire_signer(
        sender: &signer,
        common_account: address,
    ): signer acquires Capability, CommonAccount, Management {
        let sender_addr = signer::address_of(sender);
        if (!exists<Capability>(sender_addr)) {
            acquire_capability(sender, common_account)
        };
        let capability = borrow_global<Capability>(sender_addr);

        assert!(
            capability.common_account == common_account,
            error::invalid_state(EUNEXPECTED_PARALLEL_ACCOUNT),
        );

        let resource = borrow_global<CommonAccount>(common_account);
        account::create_signer_with_capability(&resource.signer_cap)
    }

    /// 确认管理员权限。
    inline fun assert_is_admin(admin: &signer, common_account: address): &mut Management {
        let management = borrow_management(common_account);
        assert!(
            signer::address_of(admin) == management.admin,
            error::permission_denied(ENOT_ADMIN),
        );
        management
    }

    /// 借用管理结构体。
    inline fun borrow_management(common_account: address): &mut Management {
        assert!(
            exists<Management>(common_account),
            error::not_found(ENO_MANAGEMENT_RESOURCE_FOUND),
        );
        borrow_global_mut<Management>(common_account)
    }

    // 测试相关的代码段
    #[test_only]
    use std::vector;

    // 结合测试的端到端测试函数
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    public fun test_end_to_end(
        alice: &signer,
        bob: &signer,
    ) acquires Capability, Management, CommonAccount {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        create(alice, vector::empty());
        add_account(alice, common_addr, bob_addr);
        acquire_capability(bob, common_addr);
        let common = acquire_signer(bob, common_addr);
        assert!(signer::address_of(&common) == common_addr, 0);
    }

    // 测试：没有账户能力的情况
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    #[expected_failure(abort_code = 0x60001, location = Self)]
    public fun test_no_account_capability(
        alice: &signer,
        bob: &signer,
    ) acquires Management {
        let alice_addr = signer::address_of(alice);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        acquire_capability(bob, common_addr);
    }

    // 测试：没有账户签名者的情况
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    #[expected_failure(abort_code = 0x60001, location = Self)]
    public fun test_no_account_signer(
        alice: &signer,
        bob: &signer,
    ) acquires Capability, CommonAccount, Management {
        let alice_addr = signer::address_of(alice);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        acquire_signer(bob, common_addr);
    }

    // 测试：没有账户能力的情况
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    #[expected_failure(abort_code = 0x60004, location = Self)]
    public fun test_account_no_capability(
        alice: &signer,
        bob: &signer,
    ) acquires Management {
        let alice_addr = signer::address_of(alice);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        create(alice, vector::empty());
        acquire_capability(bob, common_addr);
    }

    // 测试：撤销账户时没有权限的情况
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    #[expected_failure(abort_code = 0x60003, location = Self)]
    public fun test_account_revoke_none(
        alice: &signer,
        bob: &signer,
    ) acquires Capability, Management {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        create(alice, vector::empty());
        remove_account(alice, common_addr, bob_addr);
    }

    // 测试：撤销账户的能力
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    public fun test_account_revoke_capability(
        alice: &signer,
        bob: &signer,
    ) acquires Capability, Management {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        create(alice, vector::empty());
        add_account(alice, common_addr, bob_addr);
        acquire_capability(bob, common_addr);
        remove_account(alice, common_addr, bob_addr);
    }

    // 测试：撤销 ACL 的账户
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    public fun test_account_revoke_acl(
        alice: &signer,
        bob: &signer,
    ) acquires Capability, Management {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        create(alice, vector::empty());
        add_account(alice, common_addr, bob_addr);
        remove_account(alice, common_addr, bob_addr);
    }

    // 测试：错误的管理员权限
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    #[expected_failure(abort_code = 0x50005, location = Self)]
    public fun test_wrong_admin(
        alice: &signer,
        bob: &signer,
    ) acquires Management {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let common_addr = account::create_resource_address(&alice_addr, vector::empty());

        create(alice, vector::empty());
        add_account(bob, common_addr, bob_addr);
    }

    // 测试：错误的能力
    #[test(alice = @0xa11c3, bob = @0xb0b)]
    #[expected_failure(abort_code = 0x30006, location = Self)]
    public fun test_wrong_cap(
        alice: &signer,
        bob: &signer,
    ) acquires Capability, Management, CommonAccount {
        let alice_addr = signer::address_of(alice);
        let bob_addr = signer::address_of(bob);
        let alice_common_addr = account::create_resource_address(&alice_addr, vector::empty());
        let bob_common_addr = account::create_resource_address(&bob_addr, vector::empty());

        create(alice, vector::empty());
        create(bob, vector::empty());
        add_account(alice, alice_common_addr, bob_addr);
        acquire_capability(bob, alice_common_addr);
        acquire_signer(bob, bob_common_addr);
    }
}

```