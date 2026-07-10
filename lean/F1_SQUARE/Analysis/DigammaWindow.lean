/-
F1 square — v0.19.0 (the genuine-pairing arc), brick W4: **the τ-parameterized archimedean
kernel `Re ψ(1/4 + iτ/2)` and its monotonicity** — the correct object the unconditional
window theorem is built from, and the honest record of what that theorem actually is.

THE HONEST FINDING (load-bearing — this brick exists to record it faithfully). Burnol's
window multiplier `α(τ) = 8√2·cos(τ·log 2)/(1+4τ²) + h₊(τ)`,
`h₊(τ) = −log π + Re ψ(1/4 + iτ/2)`, is NOT pointwise non-negative. At the window center
`α(0) ≈ 5.94 > 0` (`burnolAlphaZero_pos`), but the multiplier is INDEFINITE: near
`τ ≈ 2.27` (where `cos(τ·log 2)` first vanishes, so `α = h₊`) `α ≈ −1.0 < 0`; near
`τ ≈ 4.5` (`cos = −1`) `α ≈ −0.46 < 0`. The negative band (`α < 0` for `τ` roughly in
`[≈0.9, ≈6.4]`) is exactly why Burnol notes "a further idea seems necessary to reach
`c = √2`" and why Connes–Consani
(*Selecta Math.* 27 (2021)) need the Sonine-space projection: windowed Weil positivity is
recovered NOT by pointwise `α ≥ 0` but by adding a correction `A_ε·cos(ετ)` (which
integrates to `0` against the RESTRICTED test class) — the form-level / integral statement,
which needs certified integration (not yet built) or the infinite-dimensional Sonine
projection. So `α(τ) ≥ 0 ∀τ` is NOT a theorem; the unconditional window positivity stays
an honest interface, exactly as the bright line requires. `α(0) > 0` is the multiplier at
ONE point — evidence at the center, not the universal.

WHAT IS TRUE AND BUILT HERE. The kernel `Re ψ(1/4 + iτ/2)` has, like `ψ(1/4)`, EXACT-
RATIONAL terms (`τ²` is the only `τ`-dependence — the kernel is even in `τ`):
    `term_n(τ) = 1/(n+1) − (n+1/4)/((n+1/4)² + τ²/4)`,
and the genuine analytic content is MONOTONICITY: the positive part
`g_n(s) = (n+1/4)/((n+1/4)² + s)` is ANTITONE in `s = τ²/4` (its denominator grows), so each
`term_n` is MONOTONE INCREASING in `τ²`, hence `Re ψ(1/4 + iτ/2)` — and `h₊(τ)` — increase
monotonically in `τ ≥ 0` (climbing from `h₊(0) ≈ −5.37` toward `+∞`). This is the structural
reason the negative band is BOUNDED (the obstruction the restricted-class correction
removes), and it is the analytic heart of the kernel. At `τ = 0` the kernel term reduces
exactly to `ψ(1/4)`'s (`term_n(0) = −3/[(n+1)(4n+1)]`, `windowTerm_zero`).

Parameterized by `s = τ²/4` as a non-negative rational `sn/sd` (`sn sd : ℕ`, `sd > 0`).

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.Rat
import F1Square.Analysis.QOrder

namespace UOR.Bridge.F1Square.Analysis

/-- **The window kernel** `g_n(s) = (n+1/4)/((n+1/4)² + s)` at `s = sn/sd ≥ 0`, in reduced
    exact-rational form `(4n+1)·16·sd / (4·((4n+1)²·sd + 16·sn))`. -/
def windowKernel (n sn sd : Nat) : Q :=
  ⟨((4 * n + 1) * 16 * sd : Nat), 4 * ((4 * n + 1) * (4 * n + 1) * sd + 16 * sn)⟩

theorem windowKernel_den_pos {n sn sd : Nat} (hsd : 1 ≤ sd) : 0 < (windowKernel n sn sd).den := by
  show 0 < 4 * ((4 * n + 1) * (4 * n + 1) * sd + 16 * sn)
  have h1 : 0 < (4 * n + 1) * (4 * n + 1) := Nat.mul_pos (by omega) (by omega)
  have h2 : 0 < (4 * n + 1) * (4 * n + 1) * sd := Nat.mul_pos h1 hsd
  omega

/-- **The window kernel is ANTITONE in `s`**: for `0 ≤ s = sn/sd ≤ s' = sn'/sd'` (i.e.
    `sn·sd' ≤ sn'·sd`), `g_n(s') ≤ g_n(s)` — the denominator `(n+1/4)² + s` grows with `s`. -/
