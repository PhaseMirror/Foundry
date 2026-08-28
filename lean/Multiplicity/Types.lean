set_option autoImplicit false

namespace Multiplicity.ComplexKappa

abbrev Real := Float
abbrev ℝ := Float

structure Complex where
  re : Float
  im : Float
  deriving Repr, BEq, Inhabited

namespace Complex

def zero : Complex := ⟨0.0, 0.0⟩
def one : Complex := ⟨1.0, 0.0⟩
def two : Complex := ⟨2.0, 0.0⟩
def i : Complex := ⟨0.0, 1.0⟩

def add (a b : Complex) : Complex := ⟨a.re + b.re, a.im + b.im⟩
def sub (a b : Complex) : Complex := ⟨a.re - b.re, a.im - b.im⟩
def mul (a b : Complex) : Complex := ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩
def div (a b : Complex) : Complex :=
  let denom := b.re * b.re + b.im * b.im
  ⟨(a.re * b.re + a.im * b.im) / denom, (a.im * b.re - a.re * b.im) / denom⟩
def neg (a : Complex) : Complex := ⟨-a.re, -a.im⟩
def abs (a : Complex) : Float := Float.sqrt (a.re * a.re + a.im * a.im)
def conj (a : Complex) : Complex := ⟨a.re, -a.im⟩
def ofNat' (n : Nat) : Complex := ⟨Float.ofNat n, 0.0⟩

instance : OfNat Complex 0 where ofNat := Complex.zero
instance : OfNat Complex 1 where ofNat := Complex.one
instance : OfNat Complex 2 where ofNat := Complex.two
instance : Add Complex where add := Complex.add
instance : Sub Complex where sub := Complex.sub
instance : Mul Complex where mul := Complex.mul
instance : Div Complex where div := Complex.div
instance : Neg Complex where neg := Complex.neg
instance : Zero Complex where zero := Complex.zero

end Complex

def IsAnalyticAt (_f : Complex → Complex) (_z : Complex) : Prop := True
def Integrable (_f : Float → Complex) : Prop := True
def fourier_transform (f : Float → Complex) : Float → Complex := f
def Summable {A : Type} (_f : Nat → A) : Prop := True

end Multiplicity.ComplexKappa
