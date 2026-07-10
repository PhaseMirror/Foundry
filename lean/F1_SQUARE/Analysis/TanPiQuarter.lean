/-
F1 square — v0.22.0 Track 1, brick (argument axis): **`tan(π/4) = 1` and the `π/2` values
`cos(π/2) = 0`, `sin(π/2) = 1`** — the anchors of the full-range complex argument `Carg`/`Clog`.

The complex logarithm beyond the principal sector (`|arg| < π/4`) routes through the reciprocal
reduction `arctan t = π/2 − arctan(1/t)` (for large `|t|`), which in turn needs `sin(π/2) = 1` and
`cos(π/2) = 0`. The obstacle: the value identity `sin(arctan t) = t·cos(arctan t)`
(`Rsin_arctan_value_eq`) is proved only for `|t| < 1/16` (the nested-composition radius forced by
`DN_arctan_decay`), while Machin's `π = 16·arctan(1/5) − 4·arctan(1/239)` uses `1/5 > 1/16`.

The way around, here: **Gauss's Machin-like formula** `π/4 = 12·arctan(1/18) + 8·arctan(1/57) −
5·arctan(1/239)`, whose three arguments are ALL `< 1/16` (common radius `ρ = 1/18`). The value
identity applies to each leaf, and the angles are chained through `Rsin_cos_add_tan` — which needs
only `1 − ab > 0` (never that the OUTPUT tangent is small), so the running tangent climbs to exactly
`1` while every step's `|running·leaf| ≤ 0.039 < 1`. The exact rational tangent of the 25-leaf
combination is `1` (`vval`-checked), giving `sin(π/4) = cos(π/4)`. Double-angle (`Rsin_add_of_tan`,
`Rcos_add_of_tan`) on `π/2 = 2·(π/4)` then yields `cos(π/2) = 1 − 1·1 = 0` and, via Pythagoras,
`sin(π/2) = 2·cos²(π/4) = 1`.

(The reciprocal arctan reduction and the lift to `Carg`/`Clog` past `|arg| < π/4` are the following
bricks; this file supplies their `π/2` anchors. Consistency with the Machin `Rpi` of `Pi.lean` —
`Rpi = 4·Spi4.angle` — is a separate later lemma.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ArctanTan

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- A real angle bundled with its (rational) tangent value: `sin A = tan·cos A`.
-- The carrier of the tangent-addition chain.
-- ===========================================================================

/-- **A tangent-carrying real angle**: `angle` with a rational `tan` and the value-level relation
    `sin(angle) = tan·cos(angle)`. The atom of the `Rsin_cos_add_tan` chain. -/
structure TanReal where
  angle : Real
  tan : Q
  htd : 0 < tan.den
  hrel : Req (Rsin angle) (Rmul (ofQ tan htd) (Rcos angle))

/-- **Add two tangent-carrying angles**: `angle₁ + angle₂` has tangent `vval = (a+b)/(1−ab)`, by the
    value-level tangent-addition law `Rsin_cos_add_tan` (requires only `1 − ab > 0`). -/
def TanReal.add (x y : TanReal)
    (hpos : 0 < (x.tan.den : Int) * y.tan.den - x.tan.num * y.tan.num) : TanReal :=
  { angle := Radd x.angle y.angle
    tan := vval x.tan y.tan
    htd := vval_den_pos x.tan y.tan hpos
    hrel := Rsin_cos_add_tan x.htd y.htd hpos x.hrel y.hrel }

/-- **Relabel the tangent to a `Qeq`-equal literal** (keeps the chain's tangents shallow, so each
    positivity `decide` stays cheap). Same angle, tangent `t'` with `tan ≈ t'`. -/
def TanReal.retag (x : TanReal) (t' : Q) (ht'd : 0 < t'.den) (h : Qeq x.tan t') : TanReal :=
  { angle := x.angle
    tan := t'
    htd := ht'd
    hrel := Req_trans x.hrel (Rmul_congr (ofQ_congr x.htd ht'd h) (Req_refl (Rcos x.angle))) }

/-- **One chain step**: add `y` to `x` then relabel the resulting tangent to the literal `t'`. -/
def TanReal.step (x y : TanReal)
    (hpos : 0 < (x.tan.den : Int) * y.tan.den - x.tan.num * y.tan.num)
    (t' : Q) (ht'd : 0 < t'.den) (h : Qeq (vval x.tan y.tan) t') : TanReal :=
  (x.add y hpos).retag t' ht'd h

