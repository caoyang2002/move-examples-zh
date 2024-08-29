# 绑定曲线启动平台

## 概述

绑定曲线启动平台（BCL） - 一种同质化资产启动平台，同时也是一个受控的 DEX，用于创建更公平的代币发行。

创建新的 FA 后，最初它只能在启动平台上进行交易。可调度的 FA 功能用于支持对外部转账的全球冻结令牌。FA 的创建者不能预铸以获得对后续参与者的优势。此外，虚拟流动性的使用防止了典型的早期参与者的压倒性优势。

一旦在流动性对中达到 APT 阈值，储备金将转移到公共 DEX，称为“毕业”。从那里，全球冻结被禁用，允许所有参与者自由使用他们的代币。

### 关键术语

**毕业（Graduation）** - 将闭环 FA 的流动性储备从“绑定曲线启动平台”转移到公共 DEX 的过程，同时允许 FA 所有者进行任何和所有转账。然后可以进行公开交易，无需为给定的 FA 咨询“绑定曲线启动平台”持有的“transfer_ref”。

**虚拟流动性（Virtual Liquidity）** - 为防止早期参与者的优势，假定在所有 APT 储备中为流动性对存在预定义数量的虚拟流动性。由于 FA 和 APT 储备在价值上会更接近，早期转账对于收到的代币数量不会那么剧烈。

## 此资源包含：

