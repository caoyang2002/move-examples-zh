# 概述

这段代码演示了如何在 Move 语言中定义一个资源类型，如何操作这个资源，以及如何处理不存在的情况。


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

## 交互

打开区块链浏览器
选择 `set_number` 设置数字 `8`, `16`, `32`, `64`, `128`, `256`, `[ 2, 3, 4, 5 ]`
选择 `get_number` 在 `address` 处输入账户地址，将显示该账户下被设置的数


# 详解

## 中文注释解释：

1. **模块定义**：
    - `module deploy_address::number`：定义了一个模块 `deploy_address::number`。

2. **资源定义**：
    - `struct NumberHolder has key`：定义了一个资源结构体 `NumberHolder`，该结构体有 7 个字段，分别是 `u8`、`u16`、`u32`、`u64`、`u128`、`u256` 和 `vec_u256`（一个 `u256` 类型的向量）。`has key` 表示这个资源类型是可以被键控的（即可以作为存储在链上的资源）。

3. **常量定义**：
    - `const ENOT_INITIALIZED: u64 = 0`：定义了一个常量 `ENOT_INITIALIZED`，表示资源未初始化时的错误码。

4. **视图函数 `get_number`**：
    - `#[view]`：标记这是一个视图函数，它不会修改区块链上的状态。
    - `get_number(addr: address)`：根据给定的地址 `addr` 获取 `NumberHolder` 资源，并返回其中的字段值。如果 `NumberHolder` 不存在，则触发 `error::not_found` 错误。

5. **入口函数 `set_number`**：
    - `public entry fun set_number(...)`：这是一个入口函数，用于设置 `NumberHolder` 的字段值。
    - `acquires NumberHolder`：表示这个函数将获得 `NumberHolder` 资源的控制权。
    - `if (!exists<NumberHolder>(account_addr))`：如果 `NumberHolder` 在指定的地址上不存在，则创建一个新的实例并将其移动到该地址。
    - `else`：如果 `NumberHolder` 已存在，则借用它并更新其字段的值。

## 中文注释

```move
module deploy_address::number {
    use std::error;
    use std::signer;

    // 定义一个资源类型 NumberHolder，作为数据持有者
    // 这个资源有 7 个字段，分别是 u8, u16, u32, u64, u128, u256 和一个 u256 的向量
    struct NumberHolder has key {
        u8: u8,
        u16: u16,
        u32: u32,
        u64: u64,
        u128: u128,
        u256: u256,
        vec_u256: vector<u256>,
    }

    /// 常量 ENOT_INITIALIZED，用于表示没有初始化的错误码
    const ENOT_INITIALIZED: u64 = 0;

    /// 视图函数 get_number
    /// 通过地址获取 NumberHolder 结构体中的各个字段
    #[view]
    public fun get_number(addr: address): (u8, u16, u32, u64, u128, u256, vector<u256>) acquires NumberHolder {
        // 确保指定地址的 NumberHolder 存在
        assert!(exists<NumberHolder>(addr), error::not_found(ENOT_INITIALIZED));
        
        // 借用指定地址的 NumberHolder 实例
        let holder = borrow_global<NumberHolder>(addr);

        // 返回 NumberHolder 中的各个字段
        (holder.u8, holder.u16, holder.u32, holder.u64, holder.u128, holder.u256, holder.vec_u256)
    }

    /// 入口函数 set_number
    /// 设置 NumberHolder 结构体的字段值
    public entry fun set_number(
        account: signer,
        u8: u8,
        u16: u16,
        u32: u32,
        u64: u64,
        u128: u128,
        u256: u256,
        vec_u256: vector<u256>)
    acquires NumberHolder {
        // 获取签名账户的地址
        let account_addr = signer::address_of(&account);

        // 如果指定地址的 NumberHolder 不存在，则创建一个新的
        if (!exists<NumberHolder>(account_addr)) {
            move_to(&account, NumberHolder {
                u8,
                u16,
                u32,
                u64,
                u128,
                u256,
                vec_u256,
            })
        } else {
            // 如果 NumberHolder 已经存在，则更新它的各个字段
            let old_holder = borrow_global_mut<NumberHolder>(account_addr);
            old_holder.u8 = u8;
            old_holder.u16 = u16;
            old_holder.u32 = u32;
            old_holder.u64 = u64;
            old_holder.u128 = u128;
            old_holder.u256 = u256;
            old_holder.vec_u256 = vec_u256;
        }
    }
}
```
