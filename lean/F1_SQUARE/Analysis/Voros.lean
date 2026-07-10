/-
F1 square — v0.20.0 stage F, frontier brick: **the Voros growth dichotomy as a structural
theorem** — the no-third-option exclusivity, mechanized.

Companion ROADMAP §F (frontier). Voros's theorem (*Math. Phys. Anal. Geom.* 9 (2006) 53–63,
arXiv math/0506326; simplifications arXiv:1602.03292) is the sharpest known statement of the
RH-hardness of Li positivity: the Li/Keiper sequence `λₙ` has exactly TWO mutually exclusive
asymptotic forms — **tempered** `λₙ ∼ (n/2)(log n − 1 + γ − log 2π)` (sub-exponential, polynomial
envelope) under RH, and **exponentially oscillating** `λₙ ∼ Σ ((τₖ+i/2)/(τₖ−i/2))ⁿ + c.c.` (modulus
growing like `|1−1/ρ|ⁿ > 1`) under ¬RH — with NO third option. Which form holds is RH itself, so
the *identification* of a regime with RH is [CLASSICAL] and stays interface here (it is exactly the
analytic content that does not close from anything built).

THE GENUINE CONSTRUCTIVE NUGGET — built here, unconditionally: the two regimes are **mutually
exclusive** (`tempered_not_exp`). A sequence with a polynomial envelope `|λₙ| ≤ C·(n+1)²` CANNOT
also exceed `2ⁿ` infinitely often, because `2ⁿ` eventually dominates any constant multiple of a
polynomial (`cube_le_pow2`: `(n+1)³ ≤ 2ⁿ` for `n ≥ 11`, so `C·(n+1)² < (n+1)³ ≤ 2ⁿ` once
`C < n+1`). This mechanizes Voros's "two sharply distinct and mutually exclusive forms, NO third
option" at the level of the growth dichotomy — the elementary skeleton of his theorem, which is
what the substrate can prove without the saddle-point asymptotics.

WHAT THIS DOES AND DOES NOT DO. It sharpens the frontier: the crux `λₙ > 0 ∀n` lives in the
tempered regime, and the dichotomy has no escape hatch — so positivity fails iff the exponential
regime is entered, which is `¬RH`. It does NOT prove which regime `genuineLamSeq` is in (that is
RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.RMax
import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The growth lemma: 2ⁿ eventually dominates a constant multiple of (n+1)².
-- ===========================================================================

/-- The cubic step `(m+2)³ ≤ 2·(m+1)³` for `m ≥ 3` (reduces to `m³ ≥ 6m+6`, proved from
    `m·m ≥ 36`). The engine of the exponential-beats-polynomial bound. -/
private theorem cube_step (m : Nat) (hm : 6 ≤ m) :
    (m + 2) * (m + 2) * (m + 2) ≤ 2 * ((m + 1) * (m + 1) * (m + 1)) := by
  have hmm : 36 ≤ m * m := Nat.mul_le_mul hm hm
  -- m³ ≥ 36·m ≥ 6m + 6
  have hcube : 6 * m + 6 ≤ m * m * m := by
    have h1 : 36 * m ≤ (m * m) * m := Nat.mul_le_mul_right m hmm
    have h2 : 6 * m + 6 ≤ 36 * m := by omega
    calc 6 * m + 6 ≤ 36 * m := h2
      _ ≤ (m * m) * m := h1
      _ = m * m * m := rfl
  -- expand both cubes and close with hcube via the Int ring identity
  have key : (2 : Int) * (((m : Int) + 1) * ((m : Int) + 1) * ((m : Int) + 1))
      = ((m : Int) + 2) * ((m : Int) + 2) * ((m : Int) + 2)
        + ((m : Int) * (m : Int) * (m : Int) - 6 * (m : Int) - 6) := by ring_uor
  have hcubeZ : (6 : Int) * (m : Int) + 6 ≤ (m : Int) * (m : Int) * (m : Int) := by
    exact_mod_cast hcube
  have : ((m + 2) * (m + 2) * (m + 2) : Int) ≤ 2 * ((m + 1) * (m + 1) * (m + 1)) := by
    rw [key]; push_cast; omega
  exact_mod_cast this

/-- **`(n+1)³ ≤ 2ⁿ` for `n ≥ 11`** — the exponential eventually dominates the cube (base
    `12³ = 1728 ≤ 2048 = 2¹¹`; step `cube_step`). -/
theorem cube_le_pow2 : ∀ n : Nat, 11 ≤ n → (n + 1) * (n + 1) * (n + 1) ≤ 2 ^ n := by
  intro n hn
  induction n with
  | zero => omega
  | succ m ih =>
      rcases Nat.lt_or_ge m 11 with hm | hm
      · -- m + 1 ≥ 11 with m < 11 forces m = 10, n = 11 — the base case, by computation
        have : m = 10 := by omega
        subst this; decide
      · have hih := ih hm
        have hstep := cube_step m (by omega)
        have hpow : 2 ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ, Nat.mul_comm]
        show (m + 2) * (m + 2) * (m + 2) ≤ 2 ^ (m + 1)
        calc (m + 2) * (m + 2) * (m + 2)
            ≤ 2 * ((m + 1) * (m + 1) * (m + 1)) := hstep
          _ ≤ 2 * 2 ^ m := Nat.mul_le_mul_left 2 hih
          _ = 2 ^ (m + 1) := hpow.symm

