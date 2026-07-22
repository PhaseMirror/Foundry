/-
F1 square — the commutative-ring normalizer over ℤ: a reflective canonical form for polynomial
expressions (the v0.3.0 analysis tool).

There is no `ring` tactic without Mathlib, so the *general* algebraic identities the program needs
(the ℚ field laws, general signature/definiteness arguments, the binomial expansions behind exact
error bounds) could previously only be checked on concrete numerals. This brick removes that ceiling
the UOR way: it gives polynomial expressions over ℤ a **canonical form** — a sorted, merged list of
(monomial, coefficient) pairs — which is exactly their content-address (the uor-addr κ, one level up
from ℚ's reduce-to-lowest-terms): two expressions denote the same polynomial function iff they share
this canonical form. A single **soundness theorem** (`norm_sound`) certifies that normalization
preserves meaning, so any identity provable by "the canonical forms coincide" (`nf_eq`) is a genuine
ℤ theorem — proved by `decide` on the finite normal-form data, with NO `ring`, NO Mathlib, NO `sorry`.

This is a *reflective* tactic-in-data: `PExpr` is the syntax, `denote` the semantics, `norm` the
canonicaliser, and `norm_sound : pden ρ (norm e) = denote ρ e` the reflection lemma. It is itself a
UOR realization (canonical form + invariant + soundness), and it is the tool that unlocks the general
algebra used by the constructive-ℝ brick (`Analysis.Real`).

Pure Lean 4, no Mathlib, no `sorry`. Soundness is built from the core ℤ ring lemmas
(`Int.mul_assoc`, `Int.mul_comm`, `Int.add_mul`, `Int.neg_mul`, …) — never assumed. The monomial
order is our own `Bool`-valued lexicographic comparison `mlt` (core provides no `LT (List Nat)`);
soundness never depends on `mlt` being a genuine order — only the *usefulness* of the canonical form
does, and that is verified per-identity by `decide`.
-/

namespace UOR.Bridge.F1Square.Analysis.RingNF

/-- A monomial: a list of variable indices, each occurrence a factor (so `x₀²x₁ = [0,0,1]`).
    Canonical monomials are sorted ascending; `mden` is permutation-invariant regardless. -/
abbrev Mono := List Nat

/-- A polynomial normal form: a list of `(monomial, coefficient)` pairs.
    Canonical polynomials are sorted by monomial, merged on equal keys, with no zero coefficients. -/
abbrev Poly := List (Mono × Int)

/-- Denote a monomial as the product of the assigned variable values. -/
def mden (ρ : Nat → Int) : Mono → Int
  | [] => 1
  | i :: m => ρ i * mden ρ m

/-- Denote a polynomial normal form as the sum of `coeff · monomial`. -/
def pden (ρ : Nat → Int) : Poly → Int
  | [] => 0
  | (m, c) :: p => c * mden ρ m + pden ρ p

/-- Left-commutativity of ℤ multiplication (no `ring`/`mul_left_comm` in core). -/
private theorem mlc (a b c : Int) : a * (b * c) = b * (a * c) := by
  rw [← Int.mul_assoc, Int.mul_comm a b, Int.mul_assoc]

/-- A reassociation of a four-fold product, used in `pscaleMono` soundness. -/
theorem mul4 (a b c d : Int) : (a * b) * (c * d) = (a * c) * (b * d) := by
  simp only [Int.mul_assoc]; rw [mlc b c d]

/-- A `Bool`-valued lexicographic comparison on monomials (core has no `LT (List Nat)`). -/
def mlt : Mono → Mono → Bool
  | [], [] => false
  | [], _ :: _ => true
  | _ :: _, [] => false
  | a :: m, b :: n => if a < b then true else if b < a then false else mlt m n

/-- Insert a variable into a sorted monomial (insertion sort step). -/
def minsert (x : Nat) : Mono → Mono
  | [] => [x]
  | y :: m => if x ≤ y then x :: y :: m else y :: minsert x m

/-- Multiply two monomials: append-by-insertion, keeping the result sorted. -/
def mmul (m₁ m₂ : Mono) : Mono := m₁.foldr minsert m₂

/-- `minsert` preserves the monomial's value: it multiplies in `ρ x`. -/
theorem minsert_sound (ρ : Nat → Int) (x : Nat) :
    ∀ m : Mono, mden ρ (minsert x m) = ρ x * mden ρ m := by
  intro m
  induction m with
  | nil => simp [minsert, mden]
  | cons y m ih =>
    simp only [minsert]
    split
    · simp [mden]
    · simp only [mden, ih]
      rw [← Int.mul_assoc, Int.mul_comm (ρ y) (ρ x), Int.mul_assoc]

/-- `mmul` denotes the product of the two monomials' values. -/
theorem mmul_sound (ρ : Nat → Int) :
    ∀ m₁ m₂ : Mono, mden ρ (mmul m₁ m₂) = mden ρ m₁ * mden ρ m₂ := by
  intro m₁ m₂
  induction m₁ with
  | nil => simp [mmul, mden]
  | cons a m₁ ih =>
    have hstep : mmul (a :: m₁) m₂ = minsert a (mmul m₁ m₂) := rfl
    rw [hstep, minsert_sound, ih]
    simp only [mden]
    rw [Int.mul_assoc]

/-- Insert `(m, c)` into a canonical polynomial: merge on equal key, drop zero coefficients,
    keep the list sorted by monomial (via `mlt`). -/
def pinsert (m : Mono) (c : Int) : Poly → Poly
  | [] => if c = 0 then [] else [(m, c)]
  | (m', c') :: p =>
      if m = m' then
        (if c + c' = 0 then p else (m', c + c') :: p)
      else if mlt m m' = true then (m, c) :: (m', c') :: p
      else (m', c') :: pinsert m c p

/-- `pinsert` adds `c · m` to the polynomial's value (merging and zero-dropping are value-preserving). -/
theorem pinsert_sound (ρ : Nat → Int) (m : Mono) (c : Int) :
    ∀ p : Poly, pden ρ (pinsert m c p) = c * mden ρ m + pden ρ p := by
  intro p
  induction p with
  | nil =>
    simp only [pinsert]
    split
    · rename_i h; subst h; simp [pden]
    · simp [pden]
  | cons hd tl ih =>
    obtain ⟨m', c'⟩ := hd
    simp only [pinsert]
    split
    · -- m = m'
      rename_i hmm; subst hmm
      split
      · -- c + c' = 0
        rename_i hc
        simp only [pden]
        have hd : c * mden ρ m + c' * mden ρ m = (c + c') * mden ρ m := by rw [Int.add_mul]
        rw [hc] at hd; simp only [Int.zero_mul] at hd; omega
      · -- c + c' ≠ 0
        simp only [pden]
        have hd : (c + c') * mden ρ m = c * mden ρ m + c' * mden ρ m := by rw [Int.add_mul]
        omega
    · split
      · -- m before m'
        simp [pden]
      · -- recurse past m'
        simp only [pden, ih]; omega

/-- Polynomial addition: fold the left summand's terms into the right via `pinsert`. -/
def padd (p q : Poly) : Poly :=
  p.foldr (fun mc acc => pinsert mc.1 mc.2 acc) q

/-- `padd` denotes the sum. -/
theorem padd_sound (ρ : Nat → Int) :
    ∀ p q : Poly, pden ρ (padd p q) = pden ρ p + pden ρ q := by
  intro p q
  induction p with
  | nil => simp [padd, pden]
  | cons hd tl ih =>
    obtain ⟨m, c⟩ := hd
    have hstep : padd ((m, c) :: tl) q = pinsert m c (padd tl q) := rfl
    rw [hstep, pinsert_sound, ih]
    simp only [pden]; omega

/-- Scale a polynomial by a single monomial term `(m, c)` (one row of `pmul`). -/
def pscaleMono (m : Mono) (c : Int) (q : Poly) : Poly :=
  q.map (fun mc => (mmul m mc.1, c * mc.2))

/-- `pscaleMono` denotes `c · m · q`. -/
theorem pscaleMono_sound (ρ : Nat → Int) (m : Mono) (c : Int) :
    ∀ q : Poly, pden ρ (pscaleMono m c q) = c * mden ρ m * pden ρ q := by
  intro q
  induction q with
  | nil => simp [pscaleMono, pden, Int.mul_zero]
  | cons hd tl ih =>
    obtain ⟨m₂, c₂⟩ := hd
    have hstep : pscaleMono m c ((m₂, c₂) :: tl) = (mmul m m₂, c * c₂) :: pscaleMono m c tl := rfl
    rw [hstep]
    simp only [pden]
    rw [mmul_sound, ih, Int.mul_add, mul4 c c₂ (mden ρ m) (mden ρ m₂)]

/-- Polynomial multiplication: sum the monomial-scaled rows. -/
def pmul (p q : Poly) : Poly :=
  p.foldr (fun mc acc => padd (pscaleMono mc.1 mc.2 q) acc) []

/-- `pmul` denotes the product. -/
theorem pmul_sound (ρ : Nat → Int) :
    ∀ p q : Poly, pden ρ (pmul p q) = pden ρ p * pden ρ q := by
  intro p q
  induction p with
  | nil => simp [pmul, pden, Int.zero_mul]
  | cons hd tl ih =>
    obtain ⟨m, c⟩ := hd
    have hstep : pmul ((m, c) :: tl) q = padd (pscaleMono m c q) (pmul tl q) := rfl
    rw [hstep, padd_sound, pscaleMono_sound, ih]
    simp only [pden]
    rw [Int.add_mul]

/-- Polynomial negation. -/
def pneg (p : Poly) : Poly := p.map (fun mc => (mc.1, -mc.2))

/-- `pneg` denotes the negation. -/
theorem pneg_sound (ρ : Nat → Int) : ∀ p : Poly, pden ρ (pneg p) = - pden ρ p := by
  intro p
  induction p with
  | nil => simp [pneg, pden]
  | cons hd tl ih =>
    obtain ⟨m, c⟩ := hd
    have hstep : pneg ((m, c) :: tl) = (m, -c) :: pneg tl := rfl
    rw [hstep]; simp only [pden, ih, Int.neg_mul]; omega

/-- A constant polynomial (drop the zero constant for canonicity). -/
def pconst (c : Int) : Poly := if c = 0 then [] else [([], c)]

/-- A single variable as a polynomial. -/
def pvar (i : Nat) : Poly := [([i], 1)]

/-- The syntax of polynomial expressions over ℤ. -/
inductive PExpr where
  | var : Nat → PExpr
  | const : Int → PExpr
  | add : PExpr → PExpr → PExpr
  | mul : PExpr → PExpr → PExpr
  | neg : PExpr → PExpr
  | sub : PExpr → PExpr → PExpr
deriving DecidableEq, Repr

/-- The semantics: evaluate an expression under a variable assignment. -/
def denote (ρ : Nat → Int) : PExpr → Int
  | .var i => ρ i
  | .const c => c
  | .add a b => denote ρ a + denote ρ b
  | .mul a b => denote ρ a * denote ρ b
  | .neg a => - denote ρ a
  | .sub a b => denote ρ a - denote ρ b

/-- The canonicaliser: compute the polynomial normal form of an expression. -/
def norm : PExpr → Poly
  | .var i => pvar i
  | .const c => pconst c
  | .add a b => padd (norm a) (norm b)
  | .mul a b => pmul (norm a) (norm b)
  | .neg a => pneg (norm a)
  | .sub a b => padd (norm a) (pneg (norm b))

/-- **Reflection lemma.** The normal form denotes the same value as the expression: normalization
    is meaning-preserving. This is the single certificate that makes the canonical form trustworthy. -/
theorem norm_sound (ρ : Nat → Int) : ∀ e : PExpr, pden ρ (norm e) = denote ρ e := by
  intro e
  induction e with
  | var i => simp [norm, pvar, pden, mden, denote]
  | const c =>
    simp only [norm, pconst, denote]
    split
    · rename_i h; subst h; simp [pden]
    · simp [pden, mden]
  | add a b iha ihb => simp only [norm, denote, padd_sound, iha, ihb]
  | mul a b iha ihb => simp only [norm, denote, pmul_sound, iha, ihb]
  | neg a iha => simp only [norm, denote, pneg_sound, iha]
  | sub a b iha ihb =>
    simp only [norm, denote, padd_sound, pneg_sound, iha, ihb]; omega

/-- **The decision procedure.** If two expressions have the same canonical form, they are equal as
    ℤ-valued functions — for *every* assignment. This is the `ring`-replacement: prove the hypothesis
    `norm a = norm b` by `decide` on the finite normal-form data, and a general identity drops out. -/
theorem nf_eq {ρ : Nat → Int} {a b : PExpr} (h : norm a = norm b) :
    denote ρ a = denote ρ b := by
  rw [← norm_sound ρ a, ← norm_sound ρ b, h]

-- ===========================================================================
-- General ℤ ring identities, proved via the canonical form — NOT reachable by `omega`/`decide`
-- alone (they are nonlinear), and impossible to state generally before this brick.
-- ===========================================================================

/-- A variable environment from a list (variable `i` ↦ `l[i]`, default `0`). Lets clients reflect an
    identity in any number of ℤ atoms (e.g. `Q`'s `num`/`den`) without bespoke env definitions. -/
def env (l : List Int) : Nat → Int := fun i => l.getD i 0

/-- Variable environments for two/three variables. -/
private def ρ2 (a b : Int) : Nat → Int := fun i => if i = 0 then a else if i = 1 then b else 0
private def ρ3 (a b c : Int) : Nat → Int :=
  fun i => if i = 0 then a else if i = 1 then b else if i = 2 then c else 0

/-- The binomial square `(a+b)² = a² + 2ab + b²`, for ALL integers — via the canonical form. -/
theorem sq_add (a b : Int) : (a + b) * (a + b) = a * a + 2 * (a * b) + b * b := by
  have h := nf_eq (ρ := ρ2 a b)
    (a := .mul (.add (.var 0) (.var 1)) (.add (.var 0) (.var 1)))
    (b := .add (.add (.mul (.var 0) (.var 0)) (.mul (.const 2) (.mul (.var 0) (.var 1))))
          (.mul (.var 1) (.var 1)))
    (by decide)
  simpa [denote, ρ2] using h

/-- The difference of squares `(a+b)(a−b) = a² − b²`, for ALL integers. -/
theorem mul_diff (a b : Int) : (a + b) * (a - b) = a * a - b * b := by
  have h := nf_eq (ρ := ρ2 a b)
    (a := .mul (.add (.var 0) (.var 1)) (.sub (.var 0) (.var 1)))
    (b := .sub (.mul (.var 0) (.var 0)) (.mul (.var 1) (.var 1)))
    (by decide)
  simpa [denote, ρ2] using h

/-- The trinomial square `(a+b+c)² = a²+b²+c² + 2(ab+bc+ca)`, for ALL integers. -/
theorem sq_add3 (a b c : Int) :
    (a + b + c) * (a + b + c)
      = a * a + b * b + c * c + 2 * (a * b) + 2 * (b * c) + 2 * (c * a) := by
  have h := nf_eq (ρ := ρ3 a b c)
    (a := .mul (.add (.add (.var 0) (.var 1)) (.var 2)) (.add (.add (.var 0) (.var 1)) (.var 2)))
    (b := .add (.add (.add (.add (.add (.mul (.var 0) (.var 0)) (.mul (.var 1) (.var 1)))
            (.mul (.var 2) (.var 2))) (.mul (.const 2) (.mul (.var 0) (.var 1))))
            (.mul (.const 2) (.mul (.var 1) (.var 2)))) (.mul (.const 2) (.mul (.var 2) (.var 0))))
    (by decide)
  simpa [denote, ρ3] using h

/-- Distributivity, freely commuted/reassociated: `a(b+c) = ba + ca`, for ALL integers. -/
theorem distrib_comm (a b c : Int) : a * (b + c) = b * a + c * a := by
  have h := nf_eq (ρ := ρ3 a b c)
    (a := .mul (.var 0) (.add (.var 1) (.var 2)))
    (b := .add (.mul (.var 1) (.var 0)) (.mul (.var 2) (.var 0)))
    (by decide)
  simpa [denote, ρ3] using h

end UOR.Bridge.F1Square.Analysis.RingNF
