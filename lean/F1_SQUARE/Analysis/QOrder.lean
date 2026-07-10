/-
F1 square — ℚ as a verified ordered field (the v0.4.0 order library).

The constructive-ℝ arithmetic of `Analysis.Real` rests on ℚ being a genuine *ordered* field: the
order must be reflexive and transitive, addition must be monotone, and the absolute value must obey
the triangle inequality and respect value-equality. v0.3.0 gave ℚ its field laws (via the ring
normalizer); this brick gives ℚ its order laws, on the same exact `Q` (raw fractions with positive
denominators). These are the lemmas the real-number regularity proofs consume.

Everything is proved from the core ℤ order/`natAbs` lemmas (`Int.mul_le_mul_of_nonneg_right`,
`le_of_mul_le_mul_right`, `Int.natAbs_add_le`, `Int.natAbs_mul`, …) and the v0.3.0 ring normalizer
for the polynomial rearrangements — pure Lean 4, no Mathlib, no `sorry`. Order/equality on `Q` are
the cross-multiplication relations, which are correct precisely when denominators are positive; the
positivity hypotheses are threaded explicitly (and discharged automatically for everything the reals
construct, since every rational they build has a positive denominator).
-/

import F1Square.Analysis.Rat
import F1Square.Analysis.RingTac

namespace UOR.Bridge.F1Square.Analysis

/-- `≤` on ℚ is reflexive. -/
theorem Qle_refl (a : Q) : Qle a a := by unfold Qle; omega

/-- Value-equality implies `≤` (no positivity needed). -/
theorem Qeq_le {a b : Q} (h : Qeq a b) : Qle a b := by unfold Qeq Qle at *; omega

/-- Monotonicity of the bound fractions: a smaller numerator over a larger denominator is `≤`.
    `c ≤ d`, `0 ≤ c`, `j ≤ k`  ⟹  `c/(k+1) ≤ d/(j+1)`. This is the workhorse for collapsing a sum of
    regularity/equality bounds — whose indices all exceed a target `n` — down to a single `C/(n+1)`,
    the form the linear-bound criterion (and hence the ring laws) consumes. -/
