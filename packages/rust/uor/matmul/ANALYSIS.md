# ANALYSIS

Where the numbers come from. Nothing here is a preference; each figure is
derived, and `cargo xtask check-model` re-derives it.

## The accumulator widths

`MAX_K_BITS = 64` is **declared**, not probed. The alternative --- deriving it
from `usize::BITS / size_of::<E>()` on the host --- gives a *narrower* bound
(79 / 94 / 125 / 188 rather than 79 / 95 / 127 / 191) and resolves to the same
accumulator type for every element type. Declaring it is still the right choice,
because it makes the table target-independent: `CD-06` and `CA-02` then compare
one function against itself rather than two functions that happen to agree.

The complex rows carry one extra bit, for the two element-products the real part
sums. `log2(PRODUCT_TERMS)` is read from the element type, so a complex alphabet
needs no separate table and no branch.

## The complete accumulator widths

For `f32`: the minimum subnormal is `2^-149`, so the minimum product exponent is
`2 * -149 = -298`. The maximum finite value is below `2^128`, so the maximum
product exponent is `256`. The span is `256 - (-298) = 554` bits. Add
`MAX_K_BITS = 64` for the depth and one for the sign: `619`, which is 10 limbs
of 64 bits, 80 bytes.

For `f64`: `2 * -1074 = -2148` and `2 * 1024 = 2048`, a span of `4196`; plus 64
plus 1 is `4261`, which is 67 limbs, 536 bytes.

The 536 bytes per output element is the real cost of exactness at `f64`, and it
is not hidden: a large register-blocked tile is expensive on a small target. The
mitigation is a traversal choice, not a method choice.

## The narrow-register thresholds

Each is `floor(cap / per_step)`, where `per_step` is the worst-case magnitude
one step of that instruction sequence contributes.

| Sequence | per step | cap | threshold |
| --- | --- | --- | --- |
| plain `i32` tile, W8A8 | `127 * 127 = 16129` | `i32::MAX` | 133144 |
| `vpdpbusd` offset, W8A8 | `255 * 127 = 32385` | `i32::MAX` | 66311 |
| `vpdpbusd` compensation | `128 * 127 = 16256` | `i32::MAX` | 132104 |
| `_mm256_madd_epi16` pair | `2 * 127 * 127 = 32258` | `i32::MAX` | 66572 steps |
| `vmull_s8` in `i16` | `127 * 127 = 16129` | `i16::MAX` | 2 |

The last row is why the NEON kernel widens to `i32` immediately: three `i16`
products do not fit (`3 * 127^2 = 48387 > i16::MAX`), so accumulating even two
of them in `i16` would be a saturation waiting to happen.

None of these is a limit. A tile past its threshold takes a wider lane and
computes the same integer, and `CU-03` asserts agreement at depths straddling
each one.

## The blocking parameters

`mc = 128`, `kc = 256`, `nc = 1024`. Cache-shaped, explicitly allowlisted out of
R1, and asserted invariant by `CD-01`: changing one cannot change any output
byte, only which traversal produces it. They are the one table in the model that
is *tuning* rather than derivation, and saying so is the point of the allowlist.

## The property-suite sample size

`CP-01` runs 4096 randomized cases per run, at a recorded seed.

The number is derived from what the suite has to catch. A defect confined to one
position of a packed tile survives a random case with probability
`1 - 1/(MR * NR)`. The widest shipped kernel is `8 x 32 = 256` positions, so
after `n` independent cases the escape probability is `(1 - 1/256)^n`. Requiring
that below `10^-6` gives

```text
n >= 256 * ln(10^6) ~= 256 * 13.8 ~= 3538
```

and 4096 is the next power of two above it. The seed is recorded so a failure is
reproducible; a suite whose failures cannot be reproduced is a lottery.

## The corpus shapes

Zero, one, primes, powers of two plus and minus one, and rectangular extremes.
Chosen so that no block size divides anything and every tail path is reached. A
corpus of round numbers would agree with almost any implementation, which is the
failure mode this list exists to avoid --- and it earned its keep immediately, by
finding a `5 x 0` output that the aliasing check reported as self-aliasing
because a row-major view over zero columns has a row stride of zero.

