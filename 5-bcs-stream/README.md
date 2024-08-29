# 概述

本模块支持将 BCS 格式的字节数组反序列化为 Move 原生类型。

反序列化策略：
- 按字节反序列化：对大多数类型使用此方法，以确保较低的 gas 消耗，此方法逐个字节处理，以满足目标 Move 类型的长度和类型要求。
- 例外：对于 `deserialize_address` 函数，使用 `aptos_std::from_bcs` 中的基于函数的方法，因为类型限制，尽管这通常更耗 gas。
- 可以通过引入原生向量切片进一步优化。

应用：
- 这个反序列化器在处理 Move 模块中的 BCS 序列化数据时尤其有价值，特别适用于需要跨链消息解释或链下数据验证的系统。

这段代码实现了一个用于从 BCS 格式的字节数组中反序列化 Move 原始类型的模块。

它定义了几种反序列化方法，包括从字节流中读取 u8、u16、u32、u64、u128、u256 等类型的数据。此外，它还包括对 bool、address、String 和 Option 的反序列化。

# 快速开始

## 使用私钥创建账户

```bash
aptos init --network testnet --private-key 0xyour...private...key
```

## 测试

```bash
aptos move test
```

test 命令会先将所有文件中的 `#[test_only]` 变得可见，然后执行所有的 `#[test]`

## 编译和部署

```bash
aptos move compile
aptos move publish
```

# 详解

这段代码定义了一个 `BCSStream` 模块，用于从 BCS 格式的字节数组中反序列化 Move 原始类型。主要包含以下功能：

1. **常量定义**：用于错误处理的常量 
   - `EMALFORMED_DATA`：格式错误的数据 
   - `EOUT_OF_BYTES`：字节不足
2. **数据结构**：`BCSStream` 结构体 
   - `data`：字节缓冲区
   - `cur`：当前指针
3. **构造函数**：`new` 函数
   - 用于初始化 `BCSStream` 实例。
4. **反序列化方法**：即将二进制数据转换为结构化数据
    - `deserialize_uleb128`：从流中反序列化 ULEB128 编码的整数。
    - `deserialize_bool`：从流中反序列化布尔值。
    - `deserialize_address`：从流中反序列化地址（32 字节）。
    - `deserialize_u8`：从流中反序列化 u8（1 字节）。
    - `deserialize_u16`：从流中反序列化 u16（2 字节）。
    - `deserialize_u32`：从流中反序列化 u32（4 字节）。
    - `deserialize_u64`：从流中反序列化 u64（8 字节）。
    - `deserialize_u128`：从流中反序列化 u128（16 字节）。
    - `deserialize_u256`：从流中反序列化 u256（32 字节）。
5. **额外功能**：
    - `deserialize_vector`：反序列化数组，使用指定的元素反序列化函数。
    - `deserialize_string`：反序列化 UTF-8 字符串。
    - `deserialize_option`：反序列化 `Option` 类型，根据布尔值决定是否有数据。

## 中文注释