theorem Qscale_le {c d : Int} {j k : Nat} (hcd : c ≤ d) (hc : 0 ≤ c) (hjk : j ≤ k) :
    Qle ⟨c, k + 1⟩ ⟨d, j + 1⟩ := by
  have hj : ((j + 1 : Nat) : Int) ≤ ((k + 1 : Nat) : Int) := by exact_mod_cast Nat.succ_le_succ hjk
  have h1 : c * ((j + 1 : Nat) : Int) ≤ c * ((k + 1 : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_left hj hc
  have h2 : c * ((k + 1 : Nat) : Int) ≤ d * ((k + 1 : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_right hcd (Int.ofNat_nonneg _)
  show c * ((j + 1 : Nat) : Int) ≤ d * ((k + 1 : Nat) : Int)
  omega

/-- `≤` on ℚ is transitive (needs the middle denominator positive). -/
theorem Qle_trans {a b c : Q} (hb : 0 < b.den)
    (hab : Qle a b) (hbc : Qle b c) : Qle a c := by
  have hb' : (0 : Int) < (b.den : Int) := by omega
  unfold Qle at *
  apply Int.le_of_mul_le_mul_right _ hb'
  have t1 : a.num * (b.den : Int) * (c.den : Int) ≤ b.num * (a.den : Int) * (c.den : Int) :=
    Int.mul_le_mul_of_nonneg_right hab (Int.ofNat_nonneg _)
  have t2 : b.num * (c.den : Int) * (a.den : Int) ≤ c.num * (b.den : Int) * (a.den : Int) :=
    Int.mul_le_mul_of_nonneg_right hbc (Int.ofNat_nonneg _)
  have e1 : a.num * (c.den : Int) * (b.den : Int) = a.num * (b.den : Int) * (c.den : Int) :=
    Int.mul_right_comm _ _ _
  have e2 : b.num * (a.den : Int) * (c.den : Int) = b.num * (c.den : Int) * (a.den : Int) :=
    Int.mul_right_comm _ _ _
  have e3 : c.num * (a.den : Int) * (b.den : Int) = c.num * (b.den : Int) * (a.den : Int) :=
    Int.mul_right_comm _ _ _
  omega

/-- `Qeq` is transitive (needs the middle denominator positive) — value-equality is an equivalence.
    The cross-multiplied identities are linear-combined (`ring_uor`) into a single `· * b.den`
    equation, then `b.den > 0` cancels it (via `Int.le_of_mul_le_mul_right` both ways). -/
theorem Qeq_trans {a b c : Q} (hb : 0 < b.den) (hab : Qeq a b) (hbc : Qeq b c) : Qeq a c := by
  have hb' : (0 : Int) < (b.den : Int) := by exact_mod_cast hb
  unfold Qeq at *
  have hz1 : a.num * (b.den : Int) - b.num * (a.den : Int) = 0 := by omega
  have hz2 : b.num * (c.den : Int) - c.num * (b.den : Int) = 0 := by omega
  have key : (a.num * (c.den : Int)) * (b.den : Int) - (c.num * (a.den : Int)) * (b.den : Int)
      = (c.den : Int) * (a.num * (b.den : Int) - b.num * (a.den : Int))
        + (a.den : Int) * (b.num * (c.den : Int) - c.num * (b.den : Int)) := by ring_uor
  rw [hz1, hz2] at key
  have e0 : (c.den : Int) * 0 + (a.den : Int) * 0 = 0 := by ring_uor
  rw [e0] at key
  have key2 : (a.num * (c.den : Int)) * (b.den : Int) = (c.num * (a.den : Int)) * (b.den : Int) := by
    omega
  have l1 := Int.le_of_mul_le_mul_right
    (show (a.num * (c.den : Int)) * (b.den : Int) ≤ (c.num * (a.den : Int)) * (b.den : Int) by omega)
    hb'
  have l2 := Int.le_of_mul_le_mul_right
    (show (c.num * (a.den : Int)) * (b.den : Int) ≤ (a.num * (c.den : Int)) * (b.den : Int) by omega)
    hb'
  omega

/-- Addition respects ℚ value-equality (a congruence): `a ≈ c → b ≈ d → a + b ≈ c + d`. The
    cross-multiplied difference is linear-combined (`ring_uor`) from the two hypotheses' vanishing
    cross-differences. -/
theorem Qadd_congr {a b c d : Q} (hac : Qeq a c) (hbd : Qeq b d) : Qeq (add a b) (add c d) := by
  unfold Qeq add at *
  simp only [Int.natCast_mul]
  have hP : a.num * (c.den : Int) - c.num * (a.den : Int) = 0 := by omega
  have hQ : b.num * (d.den : Int) - d.num * (b.den : Int) = 0 := by omega
  have key :
      (a.num * (b.den : Int) + b.num * (a.den : Int)) * ((c.den : Int) * (d.den : Int))
        - (c.num * (d.den : Int) + d.num * (c.den : Int)) * ((a.den : Int) * (b.den : Int))
      = (b.den : Int) * (d.den : Int) * (a.num * (c.den : Int) - c.num * (a.den : Int))
        + (a.den : Int) * (c.den : Int) * (b.num * (d.den : Int) - d.num * (b.den : Int)) := by
    ring_uor
  rw [hP, hQ] at key
  have e0 : (b.den : Int) * (d.den : Int) * 0 + (a.den : Int) * (c.den : Int) * 0 = 0 := by ring_uor
  rw [e0] at key
  omega

/-- Multiplication respects ℚ value-equality (a congruence): `a ≈ c → b ≈ d → a·b ≈ c·d`.
    (Multiply the two cross-multiplied hypotheses.) -/
theorem Qmul_congr {a b c d : Q} (hac : Qeq a c) (hbd : Qeq b d) : Qeq (mul a b) (mul c d) := by
  unfold Qeq mul at *
  simp only [Int.natCast_mul]
  have h : (a.num * (c.den : Int)) * (b.num * (d.den : Int))
      = (c.num * (a.den : Int)) * (d.num * (b.den : Int)) := by rw [hac, hbd]
  calc (a.num * b.num) * ((c.den : Int) * (d.den : Int))
      = (a.num * (c.den : Int)) * (b.num * (d.den : Int)) := by ring_uor
    _ = (c.num * (a.den : Int)) * (d.num * (b.den : Int)) := h
    _ = (c.num * d.num) * ((a.den : Int) * (b.den : Int)) := by ring_uor

/-- Right distributivity of ℚ multiplication over addition (value-level): `(a+b)·c ≈ a·c + b·c`. -/
theorem Qmul_add_right (a b c : Q) : Qeq (mul (add a b) c) (add (mul a c) (mul b c)) := by
  simp only [Qeq, mul, add]; push_cast; ring_uor

/-- `|·|` respects ℚ value-equality. -/
theorem Qabs_Qeq {a b : Q} (h : Qeq a b) : Qeq (Qabs a) (Qabs b) := by
  unfold Qeq Qabs at *
  have hn : (a.num * (b.den : Int)).natAbs = (b.num * (a.den : Int)).natAbs := by rw [h]
  rw [Int.natAbs_mul, Int.natAbs_mul, Int.natAbs_ofNat, Int.natAbs_ofNat] at hn
  rw [← Int.natCast_mul, ← Int.natCast_mul, hn]

/-- Transport `≤` along value-equality on the left (needs the replaced denominator positive). -/
theorem Qle_congr_left {a a' b : Q} (ha : 0 < a.den) (h : Qeq a a')
    (hab : Qle a b) : Qle a' b := by
  have ha' : (0 : Int) < (a.den : Int) := by omega
  unfold Qle Qeq at *
  apply Int.le_of_mul_le_mul_right _ ha'
  have t1 : a.num * (b.den : Int) * (a'.den : Int) ≤ b.num * (a.den : Int) * (a'.den : Int) :=
    Int.mul_le_mul_of_nonneg_right hab (Int.ofNat_nonneg _)
  have eL : a'.num * (b.den : Int) * (a.den : Int) = a.num * (b.den : Int) * (a'.den : Int) := by
    rw [Int.mul_right_comm a'.num, ← h, Int.mul_right_comm a.num]
  have eR : b.num * (a'.den : Int) * (a.den : Int) = b.num * (a.den : Int) * (a'.den : Int) :=
    Int.mul_right_comm _ _ _
  omega

/-- Transport `≤` along value-equality on the right (needs the replaced denominator positive). -/
theorem Qle_congr_right {a b b' : Q} (hb : 0 < b.den) (h : Qeq b b')
    (hab : Qle a b) : Qle a b' := by
  have hb' : (0 : Int) < (b.den : Int) := by omega
  unfold Qle Qeq at *
  apply Int.le_of_mul_le_mul_right _ hb'
  have t1 : a.num * (b.den : Int) * (b'.den : Int) ≤ b.num * (a.den : Int) * (b'.den : Int) :=
    Int.mul_le_mul_of_nonneg_right hab (Int.ofNat_nonneg _)
  have eL : a.num * (b'.den : Int) * (b.den : Int) = a.num * (b.den : Int) * (b'.den : Int) :=
    Int.mul_right_comm _ _ _
  have eR : b'.num * (a.den : Int) * (b.den : Int) = b.num * (a.den : Int) * (b'.den : Int) := by
    rw [Int.mul_right_comm b'.num, ← h, Int.mul_right_comm b.num]
  omega

-- The pure-ℤ kernel of additive monotonicity (rearrangements via the v0.3.0 ring normalizer).
private theorem add_mono_core (an bn cn dn ad bd cd dd : Int)
    (h1 : an * bd ≤ bn * ad) (h2 : cn * dd ≤ dn * cd)
    (had : 0 ≤ ad) (hbd : 0 ≤ bd) (hcd : 0 ≤ cd) (hdd : 0 ≤ dd) :
    (an * cd + cn * ad) * (bd * dd) ≤ (bn * dd + dn * bd) * (ad * cd) := by
  have t1 : (an * bd) * (cd * dd) ≤ (bn * ad) * (cd * dd) :=
    Int.mul_le_mul_of_nonneg_right h1 (Int.mul_nonneg hcd hdd)
  have t2 : (cn * dd) * (ad * bd) ≤ (dn * cd) * (ad * bd) :=
    Int.mul_le_mul_of_nonneg_right h2 (Int.mul_nonneg had hbd)
  have eL : (an * cd + cn * ad) * (bd * dd) = (an * bd) * (cd * dd) + (cn * dd) * (ad * bd) := by
    have h := RingNF.nf_eq (ρ := RingNF.env [an, bn, cn, dn, ad, bd, cd, dd])
      (a := .mul (.add (.mul (.var 0) (.var 6)) (.mul (.var 2) (.var 4))) (.mul (.var 5) (.var 7)))
      (b := .add (.mul (.mul (.var 0) (.var 5)) (.mul (.var 6) (.var 7)))
            (.mul (.mul (.var 2) (.var 7)) (.mul (.var 4) (.var 5))))
      (by decide)
    simpa [RingNF.denote, RingNF.env] using h
  have eR : (bn * dd + dn * bd) * (ad * cd) = (bn * ad) * (cd * dd) + (dn * cd) * (ad * bd) := by
    have h := RingNF.nf_eq (ρ := RingNF.env [an, bn, cn, dn, ad, bd, cd, dd])
      (a := .mul (.add (.mul (.var 1) (.var 7)) (.mul (.var 3) (.var 5))) (.mul (.var 4) (.var 6)))
      (b := .add (.mul (.mul (.var 1) (.var 4)) (.mul (.var 6) (.var 7)))
            (.mul (.mul (.var 3) (.var 6)) (.mul (.var 4) (.var 5))))
      (by decide)
    simpa [RingNF.denote, RingNF.env] using h
  rw [eL, eR]; exact Int.add_le_add t1 t2

/-- Addition on ℚ is monotone: `a ≤ b → c ≤ d → a + c ≤ b + d`. -/
theorem Qadd_le_add {a b c d : Q} (hab : Qle a b) (hcd : Qle c d) :
    Qle (add a c) (add b d) := by
  unfold Qle add at *
  simp only [Int.natCast_mul]
  exact add_mono_core a.num b.num c.num d.num a.den b.den c.den d.den
    hab hcd (Int.ofNat_nonneg _) (Int.ofNat_nonneg _) (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)

/-- The triangle inequality for sums on ℚ: `|a + b| ≤ |a| + |b|`. -/
theorem Qabs_add_le (a b : Q) : Qle (Qabs (add a b)) (add (Qabs a) (Qabs b)) := by
  unfold Qle Qabs add
  simp only [Int.natCast_mul]
  -- both sides share denominator ↑a.den * ↑b.den; reduce to the numerator inequality
  have key : ((a.num * (b.den : Int) + b.num * (a.den : Int)).natAbs : Int)
      ≤ ((a.num.natAbs : Int) * (b.den : Int) + (b.num.natAbs : Int) * (a.den : Int)) := by
    have e1 : (a.num.natAbs : Int) * (b.den : Int) = ((a.num * (b.den : Int)).natAbs : Int) := by
      rw [Int.natAbs_mul, Int.natAbs_ofNat, Int.natCast_mul]
    have e2 : (b.num.natAbs : Int) * (a.den : Int) = ((b.num * (a.den : Int)).natAbs : Int) := by
      rw [Int.natAbs_mul, Int.natAbs_ofNat, Int.natCast_mul]
    rw [e1, e2]
    have := Int.natAbs_add_le (a.num * (b.den : Int)) (b.num * (a.den : Int))
    omega
  have hD : (0 : Int) ≤ (a.den : Int) * (b.den : Int) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  exact Int.mul_le_mul_of_nonneg_right key hD

/-- The telescoping triangle inequality on ℚ: `|(a+b) − (c+d)| ≤ |a−c| + |b−d|`. This is exactly the
    bound the constructive-ℝ addition needs (split a difference of sums coordinatewise). -/
theorem Qabs_sub_add4 {a b c d : Q} (ha : 0 < a.den) (hb : 0 < b.den)
    (hc : 0 < c.den) (hd : 0 < d.den) :
    Qle (Qabs (Qsub (add a b) (add c d))) (add (Qabs (Qsub a c)) (Qabs (Qsub b d))) := by
  have htel : Qeq (Qsub (add a b) (add c d)) (add (Qsub a c) (Qsub b d)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have h2 := Qabs_add_le (Qsub a c) (Qsub b d)
  have hpos : 0 < (Qabs (add (Qsub a c) (Qsub b d))).den :=
    Qabs_den_pos (add_den_pos (Qsub_den_pos ha hc) (Qsub_den_pos hb hd))
  exact Qle_congr_left hpos (Qeq_symm (Qabs_Qeq htel)) h2

/-- ℚ order is total: `a ≤ b` or `b < a`. -/
theorem Qle_or_Qlt (a b : Q) : Qle a b ∨ Qlt b a := by unfold Qle Qlt; omega

/-- The 3-point triangle inequality on ℚ: `|a − c| ≤ |a − b| + |b − c|`. -/
theorem Qabs_sub_triangle {a b c : Q} (ha : 0 < a.den) (hb : 0 < b.den) (hc : 0 < c.den) :
    Qle (Qabs (Qsub a c)) (add (Qabs (Qsub a b)) (Qabs (Qsub b c))) := by
  have htel : Qeq (Qsub a c) (add (Qsub a b) (Qsub b c)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have h2 := Qabs_add_le (Qsub a b) (Qsub b c)
  have hpos : 0 < (Qabs (add (Qsub a b) (Qsub b c))).den :=
    Qabs_den_pos (add_den_pos (Qsub_den_pos ha hb) (Qsub_den_pos hb hc))
  exact Qle_congr_left hpos (Qeq_symm (Qabs_Qeq htel)) h2

-- The pure-ℤ contradiction kernel of the Archimedean lemma.
private theorem arch_core (N P : Int) (hN : 1 ≤ N) (hP : 1 ≤ P) :
    ¬ (N * (6 * P + 1) ≤ 6 * P) := by
  intro h
  have h1 : P ≤ N * P := by
    have := Int.mul_le_mul_of_nonneg_right hN (by omega : (0 : Int) ≤ P); simpa using this
  have h2 : N * (6 * P + 1) = 6 * (N * P) + N := by ring_uor
  omega

/-- **Archimedean lemma** on ℚ: if `p ≤ q + 6/(m+1)` for every `m`, then `p ≤ q`. The vanishing of
    the rational tail `6/(m+1)` (no `m` makes it negative) is what makes Bishop `≈` transitive. -/
theorem Qarch {p q : Q} (hp : 0 < p.den) (hq : 0 < q.den)
    (H : ∀ m : Nat, Qle p (add q ⟨6, m + 1⟩)) : Qle p q := by
  rcases Qle_or_Qlt p q with h | h
  · exact h
  · exfalso
    unfold Qlt at h
    have key := H (6 * (p.den * q.den))
    unfold Qle add at key
    push_cast at key h
    have hP1 : (1 : Int) ≤ (p.den : Int) * (q.den : Int) := by
      have h0 : 0 < p.den * q.den := Nat.mul_pos hp hq
      have h1 : (0 : Int) < ((p.den * q.den : Nat) : Int) := by exact_mod_cast h0
      push_cast at h1; omega
    have hN1 : (1 : Int) ≤ p.num * (q.den : Int) - q.num * (p.den : Int) := by omega
    have e1 : p.num * ((q.den : Int) * (6 * ((p.den : Int) * (q.den : Int)) + 1))
            = p.num * (q.den : Int) * (6 * ((p.den : Int) * (q.den : Int)) + 1) := by ring_uor
    have e2 : (q.num * (6 * ((p.den : Int) * (q.den : Int)) + 1) + 6 * (q.den : Int)) * (p.den : Int)
            = q.num * (p.den : Int) * (6 * ((p.den : Int) * (q.den : Int)) + 1)
              + 6 * ((p.den : Int) * (q.den : Int)) := by ring_uor
    have e3 : (p.num * (q.den : Int) - q.num * (p.den : Int))
                * (6 * ((p.den : Int) * (q.den : Int)) + 1)
            = p.num * (q.den : Int) * (6 * ((p.den : Int) * (q.den : Int)) + 1)
              - q.num * (p.den : Int) * (6 * ((p.den : Int) * (q.den : Int)) + 1) := by ring_uor
    have hbig : (p.num * (q.den : Int) - q.num * (p.den : Int))
                * (6 * ((p.den : Int) * (q.den : Int)) + 1)
              ≤ 6 * ((p.den : Int) * (q.den : Int)) := by omega
    exact arch_core _ _ hN1 hP1 hbig

-- The pure-ℤ contradiction kernel of the generalized Archimedean lemma (arbitrary coefficient `C`).
private theorem arch_core_gen (N P C : Int) (hN : 1 ≤ N) (hP : 1 ≤ P) (hC : 0 ≤ C) :
    ¬ (N * (C * P + 1) ≤ C * P) := by
  intro h
  have hNP : P ≤ N * P := by
    have := Int.mul_le_mul_of_nonneg_right hN (by omega : (0 : Int) ≤ P); simpa using this
  have h1 : C * P ≤ C * (N * P) := Int.mul_le_mul_of_nonneg_left hNP hC
  have h2 : N * (C * P + 1) = C * (N * P) + N := by ring_uor
  omega

/-- **Generalized Archimedean lemma** on ℚ: if `p ≤ q + C/(m+1)` for every `m` (any fixed coefficient
    `C : ℕ`), then `p ≤ q`. The vanishing of the rational tail `C/(m+1)` is what lets a *linear* bound
    `|xₙ − yₙ| ≤ C/(n+1)` (with any constant `C`) collapse to Bishop equality — the criterion the ℝ
    ring laws rest on. (`Qarch` is the `C = 6` instance.) -/
theorem Qarch_gen {p q : Q} {C : Nat} (hp : 0 < p.den) (hq : 0 < q.den)
    (H : ∀ m : Nat, Qle p (add q ⟨(C : Int), m + 1⟩)) : Qle p q := by
  rcases Qle_or_Qlt p q with h | h
  · exact h
  · exfalso
    unfold Qlt at h
    have key := H (C * (p.den * q.den))
    unfold Qle add at key
    push_cast at key h
    have hP1 : (1 : Int) ≤ (p.den : Int) * (q.den : Int) := by
      have h0 : 0 < p.den * q.den := Nat.mul_pos hp hq
      have h1 : (0 : Int) < ((p.den * q.den : Nat) : Int) := by exact_mod_cast h0
      push_cast at h1; omega
    have hN1 : (1 : Int) ≤ p.num * (q.den : Int) - q.num * (p.den : Int) := by omega
    have e1 : p.num * ((q.den : Int) * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1))
            = p.num * (q.den : Int) * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1) := by ring_uor
    have e2 : (q.num * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1) + (C : Int) * (q.den : Int))
                * (p.den : Int)
            = q.num * (p.den : Int) * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1)
              + (C : Int) * ((p.den : Int) * (q.den : Int)) := by ring_uor
    have e3 : (p.num * (q.den : Int) - q.num * (p.den : Int))
                * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1)
            = p.num * (q.den : Int) * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1)
              - q.num * (p.den : Int) * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1) := by ring_uor
    have hbig : (p.num * (q.den : Int) - q.num * (p.den : Int))
                * ((C : Int) * ((p.den : Int) * (q.den : Int)) + 1)
              ≤ (C : Int) * ((p.den : Int) * (q.den : Int)) := by omega
    exact arch_core_gen _ _ _ hN1 hP1 (Int.ofNat_nonneg _) hbig