## The scaling fits

Least squares in log-log space, over geometrically spaced points. Geometric
rather than linear because a fit over linearly spaced sizes is dominated by the
largest few and reports the asymptote of the tail rather than of the curve.

Fewer than three points do not fit: two points determine a line exactly and
would report a confidence interval of zero, which would be a lie rather than a
measurement. The reported interval is `1.96` standard errors; with few points
that is optimistic, which is why the sample count is reported beside it.

Every figure is `open`. `CG-01` on a two-core shared runner measured an exponent
of about `0.98 +/- 0.06` against MAC count, which is what an `O(m k n)`
implementation should give --- reported, not asserted.

## Where the time goes

Measured on a two-core shared runner with AVX2 and no AVX-512. Every figure is
`open`. What follows is what measuring found, in the order it was found, because
every one of them was a copy or a traversal rather than arithmetic --- and none
of them was visible by reading.

**The accumulator was passed by value.** `Element::mac` took and returned
`Self::Acc`. For an `i128` that is free; for `Complete<10>` it is 88 bytes in
and 88 bytes out, *twice* per product once `add_scaled` did the same. Making
both take `&mut` was worth 4x on `f32` and 1.6x on the packed integer path,
because the integer kernels were paying for it too through the shared trait.

**The complete accumulator added at full width.** `add_scaled` built a
full-width value and combined it, which is O(L) per product --- 67 limbs for
`f64`. Adding the three spread limbs in place, with a carry that stops as soon
as a limb absorbs it, makes it O(1) in the common case. `Limbs::add_i128` had
the same shape and got the same fix.

**Coded random access walked the row.** `CodedMatrix::at` found row `r` by
walking every preceding row's codes. That is O(row) per element, which makes a
driver reading one element at a time O(k^2 n) rather than O(m k n) --- not a
constant factor, a different curve. It showed up as a benchmark that did not
finish. Fixed-width tiers now index by arithmetic; only a run codec walks, and
only when a caller uses random access on one.

**The packing loop indexed instead of walking.** `origin + i * rs + j * cs` per
element is two multiplies where a walk is one add, and the panel is a million
elements. `MatView::row_walk` and `column_walk`, with the full panel split from
the edge, was worth 1.7x on `i32`.

**Panels were packed at microkernel granularity.** A panel is `mr` rows or `nr`
columns wide, and packing at that granularity repacks `A` once per column
*panel*: `m*n*k/nr` element copies against `m*n*k` of arithmetic. At the shipped
`nr` that is not a rounding error --- it was the same order as the arithmetic,
and it was the whole distance between this driver and the instruction ceiling of
its own kernels. Packing in cache-shaped *blocks* instead was worth 2.1x on `i8`
and 2.3x on `i32`.

**`k_group` was declared and ignored.** Every SIMD kernel rebuilt its `k`-group
in a stack buffer once per step, because the packed layout did not group. Making
the layout honour it --- `k`-major in groups, lane-major within one --- lets
`B`'s group widen straight into the vectors `madd`, `dpwssd`, `sdot` and `dot`
consume, and `A`'s group be one unaligned load and a broadcast. It also removed
every kernel's `k`-tail. Worth 1.35x on `i8`.

**The inner loop held the larger panel.** With the column panel as the inner
loop's invariant, `nr * kpad` is what has to stay in L1 --- and at a panel whose
depth is the whole of `k` that is 32 KiB at `n = 2048`. The row panel is
`mr * kpad`, which is smaller, so it is the one to hold. Worth 1.3x at
`n = 2048` and nothing below it, which is what a cache-residency fix should look
like.

**The block extents read the blocking as a column count.** `NC` columns of `B`
at a panel depth of the whole `k` is a `k/KC`-times-oversized panel, which at
`k = 1024` is the difference between a panel in L2 and a panel in memory. Read
as a working *set* --- `KC * NC` elements of `B`, `MC * KC` of `A` --- the block
narrows as the depth grows and what stays resident stays the same size.

