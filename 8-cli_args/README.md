# 概述

在 Move 语言中定义和操作包含复杂数据结构的资源账户 Holder。通过公共入口函数 set_vals 可以设置 Holder 中各个字段的值，并使用 reveal 视图函数可以读取 Holder 中的内容及其类型信息。这种设计适合在区块链应用中管理和操作包含多种类型数据的资源。

# 快速开始

## 使用私钥创建账户

```bash
aptos init --network testnet --private-key 0xyour...private...key
```

## 测试

```bash
aptos move test
```

# 详解

这段代码展示了如何在 Move 语言中定义一个模块，用于管理包含复杂数据结构的资源账户 `Holder`。以下是代码的详细解释：

### 模块声明和依赖项

```move
// :!:>resource
module test_account::cli_args {
    use std::signer;
    use aptos_std::type_info::{Self, TypeInfo};
    use std::string::String;
```

- `test_account::cli_args` 是一个模块的声明。
- `use std::signer;` 引入了标准库中的 `signer` 模块，用于处理账户签名者的相关操作。
- `use aptos_std::type_info::{Self, TypeInfo};` 引入了 `aptos_std` 中的 `type_info` 模块，用于获取类型信息。
- `use std::string::String;` 引入了标准库中的 `String` 类型。

### 资源结构体定义 `Holder`

```move
    struct Holder has key, drop {
        u8_solo: u8,
        bytes: vector<u8>,
        utf8_string: String,
        bool_vec: vector<bool>,
        address_vec_vec: vector<vector<address>>,
        type_info_1: TypeInfo,
        type_info_2: TypeInfo,
    } //<:!:resource
```

- `Holder` 结构体被标记为 `has key, drop`，表明它是一个具有键和生命周期管理的资源。
- `u8_solo` 是一个 `u8` 类型的单值。
- `bytes` 是一个存储 `u8` 类型的向量。
- `utf8_string` 是一个 `String` 类型的 UTF-8 字符串。
- `bool_vec` 是一个存储 `bool` 类型的向量。
- `address_vec_vec` 是一个存储 `address` 向量的向量。
- `type_info_1` 和 `type_info_2` 是 `TypeInfo` 类型的字段，用于存储 `T1` 和 `T2` 的类型信息。

### 设置函数 `set_vals`

```move
    // :!:>setter
    /// Set values in a `Holder` under `account`.
    public entry fun set_vals<T1, T2>(
        account: signer,
        u8_solo: u8,
        bytes: vector<u8>,
        utf8_string: String,
        bool_vec: vector<bool>,
        address_vec_vec: vector<vector<address>>,
    ) acquires Holder {
        let account_addr = signer::address_of(&account);
        if (exists<Holder>(account_addr)) {
            move_from<Holder>(account_addr);
        };
        move_to(&account, Holder {
            u8_solo,
            bytes,
            utf8_string,
            bool_vec,
            address_vec_vec,
            type_info_1: type_info::type_of<T1>(),
            type_info_2: type_info::type_of<T2>(),
        });
    } //<:!:setter
```

- `set_vals` 是一个公共入口函数，用于在 `Holder` 中设置各种类型的值。
- `account: signer` 参数指定了账户的签名者。
- 函数使用 `acquires Holder` 语句表明它会获取 `Holder` 的资源。
- 如果指定账户已经存在 `Holder` 资源，使用 `move_from<Holder>(account_addr)` 将其移除。
- 使用 `move_to(&account, Holder { ... })` 将新的 `Holder` 结构体移动到指定账户下：
  - 将各种字段值赋给 `Holder` 结构体，包括 `u8_solo`、`bytes`、`utf8_string`、`bool_vec`、`address_vec_vec`。
  - 使用 `type_info::type_of<T1>()` 和 `type_info::type_of<T2>()` 获取 `T1` 和 `T2` 的类型信息，并赋给 `type_info_1` 和 `type_info_2`。

### 查看函数 `reveal`

```move
    // :!:>view
    struct RevealResult has drop {
        u8_solo: u8,
        bytes: vector<u8>,
        utf8_string: String,
        bool_vec: vector<bool>,
        address_vec_vec: vector<vector<address>>,
        type_info_1_match: bool,
        type_info_2_match: bool
    }

    #[view]
    /// Pack into a `RevealResult` the first three fields in host's
    /// `Holder`, as well as two `bool` flags denoting if `T1` & `T2`
    /// respectively match `Holder.type_info_1` & `Holder.type_info_2`,
    /// then return the `RevealResult`.
    public fun reveal<T1, T2>(host: address): RevealResult acquires Holder {
        let holder_ref = borrow_global<Holder>(host);
        RevealResult {
            u8_solo: holder_ref.u8_solo,
            bytes: holder_ref.bytes,
            utf8_string: holder_ref.utf8_string,
            bool_vec: holder_ref.bool_vec,
            address_vec_vec: holder_ref.address_vec_vec,
            type_info_1_match:
                type_info::type_of<T1>() == holder_ref.type_info_1,
            type_info_2_match:
                type_info::type_of<T2>() == holder_ref.type_info_2
        }
    }
```

