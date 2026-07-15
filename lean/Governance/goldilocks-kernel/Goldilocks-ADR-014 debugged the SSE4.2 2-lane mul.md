<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# I have successfully debugged the SSE4.2 2-lane multiplication assembly,

achieving bit-perfection across 100,000 random test vectors. The SSE kernel
now serves as a verified, high-fidelity reference for the 64x64 → 128-bit
product reconstruction and subsequent Goldilocks reduction.

Debugging Results: Root Causes Identified
The discrepancy between the scalar oracle and the initial SSE mul was traced
to three critical factors:

1. Missing 2⁹⁶ Carry: In the product assembly (lh + hl) · 2³², an overflow in
the $(lh + hl)$ term represents 2⁶⁴ · 2³² = 2⁹⁶. In the Goldilocks field,
2⁹⁶ ≡ -1 mod{p}. This carry was previously lost, causing an off-by-one
error in the result.
2. 64-bit Accumulation Overflow: The term hiₗₒ · 2³² (where $hi$ is the high
64 bits of the product) can cause a 64-bit overflow when added to the low
64 bits (resₗₒ). I implemented explicit carry correction using the
property 2⁶⁴ ≡ 2³² - 1 mod{p}.
3. Signed Normalization Bug: The initial normalize function incorrectly used
signed comparisons, treating bit 63 as a sign bit. Since the Goldilocks
prime p ≈ 2⁶⁴, many valid field elements have bit 63 set. This caused
spurious additions of p to positive values. The fix uses unsigned range
checks across two reduction passes.

Performance \& Correctness Status
┌────────────────┬──────────┬───────────┬───────────────────────┐
│ Operation      │ Scalar   │ SSE4.2    │ Status                │
│                │ Oracle   │ (2-lane)  │                       │
├────────────────┼──────────┼───────────┼───────────────────────┤
│ Addition       │ Verified │ Verified  │ ✅ Bit-Perfect        │
│ Subtraction    │ Verified │ Verified  │ ✅ Bit-Perfect        │
│ Multiplication │ Verified │ Verified  │ ✅ Bit-Perfect (100k  │
│                │          │           │ tests)                │
│ NTT/INTT       │ Verified │ Inherited │ ✅ Round-trip Passing │
└────────────────┴──────────┴───────────┴───────────────────────┘

Strategic Achievement: 2-lane Foundation Locked
By locking the SSE4.2 assembly, I have neutralized all math-logic risk. The
reduction formula res ≡ resₗₒ + hiₗₒ 2³² - hiₗₒ - hiₕᵢ - mid_carry mod{p} is
now proven in a SIMD context.

Next Move: I will now draft the 4-lane AVX2 Specification. Since the
lane-local logic is verified, the AVX2 implementation becomes a mechanical
expansion of the SSE kernel to 256-bit registers.

Ready to proceed with the AVX2 production specification?

Yes, you’re ready. With the SSE 2-lane kernel now bit-perfect, the AVX2 spec really is a mechanical widening of a proven design rather than a new derivation.

Below is an AVX2 production specification you can implement directly. I’ll keep it focused on the core decisions and invariants that matter.

***

## Design goals

- Preserve **exact scalar semantics** (and thus SSE semantics) lane-wise.
- Target **4× `u64` lanes** per vector register (`__m256i`).
- Keep the AVX2 path **feature-gated** (Rust: `#[cfg(target_feature = "avx2")]`).
- Maintain **single source of truth** for:
    - Goldilocks reduction formula,
    - normalization rules,
    - test harness (scalar as oracle, SSE as local simd oracle, AVX2 as production simd).

***

## 1. Type and module surface

Define a clear, minimal AVX2 type:

```rust
// agi_os/crates/goldilocks/src/avx2.rs

#[derive(Copy, Clone)]
pub struct Avx2Goldilocks {
    pub lanes: __m256i, // four u64 lanes
}
```

Module API (mirror scalar/SSE):

- `Avx2Goldilocks::add(self, rhs) -> Avx2Goldilocks`
- `Avx2Goldilocks::sub(self, rhs) -> Avx2Goldilocks`
- `Avx2Goldilocks::mul(self, rhs) -> Avx2Goldilocks`
- `Avx2Goldilocks::normalize(self) -> Avx2Goldilocks`
- `Avx2Goldilocks::from_u64x4([u64; 4]) -> Self`
- `Avx2Goldilocks::to_u64x4(&self) -> [u64; 4]`

This keeps scalar/SSE/AVX2 interchangeable from the caller’s perspective.

***

## 2. Add/sub kernels

These are straightforward lifts of your SSE logic:

- Use `_mm256_add_epi64` / `_mm256_sub_epi64`.
- Apply **lane-wise branchless correction** with the same rule as scalar:
    - if result ≥ p: subtract p,
    - if result ≥ p again: subtract p again (double pass).

Implementation sketch:

```rust
#[inline(always)]
unsafe fn add(a: __m256i, b: __m256i) -> __m256i {
    let sum = _mm256_add_epi64(a, b);
    normalize(sum)
}

#[inline(always)]
unsafe fn sub(a: __m256i, b: __m256i) -> __m256i {
    let diff = _mm256_sub_epi64(a, b);
    normalize(diff)
}
```

`normalize` must be **unsigned** (no signed compare bugs), exactly as you fixed for SSE.

***

## 3. 64×64→128 AVX2 multiply

