/-
F1 square — the first analysis brick: exact rationals ℚ, built the UOR way (Thrust C).

Per the standing directive, the analytic substrate is built from first principles on the UOR
pattern (canonical form + exact arithmetic + realization), NOT imported from Mathlib. This is brick
one: exact rationals from ℤ, whose **canonical form is reduce-to-lowest-terms** — ℚ's content-address
(the uor-addr κ, one level down): two fractions mean the same number iff they share a canonical form.
Pure Lean 4, no Mathlib, no `sorry`.

Scope (honest): the TYPE, the OPERATIONS, the canonical form, and DECIDABLE exact equality/order are
built and verified; these already give exact cycle-means and exact signature comparisons. The
*general* field axioms and general idempotence of `reduce` need a commutative-ring normalizer for ℤ
(there is no `ring` tactic without Mathlib) — that normalizer is itself a UOR-consistent analysis
tool and is the first task of the v0.3.0 analysis work. Here the laws are verified concretely.

Roadmap (one brick per release): ℚ (here) → constructive ℝ (Cauchy-with-modulus / intervals) → ℂ +
transcendentals (exp/log/cos via convergent series with rigorous error bounds) → ζ and λₙ as
exact-bounded objects. Each brick makes more of the analytic half statable and checkable — never the
crux (proving `λₙ ≥ 0 ∀n` / the Hodge index on 𝕊 is RH).
-/

import F1Square.Analysis.RingNF

namespace UOR.Bridge.F1Square.Analysis

/-- A rational as a raw fraction `num / den` (denominator intended `> 0`). -/
structure Q where
  num : Int
  den : Nat
deriving DecidableEq, Repr

/-- Cross-multiplication equality: `a/b = c/d ⟺ a·d = c·b`. -/
def Qeq (a b : Q) : Prop := a.num * (b.den : Int) = b.num * (a.den : Int)

instance (a b : Q) : Decidable (Qeq a b) := by unfold Qeq; infer_instance

/-- Order: `a/b ≤ c/d ⟺ a·d ≤ c·b` (for positive denominators). -/
def Qle (a b : Q) : Prop := a.num * (b.den : Int) ≤ b.num * (a.den : Int)

instance (a b : Q) : Decidable (Qle a b) := by unfold Qle; infer_instance

/-- Strict order on ℚ: `a < b ⟺ a·d_b < b·d_a` (for positive denominators). -/
def Qlt (a b : Q) : Prop := a.num * (b.den : Int) < b.num * (a.den : Int)

instance (a b : Q) : Decidable (Qlt a b) := by unfold Qlt; infer_instance

/-- Addition `a/b + c/d = (ad + cb)/(bd)`. -/
def add (a b : Q) : Q := ⟨a.num * (b.den : Int) + b.num * (a.den : Int), a.den * b.den⟩

/-- Multiplication `a/b · c/d = (ac)/(bd)`. -/
def mul (a b : Q) : Q := ⟨a.num * b.num, a.den * b.den⟩

/-- Negation. -/
def neg (a : Q) : Q := ⟨-a.num, a.den⟩

/-- Subtraction on ℚ: `a − b := a + (−b)`. -/
def Qsub (a b : Q) : Q := add a (neg b)

/-- Absolute value on ℚ: keep the denominator, take `|numerator|`. -/
def Qabs (a : Q) : Q := ⟨(a.num.natAbs : Int), a.den⟩

/-- Addition keeps the denominator positive. -/
theorem add_den_pos {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) : 0 < (add a b).den :=
  Nat.mul_pos ha hb

/-- Negation preserves the denominator. -/
theorem neg_den_pos {a : Q} (ha : 0 < a.den) : 0 < (neg a).den := ha

/-- Subtraction keeps the denominator positive. -/
theorem Qsub_den_pos {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) : 0 < (Qsub a b).den :=
  add_den_pos ha (neg_den_pos hb)

/-- Absolute value preserves the denominator. -/
theorem Qabs_den_pos {a : Q} (ha : 0 < a.den) : 0 < (Qabs a).den := ha

