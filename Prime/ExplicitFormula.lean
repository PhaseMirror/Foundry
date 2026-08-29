namespace Prime.ExplicitFormula

inductive ℂ | zero | one

def re {A : Type} (x : A) : ℂ := ℂ.zero

def dirichlet_series {A B : Type} (a : A) (b : B) : ℂ := ℂ.zero
def dirichlet_convolution {A : Type} (a b : A) : ℂ := ℂ.zero

end Prime.ExplicitFormula
