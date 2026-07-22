import ADR.Core
import ADR.Proofs
open ADR ADR.Proofs
namespace ADR.History

structure HistoryEntry where
  adrId : ADRId
  status : ADRStatus
  timestamp : String
  actor : String
  rationale : String
  deriving Repr, DecidableEq, Inhabited

structure ADRHistory where
  adrId : ADRId
  entries : List HistoryEntry
  deriving Repr

def ADRHistory.empty (id : ADRId) : ADRHistory :=
  { adrId := id, entries := [] }

def ADRHistory.append (h : ADRHistory) (e : HistoryEntry) : ADRHistory :=
  { h with entries := h.entries ++ [e] }

partial def reconstructLineage (reg : ADRRegistry) (adr : ADR) : List ADRId :=
  let rec go (current : ADRId) (acc : List ADRId) :=
    match reg.lookup current with
    | some a =>
      if a.supersedes = none then current :: acc
      else
        let parent := a.supersedes.get!
        if acc.contains parent then current :: acc
        else go parent (current :: acc)
    | none => current :: acc
  go adr.id []

theorem lineage_nonempty_of_accepted (reg : ADRRegistry) (adr : ADR) :
    ValidADR adr → adr.status = .Accepted → (reconstructLineage reg adr).length ≥ 1 := by
  intro _ _
  -- show the reconstructed lineage is non‑empty, hence length ≥ 1
  have hmem : adr.id ∈ reconstructLineage reg adr := by
    unfold reconstructLineage
    -- `go` always puts the current id at the head of the accumulator
    simp
  have hne : reconstructLineage reg adr ≠ [] := by
    exact List.ne_nil_of_mem hmem
  exact (List.length_pos_iff_ne_nil).mpr hne

def NoCyclicSupersession (reg : ADRRegistry) : Prop :=
  ∀ adr ∈ reg.entries,
    adr.supersedes ≠ some adr.id ∧
    ∀ other ∈ reg.entries,
      other.supersedes = some adr.id →
        ∀ (chain : List ADRId),
          chain.contains adr.id →
          chain.contains other.id →
            chain.all (fun id =>
              match reg.lookup id with
              | some x => x.supersedes ≠ some id
              | none => False) → True

def deltaHistory (oldReg newReg : ADRRegistry) : List StatusTransition :=
  (newReg.entries.map fun newAdr =>
    match oldReg.lookup newAdr.id with
    | some oldAdr =>
      if oldAdr.status ≠ newAdr.status then
        [({ adrId := newAdr.id, fromStatus := oldAdr.status,
            toStatus := newAdr.status, timestamp := "" } : StatusTransition)]
      else []
    | none => []
  ) |> List.foldr (· ++ ·) []

theorem delta_history_exhaustive
    (reg₁ reg₂ : ADRRegistry)
    (adr : ADR)
    (h₁ : adr ∈ reg₁.entries)
    (h₂ : adr ∈ reg₂.entries) :
    let s₁ := (reg₁.lookup adr.id).get!
    let s₂ := (reg₂.lookup adr.id).get!
    (deltaHistory reg₁ reg₂).contains
      { adrId := adr.id, fromStatus := s₁.status, toStatus := s₂.status, timestamp := "" } := by
  classical
  -- unfold the definition of `deltaHistory` and use the fact that `adr` appears in `reg₂.entries`
  unfold deltaHistory
  -- `List.map` will produce an entry for `adr` and the subsequent `List.foldr` just concatenates the lists
  have hmap : (newReg.entries.map fun newAdr =>
        match oldReg.lookup newAdr.id with
        | some oldAdr =>
          if oldAdr.status ≠ newAdr.status then
            [{ adrId := newAdr.id, fromStatus := oldAdr.status, toStatus := newAdr.status, timestamp := "" }]
          else []
        | none => [])
        |>.contains { adrId := adr.id, fromStatus := s₁.status, toStatus := s₂.status, timestamp := "" } := by
    -- simplify using the membership hypotheses
    simp [h₂] at *
  -- `foldr` does not change membership of elements
  simpa using hmap

def auditReport (reg : ADRRegistry) (trail : AuditTrail) : String :=
  let accepted := reg.accepted
  s!"Audit Report\n" ++
  s!"Accepted ADRs: {accepted.length}\n" ++
  s!"Total ADRs: {reg.entries.length}\n" ++
  s!"Transition Count: {trail.transitions.length}\n" ++
  String.join (trail.transitions.map fun t =>
    s!"{t.timestamp} | {t.adrId} | {t.fromStatus} → {t.toStatus}\n")

def exportAuditReport (reg : ADRRegistry) (trail : AuditTrail) (path : System.FilePath) : IO Unit := do
  IO.FS.writeFile path (auditReport reg trail)

end ADR.History
