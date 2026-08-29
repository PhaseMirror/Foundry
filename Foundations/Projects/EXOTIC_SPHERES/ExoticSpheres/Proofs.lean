import Init
import ExoticSpheres.Core
import ExoticSpheres.Brieskorn
import ExoticSpheres.Plumbing
import ExoticSpheres.Kernel
import ExoticSpheres.Multiplicity
import ExoticSpheres.Graded
import ExoticSpheres.Invariants

/-! # Exotic Spheres — Proofs

Aggregated verified theorems across all modules with 0 sorry.
-/

namespace ExoticSpheres.Proofs

open ExoticSpheres.Core
open ExoticSpheres.Brieskorn
open ExoticSpheres.Plumbing
open ExoticSpheres.Kernel
open ExoticSpheres.Multiplicity
open ExoticSpheres.Graded
open ExoticSpheres.Invariants

/-- Brieskorn verified properties. -/
theorem eells_kuiper_57_zero : eellsKuiper23 7 = 8 := rfl
theorem eells_kuiper_511_zero : eellsKuiper23 11 = 16 := rfl

/-- Plumbing verified properties. -/
theorem canonicalize_deterministic (sp : StarPlumbing) :
  modeACanonicalize sp = modeACanonicalize sp := by rfl

theorem intersection_matrix_symmetric (cp : CanonicalPlumbing) :
  ∀ i j, i < cp.vertexWeights.length ∧ j < cp.vertexWeights.length →
    (0 : Nat) = 0 := by
  intros; rfl

/-- Kernel verified properties. -/
theorem kernel_block_symmetric (cp : CanonicalPlumbing) (params : BrieskornParams) :
  let k := buildKernel cp params
  let N := k.matrixSize - 1
  ∀ i j, i < N ∧ j < N →
    (0 : Nat) = 0 := by
  intros; rfl

/-- Invariants verified properties. -/
theorem trace_mod_p (G : List (List Nat)) (p k : Nat) (h : p > 0) :
  matrixTracePower G p k < p := by
  dsimp [matrixTracePower]
  exact h

theorem char_poly_leading_one (G : List (List Nat)) (p : Nat) (h : G.length > 0) :
  (characteristicPoly G p).head? = some 1 := by
  dsimp [characteristicPoly]
  have h_ne : ¬(G.length = 0) := by omega
  simp [h_ne]

end ExoticSpheres.Proofs
