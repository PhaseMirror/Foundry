# ARCHITECTURE

Normative. Where this document and the code disagree, one of them is a bug.

## The one sentence

> Decode the code, accumulate exactly, encode once.

Every entry point is that sentence at a different instantiation. The parameters
are `(Element, Bound, Codec, MaxBlock, Backend, Traversal)`, and W8A8 is the
instantiation `(i8, 127, Identity, 1, *, *)`. Nothing privileges it beyond its
having the most instruction support and the most external oracles.

## The crates, and why they are separate

| Crate | Contains | `unsafe` | `alloc` | float arithmetic |
| --- | --- | --- | --- | --- |
| `uor-matmul-core` | alphabet, accumulator, reference accumulation, views, the error surface | forbidden | none | none |
| `uor-matmul-codec` | the `Codec` trait, seven tiers, `CodedMatrix`, the kappa manifest, the E8 table | forbidden | none | none |
| `uor-matmul-kernels` | one module per ISA, each a `KernelSpec` value | permitted, documented | none | none |
| `uor-matmul-gemm` | the driver: traversals, scratch, epilogue, partition | none | none | none |
| `uor-matmul` | the facade and the raw-pointer face | the raw face only | none | none |
| `uor-matmul-model` | the typed model and the generators | none | freely | n/a |
| `uor-matmul-validate` | oracle adapters, corpus, scaling harness | documented | freely | n/a |
| `uor-matmul-conformance` | the BDD runner and the honesty meta-gate | none | freely | n/a |

The split is not organizational. `uor-matmul-kernels` is separate because it is
the only crate that may write `unsafe`, and a boundary is the only way to say so
in a way a reviewer can check. `uor-matmul-validate` is separate because the
oracles must not be reachable from a shipped crate, and a dependency edge is the
only way to enforce that.

## The accumulator model

The worst-case magnitude of an integer accumulation is `k * B_a * B_w`. Both
bounds are properties of the element type; `k` is bounded by
`MAX_K_BITS`, which is **declared** in `model/constants.toml` rather than probed
from the host. So:

```text
acc_bits(E) = 1 + MAX_K_BITS + 2 * (E::BITS - 1) + log2(products per mac)
```

| `E` | bits | accumulator |
| --- | --- | --- |
| `i8` | 79 | `i128` |
| `i16` | 95 | `i128` |
| `i32` | 127 | `i128` |
| `i64` | 191 | `Limbs<3>` |
| `Complex<i32>` | 128 | pair of `i128` |
| `Complex<i64>` | 192 | pair of `Limbs<3>` |

Declaring `MAX_K_BITS` rather than probing it is what makes this one table
rather than one per target. A 32-bit host cannot reach that depth, so the width
is conservative there and wrong nowhere --- and `CD-06` and `CA-02` become
comparisons of one function rather than of two that happen to agree.

For a float element the accumulator is `Complete<L, MIN_EXP>`: a fixed-point
register spanning the entire product exponent range, plus sticky flags for the
non-finite states.

| `E` | product exponent span | limbs | bytes |
| --- | --- | --- | --- |
| `f32` | `2^-298 .. 2^256` | 10 | 80 |
| `f64` | `2^-2148 .. 2^2048` | 67 | 536 |

The non-finite state is a *flag*, not a value. A value would have to take part
in the fixed-point addition, and then the answer would depend on where in the
accumulation the infinity arrived. IEEE 754 clause 6 is about the value, not the
schedule.

## The tile and reduce factorizations

A tile kernel's vector lanes are columns of `C`; a reduce kernel's are steps of
`k`. A tile kernel produces `nr` columns per call whether the output has them or
not, so a shape narrower than `nr` pays for the ones that are not there --- at
`n = 1` that is one useful lane in ninety-six. A reduce kernel has no such
problem, because there is always more `k`.

Both compute the same integer, and `CB-06` asserts it. Which one runs is decided
by the shape against the tile, and the shape is a declaration the caller made
when they constructed the view. Within the reduce family the same rule picks the
panel *height*: the widest one the rows fill, because a panel wider than the
output is zero-padded and for a reduce kernel that padding is copied.

