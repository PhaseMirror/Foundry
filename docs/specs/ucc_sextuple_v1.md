# UCC Sextuple — Public Specification v1.0

**Status:** Adopted (ADR-0014 layer: "Sextuple + Lean surface").
**Reference:** ADR-0014 §Layers-vs-quarters; ADR-0021 (prime-indexing math); `docs/Universal_Closure/The Universal Calculator.tex` §2.1.

## The sextuple

The Universal Closure Calculator kernel (UCC) accepts a **partial system** expressed as the
sextuple `(X, ∘, α, μ, F, Δ)`:

| Slot | Name | Meaning | Wire field |
|---|---|---|---|
| X | state set | the prime-indexed objects of the system; each object carries an **irreducible prime identity** | `x` |
| ∘ | lawful composition | the composition law the closure must respect: `join` (⊗, lossless `lcm` structural join) or `union` (⊕, exact exponent aggregation / Dirichlet convolution on multiplicative coefficients) | `op` |
| α | closure anchor | the coherence/identity anchor of the composition law; `1` for join (lcm identity), `0` for union (empty exponent profile) | `alpha` |
| μ | surplus ledger | the finite-support exponent map (from ADR-0021, "exponents as memory"); `v_p` per prime, defaults to `1` for every present node | `multiplicity` |
| F | endomorphism | the lawful transform applied to a relation step: `identity` (no growth) or `ofai` (operator-first arithmetic iterate with `iterate >= 1`) | `f` |
| Δ | defect | the residual defect of the call. The kernel **rederives** Δ over the whole system; a caller may carry a prior named defect in `delta` | `delta` |

## The lawfulness gate (L0)

The kernel never emits a closure it cannot prove lawful. A call is **unlawful**, and the L0
gate kills the transition (fail-closed, non-maskable), when any named defect Δ ≠ ∅ is present:

1. `IdentityIrreducible` — an object identity is not a prime number.
2. `IdentityUnique` — two objects share the same prime identity.
3. `RelationDangling` — a relation references an identity outside X (a forbidden prime channel).
4. `MultiplicityKeyUnknown` — the surplus ledger μ keys an identity not in X.
5. `EndomorphismUnlawful` — F is malformed (`kind` unknown, or `iterate == 0`).
6. `CoherenceAnchor` — α does not equal the identity of the declared composition law.
7. `MonotonicityBreach` — composition would decrease a surplus exponent below its carried base.
8. `AssociatorDefect` — the scaled associator norm ‖Δ‖ exceeds the tolerance ε (the two
   association orders of the composition law disagree).
9. `ExpansiveTransition` — the scaled spectral envelope Λ_m fails contractivity (Λ_m ≥ 1), or a
   recursion escalation bound is breached (`iterate` or relation arity over its cap).
10. `ArithmeticOverflow` — a lawful composition overflows the integer envelope.

Lawfulness is a **structural** contractivity/associator property of the kernel boundary. This
specification does not assert any relation to, or consequences for, the Riemann Hypothesis;
the RH discussion lives in the paper. The kernel SLA is kernel version, latency, and receipt
integrity (ADR-0014).

## The four artifacts of every call

A call to `/close` returns:

1. **Closure** — the smallest equivalence relation over X respecting lawful composition,
   computed as a Kuratowski closure (extensive, monotone, idempotent). Each component is
   labelled by the lawful composition of its members.
2. **Defect (Δ)** — each named in English a node can act on, with the affected primes and a
   fixed-point metric ‖Δ‖.
3. **Receipt** — `input_sha256 || kernel_version || lawful_recursion_version || build_id ||
   timestamp`, canonically serialized per ADR-0021 (fixed field order, ULEB128-prefixed
   sequences, no floats) and checked into the PWEH integrity chain.
4. **Levers** — when Δ ≠ 0, one `[owner] — action — metric — horizon` pair per defect.

## Wire format

- Integer-only. No floating point anywhere in the wire schema; drift is structurally
  impossible (ADR-0021).
- Canonical serialization: fixed field order, ULEB128 length prefixes (ADR-0021 §BCS).
- Array element count prefixes are deterministic and length-checked.

## Example (lawful)

```json
{
  "x": [ { "prime": 2, "label": "alpha" }, { "prime": 3, "label": "beta" }, { "prime": 5, "label": "gamma" } ],
  "op": "join",
  "alpha": 1,
  "multiplicity": {},
  "f": { "kind": "identity", "iterate": 1 },
  "relations": [ { "a": 2, "b": 3 } ],
  "delta": null
}
```

## Example (unlawful — composite identity)

```json
{
  "x": [ { "prime": 6, "label": "not-a-prime" } ],
  "op": "join",
  "alpha": 1,
  "multiplicity": {},
  "f": { "kind": "identity", "iterate": 1 },
  "relations": [],
  "delta": null
}
```

## Machine schema

`docs/specs/ucc_sextuple_v1.schema.json`.