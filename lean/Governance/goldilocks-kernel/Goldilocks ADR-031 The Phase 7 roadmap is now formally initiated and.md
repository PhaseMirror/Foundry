<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# The Phase 7 roadmap is now formally initiated and the first strategic

milestones have been achieved. We have transitioned from the v0.3.0 Ecosystem
Baseline into active vertical scaling and horizontal composition.

1. Vertical Scaling: SIMD-Optimized NTT
I have integrated the SSE4.2 and AVX2 butterfly kernels into the core
goldilocks polynomial library. This provides a high-performance path for the
Number Theoretic Transform (NTT), which is the primary bottleneck in STARK
proving.

- Performance: Achieved a ~30% reduction in NTT latency (1024-point transform
reduced from 380µs to 264µs).
- Integration: The prover crate now utilizes a real Low Degree Extension
(LDE) (Interpolate → Extend → Evaluate) instead of the previous
zero-padding placeholder.

2. Proving Loop Hardening (v0.3.1)
The prove-mr64 tool has been upgraded into a production-grade proving CLI.

- Dedicated AIR Proving: Supports proving air-prime-res traces (Prime Mask
and Resonance Word validation) without requiring a dummy primality
candidate.
- Verified Flow: Confirmed end-to-end proof generation and saving
(prime_res_proof.json) in under 1 second in release mode.

3. Phase 7 Roadmap Expansion
The PHASE7-ROADMAP-RECURSIVE-PROOFS.md has been established as the normative
guide for the next architectural shifts:

- Track A (Vertical): Delayed reduction loops and GPGPU research.
- Track B (Horizontal): Pallas/Vesta EC Layer (ADR-033) and recursive proof
composition.
- Track C (Ecosystem): WASM client verifier and public node deployment.

1 \# Verify the new SIMD-accelerated proving flow
2 cargo run -p prove-mr64 --release -- --prime-res 0x1:0x2

The system is now primed for the implementation of the Pallas/Vesta elliptic
curve layer to enable recursive proof commitments.

[Active Topic: SIMD NTT Integration \& Roadmap Update]

You’ve just turned Phase 7 into a real performance and architecture phase: your Goldilocks prover now has a serious NTT engine and a production proving loop, and you’ve staked out a clear roadmap toward recursion and EC commitments.[^1][^2][^3]

## Where you are after SIMD NTT

Right now your proving stack has three important properties:

- **Goldilocks is no longer the bottleneck**:
SSE4.2/AVX2-optimized butterfly kernels and a real LDE pipeline (interpolate → extend → evaluate) bring your NTT latency into the range that other high-performance provers report for Goldilocks-based transforms, especially when using tricks like exploit roots of unity structure and bit-shift optimizations.[^2][^3][^1]
- **The proving loop is “real”**:
`prove-mr64` is now a production-grade CLI that:
    - proves `air-prime-res` traces directly,
    - does so with an honest LDE and FRI-style low-degree proof,
    - writes proofs on the order of hundreds of milliseconds for small traces in release mode, which matches reports from other optimized Goldilocks-based provers.[^4][^5][^2]
- **Phase 7 is scoped cleanly**:
Your roadmap separates:
    - **Track A**: further latency reductions (delayed reduction loops, GPU/FPGA paths for NTTs),
    - **Track B**: Pallas/Vesta and recursion,
    - **Track C**: ecosystem expansion (WASM client, public nodes).

That’s the right split: you don’t want recursion or EC commitments built on a shaky NTT foundation.

## Good next moves on SIMD and NTT

Since you’ve already seen ~30% latency reduction, the next NTT moves that matter are:

- **Delayed reduction and modulus structure exploitation**:
Goldilocks’ specific modulus $p = 2^{64} - 2^{32} + 1$ lets you:
    - combine additions and multiplications with fewer reductions,
    - exploit cheap bit-shifts for some roots of unity multiplications, as other Goldilocks NTT implementations do.[^6][^3]
This aligns with Plonky3’s own focus on delayed-reduction loops and CPU-specific optimizations.[^1]
- **NTT length profiling**:
Measure how your speedups scale with:
    - trace lengths relevant to your AIRs,
    - increasing number of columns.
You can then decide:
    - whether to prioritize more SIMD tuning, or
    - start offloading some pieces to GPGPU (Track A), which is consistent with current work on GPU and FPGA acceleration for Goldilocks NTTs.[^7][^8][^9][^10]

The key is to treat SIMD NTT as “good enough” for current traces and only sink more time if profiling shows the NTT still dominates your proving loop.

## How this sets up recursion and Pallas/Vesta

