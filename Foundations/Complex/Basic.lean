import Foundations.Rat.Basic

namespace Foundations.Complex

/-- Exact constructive complex number as a pair of rationals. -/
structure Complex where
  re : Rat
  im : Rat
  deriving Repr, DecidableEq

def add (a b : Complex) : Complex := ⟨a.re + b.re, a.im + b.im⟩
instance : Add Complex := ⟨add⟩

def sub (a b : Complex) : Complex := ⟨a.re - b.re, a.im - b.im⟩
instance : Sub Complex := ⟨sub⟩

def mul (a b : Complex) : Complex := ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩
instance : Mul Complex := ⟨mul⟩

def neg (a : Complex) : Complex := ⟨-a.re, -a.im⟩
instance : Neg Complex := ⟨neg⟩

def conj (a : Complex) : Complex := ⟨a.re, -a.im⟩

theorem conj_conj (z : Complex) : conj (conj z) = z := by
  cases z
  dsimp [conj]
  rw [Rat.neg_neg]

def normSq (z : Complex) : Rat := z.re * z.re + z.im * z.im

def zero : Complex := ⟨0, 0⟩
def one : Complex := ⟨1, 0⟩
def I : Complex := ⟨0, 1⟩

instance : Zero Complex := ⟨zero⟩
instance : One Complex := ⟨one⟩

theorem I_re : I.re = 0 := rfl
theorem I_im : I.im = 1 := rfl
theorem zero_re : (0 : Complex).re = 0 := rfl
theorem zero_im : (0 : Complex).im = 0 := rfl
theorem one_re : (1 : Complex).re = 1 := rfl
theorem one_im : (1 : Complex).im = 0 := rfl

end Foundations.Complex