/-- **Negate a tangent-carrying angle**: `−angle` has tangent `−tan` (`sin` odd, `cos` even). Completes
    the bundle's additive group, so subtracted angles (e.g. the `−5·arctan(1/239)` term of a Machin
    combination) are handled at the bundle level rather than through signed leaves. -/
def TanReal.negate (x : TanReal) : TanReal :=
  { angle := Rneg x.angle
    tan := neg x.tan
    htd := x.htd
    hrel := by
      have h3 : Req (Rmul (ofQ (neg x.tan) x.htd) (Rcos (Rneg x.angle)))
          (Rneg (Rmul (ofQ x.tan x.htd) (Rcos x.angle))) :=
        Req_trans (Rmul_congr (Req_refl (ofQ (neg x.tan) x.htd)) (Rcos_neg x.angle))
          (Req_trans (Rmul_congr (Req_symm (Rneg_ofQ x.tan x.htd)) (Req_refl (Rcos x.angle)))
            (Rmul_neg_left (ofQ x.tan x.htd) (Rcos x.angle)))
      exact Req_trans (Req_trans (Rsin_neg x.angle) (Rneg_congr x.hrel)) (Req_symm h3) }

/-- **Subtract**: `x.angle − y.angle` carries tangent `vval x.tan (−y.tan) = (a−b)/(1+ab)`. -/
def TanReal.sub (x y : TanReal)
    (hpos : 0 < (x.tan.den : Int) * (neg y.tan).den - x.tan.num * (neg y.tan).num) : TanReal :=
  x.add y.negate hpos

-- ===========================================================================
-- The three Gauss leaves at the common radius ρ = 1/18 (each |r| ≤ 1/18 < 1/16).
-- ===========================================================================

/-- The leaf `arctan(1/18)` with tangent `1/18` (value identity at `ρ = 1/18`). -/
def L18 : TanReal :=
  { angle := Rarctan (⟨1, 18⟩ : Q) (by decide) (by decide) (by decide) (by decide)
      (show Qle (Qabs (⟨1, 18⟩ : Q)) (⟨1, 18⟩ : Q) by decide)
    tan := ⟨1, 18⟩
    htd := by decide
    hrel := Rsin_arctan_value_eq (⟨1, 18⟩ : Q) (⟨1, 18⟩ : Q) (by decide) (by decide) (by decide)
      (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) }

/-- The leaf `arctan(1/57)` with tangent `1/57`. -/
def L57 : TanReal :=
  { angle := Rarctan (⟨1, 57⟩ : Q) (by decide) (by decide) (by decide) (by decide)
      (show Qle (Qabs (⟨1, 57⟩ : Q)) (⟨1, 18⟩ : Q) by decide)
    tan := ⟨1, 57⟩
    htd := by decide
    hrel := Rsin_arctan_value_eq (⟨1, 57⟩ : Q) (⟨1, 18⟩ : Q) (by decide) (by decide) (by decide)
      (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) }

/-- The leaf `arctan(−1/239)` with tangent `−1/239`. -/
def L239n : TanReal :=
  { angle := Rarctan (⟨-1, 239⟩ : Q) (by decide) (by decide) (by decide) (by decide)
      (show Qle (Qabs (⟨-1, 239⟩ : Q)) (⟨1, 18⟩ : Q) by decide)
    tan := ⟨-1, 239⟩
    htd := by decide
    hrel := Rsin_arctan_value_eq (⟨-1, 239⟩ : Q) (⟨1, 18⟩ : Q) (by decide) (by decide) (by decide)
      (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) }

-- ===========================================================================
-- The 25-leaf Gauss chain: 12×(1/18) + 8×(1/57) + 5×(−1/239). Running tangent → 1.
-- ===========================================================================