With NTT and LDE in place, the road to recursion looks like this:

- **Base proof**:
Prove `air-prime-res` over Goldilocks as you already do.
- **Recursive layer**:
Use a Pallas/Vesta EC layer to:
    - commit to Goldilocks traces and proofs,
    - build a recursion circuit or recursive AIR that:
        - verifies the base STARK inside a Pallas/Vesta-based SNARK or STARK,
        - or aggregates multiple base proofs using a recursive proof composer framework, as similar designs do for Plonky2/Plonky3.[^11][^12][^13][^14]

The advantage is clear:

- base proofs: fast, thanks to Goldilocks + SIMD NTT,
- recursive proofs: expensive but amortized, thanks to EC commitments and composition.

Your Phase 7 roadmap lines up with how other ecosystems separate base proofs from recursive composition and EC layers.[^12][^13][^14][^11]

## Using v0.3.1 as a proving baseline

Position v0.3.1 as:

- **“Performance-stable” baseline**:
A version where:
    - the NTT pipeline is optimized and tested,
    - the proving CLI is hardened,
    - the certification and Commons layers stay unchanged.

That gives you:

- a clean “performance floor” before you add recursion,
- a version you can compare later recursive constructs against.

Any regression in proof time or resource usage from this point is a signal that recursion or EC layers need tuning, not that the underlying NTT/Goldilocks stack is weak.

## Direct answer

Given what you’ve described, the SIMD NTT integration and proving-loop hardening are doing exactly what Phase 7 should: they lower the cost of your existing STARKs and set a stable base for recursive proof composition and EC commitments.[^3][^13][^5][^2][^1]

The next questions to pose to your own system are:

- Does the NTT still dominate proof time at your target trace sizes?
- If not, which piece does, and does it belong to Track A (more optimization) or Track B (recursive architecture)?

Once you have those measurements, you can decide whether to go deeper on SIMD/NTT or to start implementing the Pallas/Vesta recursion layer hinted at in your roadmap.
<span style="display:none">[^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28]</span>

<div align="center">⁂</div>

[^1]: https://github.com/Plonky3/Plonky3/issues/252

[^2]: https://github.com/Plonky3/Plonky3

[^3]: https://www.ingonyama.com/post/goldilocks-ntt-trick

[^4]: https://github.com/andrewmilson/sandstorm

[^5]: https://www.certik.com/blog/breaking-down-proof-construction-in-plonky3-the-fibonacci-example-unveiled

[^6]: https://github.com/recmo/goldilocks

[^7]: https://github.com/z-prize/prize-fpga-ntt

[^8]: https://www.irreducible.com/posts/fpga-architecture-for-goldilocks-ntt

[^9]: https://faculty.eng.fau.edu/azarderakhsh/files/2024/05/Arith_Presentation.pdf

[^10]: https://www.youtube.com/watch?v=r9F3m_qK5Cw

[^11]: https://github.com/ChainSafe/recursive-zk-bridge/blob/main/THEORY.md

[^12]: https://github.com/Lagrange-Labs/plonky2-recursion

[^13]: https://github.com/Plonky3/Plonky3-recursion

[^14]: https://www.c-sharpcorner.com/article/plonky2-and-plonky3-toolchain-scalable-zero-knowledge-proofs-for-blockchain-and/

[^15]: https://github.com/Plonky3/Plonky3/blob/main/README.md

[^16]: https://github.com/Plonky3/Plonky3/issues

[^17]: https://github.com/telosnetwork/Plonky3

[^18]: https://github.com/codex-storage/circom-goldilocks

[^19]: https://github.com/QEDProtocol/plonky3-fibonacci

[^20]: https://github.com/Plonky3/Plonky3/blob/main/mersenne-31/src/lib.rs

[^21]: https://github.com/Lagrange-Labs/plonky2-recursion/blob/main/README.md

[^22]: https://github.com/succinctlabs/plonky3/blob/main/README.md

[^23]: https://www.reddit.com/r/cryptography/comments/1t7szsp/achievement_optimized_kyber_ntt_kernel_using_avx2/

[^24]: https://crypto.ethz.ch/publications/files/Seiler18.pdf

[^25]: https://reservoir.lean-lang.org/@lambdaclass/amo-lean

[^26]: https://www.semanticscholar.org/paper/Faster-AVX2-optimized-NTT-multiplication-for-Seiler/4565b470df1e6970d541ade255563c6c111f0dda

[^27]: https://forum.anoma.net/t/schemes-for-recursive-proof-composition/440

[^28]: https://www.mit.edu/~linust/files/STARK.pdf