**The working set shrank the blocks past where it could help.** `nc` was capped
at `KC * NC / kpad`, which at `k = 262144` is one column --- and then `A` is read
once per column of `B`. But once a single microkernel panel at that depth already
exceeds the working set, shrinking the block gains nothing, because the panel is
out of that cache either way. The cap now applies only while it can be satisfied.

**A narrow output paid for columns that were not there.** A tile kernel produces
`nr` columns per call whether the output has them or not; at `n = 1` that is one
useful lane in ninety-six. The reduce factorization puts the lanes on `k`, where
there is always more. Worth 50x on a matrix-vector product.

**The packing walked the wrong stride.** `pack_columns` looped lanes outside and
depth inside, so it read a row-major `B` down its columns --- a new cache line
per element. Which loop is inner decides which stride the reads walk, and the
right answer is whichever stride is smaller, which is a question about the
*declared* strides. It is invisible on a square, where the packing is amortized
over the row blocks, and it is the whole cost when `m` is small: worth 1.8x on
`1x1024x1024` and 2.0x on `4096x2x4096`. It also has to be *off* for a
one-lane reduce panel, where an inner loop of one element is all overhead ---
which measuring caught, at a 2x regression on `8x262144x8`.

**A packed panel is a copy, and some panels were already there.** For a
`LaneLayout::Contiguous` kernel the panel *is* a run of rows or of columns, so a
row-major `A` and a column-major `B` already hold it --- which is not an exotic
case, it is a matrix-vector product with the ordinary layout, where the panel
would otherwise be one element written per multiply-accumulate and double the
whole product's memory traffic. `MatView::row_block` and `column_block` hand back
the operand's own memory when the strides already say so. Worth a further 37x on
a single deep dot product, which then needs no working memory at all.

**The driver had no way to compare its two traversals.** The packed traversal
pads the shape up to whole panels and copies them; the streaming reference does
exactly the products the shape names and copies nothing. Below `n = 13` the
reference is *faster* --- by 7x at `n = 1` --- and nothing in the kernel table
said so, because no sequence declared how much a padded product costs it.
`products_per_step` is that declaration, and the driver now counts both
traversals: element accesses (two per packed element, and the *padded* extents,
because a shape narrower than a panel pays for the whole panel) and instruction
issues (one per `products_per_step` padded products, against one per streaming
product plus its two operand reads). Worth 2.6x at `n = 1` and 2x at `n = 4`.

The counts are exact; what they omit is the packed traversal's fixed setup, which
is proportional to nothing. Measured, the model is right at every size except
`n = 6` and `n = 8`, where it takes the packed traversal and the reference is
1.2x to 1.8x faster --- a residual of a few hundred nanoseconds, reported rather
than closed with a tuned constant, because a tuned constant is the thing R8 does
not permit.

**The float encode formed the magnitude once per bit.** `magnitude_bit` negated
the whole register on every call: 10 limbs for `f32`, 67 for `f64`, once per
significand bit. That is O(P*L) where O(P + L) does. Forming the magnitude once
and reading a `P`-bit window out of it was worth 2.9x on `f32` at `k = 2`, where
the encode is nearly the whole cost, and nothing at large `k`, where the
accumulate loop is.

**The float loop asked three questions per product that belonged elsewhere.**
Whether a code is finite is a fact about the *panel*, settled while its codes are
walked anyway. Whether a product of two significands fits an `i64` is a fact
about the *element type* --- `2 * 24 <= 63` for `f32`. And the limb window flushed
by cutting its `i128` into four 63-bit pieces, where `add_scaled` places a
magnitude at a scale in one three-limb spread. Together worth 1.35x at
`n = 1024`, 1.4x at `n = 512`, and 1.4x on the rectangular shapes.

## The constraint that is not ours

A classical GEMM chunks the reduction so its panels fit cache, and adds the
chunks into `C` as it goes. It can do that because its accumulator and its output
are the same width --- and it pays for it with an answer that depends on the
chunking, which is why no two classical `sgemm` implementations agree bit for bit.

This library cannot write partial sums into `C`, because `C` is the *encoded*
output and a partial sum encoded is a partial sum rounded. So without somewhere to
keep exact partial sums, the panels must hold the whole of `k` --- and then the
offer grows with the depth, and a caller with an astronomical `k` either supplies
an astronomical buffer or gets an unblocked traversal.