private def s0 : TanReal := L18
private def s1 : TanReal := (s0).step L18 (by decide) ⟨36, 323⟩ (by decide) (by decide)
private def s2 : TanReal := (s1).step L18 (by decide) ⟨971, 5778⟩ (by decide) (by decide)
private def s3 : TanReal := (s2).step L18 (by decide) ⟨23256, 103033⟩ (by decide) (by decide)
private def s4 : TanReal := (s3).step L18 (by decide) ⟨521641, 1831338⟩ (by decide) (by decide)
private def s5 : TanReal := (s4).step L18 (by decide) ⟨11220876, 32442443⟩ (by decide) (by decide)
private def s6 : TanReal := (s5).step L18 (by decide) ⟨234418211, 572743098⟩ (by decide) (by decide)
private def s7 : TanReal := (s6).step L18 (by decide) ⟨4792270896, 10074957553⟩ (by decide) (by decide)
private def s8 : TanReal := (s7).step L18 (by decide) ⟨96335833681, 176556965058⟩ (by decide) (by decide)
private def s9 : TanReal := (s8).step L18 (by decide) ⟨1910601971316, 3081689537363⟩ (by decide) (by decide)
private def s10 : TanReal := (s9).step L18 (by decide) ⟨37472525021051, 53559809701218⟩ (by decide) (by decide)
private def s11 : TanReal := (s10).step L18 (by decide) ⟨728065260080136, 926604049600873⟩ (by decide) (by decide)
private def s12 : TanReal := (s11).step L57 (by decide) ⟨339410590993349, 416706924537357⟩ (by decide) (by decide)
private def s13 : TanReal := (s12).step L57 (by decide) ⟨79052442444633, 93651536430544⟩ (by decide) (by decide)
private def s14 : TanReal := (s13).step L57 (by decide) ⟨36797126046197, 42072681072771⟩ (by decide) (by decide)
private def s15 : TanReal := (s14).step L57 (by decide) ⟨8558035462824, 9445382780407⟩ (by decide) (by decide)
private def s16 : TanReal := (s15).step L57 (by decide) ⟨3978027233291, 4238630264163⟩ (by decide) (by decide)
private def s17 : TanReal := (s16).step L57 (by decide) ⟨923944730247, 950495591296⟩ (by decide) (by decide)
private def s18 : TanReal := (s17).step L57 (by decide) ⟨428922761723, 426034431789⟩ (by decide) (by decide)
private def s19 : TanReal := (s18).step L57 (by decide) ⟨99498527400, 95420159401⟩ (by decide) (by decide)
private def s20 : TanReal := (s19).step L239n (by decide) ⟨829268159, 801964799⟩ (by decide) (by decide)
private def s21 : TanReal := (s20).step L239n (by decide) ⟨3455641, 3369960⟩ (by decide) (by decide)
private def s22 : TanReal := (s21).step L239n (by decide) ⟨28799, 28321⟩ (by decide) (by decide)
private def s23 : TanReal := (s22).step L239n (by decide) ⟨120, 119⟩ (by decide) (by decide)
private def s24 : TanReal := (s23).step L239n (by decide) ⟨1, 1⟩ (by decide) (by decide)

/-- **`π/4`** as a tangent-carrying real: the Gauss combination, tangent exactly `1`. -/
def Spi4 : TanReal := s24

/-- **`tan(π/4) = 1`** at the value level: `sin(π/4) = cos(π/4)`. The tangent of `Spi4` is `⟨1,1⟩`,
    so its defining relation `sin = (ofQ 1)·cos` simplifies to `sin = cos`. -/
theorem sin_eq_cos_pi4 : Req (Rsin Spi4.angle) (Rcos Spi4.angle) :=
  Req_trans Spi4.hrel (Rone_mul_loc (Rcos Spi4.angle))

-- ===========================================================================
-- The right angle π/2 = π/4 + π/4, and its sine/cosine values.
-- ===========================================================================

/-- **`π/2`** = `π/4 + π/4`. -/
def Rpi_half : Real := Radd Spi4.angle Spi4.angle

/-- `Rmul zero x ≈ zero`. -/
private theorem Rzero_mul (x : Real) : Req (Rmul zero x) zero :=
  Req_trans (Rmul_comm zero x) (Rmul_zero x)

/-- **`cos(π/2) = 0`**: double-angle `cos(A+A) = (1 − 1·1)·cos A·cos A` (`Rcos_add_of_tan` with
    tangent `1`), and `1 − 1 = 0`. -/
theorem Rcos_pi_half : Req (Rcos Rpi_half) zero := by
  have hadd := Rcos_add_of_tan Spi4.htd Spi4.htd Spi4.hrel Spi4.hrel
  have hcoef : Req (Rsub one (Rmul (ofQ Spi4.tan Spi4.htd) (ofQ Spi4.tan Spi4.htd))) zero :=
    Req_trans (Rsub_congr (Req_refl one) (Rmul_one one)) (Radd_neg one)
  exact Req_trans hadd
    (Req_trans (Rmul_congr hcoef (Req_refl (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle))))
      (Rzero_mul (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle))))

