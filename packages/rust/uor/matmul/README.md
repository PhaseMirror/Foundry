# uor-matmul

**Decode the code, accumulate exactly, encode once.**

MatMul as an operation on *coded* operands. A weight tier is a codec
`d : Code -> Alphabet(B)`; the operation is the exact accumulation
`sum a_i * d(c_i)`; the result is encoded once into whatever the caller asked
for. The codec is not an argument of the arithmetic, which is why the same
result survives a change of tier, a change of reduction schedule, and a change
of substrate.

There is one method and it is used everywhere. Not one method for integers and
another for floats; not a fast path and a careful path; not a SIMD kernel and a
scalar fallback. Every entry point is that sentence at a different
instantiation, and the library holds nothing in reserve for cases it finds hard,
because the exact accumulation has no hard cases.

```rust
use uor_matmul::prelude::*;

let a = [1i8, 2, 3, 4];
let b = [5i8, 6, 7, 8];
let mut c = [0i32; 4];

let av = MatView::row_major(as_alphabet_full(&a), 2, 2).unwrap();
let bv = MatView::row_major(as_alphabet_full(&b), 2, 2).unwrap();
let cv = MatViewMut::row_major(&mut c, 2, 2).unwrap();

// The one fallible step: does this product exist?
let mut t = Triple::new(av, bv, cv).unwrap();

// The operation itself cannot fail, so it returns `()`.
gemm(&mut t, &Linear::OVERWRITE, GemmOptions::default(), &mut Scratch::none());
assert_eq!(c, [19, 22, 43, 50]);
```

## The six hard constraints

| # | Constraint |
| --- | --- |
| C1 | `no_std`, zero heap allocation, compiles for wasm and embedded |
| C2 | The UTQC method informs the implementation: docs-as-code, BDD-first, committed oracles, a three-level honesty ledger with a meta-gate |
| C3 | Scaling is compared against the oracle's scaling, as a fitted exponent with a confidence interval |
| C4 | No arbitrary limitations; completely parametric; arbitrary sizes and inputs |
| C5 | Purely UOR; no classical approach and no fallback to a lesser method |
| C6 | Never errors on valid input; arbitrary means arbitrary |

## The library has no envelope

> For every input the machine can represent, this library returns the exact
> value of the sum, encoded once into the caller's requested output type. There
> is no domain in which it approximates, no depth at which it wraps, and no
> shape at which it declines.

The accumulator's width is a compile-time function of the element type alone,
sized against the largest `k` the machine can address, so overflow is
*unreachable* rather than guarded:

| `E` | worst-case bits | accumulator |
| --- | --- | --- |
| `i8` | 79 | `i128` |
| `i16` | 95 | `i128` |
| `i32` | 127 | `i128` |
| `i64` | 191 | `Limbs<3>` (192 bits) |

`MAX_K_BITS` is *declared* in `model/constants.toml`, not probed from the host,
so this table is the same table on a 64-bit host, a 32-bit host, and wasm32. A
32-bit host cannot reach that depth, which makes the width conservative there
and never wrong anywhere.

There is no ladder, no policy, no promotion, and no `k_max` in the public API.
`fits_narrow` survives only as an internal predicate answering one question:
*may this tile be accumulated in a narrower register without changing the
answer?* Both sides compute the same integer, so the choice is invisible, has no
failure mode, and is never surfaced to the caller. That is what separates an
optimization from a fallback: a fallback changes the answer or the guarantee,
and this changes neither.

## The error surface, in full

Two variants, both meaning *the requested object does not exist*, both reported
at view construction, before any arithmetic is named:

- `Nonconformant` — A is `m x k` and B is `p x n` with `k != p`.
- `OutputAliasesItself` — the output strides map two coordinates onto one cell.

Neither can be caused by the size, depth, magnitude, or distribution of the
data, nor by the host. Deliberately absent, each absence load-bearing:

