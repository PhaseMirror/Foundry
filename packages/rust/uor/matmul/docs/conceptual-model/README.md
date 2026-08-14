# The conceptual model, in prose

The typed half lives in `model/*.toml` and is the single source of every
constant (R10). This is the half that explains what those numbers *mean*, and
the two are meant to be read together.

## A matmul on coded operands

The usual way to think about quantized matmul is that it is a matmul with a
compression scheme bolted on: decompress the weights, then multiply. The model
here inverts that. The codec is not a preprocessing step; it is part of what the
operand *is*. A weight tier is a function `d : Code -> Alphabet(B)`, and the
operation is

```text
sum_i a_i * d(c_i)
```

The consequence that matters is that `d` does not appear in the arithmetic. Two
tiers with equal decodes produce equal products --- not approximately, not up to
a rounding mode, but byte for byte. That is `CL-MM01`, and it is the reason a
change of tier is a change of *artifact* rather than a change of *result*.

## Why exactness is the cheap choice

An exact accumulation sounds expensive and in one sense it is: a complete
accumulator for `f64` is 536 bytes per output element. What it buys is that a
long list of things stop being questions.

Is the result the same on two backends? Yes, necessarily, because both compute
the same integer. Is it the same with a different tile partition? Yes. With a
different number of threads? Yes. Does it depend on the order the reduction
happened in? No --- and for a classical `f32` GEMM the answer to every one of
those is "usually, within a tolerance nobody has written down".

The engineering that normally goes into managing those questions --- tolerances,
reproducibility modes, deterministic-reduction flags --- is not needed, because
the questions do not arise. That is the trade, and it is worth stating plainly
rather than pretending the exactness is free.

## Why there is no envelope

A quantized kernel usually documents a range in which it is exact and wraps or
saturates outside it. This library has no such range, and the reason is
structural rather than heroic: the worst case is `k * B_a * B_w`, all three
factors are bounded by things the machine already fixes, so an accumulator sized
against that worst case cannot overflow *for any input the machine can
represent*. Overflow is unreachable rather than guarded.

What survives of the envelope idea belongs to the oracles. A classical GEMM has
one, usually undocumented, and outside it the oracle is the one that is wrong.
Because this library holds the exact value, that becomes measurable: "how far
off is `matrixmultiply` at k = 4096" is a number to publish rather than a
difference to explain away.

## Why a float is a code

An IEEE 754 value is a bit pattern naming an exact dyadic rational. That is
exactly the shape of a codebook entry, so the float path is not a second method
--- it is the same three steps at a different instantiation. Decode the pattern,
accumulate the exact products in a fixed-point register wide enough for the
whole exponent range, round once.

The result is the correctly-rounded value of the exact sum, which is
schedule-independent by construction. It is therefore *not* bit-identical to any
classical `sgemm`, and reproducing one is non-goal N1.

## Why the honesty levels

Three registers, and confusing them is the failure mode this repository is most
at risk of. The identity is proved upstream (`some-true`). That the kernels here
realize it is evidence, gathered by differential testing against libraries that
have never heard of it (`build`). How fast any of it runs is a measurement of a
machine on a day (`open`).

A sentence like "this library proves codec invariance" collapses all three, and
nobody writes it on purpose --- they write "proves" where they meant "is
evidence for", and six months later the sentence is load-bearing. The meta-gate
exists because the failure is linguistic, so the check has to be too.