/-- **`sin(π/2) = 1`**: double-angle `sin(A+A) = (1+1)·cos A·cos A = cos²A + cos²A`
    (`Rsin_add_of_tan`), then `cos²A = sin²A` (`tan = 1`) and Pythagoras `cos²A + sin²A = 1`. -/
theorem Rsin_pi_half : Req (Rsin Rpi_half) one := by
  have hadd := Rsin_add_of_tan Spi4.htd Spi4.htd Spi4.hrel Spi4.hrel
  -- the coefficient (ofQ 1 + ofQ 1) distributes: (1+1)·X ≈ X + X, X = cos²
  have hdist : Req (Rmul (Radd (ofQ Spi4.tan Spi4.htd) (ofQ Spi4.tan Spi4.htd))
        (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle)))
      (Radd (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle)) (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle))) :=
    Req_trans (Rmul_distrib_right (ofQ Spi4.tan Spi4.htd) (ofQ Spi4.tan Spi4.htd)
        (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle)))
      (Radd_congr (Rone_mul_loc (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle)))
        (Rone_mul_loc (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle))))
  -- X = cos² ≈ sin² (since sin = cos), so X + X ≈ cos² + sin² ≈ 1
  have hcs : Req (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle))
      (Rmul (Rsin Spi4.angle) (Rsin Spi4.angle)) :=
    Rmul_congr (Req_symm sin_eq_cos_pi4) (Req_symm sin_eq_cos_pi4)
  have hpyth := Rcos_sq_add_sin_sq Spi4.angle
  exact Req_trans hadd (Req_trans hdist
    (Req_trans (Radd_congr (Req_refl (Rmul (Rcos Spi4.angle) (Rcos Spi4.angle))) hcs) hpyth))

-- ===========================================================================
-- Complementary-angle formulas: sin(π/2 − x) = cos x, cos(π/2 − x) = sin x.
-- The bridge from the π/2 values to the reciprocal reduction arctan t = π/2 − arctan(1/t).
-- ===========================================================================

/-- **cos subtraction formula**: `cos(x − y) = cos x·cos y + sin x·sin y` (`Rcos_add` + parity). -/
theorem Rcos_sub (x y : Real) :
    Req (Rcos (Rsub x y)) (Radd (Rmul (Rcos x) (Rcos y)) (Rmul (Rsin x) (Rsin y))) := by
  refine Req_trans (Rcos_add x (Rneg y)) ?_
  refine Req_trans (Rsub_congr (Rmul_congr (Req_refl (Rcos x)) (Rcos_neg y))
    (Rmul_congr (Req_refl (Rsin x)) (Rsin_neg y))) ?_
  refine Req_trans (Rsub_congr (Req_refl (Rmul (Rcos x) (Rcos y)))
    (Rmul_neg_right (Rsin x) (Rsin y))) ?_
  exact Radd_congr (Req_refl (Rmul (Rcos x) (Rcos y))) (Rneg_neg (Rmul (Rsin x) (Rsin y)))

/-- **`sin(π/2 − x) = cos x`**: `sin(π/2)·cos x − cos(π/2)·sin x = 1·cos x − 0·sin x = cos x`. -/
theorem Rsin_pi_half_sub (x : Real) : Req (Rsin (Rsub Rpi_half x)) (Rcos x) := by
  refine Req_trans (Rsin_sub Rpi_half x) ?_
  refine Req_trans (Rsub_congr (Rmul_congr Rsin_pi_half (Req_refl (Rcos x)))
    (Rmul_congr Rcos_pi_half (Req_refl (Rsin x)))) ?_
  refine Req_trans (Rsub_congr (Rone_mul_loc (Rcos x)) (Rzero_mul (Rsin x))) ?_
  exact Rsub_zero (Rcos x)

/-- **`cos(π/2 − x) = sin x`**: `cos(π/2)·cos x + sin(π/2)·sin x = 0·cos x + 1·sin x = sin x`. -/
theorem Rcos_pi_half_sub (x : Real) : Req (Rcos (Rsub Rpi_half x)) (Rsin x) := by
  refine Req_trans (Rcos_sub Rpi_half x) ?_
  refine Req_trans (Radd_congr (Rmul_congr Rcos_pi_half (Req_refl (Rcos x)))
    (Rmul_congr Rsin_pi_half (Req_refl (Rsin x)))) ?_
  refine Req_trans (Radd_congr (Rzero_mul (Rcos x)) (Rone_mul_loc (Rsin x))) ?_
  exact Req_trans (Radd_comm zero (Rsin x)) (Radd_zero (Rsin x))