| Absent | Why |
| --- | --- |
| a depth or size limit | the accumulator cannot overflow |
| an alphabet violation | every value of `E` is in `Alphabet<E, Full<E>>` |
| a scratch error | scratch is an offer; too little means a different traversal, not a failure |
| an accumulator-policy error | there is no policy |
| an epilogue capacity error | the epilogue evaluates in the accumulator's width, which cannot overflow |
| a backend-unavailable error | the portable backend is always present and always correct |
| a non-finite-input error | non-finite floats are codes with IEEE-defined behaviour |

`i8::MIN` is not rejected. It is an element of `Alphabet<i8, Full<i8>>`, whose
bound is 128. Refusing a representable value would be an arbitrary limitation
dressed as rigour.

## Floats are codes

An IEEE 754 value is a bit pattern naming an exact dyadic rational. That is a
codec, with the same shape as a codebook, so the float path is not a second
method: decode exactly, accumulate into a *complete accumulator* spanning the
entire product exponent range, and round once at the end.

Consequences, stated plainly:

- The `f32` result is the correctly-rounded value of the exact sum. It is
  schedule-independent, tile-independent, and substrate-independent, which no
  classical `f32` GEMM is.
- It is therefore **not** bit-identical to `matrixmultiply`, `faer`, or BLAS in
  general. Where they differ, they differ by their own rounding error, and this
  repository reports that error in ulps against the exact value rather than
  matching it.
- The integer paths are bit-identical to the integer oracles **everywhere**,
  including past the depth at which those oracles wrap. Reduction modulo `2^w`
  is a ring homomorphism, so reducing the exact sum once at the end equals
  reducing at every step: `EncodeMode::Wrapping` into a `w`-bit output
  reproduces a classical wrapping accumulator's bytes exactly, at every depth.
  There is no exempted region. A caller who wants the mathematical value
  instead asks for `EncodeMode::Saturating`, and both answers come from one
  accumulation.
- Non-finite inputs are codes too. NaN and infinity propagate by the IEEE rules;
  they are not an error condition.

## Non-goals

| # | Non-goal | Kind | Reason |
| --- | --- | --- | --- |
| N1 | Reproducing another library's float rounding | mathematics | this library computes the correctly-rounded result of the exact sum. A classical GEMM computes an order-dependent approximation of it. Where they differ, the difference is the other library's rounding error, and this repository measures it rather than matching it. |
| N2 | A proof development in this repository | scope | the formalization is upstream and is cited. This repo is a Rust library and is judged on the library. |
| N3 | Any quality claim about a codebook | discipline | VQ quality is measured per (model, codebook) and reported `open`, never asserted |
| N4 | Beating `matrixmultiply` / `faer` on f32 throughput | scope | exact accumulation into a complete accumulator costs more per element than one FMA. The claim made instead is: the same exponent, a lower residency constant, and an exactly defined result. |
| N5 | A second method for any case, however hard | design | there is nothing this library does not do with decode-accumulate-encode, so there is nothing left over for a second method to cover |

Note what is **not** on that list. Asymmetric quantization is not a non-goal: a
zero point is the codec `d(c) = c - z`, expressed as `Offset<C>`. A reduction
depth is not a non-goal: the accumulator cannot overflow. An unaligned or prime
shape is not a non-goal: padding with the alphabet's zero is exact. A float
input is not a non-goal: it is a code.

## Claim discipline

Every claim carries one of three honesty levels, and the build fails if the two
registers are blurred:

| Level | Meaning |
| --- | --- |
| `some-true` | reproduced from an authority — the upstream formalization, a published instruction semantics, an IEEE 754 rule. **Not established here.** |
| `build` | constructed here and validated against its oracle. Evidence that the kernels realize the identity, **not a proof of it**. |
| `open` | measured and reported, **never asserted**. |

A cross-library agreement is `build`, never `some-true`: it is evidence that the
kernels realize the identity, not a proof of it. The identity itself is cited
from upstream and says nothing about any binary in this repository.