/-- Multiplication keeps the denominator positive. -/
theorem Qmul_den_pos {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) : 0 < (mul a b).den :=
  Nat.mul_pos ha hb

/-- An absolute value has a non-negative numerator. -/
theorem Qabs_num_nonneg (a : Q) : 0 ≤ (Qabs a).num := Int.ofNat_nonneg _

/-- The canonical form: reduce to lowest terms via `gcd` — ℚ's content-address. -/
def reduce (a : Q) : Q :=
  let g : Nat := Nat.gcd a.num.natAbs a.den
  if g = 0 then ⟨0, 1⟩ else ⟨a.num / (g : Int), a.den / g⟩

-- General, reachable without a ring normalizer:

/-- `Qeq` is reflexive. -/
theorem Qeq_refl (a : Q) : Qeq a a := rfl

/-- `Qeq` is symmetric. -/
theorem Qeq_symm {a b : Q} (h : Qeq a b) : Qeq b a := h.symm

-- Concrete verification of the canonical form (= content-address) and the operations:

/-- `6/8` reduces to its canonical form `3/4`. -/
theorem reduce_6_8 : reduce ⟨6, 8⟩ = ⟨3, 4⟩ := by decide

/-- The canonical form is IDEMPOTENT — the ℚ analogue of the κ-idempotence (R2). -/
theorem reduce_idem : reduce (reduce ⟨6, 8⟩) = reduce ⟨6, 8⟩ := by decide
theorem reduce_idem_neg : reduce (reduce ⟨-12, 18⟩) = reduce ⟨-12, 18⟩ := by decide

/-- Reduction preserves the value (`Qeq`). -/
theorem reduce_preserves_value : Qeq (reduce ⟨6, 8⟩) ⟨6, 8⟩ := by decide

/-- Same meaning ⟺ same canonical address (the content-address property), on a sample. -/
theorem same_address_iff_eq :
    (reduce ⟨2, 4⟩ = reduce ⟨3, 6⟩) ∧ Qeq ⟨2, 4⟩ ⟨3, 6⟩ := by decide

/-- `1/2 + 1/3 = 5/6` (exact). -/
theorem add_sample : reduce (add ⟨1, 2⟩ ⟨1, 3⟩) = ⟨5, 6⟩ := by decide

/-- `2/3 · 3/4 = 1/2` (exact). -/
theorem mul_sample : reduce (mul ⟨2, 3⟩ ⟨3, 4⟩) = ⟨1, 2⟩ := by decide

/-- Exact order: `1/3 ≤ 1/2`. -/
theorem Qle_sample : Qle ⟨1, 3⟩ ⟨1, 2⟩ := by decide

-- ===========================================================================
-- v0.3.0 — GENERAL ℚ field laws, no longer only concrete samples. Each is a polynomial identity in
-- the numerators and (cast) denominators, discharged by the v0.3.0 ℤ ring normalizer
-- (`RingNF.nf_eq`): unfold `Qeq`/`add`/`mul`, push the `Nat→Int` casts to the leaves, then reflect.
-- This is the no-`ring` ceiling lifting: the laws hold for ALL rationals, not just the v0.2.0 numerals.
-- ===========================================================================

/-- Commutativity of `+` on ℚ (value-level), for ALL rationals. -/
theorem add_comm (a b : Q) : Qeq (add a b) (add b a) := by
  unfold Qeq add; simp only [Int.natCast_mul]
  have h := RingNF.nf_eq (ρ := RingNF.env [a.num, b.num, (a.den : Int), (b.den : Int)])
    (a := .mul (.add (.mul (.var 0) (.var 3)) (.mul (.var 1) (.var 2))) (.mul (.var 3) (.var 2)))
    (b := .mul (.add (.mul (.var 1) (.var 2)) (.mul (.var 0) (.var 3))) (.mul (.var 2) (.var 3)))
    (by decide)
  simpa [RingNF.denote, RingNF.env] using h

