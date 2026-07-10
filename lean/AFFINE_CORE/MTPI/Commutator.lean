import AffineCore.Foundations.BanachSpace

-- Use a complex Hilbert space H
variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

/--
The Commutator [A, B] = AB - BA.
-/
def commutator (A B : H →L[ℂ] H) : H →L[ℂ] H :=
  A.comp B - B.comp A

/--
Theorem 3.2: Admissibility Criterion.
A transition M is admissible if it commutes with the Ethical Tensor field E_t.
[M, E_t] = 0.
-/
def is_admissible (M Et : H →L[ℂ] H) : Prop :=
  commutator M Et = 0

/--
Lemma: Commutation implies that the order of ethical interpretation and 
operator application does not affect the final state.
-/
theorem commutation_order_invariance (M Et : H →L[ℂ] H) (h : is_admissible M Et) :
    ∀ ψ, M (Et ψ) = Et (M ψ) := by
  intro ψ
  have h_comm : M.comp Et = Et.comp M := by
    rw [is_admissible, commutator] at h
    exact sub_eq_zero.mp h
  calc M (Et ψ) 
      = (M.comp Et) ψ := rfl
    _ = (Et.comp M) ψ := by rw [h_comm]
    _ = Et (M ψ) := rfl