-- ===========================================================================
-- v0.5.0 — ℚ multiplication and order (the lemmas ℝ multiplication consumes).
-- ===========================================================================

/-- `|a · b| = |a| · |b|` exactly, as rationals. -/
theorem Qabs_mul (a b : Q) : Qabs (mul a b) = mul (Qabs a) (Qabs b) := by
  simp only [Qabs, mul]
  congr 1
  rw [Int.natAbs_mul, Int.natCast_mul]

/-- Scaling on the left by a non-negative rational preserves `≤`. -/
theorem Qmul_le_mul_left {a b c : Q} (hc : 0 ≤ c.num) (hab : Qle a b) :
    Qle (mul c a) (mul c b) := by
  simp only [Qle, mul] at hab ⊢
  push_cast
  have hcc : 0 ≤ c.num * (c.den : Int) := Int.mul_nonneg hc (Int.ofNat_nonneg _)
  have e1 : c.num * a.num * ((c.den : Int) * (b.den : Int))
          = c.num * (c.den : Int) * (a.num * (b.den : Int)) := by ring_uor
  have e2 : c.num * b.num * ((c.den : Int) * (a.den : Int))
          = c.num * (c.den : Int) * (b.num * (a.den : Int)) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left hab hcc

/-- Scaling on the right by a non-negative rational preserves `≤`. -/
theorem Qmul_le_mul_right {a b c : Q} (hc : 0 ≤ c.num) (hab : Qle a b) :
    Qle (mul a c) (mul b c) := by
  simp only [Qle, mul] at hab ⊢
  push_cast
  have hcc : 0 ≤ c.num * (c.den : Int) := Int.mul_nonneg hc (Int.ofNat_nonneg _)
  have e1 : a.num * c.num * ((b.den : Int) * (c.den : Int))
          = c.num * (c.den : Int) * (a.num * (b.den : Int)) := by ring_uor
  have e2 : b.num * c.num * ((a.den : Int) * (c.den : Int))
          = c.num * (c.den : Int) * (b.num * (a.den : Int)) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left hab hcc

