/-
F1 square — **the Gershgorin PSD certificate: diagonal dominance ⟹ WeilPSD** (`DiagDominant.lean`).
A symmetric kernel whose diagonal dominates its absolute row sum (`Σ_{j<N} |B(i,j)| ≤ 2·B(i,i)` ∀i) has
`weilQuad B c N ≥ 0` for every test, hence `WeilPSD B` — the classical diagonally-dominant-⟹-PSD fact,
constructivized (sqrt-free, via the pointwise AM-GM `2xy·k ≥ −(x²+y²)|k|`, symmetrized). Genuine reusable
positivity infrastructure beyond the rank-one/Euclidean-Gram certificates.

HONEST SCOPE. `DiagDominant` is a SUFFICIENT CONDITION, never asserted to hold. For the coupled Weil
kernel it is a concrete per-`n` sufficient condition for the coupled positivity, STRICTLY STRONGER than
the exact dominance (= RH); whether it holds at the genuine data is unproven. A fence/lever, not a
discharge; crux stays `none`. Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/
import Multiplicity.F1Square.Square.SelfAdjoint
import Multiplicity.F1Square.Analysis.RabsLemmas
import Multiplicity.F1Square.Analysis.ThetaLipschitz

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|x|·|x| ≈ x·x`. -/
theorem Rabs_mul_self (x : Real) : Req (Rmul (Rabs x) (Rabs x)) (Rmul x x) :=
  Req_trans (Req_symm (Rabs_Rmul x x)) (Rabs_of_nonneg (Rnonneg_Rmul_self x))

/-- **Pointwise AM-GM**: `2·|a|·|b| ≤ a² + b²`. -/
theorem two_Rabs_mul_le (a b : Real) :
    Rle (Radd (Rmul (Rabs a) (Rabs b)) (Rmul (Rabs a) (Rabs b)))
        (Radd (Rmul a a) (Rmul b b)) := by
  have hexp := Rsub_sq_expand (Rabs a) (Rabs b)
  have hsq : Rnonneg (Rmul (Rsub (Rabs a) (Rabs b)) (Rsub (Rabs a) (Rabs b))) :=
    Rnonneg_Rmul_self _
  have h1 : Rle (Radd (Rmul (Rabs a) (Rabs b)) (Rmul (Rabs a) (Rabs b)))
      (Radd (Rmul (Rabs a) (Rabs a)) (Rmul (Rabs b) (Rabs b))) :=
    Rle_of_Rnonneg_Rsub (Rnonneg_congr hexp hsq)
  exact Rle_trans h1 (Rle_of_Req (Radd_congr (Rabs_mul_self a) (Rabs_mul_self b)))

/-- **The cross-term lower bound**: `2·x·(y·k) ≥ −(x²+y²)·|k|`. -/
theorem cross_term_lower (x y k : Real) :
    Rle (Rneg (Rmul (Radd (Rmul x x) (Rmul y y)) (Rabs k)))
        (Radd (Rmul x (Rmul y k)) (Rmul x (Rmul y k))) := by
  have hTabs : Req (Rabs (Rmul x (Rmul y k))) (Rmul (Rmul (Rabs x) (Rabs y)) (Rabs k)) :=
    Req_trans (Rabs_Rmul x (Rmul y k))
      (Req_trans (Rmul_congr (Req_refl (Rabs x)) (Rabs_Rmul y k))
        (Req_symm (Rmul_assoc (Rabs x) (Rabs y) (Rabs k))))
  have htri : Rle (Rabs (Radd (Rmul x (Rmul y k)) (Rmul x (Rmul y k))))
      (Radd (Rmul (Rmul (Rabs x) (Rabs y)) (Rabs k)) (Rmul (Rmul (Rabs x) (Rabs y)) (Rabs k))) :=
    Rle_trans (Rabs_Radd _ _) (Rle_of_Req (Radd_congr hTabs hTabs))
  have hdist : Req (Radd (Rmul (Rmul (Rabs x) (Rabs y)) (Rabs k)) (Rmul (Rmul (Rabs x) (Rabs y)) (Rabs k)))
      (Rmul (Radd (Rmul (Rabs x) (Rabs y)) (Rmul (Rabs x) (Rabs y))) (Rabs k)) :=
    Req_symm (Rmul_distrib_right (Rmul (Rabs x) (Rabs y)) (Rmul (Rabs x) (Rabs y)) (Rabs k))
  have hmono : Rle (Rmul (Radd (Rmul (Rabs x) (Rabs y)) (Rmul (Rabs x) (Rabs y))) (Rabs k))
      (Rmul (Radd (Rmul x x) (Rmul y y)) (Rabs k)) :=
    Rmul_le_Rmul_right (Rnonneg_Rabs k) (two_Rabs_mul_le x y)
  exact Rneg_le_of_Rabs_le (Rle_trans htri (Rle_trans (Rle_of_Req hdist) hmono))


/-- The **absolute off-diagonal mass**, weighted by `c²`: `Σ_i c_i²·(Σ_j |D(i,j)|)`. -/
def offMass (D : Nat → Nat → Real) (c : Nat → Real) (N : Nat) : Real :=
  RsumN (fun i => Rmul (Rmul (c i) (c i)) (RsumN (fun j => Rabs (D i j)) N)) N

/-- **Symmetrization**: for a symmetric `D`, `Σ_i Σ_j c_j²·|D(i,j)| ≈ offMass D c N`. -/
theorem crossMass_eq_offMass (D : Nat → Nat → Real) (hsym : SymKernel D) (c : Nat → Real) (N : Nat) :
    Req (RsumN (fun i => RsumN (fun j => Rmul (Rmul (c j) (c j)) (Rabs (D i j))) N) N)
        (offMass D c N) := by
  -- swap the two sums, pull c_j² out, use |D(i,j)|=|D(j,i)|
  refine Req_trans (RsumN_swap (fun i j => Rmul (Rmul (c j) (c j)) (Rabs (D i j))) N N) ?_
  refine RsumN_congr N (fun j _ => ?_)
  refine Req_trans (Req_symm (Rmul_RsumN_left (Rmul (c j) (c j)) (fun i => Rabs (D i j)) N)) ?_
  exact Rmul_congr (Req_refl _) (RsumN_congr N (fun i _ => Rabs_congr (hsym i j)))

/-- **The off-diagonal lower bound**: for a symmetric kernel `D`, `weilQuad D c N ≥ −offMass D c N`,
    equivalently `weilQuad D c N + offMass D c N ≥ 0` — the symmetrized AM-GM estimate. -/
theorem weilQuad_offdiag_lower (D : Nat → Nat → Real) (hsym : SymKernel D) (c : Nat → Real) (N : Nat) :
    Rnonneg (Radd (weilQuad D c N) (offMass D c N)) := by
  -- augmented term  g i j = (c_i c_j D_ij + c_i c_j D_ij) + (c_i²+c_j²)|D_ij|  ≥ 0
  have hterm : ∀ i j, Rnonneg (Radd (Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) (Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j)))) := by
    intro i j
    have hcl := cross_term_lower (c i) (c j) (D i j)
    -- Rle (Rneg (Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j)))) (Rmul (c i) (Rmul (c j) (D i j)) + Rmul (c i) (Rmul (c j) (D i j)))  ⟹  (wq+wq) + C ≥ 0
    refine Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle hcl)
    exact Radd_congr (Req_refl _) (Rneg_Rneg _)
  -- Σ_i Σ_j g i j ≥ 0
  have hsum : Rnonneg (RsumN (fun i => RsumN (fun j => Radd (Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) (Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j)))) N) N) :=
    Rnonneg_RsumN N (fun i _ => Rnonneg_RsumN N (fun j _ => hterm i j))
  -- Σ_i Σ_j g i j ≈ (weilQuad + offMass) + (weilQuad + offMass)
  have heq : Req (RsumN (fun i => RsumN (fun j => Radd (Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) (Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j)))) N) N)
      (Radd (Radd (weilQuad D c N) (offMass D c N)) (Radd (weilQuad D c N) (offMass D c N))) := by
    -- split each inner Radd, then the outer, into the four double sums
    have hstep : Req (RsumN (fun i => RsumN (fun j => Radd (Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) (Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j)))) N) N)
        (Radd (RsumN (fun i => RsumN (fun j => Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) N) N)
              (RsumN (fun i => RsumN (fun j => Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j))) N) N)) := by
      refine Req_trans (RsumN_congr N (fun i _ => RsumN_add _ _ N)) ?_
      exact RsumN_add (fun i => RsumN (fun j => Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) N)
        (fun i => RsumN (fun j => Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j))) N) N
    refine Req_trans hstep ?_
    -- term1 = weilQuad + weilQuad
    have hT1 : Req (RsumN (fun i => RsumN (fun j => Radd (Rmul (c i) (Rmul (c j) (D i j))) (Rmul (c i) (Rmul (c j) (D i j)))) N) N)
        (Radd (weilQuad D c N) (weilQuad D c N)) := by
      refine Req_trans (RsumN_congr N (fun i _ => RsumN_add (fun j => Rmul (c i) (Rmul (c j) (D i j))) (fun j => Rmul (c i) (Rmul (c j) (D i j))) N)) ?_
      exact RsumN_add (fun i => RsumN (fun j => Rmul (c i) (Rmul (c j) (D i j))) N) (fun i => RsumN (fun j => Rmul (c i) (Rmul (c j) (D i j))) N) N
    -- term2 = offMass + offMass
    have hT2 : Req (RsumN (fun i => RsumN (fun j => Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j))) N) N)
        (Radd (offMass D c N) (offMass D c N)) := by
      -- Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j)) = c_i²|D_ij| + c_j²|D_ij|
      have hCsplit : Req (RsumN (fun i => RsumN (fun j => Rmul (Radd (Rmul (c i) (c i)) (Rmul (c j) (c j))) (Rabs (D i j))) N) N)
          (Radd (RsumN (fun i => RsumN (fun j => Rmul (Rmul (c i) (c i)) (Rabs (D i j))) N) N)
                (RsumN (fun i => RsumN (fun j => Rmul (Rmul (c j) (c j)) (Rabs (D i j))) N) N)) := by
        refine Req_trans (RsumN_congr N (fun i _ => RsumN_congr N (fun j _ =>
          Rmul_distrib_right (Rmul (c i) (c i)) (Rmul (c j) (c j)) (Rabs (D i j))))) ?_
        refine Req_trans (RsumN_congr N (fun i _ => RsumN_add _ _ N)) ?_
        exact RsumN_add _ _ N
      refine Req_trans hCsplit ?_
      refine Radd_congr ?_ (crossMass_eq_offMass D hsym c N)
      -- first double sum = offMass (pull c_i² out of inner)
      exact RsumN_congr N (fun i _ =>
        Req_symm (Rmul_RsumN_left (Rmul (c i) (c i)) (fun j => Rabs (D i j)) N))
    refine Req_trans (Radd_congr hT1 hT2) ?_
    exact Radd_rearrange4 (weilQuad D c N) (weilQuad D c N) (offMass D c N) (offMass D c N)
  exact Rnonneg_of_Radd_self (Rnonneg_congr heq hsum)


/-- Kernels transported along a pointwise `≈` give equal quadratic forms. -/
theorem weilQuad_congr {B B' : Nat → Nat → Real} (h : ∀ i j, Req (B i j) (B' i j))
    (c : Nat → Real) (N : Nat) : Req (weilQuad B c N) (weilQuad B' c N) :=
  RsumN_congr N (fun i _ => RsumN_congr N (fun j _ =>
    Rmul_congr (Req_refl (c i)) (Rmul_congr (Req_refl (c j)) (h i j))))

/-- The **off-diagonal part** of a kernel: `B(i,j)` off the diagonal, `0` on it. -/
def offKernel (B : Nat → Nat → Real) : Nat → Nat → Real :=
  fun i j => if i = j then zero else B i j

/-- The off-diagonal part of a symmetric kernel is symmetric. -/
theorem offKernel_sym {B : Nat → Nat → Real} (hsym : SymKernel B) : SymKernel (offKernel B) := by
  intro i j
  by_cases h : i = j
  · subst h; exact Req_refl _
  · show Req (if i = j then zero else B i j) (if j = i then zero else B j i)
    rw [if_neg h, if_neg (fun hh => h hh.symm)]
    exact hsym i j

/-- **Diagonal dominance** (mask form): the off-diagonal absolute row sum is dominated by the
    diagonal — `Σ_{j<N, j≠i} |B(i,j)| ≤ B(i,i)` for every `i < N`. -/
def DiagDominant (B : Nat → Nat → Real) (N : Nat) : Prop :=
  ∀ i, i < N → Rle (RsumN (fun j => if i = j then zero else Rabs (B i j)) N) (B i i)

/-- `Σ_j |offKernel B (i,j)| ≈ Σ_{j≠i} |B(i,j)|` — the abs pushes through the mask. -/
theorem offKernel_absRow (B : Nat → Nat → Real) (i N : Nat) :
    Req (RsumN (fun j => Rabs (offKernel B i j)) N)
        (RsumN (fun j => if i = j then zero else Rabs (B i j)) N) := by
  refine RsumN_congr N (fun j _ => ?_)
  show Req (Rabs (if i = j then zero else B i j)) (if i = j then zero else Rabs (B i j))
  by_cases h : i = j
  · rw [if_pos h, if_pos h]; exact Rabs_zero
  · rw [if_neg h, if_neg h]; exact Req_refl _

/-- **★ GERSHGORIN**: a symmetric, diagonally dominant kernel has `weilQuad B c N ≥ 0`. -/
theorem weilQuad_nonneg_of_diagDominant (B : Nat → Nat → Real) (hsym : SymKernel B)
    (c : Nat → Real) (N : Nat) (hdd : DiagDominant B N) : Rnonneg (weilQuad B c N) := by
  -- weilQuad B ≈ weilQuad(multForm diag) + weilQuad(offKernel B)
  have hsplit : Req (weilQuad B c N)
      (Radd (weilQuad (multForm (fun k => B k k)) c N) (weilQuad (offKernel B) c N)) := by
    refine Req_trans (weilQuad_congr (fun i j => ?_) c N)
      (weilQuad_add (multForm (fun k => B k k)) (offKernel B) c N)
    by_cases h : i = j
    · subst h
      show Req (B i i) (Radd (multForm (fun k => B k k) i i) (offKernel B i i))
      rw [multForm_diag]
      show Req (B i i) (Radd (B i i) (if i = i then zero else B i i))
      rw [if_pos rfl]
      exact Req_symm (Radd_zero (B i i))
    · show Req (B i j) (Radd (multForm (fun k => B k k) i j) (offKernel B i j))
      show Req (B i j) (Radd (if i = j then (B i i) else zero) (if i = j then zero else B i j))
      rw [if_neg h, if_neg h]
      exact Req_symm (Req_trans (Radd_comm zero (B i j)) (Radd_zero (B i j)))
  -- diagPart closed form
  have hdiag : Req (weilQuad (multForm (fun k => B k k)) c N)
      (RsumN (fun i => Rmul (c i) (Rmul (c i) (B i i))) N) := weilQuad_multForm _ c N
  -- offMass(offKernel B) ≤ diagPart
  have hbound : Rle (offMass (offKernel B) c N) (weilQuad (multForm (fun k => B k k)) c N) := by
    refine Rle_trans (RsumN_le N (fun i hi => ?_)) (Rle_of_Req (Req_symm hdiag))
    -- per i: c_i²·(Σ_j|offKernel|) ≤ c_i·(c_i·B(i,i))
    have hrow : Rle (RsumN (fun j => Rabs (offKernel B i j)) N) (B i i) :=
      Rle_trans (Rle_of_Req (offKernel_absRow B i N)) (hdd i hi)
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rmul_self (c i)) hrow) ?_
    exact Rle_of_Req (Rmul_assoc (c i) (c i) (B i i))
  -- weilQuad(offKernel) ≥ −offMass(offKernel)
  have hoff : Rle (Rneg (offMass (offKernel B) c N)) (weilQuad (offKernel B) c N) := by
    have := weilQuad_offdiag_lower (offKernel B) (offKernel_sym hsym) c N
    -- Rnonneg (weilQuad + offMass) ⟹ −offMass ≤ weilQuad
    exact Rle_of_Rnonneg_Rsub (Rnonneg_congr
      (Radd_congr (Req_refl _) (Req_symm (Rneg_Rneg (offMass (offKernel B) c N)))) this)
  -- assemble: weilQuad B ≈ diagPart + weilQuad(off) ≥ diagPart − offMass(off) ≥ 0
  refine Rnonneg_congr (Req_symm hsplit) ?_
  have hstep : Rle (Radd (weilQuad (multForm (fun k => B k k)) c N) (Rneg (offMass (offKernel B) c N)))
      (Radd (weilQuad (multForm (fun k => B k k)) c N) (weilQuad (offKernel B) c N)) :=
    Radd_le_add (Rle_refl _) hoff
  have hpos : Rnonneg (Radd (weilQuad (multForm (fun k => B k k)) c N) (Rneg (offMass (offKernel B) c N))) :=
    Rnonneg_Rsub_of_Rle hbound
  exact Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg hpos) hstep)

/-- **The Gershgorin PSD certificate**: a symmetric kernel diagonally dominant at every truncation is
    `WeilPSD`. UNCONDITIONAL, sqrt-free — a new PSD class beyond rank-one/Euclidean-Gram. -/
theorem WeilPSD_of_diagDominant (B : Nat → Nat → Real) (hsym : SymKernel B)
    (hdd : ∀ N, DiagDominant B N) : WeilPSD B :=
  fun N c => weilQuad_nonneg_of_diagDominant B hsym c N (hdd N)


/-- **Diagonal dominance forces a nonnegative diagonal**: the diagonal dominates a sum of absolute
    values, hence `B(i,i) ≥ 0` — so `DiagDominant` is only ever satisfiable where the diagonal is `≥ 0`
    (for the coupled kernel: `arch(n) − primeGram(n,n) ≥ 0`, a genuine constraint on the arch excess). -/
theorem diagDominant_imp_nonneg_diag (B : Nat → Nat → Real) (N : Nat) (hdd : DiagDominant B N)
    {i : Nat} (hi : i < N) : Rnonneg (B i i) := by
  refine Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg ?_) (hdd i hi))
  refine Rnonneg_RsumN N (fun j _ => ?_)
  by_cases h : i = j
  · rw [if_pos h]; exact Rnonneg_zero
  · rw [if_neg h]; exact Rnonneg_Rabs (B i j)

end Multiplicity.UOR.Bridge.F1Square.Square