```move
/// 该模块用于将BCS格式的字节数组反序列化为Move原始类型。
/// 反序列化策略：
/// - 每字节反序列化：用于大多数类型，以确保较低的gas消耗，此方法逐字节处理以匹配目标 Move 类型的长度和类型要求。
/// - 例外：对于`deserialize_address`函数，由于类型约束，使用了`aptos_std::from_bcs`的函数化方法，虽然通常更消耗gas。
/// - 通过引入原生向量切片可以进一步优化。
/// 应用：
/// - 该反序列化器特别适用于在 Move 模块中处理 BCS 序列化数据，特别适合需要跨链消息解释或链下数据验证的系统。
module bcs_stream::bcs_stream {
    use std::error;
    use std::vector;
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use aptos_std::from_bcs;

    /// 数据格式不符合预期。
    const EMALFORMED_DATA: u64 = 1;
    /// 反序列化时字节数不足。
    const EOUT_OF_BYTES: u64 = 2;

    struct BCSStream has drop {
        /// 包含序列化数据的字节缓冲区。
        data: vector<u8>,
        /// 表示当前字节缓冲区位置的游标。
        cur: u64,
    }

    /// 从提供的字节数组构造新的 BCSStream 实例。
    public fun new(data: vector<u8>): BCSStream {
        BCSStream {
            data,
            cur: 0,
        }
    }

    /// 从流中反序列化 ULEB128 编码的整数。
    /// 在BCS格式中，向量的长度使用ULEB128编码表示。
    public fun deserialize_uleb128(stream: &mut BCSStream): u64 {
        let res = 0;
        let shift = 0;

        while (stream.cur < vector::length(&stream.data)) {
            let byte = *vector::borrow(&stream.data, stream.cur);
            stream.cur = stream.cur + 1;

            let val = ((byte & 0x7f) as u64);
            if (((val << shift) >> shift) != val) {
                abort error::invalid_argument(EMALFORMED_DATA)
            };
            res = res | (val << shift);

            if ((byte & 0x80) == 0) {
                if (shift > 0 && val == 0) {
                    abort error::invalid_argument(EMALFORMED_DATA)
                };
                return res
            };

            shift = shift + 7;
            if (shift > 64) {
                abort error::invalid_argument(EMALFORMED_DATA)
            };
        };

        abort error::out_of_range(EOUT_OF_BYTES)
    }

    /// 从流中反序列化一个`bool`值。
    public fun deserialize_bool(stream: &mut BCSStream): bool {
        assert!(stream.cur < vector::length(&stream.data), error::out_of_range(EOUT_OF_BYTES));
        let byte = *vector::borrow(&stream.data, stream.cur);
        stream.cur = stream.cur + 1;
        if (byte == 0) {
            false
        } else if (byte == 1) {
            true
        } else {
            abort error::invalid_argument(EMALFORMED_DATA)
        }
    }

    /// 从流中反序列化一个`address`值。
    /// 32字节的`address`值使用小端字节序列化。
    /// 由于Move类型系统不允许逐字节引用地址，此函数使用`aptos_std::from_bcs`模块中的`to_address`函数。
    public fun deserialize_address(stream: &mut BCSStream): address {
        let data = &stream.data;
        let cur = stream.cur;

        assert!(cur + 32 <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));
        let res = from_bcs::to_address(vector::slice(data, cur, cur + 32));

        stream.cur = cur + 32;
        res
    }

    /// 从流中反序列化一个`u8`值。
    /// 1字节的`u8`值使用小端字节序列化。
    public fun deserialize_u8(stream: &mut BCSStream): u8 {
        let data = &stream.data;
        let cur = stream.cur;

        assert!(cur < vector::length(data), error::out_of_range(EOUT_OF_BYTES));

        let res = *vector::borrow(data, cur);

        stream.cur = cur + 1;
        res
    }

    /// 从流中反序列化一个`u16`值。
    /// 2字节的`u16`值使用小端字节序列化。
    public fun deserialize_u16(stream: &mut BCSStream): u16 {
        let data = &stream.data;
        let cur = stream.cur;

        assert!(cur + 2 <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));
        let res =
            (*vector::borrow(data, cur) as u16) |
                ((*vector::borrow(data, cur + 1) as u16) << 8)
        ;

        stream.cur = stream.cur + 2;
        res
    }

    /// 从流中反序列化一个`u32`值。
    /// 4字节的`u32`值使用小端字节序列化。
    public fun deserialize_u32(stream: &mut BCSStream): u32 {
        let data = &stream.data;
        let cur = stream.cur;

        assert!(cur + 4 <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));
        let res =
            (*vector::borrow(data, cur) as u32) |
                ((*vector::borrow(data, cur + 1) as u32) << 8) |
                ((*vector::borrow(data, cur + 2) as u32) << 16) |
                ((*vector::borrow(data, cur + 3) as u32) << 24)
        ;

        stream.cur = cur + 4;
        res
    }

    /// 从流中反序列化一个`u64`值。
    /// 8字节的`u64`值使用小端字节序列化。
    public fun deserialize_u64(stream: &mut BCSStream): u64 {
        let data = &stream.data;
        let cur = stream.cur;

        assert!(cur + 8 <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));
        let res =
            (*vector::borrow(data, cur) as u64) |
                ((*vector::borrow(data, cur + 1) as u64) << 8) |
                ((*vector::borrow(data, cur + 2) as u64) << 16) |
                ((*vector::borrow(data, cur + 3) as u64) << 24) |
                ((*vector::borrow(data, cur + 4) as u64) << 32) |
                ((*vector::borrow(data, cur + 5) as u64) << 40) |
                ((*vector::borrow(data, cur + 6) as u64) << 48) |
                ((*vector::borrow(data, cur + 7) as u64) << 56)
        ;

        stream.cur = cur + 8;
        res
    }

    /// 从流中反序列化一个 `u128` 值的入口函数。
    /// 16 字节的 `u128` 值使用小端字节序进行序列化。
    public fun deserialize_u128(stream: &mut BCSStream): u128 {
        let data = &stream.data;
        let cur = stream.cur;

        assert!(cur + 16 <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));
        let res =
            (*vector::borrow(data, cur) as u128) |
                ((*vector::borrow(data, cur + 1) as u128) << 8) |
                ((*vector::borrow(data, cur + 2) as u128) << 16) |
                ((*vector::borrow(data, cur + 3) as u128) << 24) |
                ((*vector::borrow(data, cur + 4) as u128) << 32) |
                ((*vector::borrow(data, cur + 5) as u128) << 40) |
                ((*vector::borrow(data, cur + 6) as u128) << 48) |
                ((*vector::borrow(data, cur + 7) as u128) << 56) |
                ((*vector::borrow(data, cur + 8) as u128) << 64) |
                ((*vector::borrow(data, cur + 9) as u128) << 72) |
                ((*vector::borrow(data, cur + 10) as u128) << 80) |
                ((*vector::borrow(data, cur + 11) as u128) << 88) |
                ((*vector::borrow(data, cur + 12) as u128) << 96) |
                ((*vector::borrow(data, cur + 13) as u128) << 104) |
                ((*vector::borrow(data, cur + 14) as u128) << 112) |
                ((*vector::borrow(data, cur + 15) as u128) << 120)
        ;
        // 更新游标位置并返回反序列化结果
        stream.cur = stream.cur + 16;
        res
    }


    /// 从流中反序列化一个 `u256` 值。
    /// 32 字节的 `u256` 值使用小端字节序进行序列化。
    public fun deserialize_u256(stream: &mut BCSStream): u256 {
        let data = &stream.data;  // 获取数据流
        let cur = stream.cur;     // 获取当前游标位置

        // 确保剩余数据长度足够读取 32 字节
        assert!(cur + 32 <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));

        // 逐字节读取数据并构建 u256 值
        let res =
            (*vector::borrow(data, cur) as u256) |
                ((*vector::borrow(data, cur + 1) as u256) << 8) |
                ((*vector::borrow(data, cur + 2) as u256) << 16) |
                ((*vector::borrow(data, cur + 3) as u256) << 24) |
                ((*vector::borrow(data, cur + 4) as u256) << 32) |
                ((*vector::borrow(data, cur + 5) as u256) << 40) |
                ((*vector::borrow(data, cur + 6) as u256) << 48) |
                ((*vector::borrow(data, cur + 7) as u256) << 56) |
                ((*vector::borrow(data, cur + 8) as u256) << 64) |
                ((*vector::borrow(data, cur + 9) as u256) << 72) |
                ((*vector::borrow(data, cur + 10) as u256) << 80) |
                ((*vector::borrow(data, cur + 11) as u256) << 88) |
                ((*vector::borrow(data, cur + 12) as u256) << 96) |
                ((*vector::borrow(data, cur + 13) as u256) << 104) |
                ((*vector::borrow(data, cur + 14) as u256) << 112) |
                ((*vector::borrow(data, cur + 15) as u256) << 120) |
                ((*vector::borrow(data, cur + 16) as u256) << 128) |
                ((*vector::borrow(data, cur + 17) as u256) << 136) |
                ((*vector::borrow(data, cur + 18) as u256) << 144) |
                ((*vector::borrow(data, cur + 19) as u256) << 152) |
                ((*vector::borrow(data, cur + 20) as u256) << 160) |
                ((*vector::borrow(data, cur + 21) as u256) << 168) |
                ((*vector::borrow(data, cur + 22) as u256) << 176) |
                ((*vector::borrow(data, cur + 23) as u256) << 184) |
                ((*vector::borrow(data, cur + 24) as u256) << 192) |
                ((*vector::borrow(data, cur + 25) as u256) << 200) |
                ((*vector::borrow(data, cur + 26) as u256) << 208) |
                ((*vector::borrow(data, cur + 27) as u256) << 216) |
                ((*vector::borrow(data, cur + 28) as u256) << 224) |
                ((*vector::borrow(data, cur + 29) as u256) << 232) |
                ((*vector::borrow(data, cur + 30) as u256) << 240) |
                ((*vector::borrow(data, cur + 31) as u256) << 248)
        ;

        // 更新游标位置并返回反序列化结果
        stream.cur = stream.cur + 32;
        res
    }

    /// 从流中反序列化一个 `u256` 值的入口函数。
    /// 32 字节的 `u256` 值使用小端字节序进行序列化。
    public entry fun deserialize_u256_entry(data: vector<u8>, cursor: u64) {
        let stream = BCSStream {
            data: data,
            cur: cursor,
        };
        deserialize_u256(&mut stream);
    }

    /// 从流中反序列化一个 BCS 可反序列化的元素数组。
    /// 首先读取长度（以 uleb128 格式存储），然后读取向量的内容。
    /// `elem_deserializer` 是用于逐个反序列化向量元素的函数。
    public inline fun deserialize_vector<E>(stream: &mut BCSStream, elem_deserializer: |&mut BCSStream| E): vector<E> {
        let len = deserialize_uleb128(stream);  // 读取向量长度
        let v = vector::empty();                // 创建一个空向量

        let i = 0;
        while (i < len) {
            vector::push_back(&mut v, elem_deserializer(stream));  // 逐个反序列化元素并添加到向量
            i = i + 1;
        };

        v
    }

    /// 从流中反序列化 utf-8 编码的 `String`。
    /// 首先读取字符串长度（以 uleb128 格式存储），然后读取字符串内容。
    public fun deserialize_string(stream: &mut BCSStream): String {
        let len = deserialize_uleb128(stream);  // 读取字符串长度
        let data = &stream.data;                // 获取数据流
        let cur = stream.cur;                  // 获取当前游标位置

        // 确保剩余数据长度足够读取指定长度的字符串
        assert!(cur + len <= vector::length(data), error::out_of_range(EOUT_OF_BYTES));

        // 读取字符串并更新游标位置
        let res = string::utf8(vector::slice(data, cur, cur + len));
        stream.cur = cur + len;

        res
    }

    /// 从流中反序列化一个 `Option` 值。
    /// 首先读取一个字节，表示是否有数据（0x01 表示有数据，0x00 表示没有数据）。
    /// 如果有数据，则读取实际数据；否则返回 `None`。
    public inline fun deserialize_option<E>(stream: &mut BCSStream, elem_deserializer: |&mut BCSStream| E): Option<E> {
        let is_data = deserialize_bool(stream);  // 读取数据是否存在的标志
        if (is_data) {
            option::some(elem_deserializer(stream))  // 如果有数据，则反序列化并返回 `Some`
        } else {
            option::none()  // 如果没有数据，则返回 `None`
        }
    }
}
```