[`Scratch::with_accumulators`] is that somewhere. With a block of exact
accumulators the reduction is chunked to whatever the cache holds while every
partial sum stays full width, and neither offer grows with `k`:
`KC * (MC + NC)` of panel room and `MC * NC` of accumulators, for any depth at
all. The chunking is invisible in the result, and that is not a hope --- it is
what an exact sum *means*: the sum is order-independent, so it may be split any
way the machine prefers and recombined with no consequence. `CD-10` asserts the
depth-chunked traversal byte-identical to the full-depth one and to the streaming
reference, over depths straddling the chunk boundary.

Measured, the full-depth traversal is still the faster of the two wherever a
caller can afford its offer, so that is what `suggested_scratch` suggests. The
accumulator offer is not a faster traversal; it is the removal of a ceiling ---
the one place where the amount of memory a caller had to find scaled with the
problem.

What remains, and why:

- `A` is still repacked once per column *block*, which at the suggested offer is
  once. Removing the last of it needs a `C` accumulator panel of exact
  accumulators, which is memory the library is not allowed to own (R7). A caller
  who wants it can partition and reuse.
- The generic and coded drivers walk `k` innermost, so `B` is read with stride
  `n`. Fixing that needs an accumulator row, which is again memory the library
  cannot own. The kernel-driven path is the one that packs.
- `m = 1` against a wide `n` still fills a `6`-row panel with one real row, so
  the kernel does six times the arithmetic the product needs. It is now level
  with `matrixmultiply` and 4.6x ahead of `ndarray` on that shape, because the
  packing rather than the arithmetic was the cost; a narrower tile panel is the
  one thing left that would buy something there.
- A deep, thin shape --- `16 x 400000 x 16` --- sustains 5.8 Gmac/s where the
  microkernel alone runs at 38. With full-depth panels nothing is resident: the
  `A` block is 1.6 MB and the `B` block 6.4 MB. The depth-chunked traversal makes
  them resident but produces one kernel call per output column at that shape, and
  measured the two land within 30% of each other. Closing it needs the traversal
  choice to know the chunk depth before it picks the panel shape, which is a
  circularity this driver does not yet break. It is reported, not hidden: `CG-08`
  prints it per pass.
- `f32` is far slower than the integer paths. The size of that gap is measured
  against the *oracles* below, not against our own integer path, because
  comparing a library to itself says nothing about whether the cost is
  reasonable.

## The constraint that is nobody's

The section above is about a constraint a classical GEMM has and this library
does not. This one is about a constraint neither has noticed.

Every traversal in this library --- and every classical GEMM --- issues
`m * k * n` products whatever the operands hold. That is not a property of the
identity. It is a property of how the identity has been walked. Two equal rows of
`A` name the same sum against every column of `B`, so a driver that computes both
has computed one thing twice, and no amount of blocking or vectorisation
recovers it: the arithmetic was already issued.

The upstream Atlas measures the same thing from the other side. Its finite sector
has `3^7 = 2187` length-seven braid words and **26** distinct canonical states ---
a degeneracy of 84 --- and it charges per distinct state, content-addressed by
`kappa`, rather than per word. What it says about this library is that the number
of *expressions* an operand is written in and the number of *meanings* it carries
are different numbers, and only one of them is worth paying for.

[`Collapse`] is that here. One pass numbers each row of `A` by the first row
equal to it; the product is taken over the distinct rows only; the output is
expanded in place. `CD-12` asserts it byte-identical to the packed and streaming
traversals at every degeneracy from one meaning to all of them, and at every
offer including none.

**Why this library may do it and a classical one may not.** Sharing a result
between two rows is sound exactly when the two rows name the same value. Here
they do: the sum is over a declared alphabet, taken exactly, with no rounding
between the products and the single encode, so equal operands give equal sums by
definition. A classical `sgemm` sharing a row would additionally have to argue
that the *order* of its additions was the same, because its answer depends on
that order --- and it is the same argument it cannot make about chunking.

### Throughput against degeneracy, Gmac/s

Against the nominal `m * k * n`, which is what the caller asked for. Reporting
against the products actually issued would print the same number in every row and
hide the whole effect. Every figure is `open`.