theorem windowKernel_antitone {n sn sd sn' sd' : Nat} (_hsd : 1 ≤ sd) (_hsd' : 1 ≤ sd')
    (hmono : sn * sd' ≤ sn' * sd) :
    Qle (windowKernel n sn' sd') (windowKernel n sn sd) := by
  show ((4 * n + 1) * 16 * sd' : Nat) * ((4 * ((4 * n + 1) * (4 * n + 1) * sd + 16 * sn) : Nat) : Int)
      ≤ (((4 * n + 1) * 16 * sd : Nat)) * ((4 * ((4 * n + 1) * (4 * n + 1) * sd' + 16 * sn') : Nat) : Int)
  push_cast
  have hkey :
      ((4 * (n:Int) + 1) * 16 * (sd':Int)) * (4 * ((4 * (n:Int) + 1) * (4 * (n:Int) + 1) * (sd:Int) + 16 * (sn:Int)))
        + 1024 * (4 * (n:Int) + 1) * ((sn':Int) * (sd:Int) - (sn:Int) * (sd':Int))
      = ((4 * (n:Int) + 1) * 16 * (sd:Int)) * (4 * ((4 * (n:Int) + 1) * (4 * (n:Int) + 1) * (sd':Int) + 16 * (sn':Int))) := by
    ring_uor
  have hX : (0:Int) ≤ (sn':Int) * (sd:Int) - (sn:Int) * (sd':Int) := by
    have : (sn:Int) * (sd':Int) ≤ (sn':Int) * (sd:Int) := by exact_mod_cast hmono
    omega
  have hc : (0:Int) ≤ 1024 * (4 * (n:Int) + 1) := Int.mul_nonneg (by decide) (by omega)
  have hadd : (0:Int) ≤ 1024 * (4 * (n:Int) + 1) * ((sn':Int) * (sd:Int) - (sn:Int) * (sd':Int)) :=
    Int.mul_nonneg hc hX
  omega

/-- **The window term** `term_n(s) = 1/(n+1) − g_n(s)` (`Re ψ`'s `n`-th summand at
    `s = τ²/4`). -/
def windowTerm (n sn sd : Nat) : Q := Qsub (⟨1, n + 1⟩ : Q) (windowKernel n sn sd)

/-- **The window term is MONOTONE INCREASING in `s`** (the kernel is antitone, subtracted):
    `0 ≤ s ≤ s' ⟹ term_n(s) ≤ term_n(s')`. So `Re ψ(1/4 + iτ/2)` and `h₊(τ)` increase in
    `τ ≥ 0` — the genuine analytic content (the negative band of `α` is therefore bounded). -/
theorem windowTerm_mono {n sn sd sn' sd' : Nat} (hsd : 1 ≤ sd) (hsd' : 1 ≤ sd')
    (hmono : sn * sd' ≤ sn' * sd) :
    Qle (windowTerm n sn sd) (windowTerm n sn' sd') := by
  -- 1/(n+1) − g(s) ≤ 1/(n+1) − g(s')  ⟺  g(s') ≤ g(s)
  have hanti := windowKernel_antitone (n := n) hsd hsd' hmono
  show Qle (Qsub (⟨1, n + 1⟩ : Q) (windowKernel n sn sd)) (Qsub (⟨1, n + 1⟩ : Q) (windowKernel n sn' sd'))
  -- Qsub a b = add a (neg b); subtract the common 1/(n+1), flip the kernel inequality
  have e : ∀ b : Q, Qsub (⟨1, n + 1⟩ : Q) b = add (⟨1, n + 1⟩ : Q) (neg b) := fun _ => rfl
  rw [e, e]
  refine Qadd_le_add (Qle_refl _) ?_
  -- neg (windowKernel n sn sd) ≤ neg (windowKernel n sn' sd')  ⟺  windowKernel n sn' sd' ≤ windowKernel n sn sd
  show ((neg (windowKernel n sn sd)).num) * ((neg (windowKernel n sn' sd')).den : Int)
      ≤ ((neg (windowKernel n sn' sd')).num) * ((neg (windowKernel n sn sd)).den : Int)
  have hanti' : (windowKernel n sn' sd').num * ((windowKernel n sn sd).den : Int)
      ≤ (windowKernel n sn sd).num * ((windowKernel n sn' sd').den : Int) := hanti
  show -(windowKernel n sn sd).num * ((windowKernel n sn' sd').den : Int)
      ≤ -(windowKernel n sn' sd').num * ((windowKernel n sn sd).den : Int)
  have e1 : -(windowKernel n sn sd).num * ((windowKernel n sn' sd').den : Int)
      = -((windowKernel n sn sd).num * ((windowKernel n sn' sd').den : Int)) := by ring_uor
  have e2 : -(windowKernel n sn' sd').num * ((windowKernel n sn sd).den : Int)
      = -((windowKernel n sn' sd').num * ((windowKernel n sn sd).den : Int)) := by ring_uor
  rw [e1, e2]; omega

/-- **Consistency at `τ = 0`**: `term_n(0) = 1/(n+1) − 1/(n+1/4) = −3/[(n+1)(4n+1)]` — the
    kernel family restricts at the center to exactly `ψ(1/4)`'s summand (`PsiQuarter.pqT`,
    negated). -/
theorem windowTerm_zero (n : Nat) :
    Qeq (windowTerm n 0 1) (neg (⟨3, (n + 1) * (4 * n + 1)⟩ : Q)) := by
  simp only [windowTerm, windowKernel, Qsub, Qeq, add, neg]
  push_cast
  ring_uor

end UOR.Bridge.F1Square.Analysis