- `RevealResult` 结构体用于存储从 `Holder` 中提取的字段值及其类型匹配信息。
- `reveal<T1, T2>(host: address)` 是一个视图函数（`#[view]` 标注），用于读取 `Holder` 的内容。
- 使用 `borrow_global<Holder>(host)` 获取 `host` 地址下的 `Holder` 引用。
- 构建一个 `RevealResult` 结构体：
  - 将 `Holder` 中的 `u8_solo`、`bytes`、`utf8_string`、`bool_vec`、`address_vec_vec` 字段值分别赋给 `RevealResult` 的对应字段。
  - 使用 `type_info::type_of<T1>() == holder_ref.type_info_1` 和 `type_info::type_of<T2>() == holder_ref.type_info_2` 分别检查 `T1` 和 `T2` 是否与 `Holder` 中存储的类型信息匹配。


# 中文注释

```move
// :!:>resource
module test_account::cli_args {
    use std::signer; // 导入标准库中的 signer 模块
    use aptos_std::type_info::{Self, TypeInfo}; // 导入 aptos_std 库中的 type_info 模块的 Self 和 TypeInfo
    use std::string::String; // 导入标准库中的 String 类型

    // 定义 Holder 结构体
    struct Holder has key, drop {
        u8_solo: u8, // 单个 u8 类型字段
        bytes: vector<u8>, // u8 类型的向量字段
        utf8_string: String, // UTF-8 编码的字符串字段
        bool_vec: vector<bool>, // 布尔类型的向量字段
        address_vec_vec: vector<vector<address>>, // address 类型的向量的向量字段
        type_info_1: TypeInfo, // 类型信息字段 1
        type_info_2: TypeInfo, // 类型信息字段 2
    } //<:!:resource


    // :!:>setter
    /// 在 `Holder` 中为 `account` 设置值。
    public entry fun set_vals<T1, T2>(
        account: signer, // 账户参数，类型为 signer
        u8_solo: u8, // u8 类型的单值参数
        bytes: vector<u8>, // u8 类型的向量参数
        utf8_string: String, // UTF-8 编码的字符串参数
        bool_vec: vector<bool>, // 布尔类型的向量参数
        address_vec_vec: vector<vector<address>>, // address 类型的向量的向量参数
    ) acquires Holder {
        let account_addr = signer::address_of(&account); // 获取账户的地址
        if (exists<Holder>(account_addr)) { // 如果 Holder 在指定地址上已存在
            move_from<Holder>(account_addr); // 从指定地址移出 Holder
        };
        move_to(&account, Holder { // 将新的 Holder 移入到指定账户地址
            u8_solo, // 设置 u8_solo 字段
            bytes, // 设置 bytes 字段
            utf8_string, // 设置 utf8_string 字段
            bool_vec, // 设置 bool_vec 字段
            address_vec_vec, // 设置 address_vec_vec 字段
            type_info_1: type_info::type_of<T1>(), // 设置 type_info_1 字段为 T1 的类型信息
            type_info_2: type_info::type_of<T2>(), // 设置 type_info_2 字段为 T2 的类型信息
        });
    } //<:!:setter

    // :!:>view
    // 定义 RevealResult 结构体
    struct RevealResult has drop {
        u8_solo: u8, // 单个 u8 类型字段
        bytes: vector<u8>, // u8 类型的向量字段
        utf8_string: String, // UTF-8 编码的字符串字段
        bool_vec: vector<bool>, // 布尔类型的向量字段
        address_vec_vec: vector<vector<address>>, // address 类型的向量的向量字段
        type_info_1_match: bool, // 类型信息 1 匹配标志
        type_info_2_match: bool // 类型信息 2 匹配标志
    }

    #[view]
    /// 将 Holder 中的前三个字段打包到 RevealResult 中，
    /// 并返回两个布尔标志，表示 T1 和 T2 是否分别与 Holder.type_info_1 和 Holder.type_info_2 匹配。
    public fun reveal<T1, T2>(host: address): RevealResult acquires Holder {
        let holder_ref = borrow_global<Holder>(host); // 获取 Holder 在指定地址上的借用引用
        RevealResult {
            u8_solo: holder_ref.u8_solo, // 设置 u8_solo 字段
            bytes: holder_ref.bytes, // 设置 bytes 字段
            utf8_string: holder_ref.utf8_string, // 设置 utf8_string 字段
            bool_vec: holder_ref.bool_vec, // 设置 bool_vec 字段
            address_vec_vec: holder_ref.address_vec_vec, // 设置 address_vec_vec 字段
            type_info_1_match: type_info::type_of<T1>() == holder_ref.type_info_1, // 检查 T1 是否与 Holder 中的 type_info_1 匹配
            type_info_2_match: type_info::type_of<T2>() == holder_ref.type_info_2 // 检查 T2 是否与 Holder 中的 type_info_2 匹配
        }
    }

} //<:!:view

```