/-- Non-negative product monotonicity: `0 ≤ a, 0 ≤ c, a ≤ b, c ≤ d ⟹ a·c ≤ b·d`. -/
theorem Qmul_le_mul {a b c d : Q} (ha : 0 < a.den) (hb : 0 < b.den) (hc : 0 < c.den)
    (ha0 : 0 ≤ a.num) (hc0 : 0 ≤ c.num) (hab : Qle a b) (hcd : Qle c d) :
    Qle (mul a c) (mul b d) := by
  have hb0 : 0 ≤ b.num := by
    have hab' := hab; simp only [Qle] at hab'
    have h1 : (0 : Int) ≤ a.num * (b.den : Int) := Int.mul_nonneg ha0 (Int.ofNat_nonneg _)
    have h2 : (0 : Int) ≤ b.num * (a.den : Int) := by omega
    have h2' : 0 * (a.den : Int) ≤ b.num * (a.den : Int) := by simpa using h2
    exact Int.le_of_mul_le_mul_right h2' (by omega)
  exact Qle_trans (Qmul_den_pos hb hc) (Qmul_le_mul_right hc0 hab) (Qmul_le_mul_left hb0 hcd)

/-- The product-difference triangle: `|x_a y_a − x_b y_b| ≤ |x_a|·|y_a − y_b| + |y_b|·|x_a − x_b|`.
    This is the heart of ℝ multiplication's regularity. -/
