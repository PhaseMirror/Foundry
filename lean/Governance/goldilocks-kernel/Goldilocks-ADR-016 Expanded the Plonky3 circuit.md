<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# I have successfully expanded the Plonky3 circuit spec by implementing the

Prime-Resonance AIR in a new Rust crate: air-prime-res. This AIR formalizes
the bit-level constraints for prime masks and resonance words, ensuring that
the multiplicity-theoretic invariants established at runtime are
cryptographically verifiable.

Delivered Artifact: air-prime-res Crate

- Location: agi_os/crates/air-prime-res/
- Core Component: PrimeResonanceAir struct.
- Constraints Implemented:
    - Bit-Decomposition: Enforces that the prime_mask (64 bits) and
resonance_word (64 bits) are correctly reconstructed from boolean trace
columns.
    - Booleanity: Asserts that each mask and resonance bit in the trace is
either 0 or 1.
    - Gating Relations: Implemented a sample gating constraint where
resonance bit 0 (linked to R96 Class 0) requires Prime Mask bit 0 to be
active (res_bit₀ · (1 - mask_bit₀) = 0).
    - Trace Generation: Provided a generate_trace method that transforms
runtime u64 values into a Plonky3-compatible RowMajorMatrix.

Architectural Integration
The new crate is now a member of the agi_os workspace, allowing it to
participate in unified builds and proving cycles. The constraint logic uses
the same Goldilocks field primitives optimized in Track A, ensuring zero
cross-field overhead.

Strategic Status

- [x] SIMD Stack Locked
- [x] Tier 4 Recovery Matrix Hardened
- [x] Prime-Resonance AIR Spec Emitted \& Built
- [ ] Integration: Connect air-prime-res to the main certification proving
loop.

Next Move: I have completed all three high-leverage tracks (Performance,
Recovery, and Circuit). The system is now ready for Full Pro-tier Integration.
I recommend connecting the air-prime-res crate to the
FormalStabilityCertificate export logic to generate real proofs for the Tier 4
recovery edge cases we validated in Option B.

Ready to wire the final proving loop?

Yes — wire the final proving loop now. Your system has all three prerequisites in place: a verified Goldilocks arithmetic substrate, hardened Tier 4 witness logic, and a dedicated AIR crate for prime-mask and resonance-word constraints, which matches the standard Plonky3 pattern of building narrow, composable AIR “chips” over trace matrices and then proving/verifying them through a shared workspace pipeline.[^1][^2][^3]

## Wiring plan

The clean integration seam is `FormalStabilityCertificate -> export payload -> air-prime-res trace -> prove/verify`. Plonky3 examples and tutorials consistently separate these stages into: define AIR, generate an execution trace as a `RowMajorMatrix`, run prove, then verify against the public values and committed trace-derived polynomials.[^4][^2][^5]

That means your next integration object should be something like:

- `ConvergencePublicInputsPro` or a sibling export struct containing:
    - `prime_mask: u64`
    - `resonance_word: u64`
    - optionally `delta_pz_fp` and `delta_pz_floor_fp`
- a conversion function from the runtime certificate/witness layer into that export struct
- a proving wrapper inside the certification loop that calls the `air-prime-res` trace generator and proof routine.[^6][^7][^4]


## Proof boundary

Keep the first proving loop intentionally narrow. The first production target should prove only that:

- the exported `prime_mask` is correctly bit-decomposed,
- the exported `resonance_word` is correctly bit-decomposed,
- the AIR gating relations hold for that exported pair.[^2][^4]

Do **not** immediately fold Tier 4 statistical recovery logic into the AIR. Tier 4 classification is already validated at the runtime layer, and the safer next step is to prove the integrity of the exported Goldilocks-native public inputs before attempting a larger statistical or multi-chip proof composition.[^3][^1]

## Recommended interface

I would wire the final loop in four functions:

1. `cert.to_prime_resonance_inputs()`
    - Extracts `prime_mask` and `resonance_word` from the certified state.
