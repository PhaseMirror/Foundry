set_option autoImplicit false
noncomputable section

namespace ComplexKappa

-- ===== Real =====
axiom Real : Type
axiom Real.zero : Real
axiom Real.one : Real
axiom Real.two : Real
instance : OfNat Real 0 where ofNat := Real.zero
instance : OfNat Real 1 where ofNat := Real.one
instance : OfNat Real 2 where ofNat := Real.two
axiom Real.ofNat' : Nat → Real
axiom Real.add : Real → Real → Real
axiom Real.sub : Real → Real → Real
axiom Real.mul : Real → Real → Real
axiom Real.div : Real → Real → Real
axiom Real.neg : Real → Real
axiom Real.lt : Real → Real → Prop
axiom Real.le : Real → Real → Prop
axiom Real.abs : Real → Real
axiom Real.pow : Real → Nat → Real
axiom Real.sqrt : Real → Real
axiom Real.pi : Real
axiom Real.sin : Real → Real
axiom Real.cos : Real → Real
axiom Real.exp : Real → Real
axiom Real.log : Real → Real
instance : Add Real where add := Real.add
instance : Sub Real where sub := Real.sub
instance : Mul Real where mul := Real.mul
instance : Div Real where div := Real.div
instance : Neg Real where neg := Real.neg
instance : LT Real where lt := Real.lt
instance : LE Real where le := Real.le
instance : HPow Real Nat Real where hPow := Real.pow
instance : Coe Nat Real where coe := Real.ofNat'
instance : Zero Real where zero := Real.zero

-- ===== Complex =====
axiom Complex : Type
axiom Complex.re : Complex → Real
axiom Complex.im : Complex → Real
axiom Complex.mk : Real → Real → Complex
axiom Complex.add : Complex → Complex → Complex
axiom Complex.sub : Complex → Complex → Complex
axiom Complex.mul : Complex → Complex → Complex
axiom Complex.div : Complex → Complex → Complex
axiom Complex.neg : Complex → Complex
axiom Complex.abs : Complex → Real
axiom Complex.exp : Complex → Complex
axiom Complex.i : Complex
axiom Complex.conj : Complex → Complex
axiom Complex.ofNat' : Nat → Complex
axiom Complex.zero : Complex
axiom Complex.one : Complex
axiom Complex.two : Complex
instance : OfNat Complex 0 where ofNat := Complex.zero
instance : OfNat Complex 1 where ofNat := Complex.one
instance : OfNat Complex 2 where ofNat := Complex.two
instance : Add Complex where add := Complex.add
instance : Sub Complex where sub := Complex.sub
instance : Mul Complex where mul := Complex.mul
instance : Div Complex where div := Complex.div
instance : Neg Complex where neg := Complex.neg
instance : Zero Complex where zero := Complex.zero
instance : HPow Complex Nat Complex where hPow z n := Complex.ofNat' n

-- ===== Coercions =====
axiom Real.toComplex : Real → Complex
instance : HMul Real Complex Complex where hMul r c := Complex.mul (Real.toComplex r) c
instance : HMul Complex Real Complex where hMul c r := Complex.mul c (Real.toComplex r)
instance : HAdd Real Complex Complex where hAdd r c := Complex.add (Real.toComplex r) c
instance : HAdd Complex Real Complex where hAdd c r := Complex.add c (Real.toComplex r)
instance : HSub Real Complex Complex where hSub r c := Complex.sub (Real.toComplex r) c
instance : HSub Complex Real Complex where hSub c r := Complex.sub c (Real.toComplex r)
instance : HDiv Real Complex Complex where hDiv r c := Complex.div (Real.toComplex r) c
instance : HDiv Complex Real Complex where hDiv c r := Complex.div c (Real.toComplex r)

-- ===== Function type instances =====
instance {A B : Type} [Add B] : Add (A → B) where add f g := fun a => f a + g a
instance {A B : Type} [Mul B] : Mul (A → B) where mul f g := fun a => f a * g a
instance {A B : Type} [Neg B] : Neg (A → B) where neg f := fun a => -f a
instance {A B : Type} [Div B] : Div (A → B) where div f g := fun a => f a / g a
instance {A B : Type} [Coe A B] : Coe A (Real → B) where coe a := fun _ => (a : B)

-- ===== Stubs for Mathlib concepts =====
axiom IsAnalyticAt : (Complex → Complex) → Complex → Prop
axiom Integrable : (Real → Complex) → Prop
axiom fourier_transform : (Real → Complex) → (Real → Complex)
axiom Summable {A : Type} : (Nat → A) → Prop

end ComplexKappa
end
