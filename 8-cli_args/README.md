# 概述

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

### 模块定义和导入

- `Holder` 结构体定义了一个持有者的数据结构，包含了多种字段
  - `u8_solo`（单个 `u8` 类型）
  - `bytes`（`u8` 类型的向量）
  - `utf8_string`（UTF-8 编码的字符串）
  - `bool_vec`（布尔类型的向量）
  - `address_vec_vec`（`address` 类型的向量的向量）
  - `type_info_1`
  - `type_info_2`（`TypeInfo` 类型的字段）
  
- `set_vals` 函数是一个公共入口函数（`public entry fun`），用于设置 `Holder` 中的字段值。它接收一个 `signer` 类型的账户 `account`，以及其他各种字段的值，并且在执行时获取（`acquires`） `Holder` 类型的所有权。

- `reveal` 函数被声明为一个视图函数（`#[view]`），这表示它只会读取状态而不会修改它。它接收一个 `address` 类型的参数 `host`，并返回 `RevealResult` 类型的结果，同样在执行时获取（`acquires`） `Holder` 类型的所有权。


- `RevealResult` 结构体定义了一个结果类型，包含了与 `Holder` 结构体中相同的字段，以及额外的 `type_info_1_match` 和 `type_info_2_match` 字段，用于表示 `T1` 和 `T2` 是否与 `Holder` 中对应的 `type_info` 匹配。

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