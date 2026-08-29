/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Multiplicity.SpectralAttractor.Tags
import Multiplicity.SpectralAttractor.Basic

/-!
# Certified ordinate intervals

Appendix-A certificates locked at scale `certScale = 10^10`.  Each ordinate
γₙ is certified by a half-open integer interval of width exactly one ulp of
the certificate grid: `[lo, lo + 1)` in units of `1 / certScale`.

Everything downstream consumes only the consequences proved here from the
locked table alone:

* positivity and boundedness of every endpoint,
* mutual disjointness of certificates of distinct modes,
* a kernel-checked lower bound for every envelope exponent.

The claim "the true ordinate lies in its interval" is *provenance data*
(the Appendix-A certification protocol), not a Lean proposition; this module
formalizes all order-theoretic content that downstream proofs may extract
from the intervals themselves.
-/

namespace ComplexKappa.SpectralAttractor

/-! ## Certificate structure -/

/-- A certified interval for one ordinate, in units of `1 / certScale`. -/
@[adr] structure OrdinateCert where
  /-- Inclusive lower endpoint (scaled by `certScale`). -/
  lo : Int
  /-- Exclusive upper endpoint (scaled by `certScale`). -/
  hi : Int
  /-- The interval is nondegenerate. -/
  lo_lt_hi : lo < hi

/-- The Appendix-A certificate attached to mode `n`: the half-open ulp
interval sitting directly on the locked table entry. -/
@[adr] def ordinateCert (n : ZeroMode) : OrdinateCert where
  lo := gammaScaled n
  hi := gammaScaled n + 1
  lo_lt_hi := by omega

@[proof] theorem ordinateCert_lo (n : ZeroMode) :
    (ordinateCert n).lo = gammaScaled n := rfl

@[proof] theorem ordinateCert_width (n : ZeroMode) :
    (ordinateCert n).hi - (ordinateCert n).lo = 1 := by
  have h1 : (ordinateCert n).hi = gammaScaled n + 1 := rfl
  have h2 : (ordinateCert n).lo = gammaScaled n := rfl
  rw [h1, h2]
  omega

/-! ## Positivity and boundedness of endpoints -/

/-- Every certificate's lower endpoint is positive. -/
@[proof] theorem ordinateCert_lo_pos (n : ZeroMode) :
    0 < (ordinateCert n).lo := gammaScaled_pos n

/-- Auxiliary: even the shifted upper endpoints stay under the table cap,
checked exactly per entry. -/
theorem vcap1_aux : ∀ v : Nat, v < 8 →
    gammaScaledV v + 1 < 44 * (10 ^ 10 : Int) := by
  intro v hv
  revert hv
  match v with
  | 0 => intro _; decide
  | 1 => intro _; decide
  | 2 => intro _; decide
  | 3 => intro _; decide
  | 4 => intro _; decide
  | 5 => intro _; decide
  | 6 => intro _; decide
  | 7 => intro _; decide
  | Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ _))))))) =>
    intro h; omega

/-- Every mode index satisfies the literal table bound. -/
theorem zeroMode_val_lt8 (n : ZeroMode) : n.val < 8 := n.isLt

/-- Every certificate's upper endpoint is bounded by the global table cap
`44 · certScale`. -/
@[proof] theorem ordinateCert_hi_bound (n : ZeroMode) :
    (ordinateCert n).hi < 44 * (10 ^ 10 : Int) := by
  have h1 : (ordinateCert n).hi = gammaScaled n + 1 := rfl
  have h3 : gammaScaled n = gammaScaledV n.val := rfl
  rw [h1, h3]
  exact vcap1_aux n.val (zeroMode_val_lt8 n)

/-! ## Mutual separation -/

/-- Certificates attached to distinct modes are disjoint — the upper
endpoint of the earlier mode's half-open ulp interval does not reach the
lower endpoint of the later one. -/
@[proof] theorem ordinateCert_disjoint (n m : ZeroMode) (hnm : n.val < m.val) :
    (ordinateCert n).hi ≤ (ordinateCert m).lo := by
  show gammaScaled n + 1 ≤ gammaScaled m
  exact gammaScaled_strictMono hnm

/-! ## Envelope-exponent bounds -/

/-- Auxiliary: the bound evaluated exactly on each locked table entry.
The guard uses the literal `8` so that the impossible catch-all branch is
visible to `omega` even across module boundaries. -/
theorem wexp_lb_aux : ∀ v : Nat, v < 8 →
    -(sigmaNum * 44 * 44 * (certScale : Int) * (certScale : Int)) /
      (sigmaDen : Int) ≤ weightExpScaledV (gammaScaledV v) := by
  intro v hv
  revert hv
  match v with
  | 0 => intro _; decide
  | 1 => intro _; decide
  | 2 => intro _; decide
  | 3 => intro _; decide
  | 4 => intro _; decide
  | 5 => intro _; decide
  | 6 => intro _; decide
  | 7 => intro _; decide
  | Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ _))))))) =>
    intro h; omega

/-- Kernel-checked uniform lower bound for the envelope exponent across all
modes: `w(γ) = -(σ γ²)/1000 ≥ -(44² · certScale² / 1000)`, evaluated
exactly on each locked table entry. -/
@[proof] theorem weightExpScaled_lower_bound (n : ZeroMode) :
    -(sigmaNum * 44 * 44 * (certScale : Int) * (certScale : Int)) /
      (sigmaDen : Int) ≤ weightExpScaled n :=
  wexp_lb_aux n.val n.isLt

/-- The exponent bound as a single conjunction, mirroring how it is consumed
by the contraction estimates. -/
@[proof] theorem weightExpScaled_bounds (n : ZeroMode) :
    weightExpScaled n < 0 ∧
      -(sigmaNum * 44 * 44 * (certScale : Int) * (certScale : Int)) /
        (sigmaDen : Int) ≤ weightExpScaled n :=
  ⟨weightExpScaled_neg n, weightExpScaled_lower_bound n⟩

end ComplexKappa.SpectralAttractor
