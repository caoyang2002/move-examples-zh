# 快速开始

```bash
aptos move test
```

# 解析

该模块允许发布到资源账户并保留对其签名者的控制，以便将来进行升级或用于其他目的，例如创建 NFT 集合。它还提供了管理对象和资源账户地址的功能，以便这些地址可以轻松地在其他模块中访问。

部署流程如下：

1. 使用 Aptos CLI 命令 `create-resource-and-publish-package` 部署包含此 package_manager 模块的包，并使用适当的种子。这将创建一个资源账户并部署模块。还需要在 Move.toml 中指定部署者地址。
2. 确保在 Move.toml 中持久化创建的资源地址，以便将来部署和升级，因为 CLI 默认不会这样做。
3. 在部署期间，将调用 package_manager::init_module 并从新创建的资源账户中提取 SignerCapability。
4. 同一包中的朋友模块可以调用 package_manager 来在需要时获取资源账户签名者。如果需要跨包访问，可以通过基于地址的白名单授权，而不是仅限于同一包内的友谊。
5. 如果需要部署新模块或更新此包中的现有模块，指定的管理员账户（默认为部署者账户）可以调用 package_manager::publish_package 来发布新代码。

```move
/// 其他模块可以通过调用 add_address 或 get_address 来存储和获取存储的地址。这对于存储同一包中的其他模块的地址或系统地址（如 NFT 集合）非常有用。
module package::package_manager {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::resource_account;
    use aptos_std::smart_table::{Self, SmartTable};
    use std::string::String;

    /// 存储用于控制资源账户的权限配置，例如 SignerCapability。
    struct PermissionConfig has key {
        /// 需要获取资源账户签名者。
        signer_cap: SignerCapability,
        /// 跟踪此包中模块创建的地址。
        addresses: SmartTable<String, address>,
    }

    /// 初始化 PermissionConfig 以建立对资源账户的控制。
    /// 此函数仅在首次部署此包时调用。
    fun init_module(package_signer: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(package_signer, @deployer);
        move_to(package_signer, PermissionConfig {
            addresses: smart_table::new<String, address>(),
            signer_cap,
        });
    }

    /// 可以被朋友模块调用以获取资源账户签名者。
    public(friend) fun get_signer(): signer acquires PermissionConfig {
        let signer_cap = &borrow_global<PermissionConfig>(@package).signer_cap;
        account::create_signer_with_capability(signer_cap)
    }

    /// 可以被朋友模块调用以跟踪系统地址。
    public(friend) fun add_address(name: String, object: address) acquires PermissionConfig {
        let addresses = &mut borrow_global_mut<PermissionConfig>(@package).addresses;
        smart_table::add(addresses, name, object);
    }

    public fun address_exists(name: String): bool acquires PermissionConfig {
        smart_table::contains(&safe_permission_config().addresses, name)
    }

    public fun get_address(name: String): address acquires PermissionConfig {
        let addresses = &borrow_global<PermissionConfig>(@package).addresses;
        *smart_table::borrow(addresses, name)
    }

    inline fun safe_permission_config(): &PermissionConfig acquires PermissionConfig {
        borrow_global<PermissionConfig>(@package)
    }

    #[test_only]
    public fun initialize_for_test(deployer: &signer) {
        let deployer_addr = std::signer::address_of(deployer);
        if (!exists<PermissionConfig>(deployer_addr)) {
            aptos_framework::timestamp::set_time_has_started_for_testing(&account::create_signer_for_test(@0x1));

            account::create_account_for_test(deployer_addr);
            move_to(deployer, PermissionConfig {
                addresses: smart_table::new<String, address>(),
                signer_cap: account::create_test_signer_cap(deployer_addr),
            });
        };
    }

    #[test_only]
    friend package::package_manager_tests;
}
```