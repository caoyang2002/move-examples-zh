# 安装 Aptos prover 依赖


## [安装 dotnet](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)

[下载 Mac 运行时 6.0.33](https://download.visualstudio.microsoft.com/download/pr/5f558675-c42d-46ad-904b-66f8e720391b/2e135412543676a0b2f554e6a8fae3ae/dotnet-runtime-6.0.33-osx-arm64.pkg)

验证安装

```bash
dotnet --version                                                     
```

## [安装 boogie](https://github.com/boogie-org/boogie)

```bash
dotnet tool install --global boogie --version  3.0.9.0
```

验证安装

```bash
boogie -version
```

>[!TIP]
> 卸载
>
> ```bash
> dotnet tool uninstall --global boogie 
> ```


## [安装 z3](https://github.com/Z3Prover/z3)

[查看 github 中的 z3 tag：4.11.2](https://github.com/Z3Prover/z3/tree/z3-4.11.2)

```bash
git clone git@github.com:Z3Prover/z3.git
git tag
git checkout z3-4.11.2 # 却换到指定的 tag，当前之支持 4.11.2 (2024/09/08)
python3 scripts/mk_make.py 
cd build
make
```

验证安装

```bash
./z3 --version
```

将 z3 复制到指定的文件夹

例如，我是"/Users/simons/bin/z3"，这个路径在设置环境变量的时候会用到

```bash
cp ./z3 /Users/simons/bin/
```


## 设置环境变量

### boogie

```bash
export BOOGIE_EXE="/Users/simons/.dotnet/tools/boogie"   
```

### z3

```bash
export Z3_EXE="/Users/simons/bin/z3"
# /Users/simons/bin/z3 是 z3 二进制文件的路径
```

## 在 aptos-core 中测试

> 克隆 aptos-core repo
> ```bash
> git clone https://github.com/aptos-labs/aptos-core
> cd aptos-core
> ```

执行 prove

```bash
aptos move prove --package-dir aptos-move/move-examples/hello_prover/
```

在当前文件夹中执行 prove

```bash
aptos move prove
```


# 详解

# `aptos move prove` 命令解析

```bash
$ aptos move prove -help
验证 Move 包

用法：aptos move prove [选项]

选项：
      --dev
          启用开发模式，使用所有的开发地址和开发依赖
      --package-dir <PACKAGE_DIR>
         Move 包的路径（包含 Move.toml 文件的文件夹）
      --output-dir <OUTPUT_DIR>
         保存编译后的 Move 包的路径
      --named-addresses <NAMED_ADDRESSES>
         Move 二进制文件的命名地址 [默认: ]
      --override-std <OVERRIDE_STD>
         通过主网/测试网/开发网覆盖标准库版本 [可能的值: mainnet, testnet, devnet]
      --skip-fetch-latest-git-deps
         跳过获取最新的 git 依赖
      --bytecode-version <BYTECODE_VERSION>
         指定编译器将要发出的字节码版本
      --compiler-version <COMPILER_VERSION>
         指定编译器的版本。目前，默认为 `v1`
      --language-version <LANGUAGE_VERSION>
         指定要支持的语言版本。目前，默认为 `v1`
      --skip-attribute-checks
         不检查 Move 代码中的未知属性
      --check-test-code
         对测试代码也应用 Aptos 的扩展检查（例如 `#[view]` 属性）。注意：此行为将来会成为默认设置。详见 <https://github.com/aptos-labs/aptos-core/issues/10335>  [环境变量: APTOS_CHECK_TEST_CODE=]
  -v, --verbosity <VERBOSITY>
         详细程度
  -f, --filter <FILTER>
         从包中过滤目标。任何具有匹配文件名的模块都将是目标，类似于 `cargo test`
  -t, --trace
         是否在错误报告中显示额外信息。这可能有助于调试，但也可能使验证变慢
      --cvc5
         是否使用 cvc5 作为 smt 求解器后端。环境变量 `CVC5_EXE` 应指向二进制文件
      --stratification-depth <STRATIFICATION_DEPTH>
         扩展分层函数的深度 [默认: 6]
      --random-seed <RANDOM_SEED>
         验证器的种子 [默认: 0]
      --proc-cores <PROC_CORES>
         用于并行处理验证条件的核心数 [默认: 4]
      --vc-timeout <VC_TIMEOUT>
         每个验证条件的求解器（软）超时时间，以秒为单位 [默认: 40]
      --disallow-global-timeout-to-be-overwritten
         是否禁用全局超时覆盖。设置了这个标志为 true 时，由 "--vc-timeout" 设置的值将全局使用
      --check-inconsistency
         是否通过注入不可能的断言来检查规范的一致性
      --unconditional-abort-as-inconsistency
         是否在检查一致性时将中止视为不一致。需要与 check-inconsistency 一起使用
      --keep-loops
         是否保留循环原样并将其传递给底层求解器
      --loop-unroll <LOOP_UNROLL>
         展开循环的迭代次数
      --stable-test-output
         例如诊断的输出是否应该是稳定的/编辑过的，以便可以在测试输出中使用
      --dump
         是否将中间步骤结果转储到文件
  -h, --help
         打印帮助信息（更多信息请使用 '--help')
  -V, --version
         打印版本信息
```