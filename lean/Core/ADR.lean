/-!
# ADR
Architecture Decision Records as first-class formal artifacts.

This module re-exports the complete ADR scaffolding:
- `ADR.Core` — foundational types
- `ADR.Logics` — embedded propositional logic for consequence entailment
- `ADR.Proofs` — formal theorems and proof obligations
- `ADR.History` — traceability and audit trail
- `ADR.Governance` — state-transition controller
- `ADR.Examples` — verified example ADRs (including ADR-120)
- `ADR.Export` — Markdown/HTML generators
- `ADR.Test` — test harness
-/

import ADR.Core
import ADR.Logics
import ADR.Proofs
import ADR.History
import ADR.Governance
import ADR.Examples
import ADR.Export
import ADR.Test