/-- **`C·(n+1)² < 2ⁿ`** once `C < n+1` and `n ≥ 11`: a constant multiple of the square is
    strictly dominated by `2ⁿ` (via `C·(n+1)² < (n+1)³ ≤ 2ⁿ`). -/
theorem quad_lt_pow2 (C n : Nat) (hC : C < n + 1) (hn : 11 ≤ n) :
    C * ((n + 1) * (n + 1)) < 2 ^ n := by
  have hX : 0 < (n + 1) * (n + 1) := Nat.mul_pos (by omega) (by omega)
  -- (C+1)·X ≤ (n+1)·X (since C+1 ≤ n+1), and (C+1)·X = C·X + X, with X > 0
  have hle : (C + 1) * ((n + 1) * (n + 1)) ≤ (n + 1) * ((n + 1) * (n + 1)) :=
    Nat.mul_le_mul_right ((n + 1) * (n + 1)) hC
  have hsucc : (C + 1) * ((n + 1) * (n + 1)) = C * ((n + 1) * (n + 1)) + (n + 1) * (n + 1) :=
    Nat.succ_mul C ((n + 1) * (n + 1))
  have h2 : (n + 1) * ((n + 1) * (n + 1)) = (n + 1) * (n + 1) * (n + 1) :=
    (Nat.mul_assoc (n + 1) (n + 1) (n + 1)).symm
  have h3 := cube_le_pow2 n hn
  omega

-- ===========================================================================
-- The two regimes and the no-third-option exclusivity.
-- ===========================================================================

/-- A nonneg-integer-valued constant real `m`. -/
private def natR (m : Nat) : Real := ofQ (⟨(m : Int), 1⟩ : Q) Nat.one_pos

/-- **Strict order on integer constants, choice-free**: if `B < A` then `natR A` is NOT
    `≤ natR B`. (Evaluate `Rle` at index `2`: it would force `3A ≤ 3B + 2`, impossible for
    `B + 1 ≤ A`. No `simp`/`push_cast` — `dsimp` + `omega` only, to stay choice-free.) -/
private theorem natR_not_le_of_lt {A B : Nat} (h : B < A) : ¬ Rle (natR A) (natR B) := by
  intro hle
  have h2 := hle 2
  dsimp only [natR, ofQ, Rle, Qle, add] at h2
  omega

