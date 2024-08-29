# 介绍
这是一个模块，展示了如何使用新的 AggregatorV2 并行性和分支预测特性来创建一个全局计数器，该计数器会检查特定的 `Milestone` 。

当交易达到这些 `Milestone` 时，会有特殊的逻辑来庆祝这些 `Milestone` 。检查 `Milestone` 只在达到 `Milestone` 时点附近创建减少的并行性，因此如果 `Milestone` 间隔较远（比如相隔一千或更多），总体上对吞吐量/并行性不会有影响。

以非常类似的方式，可以处理代币（数字资产）铸造的 `Milestone` ，通过使用
`collection::is_total_minted_at_least`
调用，因为数字资产集合会跟踪它们的供应量以及迄今为止铸造的总量。

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
```bash
aptos move compile
aptos move publish
```



# 详细说明

## 代码实现了以下功能：

创建全局计数器：模块提供了一个 create 函数来初始化一个 MilestoneCounter 资源，这个资源包含了计数器、下一个里程碑以及每次里程碑之间的间隔。

增加计数并检查里程碑：模块还提供了一个 increment_milestone 函数来递增计数器，并在达到新的里程碑时触发一个事件。这个函数在计数器达到当前设定的里程碑时，会发出一个 MilestoneReached 事件，并更新下一个里程碑的值。


## 主要功能和注意事项

**创建计数器**：create 函数将计数器资源初始化到发布者的帐户中。初始化时设置计数器和里程碑的相关参数。

**递增计数器**：increment_milestone 函数用于递增计数器，并在计数器达到设定的里程碑时发出事件并更新下一个里程碑。这保证了里程碑检查是高效的，不会影响整体的吞吐量和并行性。

**事件触发**：当计数器达到新里程碑时，系统会发出一个 MilestoneReached 事件，这可以用于触发额外的逻辑，比如通知用户或记录数据。

## 中文注释
```bash
/// 该模块展示了如何使用 AggregatorV2 的并行和分支预测特性
/// 来管理一个全局计数器，并在计数器达到特定里程碑时执行特殊逻辑庆祝这些里程碑。
/// 它确保只有在里程碑被达到时才会检查里程碑，从而最小化对整体吞吐量和并行性的影响。
///
/// 类似的逻辑也可以应用于代币（数字资产）的铸造，通过使用 collection::is_total_minted_at_least 函数
/// 来处理代币（数字资产）集合中的里程碑。数字资产集合跟踪其供应量和迄今为止铸造的总量。
module aggregator_examples::counter_with_milestone {
    use std::error;
    use std::signer;
    use aptos_framework::aggregator_v2::{Self, Aggregator};
    use aptos_framework::event;

    // 当被修改的资源不存在时的错误代码
    const ERESOURCE_NOT_PRESENT: u64 = 2;

    // 当计数器递增失败时的错误代码
    const ECOUNTER_INCREMENT_FAIL: u64 = 4;

    // 当未授权访问时的错误代码
    const ENOT_AUTHORIZED: u64 = 5;

    // 定义一个结构体来存储里程碑计数器的信息
    // 这个结构体是基于键的，意味着它有一个唯一的键并且是全局可访问的
    struct MilestoneCounter has key {
        next_milestone: u64,        // 下一个要达到的里程碑
        milestone_every: u64,       // 里程碑之间的间隔
        count: Aggregator<u64>,     // 处理全局计数器的聚合器
    }

    // 定义一个事件，当里程碑被达到时将会触发这个事件
    #[event]
    struct MilestoneReached has drop, store {
        milestone: u64,             // 达到的里程碑值
    }

    // 公共入口函数，用于创建全局 `MilestoneCounter`
    // 这个函数由模块发布者调用，初始化计数器
    public entry fun create(publisher: &signer, milestone_every: u64) {
        assert!(
            signer::address_of(publisher) == @aggregator_examples,
            ENOT_AUTHORIZED,
        );

        // 将新创建的 `MilestoneCounter` 资源移动到发布者的账户中
        move_to<MilestoneCounter>(
            publisher,
            MilestoneCounter {
                next_milestone: milestone_every,  // 设置初始里程碑
                milestone_every,                  // 设置里程碑之间的间隔
                count: aggregator_v2::create_unbounded_aggregator(), // 为计数器创建一个无限聚合器
            }
        );
    }

    // 公共入口函数，用于递增里程碑计数器
    // 这个函数检查是否达到了里程碑，并在达到时触发事件
    public entry fun increment_milestone() acquires MilestoneCounter {
        // 确保 `MilestoneCounter` 资源存在
        assert!(exists<MilestoneCounter>(@aggregator_examples), error::invalid_argument(ERESOURCE_NOT_PRESENT));

        // 借用 `MilestoneCounter` 资源
        let milestone_counter = borrow_global_mut<MilestoneCounter>(@aggregator_examples);

        // 递增计数器，并确保成功
        assert!(aggregator_v2::try_add(&mut milestone_counter.count, 1),

```