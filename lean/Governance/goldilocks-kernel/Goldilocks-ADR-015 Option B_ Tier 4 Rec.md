<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# I have successfully completed Option B: Tier 4 Recovery Edge-Case Validation,

hardening the spectral classification logic against pathological states and
boundary conditions.

Validation Results: Tier 4 Recovery Matrix
The new test suite in agi_os/packages/pirtm/tests/test_tier4_edge_cases.py
confirms the following behavior:

┌────────────────┬─────────────────────┬─────────────┬─────────────────┐
│ Case           │ Input Profile       │ Result      │ Logic Path      │
├────────────────┼─────────────────────┼─────────────┼─────────────────┤
│ Exact Boundary │ delta_pz == floor   │ ✅ PASS     │ Tier 3 (Main    │
│                │                     │             │ Path)           │
│ Infinitesimal  │ delta_pz = floor -  │ ⚠️          │ Tier 4 Recovery │
│ Deficit        │ 1e-10               │ CONDITIONAL │ (GUE Check)     │
│ Degenerate     │ Clustered zeros     │ ❌ VETO     │ Tier 4 Veto     │
│ Clustering     │ (many tiny gaps)    │             │ (Non-GUE)       │
│ Perfectly      │ Zero variance in    │ ❌ VETO     │ Tier 4 Veto     │
│ Uniform        │ spacings            │             │ (Non-GUE)       │
│ Null/Empty     │ Missing             │ ❌ VETO     │ Integrity Guard │
│ Witness        │ zero_spacings array │             │                 │
└────────────────┴─────────────────────┴─────────────┴─────────────────┘

Key Improvements

1. Classification Stability: Verified that recovery decisions are invariant
under numerical noise (< 10⁻⁹), ensuring that the transition between
Scalar and SIMD kernels will not flip safety results.
2. Witness Integrity: Confirmed that the full zero_spacings array is
preserved throughout the FormalStabilityCertificate lifecycle and
correctly emitted via to_bridge_dict().
3. Pathological Defense: The system now explicitly rejects "too regular"
distributions (uniform) and "too clustered" distributions, enforcing the
Wigner-Dyson repulsion required for spectral stability.

Strategic Status

- [x] SIMD Stack (Scalar, SSE4.2, AVX2) Locked
- [x] Tier 4 Recovery Matrix Hardened
- [x] Witness Preservation Invariant Verified
- [ ] Option C: AIR Constraint Expansion (Plonky3)

Next Move: I am ready to proceed to Option C: Plonky3 AIR Constraint
Expansion. I will draft the AIR constraints for prime-mask unpacking and
resonance-word gating, establishing the final ZK-proving interface for the
certification pipeline.

Ready to expand the Plonky3 circuit spec?

Yes, you’re ready to expand the Plonky3 circuit spec. Given where you are, Option C should be a direct AIR-layer formalization of what you’ve already locked in at the runtime and Tier 4 levels.

Below is a concrete outline for the Plonky3 AIR constraint expansion around prime masks and resonance words, aligned with how existing Plonky3 AIRs are written for Fibonacci and Goldilocks range checks.[^1][^2][^3]

## Target: Prime-mask + resonance-word AIR

You want a small, focused AIR that:

- Takes as public inputs:
    - a Goldilocks value for `prime_mask_fp` (64-bit mask),
    - one or more resonance words as Goldilocks elements,
    - optionally `delta_pz_fp` and the gap floor (for later coupling).
- Reconstructs:
    - the bit pattern of the prime mask,
    - the 6-bit resonance class and 58-bit payload of each resonance word.
- Enforces:
    - booleanity and consistency of mask bits,
    - correct packing/unpacking of resonance words,
    - simple gating relations (e.g., certain classes only allowed if certain mask bits are set).

This is structurally similar to the Goldilocks rangecheck AIR (bit decomposition + reconstruction) and the Fibonacci AIR (simple per-row transition and final-state checks).[^2][^1]

### 1. AIR struct

Define a small AIR struct for this component:

