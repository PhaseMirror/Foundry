# ADR-PML-067: Consequence Entailment Vacuum — formal ADR model has no consequence-checker

## Status
Accepted
Proposed

## Axis
control desired vs available

## Owner
`the-publisher`

## Dissonance Score
- Impact = severity (4) x blast radius (1) = **4**
- Tractability = **4.0**
- **Score = 16.0**

## Context
The formal ADR model in `AGENTS.md` requires that every listed consequence be
"logically entailed by decision + context" (simple `simp`/`rintro` proofs or a
tiny embedded logic). The `Prime/lean/Core/ADR.lean` re-export wrapper imports
`ADR.Logics`, but:

1. `ADR.Logics` does not exist as a `.lean` file anywhere in the workspace.
2. `adr0001.lean:73–78` discharges `ValidADR` using `trivial` for **all** proof
   obligations, including `consequences_entailed`.
3. The `entails` predicate referenced in `adr0001.lean:66` is never defined.

### Manifested boundary
Leaked (unmanifested): YES — the formal model promises consequence verification
but implements none. Any `ADRRecord` with false consequences would pass
`ValidADR` because all checks are vacuous.

## Decision
Implement `ADR.Core` and `ADR.Logics` as the foundation modules, then implement
a minimal embedded propositional logic for consequence entailment. Replace
`trivial` in `adr0001.lean` with actual proof scripts.

The entailment checker is deliberately simple: a `List (String × String)` for
context/consequence pairs, with a `decide`-based matcher for now. A future
iteration can replace this with a full embedded DSL without changing the `ADRRecord`
type.

## Consequences
- **Positive**: the formal model is no longer a shell. `ValidADR` catches
  malformed ADRs at type-check time.
- **Negative / Constraints**: the initial matcher is string-based and does not
  perform deep semantic entailment.
- **Verification Strategy**: every `ADRExample` must pass `adr_example_valid`;
  a deliberately malformed example must fail to type-check.

## Metrics (resolution is confirmed when)
- `ADR/Logics.lean` compiles and defines `Entails`.
- `adr0001.lean` replaces all `trivial` proofs with actual `Entails` instances.
- `lake test` passes the `adr_test` driver.
- A `@[expect failure]` theorem demonstrates the type system catching a malformed ADR.

## Actionable Levers
1. Create `Prime/lean/Core/ADR/Core.lean` with `ADRStatus`, `ADRId`, `ArtifactLink`,
   `ADRRecord`, `ValidADR`, and `ADRStatus` inductive.
2. Create `Prime/lean/Core/ADR/Logics.lean` with `Entails` decision procedure.
3. Refactor `adr0001.lean` to use the new `Entails` proofs.
4. Re-run `scripts/phase_mirror_loop.py`; this tension's score must reach 0.

## Links
- Formal scaffold: `Prime/lean/formal/ADR.md`
- Ghost re-export: `Prime/lean/Core/ADR.lean`
- Empty proof: `Prime/lean/adr-governance/ADR/FolderLoop/ADR0001.lean:73–78`
