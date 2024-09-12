# 快速开始

```bash
aptos move test
```

这段代码是使用 Aptos 语言（基于 Move 语言）编写的智能合约。它定义了一个模块 `test_object`，这个模块处理对象的创建、更新和删除，并在这些操作中发出事件。下面是对这段代码的详细解析：

### 模块导入和结构定义

```rust
module object::test_object {
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::event;
    use aptos_framework::object::{Self, Object};
```

- `use std::signer;`：引入用于签名者的模块。
- `use std::string::{Self, String};`：引入字符串类型。
- `use aptos_framework::event;`：引入事件模块。
- `use aptos_framework::object::{Self, Object};`：引入 Aptos 对象相关的模块。

```rust
    struct Content has key {
        value: string::String
    }

    struct Refs has key {
        delete_ref: object::DeleteRef,
        extend_ref: object::ExtendRef,
    }
```

- `Content` 结构体：表示一个包含字符串值的对象，`has key` 表示这个结构体是一个持久化对象，并且使用主键（`key`）来标识。
- `Refs` 结构体：保存与对象相关的引用，包括 `delete_ref` 和 `extend_ref`，用于删除和扩展操作。

### 创建对象的入口函数

```rust
    #[event]
    struct CreateEvent has drop,store {
        sender: address,
        object: Object<Content>
    }

    entry fun create (sender: &signer, content: string::String){
        let object_cref = object::create_object(signer::address_of(sender));
        let object_signer = object::generate_signer(&object_cref);

        move_to(
            &object_signer,
            Refs {
                delete_ref: object::generate_delete_ref(&object_cref),
                extend_ref: object::generate_extend_ref(&object_cref),
            }
        );
        move_to(
            &object_signer,
            Content {
                value:content
            }
        );

        event::emit( CreateEvent {
            sender: signer::address_of(sender),
            object: object::object_from_constructor_ref(&object_cref)
        });
    }
```

- `CreateEvent` 事件：在创建新对象时发出，包括发送者地址和新创建的对象。
- `create` 函数：
    - 使用 `object::create_object` 创建一个新的对象，并获取其引用 `object_cref`。
    - 使用 `object::generate_signer` 生成一个对象签名者。
    - 将 `Refs` 和 `Content` 对象转移到新创建的对象中。
    - 发出 `CreateEvent` 事件，记录创建对象的相关信息。

### 设置内容的入口函数

```rust
    #[event]
    struct SetContentEvent has drop,store {
        sender: address,
        object: Object<Content>,
        old_content: String,
        new_content: String
    }

    entry fun set_content(sender: &signer, object: Object<Content>, new_content: string::String) acquires Content {
        assert!(object::is_owner(object, signer::address_of(sender)), 1);

        let old_content = borrow_global<Content>(object::object_address(&object)).value;

        borrow_global_mut<Content>(object::object_address(&object)).value = new_content;

        event::emit(
            SetContentEvent {
                sender: signer::address_of(sender),
                object,
                old_content,
                new_content,
            }
        )
    }
```

- `SetContentEvent` 事件：在更新对象内容时发出，包括发送者地址、对象、旧内容和新内容。
- `set_content` 函数：
    - 确保调用者是对象的拥有者（使用 `object::is_owner`）。
    - 获取对象的当前内容，更新为新内容。
    - 发出 `SetContentEvent` 事件，记录内容更新的相关信息。

### 删除对象的入口函数

```rust
    #[event]
    struct DeleteEvent has drop,store {
        sender: address,
        object: Object<Content>,
        content: String
    }

    entry fun delete (sender: &signer,object: Object<Content>) acquires Content, Refs {
        assert!(object::is_owner(object, signer::address_of(sender)), 1);
        let Content {
            value
        } = move_from<Content>(object::object_address(&object));

        let Refs {
            delete_ref ,
            extend_ref: _ ,
        } = move_from<Refs>(object::object_address(&object));

        object::delete(
            delete_ref
        );

        event::emit(
            DeleteEvent {
                sender: signer::address_of(sender),
                object,
                content: value
            }
        )
    }
```

- `DeleteEvent` 事件：在删除对象时发出，包括发送者地址、对象和被删除的内容。
- `delete` 函数：
    - 确保调用者是对象的拥有者（使用 `object::is_owner`）。
    - 获取并删除对象中的内容，删除对象。
    - 发出 `DeleteEvent` 事件，记录对象删除的相关信息。

### 总结

- **`Content`**：表示具有字符串内容的对象。
- **`Refs`**：用于存储与对象操作相关的引用。
- **`create` 函数**：创建一个新的对象并发出创建事件。
- **`set_content` 函数**：更新对象的内容并发出更新事件。
- **`delete` 函数**：删除对象并发出删除事件。

这段代码展示了如何在 Aptos 上编写智能合约，进行对象的创建、更新和删除，并通过事件机制记录这些操作。