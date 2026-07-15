axiom Real : Type
abbrev ℝ := Real

axiom Real.add : Real → Real → Real
noncomputable instance : Add Real := ⟨Real.add⟩

axiom Real.mul : Real → Real → Real
noncomputable instance : Mul Real := ⟨Real.mul⟩

axiom Real.sub : Real → Real → Real
noncomputable instance : Sub Real := ⟨Real.sub⟩

axiom Real.div : Real → Real → Real
noncomputable instance : Div Real := ⟨Real.div⟩

axiom Real.neg : Real → Real
noncomputable instance : Neg Real := ⟨Real.neg⟩

axiom Real.lt : Real → Real → Prop
instance : LT Real := ⟨Real.lt⟩

axiom Real.le : Real → Real → Prop
instance : LE Real := ⟨Real.le⟩

axiom Real.ofNat : Nat → Real
noncomputable instance (n : Nat) : OfNat Real n := ⟨Real.ofNat n⟩

axiom Real.ofScientific : Nat → Bool → Nat → Real
noncomputable instance : OfScientific Real := ⟨Real.ofScientific⟩

axiom abs : Real → Real

/--
The Beta function for a quartic coupling in melonic GFT.
β_4(lambda) = lambda^2 - 0.1 * lambda
-/
noncomputable def beta4 (lambda : Real) : Real := lambda * lambda - 0.1 * lambda

/--
The Beta function for a sextic coupling in melonic GFT.
β_6(lambda) = lambda^2 - 0.08 * lambda - 0.02
-/
noncomputable def beta6 (lambda : Real) : Real := lambda * lambda - 0.08 * lambda - 0.02

/--
Equilibrium Fixed Point for lambda4.
lambda* satisfies β_4(lambda*) = 0.
Possible values: 0, 0.1.
-/
axiom lambda4_fixed_point_stable : beta4 0.1 = 0

/--
Theorem: Monotonicity of flow toward the IR attractor.
-/
axiom beta4_neg_in_range (lambda : Real) (h1 : 0 < lambda) (h2 : lambda < 0.1) : beta4 lambda < 0