/-- Commutativity of `·` on ℚ (value-level), for ALL rationals. -/
theorem mul_comm (a b : Q) : Qeq (mul a b) (mul b a) := by
  unfold Qeq mul; simp only [Int.natCast_mul]
  have h := RingNF.nf_eq (ρ := RingNF.env [a.num, b.num, (a.den : Int), (b.den : Int)])
    (a := .mul (.mul (.var 0) (.var 1)) (.mul (.var 3) (.var 2)))
    (b := .mul (.mul (.var 1) (.var 0)) (.mul (.var 2) (.var 3)))
    (by decide)
  simpa [RingNF.denote, RingNF.env] using h

/-- Associativity of `·` on ℚ (value-level), for ALL rationals. -/
theorem mul_assoc (a b c : Q) : Qeq (mul (mul a b) c) (mul a (mul b c)) := by
  unfold Qeq mul; simp only [Int.natCast_mul]
  have h := RingNF.nf_eq
    (ρ := RingNF.env [a.num, b.num, c.num, (a.den : Int), (b.den : Int), (c.den : Int)])
    (a := .mul (.mul (.mul (.var 0) (.var 1)) (.var 2)) (.mul (.var 3) (.mul (.var 4) (.var 5))))
    (b := .mul (.mul (.var 0) (.mul (.var 1) (.var 2))) (.mul (.mul (.var 3) (.var 4)) (.var 5)))
    (by decide)
  simpa [RingNF.denote, RingNF.env] using h

/-- Associativity of `+` on ℚ (value-level), for ALL rationals. -/
theorem add_assoc (a b c : Q) : Qeq (add (add a b) c) (add a (add b c)) := by
  unfold Qeq add; simp only [Int.natCast_mul]
  have h := RingNF.nf_eq
    (ρ := RingNF.env [a.num, b.num, c.num, (a.den : Int), (b.den : Int), (c.den : Int)])
    (a := .mul (.add (.mul (.add (.mul (.var 0) (.var 4)) (.mul (.var 1) (.var 3))) (.var 5))
            (.mul (.var 2) (.mul (.var 3) (.var 4)))) (.mul (.var 3) (.mul (.var 4) (.var 5))))
    (b := .mul (.add (.mul (.var 0) (.mul (.var 4) (.var 5)))
            (.mul (.add (.mul (.var 1) (.var 5)) (.mul (.var 2) (.var 4))) (.var 3)))
          (.mul (.mul (.var 3) (.var 4)) (.var 5)))
    (by decide)
  simpa [RingNF.denote, RingNF.env] using h

/-- Left distributivity `a·(b+c) = a·b + a·c` on ℚ (value-level), for ALL rationals. -/
theorem mul_add (a b c : Q) : Qeq (mul a (add b c)) (add (mul a b) (mul a c)) := by
  unfold Qeq mul add; simp only [Int.natCast_mul]
  have h := RingNF.nf_eq
    (ρ := RingNF.env [a.num, b.num, c.num, (a.den : Int), (b.den : Int), (c.den : Int)])
    (a := .mul (.mul (.var 0) (.add (.mul (.var 1) (.var 5)) (.mul (.var 2) (.var 4))))
          (.mul (.mul (.var 3) (.var 4)) (.mul (.var 3) (.var 5))))
    (b := .mul (.add (.mul (.mul (.var 0) (.var 1)) (.mul (.var 3) (.var 5)))
            (.mul (.mul (.var 0) (.var 2)) (.mul (.var 3) (.var 4))))
          (.mul (.var 3) (.mul (.var 4) (.var 5))))
    (by decide)
  simpa [RingNF.denote, RingNF.env] using h

/-- `a · 1 = a` on ℚ (value-level). -/
theorem mul_one (a : Q) : Qeq (mul a ⟨1, 1⟩) a := by
  unfold Qeq mul; simp

/-- `a + 0 = a` on ℚ (value-level). -/
theorem add_zero (a : Q) : Qeq (add a ⟨0, 1⟩) a := by
  unfold Qeq add; simp

/-- `a + (−a) = 0` on ℚ (value-level), for ALL rationals: the additive inverse law. -/
theorem add_neg (a : Q) : Qeq (add a (neg a)) ⟨0, 1⟩ := by
  unfold Qeq add neg; simp; omega

end UOR.Bridge.F1Square.Analysis
