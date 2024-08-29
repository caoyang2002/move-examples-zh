# 概述

定义了一个简单的 Aptos 智能合约模块 `hello_blockchain::message`，实现了消息的存储、更新和事件发射功能。

# 快速开始

## 创建 aptos 地址

```bash
aptos init --network testnet # 网络可以自定义，推荐测试网
```

## 测试

```bash
aptos move test
```

## 部署


更新 `Move.toml`

```toml
[addresses]
hello_blockchain = "0xaptos-account-address"
```

编译和部署（发布）

```bash
aptos move complie
aptos move publish
```

## 查看和交互

在区块链浏览器中查看和使用合约

aptos explorer: https://explorer.aptoslabs.com/

在搜索框中输入 `account` 地址，并连接钱包，选择 testnet

在 `modules` 中：
- `code` 可以查看代码
- `run` 所有 `public entry` 的函数都会出现在这里，可以输入内容，以设置 message
- `view` 视图函数，所有被标记为 `#[view]` 的函数都会出现在这里，可以输入你自己的 account 地址或者设置过 message 的 account 地址，以查看 message

# 详解

## 主要功能和注意事项

**定义消息持有者**： `MessageHolder` 结构体用于存储消息，每个账户有一个唯一的消息持有者资源。

**事件定义**： `MessageChange` 事件在消息变化时触发，记录了账户地址、旧消息和新消息，用于跟踪消息的变化。

**获取消息**： `get_message` 函数用于获取指定账户的消息。这个函数是一个视图函数，只用于读取数据，不修改区块链状态。

**设置消息**： `set_message` 函数用于设置指定账户的消息。如果账户没有消息持有者资源，则创建一个新的；如果已经存在，则更新现有的消息，并发出 MessageChange 事件。

**测试函数**： `sender_can_set_message` 函数用于测试 set_message 和 get_message 函数的功能。创建一个新的测试账户，设置消息，并验证消息是否设置成功。

## 中文注释
```move
module hello_blockchain::message {
    use std::error;
    use std::signer;
    use std::string;
    use aptos_framework::event;

    //:!:>resource
    // 定义一个 `MessageHolder` 结构体，用于存储消息
    // 该结构体是有键的资源，意味着它在区块链上有唯一标识并且可以被全局访问
    struct MessageHolder has key {
        message: string::String,  // 存储消息的字段
    }
    //<:!:resource

    // 定义一个事件 `MessageChange`，当消息变化时触发
    // 该事件包含账户地址、旧消息和新消息
    #[event]
    struct MessageChange has drop, store {
        account: address,              // 消息所属的账户地址
        from_message: string::String, // 旧消息
        to_message: string::String,   // 新消息
    }

    // 错误代码：没有找到消息
    const ENO_MESSAGE: u64 = 0;

    // 视图函数：获取指定账户的消息
    // 这个函数不会修改区块链状态，只是读取数据
    #[view]
    public fun get_message(addr: address): string::String acquires MessageHolder {
        // 确保指定地址存在 `MessageHolder` 资源
        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));
        // 返回存储的消息
        borrow_global<MessageHolder>(addr).message
    }

    // 入口函数：设置指定账户的消息
    // 这个函数会修改区块链上的状态
    public entry fun set_message(account: signer, message: string::String)
    acquires MessageHolder {
        let account_addr = signer::address_of(&account); // 获取账户地址
        if (!exists<MessageHolder>(account_addr)) {
            // 如果账户没有 `MessageHolder` 资源，则创建一个新的
            move_to(&account, MessageHolder {
                message,
            });
        } else {
            // 如果账户已经存在 `MessageHolder` 资源，则更新消息
            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);
            let from_message = old_message_holder.message;
            // 发出 `MessageChange` 事件，记录消息变化
            event::emit(MessageChange {
                account: account_addr,
                from_message,
                to_message: copy message,
            });
            // 更新消息
            old_message_holder.message = message;
        }
    }

    // 测试函数：检查发送者是否能够设置消息
    // 这个函数在测试环境中运行，用于验证 `set_message` 和 `get_message` 函数的正确性
    #[test(account = @0x1)]
    public entry fun sender_can_set_message(account: signer) acquires MessageHolder {
        let addr = signer::address_of(&account);
        // 为测试账户创建一个新的账户
        aptos_framework::account::create_account_for_test(addr);
        // 设置消息
        set_message(account, string::utf8(b"Hello, Blockchain"));

        // 验证消息是否设置成功
        assert!(
            get_message(addr) == string::utf8(b"Hello, Blockchain"),
            ENO_MESSAGE
        );
    }
}

```