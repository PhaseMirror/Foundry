axiom Complex : Type
notation "ℂ" => Complex

axiom Rpi : ℂ
axiom Cpow : ℂ → ℂ → ℂ

axiom Complex.sin : ℂ → ℂ
axiom Complex.re : ℂ → Float
axiom Complex.im : ℂ → Float

axiom Complex.ofNat : Nat → ℂ
noncomputable instance : OfNat ℂ n where
  ofNat := Complex.ofNat n

axiom Complex.div : ℂ → ℂ → ℂ
noncomputable instance : Div ℂ where
  div := Complex.div

axiom Complex.add : ℂ → ℂ → ℂ
noncomputable instance : Add ℂ where
  add := Complex.add

axiom Complex.sub : ℂ → ℂ → ℂ
noncomputable instance : Sub ℂ where
  sub := Complex.sub

axiom Complex.mul : ℂ → ℂ → ℂ
noncomputable instance : Mul ℂ where
  mul := Complex.mul

axiom Complex.neg : ℂ → ℂ
noncomputable instance : Neg ℂ where
  neg := Complex.neg
