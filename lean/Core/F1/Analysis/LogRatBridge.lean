/-
F1 square — **the `∫ log` layer, part 2c(ii): the log-of-rational bridge**
(`LogRatBridge.lean`). The point values of the totalized integrand `gLog c` are
`RlogPos (ofQ q)` at the dyadic samples `q = (c(N+1)+j)/(N+1)`; the telescoping rate
(`LogStep`) speaks `logN`. This file joins them:

    `RlogPos (ofQ ⟨a, d⟩) ≈ logN a − logN d`      (`d ≤ a ≤ 4d`)

by **exp-injectivity** — no new series, no new integral:

    `exp(RlogPos(a/d) + logN d) ≈ exp(RlogPos(a/d)) · exp(logN d)`   (`RexpReal_add`)
                               `≈ (a/d) · d ≈ a ≈ exp(logN a)`        (`Rexp_log_ratQ`, `Rexp_logN`)

then `RexpReal_inj_gen` cancels the `exp` and `(X+Y)−Y ≈ X` finishes. The two
certificates consumed are exactly the part 2c(i) products: `radius_half_proj` (the
uniform small-radius certificate on the band `d ≤ a ≤ 4d`) feeding `RlogPos_eq_Rlog`
at the presented modulus `B = a/d`, and `sample_ge_one`.

HONEST SCOPE. An identity between two constructed logarithms; no integral is evaluated
and no positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ComplexArgAdd
import Core.F1.Analysis.RlogMulPos
import Core.F1.Analysis.LogRatCert

namespace UOR.Bridge.F1Square.Analysis

/-- `(X+Y) − Y ≈ X` (private copy; the `RealPow` original is private). -/
private theorem radd_sub_cancel (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

/-- The band sample as a constant real is positive at every index. -/
private theorem band_xpos (a d : Nat) (hd : 0 < d) (ha1 : 1 ≤ a) :
    ∀ n, 0 < ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq n).num := fun _ => by
  show (0 : Int) < ((a : Nat) : Int); exact_mod_cast ha1

/-- The band sample squared clears `1`: `1 ≤ (a/d)²` from `d ≤ a`. -/
private theorem band_lo (a d : Nat) (hd : 0 < d) (hda : d ≤ a) :
    ∀ n, Qle (⟨1, 1⟩ : Q)
      (mul ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq n) (⟨(a : Int), d⟩ : Q)) := fun _ => by
  show (1 : Int) * ((d * d : Nat) : Int) ≤ ((a : Int) * (a : Int)) * 1
  have hsq : ((d : Int)) * (d : Int) ≤ (a : Int) * (a : Int) := by
    exact_mod_cast Nat.mul_le_mul hda hda
  push_cast
  omega

/-- The product collapse `(a/d)·d = a` at the rational layer. -/
private theorem band_mul_den (a d : Nat) :
    Qeq (mul (⟨(a : Int), d⟩ : Q) (⟨(d : Int), 1⟩ : Q)) (⟨(a : Int), 1⟩ : Q) := by
  show ((a : Int) * (d : Int)) * 1 = (a : Int) * ((d * 1 : Nat) : Int)
  push_cast; ring_uor

/-- **★ The log-of-rational bridge**: for `d ≤ a ≤ 4d` (`0 < d`) and any positivity
    witness `(k, hk)`,

        `RlogPos (ofQ ⟨a, d⟩) k hk ≈ logN a − logN d`.

    Route: `RlogPos_eq_Rlog` at the presented modulus `B = a/d` (small-radius certificate
    `radius_half_proj`, uniform on the band), `Rexp_log_ratQ` for `exp(log(a/d)) ≈ a/d`,
    the constant-real product collapse `(a/d)·d ≈ a`, `Rexp_logN` on both naturals, and
    `RexpReal_inj_gen` to cancel the `exp`. General in the sample — this is the single
    lemma every dyadic point value of `gLog c` (`c ≤ 3`) routes through. -/
theorem RlogPos_ofQ_eq_logN (a d : Nat) (hd : 0 < d) (hda : d ≤ a) (ha4 : a ≤ 4 * d)
    (k : Nat) (hk : Qlt (Qbound k) ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq k)) :
    Req (RlogPos (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk)
      (Rsub (logN a (Nat.le_trans hd hda)) (logN d hd)) := by
  have ha1 : 1 ≤ a := Nat.le_trans hd hda
  have hqge := sample_ge_one a d hda
  have hxpos := band_xpos a d hd ha1
  have hhi : ∀ n, Qle ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq n) (⟨(a : Int), d⟩ : Q) :=
    fun _ => Qle_refl _
  have hlo := band_lo a d hd hda
  -- A. `exp(RlogPos(a/d)) ≈ a/d`: auto-radius → presented modulus → the rational gate.
  have hA : Req (RexpReal (RlogPos (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk))
      (ofQ (⟨(a : Int), d⟩ : Q) hd) :=
    Req_trans
      (RexpReal_congr (RlogPos_eq_Rlog (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk
        (⟨(a : Int), d⟩ : Q) hd hqge hxpos hhi hlo (radius_half_proj a d hd hda ha4)))
      (Rexp_log_ratQ (⟨(a : Int), d⟩ : Q) hd hqge hxpos hhi hlo)
  -- B. `exp(RlogPos(a/d) + logN d) ≈ exp(logN a)`.
  have hB : Req (RexpReal (Radd (RlogPos (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk) (logN d hd)))
      (RexpReal (logN a ha1)) :=
    Req_trans (RexpReal_add _ (logN d hd))
      (Req_trans (Rmul_congr hA (Rexp_logN d hd))
        (Req_trans (Rmul_ofQ_ofQ hd Nat.one_pos)
          (Req_trans (ofQ_congr (Qmul_den_pos hd Nat.one_pos) Nat.one_pos (band_mul_den a d))
            (Req_symm (Rexp_logN a ha1)))))
  -- C. Cancel the `exp`, then subtract `logN d`.
  exact Req_trans (Req_symm (radd_sub_cancel _ (logN d hd)))
    (Rsub_congr (RexpReal_inj_gen hB) (Req_refl (logN d hd)))

end UOR.Bridge.F1Square.Analysis