| `m x k x n` | `d = 1` | `m/8` | `m/2` | `d = m` | uor packed | ndarray |
| --- | --- | --- | --- | --- | --- | --- |
| 4096x512x512 | 715 | 217 | -- | 38.6 | 40.2 | 0.53 |
| 4096x64x64 | 76.0 | 42.6 | -- | 12.0 | 13.7 | 1.85 |
| 65536x128x128 | 166 | 95.3 | 29.8 | 17.6 | 19.8 | 0.70 |

At `4096 x 512 x 512` with one distinct row that is **17.8x** this library's own
packed traversal and **1350x** `ndarray`, on an answer asserted byte for byte
against both.

### The price of looking

The last two columns are the row to read second. An operand whose rows are
pairwise distinct pays the pass and gets nothing: 4% at `k = 512`, 12% at
`k = 64`, 11% at `65536 x 128 x 128`. That is the honest cost of the question,
and it is why the traversal is entered through an *offer* rather than always.
`Scratch` set the precedent --- a caller who cannot spare the memory gets the
same bytes from a different walk --- and the same rule applies here: a caller who
knows their `A` has no repeated rows offers nothing and pays nothing.

Three things were measured and fixed before that price was 4% rather than 25%:

**The pass hashed through the wrapper.** `Alphabet`'s derived `Hash` and
`PartialEq` ask for one on the *bound*, which is a marker with nothing to
compare, so the comparison was element by element where the peeled slices are one
`memcmp`. At one distinct row --- every row compared against the representative
--- that was half the pass.

**One hash lane is a serial multiply chain.** FNV's mix has five-cycle latency
and one-cycle throughput, so a single accumulator runs at a fifth of the
multiplier's rate. Eight independent lanes over `chunks_exact(8)`, destructured
rather than indexed so the bounds check does not survive, took the pass from
2.4 ns per element to 0.6.

**The fold cost more than a twelfth of the row.** Folding eight lanes by running
the byte mix over all sixty-four of their bytes is sixty-four *serial*
multiplies per row --- at `k = 512` that is a twelfth of the elements and a third
of the time. One rotate-xor per lane and a multiply-shift finisher does it in
sixteen operations.

**The expansion wrote cells.** Replicating an output row is `n` strided writes
each costing two index computations, where a row-major output already holds the
row as a run. [`MatViewMut::copy_row`] is [`MatView::row_block`]'s mutable twin
and moves it. It is also where the earlier measurement was wrong: the first
version read 0.64 GB/s and the second 24 GB/s, and the difference was entirely
the first touch of an 8 MB output. A copy rate measured on unfaulted pages is a
page-fault rate.

### What it is not

The upstream paper is careful, and this section is careful in the same way. The
Atlas claims polynomial-time evaluation for the *finite* sector's invariant
decisions and explicitly disclaims subverting the `#P`-hardness of general tensor
contraction. The analogue here is exactly as narrow: a dense product of two
operands with no repeated content costs what it costs, and the row above says so.
What the collapse traversal removes is the assumption that the cost of a product
is a function of its *shape* --- and for a batch over a vocabulary, a one-hot or
gather product, a padded batch, or a low-bit quantised operand, the shape and the
content say very different things.

One thing it does not do, decided by a declaration rather than by the data: an
epilogue that reads `C` gets the packed traversal, because two rows with equal
rows of `A` still have different outputs when the `C` they read differs.

### Columns, and why the layout decides what they cost

Sharing is not always on the `A` side, and the other side needs no second
traversal. `(A * B)^T = B^T * A^T`, transposition is a stride, and equal columns
of `B` are equal rows of `B^T` --- so [`Triple::transposed`] is the whole of it,
and `gemm_collapsed` on that triple runs the same pass, the same compaction, and
the same expansion. `CD-12` asserts that too.

What it costs is not the same, and the reason is worth stating because it is the
one thing about this traversal that the *caller's* declaration decides. The pass
has to read the axis it is collapsing. At `512 x 512 x 4096`, one distinct
column:

| `B`'s layout | `d = 1` | `d = n/8` | `d = n` | uor packed |
| --- | --- | --- | --- | --- |
| column-major | 194 | 118 | 34.0 | 37.1 |
| row-major | 54.2 | 44.6 | 29.7 | 38.0 |

A column of a column-major `B` is a run, so the pass reads it the way
[`MatView::row_block`] hands it over and compares it with one `memcmp`. A column
of a row-major `B` is `k` reads on `k` different cache lines, and there are `n`
of them --- `Theta(k * n)` cache misses, which is `1/m` of the product's work at
thirty times the cost per access. That is the whole distance between 5.2x and
1.4x. Nothing about the answer differs, and `CD-12` covers both.

The expansion has the same shape and the same answer: which loop is inner is
decided by the output's strides and not by the order the rows were written in.
Every column of the expansion is independent, so the descending walk that makes
it safe is preserved either way, and the inner loop is free to be whichever axis
is the near one. Getting that wrong is expensive and was: walking the rows of
`C^T` outermost over a row-major `C` reads a cache line per cell, and it held the
column figure at parity until the loops were exchanged.

## Against the oracles

C3 is a hard constraint: scaling is compared against the oracle's scaling. Both
sides are measured in one process, over one sweep spanning ten orders of
magnitude in MAC count, with the answer asserted inside the timed region --- a
speed measured on the wrong bytes is not a measurement.

Two-core shared runner with AVX2 and no AVX-512. Best of as many repetitions as
fit a fixed wall-clock budget, so the large end gets more than two samples.
Operands are a recorded pseudo-random fill: they used to be all ones, which
flattered this library twice, because then every `f32` product shares one
exponent and the complete accumulator's limb window never once has to flush.
Every figure is `open`.

### Throughput on squares, Gmac/s

| `n` | uor `i8` | uor `i32` | ndarray `i32` | nalgebra `i32` | uor `f32` exact | matrixmultiply `f32` |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 0.007 | 0.010 | 0.017 | 0.014 | 0.017 | 0.013 |
| 4 | 0.27 | 0.36 | 0.46 | 0.46 | 0.12 | 0.64 |
| 8 | 0.53 | 1.16 | 1.02 | 1.55 | 0.19 | 4.66 |
| 16 | 4.09 | 4.01 | 1.50 | 3.15 | 0.26 | 14.6 |
| 32 | 6.44 | 6.21 | 1.74 | 4.17 | 0.29 | 26.8 |
| 128 | 19.7 | 17.1 | 0.78 | 4.50 | 0.33 | 28.9 |
| 512 | 38.5 | 29.9 | 0.53 | 4.71 | 0.32 | 43.2 |
| 1024 | 37.7 | 29.1 | 0.21 | 4.58 | 0.32 | 43.3 |
| 2048 | 32.9 | 26.4 | 0.15 | 4.54 | 0.32 | 41.2 |

At `n = 2048` a single one of our repetitions already exceeds the wall-clock
budget, so that row is a best-of-one and moves by up to a third between runs on a
shared machine. It is reported rather than smoothed, and the row above it is the
one to read.

The three smallest rows are where an oracle is ahead, and they are the rows where
a call is a few hundred nanoseconds and dominated by what happens before the
arithmetic. `ndarray`'s figure there includes a heap allocation and ours includes
none; what ours includes instead is walking the kernel table and weighing two
traversals, which is what buys the rest of the table.

### Throughput on shapes that are not squares, Gmac/s

A square is one use-case and not the interesting one. Each row below stresses a
different half of the driver.

| `m x k x n` | uor `i8` | uor `i32` | ndarray `i32` | nalgebra `i32` | uor `f32` | matrixmultiply `f32` |
| --- | --- | --- | --- | --- | --- | --- |
| 1024x1024x1 | 37.5 | 16.7 | 3.24 | 0.18 | 0.22 | 2.25 |
| 1x1024x1024 | 1.09 | 0.94 | 0.20 | 0.14 | 0.16 | 1.18 |
| 8x262144x8 | 6.64 | 4.52 | 1.70 | 1.82 | 0.29 | 16.0 |
| 1x1048576x1 | 40.1 | 10.2 | 2.41 | 0.34 | 0.16 | 0.31 |
| 2048x8x2048 | 9.24 | 8.34 | 1.08 | 0.82 | 0.17 | 13.4 |
| 4096x2x4096 | 2.57 | 2.51 | 0.41 | 0.17 | 0.07 | 0.86 |
| 509x1021x257 | 26.8 | 24.5 | 1.18 | 5.54 | 0.32 | 41.6 |