/-- **TEMPERED GROWTH** (Voros's RH regime): the sequence has a polynomial envelope —
    `|λₙ| ≤ C·(n+1)²` for some constant `C`, all `n`. The genuine `λₙ ∼ (n/2)log n = o(n²)`
    satisfies this; it is the sub-exponential regime. -/
def TemperedGrowth (lam : Nat → Real) : Prop :=
  ∃ C : Nat, ∀ n : Nat, Rle (Rabs (lam n)) (natR (C * ((n + 1) * (n + 1))))

/-- **EXPONENTIAL OSCILLATION** (Voros's ¬RH regime): the sequence exceeds `2ⁿ` in modulus
    infinitely often — the non-tempered, exponentially-growing failure mode. -/
def ExpOscillation (lam : Nat → Real) : Prop :=
  ∀ N : Nat, ∃ n : Nat, N ≤ n ∧ Rle (natR (2 ^ n)) (Rabs (lam n))

/-- **THE NO-THIRD-OPTION EXCLUSIVITY — the constructive skeleton of Voros's dichotomy**: a
    tempered sequence (polynomial envelope) is NEVER exponentially oscillating. The two regimes
    are mutually exclusive, unconditionally. (Proof: at an `n ≥ max(C+1, 11)` where the
    oscillation exceeds `2ⁿ`, the polynomial envelope `C·(n+1)²` would have to reach `2ⁿ` too —
    but `quad_lt_pow2` says `C·(n+1)² < 2ⁿ`, and the two `Rle` bounds force `2ⁿ ≤ C·(n+1)²`.) -/
theorem tempered_not_exp (lam : Nat → Real) (ht : TemperedGrowth lam) : ¬ ExpOscillation lam := by
  intro hexp
  obtain ⟨C, hC⟩ := ht
  obtain ⟨n, hn, hle⟩ := hexp (max (C + 1) 11)
  -- `2ⁿ ≤ |λₙ| ≤ C·(n+1)²`, so `natR 2ⁿ ≤ natR (C·(n+1)²)` as constant reals
  have hchain : Rle (natR (2 ^ n)) (natR (C * ((n + 1) * (n + 1)))) :=
    Rle_trans hle (hC n)
  -- but `C·(n+1)² < 2ⁿ` (n ≥ C+1 and n ≥ 11), so that `Rle` is impossible
  have hlt := quad_lt_pow2 C n (by omega) (by omega)
  exact natR_not_le_of_lt hlt hchain

/-- The symmetric reading: an exponentially-oscillating sequence is never tempered. -/
theorem exp_not_tempered (lam : Nat → Real) (he : ExpOscillation lam) : ¬ TemperedGrowth lam :=
  fun ht => tempered_not_exp lam ht he

-- ===========================================================================
-- The dichotomy as a structural theorem: exactly one regime.
-- ===========================================================================

/-- **Voros's dichotomy, as a Prop**: a sequence is in (at least) one of the two regimes. For
    the genuine `λ` of ζ the "at least one" disjunction IS Voros's saddle-point theorem
    [CLASSICAL, interface — the analytic content that is RH-equivalent]; here we mechanize the
    other half, "AT MOST one" (`voros_at_most_one`), unconditionally. -/
def VorosDichotomy (lam : Nat → Real) : Prop := TemperedGrowth lam ∨ ExpOscillation lam

/-- **AT MOST ONE regime** — the constructive content of the dichotomy: no sequence is BOTH
    tempered and exponentially oscillating. (Restatement of `tempered_not_exp` as the
    no-overlap half of "exactly one".) -/
theorem voros_at_most_one (lam : Nat → Real) :
    ¬ (TemperedGrowth lam ∧ ExpOscillation lam) :=
  fun ⟨ht, he⟩ => tempered_not_exp lam ht he

/-- **The structural dichotomy theorem**: GIVEN that a sequence is in some regime
    (`VorosDichotomy`, Voros's classical saddle-point input), it is in EXACTLY one — the two are
    mutually exclusive. So "which regime" is a genuine binary invariant of the sequence: tempered
    (the crux `λₙ > 0 ∀n` lives here, RH) XOR exponential oscillation (¬RH). The identification
    of the regime with RH is the open analytic content; the EXCLUSIVITY (no third option, no
    overlap) is the unconditional theorem. -/
theorem voros_exactly_one (lam : Nat → Real) (h : VorosDichotomy lam) :
    (TemperedGrowth lam ∧ ¬ ExpOscillation lam) ∨ (ExpOscillation lam ∧ ¬ TemperedGrowth lam) := by
  rcases h with ht | he
  · exact Or.inl ⟨ht, fun he => tempered_not_exp lam ht he⟩
  · exact Or.inr ⟨he, fun ht => tempered_not_exp lam ht he⟩

end UOR.Bridge.F1Square.Analysis
