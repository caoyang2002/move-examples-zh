# Aptos-Move 代码 / 项目示例

> 项目名沿用的原项目名称

1. [初始化 aptos 项目](./0-init-aptos-project/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>初始化项目概述</summary>
  <div>
  <li>创建一个基础的 aptos 项目，并输出 <code>hello_blockchain</code></li>
   </div>
</details>

2. [原始类型](./1-basic/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>测试项目概述</summary>
  <div>
  <li>赋值：<code>string::utf8 int number bool</code></li>
   <li>比较：<code>> < == >= <=</code></li>
   <li>算数：<code>+ - * / %</code></li>
   <li>逻辑：<code>| & ^ ! && ||</code></li>
   <li>位运算：`<<` / `>>`</li>
   </div>
</details>

3. [计数器](./3-aggregator_examples/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>计数概述</summary>
  <div>
  <li>实现了一个全局计数器</li>
  </div>
</details>

4. [创建一个资源](./4-argument_example/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>资源概述</summary>
  <div>
  <li>通过调用合约<code>设置链上数据</code>和<code>获取链上数据</code></li>
  </div>
</details>

5. [BCS 反序列化](./5-bcs-stream/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>反序列化概述</summary>
  <div>
  <li>从 BCS 格式的字节数组中反序列化 Move 原始类型</li>
  </div>
</details>

6. [DEX](./6-bonding_curve_launchpad/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>去中心化交易所概述</summary>
  <div>
  <li>为 FA 发行活动创造一个更直接和开放的环境</li>
  </div>
</details>

7. [没看明白](./7-cli-e2e-tests/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>...</summary>
  <div>
  <li>...</li>
  </div>
</details>

8. [没看明白](./8-cli_args/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>...</summary>
  <div>
  <li>...</li>
  </div>
</details>

9. [共享资源账户](./9-common_account/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>共享资源账户概述</summary>
  <div>
  <li>创建和管理共享资源账户，并允许其他账户使用这些资源的签名能力。</li>
  </div>
</details>

10. [DAO](./10-dao/)

<details style="margin-left: 48px;margin-top:-12px">
  <summary>去中心化自治组织</summary>
  <div>
  <li>创建一个与其现有 NFT 项目连接的 DAO</li>
 <li>创建可以在链上投票的提案</li>
 <li>完成并执行链上提案结果</li>
  </div>
</details>

11. [双向链表](./11-data_structures/)
<details style="margin-left: 48px;margin-top:-12px">
  <summary>基于双向链表实现的可迭代表</summary>
  <div>
  <li>用于管理键值对数据结构的操作</li>

  </div>
</details>

---

# README

[在 GitHub 中查看](https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/move-examples/move-tutorial)

要尝试这些示例，请按照以下步骤操作：

1. 克隆此仓库

   ```
   git clone https://github.com/aptos-labs/aptos-core.git
   ```

2. 打开一个新的终端，并通过运行 `cd aptos-move/move-examples` 导航到这个文件夹。

3. 进入你感兴趣的特定教程目录（例如 `cd hello_blockchain`）。

4. 你可以使用 Aptos CLI 来编译、测试、发布和运行这些合约，使用这里概述的命令：https://aptos.dev/move/move-on-aptos/cli/
   - 如果你需要安装 Aptos CLI，你可以按照这些说明进行：https://aptos.dev/tools/aptos-cli/install-cli/

**警告：** 这些 Move 示例尚未经过审计。如果你在生产系统中使用它们，请自行承担风险。
特别要注意那些包含复杂加密代码的 Move 示例（例如 `drand`, `veiled_coin`）。

# 贡献

## 编写 Move 示例

创建 Move 示例时，请使目录名称与源文件名称和包名称相同。

例如，对于 `drand` 随机信标示例，创建一个 `drand` 目录，并在其中创建一个 `sources/drand.move` 文件，文件中包含 `module drand::some_module_name { /* ... */ }`。
这是因为测试框架将仅根据目录名称分配地址给 `drand`，而不是基于 `drand.move` 中的命名地址。

## 运行测试

要为 **所有** 示例运行测试：

```
cargo test -- --nocapture
```

要为特定示例（例如 `hello_blockchain`）运行测试：

```
cargo test -- hello_blockchain --nocapture
```