### Latency at the smallest shapes, nanoseconds per call

| `n` | uor `i8` | uor `i32` | ndarray | matrixmultiply |
| --- | --- | --- | --- | --- |
| 1 | 140 | 100 | 60 | 80 |
| 2 | 150 | 110 | 69 | 80 |
| 3 | 180 | 130 | 89 | 89 |
| 4 | 240 | 180 | 140 | 100 |

### Fitted exponent of throughput against MAC count

| | exponent |
| --- | --- |
| uor `i8` | 0.35 |
| uor `i32` | 0.32 |
| ndarray | 0.04 |
| nalgebra | 0.20 |
| uor `f32` | 0.09 |
| matrixmultiply | 0.32 |

A positive exponent means throughput still improving with size: the small end is
latency-dominated for everyone. `ndarray`'s 0.04 is the opposite story --- it
starts fast and *degrades*, from 1.9 Gmac/s at `n = 64` to 0.15 at `n = 2048`,
which is a cache story rather than an arithmetic one. Ours tracks
`matrixmultiply`'s almost exactly, which is what a driver with the same blocking
structure should do.

### What this says

**On integers, this library is ahead of both oracles at every size that is not
latency-bound.** At `n = 512` it is 73x `ndarray` and 8.2x `nalgebra`; at
`n = 1024`, 184x and 8.2x; at `n = 2048`, 225x and 7.2x. Nothing about that is a compromise on exactness: the
integer result is the exact sum encoded once, and `CX-01` .. `CX-04` and `CX-10`
assert it byte for byte against four independent implementations, including one
outside the Rust ecosystem.

**On integer squares it is now within 1.2x of `matrixmultiply`'s `f32`.** That
comparison is across element types and is not a like-for-like claim; it is here
because `matrixmultiply` is the fastest thing in the process and it says how much
of the machine the driver is reaching.

**On a matrix-vector product it is 10x ahead of `ndarray` and 15x ahead of
`matrixmultiply`.** That shape used to be this library's worst, at 0.70 Gmac/s,
and the reason was structural: the tile kernel produced sixteen columns for a
product that has one. The reduce factorization and panel borrowing are what
closed it, and both are the same identity, factored differently.

**Latency at `n = 1` is 140 ns against `ndarray`'s 60.** The difference is view
construction, walking the kernel table, and weighing the two traversals --- all
once per call and none of it scaling. Measured, the table walk is 20 ns per
family and there are two, which is the largest single piece. It is one of two
places an oracle is ahead, and the sweep says so.

**On floats the library is roughly 134x behind `matrixmultiply`, and that is the
trade N4 names.** A classical `sgemm` issues one fused multiply-add per element.
This one decodes two IEEE bit patterns, multiplies their significands as
integers, and places the exact product into a 619-bit fixed-point register ---
and never rounds until the end. The gap is the price of an answer that does not
depend on the order of the additions, which no figure in the `matrixmultiply`
column has. It is also the honest figure rather than the earlier one: with
all-ones operands the limb window never flushed and the same measurement read
120x, which was a better number about a worse question.

### The modular factorization

`i32` reaching 27 Gmac/s is not a `wrapping_mul` shortcut. When the caller asks
to encode by wrapping into a `w`-bit output, reduction modulo `2^w` is a ring
homomorphism, so accumulating in `Z/2^w` *is* the exact accumulation seen in the
quotient the caller named. `_mm256_mullo_epi32` then gives eight products per
instruction where the exact `i64` lane gives four, with no widening, because in
the quotient there is nothing to widen to.

Which factorization runs is decided by two *declarations* --- the encode mode
and the output width --- and never by inspecting the data. `CD-05` asserts that
both give the value their mode asks for, and that past `i32` they disagree,
which is what makes the choice observable rather than cosmetic.