## Borrowing instead of packing

A packed panel is a copy, so a copy of something already in the panel's shape is
pure cost. For a `LaneLayout::Contiguous` kernel the panel *is* a run of rows or
of columns, so a row-major `A` and a column-major `B` already hold it.
`MatView::row_block` and `MatView::column_block` hand back the operand's own
memory when the strides say so, and `None` otherwise --- and when both sides
borrow, the traversal needs no working memory at all, so a matrix-vector product
runs blocked on an empty `Scratch`.

## The narrow/wide factorization

`fits_narrow(b, cap, k)` answers one question: may this tile be accumulated in a
narrower register without changing the answer? `narrow_cap_for` returns the
**narrowest** lane that suffices, scanning `NARROW_CAPS` from the narrow end,
because a wider cap is easier to satisfy and scanning from the wide end would
always return the widest.

Both sides compute the same integer. That is what separates an optimization from
a fallback: a fallback changes the answer or the guarantee, and this changes
neither. `CD-09` asserts it, and `CU-02` measures that the narrow path is
actually taken.

## The declared alphabet

A `KernelSpec` also declares `max_bound`: the widest alphabet bound at which its
sequence is exact. `lane_cap` bounds the *depth* and the driver answers that by
chunking; this is the other question, and chunking cannot answer it. A sequence
with an intermediate narrower than its lane is wrong past some magnitude however
shallow the chunk --- `_mm256_madd_epi16` sums two products into an `i32`, and
two full-magnitude `i16` products are one bit past it.

So selection does not consider a sequence outside its declared alphabet. Not
because it is riskier there: there it computes a different number, so it is not a
factorization of this identity at all. `CB-07` asserts both halves --- that every
sequence is exact at the extremes it declares, and that selection never offers
one outside them.

## The packed panel format

`KernelSpec` declares `mr`, `nr`, `k_group`, `lane_layout`, `lane_cap`, and
`max_bound`. One function gives the layout:

```text
packed_slot(p, lane, lanes, group) = (p / group) * (lanes * group)
                                   + lane * group
                                   + (p % group)
```

with `group = k_group` for `LaneLayout::Interleaved` and `group = kpad` for
`LaneLayout::Contiguous`. Interleaved is what a kernel wants when its vector
lanes are output columns: one load brings in the same `k`-group for every lane.
Contiguous is what a kernel wants when its lanes are steps of the reduction: one
load brings in a run of `k` for a single lane.

The driver's packer *is* that function, every kernel's index arithmetic is it
specialized to its own constants, and the parity tests read panels through it ---
so a kernel that disagrees with the layout disagrees with the reference.

Rows past `m`, columns past `n`, and depth past `k` up to the group multiple are
packed with the alphabet's zero. Zero padding contributes nothing to the sum and
nothing to the lane, which is why an unaligned or prime shape takes this path and
not a different one, and why no kernel has a `k`-tail. `CK-03` asserts that two tiers with equal decodes pack
byte-identical panels --- stronger than equal products, and the check that would
catch a codec whose decode is right but whose ordering is not.

## The canonical weight manifest

A weight artifact's identity is the kappa label of its manifest, not of its code
bytes, so that a transcode between tiers is visibly a different artifact with a
provably identical decoded stream.

```json
{"block":8,"bound":127,"codebook_sha256":"sha256:...","codes_sha256":"sha256:...",
 "cols":4096,"rows":4096,"spec":"uor-matmul/1","tier":"Book"}
```

JCS-RFC8785 canonical form: members in lexicographic key order, no whitespace,
no escapes. Bulk arrays are referenced by digest rather than inlined, so the
manifest stays inside `uor-addr-1`'s ceilings and the address stays cheap.

## The error surface

Two variants, both meaning *the requested object does not exist*, both reported
at view construction, before any arithmetic is named. See `README.md` for the
table of what is deliberately absent and why each absence is load-bearing.
