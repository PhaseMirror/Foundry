import UniversalLogic.Types

set_option autoImplicit false

/-!
# Free-Type Signatures (FTS) Algebraic Soundness & Conservation
-/

namespace UniversalLogic

/-- Signature conservation condition: sigma_in + sigma_param = sigma_out. -/
def signature_conserved (sigma_in sigma_param sigma_out : FTS) : Prop :=
  FTS.add sigma_in sigma_param = sigma_out

/-- Theorem: Identity/Neutral parameters (sigma = 0) strictly preserve input signatures. -/
theorem neutral_param_preserves_signature (s : FTS) :
    FTS.add s FTS.zero = s := by
  dsimp [FTS.add, FTS.zero]
  match s with
  | ⟨c, f, h, m, q⟩ =>
      dsimp
      have h1 : c + 0 = c := by omega
      have h2 : f + 0 = f := by omega
      have h3 : h + 0 = h := by omega
      have h4 : m + 0 = m := by omega
      have h5 : q + 0 = q := by omega
      rw [h1, h2, h3, h4, h5]

/-- Theorem: FTS composition is strictly associative. -/
theorem fts_add_assoc (s1 s2 s3 : FTS) :
    FTS.add (FTS.add s1 s2) s3 = FTS.add s1 (FTS.add s2 s3) := by
  dsimp [FTS.add]
  have h1 : s1.classical_weight + s2.classical_weight + s3.classical_weight =
            s1.classical_weight + (s2.classical_weight + s3.classical_weight) := by omega
  have h2 : s1.fuzzy_weight + s2.fuzzy_weight + s3.fuzzy_weight =
            s1.fuzzy_weight + (s2.fuzzy_weight + s3.fuzzy_weight) := by omega
  have h3 : s1.heyting_weight + s2.heyting_weight + s3.heyting_weight =
            s1.heyting_weight + (s2.heyting_weight + s3.heyting_weight) := by omega
  have h4 : s1.modal_weight + s2.modal_weight + s3.modal_weight =
            s1.modal_weight + (s2.modal_weight + s3.modal_weight) := by omega
  have h5 : s1.quantum_weight + s2.quantum_weight + s3.quantum_weight =
            s1.quantum_weight + (s2.quantum_weight + s3.quantum_weight) := by omega
  rw [h1, h2, h3, h4, h5]

end UniversalLogic
