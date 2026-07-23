/-!
# ADR
Architecture Decision Records as first-class formal artifacts.

This module documents the ADR scaffolding locations in the project:

- `ADR.Core` — defined in `src/ADR/Core.lean` (existing ADR lib)
- `ADR.Proofs` — defined in `src/ADR/Proofs.lean`
- `ADR.Examples` — defined in `src/ADR/Examples.lean`
- `ADR.Export` — defined in `src/ADR/Export.lean`
- `ADR.Test` — defined in `src/ADR/Test.lean`
- `ADR.Resonance` — defined in `src/ADR/Resonance.lean`
- `ADR.PhaseMirror` — defined in `src/ADR/PhaseMirror.lean`
- `ADR.Dissonance` — defined in `src/ADR/Dissonance.lean`

NOTE: The re-export imports below are intentionally commented out because
they reference modules in the `ADR` lib (`src/ADR/`), which is a separate
Lake package (`Prime/lakefile.lean`). Uncommenting them would require
adjusting the package configuration to make the ADR lib visible to Core.

See `ADR-PML-066` and `ADR-PML-068` for the architectural contradictions
this creates.
-/

-- import ADR.Core
-- import ADR.Proofs
-- import ADR.Examples
-- import ADR.Export
-- import ADR.Test
-- import ADR.Resonance
-- import ADR.PhaseMirror
-- import ADR.Dissonance
