这为 Aptos 链上资产市场的标准奠定了核心基础。

这个包的目标是：
* 为了可读性和随时间的扩展，分离核心逻辑组件。
* 尽可能利用函数 API 作为兼容性层，而不是暴露数据结构。
* 利用对象和资源组统一通用逻辑，避免存储浪费。
* 为创建列表的市场统一定义费用计划。
* 为拍卖和固定价格列表提供统一框架。
* 支持 TokenV1、TokenV2 和基于对象的资产。
* 支持以 Coin 或 FungibleAsset 形式接收资金。

费用计划包括：
* 列表、出价和佣金
* 清晰的界面，允许随着时间的推移添加新的业务逻辑，通过传入当前定价信息

所有列表支持：
* 指定固定购买价格的能力
* 定义何时可以开始购买
* 嵌入托管市场的费用计划
* 如果接收方未启用直接存款，则为 tokenv1 持有容器

拍卖支持：
* 立即购买
* 基于最后一次出价时间的递增结束时间
* 最小出价增量

固定价格支持：
* 卖家可以随时结束。

收藏品报价：
* 提供者可以随时结束。

这是对理想市场框架的探索。请提出拉取请求以扩展它并概括我们的用例。除非社区团结起来支持一个共同的市场并加以利用，否则这可能永远不会在主网上实际部署。


# 快速开始

```bash
aptos move test
```


---
This introduces the core for a potential Aptos standard around marketplace for assets on-chain.

The goals of this package are to
* Separate core logical components for readability and expansion over time.
* Where possible leverage function APIs as the layer of compatibility instead of exposing data structures.
* Leverage of objects and resource groups to unify common logic without wasting storage.
* Single definition of a fee schedule for the marketplace where the listing was created.
* Unified framework for auctions and fixed-price listings.
* Support for TokenV1, TokenV2, and Object based assets.
* Support for receiving funds in either Coin or FungibleAsset.

FeeSchedule includes:
* Listing, bidding, and commission
* Clean interface that allows newer business logic to be added over time, by passing in current pricing information

All listings support:
* Ability to specify a fixed purchase price
* Define when purchasing may begin
* Embed a fee schedule for the hosting marketplace
* Holding container for tokenv1 if the recipient does not have direct deposit enabled

Auctions support:
* Buy-it-now
* Incremental end times based upon the last bid time
* Minimum bid increments

Fixed-price support:
* Seller can end at any time.

Collection offer:
* Offerer can end at any time.

This is intended as an exploration into the ideal marketplace framework. Please make pull requests to extend it and generalize our use cases. This may never actually be deployed on Mainnet unless the community rallies behind a common marketplace and harness.
