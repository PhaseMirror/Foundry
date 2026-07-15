# ADR-WF-001 — pscmd compose: Declarative Workflow Authoring

## Status
Accepted (2026-05-22)

## Context
Phase 4 Step 11 introduces `.sigma.yaml` as a declarative workflow authoring surface. 
Currently, the system uses `lever_manifest.yaml` as an imperative surface for "levers".
We need to define the relationship between these two surfaces and ensure they both target the same execution kernel.

## Decision
**Option A: Coexistence.**

1. Both `lever_manifest.yaml` (levers) and `.sigma.yaml` (composed workflows) will be supported indefinitely.
2. We will promote the `Workflow` and `Task` structures from `multiplicity-sigma` to `multiplicity-common` to serve as the unified Intermediate Representation (IR).
3. `pscmd compose` will act as a compiler that transforms `.sigma.yaml` into this unified IR.
4. The `commander-core` kernel will remain transport-and-source agnostic, executing only the unified IR.

## Consequences
- **Maintenance**: Requires maintaining two parser codepaths (YamlLoader for levers, Serde-Yaml for Sigma).
- **Consistency**: Centralizing the `Task` and `Workflow` structs in `common` prevents schema drift between the two authoring surfaces.
- **Portability**: Sigma workflows can declare complex multi-step interactions and custom server bindings that levers cannot easily express.

## Non-negotiable constraint
Compiled output MUST be the unified `Workflow` / `Task` structure that passes `cargo test --test governance`. No new execution path. No new trust surface.
