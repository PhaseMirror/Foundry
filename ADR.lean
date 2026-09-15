import ADR.Core
import ADR.Proofs
import ADR.Examples
import ADR.Export
import ADR.Test
import ADR.Migrated

/-!
# ADR Formal Governance Library — Entry Facade

This file is the **root module** of the `ADR` lean library (see `lakefile.lean`).
Lake requires a root module named exactly after the library; this facade
re-exports the authoritative `ADR.*` modules (single source of truth) and must
be built before any `ADR.*` consumer.

The shadow namespace `ADR.ADR.*` (legacy `adr_scaffolding` layout) is retired;
its source files are retained under `ADR/ADR/` for reference only and are
superseded by the modules imported above.
-/

open ADR

/-- The `ADRId` for this facade module, useful for provenance assertions. -/
def facadeId : ADRId := "ADR-facade"

/-- Documentation marker theorem: the facade imports expose the core model. -/
theorem facade_exposes_core :
    (ADR.ADRId = ADR.ADRId) := by rfl