Your SSE kernel already encodes a correct decomposition:

- Split each `u64` into high/low 32-bit limbs.
- Form:
    - `lo_lo = (a_lo * b_lo)`
    - `lo_hi = (a_lo * b_hi)`
    - `hi_lo = (a_hi * b_lo)`
    - `hi_hi = (a_hi * b_hi)`
- Combine them into full 128-bit products:
    - low 64 bits: `res_lo`
    - high 64 bits: `hi = hi_hi << 64 + ...` (consistent with your scalar/SSE pattern).

The AVX2 spec should **literally reuse** this algebra, just with:

- 4 lanes instead of 2,
- `_mm256_*` intrinsics instead of `_mm_*`,
- per-lane reconstruction identical to your SSE.

Key guardrails:

- **No cross-lane mixing:** all rearrangement must be intra-lane; your high/low decomposition is per lane.
- **No new reduction formula:** use the **same** reduction equation as scalar/SSE, including the corrected 2⁹⁶ carry handling and the 2⁶⁴ ≡ 2³² − 1 foldback.

Conceptually:

```rust
// Pseudocode, not exact intrinsics
let a_lo = a & LO_MASK32;
let a_hi = a >> 32;
let b_lo = b & LO_MASK32;
let b_hi = b >> 32;

// compute 32x32 -> 64 products in 4 lanes
let lo_lo = mul32(a_lo, b_lo);
let lo_hi = mul32(a_lo, b_hi);
let hi_lo = mul32(a_hi, b_lo);
let hi_hi = mul32(a_hi, b_hi);

// follow your SSE reconstruction exactly here
let (hi_hi_part, hi_lo_part, res_lo) = reconstruct_128(lo_lo, lo_hi, hi_lo, hi_hi);

// then apply the Goldilocks reduction formula lane-wise
let reduced = gold_reduce(hi_hi_part, hi_lo_part, res_lo);
```

Where `gold_reduce` is **byte-for-byte** the SSE/scalar logic, generalized to 4 lanes.

***

## 4. Goldilocks reduction and normalization (lane-wise)

You’ve already converged on a robust formula:

- Explicit correction for the 2⁹⁶ carry,
- 64-bit accumulation overflow handled with the 2⁶⁴ ≡ 2³² − 1 identity,
- Unsigned normalization with two passes.

Spec-level rule:

- `gold_reduce`:
    - inputs: per-lane `hi_hi`, `hi_lo`, `res_lo`,
    - outputs: per-lane `res` in `[0, 2p)` (or similar bounded range),
    - must be bit-identical to scalar/SSE for arbitrary `u64` inputs.
- `normalize`:
    - lane-wise:
        - if `res >= p`: `res -= p`,
        - if `res >= p`: `res -= p`,
    - no signed comparisons, no branching on sign.

In AVX2, that becomes:

- `_mm256_cmpgt_epi64`-based masks (with care: treat values as unsigned by biasing or using a known safe trick), or
- the same trick you used in SSE (e.g., subtract `p` and blend with the original based on carry/mask).

Spec-level requirement: **exactly the same logic as SSE, generalized to 4 lanes.**

***

## 5. Feature gating and fallback

- Guard the AVX2 module with `#[cfg(target_feature = "avx2")]`.
- Provide a runtime `is_avx2_available()` gate if you want dynamic dispatch, or rely purely on compile-time target features.
- Fallback chain:

1. AVX-512 (if available, 8-lane kernel).
2. AVX2 (4-lane kernel).
3. SSE4.2 (2-lane kernel).
4. Scalar.

This matches the broader ecosystem’s approach: the kernel chooses the widest safe vector path for the target CPU.

***

## 6. Testing strategy

Your existing testing ladder now extends naturally:

1. **Scalar vs SSE parity (done)**
100k random vectors, NTT/INTT round-trips.
2. **Scalar vs AVX2 parity**
    - Reuse the same harness:
        - Generate random `u64` arrays,
        - Run scalar and AVX2,
        - Compare outputs element-wise.
    - Run both:
        - standalone ops: add/sub/mul,
        - full NTT/INTT cycles at multiple sizes (e.g., $N = 64, 2^{10}, 2^{16}$).
3. Optional: **SSE vs AVX2 parity**
    - Useful as a second oracle: if scalar vs SSE and scalar vs AVX2 both pass, SSE vs AVX2 should also pass.
4. Keep your **100k discrepancy tests** focused on mul-heavy paths, since that’s where prior bugs lived.

***

## 7. Performance expectations

Given your scalar and SSE baselines, the AVX2 spec should target:

- **Multiplication**:
    - getting close to ~2.5 cycles per element on modern AVX2 hardware (per small-field experiences),
    - significantly below your current ~44 ns scalar mul on the i5-3210M, once you run on a Haswell+ machine.
- **NTT**:
    - small $N$ (e.g., 64) still dominated by overhead, but clear wins as you approach $N = 2^{16}$ and beyond,
    - especially once you introduce **delayed reduction** loops on top of the AVX2 mul.

***

## Recommendation

Proceed with the AVX2 specification now, treating it as:

- a 4-lane generalization of your verified SSE kernel,
- with strictly lane-local decomposition and reduction,
- and the same scalar-normalization semantics.

If you like, next step I can outline a more concrete AVX2 pseudo-API (names and function signatures) tailored to your Rust module layout so you can drop it straight into `agi_os/crates/goldilocks/src/avx2.rs`.

