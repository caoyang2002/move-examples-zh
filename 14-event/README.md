# 概述

在 Move 语言中使用事件模块来定义、发出和验证事件

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

这段代码展示了如何在 Move 语言中使用事件模块来定义、发出和验证事件。

### 模块和依赖项

```move
module event::event {
    use aptos_framework::event;
    #[test_only]
    use std::vector;
```

- `event::event` 是一个模块的声明。
- `use aptos_framework::event;` 引入了事件模块，使得可以使用其中的事件相关功能。
- `#[test_only] use std::vector;` 这里标记了对标准库中的 `vector` 的引用只用于测试环境中。

### 结构体定义

```move
    struct Field has store, drop {
        field: bool,
    }

    #[event]
    struct MyEvent has store, drop {
        seq: u64,
        field: Field,
        bytes: vector<u64>
    }
```

- `Field` 结构体定义了一个布尔类型的字段 `field`。
- `MyEvent` 结构体通过 `#[event]` 注解标记为一个事件，具有状态（`store`）和生命周期管理（`drop`）功能。
    - `seq` 是一个 `u64` 类型的序列号。
    - `field` 是一个 `Field` 类型的结构体。
    - `bytes` 是一个存储 `u64` 类型的向量。

### 公共入口函数 `emit`

```move
    public entry fun emit(num: u64) {
        let i = 0;
        while (i < num) {
            let event = MyEvent {
                seq: i,
                field: Field { field: false },
                bytes: vector[]
            };
            event::emit(event);
            i = i + 1;
        }
    }
```

- `emit(num: u64)` 是一个公共入口函数，用于生成和发出多个事件。
- 在函数中，使用 `while` 循环生成 `num` 个事件，每个事件具有递增的序列号 `i`，一个初始值为 `false` 的 `Field` 结构体，以及空的 `u64` 向量 `bytes`。
- 使用 `event::emit(event)` 发出每个事件。

### 公共入口函数 `call_inline` 和内联函数 `emit_one_event`

```move
    public entry fun call_inline() {
        emit_one_event()
    }

    inline fun emit_one_event() {
        event::emit(MyEvent {
            seq: 1,
            field: Field { field: false },
            bytes: vector[]
        });
    }
```

- `call_inline()` 是一个公共入口函数，调用了内联函数 `emit_one_event()`。
- `emit_one_event()` 是一个内联函数，用于直接发出一个事件。在这里，生成一个具有序列号 `1` 的 `MyEvent` 事件。

### 测试函数 `test_emitting`

```move
    #[test]
    public entry fun test_emitting() {
        emit(20);
        let module_events = event::emitted_events<MyEvent>();
        assert!(vector::length(&module_events) == 20, 0);
        let i = 0;
        while (i < 20) {
            let event = MyEvent {
                seq: i,
                field: Field {field: false},
                bytes: vector[]
            };
            assert!(vector::borrow(&module_events, i) == &event, i);
            i = i + 1;
        };
        let event = MyEvent {
            seq: 0,
            field: Field { field: false },
            bytes: vector[]
        };
        assert!(event::was_event_emitted(&event), i);
    }
```

- `test_emitting()` 是一个测试函数，使用 `#[test]` 标注为测试函数入口。
- 首先调用 `emit(20)` 生成并发出 20 个事件。
- 使用 `event::emitted_events<MyEvent>()` 获取所有已发出的 `MyEvent` 事件。
- 使用 `assert!` 断言验证：
    - 已发出的事件数量应为 20。
    - 每个生成的事件在发出后应与预期的事件相匹配。
    - 检查序列号为 `0` 的事件是否已经被发出。

### 测试函数 `test_inline`

```rust
    #[test]
    public entry fun test_inline() {
        call_inline();
        assert!(event::was_event_emitted(&MyEvent {
            seq: 1,
            field: Field { field: false },
            bytes: vector[]
        }), 0);
    }
```

- `test_inline()` 是另一个测试函数，用于测试内联发出事件的情况。
- 调用 `call_inline()` 触发发出一个事件。
- 使用 `assert!` 断言验证事件 `MyEvent` 序列号为 `1` 的事件是否已经被发出。
