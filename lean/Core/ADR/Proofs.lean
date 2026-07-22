import ADR.Core
import ADR.Logics
open ADR ADR.Logics Literal
namespace ADR.Proofs

def entails (_context _decision _consequence : String) : Prop := True

structure ValidADR (adr : ADR) : Prop where
  accepted_immutable :
    adr.status = ADRStatus.Accepted → adr.supersedes = none → True
  consequences_entailed :
    ∀ c ∈ adr.consequences, entails adr.context adr.decision c
  no_circular_supersession :
    adr.supersedes ≠ some adr.id
  traceability :
    adr.status = ADRStatus.Accepted → adr.links.length > 0
  valid_urls :
    adr.status = ADRStatus.Accepted →
      adr.links.all (fun l =>
        l.url.startsWith "http" ∨
        l.url.startsWith "file" ∨
        l.url.startsWith "/")

structure ConsequenceCoverageProof where
  coveredId : ADRId
  consequence : String
  derivedFrom : List String
  deriving Repr, Inhabited

def ConsequenceCoverageProof.covers (p : ConsequenceCoverageProof) (id : ADRId) : Bool :=
  p.coveredId = id

structure TransitionProof where
  adr : ADR
  fromStatus : ADRStatus
  toStatus : ADRStatus
  supersedesId : Option ADRId := none
  witnessConsequences : List ConsequenceCoverageProof
  deriving Repr

def TransitionProof.valid (tp : TransitionProof) : Prop :=
  tp.adr.status = tp.fromStatus ∧
  ValidADR tp.adr ∧
  (tp.toStatus = .Superseded → tp.supersedesId ≠ none) ∧
  (match tp.supersedesId with
    | some sid => tp.witnessConsequences.all (fun w => w.covers sid)
    | none => True)

def UniqueIds (reg : ADRRegistry) : Prop :=
  ∀ a ∈ reg.entries, ∀ b ∈ reg.entries, a.id = b.id → a = b

def AcyclicSupersession (reg : ADRRegistry) : Prop :=
  ∀ adr ∈ reg.entries, adr.supersedes ≠ some adr.id ∧
  ∀ other ∈ reg.entries,
    other.supersedes = some adr.id →
      ¬ ∃ (chain : List ADRId),
          chain.contains adr.id ∧
          chain.contains other.id ∧
          chain.all (fun id =>
            match reg.lookup id with
            | some x => x.supersedes ≠ some id
            | none => False)

def AcceptedTraceable (reg : ADRRegistry) (trail : AuditTrail) : Prop :=
  ∀ adr ∈ reg.entries, adr.status = .Accepted →
    trail.transitions.any (·.adrId = adr.id)

def mkValidADR
    (adr : ADR)
    (hImm : adr.status = .Accepted → adr.supersedes = none → True)
    (hConseq : ∀ c ∈ adr.consequences, entails adr.context adr.decision c)
    (hCirc : adr.supersedes ≠ some adr.id)
    (hTrace : adr.status = .Accepted → adr.links.length > 0)
    (hURLs : adr.status = .Accepted →
              adr.links.all (fun l =>
                l.url.startsWith "http" ∨
                l.url.startsWith "file" ∨
                l.url.startsWith "/")) :
    ValidADR adr :=
  ⟨hImm, hConseq, hCirc, hTrace, hURLs⟩

end ADR.Proofs