-- ===========================================================================
-- π = 2·(π/2): cos π = −1, sin π = 0, and the π-shift formulas (toward the left half-plane).
-- ===========================================================================

/-- **`π`** = `π/2 + π/2` (the constructive π, via the Gauss-based `Rpi_half`). -/
def Rpi_full : Real := Radd Rpi_half Rpi_half

/-- **`cos π = −1`**: double-angle `cos(A+A) = cos²A − sin²A = 0 − 1 = −1` (`A = π/2`). -/
theorem Rcos_pi : Req (Rcos Rpi_full) (Rneg one) := by
  refine Req_trans (Rcos_add Rpi_half Rpi_half) ?_
  refine Req_trans (Rsub_congr (Rmul_congr Rcos_pi_half Rcos_pi_half)
    (Rmul_congr Rsin_pi_half Rsin_pi_half)) ?_
  refine Req_trans (Rsub_congr (Rmul_zero zero) (Rmul_one one)) ?_
  exact Req_trans (Radd_comm zero (Rneg one)) (Radd_zero (Rneg one))

/-- **`sin π = 0`**: double-angle `sin(A+A) = cos A·sin A + sin A·cos A = 0 + 0 = 0` (`A = π/2`). -/
theorem Rsin_pi : Req (Rsin Rpi_full) zero := by
  refine Req_trans (Rsin_add Rpi_half Rpi_half) ?_
  refine Req_trans (Radd_congr (Rmul_congr Rcos_pi_half Rsin_pi_half)
    (Rmul_congr Rsin_pi_half Rcos_pi_half)) ?_
  refine Req_trans (Radd_congr (Rzero_mul one) (Rmul_zero one)) ?_
  exact Radd_zero zero

/-- **`sin(x + π) = −sin x`**: `sin x·cos π + cos x·sin π = −sin x + 0`. -/
theorem Rsin_add_pi (x : Real) : Req (Rsin (Radd x Rpi_full)) (Rneg (Rsin x)) := by
  refine Req_trans (Rsin_add x Rpi_full) ?_
  refine Req_trans (Radd_congr (Rmul_congr (Req_refl (Rcos x)) Rsin_pi)
    (Rmul_congr (Req_refl (Rsin x)) Rcos_pi)) ?_
  refine Req_trans (Radd_congr (Rmul_zero (Rcos x)) (Rmul_neg_right (Rsin x) one)) ?_
  refine Req_trans (Radd_comm zero (Rneg (Rmul (Rsin x) one))) ?_
  exact Req_trans (Radd_zero (Rneg (Rmul (Rsin x) one))) (Rneg_congr (Rmul_one (Rsin x)))

/-- **`cos(x + π) = −cos x`**: `cos x·cos π − sin x·sin π = −cos x − 0`. -/
theorem Rcos_add_pi (x : Real) : Req (Rcos (Radd x Rpi_full)) (Rneg (Rcos x)) := by
  refine Req_trans (Rcos_add x Rpi_full) ?_
  refine Req_trans (Rsub_congr (Rmul_congr (Req_refl (Rcos x)) Rcos_pi)
    (Rmul_congr (Req_refl (Rsin x)) Rsin_pi)) ?_
  refine Req_trans (Rsub_congr (Rmul_neg_right (Rcos x) one) (Rmul_zero (Rsin x))) ?_
  -- Rsub (Rneg (Rmul (Rcos x) one)) zero ≈ Rneg (Rcos x)
  refine Req_trans (Rsub_zero (Rneg (Rmul (Rcos x) one))) (Rneg_congr (Rmul_one (Rcos x)))

-- ===========================================================================
-- The reciprocal/complementary tangent: if A has tangent s, then π/2 − A has tangent 1/s.
-- This is the value-level engine of arctan t = π/2 − arctan(1/t) for large |t|.
-- ===========================================================================

/-- **★ complementary tangent**: if `A` has tangent `s` (`sin A = s·cos A`) and `t·s = 1`, then the
    complementary angle `π/2 − A` has tangent `t`: `sin(π/2 − A) = t·cos(π/2 − A)`. Via the
    complementary formulas (`sin(π/2−A) = cos A`, `cos(π/2−A) = sin A`) and `sin A = s·cos A`:
    `t·cos(π/2−A) = t·sin A = t·s·cos A = cos A = sin(π/2−A)`. This is the value-level form of the
    reciprocal reduction `arctan t = π/2 − arctan(1/t)` — it lets the small-argument value identity
    (`|s| < 1/16`) supply the tangent of a LARGE argument `t = 1/s` through the complementary angle. -/