theorem Qabs_mul_diff {xa ya xb yb : Q} (hxa : 0 < xa.den) (hya : 0 < ya.den)
    (hxb : 0 < xb.den) (hyb : 0 < yb.den) :
    Qle (Qabs (Qsub (mul xa ya) (mul xb yb)))
        (add (mul (Qabs xa) (Qabs (Qsub ya yb))) (mul (Qabs yb) (Qabs (Qsub xa xb)))) := by
  have htel : Qeq (Qsub (mul xa ya) (mul xb yb))
      (add (mul xa (Qsub ya yb)) (mul yb (Qsub xa xb))) := by
    simp only [Qeq, Qsub, add, mul, neg]; push_cast; ring_uor
  have h2 := Qabs_add_le (mul xa (Qsub ya yb)) (mul yb (Qsub xa xb))
  rw [Qabs_mul, Qabs_mul] at h2
  have hpos : 0 < (Qabs (add (mul xa (Qsub ya yb)) (mul yb (Qsub xa xb)))).den :=
    Qabs_den_pos (add_den_pos (Qmul_den_pos hxa (Qsub_den_pos hya hyb))
      (Qmul_den_pos hyb (Qsub_den_pos hxa hxb)))
  exact Qle_congr_left hpos (Qeq_symm (Qabs_Qeq htel)) h2

