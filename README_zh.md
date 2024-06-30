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