* （可调度的）同质化的资产。
* 重用存储的签名者的变量（使用 [对象](https://aptos.dev/move/move-on-aptos/objects/)）。
* 外部第三方依赖项。
* 端到端测试（使用对象部署、APT 创建）。
* 使用 `rev` 来指定功能分支（[可调度 FA](https://github.com/aptos-labs/aptos-core/commit/bbf569abd260d94bc30fe96da297d2aecb193644)）。
* 等等。

## 深入信息

### 描述

绑定曲线启动板的目标是为 FA 发行活动创造一个更直接和开放的环境。这意味着什么？
* 早期参与者们的优势减少
* 没有预铸
* 没有向私人投资者分配

由于区块链的技术性质，可能很难确定一个 FA 是否受到上述属性的影响。
尽管这些本身并非负面的，但许多用户承认对包含这些属性的新 FA 的兴趣降低。
这导致了对提高 FA 发行活动“公平性”的兴趣增加，而实现这一目标的一种方法是通过智能合约解决方案。

`bonding_curve_launchpad` 是基于智能合约实现这一目标的一个实例。

### 可调度的提现函数

当使用可调度 FA 标准时，可以定义自定义的“提现”函数（以及其他函数，如存款和派生余额）。每次调用默认的“提现”时（例如在 FA 转账期间）都会执行此逻辑。

“绑定曲线启动板”利用这一点，有条件地检查流动性对状态变量是否有效。更具体地说，相关 FA 的状态变量“is_frozen”必须设置为“false”，否则所有提现都将失败。

这防止了在“transfer_ref”的明确使用之外发生任何转账。参与者将被迫仅在“绑定曲线启动板”的上下文中使用他们的 FA，直到在“毕业”期间相应 FA 的“is_frozen”切换为“true”。

### 交易功能

在 `liquidity_pairs` 内使用恒定乘积公式来计算 `get_amount_out`，类似于 [以太坊上的 UniswapV2](https://docs.uniswap.org/contracts/v2/concepts/protocol-overview/how-uniswap-works) 。
虽然出于熟悉和简单的原因选择了它，但在生产环境中，人们可能会考虑其他交易功能。

一种风格可以包括次线性函数，以更重地奖励早期采用者们。

## 相关文件

### `bonding_curve_launchpad.move`

* 包含面向最终用户的公共函数（入口和普通函数）。
* 通过 FA 的相应对象创建并持有对已启动的可替代资产（Fungible Asset）的引用（转移）。
* 调度到 `liquidity_pairs` 以在已启动的 FA 和 APT 之间创建新对。
* 促进任何已启用的 FA 和 APT 之间的交换。

### `liquidity_pairs.move`

* 通过命名对象创建并持有对每个流动性对的引用。
* 包含对每个对执行交换的业务逻辑。
* 执行毕业仪式以禁用流动性对，并将所有储备转移到外部的第三方 DEX。

### `test_bonding_curve_launchpad.move`

* 端到端测试。

### `move-examples/swap`

* 来自 `aptos-move` 示例的可替代资产 DEX 示例。

### 已启动的 FA 的生命周期

#### 启动 FA 和流动性对

1. 用户通过 `create_fa_pair(...)` 在 `bonding_curve_launchpad` 上启动 FA 的创建。
   1. `bonding_curve_launchpad` 创建一个新的可调度 FA，并通过使用存储的 `extend_ref` 检索其 `signer`，将 `"FA Generator" 对象` 分配为创建者。重要的是，启动 FA 的用户没有任何权限（铸造、转移、销毁），防止他们预先铸造。FA 功能（`transfer_ref`）存储在 FA 的相应对象中，以供将来转移。
   2. 定义了可调度的 `withdraw` 函数，以禁止 FA 所有者之间的所有转移，直到满足 **毕业** 条件。它通过与 FA 即将生成的流动性对相关联的状态值 `is_frozen` 来实现，该值最初设置为 `true`。这禁止了 FA 在外部 DEX 或通过外部方式进行交易。转移仅通过 `bonding_curve_launchpad` 上存储的有限 `transfer_ref` 可用，并限于在 `liquidity_pairs` 的流动性对上进行交换。
   3. 预先铸造一定数量的 FA，并暂时保留在 `bonding_curve_launchpad` 上。
   
2. `bonding_curve_launchpad` 在 `liquidity_pairs` 模块上创建一个遵循恒定乘积公式的流动性对。
   1. 流动性对被表示并存储为一个对象。这允许储备金直接保存在对象上，而不是 `bonding_curve_launchpad` 账户上。
   2. 铸造的整个 FA 加上为 APT 预先定义数量的 **虚拟流动性** 被存入流动性对对象。
   3. 针对流动性对的交易被启用，但仅限于 `bonding_curve_launchpad` 中的 `public entry` 函数。
   
3. 可选地，创建者可以立即从 APT 启动对 FA 的交换。


#### 针对 FA 的相关流动性对进行交易
1. 外部用户可以通过 `bonding_curve_launchpad` 上可用的 `public entry` 方法将 APT 兑换为 FA，反之亦然。
   1. 虽然 FA 的正常 `transfer` 功能被自定义的可调度 `withdraw` 函数禁用，但 `bonding_curve_launchpad` 可以使用其从 FA 的对象存储的 `transfer_ref` 协助兑换。`transfer_ref` 不受自定义的可调度函数的妨碍。
   2. 用于计算兑换的 `amountOut` 的逻辑基于恒定乘积公式以使读者熟悉。在生产场景中，次线性交易函数可以有助于激励一般的早期采用。

#### 从 `liquidity_pairs` 毕业到公共 FA DEX

1. 在每次从 APT 到 FA 的兑换之后，当 APT 储备增加时，检查流动性对是否可以 **毕业** 的阈值。阈值是储备中必须存在的预先定义的 APT 最小数量。一旦在兑换期间达到此阈值，**毕业** 开始。
   1. 通过切换 `is_enabled`，`liquidity_pairs` 模块上的相关流动性对被禁用，防止针对该对进行更多兑换。此外，流动性对的 `is_frozen` 被禁用，以允许所有者自由转移。
   2. 来自流动性对的 APT 和 FA 储备被作为新的流动性对转移到外部的公共第三方 DEX。在这种情况下，是 `aptos-move` FA DEX 示例，称为交换。
   3. 为了防止 `bonding_curve_launchpad` 所有者的任何不当行为，在第三方 DEX 上创建新流动性对期间收到的任何流动性代币将被发送到一个无效地址。否则，这些代币可能随时被用于抽干流动性。
## 如何测试：

```console
aptos move test --dev
```

## 示例测试网部署
[Bonding Curve Launchpad](https://explorer.aptoslabs.com/account/0x0bb954c7dda5fa777cb34d2e35f593ddc4749f1ab260017ee75d1d216a551841/transactions?network=testnet)

[Swap DEX](https://explorer.aptoslabs.com/account/0xe26bbe169db47aaa32349d253891af42134e1f6b64fef63f60105ec9ab6b240f/transactions?network=testnet?)

[Swap 部署者](https://explorer.aptoslabs.com/account/0x4d51c99abff19bfb5ca3065f1e71dfc066c38e334def24dbac2b2a38bee8b946?network=testnet)

## 如何部署：

1. **注意：** 由于我们作为第三方 DEX 所依赖的 `swap` 模块不在链上，您首先需要：
   * 在链上部署 `swap` 模块。或者，如果您在测试网上，可以使用 [已部署的 `swap` 智能合约](https://explorer.aptoslabs.com/account/0xe26bbe169db47aaa32349d253891af42134e1f6b64fef63f60105ec9ab6b240f/transactions?network=testnet?) 。
   * 依靠不同的 DEX 进行代币的毕业操作。

从那里，您可以按照 [对象代码部署](https://preview.aptos.dev/en/build/smart-contracts/learn-move/advanced-guides/object-code-deployment) 步骤来部署和设置智能合约。

### 测试网部署

将 `bonding_curve_launchpad` 部署到测试网，并参考已部署的 `swap` 智能合约：

```console
aptos move publish --profile testnet_bonding_curve_launchpad \
--named-addresses bonding_curve_launchpad={REPLACE_WITH_YOUR_ACCOUNT},swap=0xe26bbe169db47aaa32349d253891af42134e1f6b64fef63f60105ec9ab6b240f,deployer=0x4d51c99abff19bfb5ca3065f1e71dfc066c38e334def24dbac2b2a38bee8b946
```





---
# Bonding Curve Launchpad

## Overview
Bonding Curve Launchpad (BCL) - A fungible asset launchpad that doubles as a controlled DEX to create fairer token launches.

After creation of a new FA, it can, initially, only be traded on the launchpad. Dispatchable FA features are used to support the global freezing of tokens from external transfers. The creator of the FA can not premint to gain advantages against latter participants. Additionally, the usage of virtual liquidity prevents the typical overwhelming early adopter's advantage.

Once the APT threshold is met within the liquidity pair, the reserves are moved onto a public DEX, referred to as graduation. From there, the global freeze is disabled, allowing all participants to freely use their tokens.

### Key terms
**Graduation** - The process of moving the close-looped FA's liquidity reserves from the `bonding_curve_launchpad` to a public DEX, while enabling any and all transfers from FA owners. Public trading is then available, removing the need to consult the `bonding_curve_launchpad`'s held `transfer_ref` for the given FA.

**Virtual Liquidity** - To prevent early adopter's advantage, a pre-defined amount of virtual liquidity is assumed to exist in all APT reserves for liquidity pairs. Since the FA and APT reserves will be closer together in value, an early transfer won't be as dramatic for the number of tokens received. 


## This resource contains:
* (Dispatchable) Fungible Assets.
* Reusing stored signer vars (w/ [objects](https://aptos.dev/move/move-on-aptos/objects/)).
* External third party dependencies.
* E2E testing (w/ object deployments, APT creation).
* Using `rev` to specify feature branches ([Dispatchable FA](https://github.com/aptos-labs/aptos-core/commit/bbf569abd260d94bc30fe96da297d2aecb193644)).
* and more.

## In-depth info
### Description
The goal of a bonding curve launchpad is to create a more direct and open environment for FA launches. What does this mean?
* Less early adopter's advantage
* No pre-mints
* No allocation to private investors

Due to the technical nature of the blockchain, it can be hard to determine whether an FA is impacted by 
the above attributes. 
Although these are not inherently negative, many users have admitted to decreased interest 
in new FAs that include them.
This has led to an increase interest on improving "fairness" of FA launches, and one way to approach this is through 
a smart contract solution. 

`bonding_curve_launchpad` is one instance of a smart contract-based effort that accomplishes this.

### Dispatchable withdraw function
When using the Dispatchable FA standard, one can define a custom `withdraw` function 
(along with others, like deposit and derived_balance). This logic is executed every time the 
default `withdraw` is called, like during an FA transfer.

`bonding_curve_launchpad` takes advantage of this by conditionally checking if a liquidity 
pair state variable is valid. More specifically, the related FA's state variable `is_frozen` must 
be set to `false`, otherwise all withdraws will fail.

This prevents any transfers from occurring that happen outside the explicit usage of `transfer_ref`. Participants will 
be forced to only use their FAs within the context of `bonding_curve_launchpad`, until the respective FA's `is_frozen` 
is toggled to `true` during **graduation**.

### Trading function
Constant product formula is used within `liquidity_pairs` for calculating `get_amount_out`, similar to 
[UniswapV2 on Ethereum](https://docs.uniswap.org/contracts/v2/concepts/protocol-overview/how-uniswap-works). 
Although chosen for familiarity and simplicity's sake, in a production environment, one may look towards other 
trading functions.

One style could encompass sublinear functions to reward early adopters more heavily.


## Related files
### `bonding_curve_launchpad.move`
* Contains public methods (both entry and normal), for the end user.
* Creates and holds references (transfer) to the launched Fungible Asset through the FA's respective Object.
* Dispatches to `liquidity_pairs` to create a new pair between the launched FA and APT.
* Facilitates swaps between any enabled FA and APT.
### `liquidity_pairs.move`
* Creates and holds references to each liquidity pair, through a named objects.
* Contains business logic for performing swaps on each pair.
* Performs graduation ceremony to disable liquidity pair, and move all reserves to an external, third party DEX.
### `test_bonding_curve_launchpad.move`
* E2E tests.
### `move-examples/swap`
* Fungible Asset DEX example from the `aptos-move` examples.


### Lifecycle of launched FA
#### Launching the FA and liquidity pair
1. User initiates FA creation on the `bonding_curve_launchpad` through `create_fa_pair(...)`.
   1. `bonding_curve_launchpad` creates a new dispatchable FA and assigns the `"FA Generator" Object` as the creator, by retrieving it's `signer` using a stored `extend_ref`. Importantly, the user initiating the FA does not have any permissions (mint, transfer, burn), preventing their ability to pre-mint. FA capabilities (`transfer_ref`) are stored within the FA's respective Object, for future transfers.
   2. The dispatchable `withdraw` function is defined to disallow all transfers between FA owners, until **graduation** is met. It does this through a state value associated with the FA's soon-to-be generated liquidity pair, called `is_frozen`, which is initially set to `true`. This prevents the FA from being traded on external DEXs or through external means. Transfers are only available through the limited `transfer_ref` stored on `bonding_curve_launchpad`, and restricted to swaps on the `liquidity_pairs`'s liquidity pair. 
   3. A pre-defined number of the FA is minted, and kept temporarily on `bonding_curve_launchpad`.
2. `bonding_curve_launchpad` creates a liquidity pair on the `liquidity_pairs` module, which follows the constant product formula.
   1. Liquidity pair is represented and stored as an Object. This allows for the reserves to be held directly on the object, rather than the `bonding_curve_launchpad` account.
   2. The entirety of minted FA + a pre-defined number of **virtual liquidity** for APT is deposited into the liquidity pair object. 
   3. Trading against the liquidity pair is enabled, but restricted to `public entry` functions found in `bonding_curve_launchpad`.
3. Optionally, the creator can immediately initiate a swap from APT to the FA.
#### Trading against the FA's associated liquidity pair
1. External users can swap APT to FA, or vice versa, through `public entry` methods available on `bonding_curve_launchpad`. 
   1. Although the normal `transfer` functionality of the FA is disabled by the custom dispatchable `withdraw` function, `bonding_curve_launchpad` can assist with swaps using it's stored `transfer_ref` from the FA's Object. `transfer_ref` is not impeded by the custom dispatchable function.
   2. The logic for calculating the `amountOut` of a swap is based on the constant product formula for reader familiarity. In a production scenario, a sub-linear trading function can assist in incentivizing general early adoption.
#### Graduating from `liquidity_pairs` to a public FA DEX
1. After each swap from APT to FA, when the APT reserves are increasing, a threshold is checked for whether the liquidity pair can **graduate** or not. The threshold is a pre-defined minimum amount of APT that must exist in the reserves. Once this threshold is met during a swap, **graduation** begins.
   1. The associated liquidity pair on the `liquidity_pairs` module is disabled by toggling `is_enabled`, preventing any more swaps against the pair. Additionally, the liquidity pair's `is_frozen` is disabled to allow owners to transfer freely. 
   2. The reserves from the liquidity pair, both APT and FA, are moved to an external, public third-party DEX as a new liquidity pair. In this case, the `aptos-move` FA DEX example, called swap. 
   3. To prevent any wrongdoing from the `bonding_curve_launchpad` owner, any liquidity tokens received during the creation of the new liquidity pair on the third-party DEX will be sent to a dead address. Otherwise, the tokens could be used to drain the liquidity pair, at any time.



## How to test:
```console
aptos move test --dev
```

## Example testnet deployments
[Bonding Curve Launchpad](https://explorer.aptoslabs.com/account/0x0bb954c7dda5fa777cb34d2e35f593ddc4749f1ab260017ee75d1d216a551841/transactions?network=testnet)

[Swap DEX](https://explorer.aptoslabs.com/account/0xe26bbe169db47aaa32349d253891af42134e1f6b64fef63f60105ec9ab6b240f/transactions?network=testnet?)

[Swap Deployer](https://explorer.aptoslabs.com/account/0x4d51c99abff19bfb5ca3065f1e71dfc066c38e334def24dbac2b2a38bee8b946?network=testnet)


## How to deploy:
0. **Note:** Since the `swap` module we're relying on as a third party DEX isn't on-chain, you'll need to first:
    * Deploy the `swap` module on-chain. Or, if you're on the testnet, you can use the [already-deployed `swap` smart contract](https://explorer.aptoslabs.com/account/0xe26bbe169db47aaa32349d253891af42134e1f6b64fef63f60105ec9ab6b240f/transactions?network=testnet?).
    * Rely on a different DEX for the token graduation.

From there, you can follow the [object code deployment](https://preview.aptos.dev/en/build/smart-contracts/learn-move/advanced-guides/object-code-deployment) steps to deploy and set up the smart contract.

### Testnet deployment
Deploy the `bonding_curve_launchpad` to the testnet referencing the already-deployed `swap` smart contract:
```console
aptos move publish --profile testnet_bonding_curve_launchpad \
--named-addresses bonding_curve_launchpad={REPLACE_WITH_YOUR_ACCOUNT},swap=0xe26bbe169db47aaa32349d253891af42134e1f6b64fef63f60105ec9ab6b240f,deployer=0x4d51c99abff19bfb5ca3065f1e71dfc066c38e334def24dbac2b2a38bee8b946
```

