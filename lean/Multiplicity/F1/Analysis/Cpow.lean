structure Complex where
  re : Float
  im : Float
  deriving Repr, Inhabited

notation "ℂ" => Complex

def Rpi : ℂ := ⟨3.141592653589793, 0.0⟩

def Cpow (z _w : ℂ) : ℂ := z

def Complex.sin (z : ℂ) : ℂ := ⟨Float.sin z.re, 0.0⟩
def Complex.re (z : ℂ) : Float := z.re
def Complex.im (z : ℂ) : Float := z.im

def Complex.ofNat (n : Nat) : ℂ := ⟨Float.ofNat n, 0.0⟩
instance : OfNat ℂ n where
  ofNat := Complex.ofNat n

def Complex.div (z _w : ℂ) : ℂ := z
instance : Div ℂ where
  div := Complex.div

def Complex.add (z w : ℂ) : ℂ := ⟨z.re + w.re, z.im + w.im⟩
instance : Add ℂ where
  add := Complex.add

def Complex.sub (z w : ℂ) : ℂ := ⟨z.re - w.re, z.im - w.im⟩
instance : Sub ℂ where
  sub := Complex.sub

def Complex.mul (z w : ℂ) : ℂ := ⟨z.re * w.re - z.im * w.im, z.re * w.im + z.im * w.re⟩
instance : Mul ℂ where
  mul := Complex.mul

def Complex.neg (z : ℂ) : ℂ := ⟨-z.re, -z.im⟩
instance : Neg ℂ where
  neg := Complex.neg
