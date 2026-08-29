/-!
# ADR Core Definitions

This module defines the fundamental types for the ADR-System.

## Types Defined

- `ADRStatus` — the lifecycle state of an Architecture Decision Record
- `ArtifactLink` — a link to an external artifact
- `ADR` — the formal structure of an Architecture Decision Record
- `Contract` — a YAML-driven contract for the provable-contracts pipeline
- `KaniHarness` — a bounded model checking harness for Rust kernels
- `PipelineStage` — the stages of the provable-contracts pipeline
- `RefinementGate` — the bidirectional refinement verification gate
- `SupersessionChain` — a list tracking ADR lineage

## Conventions

All definitions follow mathlib naming conventions. Doc comments use `/-! ... -/`
blocks.
-/

namespace ADR

/-! ### ADRStatus -/

/-- The lifecycle status of an Architecture Decision Record.

Four states cover the full ADR lifecycle:
- `Proposed`: initial draft, subject to review
- `Accepted`: formally adopted, immutable without supersession
- `Deprecated`: superseded by a newer decision, retained for history
- `Superseded`: replaced by another ADR, chain preserved for traceability
-/
inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, BEq, DecidableEq, Inhabited

instance : ToString ADRStatus := ⟨fun s => match s with
  | ADRStatus.Proposed => "Proposed"
  | ADRStatus.Accepted => "Accepted"
  | ADRStatus.Deprecated => "Deprecated"
  | ADRStatus.Superseded => "Superseded"
  ⟩

/-! ### ArtifactLink -/

/-- A link to an external artifact such as a Git commit, Kani verification
report, Lean definition, or Rust kernel file. -/
structure ArtifactLink where
  url : String
  description : String
  deriving Repr, BEq

/-! ### ADR -/

/-- The formal structure of an Architecture Decision Record.

Fields:
- `id`: unique identifier (e.g., "ADR-005")
- `title`: human-readable title
- `status`: current lifecycle state
- `context`: the problem domain and constraints
- `decision`: the chosen course of action
- `consequences`: list of outcomes resulting from the decision
- `supersedes`: optional reference to a prior ADR this replaces
- `links`: list of external artifacts for traceability
-/
structure ADR where
  id           : String
  title        : String
  status       : ADRStatus
  context      : String
  decision     : String
  consequences : List String
  supersedes   : Option String := none
  links        : List ArtifactLink := []
  riskLevel    : String := "Medium"
  deriving Repr, BEq

/-! ### Contract (provable-contracts YAML representation) -/

/-- A contract definition for the provable-contracts pipeline.

Contracts specify the inputs, outputs, theorems, and computational bounds
for a Rust kernel + Lean theorem pair. They drive the bidirectional
refinement pipeline.
-/
structure Contract where
  name : String
  version : String
  description : String
  inputs : List String
  outputs : List String
  theorems : List String
  rust_implementation : String
  lean_implementation : String
  kani_bound : Nat
  deriving Repr, BEq

/-! ### KaniHarness -/

/-- A Kani bounded model checking harness for a Rust kernel.

Each harness is bounded by the contract's `kani_bound` and verifies that
the Rust implementation respects the Lean theorem for all symbolic inputs
within the bound. -/
structure KaniHarness where
  contract_name : String
  function_name : String
  bound : Nat
  file_path : String
  properties : List String
  derived_from : String
  deriving Repr, BEq

/-! ### PipelineStage -/

/-- A stage in the provable-contracts bidirectional refinement pipeline.

The pipeline stages are:
1. `ContractDefinition` — YAML contract authored
2. `LeanStubGeneration` — Lean stubs generated from contract
3. `RustKernelGeneration` — Rust kernel stubs generated from contract
4. `KaniHarnessGeneration` — Kani harnesses generated with bounds
5. `ProofFilling` — Lean theorems proven using constructive analysis
6. `RefinementVerification` — Kani proves Rust respects Lean theorem
-/
inductive PipelineStage where
  | ContractDefinition
  | LeanStubGeneration
  | RustKernelGeneration
  | KaniHarnessGeneration
  | ProofFilling
  | RefinementVerification
  deriving Repr, BEq, Inhabited

instance : ToString PipelineStage := ⟨fun s => match s with
  | PipelineStage.ContractDefinition => "ContractDefinition"
  | PipelineStage.LeanStubGeneration => "LeanStubGeneration"
  | PipelineStage.RustKernelGeneration => "RustKernelGeneration"
  | PipelineStage.KaniHarnessGeneration => "KaniHarnessGeneration"
  | PipelineStage.ProofFilling => "ProofFilling"
  | PipelineStage.RefinementVerification => "RefinementVerification"
  ⟩

/-! ### RefinementGate -/