### The reduce factorization

A tile kernel's vector lanes are columns of `C`. A reduce kernel's are steps of
`k`. Both compute the same integer, and `CB-06` asserts it; which one runs is
decided by the shape against the tile, which is a declaration the caller made
when they constructed the view.

It needs no second driver. A reduce panel is the *same* layout function at
`group = kpad`, so `packed_slot` reduces to `lane * kpad + p` and one `usize` in
the packer covers both. The table carries a reduce sequence for every family on
every ISA, each at a four-row and a one-row panel, because a panel wider than the
output is zero-padded and for a reduce kernel that padding is copied at `k`
elements a row.

### The narrow panel

`i8` at `n = 8` ran *slower* than the same kernel at `n = 16` --- 0.51 Gmac/s
against 4.05. That is not a property of the shape. The AVX2 `i8` tile is
`6 x 16`, so an output eight columns wide paid for sixteen: twice the arithmetic,
twice the packing, and a padded panel that fills half its lanes with zeros.

The table already had the answer on the other axis. `AVX2_I8_I32_M1` exists
because a panel *taller* than the output does the padding's arithmetic at `m = 1`;
`AVX2_I8_I32_N8` is the same argument on the columns. Measured, `8 x 8 x 8` went
from 1001 ns to 490 ns, a factor of two, and nothing above `n = 16` moved.

Three things had to be got right, and two of them were got wrong first.

**A width parameter costs the full-width panel its registers.** Folding both
widths into one kernel behind a `const V` --- an accumulator array indexed by the
parameter --- took `n = 2048` from 31.3 Gmac/s to 24.9. The array stops being
register-allocated and starts being memory. Two panel widths are two sequences,
which is what a table of sequences is for, and `CB-01` .. `CB-06` hold both to the
same integer. They are written out separately and the differential net sees both
--- `every_i8_tile()` chains the two lists, because a sequence outside the net is
a sequence nothing checks.

**The narrow panels are a second list, not more entries in the first.** Putting
them in `available_i8` lengthened *every* selection, including the calls that
could never use one: measured, a hundred nanoseconds on a shape whose whole cost
is a hundred and twenty. The driver only asks when `shape.n < tile.nr`, which is
the same condition under which it already asks for a reduce sequence, so a
product wider than its panel pays nothing for the question. What it does cost, on
a shape narrower than the tile that then does not want one, is one table walk:
20 ns, against the 511 ns it buys at `n = 8`. `n <= 4` and `n = 12` are 40 ns
worse and every size from 6 up is better, which is the trade and it is reported
rather than averaged away.

**The cost model priced a traversal the offer could not run.** `packed_cost`
counted the blocked traversal's packing --- each operand packed once per block ---
whatever the caller offered. But `run` takes the blocked traversal only when a
block of both panels fits the offer; below that it repacks *both* panels for every
output tile, which is a different count entirely. Narrowing the panel shrank
`mr + nr` enough for `4 x 4 x 4` to slip past the scratch guard into that
per-tile path, and the model --- still pricing the blocked one --- called it
cheaper than the streaming reference while it ran three and a half times slower.
Costing the traversal the offer actually buys fixed it, and it is the count that
was wrong rather than a constant that needed tuning: `calls * (mr + nr) * kpad`
against `(rows + cols) * kpad`.

### The declared alphabet

`_mm256_madd_epi16` sums two products into an `i32`, and two full-magnitude
`i16` products are `2 * 2^30` --- one bit past it. So that sequence is exact
exactly while the alphabet bound is at most `32767`, and at the full `i16`
alphabet it returned `-2^31` where the exact sum is `+2^31`. A random fill
reaches that input with probability `2^-64`, which is why the parity tests did
not find it and now ask for the extremes by name.

The fix is a declaration, not a guard: a `KernelSpec` carries `max_bound`, the
widest alphabet its sequence is exact on, and selection does not consider a
sequence outside it. The paired sequence declares `32767` and keeps its
instruction count; a widening sequence declares every `i16` and issues more.
Both are exact on what they declare, which is what makes them two factorizations
rather than a fast one and a safe one --- outside its alphabet the paired
sequence does not compute this identity at all.
