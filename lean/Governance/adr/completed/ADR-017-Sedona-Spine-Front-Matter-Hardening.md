# ADR-017: Sedona-Spine Front-Matter Hardening

## Status
Draft

## Context
Implementation velocity of the PIRTM compiler frontend (lexer, parser, AST construction) is in tension with the Sedona Spine mandate. The mandate requires that successor predicates and multiplicity conservation must be non-bypassable first-class compilation errors at the earliest materialization points. We need to ensure that no invalid stratum can materialize before validation executes.

## Decision
We define the exact entry points (lexer token rules, parser productions, AST node builders) and require construction-time invariant checks.
1. We mandate Rational64 exactness for the Multiplicity Functor \(M(S)\).
2. Every path is bound to Lean 4 proof materialization.
3. We elevate successor-predicate and stratum-boundary checks to failable constructors for AST nodes where feasible. We keep decoupled validation only for context-dependent strata.
4. The CI pipeline will feature a non-bypassable Sedona Spine gate that rejects any PR touching lexer/parser/AST if it fails the AdmissibilityValidator and successor checks before any IR generation. 
5. A valid ContractivityReceipt is strictly required before merge or MLIR emission.

## Consequences
- **Owner: DevOps Lead** -> 100% of PRs touching lexer/parser/AST pass Sedona Spine CI gate. (Horizon: 7 days)
- **Owner: Compiler Engineering** -> Zero front-matter paths that emit or store invalid stratum without Rational64 exactness and ContractivityReceipt linkage. (Horizon: 14 days)
- **Owner: Governance** -> Full provenance from source edit through Archivum Ledger for every frontend change. (Horizon: 30 days)

## Precision Response
The current parser (context-agnostic on prime literals) plus state-dependent AdmissibilityValidator leaves some lexer or AST construction paths that can materialize an invalid \(P_N(t)\) stratum before validation executes. Thus, not all front-matter entry points are currently safe under the existing design. Hardening these with construction-time invariant checks is necessary to close this gap.
