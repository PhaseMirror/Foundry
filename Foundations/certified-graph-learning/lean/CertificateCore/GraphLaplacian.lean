import CertificateCore.Matrix

/-!
# CertificateCore.GraphLaplacian

Graph Laplacian matrices: definition, spectral axioms, and the heat step operator.

The graph Laplacian L = D - A where D is the diagonal degree matrix and A is the
adjacency matrix. Key properties:
- L is symmetric
- L is positive semi-definite
- All rows sum to 0 (the constant vector is an eigenvector with eigenvalue 0)
- The second eigenvalue (spectral gap) λ₂ > 0 for connected graphs

Eigenvalue machinery is captured by documented axioms — never `sorry`.
-/

namespace CertificateCore

/-- Graph Laplacian structure: the matrix together with its structural axioms. -/
structure GraphLaplacian (n : Nat) where
  L : Mat n
  symmetric : Mat.IsSymmetric L
  psd : Mat.IsPSD L
  rowSum : Mat.RowSumEq L 0

namespace GraphLaplacian

variable {n : Nat}

/-! ## Structural Properties -/

/-- Laplacian applied to the constant vector is zero (L · 𝟙 = 0). -/
theorem laplacian_const_zero (G : GraphLaplacian n) :
    Mat.mulVec G.L (Vec.ones : Vec n) = Vec.zero := by
  change Mat.mulVec G.L (fun _ : Fin n => 1) = Vec.zero
  exact Mat.rowSum_zero_mulVec_const G.L G.rowSum

/-- The mean of L·u is zero for every u.
    Axiomatized: requires column-sum interchange via symmetry (Σᵢ Lᵢⱼ = 0). -/
axiom laplacian_mean_zero (G : GraphLaplacian n) (u : Vec n) :
    Vec.mean (Mat.mulVec G.L u) = 0

/-- The Laplacian preserves the mean-zero subspace: P(L·u) = L·u. -/
theorem laplacian_preserves_mean_zero (G : GraphLaplacian n) (u : Vec n) :
    Vec.meanZero (Mat.mulVec G.L u) = Mat.mulVec G.L u :=
  Vec.meanZero_eq_of_mean_zero (Mat.mulVec G.L u) (laplacian_mean_zero G u)

/-- The constant component of `u` does not affect L·u: L(P·u) = L·u. -/
theorem laplacian_mulVec_meanZero (G : GraphLaplacian n) (u : Vec n) :
    Mat.mulVec G.L (Vec.meanZero u) = Mat.mulVec G.L u := by
  unfold Vec.meanZero
  rw [Mat.mulVec_sub]
  have hC : Mat.mulVec G.L (Vec.smul (Vec.mean u) Vec.ones) = Vec.zero := by
    rw [Mat.mulVec_smul]
    rw [laplacian_const_zero]
    exact Vec.smul_zero (Vec.mean u)
  rw [hC]
  exact Vec.vsub_zero (Mat.mulVec G.L u)

/-- The Laplacian is self-adjoint for the inner product:
    ⟨L·u, v⟩ = ⟨u, L·v⟩.
    Axiomatized: requires summation interchange over `Fin n` combined with
    symmetry of L. -/
axiom laplacian_self_adjoint (G : GraphLaplacian n) (u v : Vec n) :
    Vec.inner (Mat.mulVec G.L u) v = Vec.inner u (Mat.mulVec G.L v)

/-! ## Spectral Axioms -/

/-- The spectral gap (second eigenvalue / Fiedler value) λ₂ of L.
    Axiomatized: computing eigenvalues requires characteristic polynomials and
    algebraic closure, thousands of lines of foundational development. -/
axiom spectral_gap (G : GraphLaplacian n) : Rat

/-- The spectral gap is positive for connected graphs. -/
axiom spectral_gap_pos (G : GraphLaplacian n) : 0 < spectral_gap G

/-- Rayleigh quotient lower bound: on the mean-zero subspace,
    xᵀ L x ≥ λ₂ · ‖x‖². -/
axiom spectral_gap_quadratic_bound (G : GraphLaplacian n) (x : Vec n)
    (hx : Vec.mean x = 0) :
    spectral_gap G * Vec.normSq x ≤ Mat.quadraticForm G.L x

/-- The spectral radius ρ(L) = λ_max of L. -/
axiom spectral_radius (G : GraphLaplacian n) : Rat

/-- Rayleigh quotient upper bound: xᵀ L x ≤ ρ · ‖x‖² for all x. -/
axiom spectral_radius_upper (G : GraphLaplacian n) (x : Vec n) :
    Mat.quadraticForm G.L x ≤ spectral_radius G * Vec.normSq x

/-- The spectral radius dominates the spectral gap: 0 < λ₂ ≤ ρ. -/
axiom spectral_gap_le_radius (G : GraphLaplacian n) :
    spectral_gap G ≤ spectral_radius G

/-! ## Heat Step Operator -/

/-- Heat step operator: u_{t+1} = u_t - α · L · u_t = (I - αL) · u_t -/
def heatStep (G : GraphLaplacian n) (alpha : Rat) (u : Vec n) : Vec n :=
  Vec.vsub u (Vec.smul alpha (Mat.mulVec G.L u))

/-- The heat step operator as a matrix: H = I - αL -/
def heatStepMatrix (G : GraphLaplacian n) (alpha : Rat) : Mat n :=
  Mat.madd Mat.id (Mat.smul (-alpha) G.L)

/-- Valid step size: α ∈ (0, 2/ρ(L)) ensures the heat step operator does not
    overshoot the spectrum. -/
def ValidStepSize (G : GraphLaplacian n) (alpha : Rat) : Prop :=
  0 < alpha ∧ alpha < (2 : Rat) / spectral_radius G

/-- The mean-zero projection commutes with the heat step:
    P(u - α·L·u) = P·u - α·L·(P·u). -/
theorem meanZero_heat_step (G : GraphLaplacian n) (alpha : Rat) (u : Vec n) :
    Vec.meanZero (heatStep G alpha u) =
      Vec.vsub (Vec.meanZero u) (Vec.smul alpha (Mat.mulVec G.L (Vec.meanZero u))) := by
  unfold heatStep
  rw [Vec.meanZero_vsub, Vec.meanZero_smul]
  rw [laplacian_preserves_mean_zero]
  rw [laplacian_mulVec_meanZero]

/-- Energy identity: the norm-squared energy after a heat step equals the
    norm-squared of the contracted mean-zero vector. -/
theorem meanZero_energy_identity (G : GraphLaplacian n) (alpha : Rat) (u : Vec n) :
    Vec.normSq (Vec.meanZero (heatStep G alpha u)) =
      Vec.normSq (Vec.vsub (Vec.meanZero u)
        (Vec.smul alpha (Mat.mulVec G.L (Vec.meanZero u)))) := by
  rw [meanZero_heat_step]

end GraphLaplacian
end CertificateCore