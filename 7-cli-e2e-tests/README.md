# CLI 端到端测试

这些软件包，每个生产网络一个，由 CLI 端到端测试用来测试 `aptos move` 子命令组的正确性。因此，这些包中包含的内容并没有特别的理由或规律，它们应该是一个表达性的精选集，包含我们可能想要断言的不同新特性。

目前，这3个包共享相同的源代码。将来，我们可能想要使用这些测试来确认 CLI 与新特性在开发网络、测试网络和主网络中的协同工作情况。为此，我们需要将源代码分开。


# CLI E2E tests
These packages, one per production network, are used by the CLI E2E tests to test the correctness of the `aptos move` subcommand group. As such there is no particular rhyme or reason to what goes into these, it is meant to be an expressive selection of different, new features we might want to assert.

As it is now the 3 packages share the same source code. Down the line we might want to use these tests to confirm that the CLI works with a new feature as it lands in devnet, then testnet, then mainnet. For that we'd need to separate the source.