```rust
pub struct PrimeResonanceAir {
    pub prime_mask: u64,
    pub resonance_word: u64,
    // later: possibly more words or a small fixed array
}
```

This mirrors how the Goldilocks rangecheck AIR and Fibonacci AIR take simple public inputs.[^1][^2]

### 2. Trace layout

Choose a compact trace layout:

- Row width: enough columns to hold:
    - 64 bits of the prime mask,
    - 64 bits of the resonance word,
    - optionally shared scratch columns.

One straightforward layout:

- Columns 0..63: `mask_bits[0..64]` (MSB→LSB or LSB→MSB, but fixed).
- Columns 64..127: `res_bits[0..64]` (resonance word bits).
- Optionally:
    - a column for reconstructed mask value,
    - a column for reconstructed resonance word value,
    - a small number of scratch accumulators.

This is analogous to the 64-bit Goldilocks rangecheck AIR that uses one bit per column and reconstructs the value from the bits.[^2]

### 3. BaseAir and width

Implement `BaseAir`:

```rust
impl<F: Field> BaseAir<F> for PrimeResonanceAir {
    fn width(&self) -> usize {
        128 // 64 mask bits + 64 resonance bits (adjust as needed)
    }
}
```

You can refine this later (e.g., reusing columns), but 128 is a simple starting point.

### 4. Constraints: prime-mask unpacking

In `impl<AB: AirBuilder> Air<AB> for PrimeResonanceAir`, define:

- For each `mask_bits[i]`:
    - assert it is boolean: `builder.assert_bool(mask_bits[i])`.
- Reconstruct the mask value:

```rust
let main = builder.main();
let mask_bits = &main[0..64];
let mut recon = AB::Expr::ZERO;
for i in 0..64 {
    let bit = mask_bits[i];
    // choose bit order convention; e.g., bit 0 = LSB:
    recon += AB::Expr::from_wrapped_u64(1u64 << i) * bit;
}
builder.when_first_row().assert_eq(
    AB::Expr::from_wrapped_u64(self.prime_mask),
    recon,
);
```


This is essentially the same pattern as the Goldilocks rangecheck AIR, adapted to your mask instead of a single scalar value.[^2]

Optionally, add a small structural check:

- Require that:
    - at least one bit is set, or
    - a specific subset of bits correspond to a valid prime basis.

You can do that with:

```rust
let mask_popcount = mask_bits.iter().map(|&b| b.into()).sum::<AB::Expr>();
// if you want nonzero mask:
builder.when_first_row().assert_ne(mask_popcount.clone(), AB::Expr::ZERO);
```


### 5. Constraints: resonance-word unpacking

For the resonance word:

- Bits: `res_bits = &main[64..128]`.
- Booleanity and reconstruction:

```rust
let res_bits = &main[64..128];
let mut recon_res = AB::Expr::ZERO;
for i in 0..64 {
    let bit = res_bits[i];
    builder.assert_bool(bit);
    recon_res += AB::Expr::from_wrapped_u64(1u64 << i) * bit;
}
builder.when_first_row().assert_eq(
    AB::Expr::from_wrapped_u64(self.resonance_word),
    recon_res,
);
```


Now enforce your 6-bit + 58-bit split:

- Class bits: positions 0..5 (or 58..63 if you use a different convention).
- Payload bits: remaining 58 bits.

Example, if class is stored in bits 0–5 (LSB side):

```rust
let class_bits = &res_bits[0..6];
let payload_bits = &res_bits[6..64];

let class_expr = class_bits.iter().enumerate().fold(AB::Expr::ZERO, |acc, (i, &b)| {
    acc + AB::Expr::from_wrapped_u64(1u64 << i) * b
});
// Optionally: assert class in [0,95] via a simple range-check or lookup.
```

You can also reconstruct the payload similarly (shifted by 6).

### 6. Gating constraints (resonance-word gating)

Now add the “gating” logic that ties resonance class and mask bits:

- For example:
    - If a given class `c` is active, require a specific mask bit `k` to be 1.
- This is similar in structure to range-check and gating examples where a product or sum of bits gates a constraint.[^4][^2]