theorem Rsin_cos_pi_half_sub_tan (A : Real) {s t : Q} (hsd : 0 < s.den) (htd : 0 < t.den)
    (hval : Req (Rsin A) (Rmul (ofQ s hsd) (Rcos A))) (hts : Qeq (mul t s) (⟨1, 1⟩ : Q)) :
    Req (Rsin (Rsub Rpi_half A)) (Rmul (ofQ t htd) (Rcos (Rsub Rpi_half A))) := by
  have hone : Req (Rmul (ofQ t htd) (ofQ s hsd)) one :=
    Req_trans (Rmul_ofQ_ofQ htd hsd)
      (ofQ_congr (Qmul_den_pos htd hsd) (by decide : 0 < (⟨1, 1⟩ : Q).den) hts)
  refine Req_trans (Rsin_pi_half_sub A) (Req_symm ?_)
  -- t·cos(π/2−A) = t·sin A = t·(s·cos A) = (t·s)·cos A = 1·cos A = cos A
  refine Req_trans (Rmul_congr (Req_refl (ofQ t htd)) (Rcos_pi_half_sub A)) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ t htd)) hval) ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ t htd) (ofQ s hsd) (Rcos A))) ?_
  exact Req_trans (Rmul_congr hone (Req_refl (Rcos A))) (Rone_mul_loc (Rcos A))

/-- **★ complementary tangent, REAL tangents**: if `A` has tangent `s` (`sin A = s·cos A`, `s` a real)
    and `t·s = 1` (real reciprocal), then `π/2 − A` has tangent `t`. The real-tangent analogue of
    `Rsin_cos_pi_half_sub_tan`, for use with the real-argument value identity `RarctanR_value_eq`
    (where the tangent is a genuine real ratio `Re/Im`). Same proof: complementary formulas + `t·s = 1`. -/
theorem Rsin_cos_pi_half_sub_tan_real (A s t : Real)
    (hval : Req (Rsin A) (Rmul s (Rcos A))) (hts : Req (Rmul t s) one) :
    Req (Rsin (Rsub Rpi_half A)) (Rmul t (Rcos (Rsub Rpi_half A))) := by
  refine Req_trans (Rsin_pi_half_sub A) (Req_symm ?_)
  refine Req_trans (Rmul_congr (Req_refl t) (Rcos_pi_half_sub A)) ?_
  refine Req_trans (Rmul_congr (Req_refl t) hval) ?_
  refine Req_trans (Req_symm (Rmul_assoc t s (Rcos A))) ?_
  exact Req_trans (Rmul_congr hts (Req_refl (Rcos A))) (Rone_mul_loc (Rcos A))

/-- **The complementary tangent-carrying angle**: from `x` (tangent `s`), `π/2 − x.angle` carries the
    reciprocal tangent `t = 1/s` (`Rsin_cos_pi_half_sub_tan`). This makes the reciprocal reduction
    `arctan t = π/2 − arctan(1/t)` a first-class operation: a small-argument leaf (tangent `s = 1/t`,
    `|s| < 1/16`) yields a LARGE-tangent angle, and the result composes with `.add`/`.step` like any
    other `TanReal`. So tangents beyond the value-identity radius are now constructible. -/
def TanReal.compl (x : TanReal) (t : Q) (htd : 0 < t.den) (hts : Qeq (mul t x.tan) (⟨1, 1⟩ : Q)) :
    TanReal :=
  { angle := Rsub Rpi_half x.angle
    tan := t
    htd := htd
    hrel := Rsin_cos_pi_half_sub_tan x.angle x.htd htd x.hrel hts }

/-- **A concrete reciprocal reduction**: the large angle `π/2 − arctan(1/18)` carries tangent `18`
    (`tan(π/2 − arctan(1/18)) = 18`) — a tangent far outside the value-identity radius `1/16`, reached
    through the complementary angle. The witness that `TanReal.compl` delivers genuine large tangents. -/
theorem tan_pi_half_sub_arctan_eighteen :
    Req (Rsin (Rsub Rpi_half L18.angle))
      (Rmul (ofQ (⟨18, 1⟩ : Q) (by decide)) (Rcos (Rsub Rpi_half L18.angle))) :=
  (L18.compl (⟨18, 1⟩ : Q) (by decide) (by decide)).hrel

end UOR.Bridge.F1Square.Analysis
