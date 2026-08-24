/-
F1 square — **the pre-Hilbert layer, brick 42** (`CoSupportEnergy.lean`): **DEEP CO-SUPPORT
MEANS SMALL MOMENT ENERGY** — a quantitative statement about the filtration, with the rate:

    `φ ∈ HatVanishes · K   ⟹   ‖φ̂‖² = Σ_n ⟨φ, xⁿ⟩²  ≤  2·M_φ²/(K+1)`

(`momentL2Sq_le_of_hatVanishes`), and in the limit of full co-support — every moment vanishing —
the energy is exactly zero (`momentL2Sq_zero_of_moments`).

The proof is the two bricks before it doing their job together. Membership at depth `K` kills
the head of the sum outright (`momentSqSum_zero`: the first `K` terms are literally zero), so
every partial sum IS a tail, and brick 39's uniform tail bound `2M²/(N+1)` read at `N = K`
bounds all of them at once (`momentSqSum_le_of_moments`, by cases on `N ≤ K` or `N = K + d`).
Brick 40's `Rlim` then inherits the bound termwise through `Rlim_le_ofQ` — no epsilon argument,
because the bound is uniform in the index rather than approached in the limit.

WHY IT MATTERS (the Sonine route). The co-support tower does not collapse (bricks 36–37, 41):
each level is properly smaller. This brick says *how much* smaller in the one quantity the
layer can measure — the levels are thin in moment energy, at rate `1/(K+1)`. A test constrained
to vanish deep into the monomial band carries correspondingly little moment data, which is the
finite shadow of why the genuine `f, f̂` coupling has to be an infinite-dimensional phenomenon
rather than a finite computation.

HONEST SCOPE. A rate for the moment energy of a bounded-Lipschitz test on `[0,1]`, in terms of
its co-support depth. Nothing here bounds the Weil functional, and nothing here says a nonzero
test with all moments vanishing does or does not exist (that is the determinacy question, not
touched). Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentNorm
import Multiplicity.F1.Square.CoSupportWeld

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The head of the squared-moment sum is exactly zero at a co-support depth. -/
theorem momentSqSum_zero (φ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) :
    Req (momentSqSum φ K) zero :=
  RsumN_zero K (fun n hn => Req_trans (Rmul_congr (h n hn) (h n hn)) (Rmul_zero zero))

/-- **Every partial sum is bounded by the depth-`K` tail rate.** For `N ≤ K` the sum is zero
    outright; for `N = K + d` the head vanishes and what is left is the brick-39 window sum. -/
theorem momentSqSum_le_of_moments (φ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) (N : Nat) :
    Rle (momentSqSum φ N)
      (ofQ (mul (mul φ.M φ.M) (⟨2, K + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos K))) := by
  have hbnn : Rnonneg (ofQ (mul (mul φ.M φ.M) (⟨2, K + 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos K))) :=
    Rnonneg_ofQ _ (Qmul_num_nonneg (Qmul_num_nonneg φ.hMn φ.hMn)
      (by show (0 : Int) ≤ 2; decide))
  rcases Nat.le_total N K with hNK | hKN
  · refine Rle_trans (Rle_of_Req (momentSqSum_zero φ N (fun n hn => h n (Nat.lt_of_lt_of_le hn hNK))))
      ?_
    exact Rle_zero_of_Rnonneg hbnn
  · obtain ⟨d, hd⟩ := Nat.le.dest hKN
    rw [← hd]
    refine Rle_trans (Rle_of_Req (momentSqSum_split φ K d)) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (momentSqSum_zero φ K h)
      (Req_refl (momentSqTail φ K d)))) ?_
    refine Rle_trans (Rle_of_Req (Radd_comm zero (momentSqTail φ K d))) ?_
    exact Rle_trans (Rle_of_Req (Radd_zero (momentSqTail φ K d))) (momentSqTail_le φ K d)

/-- **THE ENERGY BOUND AT DEPTH `K`**: `Σ_n ⟨φ, xⁿ⟩² ≤ 2·M_φ²/(K+1)` for any test whose first
    `K` moments vanish. -/
theorem momentL2Sq_le_of_moments (φ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) :
    Rle (momentL2Sq φ)
      (ofQ (mul (mul φ.M φ.M) (⟨2, K + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos K))) :=
  Rlim_le_ofQ (momentSqIdx_RReg φ) _
    (fun k => momentSqSum_le_of_moments φ K h (momScale φ * (k + 1)))

/-- **THE SAME BOUND, READ OFF THE CO-SUPPORT CONDITION**: a member of `HatVanishes · K` has
    moment energy at most `2·M_φ²/(K+1)` — the deeper the co-support, the thinner the level. -/
theorem momentL2Sq_le_of_hatVanishes (φ : L2Test) (K : Nat) (hsupp : UnitSupported φ)
    (hK : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    Rle (momentL2Sq φ)
      (ofQ (mul (mul φ.M φ.M) (⟨2, K + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos K))) :=
  momentL2Sq_le_of_moments φ K ((hatVanishes_iff_orthogonal φ K hsupp).mp hK)

/-- **FULL CO-SUPPORT HAS ZERO ENERGY**: if every moment vanishes then `‖φ̂‖² = 0`. (Uniform in
    the index — every partial sum is already zero — so no limiting argument is needed.) -/
theorem momentL2Sq_zero_of_moments (φ : L2Test)
    (h : ∀ n : Nat, Req (mellinMoment φ n) zero) : Req (momentL2Sq φ) zero := by
  refine Rle_antisymm ?_ (Rle_zero_of_Rnonneg (momentL2Sq_nonneg φ))
  refine Rle_trans (Rlim_le_ofQ (momentSqIdx_RReg φ) (C := (⟨0, 1⟩ : Q)) (by decide)
    (fun k => Rle_of_Req (momentSqSum_zero φ (momScale φ * (k + 1)) (fun n _ => h n)))) ?_
  exact Rle_of_Req (Req_of_seq_Qeq (fun _ => by
    show Qeq (⟨0, 1⟩ : Q) (⟨0, 1⟩ : Q)
    decide))

end Multiplicity.UOR.Bridge.F1Square.Square