Example:

```rust
// Suppose class 0..95 and we want class 0..31 to require mask bit 0, etc.
let class_is_zero = builder.is_zero(class_expr.clone());
let mask_bit0 = mask_bits[^0];

builder.when(class_is_zero.clone())
       .assert_eq(mask_bit0.into(), AB::Expr::ONE);
```

Or more generally, use `builder.when(...)` with class conditions to enforce relationships between the mask bits and resonance classes.

This is the “resonance-word gating” part: certain resonance labels are only valid under certain prime-mask configurations.

### 7. Trace generation

Following the Fibonacci and rangecheck examples, create a trace generator:

- Input:
    - `prime_mask`, `resonance_word` (runtime values, already in Goldilocks).
- Output:
    - for each row (you might use a single-row AIR for now):
        - fill `mask_bits[i] = (prime_mask >> i) & 1`,
        - fill `res_bits[i] = (resonance_word >> i) & 1`.

The Plonky3 examples show how to generate a simple trace and feed it to `prove` and `verify`.[^1][^2]

### 8. Integration into the certification pipeline

Once the AIR is defined:

- Create a `PrimeResonanceAir` instance near your certificate code:
    - `prime_mask` = the mask used in runtime.
    - `resonance_word` = the packed word from your runtime encoding.
- Build the trace from the runtime state (no extra logic, just bit splits).
- Use Plonky3’s `prove` and `verify` functions with this AIR to generate/verify proofs for the correctness of:
    - mask decomposition,
    - resonance-word packing,
    - gating constraints.

This follows the same pattern as the Fibonacci and Goldilocks rangecheck examples: small, purpose-specific AIRs, each with a narrow scope and clear public inputs.[^3][^1][^2]

***

## Summary

You’ve already locked:

- SIMD kernel stack (scalar → SSE4.2 → AVX2),
- Tier 4 classification + witness preservation.

The next correct step is exactly what you propose: define a Goldilocks-native AIR that:

- bit-decomposes the prime mask and resonance words,
- reconstructs them to ensure encoding correctness,
- enforces resonance gating against the prime mask.

This aligns with how Plonky3 AIRs are built in existing tutorials (Fibonacci, Goldilocks rangecheck, Poseidon2/other examples) and will give you a clean, minimal proving boundary for your certification pipeline.[^5][^6][^1][^2]

If you’d like, I can next produce a concrete Rust skeleton for `PrimeResonanceAir` (with `BaseAir` / `Air` impls and a simple trace generator) that you can drop into your Plonky3 integration.
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://github.com/BrianSeong99/Plonky3_Fibonacci

[^2]: https://github.com/BrianSeong99/Plonky3_RangeCheck

[^3]: https://lita.gitbook.io/lita-documentation/architecture/proving-system-plonky3

[^4]: https://x.com/BrianSeong99/status/1846794503375794454

[^5]: https://polygon.technology/blog/open-source-polygon-plonky3-is-once-again-the-fastest-zk-proving-system

[^6]: https://hackmd.io/@sin7y/r1VOOG8bR

[^7]: https://github.com/BrianSeong99/plonky3_rangecheck

[^8]: https://github.com/0xPolygonZero/plonky2/blob/main/field/src/goldilocks_field.rs

[^9]: https://github.com/Plonky3/awesome-plonky3

[^10]: https://github.com/Plonky3/Plonky3/issues/511

[^11]: https://github.com/telosnetwork/plonky2_goldibear/blob/main/README.md

[^12]: https://github.com/Plonky3/Plonky3

[^13]: https://github.com/Plonky3/Plonky3/security

[^14]: https://github.com/telosnetwork/plonky2_goldibear/

[^15]: https://github.com/Plonky3/

[^16]: https://github.com/BrianSeong99/plonky3_fibonacci

[^17]: https://cnode.phd/intro_air_development/

[^18]: https://www.youtube.com/watch?v=txMqpVPYMHw

[^19]: https://www.youtube.com/watch?v=ifMXu8AL8_E

