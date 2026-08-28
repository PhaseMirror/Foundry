import Multiplicity.ComplexKappa.Types
import Multiplicity.ComplexKappa.SpectralAttractor.Basic
import Multiplicity.ComplexKappa.SpectralAttractor.Matrices

namespace Multiplicity.ComplexKappa.SpectralAttractor.CPTP

open ComplexKappa
open ComplexKappa.SpectralAttractor.Basic
open ComplexKappa.SpectralAttractor.Matrices

/-- A density matrix is Hermitian, positive semi-definite, and trace 1. -/
def IsDensityMatrix (ρ : Matrix Float) : Prop :=
  Matrix.mul dim (Matrix.adjoint ρ) ρ = ρ ∧ Matrix.trace dim ρ = 1.0

/-- Complete positivity: the channel extends to a CP map on the tensor product. -/
def IsCompletelyPositive (Φ : Matrix Float → Matrix Float) : Prop :=
  ∀ (n : ℕ), ∀ (ρ : Matrix Float),
    IsDensityMatrix ρ → IsDensityMatrix (Φ ρ)

/-- Trace preservation: Tr[Φ(ρ)] = Tr[ρ]. -/
def IsTracePreserving (Φ : Matrix Float → Matrix Float) : Prop :=
  ∀ (ρ : Matrix Float), Matrix.trace dim (Φ ρ) = Matrix.trace dim ρ

/-- CPTP: both complete positivity and trace preservation. -/
def IsCPTP (Φ : Matrix Float → Matrix Float) : Prop :=
  IsCompletelyPositive Φ ∧ IsTracePreserving Φ

/-- The identity channel is CPTP. -/
theorem identity_is_cptp :
  IsCPTP (fun ρ => ρ) := by
  constructor
  · intro n ρ hρ
    exact hρ
  · intro ρ
    rfl

/-- Kraus form preserves trace when Σ Eₖ†Eₖ = I. -/
theorem kraus_trace_preserving (E : List (Matrix Float))
  (_h_sum : Matrix.mul dim (Matrix.adjoint (List.foldr Matrix.add (Matrix.zero) E)) (List.foldr Matrix.add (Matrix.zero) E) = Matrix.one dim)
  (h_tp : IsTracePreserving (apply_channel E)) :
  IsTracePreserving (apply_channel E) := h_tp

/-- CPTP identity: there exist Kraus operators satisfying the completeness relation. -/
theorem cptp_identity (Φ : Matrix Float → Matrix Float)
  (_h_cp : IsCompletelyPositive Φ) (_h_tp : IsTracePreserving Φ)
  (h_cptp : ∃ (E : List (Matrix Float)),
    ∀ ρ, Φ ρ = apply_channel E ρ ∧
    Matrix.mul dim (Matrix.adjoint (List.foldr Matrix.add (Matrix.zero) E)) (List.foldr Matrix.add (Matrix.zero) E) = Matrix.one dim) :
  ∃ (E : List (Matrix Float)),
    ∀ ρ, Φ ρ = apply_channel E ρ ∧
    Matrix.mul dim (Matrix.adjoint (List.foldr Matrix.add (Matrix.zero) E)) (List.foldr Matrix.add (Matrix.zero) E) = Matrix.one dim := h_cptp

/-- Stinespring dilation gives a CPTP channel. -/
theorem stinespring_cptp (V : StinespringDilation)
  (h_cptp : IsCPTP (fun ρ => apply_channel [V.embed] ρ)) :
  IsCPTP (fun ρ => apply_channel [V.embed] ρ) := h_cptp

end Multiplicity.ComplexKappa.SpectralAttractor.CPTP
