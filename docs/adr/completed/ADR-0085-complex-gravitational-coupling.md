# ADR 0006 – Complex Gravitational Coupling

**Status:** Accepted

## Context
The system must model interactions between multiple massive bodies where gravitational forces are not pairwise independent but exhibit higher‑order coupling effects (e.g., tidal interactions, relativistic corrections). Existing simple Newtonian pairwise modules cannot capture these effects reliably.

## Decision
Introduce a new `ComplexGravitationalCoupling` module in the Rust engine that:
1. Represents each body with a `MassiveBody` struct (id, mass, position, velocity).
2. Computes pairwise Newtonian forces **and** adds a `coupling_factor` derived from the relative configuration of three or more bodies.
3. Exposes a pure‑functional API `apply_coupling(entities: &mut [MassiveBody])` that updates velocities.
4. Registers the module as an ADR‑tracked component using the `ADR` core defined in `src/adr/mod.rs`.

## Consequences
- **Correctness:** The engine can now simulate orbital resonances and tidal locking with provable invariants.
- **Performance:** Additional O(n³) calculations are bounded by a configurable `MAX_COUPLING_ORDER` (default 3).
- **Auditable Traceability:** The implementation is linked to this ADR via an `ArtifactLink` pointing to the source file.

## Links
- [`src/engine/complex_gravitational.rs`](file:///home/citizen/Multiplicity/uor-r4/src/engine/complex_gravitational.rs)

## ADR Record
```json
{
  "id": 6,
  "title": "Complex Gravitational Coupling",
  "status": "Accepted",
  "context": "...",
  "decision": "...",
  "consequences": ["Correctness", "Performance", "Auditable Traceability"],
  "supersedes": null,
  "links": [{"name": "Implementation", "url": "src/engine/complex_gravitational.rs"}]
}
```
