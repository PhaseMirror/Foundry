# Observability Calculus — Public Specification v1.0

**Status:** Implementation-delivered (ADRs 0022–0028). Kernel `observ-0.1.0`, wire version `0x004F`.
**Reference:** ADRs 0022–0028 (source papers); `docs/Universal_Closure/The Universal Calculator.tex` §2.1; ADR-0021 (prime-indexing math, no floats).

## The measurement program (input)

The kernel accepts a **measurement map** described over an operator space of dimension `dim ≤ 32`:

| Wire field | Meaning |
|---|---|
| `stages` | ordered stages `S, R, P, A, T` (probe), first-applied first. Kinds: `source`, `response`, `probe_projection`, `averaging`, `transfer`, `nuisance`. Each a `dim × dim` exact-integer matrix. |
| `targets` | focus functionals `C` (rows over the operator coordinates) to be identified. |
| `probes` | additional experimental channels whose rows can be added to resolve obstruction. |
| `claims` | six-component closure claims (below). |
| `reversals` | Walsh–Hadamard reversal cubes (below). |
| `reference` | the admissible symmetry reference (below), required for any source-state closure. |
| `claims[]` / `reversals[]` / `reference` | optional; default absent. |

Integer-only wire. Every coefficient is an `i64` with `|v| ≤ 2^31` (`MAX_ENTRY`); floating point is
structurally impossible (ADR-0021).

## The null filtration and witness duality

With `F_j = a_j ∘ a_{j-1} ∘ … ∘ a_1` (left-applied-first, `F_0 = I`):

- **Null filtration** `K_j = ker F_j`, per cumulative stage, by exact row reduction.
- **New-null attribution** `new_null_j = dim K_j − dim K_{j−1}` — which stage first erases the direction.
- **Dual witness filtration** `W_j = im F_j^*` (`dim W_j = rank F_j`), the recoverable readouts.
- **Refactor attribution**: the same total fiber can be reached by two filters; the calculus reports
  where in the pipeline the fiber closed, not merely that it closed.

## Target obstruction and design gain

For a focus functional `C` against a stacked map `S` (all stage/probe rows):

- `obstruction_dim(S) = dim C(ker S)` — the identifiable-vs-obstructed split.
- The dual **counterexample**: when `d_C > 0`, a witness row `λ` with `λ ∉ im S^T` and `λ·ker
  S ≠ {0}` is reported explicitly.
- **Design gain** `Δ_C = d_C(base) − d_C(base ∪ probe)` — a repeat of a varying channel
  (`B_sig`) earns `Δ = 0`; a target-changing channel (`B_tar`) earns `Δ = 1`.
- The pipeline is **lockdown-bounded**: `#stages × dim ≤ 512` (`LOCKDOWN_PIPELINE_CELLS`).

## Reversal-space coding

A reversal cube encodes `y(s) = Σ_q χ_q(s) f_q` over `n` independent sign flips into exact
Walsh–Hadamard characters `Î_A = (Σ_s y(s)·χ_A(s)) / 2^n` (exact rational `Q`). A **forbidden
mask** `A` with `Î_A ≠ 0` is a forbidden-sector leak and kills the gate. Reversal maps must be
valid involutive commuting signed permutations (`group_is_valid`).

## The admissible reference (state gate)

Given a group `G` of signed permutations with characters `χ`:

- Projector `P = (1/|G|) Σ_g ρ(g)`; invariant sector = `im P`, complement (odd) = `ker P`.
- `a_null`: the reference target vanishes on the invariant sector (`O·P = 0`).
- Parity: for the declared odd direction `λ`, `F_O(ρ_g λ) = χ(g)·F_O(λ)` must hold for every `g`.
- `admissible = independent ∧ state ∧ a_null ∧ no-retune` — the reference certificate required
  to close any source (`S`) claim. Otherwise the kernel names `ReferenceInapplicable`.

## The six-component claim gate

Claims are rows over components `M, S, E, X, R, K`. The kernel assesses each against
`(channel, focus)`:

- A claim **closes** only if `status ∈ {Closed, Supported}` and the focus is identifiable
  (`obstruction_dim(channel, focus) = 0`).
- **Source-state gate**: any `S` (source/exchange) claim requires an admissible declared
  reference; closing `M` when the microstructure is contradictory is a `NullMisattribution`,
  migrating the claim (`ClaimMigration`).
- **Contamination**: once the micro component is in `{Contradicted, Blocked}`, downstream
  components are revised to `Blocked`; closing them is `DownstreamBeforeSourceGate`.

## Defects, latches, verdict

Named defects (each a node can act on, fixed-point metric, in English): `ProgramMalformed`,
`NullMisattribution`, `ClaimMigration`, `DownstreamBeforeSourceGate`, `ReferenceInapplicable`,
`ForbiddenSectorLeak`, `ReversalPathBreach`, `ExpansiveTransition`, `ArithmeticOverflow`.

A `FailLatch` commits `(named defect, expansive)`; any `Δ ≠ ∅` or expansive transition produces
the non-maskable kill signal `sig_gov_kill` (fail-closed, and no false-kill and
kill-requires-evidence hold as kani-proved properties). Lawful measurements also emit a **receipt**:
a canonical 64-byte core (`program_sha256 ‖ kernel_version_tag ‖ wire_version ‖ build_id ‖
governance_meta`) bound into the CRMF PWEH integrity chain (prime 2), and the four kani harness
names. When `Δ ≠ ∅`, one `[owner] — action — metric — horizon` lever is derived per defect.

## Example (lawful)

```json
{
  "name": "polarization_split",
  "dim": 2,
  "stages": [
    { "name": "unpolarized_projection", "kind": "probe_projection",
      "matrix": [[1, 0], [0, 0]] }
  ],
  "targets": [ { "name": "chiral_correlator", "rows": [[1, 0]] } ],
  "probes": [], "claims": [], "reversals": [], "reference": null
}
```

Verdict: `signal: "nominal"`, `obstruction_dim: 0`, `new_null: 1` (polarization projection class).

## Example (unlawful — forbidden-sector leak)

```json
{
  "name": "reversal_cube",
  "dim": 2,
  "stages": [
    { "name": "fiber_readout", "kind": "response", "matrix": [[1, 0], [0, 1]] }
  ],
  "targets": [ { "name": "target", "rows": [[1, 0]] } ],
  "probes": [], "claims": [], "reference": null,
  "reversals": [
    { "n": 2, "cube": [1, -1, -1, 1],
      "forbidden_masks": [3], "state_dim": 2,
      "reversal_maps": [ [[1,0],[0,1]], [[1,0],[0,1]] ] }
  ]
}
```

Verdict: `signal: "sig_gov_kill"`, `defects: [{code: "forbidden_sector_leak", …}]`, exit 2.