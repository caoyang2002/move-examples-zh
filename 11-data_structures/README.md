# 概述

这段代码是一个基于双向链表实现的可迭代表（Iterable Table）模块，用于管理键值对数据结构的操作。

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

这段代码是一个基于双向链表实现的可迭代表（Iterable Table）模块，用于管理键值对数据结构的操作。让我们逐步解释每个部分的功能和设计：

## 模块声明和依赖

```move
module aptos_std::iterable_table {
    use std::option::{Self, Option};  // 使用标准库中的 Option 类型
    use aptos_std::table_with_length::{Self, TableWithLength};  // 使用 TableWithLength 模块
}
```

- `aptos_std::iterable_table` 是这个模块的命名空间。
- `std::option::Option` 是用来处理可能为空的值的标准库类型。
- `aptos_std::table_with_length::TableWithLength` 是一个具有长度信息的表格类型，这个模块似乎建立在它的基础上。

## 数据结构定义

```move
struct IterableValue<K: copy + store + drop, V: store> has store {
    val: V,
    prev: Option<K>,
    next: Option<K>,
}
```

- `IterableValue` 结构体用于包装存储在表中的值 `val`，同时记录前驱 `prev` 和后继 `next` 的键（Key）。这样的设计是为了支持双向链表的操作。

```move
struct IterableTable<K: copy + store + drop, V: store> has store {
    inner: TableWithLength<K, IterableValue<K, V>>,
    head: Option<K>,
    tail: Option<K>,
}
```

- `IterableTable` 结构体实现了一个可迭代表，内部包含了一个 `TableWithLength` 实例 `inner`，用于存储 `K` 类型的键和 `IterableValue<K, V>` 类型的值。
- `head` 和 `tail` 分别指向表头和表尾的键，支持快速迭代和插入操作。

## 表操作函数

接下来是一系列操作函数，用于对 `IterableTable` 进行常见的增删改查操作，以及支持迭代器的操作：

- `new`: 创建一个空的 `IterableTable` 实例。
- `destroy_empty`: 销毁一个空的表格实例。
- `add`: 向表格中添加新的条目，如果键已存在则中止操作。
- `remove`: 从表格中移除指定键的条目，并返回其对应的值。
- `borrow` 和 `borrow_mut`: 获取指定键的值的不可变和可变引用。
- `length` 和 `empty`: 返回表格的长度和是否为空。
- `contains`: 判断表格是否包含指定的键。

## 迭代器操作函数

- `head_key` 和 `tail_key`: 返回表格的头部和尾部键，用于迭代操作。
- `borrow_iter` 和 `borrow_iter_mut`: 获取指定键对应的 `IterableValue` 的不可变和可变引用，包括其值和前驱后继键。
- `remove_iter`: 移除指定键对应的条目，并返回其值和前驱后继键。

## 测试函数

最后，代码还包括一个测试函数 `iterable_table_test`，用于验证 `IterableTable` 模块的功能和正确性。

## 数据结构

可迭代的包装器围绕值，如果存在，指向前一个和下一个键。

```rust
/// The iterable wrapper around value, points to previous and next key if any.
struct IterableValue<K: copy + store + drop, V: store> has store {
    val: V,
    prev: Option<K>,
    next: Option<K>,
}
```


基于双向链表的可迭代表实现。

```
/// An iterable table implementation based on double linked list.
struct IterableTable<K: copy + store + drop, V: store> has store {
    inner: TableWithLength<K, IterableValue<K, V>>,
    head: Option<K>,
    tail: Option<K>,
}
```

创建一个空的表

```
/// Regular table API.

/// Create an empty table.
public fun new<K: copy + store + drop, V: store>(): IterableTable<K, V> {
    IterableTable {
        inner: table_with_length::new(),
        head: option::none(),
        tail: option::none(),
    }
}
```

销毁一个表。要成功，表必须是空的。

```
/// Destroy a table. The table must be empty to succeed.
public fun destroy_empty<K: copy + store + drop, V: store>(table: IterableTable<K, V>) {
    assert!(empty(&table), 0);
    assert!(option::is_none(&table.head), 0);
    assert!(option::is_none(&table.tail), 0);
    let IterableTable {inner, head: _, tail: _} = table;
    table_with_length::destroy_empty(inner);
}
```

向表中添加一个新的条目。如果这个键的条目已经存在，则会中止。

```
/// Add a new entry to the table. Aborts if an entry for this
/// key already exists.
public fun add<K: copy + store + drop, V: store>(table: &mut IterableTable<K, V>, key: K, val: V) {
    let wrapped_value = IterableValue {
        val,
        prev: table.tail,
        next: option::none(),
    };
    table_with_length::add(&mut table.inner, key, wrapped_value);
    if (option::is_some(&table.tail)) {
        let k = option::borrow(&table.tail);
        table_with_length::borrow_mut(&mut table.inner, *k).next = option::some(key);
    } else {
        table.head = option::some(key);
    };
    table.tail = option::some(key);
}
```

从 `table` 中移除并返回 `key` 所映射的值。如果 `key` 没有对应的条目，则会中止。

```
/// Remove from `table` and return the value which `key` maps to.
/// Aborts if there is no entry for `key`.
public fun remove<K: copy + store + drop, V: store>(table: &mut IterableTable<K, V>, key: K): V {
    let (val, _, _) = remove_iter(table, key);
    val
}
```

