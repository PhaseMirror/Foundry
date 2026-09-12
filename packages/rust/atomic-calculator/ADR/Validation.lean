import ADR.Core

namespace ADR.Validation

def WellFormed (r : DecisionRecord) : Prop :=
  r.id ≠ "" ∧ r.title ≠ "" ∧ r.context ≠ "" ∧ r.decision ≠ "" ∧ r.consequences ≠ "" ∧ r.date ≠ "" ∧ r.authors ≠ []

def StatusValid (r : DecisionRecord) : Prop :=
  match r.status with
  | Status.superseded id => id ≠ ""
  | _ => True

def Invariant (r : DecisionRecord) : Prop :=
  WellFormed r ∧ StatusValid r

theorem mkADR_well_formed (id title context decision consequences date authors : String) (status : Status)
  (h_id : id ≠ "") (h_title : title ≠ "") (h_context : context ≠ "") (h_decision : decision ≠ "") (h_cons : consequences ≠ "")
  (h_date : date ≠ "") (h_authors : authors.splitOn "," ≠ []) :
  WellFormed (mkADR id title context decision consequences date authors status) := by
  unfold WellFormed mkADR
  simp [h_id, h_title, h_context, h_decision, h_cons, h_date, h_authors]

theorem mkADR_invariant (id title context decision consequences date authors : String) (status : Status)
  (h_id : id ≠ "") (h_title : title ≠ "") (h_context : context ≠ "") (h_decision : decision ≠ "") (h_cons : consequences ≠ "")
  (h_date : date ≠ "") (h_authors : authors.splitOn "," ≠ []) (h_status : StatusValid (mkADR id title context decision consequences date authors status)) :
  Invariant (mkADR id title context decision consequences date authors status) := by
  apply And.intro
  exact mkADR_well_formed _ _ _ _ _ _ _ _ h_id h_title h_context h_decision h_cons h_date h_authors
  exact h_status

end ADR.Validation
