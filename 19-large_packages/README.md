这个软件包提供了一个实验性服务，用于将非常大的模块上传到 Aptos 网络。要使用这个 API 发布，你必须将你的元数据和模块分割成多个调用到 `large_packages::stage_code`。具体来说：

* 确保 LargePackages 已经部署到你选择的网络上，你目前在测试网上可以找到它在地址 `0xd20f305e3090a24c00524604dc2a42925a75c67aa6020d33033d516cf0878c4a`
* 编译你的包
* 将元数据和模块分块，并调用 `large_packages::stage_code`
* 在你对 `large_packages::stage_code` 的最后一次调用中将 `publish` 设置为 `true`

上述逻辑目前在 Python SDK 中实现：`aptos-core/ecosystem/python/sdk/aptos_sdk/package_publisher.py`

为了验证目的，这包含了一个包，`large_package_example`，它超出了单笔交易发布要求。

这个框架有一些限制：
* 在发布尝试之前没有一致性检查
* 模块代码没有跨块分割，所以如果单个模块太大，它将无法工作


---

This package provides an experimental service for uploading very large modules to the Aptos network. To publish using this API, you must divide your metadata and modules across multiple calls into `large_packages::stage_code`. Specifically:

* Make sure LargePackages is deployed to your network of choice, you can currently find it on testnet at `0xd20f305e3090a24c00524604dc2a42925a75c67aa6020d33033d516cf0878c4a`
* Compile your package
* Chunk up the metadata and modules and call `large_packages::stage_code`
* In your last call to `large_packages::stage_code` set `publish` to `true`

The above logic is currently implemented in the Python SDK: `aptos-core/ecosystem/python/sdk/aptos_sdk/package_publisher.py`

For validation purposes, this contains a package, `large_package_example` that exceeds the requirements for publishing in a single transaction.

This framework has some limitations:
* There is no consistency checking until the publishing attempt
* Module code is not split across chunks, so if a single module is too big, it won't work