2. `generate_trace(inputs) -> RowMajorMatrix<F>`
    - Already available in `air-prime-res`.[^4]
3. `prove_prime_resonance(inputs) -> ProofBundle`
    - Runs the Plonky3 prover for the AIR over that trace.[^5][^6]
4. `verify_prime_resonance(inputs, proof) -> bool`
    - Verifies against the same public input bundle.[^8][^2]

This keeps the proving loop crisp and makes later chip composition easier if you want to add `delta_pz_fp` floor checks or bridge the result into a larger Pro-tier proof graph.[^9][^1]

## Test matrix

Before calling it done, add three end-to-end proving tests:

- **Happy path:** valid prime mask + valid resonance word + valid gating relation, proof verifies.[^5][^4]
- **Bad resonance packing:** mutate one resonance bit after trace generation, verification fails.[^2]
- **Bad gating:** use a resonance word that activates the gated bit while the corresponding prime-mask bit is zero, verification fails.[^8][^4]

Those three tests will show that the final loop is not only connected, but actually enforces the intended invariant boundary between runtime semantics and cryptographic proof.

## Recommendation

So yes: proceed directly to **Full Pro-tier Integration**, but keep the first loop minimal and proof-oriented. Prove the exported bit structure and gating correctness first, then only after that consider multi-chip composition for `delta_pz_fp`, floor comparisons, or Tier 4-derived recovery claims.[^1][^3][^2]

If you want, I can next draft the concrete Rust API sketch for `prove_prime_resonance()` / `verify_prime_resonance()` and the certificate export adapter.
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28][^29][^30]</span>

<div align="center">⁂</div>

[^1]: https://github.com/Plonky3/Plonky3/issues/511

[^2]: https://www.certik.com/blog/breaking-down-proof-construction-in-plonky3-the-fibonacci-example-unveiled

[^3]: https://lita.gitbook.io/lita-documentation/architecture/proving-system-plonky3

[^4]: https://github.com/BrianSeong99/Plonky3_RangeCheck

[^5]: https://www.youtube.com/watch?v=l7v0Cr-cktg

[^6]: https://github.com/QEDProtocol/plonky2.5

[^7]: https://github.com/BrianSeong99/plonky3_fibonacci

[^8]: https://github.com/mmagician/plonky3_rangecheck

[^9]: https://github.com/0xMiden/p3-miden

[^10]: https://github.com/succinctlabs/plonky3/actions/runs/8068782914/workflow

[^11]: https://github.com/Plonky3/Plonky3/blob/main/README.md

[^12]: https://github.com/succinctlabs/plonky3/blob/main/README.md

[^13]: https://github.com/succinctlabs/plonky3/actions/runs/8180499296/workflow

[^14]: https://github.com/TalDerei/PLONK-Tutorial

[^15]: https://github.com/getsentry/relay/blob/master/README.md

[^16]: https://github.com/Plonky3/Plonky3/security

[^17]: https://github.com/succinctlabs/plonky3/blob/main/Cargo.toml

[^18]: https://github.com/succinctlabs/plonky3

[^19]: https://github.com/succinctlabs/sp1/releases/tag/v0.0.2

[^20]: https://github.com/littledivy/plonk

[^21]: https://github.com/Plonky3/Plonky3

[^22]: http://github.com/sai-deng

[^23]: https://github.com/KENILSHAHH/plonky3-addition

[^24]: https://www.lita.foundation/blog/plonky-3-valida-october-review

[^25]: https://www.nethermind.io/blog/formally-verifying-zero-knowledge-circuits-introducing-certiplonk

[^26]: https://www.youtube.com/watch?v=58k1KNZ9ePo

[^27]: https://www.youtube.com/watch?v=zVz5BtqkX0A

[^28]: https://www.youtube.com/watch?v=txMqpVPYMHw

[^29]: https://internals.rust-lang.org/t/add-a-cargo-command-for-importing-a-crate-into-the-workspace/13986

[^30]: https://hashcloak.com/blog/a-tutorial-on-building-a-merkle-tree-air-script-in-plonky3