/-- The bidirectional refinement verification gate.

A refinement gate checks that:
1. The Lean theorem compiles with zero `sorry`s (except explicit T5 axiom)
2. The Kani harness passes for all symbolic inputs up to the bound
3. The contract's `rust_implementation` and `lean_implementation` are mutually consistent
-/
structure RefinementGate where
  contract : Contract
  lean_passed : Bool
  kani_passed : Bool
  consistency_checked : Bool
  sorry_count : Nat
  kani_bound_respected : Bool
  deriving Repr, BEq

/-- A refinement gate passes when all three checks succeed. -/
def RefinementGate.passes (g : RefinementGate) : Bool :=
  g.lean_passed && g.kani_passed && g.consistency_checked &&
  g.sorry_count = 0 && g.kani_bound_respected

/-! ### Pipeline State -/

/-- The complete state of the provable-contracts pipeline for a single contract.

Tracks the contract, its current pipeline stage, and the refinement gate result.
-/
structure PipelineState where
  contract : Contract
  stage : PipelineStage
  gate : RefinementGate
  deriving Repr, BEq

/-! ### Supersession Chain -/

/-- A supersession chain is a list of ADR IDs where each ADR supersedes the
previous one. Used to track the lineage of decisions and prove properties
about circularity and traceability. -/
abbrev SupersessionChain := List String

/-- Append an ADR ID to a supersession chain. -/
def SupersessionChain.push (chain : SupersessionChain) (id : String) : SupersessionChain :=
  id :: chain

/-- Check if an ADR ID appears in a supersession chain (cycle detection). -/
def SupersessionChain.hasCycle (chain : SupersessionChain) (id : String) : Bool :=
  id ∈ chain

/-! ### Registry -/

/-- A registry is the ordered collection of ADRs governed by the system.

The registry is the single source of truth for lookups (`lookup`),
traceability (`Registry.trace` in `ADR.Proofs`), and the audit-monitor
queries exported for Kani cross-checks. -/
structure Registry where
  adrs : List ADR
  deriving Repr, BEq

namespace Registry

/-- Look up an ADR by its id within the registry. -/
def lookup (reg : Registry) (id : String) : Option ADR :=
  reg.adrs.find? (fun a => a.id == id)

/-- Register a new ADR, appending it to the registry (append-only discipline). -/
def add (reg : Registry) (a : ADR) : Registry :=
  { adrs := reg.adrs ++ [a] }

/-- The accepted ADRs of a registry, in registry order. -/
def accepted (reg : Registry) : List ADR :=
  reg.adrs.filter (fun a => a.status == ADRStatus.Accepted)

/-- The proposed ADRs of a registry, in registry order. -/
def proposed (reg : Registry) : List ADR :=
  reg.adrs.filter (fun a => a.status == ADRStatus.Proposed)

/-- The ids of all ADRs in the registry, in registry order. -/
def ids (reg : Registry) : List String :=
  reg.adrs.map (fun a => a.id)

/-- True when no id occurs twice in the registry (append-only uniqueness). -/
def uniqueIds (reg : Registry) : Bool :=
  (reg.ids.eraseDups).length == reg.ids.length

end Registry

/-! ### Status Transitions -/

/-- A formally valid status transition between two ADRs.

The constructors *enforce* the governance rules at the type level, so no
transition object exists unless the status discipline is satisfied:

- `accept`: a `Proposed` ADR becomes `Accepted`; the successor keeps the
  original supersession pointer (acceptance never rewrites history).
- `supersede`: an `Accepted` ADR is replaced; the successor must name the
  superseded ADR in `supersedes`.
- `deprecate`: an `Accepted` ADR is deprecated; the successor must name the
  superseded ADR so history remains reconstructible.

Because the field `rule` of `Transition` carries a `ValidTransition` proof,
a user cannot construct an invalid state change — this is the first line of
defense against conflicting or orphaned decisions (ADR-009 § Integration).
-/
inductive ValidTransition (src dst : ADR) : Prop where
  | accept (hsrc : src.status = ADRStatus.Proposed)
      (hdst : dst.status = ADRStatus.Accepted)
      (hkeep : dst.supersedes = src.supersedes) : ValidTransition src dst
  | supersede (hsrc : src.status = ADRStatus.Accepted)
      (hdst : dst.supersedes = some src.id) : ValidTransition src dst
  | deprecate (hsrc : src.status = ADRStatus.Accepted)
      (hdst : dst.status = ADRStatus.Deprecated)
      (href : dst.supersedes = some src.id) : ValidTransition src dst

/-- A proof-carrying status transition: the `rule` field makes the transition
formally valid by construction. -/
structure Transition where
  src : ADR
  dst : ADR
  rule : ValidTransition src dst

end ADR
