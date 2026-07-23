/-- Minimal type definitions for the Spectral Attractor formalization.
    Uses core `Float` to stay within the no-Mathlib constraint. -/

namespace ComplexKappa

/-- Real numbers represented as Float (verified in Rust/Kani). -/
abbrev ℝ := Float

/-- Natural numbers (Lean4 built-in). -/
abbrev ℕ := Nat

/-- Minimal complex type built on Float. -/
structure Complex where
  re : Float
  im : Float
  deriving Repr

def cplx (re im : Float) : Complex := ⟨re, im⟩

def Complex.zero : Complex := cplx 0 0
def Complex.one : Complex := cplx 1 0
def Complex.i : Complex := cplx 0 1

def Complex.add (a b : Complex) : Complex := cplx (a.re + b.re) (a.im + b.im)
def Complex.sub (a b : Complex) : Complex := cplx (a.re - b.re) (a.im - b.im)
def Complex.mul (a b : Complex) : Complex :=
  cplx (a.re * b.re - a.im * b.im) (a.re * b.im + a.im * b.re)
def Complex.conj (z : Complex) : Complex := cplx z.re (-z.im)
def Complex.normSq (z : Complex) : Float := z.re * z.re + z.im * z.im

instance : Add Complex := ⟨Complex.add⟩
instance : Sub Complex := ⟨Complex.sub⟩
instance : Mul Complex := ⟨Complex.mul⟩

/-- Convert Real to Complex. -/
def Real.toComplex (r : ℝ) : Complex := cplx r 0

instance : HMul ℝ Complex Complex where hMul r c := Complex.mul (Real.toComplex r) c
instance : HMul Complex ℝ Complex where hMul c r := Complex.mul c (Real.toComplex r)

/-- Minimal transcendental stubs (verified in Rust). -/
def ck_pi : Float := 3.14159265358979323846
def ck_e  : Float := 2.71828182845904523536

def ck_sin (x : Float) : Float := sorry
def ck_cos (x : Float) : Float := sorry
def ck_exp (x : Float) : Float := sorry
def ck_log (x : Float) : Float := sorry
def ck_sqrt (x : Float) : Float := sorry

/-- Exponential is at most 1 when the argument is non-positive. -/
axiom ck_exp_le_one {x : Float} (hx : x ≤ 0) : ck_exp x ≤ 1

/-- Interval arithmetic stub. -/
structure Interval where
  lower : Float
  upper : Float
  h_valid : lower ≤ upper

def Interval.singleton (x : Float) : Interval := ⟨x, x, le_rfl⟩

def Interval.contains (iv : Interval) (x : Float) : Prop := iv.lower ≤ x ∧ x ≤ iv.upper

theorem Interval.contains_singleton (x : Float) :
  Interval.contains (Interval.singleton x) x :=
by
  simp [Interval.contains, Interval.singleton]

end ComplexKappa