/-- `|b| ≤ |a| + |b − a|` — the bound used to derive a uniform `|xₙ| ≤ |x₀| + 2`. -/
theorem Qabs_le_add {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) :
    Qle (Qabs b) (add (Qabs a) (Qabs (Qsub b a))) := by
  have htel : Qeq b (add a (Qsub b a)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have h2 := Qabs_add_le a (Qsub b a)
  have hpos : 0 < (Qabs (add a (Qsub b a))).den :=
    Qabs_den_pos (add_den_pos ha (Qsub_den_pos hb ha))
  exact Qle_congr_left hpos (Qeq_symm (Qabs_Qeq htel)) h2

/-- Adding a non-negative rational increases (`≤`) the value. -/
theorem Qle_self_add {x p : Q} (hp : 0 ≤ p.num) : Qle x (add x p) := by
  unfold Qle add
  push_cast
  have key : (x.num * (p.den : Int) + p.num * (x.den : Int)) * (x.den : Int)
      = x.num * ((x.den : Int) * (p.den : Int)) + p.num * ((x.den : Int) * (x.den : Int)) := by ring_uor
  rw [key]
  have hnn : 0 ≤ p.num * ((x.den : Int) * (x.den : Int)) :=
    Int.mul_nonneg hp (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
  omega

/-- Adding a non-negative rational on the left increases (`≤`) the value. -/
theorem Qle_add_self {x p : Q} (hp : 0 ≤ p.num) : Qle x (add p x) := by
  unfold Qle add
  push_cast
  have key : (p.num * (x.den : Int) + x.num * (p.den : Int)) * (x.den : Int)
      = x.num * ((p.den : Int) * (x.den : Int)) + p.num * ((x.den : Int) * (x.den : Int)) := by ring_uor
  rw [key]
  have hnn : 0 ≤ p.num * ((x.den : Int) * (x.den : Int)) :=
    Int.mul_nonneg hp (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
  omega

end UOR.Bridge.F1Square.Analysis
