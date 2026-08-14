# The parametric framework, and the packing formats

`ARCHITECTURE.md` is the normative document. This is the discussion.

## What "parametric" is doing

The parameters are `(Element, Bound, Codec, MaxBlock, Backend, Traversal)`, and
the discipline is that none of them is ever a `match`. Adding an element type is
an `impl`. Adding a codec is an `impl`. Adding an ISA is a `KernelSpec` value.
If a change needs a branch on which one it got, the parametricity has failed and
that is the bug --- not the branch.

The reason is not elegance. A branch is a place where two paths can drift, and
two paths that can drift are two answers waiting to happen. W8A8 is the
instantiation with the most instruction support and the most external oracles,
and that is *all* it is: if the code ever treats it as the real case and the
others as generalizations, the generalizations will rot.

## The bound is a declaration, not a restriction

`Alphabet<E, Bd>` carries a bound, and the bound is a claim about the data, not
a constraint on it. `Full<E>` admits every value of `E`, including `i8::MIN`,
whose magnitude is 128 rather than 127. Refusing a representable value to keep a
bound tidy would be an arbitrary limitation dressed as rigour.

What a narrower bound buys is a longer narrow-register run. It buys nothing
else, and it can change no output byte. That is why `as_alphabet` returns the
*observed* bound when a declaration is wrong rather than an error: being wrong
about your own data is not a reason for a matmul to fail.

## The packed panel format

k-major, `pa[p * mr + i]` and `pb[p * nr + j]`, with the tails packed with the
alphabet's zero.

Zero padding is what makes an arbitrary shape take the same path as an aligned
one. It is exact --- a zero contributes nothing to an exact sum --- so there is
no tail kernel, no special case, and no shape at which a different code path
runs. `CK-03` checks the stronger property that two tiers with equal decodes
pack byte-identical panels, which is what would catch a codec whose decode is
right but whose ordering is not.

## The `kc` chunking, and why it is not a limit

A microkernel accumulates in a 32-bit lane, so a deep accumulation is split into
chunks the lane can hold and the chunks are combined in the accumulator that
cannot overflow. The chunk depth is chosen from the kernel's declared `lane_cap`
and the alphabet bound.

None of that is visible in the answer. A different chunk depth, a different
kernel, a different scratch offer: all the same bytes. `CD-01` and `CD-10`
assert it, and the reason it holds is that `combine` is associative on every
value that can arise --- which is a property of an exact accumulator and of
nothing else.

## Variable-length tiers

`Codec::MAX_BLOCK` is a *maximum*, and `decode_len` reports what a particular
code actually produces. That is what lets a run codec be a tier rather than a
second algorithm: the run structure lives inside the `Codec` impl, the matrix
validates that the lengths sum to the declared row width (`CK-06`), and
everything downstream stays dense and knows nothing about it.

The alternative --- a separate sparse matrix type with a separate driver ---
would have been two paths, and two paths drift.
