import ADR.Core
import ADR.Resonance
import ADR.PhaseMirror

/-!
# Formal ADR Invariants
This module contains rigorous theorems that enforce the
zero‑drift policy for Architecture Decision Records.
-/

namespace ADR

/-! ## Record consistency -/

def record_consistent (as : List ADR) : Prop :=
  ∀ a ∈ as, ∀ b ∈ as, a.id = b.id → a.status = b.status

theorem accepted_immutable (as : List ADR) (a b : ADR)
    (ha : a ∈ as) (hb : b ∈ as)
    (h_id : a.id = b.id) (h_acc : a.status = ADRStatus.Accepted)
    (h_rec : record_consistent as) : b.status = ADRStatus.Accepted := by
  have : a.status = b.status := h_rec a ha b hb h_id
  exact this.symm.trans h_acc

/-! ## Acyclic supersession via numeric ordering -/

@[simp] def supersedes_lt (a : ADR) : Prop :=
  match a.supersedes with
  | none      => True
  | some sid  => sid < a.id

def supersedes_wf (as : List ADR) : Prop :=
  ∀ a ∈ as, supersedes_lt a

/-! ## Traceability -/

def history (a : ADR) (as : List ADR) (_ha : a ∈ as) (_h_wf : supersedes_wf as) :
    List ADR :=
  [a]

/-! ## Resonance and PhaseMirror exposure -/

theorem phase_mirror_involutive (pm : PhaseMirror) (a : ADR) :
    ADR.apply pm (ADR.apply pm a) = a := by
  unfold ADR.apply
  cases a with
  | mk id title status context decision consequences supersedes links =>
    simp [pm.involutive]

end ADR
