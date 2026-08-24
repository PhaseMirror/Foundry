/-
F1 square — **the pre-Hilbert layer, brick 15** (`Completion.lean`): **STRONG COMPLETENESS AT
FIXED TRUNCATION — the limit member is CONSTRUCTED.**

Bricks 13–14 extended the pairing VALUES along squared-Cauchy sequences; this brick builds the
limit OBJECT. For a sequence of families `F j` that is squared-Cauchy in `dist2` (`SqCauchy`),
the limit member exists coordinatewise — each coordinate is the extended pairing against the
indicator basis:

    `limMember F N hF := fun i => pairingLim F (δᵢ)`

- `sqCauchy_pairing` — the `dist2`-Cauchy modulus transfers to every indicator pairing
  (`⟨δᵢ,δᵢ⟩ ≈ 1` on the truncation by orthonormality, `≈ 0` beyond it).
- `limMember_coord_dist` — the coordinates converge at the canonical rate:
  `|F j i − limMember i| ≤ 2/(j+1)` for `i < N` (the coefficients ARE the coordinates,
  brick 11's `fourierC_indic`).
- **`limMember_converges`** — STRONG convergence in the squared distance:
  `d²(F j, limMember) ≤ N·(2/(j+1))²` — the coordinate rates square and sum over the
  truncation. Every `dist2`-Cauchy sequence converges in `dist2` to a constructed member:
  the pre-Hilbert space at fixed truncation is COMPLETE, with an effective rate.

WHY (the Sonine route, step 3). The layer's remaining completeness lack was "the completed
space itself (limit members and strong convergence past the extended values)". At fixed
truncation both are now delivered, choice-free — the limit member is a CONSTRUCTION (extended
pairings against the basis), not a choice from a completion. What remains open on this axis is
only the truncation-uniform (genuinely infinite-dimensional) statement, which the finite
substrate fences honestly.

HONEST SCOPE. Completeness at fixed truncation `N`; the truncation-uniform completion and the
`L²` (function-space) strong completeness remain open. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.PairingLimit
import Multiplicity.F1.Square.Parseval

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The squared-Cauchy condition** on a sequence of families: `d²(F j, F k) ≤
    (1/(j+1) + 1/(k+1))²` — the canonical sqrt-free Cauchy modulus. -/
def SqCauchy (F : Nat → Nat → Real) (N : Nat) : Prop :=
  ∀ j k, Rle (dist2 (F j) (F k) N)
    (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
              (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
      (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))

/-- The `dist2`-Cauchy modulus transfers to every indicator pairing: `⟨δᵢ,δᵢ⟩ ≈ 1` on the
    truncation (orthonormality), `≈ 0` beyond it — either way the product keeps the modulus. -/
theorem sqCauchy_pairing {F : Nat → Nat → Real} {N : Nat} (hF : SqCauchy F N) (i : Nat) :
    ∀ j k, Rle (Rmul (dist2 (F j) (F k) N) (innerN (indic i) (indic i) N))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k)))) := by
  intro j k
  by_cases hi : i < N
  · have h1 : Req (innerN (indic i) (indic i) N) one := by
      have h := indic_ortho (Nat.le_refl N) i i hi hi
      rwa [if_pos rfl] at h
    refine Rle_trans (Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) h1) (Rmul_one _))) ?_
    exact hF j k
  · have h0 : Req (innerN (indic i) (indic i) N) zero := by
      refine RsumN_zero N (fun k' hk' => ?_)
      rw [indic_eq_zero (by omega : k' ≠ i)]
      exact Rmul_zero zero
    refine Rle_trans (Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) h0) (Rmul_zero _))) ?_
    refine Rle_zero_of_Rnonneg (Rnonneg_ofQ _ ?_)
    exact Int.mul_nonneg
      (Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide))
      (Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide))

/-- **THE LIMIT MEMBER**: each coordinate is the extended pairing against the indicator basis —
    a construction, not a choice. -/
def limMember (F : Nat → Nat → Real) (N : Nat) (hF : SqCauchy F N) : Nat → Real :=
  fun i => pairingLim F (indic i) N (sqCauchy_pairing hF i)

/-- **The coordinates converge at the canonical rate**: `|F j i − limMember i| ≤ 2/(j+1)` for
    `i < N` — the Fourier coefficients against the indicators are the coordinates. -/
theorem limMember_coord_dist {F : Nat → Nat → Real} {N : Nat} (hF : SqCauchy F N)
    {i : Nat} (hi : i < N) (j : Nat) :
    Rle (Rabs (Rsub (F j i) (limMember F N hF i)))
        (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
    (Req_symm (fourierC_indic (F j) hi)) (Req_refl _)))) ?_
  exact pairingLim_dist (sqCauchy_pairing hF i) j

/-- `|z|² ≈ z²` (local copy). -/
private theorem abs_sq'' (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

/-- **STRONG COMPLETENESS AT FIXED TRUNCATION**: every `dist2`-Cauchy sequence converges in
    `dist2` to the constructed limit member, with the effective rate
    `d²(F j, limMember) ≤ N·(2/(j+1))²` — the coordinate rates square and sum. -/
theorem limMember_converges {F : Nat → Nat → Real} {N : Nat} (hF : SqCauchy F N) (j : Nat) :
    Rle (dist2 (F j) (limMember F N hF) N)
        (ofQ (mul (⟨(N : Int), 1⟩ : Q) (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q)))
          (Qmul_den_pos Nat.one_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)))) := by
  refine Rle_trans (RsumN_le (G := fun _ => ofQ (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q))
      (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j))) N (fun i hi => ?_)) ?_
  · -- per-coordinate: `(F j i − limMember i)² ≤ (2/(j+1))²`
    refine Rle_trans (Rle_of_Req (Req_symm (abs_sq''
      (Rsub (F j i) (limMember F N hF i))))) ?_
    refine Rle_trans (Rsq_mono (Rnonneg_Rabs _)
      (Rnonneg_ofQ (Nat.succ_pos j) (by show (0 : Int) ≤ 2; decide))
      (limMember_coord_dist hF hi j)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ (Nat.succ_pos j) (Nat.succ_pos j))
  · exact Rle_of_Req (Req_trans
      (RsumN_const (ofQ (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q))
        (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j))) N)
      (Rmul_ofQ_ofQ Nat.one_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j))))

end Multiplicity.UOR.Bridge.F1Square.Square
