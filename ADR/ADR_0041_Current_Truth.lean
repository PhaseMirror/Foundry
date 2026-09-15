import ADR.Core
import ADR.Proofs

/-! # ADR‑0041 — CURRENT_TRUTH
   Living Honesty Ledger & Current Truth specification.
   Formalized against the current `ADR.Core` API (string identifiers, `Entails` on `PropTerm`).
-/

open ADR

/-- Helper to create an `ArtifactLink`. -/
def mkLink (desc url : String) : ArtifactLink := ⟨url, .SpecificationDoc, desc⟩

/-- ADR‑0041 definition: the immutable Current Truth ledger. -/
@[adr]
def ADR_0041 : ADR :=
  { id := "ADR-0041"
    title := "CURRENT_TRUTH – Living Honesty Ledger & Current Truth"
    status := ADRStatus.Accepted
    context := "Defines a globally shared, append‑only ledger that records every accepted ADR together with its cryptographic hash and a Merkle proof. The ledger is the source of truth for all governance queries."
    decision := "Adopt an immutable append‑only data structure (Merkle‑log) as the authoritative Current Truth ledger; all runtime components must query this ledger for the latest accepted ADRs."
    consequences := [ "Globally verifiable audit trail"
                    , "Zero‑drift governance state"
                    , "Cryptographic proof of inclusion for every ADR"
                    , "Deterministic reconciliation across replicas" ]
    supersedes := none
    links := [ mkLink "Merkle Log Specification" "https://example.org/merkle-log"
             , mkLink "Current Truth Whitepaper" "https://example.org/current-truth" ] }

/-- The decision proposition self-entails under the embedded propositional semantics.
This is the syntactic (tractable) guarantee; full decision→consequence entailment is
the extension seam exposed by `PropTerm`/`Entails` in `ADR.Core`. -/
@[proof]
theorem decision_self_entailed_0041 :
    Entails [PropTerm.atom ADR_0041.decision] (PropTerm.atom ADR_0041.decision) := by
  intro env hprem
  exact hprem (PropTerm.atom ADR_0041.decision) (by simp)

/-- ADR‑0041 is Accepted and thus participates in traceability obligations. -/
@[proof]
theorem adr0041_accepted : ADR_0041.status = ADRStatus.Accepted := by
  rfl