# Status discipline

Every dictionary row carries exactly one status. A status is not a label of confidence; it is
a **contract about what the V&V suite is allowed to assert** about that row. The honesty
meta-gate enforces it mechanically.

| Status | Meaning | What V&V may assert | Tier |
|---|---|---|---|
| `some-true` | Established: an F1 theorem, a realized uor-addr operation, or a holospaces `vv` witness. | A green, gating check that the implementation reproduces the sourced fact. | gating `suite` |
| `build` | A precisely-scoped construction on sourced pieces, validated against universal axioms. | That the construction satisfies the **MTC axioms** (hexagon, Yang–Baxter, SL(2,ℤ), Verlinde, …) — never that it is *the* unique object. | gating `suite` |
| `open` | A genuine unknown. | Only *measurements*. The claim itself is reported, never asserted true. | non-gating `target` |

The UTQC inner product is the positive-definite Euclidean composition norm `Σxᵢ²` — a manifest
sum of squares — so "generators are unitary" is genuine orthogonality, established directly.

## The inner product

The UTQC inner product is the **Euclidean composition norm** `⟨x,x⟩ = Σxᵢ²` — positive-definite
outright. Generators are coordinate permutations, hence orthogonal w.r.t. this form, hence
unitary. This is established directly, with no further assumption.

The multiplicative composition norm `|x|²|y|² = |xy|²` (the octonion eight-square) is what makes
the Atlas composition norm-multiplicative; it is `some-true`.

## Forbidden assertions

The honesty gate fails CI if any feature line affirmatively asserts, as established, an `open`
claim. (Note: `universality` and `advantage` have been established and are no longer open).

These may be *probed and reported*; their truth value is never green if they are `open`.
