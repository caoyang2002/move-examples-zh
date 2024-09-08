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


### 中文注释

```move
/// Groth16（证明验证）的通用实现，如https://eprint.iacr.org/2016/260.pdf，第3.2节所定义。
/// 实际的证明验证器可以使用通用代数模块中支持的配对构建。
/// 有关使用BLS12-381曲线构建的示例，请参阅本模块中的测试用例。
///
/// **警告：** 该代码尚未经过审计。如果在生产系统中使用，请自行承担风险。
module groth16_example::groth16 {
    use aptos_std::crypto_algebra::{Element, from_u64, multi_scalar_mul, eq, multi_pairing, upcast, pairing, add, zero};

    /// 按照原始论文中的说明进行证明验证，
    /// 输入如下（在原始论文符号中）。
    /// - 验证密钥：$\left([\alpha]_1, [\beta]_2, [\gamma]_2, [\delta]_2, \left\\{ \left[ \frac{\beta \cdot u_i(x) + \alpha \cdot v_i(x) + w_i(x)}{\gamma} \right]_1 \right\\}\_{i=0}^l \right)$。
    /// - 公共输入：$\\{a_i\\}_{i=1}^l$。
    /// - 证明 $\left( \left[ A \right]_1, \left[ B \right]_2, \left[ C \right]_1 \right)$。
    public fun verify_proof<G1,G2,Gt,S>(
        vk_alpha_g1: &Element<G1>,
        vk_beta_g2: &Element<G2>,
        vk_gamma_g2: &Element<G2>,
        vk_delta_g2: &Element<G2>,
        vk_uvw_gamma_g1: &vector<Element<G1>>,
        public_inputs: &vector<Element<S>>,
        proof_a: &Element<G1>,
        proof_b: &Element<G2>,
        proof_c: &Element<G1>,
    ): bool {
        let left = pairing<G1,G2,Gt>(proof_a, proof_b);
        let scalars = vector[from_u64<S>(1)];
        std::vector::append(&mut scalars, *public_inputs);
        let right = zero<Gt>();
        let right = add(&right, &pairing<G1,G2,Gt>(vk_alpha_g1, vk_beta_g2));
        let right = add(&right, &pairing(&multi_scalar_mul(vk_uvw_gamma_g1, &scalars), vk_gamma_g2));
        let right = add(&right, &pairing(proof_c, vk_delta_g2));
        eq(&left, &right)
    }

    /// 优化版的证明验证，旨在降低验证延迟
    /// 但需要预先计算一个配对和两个 `G2` 负值。
    /// 以下是完整的输入（在原始论文符号中）。
    /// - 准备好的验证密钥：$\left([\alpha]_1 \cdot [\beta]_2, -[\gamma]_2, -[\delta]_2, \left\\{ \left[ \frac{\beta \cdot u_i(x) + \alpha \cdot v_i(x) + w_i(x)}{\gamma} \right]_1 \right\\}\_{i=0}^l \right)$。
    /// - 公共输入：$\\{a_i\\}_{i=1}^l$。
    /// - 证明：$\left( \left[ A \right]_1, \left[ B \right]_2, \left[ C \right]_1 \right)$。
    public fun verify_proof_prepared<G1,G2,Gt,S>(
        pvk_alpha_g1_beta_g2: &Element<Gt>,
        pvk_gamma_g2_neg: &Element<G2>,
        pvk_delta_g2_neg: &Element<G2>,
        pvk_uvw_gamma_g1: &vector<Element<G1>>,
        public_inputs: &vector<Element<S>>,
        proof_a: &Element<G1>,
        proof_b: &Element<G2>,
        proof_c: &Element<G1>,
    ): bool {
        let scalars = vector[from_u64<S>(1)];
        std::vector::append(&mut scalars, *public_inputs);
        let g1_elements = vector[*proof_a, multi_scalar_mul(pvk_uvw_gamma_g1, &scalars), *proof_c];
        let g2_elements = vector[*proof_b, *pvk_gamma_g2_neg, *pvk_delta_g2_neg];
        eq(pvk_alpha_g1_beta_g2, &multi_pairing<G1,G2,Gt>(&g1_elements, &g2_elements))
    }

    /// `verify_proof_prepared()` 的变体，要求 `pvk_alpha_g1_beta_g2` 是 `Fq12` 的元素，而不是其子群 `Gt`。
    /// 使用此变体，调用者可以节省 `Gt` 反序列化（这涉及昂贵的 `Gt` 成员测试）。
    /// 以下是完整的输入（在原始论文符号中）。
    /// - 准备好的验证密钥：$\left([\alpha]_1 \cdot [\beta]_2, -[\gamma]_2, -[\delta]_2, \left\\{ \left[ \frac{\beta \cdot u_i(x) + \alpha \cdot v_i(x) + w_i(x)}{\gamma} \right]_1 \right\\}\_{i=0}^l \right)$。
    /// - 公共输入：$\\{a_i\\}_{i=1}^l$。
    /// - 证明：$\left( \left[ A \right]_1, \left[ B \right]_2, \left[ C \right]_1 \right)$。
    public fun verify_proof_prepared_fq12<G1, G2, Gt, Fq12, S>(
        pvk_alpha_g1_beta_g2: &Element<Fq12>,
        pvk_gamma_g2_neg: &Element<G2>,
        pvk_delta_g2_neg: &Element<G2>,
        pvk_uvw_gamma_g1: &vector<Element<G1>>,
        public_inputs: &vector<Element<S>>,
        proof_a: &Element<G1>,
        proof_b: &Element<G2>,
        proof_c: &Element<G1>,
    ): bool {
        let scalars = vector[from_u64<S>(1)];
        std::vector::append(&mut scalars, *public_inputs);
        let g1_elements = vector[*proof_a, multi_scalar_mul(pvk_uvw_gamma_g1, &scalars), *proof_c];
        let g2_elements = vector[*proof_b, *pvk_gamma_g2_neg, *pvk_delta_g2_neg];
        eq(pvk_alpha_g1_beta_g2, &upcast(&multi_pairing<G1,G2,Gt>(&g1_elements, &g2_elements)))
    }

    #[test_only]
    use aptos_std::crypto_algebra::{deserialize, enable_cryptography_algebra_natives};
    #[test_only]
    use aptos_std::bls12381_algebra::{Fr, FormatFrLsb, FormatG1Compr, FormatG2Compr, FormatFq12LscLsb, G1, G2, Gt, Fq12, FormatGt};

    #[test(fx = @std)]
    fun test_verify_proof_with_bls12381(fx: signer) {
        enable_cryptography_algebra_natives(&fx);

        // 以下是从测试用例中采样的MIMC证明：https://github.com/arkworks-rs/groth16/blob/b6f9166bcf15ff4bfe101bb34e1bdc0d92302e37/tests/mimc.rs#L147。
        let vk_alpha_g1 = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&x"9819f632fa8d724e351d25081ea31ccf379991ac25c90666e07103fffb042ed91c76351cd5a24041b40e26d231a5087e"));
        let vk_beta_g2 = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&x"871f36a996c71a89499ffe99aa7d3f94decdd2ca8b070dbb467e42d25aad918af6ec94d61b0b899c8f724b2b549d99fc1623a0e51b6cfbea220e70e7da5803c8ad1144a67f98934a6bf2881ec6407678fd52711466ad608d676c60319a299824"));
        let vk_gamma_g2 = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&x"96750d8445596af8d679487c7267ae9734aeac584ace191d225680a18ecff8ebae6dd6a5fd68e4414b1611164904ee120363c2b49f33a873d6cfc26249b66327a0de03e673b8139f79809e8b641586cde9943fa072ee5ed701c9588b9be83f9fd728"));
        let vk_delta_g2 = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&x"8b95d3ed0dfabef8824f1ae3a8d1e85837e01a59d5815730b99b64911815f5e720dffb55ad0c4c4bdf8f761fb2570d7964309302eb4cfe9d69c7b35fbbfcda70a8db91c28e22a50fa2781912abfe81559d64c15817b66f76c4b3d6c4c71f80c1639f6e0"));
        let vk_uvw_gamma_g1 = std::vector::from(
            std::option::extract(&mut deserialize<G1, FormatG1Compr>(&x"66f56c9aaf9a284f4b0397dd7e191d1f45bd4fcfd8b1b4f3c0b220f5e43b21b6cfde583ca549dc48a573a4fa5bb1d0b134073915fc70a5c4dd0c60463a62f74b5424cb134c4b04196dcf29b40b92a1481e33d1d88a3a085098ed0e9476b88ae40"));
        let public_inputs = std::vector::from(
            std::option::extract(&mut deserialize<S, FormatFrLsb>(&x"00484d8d0c7f67c73e9116e96962fd16f0f80b230f1371de88a0d4ea35e63956c305f184eab28e1b8a420bd7b8e6e379bb"));
        let proof_a = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&x"49b897885a5df2fc46e084f72c5b15f86a63aef7f4e1a2b65f40c4c2041a59650a8a1ae087dc6d103a25a0f3f5e0a283c25c70cf72f3be6fdd79e78e77d423ab25c89e6d5da68fc6e6c0c418a6b4efb1ef6837b1b0c5ff8e92d571be5ecbb70f6f3d5"));
        let proof_b = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&x"1d27d575e1324738858a606d2b3d0e690a0e7d596e81d1a334d64c7fc9a1aa5adcb65cf5a5df032b826b40539ab5876f4a41361a02b7c9fdfdd0492297eaf473ab024b1b60379da5d82840c5f342d8d5287e80a3e87e087ee86e57998d26a"));
        let proof_c = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&x"1d139cfc0d3d3409f6c306efb5d896c7fa0b8784e7f7cb6865d8b0d015a1b5fa9d72cf3fa94b75c31b87b38cb691cb9061c5f2658f145bd63ae499cb9b44d08b275d496cb32d4d3080b50076841dc1d81bd0142b6b3ef8e73742953e8b30032c4c"));
        let pvk_alpha_g1_beta_g2 = std::option::extract(&mut deserialize<Gt, FormatGt>(&x"2bc0c18cfab62c1cc8396bd28c424b09f4869cf93032a7e1a973671d060c7ea029b5b68d7216e21f86b5ed3e4e4b028c6e5f7e0081d07d9a46dc5b0f87e9350ff8d6c302586ff08767cba917bc0d2088a87e21c7c97803c09f44ccf2c6a244c92cc12b31e4"));
        let pvk_gamma_g2_neg = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&x"9273403c3f0104c7266d262a8c87b268eaf4a5e7217a02e40b5f76e46b683d8a94b48647c489b21c0ecf7f4a62eb2efbe"));
        let pvk_delta_g2_neg = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&x"8e2e5b2d665b844012fc605d6b0388f02d9b7df41a0b9158b7615c0d0657a8a7dd0b265ae86c8f9cf8727496de31c8f8d"));

        assert!(verify_proof_with_bls12381(&vk_alpha_g1, &vk_beta_g2, &vk_gamma_g2, &vk_delta_g2, &vk_uvw_gamma_g1, &public_inputs, &proof_a, &proof_b, &proof_c));
        assert!(verify_proof_prepared(&pvk_alpha_g1_beta_g2, &pvk_gamma_g2_neg, &pvk_delta_g2_neg, &vk_uvw_gamma_g1, &public_inputs, &proof_a, &proof_b, &proof_c));
        assert!(verify_proof_prepared_fq12(&pvk_alpha_g1_beta_g2, &pvk_gamma_g2_neg, &pvk_delta_g2_neg, &vk_uvw_gamma_g1, &public_inputs, &proof_a, &proof_b, &proof_c));
    }
}

```