# 概述

这段代码是一个用于 Groth16 零知识证明系统的验证实现。

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


### `verify_proof` 函数
这个函数用于验证证明，它遵循 Groth16 证明系统的原始论文定义。函数的输入参数包括：
- `vk_alpha_g1`、`vk_beta_g2`、`vk_gamma_g2`、`vk_delta_g2`：验证密钥的组成部分。
- `vk_uvw_gamma_g1`：一个向量，包含公共输入的加权组合。
- `public_inputs`：公共输入的向量。
- `proof_a`、`proof_b`、`proof_c`：证明的三个组成部分。

在函数中，首先计算左侧的pairing值 `left`，然后构造右侧的加权组合 `right`，包括：
- `vk_alpha_g1` 和 `vk_beta_g2` 的pairing。
- `vk_uvw_gamma_g1` 和 `vk_gamma_g2` 的pairing。
- `proof_c` 和 `vk_delta_g2` 的pairing。

最后，通过调用 `eq` 函数比较 `left` 和 `right` 的值，返回比较结果作为函数的输出。

### `verify_proof_prepared` 函数
这个函数是 `verify_proof` 的优化版本，旨在降低验证延迟。不同之处在于，它接受一组预先计算好的验证密钥成员，并要求这些成员在传递之前已经进行了计算和准备。函数的输入参数包括：
- `pvk_alpha_g1_beta_g2`：预先计算的 `vk_alpha_g1` 和 `vk_beta_g2` 的乘积。
- `pvk_gamma_g2_neg`、`pvk_delta_g2_neg`： `vk_gamma_g2` 和 `vk_delta_g2` 的负值。
- `pvk_uvw_gamma_g1`、`public_inputs`、`proof_a`、`proof_b`、`proof_c`：与 `verify_proof` 函数相同。

在函数中，构造了左侧的元素向量 `g1_elements` 和 `g2_elements`，然后调用 `eq` 函数比较 `pvk_alpha_g1_beta_g2` 和 `multi_pairing` 函数的结果。

### `verify_proof_prepared_fq12` 函数
这个函数与 `verify_proof_prepared` 类似，但要求 `pvk_alpha_g1_beta_g2` 是 `Fq12` 的一个元素，而不是它的子群 `Gt` 的一个元素。这种变体可以节省 `Gt` 反序列化的开销。

### 测试函数
代码末尾的测试函数 `test_verify_proof_with_bls12381`、`test_verify_proof_prepared_with_bls12381` 和 `test_verify_proof_prepared_fq12_with_bls12381` 演示了如何使用这些验证函数来验证具体的MIMC证明。测试函数中通过 `deserialize` 函数将十六进制字符串转换为具体的加密代数元素，并使用 `assert!` 断言来检验验证函数的正确性。

总体来说，这些代码是用于实现Groth16零知识证明系统的一部分，并提供了不同级别的优化来平衡验证速度和计算开销。