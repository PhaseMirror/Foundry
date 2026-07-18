/- ===========================================================================
   ADR-100: Conditional Proof Scaffold
   This is a research program. RH remains open. The F1-square with Hodge index
   is unconstructed. Numerical experiments and admitted bounds are exploratory
   and do not constitute proof or unconditional verification.
   ===========================================================================
   F1 square — the characteristic-1 (max-plus / tropical) base, as a UOR-style realization.

Companion `characteristic_1_constructions.md` R1–R12. Canonical form: the max-plus semiring
`ℝ_max = (ℝ∪{−∞}, max, +)`, here modelled in pure Lean 4 (no Mathlib) over `Option Int`
(`none = −∞`). Invariants proved — no `()`:
  • R1: tropical addition is idempotent (`x ⊕ x = x`) — the defining characteristic-1 trait;
  • the semiring shape: `⊕` commutative with identity `−∞`, `⊗` commutative with identity `0`,
    `−∞` absorbing for `⊗`;
  • R12: a cycle and its reversal have equal total weight and equal length — hence equal cycle
    mean, i.e. `spectrum(W) = spectrum(Wᵀ)` at the cycle level (the tropical functional equation).
Tropical intersection-positivity (R13) lives in `Mechanism.lean` (`tropMult_nonneg`).

Scope: the κ Kleene-star closure and the full κ⊥spectrum search (R9/R10) need a tropical
matrix-closure module; the trace-count side (R6) is mechanized exactly in `CycleCounts.lean`.
-/

namespace UOR.Bridge.F1Square.CharOne

/-- Characteristic-1 scalar: `Option Int` with `none = −∞`. -/
abbrev T : Type := Option Int

/-- Tropical addition `⊕ = max`; `−∞` (`none`) is the identity. -/
def tAdd : T → T → T
  | none,   y      => y
  | x,      none   => x
  | some a, some b => some (max a b)

/-- Tropical multiplication `⊗ = +`; `−∞` (`none`) is absorbing. -/
def tMul : T → T → T
  | none,   _      => none
  | _,      none   => none
  | some a, some b => some (a + b)

/-- **R1.** Tropical addition is idempotent — the defining trait of characteristic 1. -/
theorem tAdd_idem (x : T) : tAdd x x = x := by
  cases x with
  | none => rfl
  | some a => simp only [tAdd, Option.some.injEq]; omega

/-- `⊕` is commutative. -/
theorem tAdd_comm (x y : T) : tAdd x y = tAdd y x := by
  cases x with
  | none => cases y <;> rfl
  | some a => cases y with
    | none => rfl
    | some b => simp only [tAdd, Option.some.injEq]; omega

/-- `−∞` is a left identity for `⊕`. -/
theorem tAdd_none_left (x : T) : tAdd none x = x := by cases x <;> rfl

/-- `−∞` is a right identity for `⊕`. -/
theorem tAdd_none_right (x : T) : tAdd x none = x := by cases x <;> rfl

/-- `⊗` is commutative. -/
theorem tMul_comm (x y : T) : tMul x y = tMul y x := by
  cases x with
  | none => cases y <;> rfl
  | some a => cases y with
    | none => rfl
    | some b => simp only [tMul, Option.some.injEq]; omega

/-- `−∞` is left-absorbing for `⊗`. -/
theorem tMul_none_left (x : T) : tMul none x = none := by cases x <;> rfl

/-- `0` (the tropical multiplicative unit) is a left identity for `⊗`. -/
theorem tMul_one_left (x : T) : tMul (some 0) x = x := by
  cases x with
  | none => rfl
  | some a => simp only [tMul, Option.some.injEq]; omega

-- R12: the reversal symmetry, at the level of a single cycle's weight-list.

/-- A cycle, as the list of its edge-weights. -/
abbrev Cycle : Type := List Int

/-- Total weight of a cycle. -/
def csum : Cycle → Int
  | []      => 0
  | a :: t  => a + csum t

theorem csum_append (l1 l2 : Cycle) : csum (l1 ++ l2) = csum l1 + csum l2 := by
  induction l1 with
  | nil => simp [csum]
  | cons a t ih =>
      show a + csum (t ++ l2) = a + csum t + csum l2
      rw [ih]; omega

/-- The total weight is invariant under reversal. -/
theorem csum_reverse (l : Cycle) : csum l.reverse = csum l := by
  induction l with
  | nil => rfl
  | cons a t ih =>
      rw [List.reverse_cons, csum_append, ih]
      simp only [csum]; omega

/-- **R12 (reversal / functional equation).** A cycle and its reversal have the same total
    weight and the same length — hence the same cycle mean. So the cycle-mean spectrum is
    invariant under edge reversal: `spectrum(W) = spectrum(Wᵀ)`. -/
theorem cycle_reversal_invariant (l : Cycle) :
    csum l.reverse = csum l ∧ l.reverse.length = l.length :=
  ⟨csum_reverse l, List.length_reverse l⟩

end UOR.Bridge.F1Square.CharOne
