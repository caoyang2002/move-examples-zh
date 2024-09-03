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

## `drand.move`
这段代码注释的中文翻译如下：

drand 随机性信标在每一轮 `i` 产生一段随机性 `r_i`，以便任何人都可以根据 drand 的公钥 `pk` 进行验证。

可以进行验证是因为 `r_i` 简单地是在与 `pk` 相对应的私钥 `sk` 下，对 `i` 进行的BLS签名。

每隔3秒进行一轮（对于“bls-unchained-on-g1”信标）。因此，根据UNIX时间戳，可以轻松地推导出 drand 应该签名的轮数 `i`，以生成该轮的随机性。

此模块中硬编码的“bls-unchained-on-g1”drand信标的参数是从[drand REST API](https://api.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/info)查询获得的。

```json
{
    "public_key": "a0b862a7527fee3a731bcb59280ab6abd62d5c0b6ea03dc4ddf6612fdfc9d01f01c31542541771903475eb1ec6615f8d0df0b8b6dce385811d6dcf8cbefb8759e5e616a3dfd054c928940766d9a5b9db91e3b697e5d70a975181e007f87fca5e",
    "period": 3,
    "genesis_time": 1677685200,
    "hash": "dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493",
    "groupHash": "a81e9d63f614ccdb144b8ff79fbd4d5a2d22055c0bfe4ee9a8092003dab1c6c0",
    "schemeID": "bls-unchained-on-g1",
    "metadata": {"beaconID": "fastnet"}
}
```

### 中文注释

```move
module drand::drand {
    use std::hash::{sha3_256, sha2_256};
    use std::option::{Self, Option, extract};
    use std::vector;
    use std::error;
    use aptos_std::crypto_algebra::{eq, pairing, one, deserialize, hash_to, from_u64, serialize};
    use aptos_std::bls12381_algebra::{G1, G2, Gt, FormatG2Compr, FormatG1Compr, HashG1XmdSha256SswuRo, Fr, FormatFrMsb};

    /// `bls-unchained-on-g1` drand信标每3秒产生一个输出。
    /// （如果节点落后，则进入追赶模式。）
    const PERIOD_SECS: u64 = 3;

    /// drand信标开始运行的UNIX时间（以秒为单位）（这是第1轮的时间）
    const GENESIS_TIMESTAMP: u64 = 1677685200;

    /// drand信标的公钥，用于验证每轮`i`的任何信标输出。
    const DRAND_PUBKEY: vector<u8> = x"a0b862a7527fee3a731bcb59280ab6abd62d5c0b6ea03dc4ddf6612fdfc9d01f01c31542541771903475eb1ec6615f8d0df0b8b6dce385811d6dcf8cbefb8759e5e616a3dfd054c928940766d9a5b9db91e3b697e5d70a975181e007f87fca5e";

    /// drand的BLS签名中使用的域分离标签（DST）
    const DRAND_DST: vector<u8> = b"BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_";

    /// 在我们的API中提交不正确随机性时的错误代码（例如，大小不对）
    const E_INCORRECT_RANDOMNESS: u64 = 1;

    /// 一个随机性对象，由成功验证的drand随机性创建。
    /// 该对象可以转换为均匀的随机整数。
    struct Randomness has drop {
        bytes: vector<u8>
    }

    /// 检查`signature`中的随机性是否验证特定的`round`。
    /// 如果验证成功，则返回实际的随机性，即应用于`signature`的哈希函数。
    public fun verify_and_extract_randomness(
        signature: vector<u8>,
        round: u64): Option<Randomness>
    {
        let pk = extract(&mut deserialize<G2, FormatG2Compr>(&DRAND_PUBKEY));
        let sig = extract(&mut deserialize<G1, FormatG1Compr>(&signature));
        let msg_hash = hash_to<G1, HashG1XmdSha256SswuRo>(&DRAND_DST, &round_number_to_bytes(round));
        assert!(eq(&pairing<G1, G2, Gt>(&msg_hash, &pk), &pairing<G1, G2, Gt>(&sig, &one<G2>())), 1);
        option::some(Randomness {
            bytes: sha3_256(signature)
        })
    }

    /// 返回在给定一些drand（已验证）`randomness`情况下的均匀数字，范围为$[0, max)$。
    /// （从技术上讲，数字中存在一个小的、计算上无法区分的偏差。）
    /// 注意：这是一个一次性的API，会消耗掉`randomness`。
    public fun random_number(randomness: Randomness, max: u64): u64 {
        assert!(vector::length(&randomness.bytes) >= 8, error::invalid_argument(E_INCORRECT_RANDOMNESS));

        let entropy = sha3_256(randomness.bytes);

        // 我们可以将`randomness`中的256个均匀位转换为均匀的64位数 `w \in [0, max)`，
        // 取`randomness`中的最后128位对`max`取模。
        let num: u256 = 0;
        let max_256 = (max as u256);

        // 啊呀，我们必须手动将其反序列化为u128
        while (!vector::is_empty(&entropy)) {
            let byte = vector::pop_back(&mut entropy);
            num = num << 8;
            num = num + (byte as u256);
        };

        ((num % max_256) as u64)
    }

    /// 返回在`unix_time_in_secs`时间戳之后`drand`将签名的下一轮`i`。
    public fun next_round_after(unix_time_in_secs: u64): u64 {
        let (next_round, _) = next_round_and_timestamp_after(unix_time_in_secs);

        next_round
    }

    /// 返回下一轮和其UNIX时间（在`unix_time_in_secs`时间戳之后的轮数）。
    /// （时间戳`GENESIS_TIMESTAMP`的轮数为1。轮数0是固定的。）
    public fun next_round_and_timestamp_after(unix_time_in_secs: u64): (u64, u64) {
        if (unix_time_in_secs < GENESIS_TIMESTAMP) {
            return (1, GENESIS_TIMESTAMP)
        };

        let duration = unix_time_in_secs - GENESIS_TIMESTAMP;

        // 如https://github.com/drand/drand/blob/0678331f90c87329a001eca4031da8259f6d1d3d/chain/time.go#L57中描述的：
        //  > 我们将从起始时间除以秒数得到时间。
        //  > 这给了我们自起源以来的周期数。
        //  > 我们加上+1因为我们想要下一轮。
        //  > 我们还加上+1因为轮数1从起源时间开始。

        let next_round = (duration / PERIOD_SECS) + 1;
        let next_time = GENESIS_TIMESTAMP + next_round * PERIOD_SECS;

        (next_round + 1, next_time)
    }

    //
    // 内部实现
    //

    /// drand签名不是直接针对轮数的，而是针对轮数的8字节（小端）表示的SHA2-256。
    ///
    /// 参见：
    ///  - https://drand.love/docs/specification/#beacon-signature
    ///  - https://github.com/drand/drand/blob/v1.2.1/chain/store.go#L39-L44
    fun round_number_to_bytes(round: u64): vector<u8> {
        let buf = serialize<Fr, FormatFrMsb>(&from_u64<Fr>(round));
        sha2_256(std::vector::trim(&mut buf, 24))
    }
}

```

## `lottery.move`

一个去中心化彩票的示例，它根据未来由 drand 随机性信标生成的随机性选择其赢家。

**警告 #1:** 此示例尚未经过审计，因此不应将其视为在Move中安全使用 `drand` 随机性的权威指南。

警告 #2: 此代码强烈假设 Aptos 时钟和 drand 时钟是同步的。

实际上，Aptos 时钟可能滞后。例如，即使当前时间是 2023 年 7 月 14 日下午 7 点 34 分，从区块链验证者的角度来看，
时间可能是 2023 年 7 月 13 日星期四。因此，对于星期五中午的 drand 轮次，它可能会错误地视为有效的未来 drand 轮次，
尽管该轮次已经过去。因此，合约必须考虑 Aptos 时钟和 drand 时钟之间的任何漂移。在此示例中，可以通过增加
MINIMUM_LOTTERY_DURATION_SECS 来解决这个问题，以考虑这种漂移。

```move
module drand::lottery {
    use std::signer;
    use aptos_framework::account;
    use std::vector;
    use std::option::{Self, Option};
    use aptos_framework::coin;
    use std::error;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;
    use drand::drand;
    //use aptos_std::debug;

    /// 当有人尝试启动非常“短”彩票时，用户可能没有足够的时间购买彩票时的错误代码。
    const E_LOTTERY_IS_NOT_LONG_ENOUGH: u64 = 0;
    /// 当有人尝试修改彩票抽奖时间时的错误代码。
    /// 一旦设置，这个时间就不能再修改（为了简单起见）。
    const E_LOTTERY_ALREADY_STARTED: u64 = 1;
    /// 当一个用户尝试在彩票关闭后购买彩票时的错误代码。这是不安全的，
    /// 因为这些用户可能知道公共随机数，在彩票关闭后不久会被揭示。
    const E_LOTTERY_HAS_CLOSED: u64 = 2;
    /// 当用户尝试在开奖时间太早时发起开奖时的错误代码（必须已经过了足够的时间，用户才能有时间注册）。
    const E_LOTTERY_DRAW_IS_TOO_EARLY: u64 = 3;
    /// 当有人为彩票随机抽奖阶段提交不正确的随机性时的错误代码。
    const E_INCORRECT_RANDOMNESS: u64 = 4;

    /// 彩票开始和关闭之间的最小时间，随机抽奖可以发生。
    /// 当前设置为（10分钟 * 60秒/分钟）秒。
    const MINIMUM_LOTTERY_DURATION_SECS: u64 = 10 * 60;

    /// 彩票票的最低价格。
    const TICKET_PRICE: u64 = 10000;

    /// 一个彩票：购买彩票的用户列表和在其后随机抽奖可以发生的时间。
    ///
    /// 获胜用户将从此列表中通过 drand 公共随机性随机选择。
    struct Lottery has key {
        // 购买彩票的用户列表
        tickets: vector<address>,

        // 彩票结束的时间（因此抽奖发生的时间）。
        // 具体来说，抽奖将在 drand 在时间 `draw_at` 的轮次中进行。
        // 如果彩票处于“未启动”状态，则为 `None`。
        draw_at: Option<u64>,

        // 用于存储可以赢得硬币的资源账户的签名者
        signer_cap: account::SignerCapability,

        // 获胜者的地址
        winner: Option<address>,
    }

    // 声明测试模块为友元，因此它可以调用下面用于测试的 `init_module`。
    friend drand::lottery_test;

    /// 初始化所谓的“资源”账户，该账户将维护用户购买的彩票列表。
    fun init_module(deployer: &signer) {
        // 创建资源账户。这将允许此模块后来获得用于此账户的 `signer` 并更新已购买彩票列表。
        let (_resource, signer_cap) = account::create_resource_account(deployer, vector::empty());

        // 获取存储彩票奖金的资源账户的签名者
        let rsrc_acc_signer = account::create_signer_with_capability(&signer_cap);

        // 初始化一个 AptosCoin 硬币存储，彩票奖金将在这里保留
        coin::register<AptosCoin>(&rsrc_acc_signer);

        // 初始化为“未启动”的彩票
        move_to(deployer,
            Lottery {
                tickets: vector::empty<address>(),
                draw_at: option::none(),
                signer_cap,
                winner: option::none(),
            }
        )
    }

    public fun get_ticket_price(): u64 { TICKET_PRICE }
    public fun get_minimum_lottery_duration_in_secs(): u64 { MINIMUM_LOTTERY_DURATION_SECS }

    public fun get_lottery_winner(): Option<address> acquires Lottery {
        let lottery = borrow_global_mut<Lottery>(@drand);
        lottery.winner
    }

    /// 允许任何人启动和配置彩票，以便在时间 `draw_at` 进行抽奖（因此用户有足够的时间购买彩票），
    /// 其中 `draw_at` 是以秒为单位的 UNIX 时间戳。
    ///
    /// 注意：实际应用可以访问并控制这一点。
    public entry fun start_lottery(end_time_secs: u64) acquires Lottery {
        // 确保彩票开放的时间足够长，以便人们购买彩票。
        assert!(end_time_secs >= timestamp::now_seconds() + MINIMUM_LOTTERY_DURATION_SECS, error::out_of_range(E_LOTTERY_IS_NOT_LONG_ENOUGH));

        // 更新 Lottery 资源，设置（未来）彩票抽奖时间，有效地“启动”彩票。
        let lottery = borrow_global_mut<Lottery>(@drand);
        assert!(option::is_none(&lottery.draw_at), error::permission_denied(E_LOTTERY_ALREADY_STARTED));
        lottery.draw_at = option::some(end_time_secs);

        //debug::print(&string::utf8(b"Started a lottery that will draw at time: "));
        //debug::print(&draw_at_in_secs);
    }

    /// 由任何用户调用，购买彩票。
    public entry fun buy_a_ticket(user: &signer) acquires Lottery {
        // 获取 Lottery 资源
        let lottery = borrow_global_mut<Lottery>(@drand);

        // 确保彩票已“启动”，但尚未“抽奖”
        let draw_at = *option::borrow(&lottery.draw_at);
        assert!(timestamp::now_seconds() < draw_at, error::out_of_range(E_LOTTERY_HAS_CLOSED));

        // 获取存储彩票奖金的资源账户的地址
        let (_, rsrc_acc_addr) = get_rsrc_acc(lottery);

        // 从用户的余额中扣除彩票的价格，并将其累积到彩票的奖金中
        coin::transfer<AptosCoin>(user, rsrc_acc_addr, TICKET_PRICE);

        // ...并为该用户发出一张彩票
        vector::push_back(&mut lottery.tickets, signer::address_of(user))
    }

    /// 允许任何人关闭彩票（如果已经过了足够的时间）并决定获胜者，通过上传与 `Lottery::draw_at` 中的承诺抽奖时间相关的正确 _drand-signed bytes_。
    /// 然后将验证这些字节并用它们提取随机性。
    public entry fun close_lottery(drand_signed_bytes: vector<u8>) acquires Lottery {
        // 获取 Lottery 资源
        let lottery = borrow_global_mut<Lottery>(@drand);

        // 确保彩票已“启动”，并且足够的时间已经过去，可以开始抽奖
        let draw_at = *option::borrow(&lottery.draw_at);
        assert!(timestamp::now_seconds() >= draw_at, error::out_of_range(E_LOTTERY_DRAW_IS_TOO_EARLY));

        // 可能没有人报名...
        if(vector::is_empty(&lottery.tickets)) {
            // 到了抽奖的时间，但没有人报名 => 没有人赢。
            // 关闭彩票（即使随机性可能不正确）。
            option::extract(&mut lottery.draw_at);
            return
        };

        // 确定 `draw_at` 后的下一个 drand 轮次
        let drand_round = drand::next_round_after(draw_at);

        // 验证该轮次的随机性并选择获胜者
        let randomness = drand::verify_and_extract_randomness(
            drand_signed_bytes,
            drand_round
        );
        assert!(option::is_some(&randomness), error::permission_denied(E_INCORRECT_RANDOMNESS));

        // 使用这些字节从 0 到 `|lottery.tickets| - 1` 随机选择一个数字并选择获胜者
        let winner_idx = drand::random_number(
            option::extract(&mut randomness),
            vector::length(&lottery.tickets)
        );

        // 支付获胜者
        let (rsrc_acc_signer, rsrc_acc_addr) = get_rsrc_acc(lottery);
        let balance = coin::balance<AptosCoin>(rsrc_acc_addr);
        let winner_addr = *vector::borrow(&lottery.tickets, winner_idx);

        coin::transfer<AptosCoin>(
            &rsrc_acc_signer,
            winner_addr,
            balance);

        // 关闭彩票
        option::extract(&mut lottery.draw_at);
        lottery.tickets = vector::empty<address>();
        lottery.winner = option::some(winner_addr);
    }

    //
    // 内部函数
    //

    fun get_rsrc_acc(lottery: &Lottery): (signer, address) {
        let rsrc_acc_signer = account::create_signer_with_capability(&lottery.signer_cap);
        let rsrc_acc_addr = signer::address_of(&rsrc_acc_signer);

        (rsrc_acc_signer, rsrc_acc_addr)
    }

    //
    // 测试函数
    //

    #[test_only]
    public fun init_module_for_testing(developer: &signer) {
        account::create_account_for_test(signer::address_of(developer));
        init_module(developer)
    }
}

```

## `lottery_test.move`