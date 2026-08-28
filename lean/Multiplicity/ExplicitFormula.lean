namespace Multiplicity.ExplicitFormula

structure ℂ where
  re : Float
  im : Float
  deriving Repr, Inhabited

def ℂ.zero : ℂ := ⟨0, 0⟩
def ℂ.one : ℂ := ⟨1, 0⟩

instance : Neg ℂ := ⟨fun z => ⟨-z.re, -z.im⟩⟩
instance : Div ℂ := ⟨fun z _ => z⟩
instance : Mul ℂ := ⟨fun z w => ⟨z.re * w.re - z.im * w.im, z.re * w.im + z.im * w.re⟩⟩
instance : OfNat ℂ n := ⟨⟨Float.ofNat n, 0⟩⟩

def ζ (s : ℂ) : ℂ := s
def deriv (f : ℂ → ℂ) (s : ℂ) : ℂ := f s
def re (s : ℂ) : ℂ := ⟨s.re, 0⟩
def gt_one (s : ℂ) : Prop := s.re > 1.0

def dirichlet_series (_a : Nat → ℂ) (_s : ℂ) : ℂ := ℂ.zero
def von_mangoldt (_n : Nat) : ℂ := ℂ.zero

end Multiplicity.ExplicitFormula