`CONFORMANCE.md` is generated from `model/ledger.toml`, so a claim cannot exist
in the documentation without a ledger row, or in the ledger without appearing in
the documentation.

## Repository layout

| Path | What it is |
| --- | --- |
| `model/` | the single source of every constant, tier, oracle, and claim |
| `features/suites/` | one Gherkin scenario per conformance ID |
| `oracles/` | committed external artifacts, with provenance and checksums |
| `crates/uor-matmul-core` | alphabet, accumulator, reference accumulation, views. `no_std`, no `alloc`, `forbid(unsafe_code)`, no float arithmetic |
| `crates/uor-matmul-codec` | the `Codec` trait, every tier, and the E8 codebook |
| `crates/uor-matmul-kernels` | one module per ISA. The only crate with `unsafe` |
| `crates/uor-matmul-gemm` | the driver: traversal, scratch, epilogue, tile partition |
| `crates/uor-matmul` | the facade, and the raw-pointer face |
| `crates/uor-matmul-model` | build-time: parses `model/*.toml`, generates the Rust consts and `CONFORMANCE.md` |
| `crates/uor-matmul-validate` | dev/CI only: oracle adapters, the differential harness, the scaling fits |
| `crates/uor-matmul-conformance` | dev/CI only: the BDD runner and the honesty meta-gate |
| `xtask/` | the gates |
| `fuzz/` | totality targets |

`just vv` is the normative acceptance gate. `VERIFICATION.md` maps each of its
axes to the claims it discharges, and lists the defect that was planted to prove
each gate can fail. `VALIDATION.md` is how a third party reproduces all of it
without trusting this repository.

## The `std` feature and which kernel runs

`std` buys runtime CPU feature detection and nothing else in the numerical
path. Without it a backend is available only if the *build* declared its target
feature, so a hosted build with neither `std` nor `-C target-cpu=native` runs
the portable kernel --- correctly, and several times slower than the machine can
manage. On an embedded target that is right; on a server it is not what was
meant. `uor_matmul::kernels::available_i8()` says which kernels a build can run.

## Performance

`ANALYSIS.md` §"Against the oracles" has the sweep --- throughput, latency, and
fitted exponents from `n = 1` to `n = 1024`, beside every oracle. In short, on a
two-core runner with AVX2:

| | uor-matmul | oracle | |
| --- | --- | --- | --- |
| `i8`, `n = 1024` | 37.7 Gmac/s | matrixmultiply `f32` 43.3 | 1.1x behind, across element types |
| `i32`, `n = 1024` | 29.1 Gmac/s | ndarray 0.21 | **142x ahead** |
| `i32`, `n = 1024` | 29.1 Gmac/s | nalgebra 4.58 | **6.3x ahead** |
| `i8`, `1024x1024x1` | 37.5 Gmac/s | ndarray 3.24 | **12x ahead** |
| `i8`, `1x1048576x1` | 40.1 Gmac/s | ndarray 2.41 | **17x ahead** |
| `f32`, `n = 1024` | 0.32 Gmac/s | matrixmultiply 43.3 | 134x behind |
| latency at `n = 1` | 140 ns | ndarray 60 ns | 2.3x behind |

The integer paths are ahead of both integer oracles at every size that is not
latency-bound, and hold their throughput from `n = 128` upward while `ndarray`
falls away. `ANALYSIS.md` §"The constraint that is nobody's" has the
one figure that is not a constant factor: the collapse traversal charges per
*distinct* row of `A` rather than per row, so at `4096 x 512 x 512` with one
distinct row it runs at **715 Gmac/s** --- 17.8x this library's own packed
traversal and 1350x `ndarray` --- on an answer asserted byte for byte against
both. An operand with no repeated rows pays 4% for the question and is told so in
the same table. The float path is two orders of magnitude behind, and that is N4 stated
as a number rather than as an excuse: one FMA per element against a decode, an
integer significand multiply, and a placement into a 619-bit register that never
rounds until the end.

## Licence

Apache-2.0.