获取 `key` 所映射值的不可变引用。如果 `key` 没有对应的条目，则会中止。

```rust
/// Acquire an immutable reference to the value which `key` maps to.
/// Aborts if there is no entry for `key`.
public fun borrow<K: copy + store + drop, V: store>(table: &IterableTable<K, V>, key: K): &V {
    &table_with_length::borrow(&table.inner, key).val
}
```




```rust
/// Acquire a mutable reference to the value which `key` maps to.
/// Aborts if there is no entry for `key`.
public fun borrow_mut<K: copy + store + drop, V: store>(table: &mut IterableTable<K, V>, key: K): &mut V {
    &mut table_with_length::borrow_mut(&mut table.inner, key).val
}
```


```
/// Acquire a mutable reference to the value which `key` maps to.
/// Insert the pair (`key`, `default`) first if there is no entry for `key`.
public fun borrow_mut_with_default<K: copy + store + drop, V: store + drop>(table: &mut IterableTable<K, V>, key: K, default: V): &mut V {
    if (!contains(table, key)) {
        add(table, key, default)
    };
    borrow_mut(table, key)
}
```


```
/// Returns the length of the table, i.e. the number of entries.
public fun length<K: copy + store + drop, V: store>(table: &IterableTable<K, V>): u64 {
    table_with_length::length(&table.inner)
}
```

```
/// Returns true if this table is empty.
public fun empty<K: copy + store + drop, V: store>(table: &IterableTable<K, V>): bool {
    table_with_length::empty(&table.inner)
}
```

```
/// Returns true iff `table` contains an entry for `key`.
public fun contains<K: copy + store + drop, V: store>(table: &IterableTable<K, V>, key: K): bool {
    table_with_length::contains(&table.inner, key)
}

/// Iterable API.

/// Returns the key of the head for iteration.
public fun head_key<K: copy + store + drop, V: store>(table: &IterableTable<K, V>): Option<K> {
    table.head
}

/// Returns the key of the tail for iteration.
public fun tail_key<K: copy + store + drop, V: store>(table: &IterableTable<K, V>): Option<K> {
    table.tail
}

/// Acquire an immutable reference to the IterableValue which `key` maps to.
/// Aborts if there is no entry for `key`.
public fun borrow_iter<K: copy + store + drop, V: store>(table: &IterableTable<K, V>, key: K): (&V, Option<K>, Option<K>) {
    let v = table_with_length::borrow(&table.inner, key);
    (&v.val, v.prev, v.next)
}

/// Acquire a mutable reference to the value and previous/next key which `key` maps to.
/// Aborts if there is no entry for `key`.
public fun borrow_iter_mut<K: copy + store + drop, V: store>(table: &mut IterableTable<K, V>, key: K): (&mut V, Option<K>, Option<K>) {
    let v = table_with_length::borrow_mut(&mut table.inner, key);
    (&mut v.val, v.prev, v.next)
}

/// Remove from `table` and return the value and previous/next key which `key` maps to.
/// Aborts if there is no entry for `key`.
public fun remove_iter<K: copy + store + drop, V: store>(table: &mut IterableTable<K, V>, key: K): (V, Option<K>, Option<K>) {
    let val = table_with_length::remove(&mut table.inner, copy key);
    if (option::contains(&table.tail, &key)) {
        table.tail = val.prev;
    };
    if (option::contains(&table.head, &key)) {
        table.head = val.next;
    };
    if (option::is_some(&val.prev)) {
        let key = option::borrow(&val.prev);
        table_with_length::borrow_mut(&mut table.inner, *key).next = val.next;
    };
    if (option::is_some(&val.next)) {
        let key = option::borrow(&val.next);
        table_with_length::borrow_mut(&mut table.inner, *key).prev = val.prev;
    };
    let IterableValue {val, prev, next} = val;
    (val, prev, next)
}

/// Remove all items from v2 and append to v1.
public fun append<K: copy + store + drop, V: store>(v1: &mut IterableTable<K, V>, v2: &mut IterableTable<K, V>) {
    let key = head_key(v2);
    while (option::is_some(&key)) {
        let (val, _, next) = remove_iter(v2, *option::borrow(&key));
        add(v1, *option::borrow(&key), val);
        key = next;
    };
}

#[test]
fun iterable_table_test() {
    let table = new();
    let i = 0;
    while (i < 100) {
        add(&mut table, i, i);
        i = i + 1;
    };
    assert!(length(&table) == 100, 0);
    i = 0;
    while (i < 100) {
        assert!(remove(&mut table, i) == i, 0);
        i = i + 2;
    };
    assert!(!empty(&table), 0);
    let key = head_key(&table);
    i = 1;
    while (option::is_some(&key)) {
        let (val, _, next) = borrow_iter(&table, *option::borrow(&key));
        assert!(*val == i, 0);
        key = next;
        i = i + 2;
    };
    assert!(i == 101, 0);
    let table2 = new();
    append(&mut table2, &mut table);
    destroy_empty(table);
    let key = tail_key(&table2);
    while (option::is_some(&key)) {
        let (val, prev, _) = remove_iter(&mut table2, *option::borrow(&key));
        assert!(val == *option::borrow(&key), 0);
        key = prev;
    };
    destroy_empty(table2);
}
}
```
