/-
F1 square — v0.17.0 stage C, brick 1: the 𝔽₁ curve at the monoid-scheme level.

Companion `f1_square_intersection_theory.md` §0.2 / §1.1 / T1. The 1-dimensional factor of the
arithmetic square is the Connes–Consani arithmetic-site curve `Spec ℤ / 𝔽₁`; at the Deitmar
monoid-scheme level its coordinate object is the MULTIPLICATIVE MONOID OF POSITIVE INTEGERS
`(ℕ₊, ·, 1)` — the free commutative monoid on the primes (its canonical form is the prime
factorization: the UOR content-address of an integer "over 𝔽₁"). Deitmar 𝔽₁-algebras are
commutative monoids, and `𝔽₁` itself is the TRIVIAL monoid `{1}` — the INITIAL object, proved
below (`f1_initial`, `f1_initial_unique`). Everything is a hand-built realization (UOR idiom:
canonical form + proved invariants): a bundled `CMon` record, monoid homs `MHom`, the curve
`Curve`, the base `F1`.

Two Frobenius-flavored maps live on the curve and must not be conflated (companion §0.2/§2.3):
  • the POWER endomorphism `frobPow k : a ↦ aᵏ` — a genuine monoid hom (`(ab)ᵏ = aᵏbᵏ`),
    the function-field-style Frobenius;
  • the SCALING map `mScale n : a ↦ n·a` — the Connes–Consani scaling flow at `n` (in log
    coordinates the SHIFT `x ↦ x + log n`), which is NOT a monoid hom for `n ≥ 2`
    (`mScale_not_hom`); on the square it is carried by the graph CORRESPONDENCE `Γ_n`
    (`Square/Divisors.lean`), exactly as the companion's parallel-pencil finding requires.

Pure Lean 4 core (no Mathlib), no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

namespace UOR.Bridge.F1Square.Square

/-- The carrier of the 𝔽₁ curve at the monoid level: positive integers (multiplicative).
    (Classically its canonical form is the prime factorization — the content-address;
    see the `Curve` docstring for the honest scope of that remark.) -/
def MPos : Type := {n : Nat // 1 ≤ n}

/-- The unit `1` of the curve monoid. -/
def mOne : MPos := ⟨1, Nat.le_refl 1⟩

/-- Positivity is multiplicative (the carrier is closed under `mMul`). -/
theorem one_le_mul {a b : Nat} (ha : 1 ≤ a) (hb : 1 ≤ b) : 1 ≤ a * b := by
  have := Nat.mul_le_mul ha hb
  omega

/-- Multiplication on the curve monoid. -/
def mMul (a b : MPos) : MPos := ⟨a.val * b.val, one_le_mul a.property b.property⟩

/-- `mMul` is associative. -/
theorem mMul_assoc (a b c : MPos) : mMul (mMul a b) c = mMul a (mMul b c) :=
  Subtype.ext (Nat.mul_assoc a.val b.val c.val)

/-- `mMul` is commutative. -/
theorem mMul_comm (a b : MPos) : mMul a b = mMul b a :=
  Subtype.ext (Nat.mul_comm a.val b.val)

/-- `1` is a left unit for `mMul`. -/
theorem mOne_mul (a : MPos) : mMul mOne a = a :=
  Subtype.ext (Nat.one_mul a.val)

/-- `1` is a right unit for `mMul`. -/
theorem mMul_one (a : MPos) : mMul a mOne = a :=
  Subtype.ext (Nat.mul_one a.val)

/-- A commutative monoid, bundled (the UOR realization of a Deitmar 𝔽₁-algebra).
    Pure-core substitute for the absent `Monoid` typeclass hierarchy. -/
structure CMon where
  /-- the underlying type -/
  carrier : Type
  /-- the multiplication -/
  mul : carrier → carrier → carrier
  /-- the unit -/
  one : carrier
  /-- associativity -/
  mul_assoc : ∀ a b c, mul (mul a b) c = mul a (mul b c)
  /-- commutativity -/
  mul_comm : ∀ a b, mul a b = mul b a
  /-- left unit law -/
  one_mul : ∀ a, mul one a = a

/-- The right unit law, derived from commutativity and the left unit law. -/
theorem cmon_mul_one (M : CMon) (a : M.carrier) : M.mul a M.one = a := by
  rw [M.mul_comm]; exact M.one_mul a

/-- The middle-four exchange `(ab)(cd) = (ac)(bd)` in any commutative monoid —
    the rearrangement the tensor's universal map needs. -/
theorem cmon_mul_mul_comm (M : CMon) (a b c d : M.carrier) :
    M.mul (M.mul a b) (M.mul c d) = M.mul (M.mul a c) (M.mul b d) := by
  rw [M.mul_assoc a b (M.mul c d), M.mul_assoc a c (M.mul b d)]
  have h : M.mul b (M.mul c d) = M.mul c (M.mul b d) := by
    rw [← M.mul_assoc b c d, M.mul_comm b c, M.mul_assoc c b d]
  rw [h]

/-- A homomorphism of commutative monoids (an 𝔽₁-algebra map). -/
structure MHom (M N : CMon) where
  /-- the underlying map -/
  map : M.carrier → N.carrier
  /-- it preserves the unit -/
  map_one : map M.one = N.one
  /-- it preserves multiplication -/
  map_mul : ∀ a b, map (M.mul a b) = N.mul (map a) (map b)

/-- The identity homomorphism. -/
def idHom (M : CMon) : MHom M M where
  map := fun a => a
  map_one := rfl
  map_mul := fun _ _ => rfl

/-- Composition of homomorphisms. -/
def compHom {M N P : CMon} (f : MHom M N) (g : MHom N P) : MHom M P where
  map := fun a => g.map (f.map a)
  map_one := by
    show g.map (f.map M.one) = P.one
    rw [f.map_one, g.map_one]
  map_mul := fun a b => by
    show g.map (f.map (M.mul a b)) = P.mul (g.map (f.map a)) (g.map (f.map b))
    rw [f.map_mul, g.map_mul]

/-- The 𝔽₁ curve `Spec ℤ / 𝔽₁` at the monoid level: `(ℕ₊, ·, 1)` — classically the free
    commutative monoid on the primes via unique factorization (whose canonical form, the
    prime exponent vector, is the UOR content-address); freeness is a [CLASSICAL] remark,
    not used or proved here — what the construction uses are the proved monoid laws below
    and the prime machinery of `Analysis/Mangoldt.lean` (`spf_prime`, `prime_dvd_mul`). -/
def Curve : CMon where
  carrier := MPos
  mul := mMul
  one := mOne
  mul_assoc := mMul_assoc
  mul_comm := mMul_comm
  one_mul := mOne_mul

/-- The base `𝔽₁`: the trivial monoid `{1}` (Deitmar). -/
def F1 : CMon where
  carrier := Unit
  mul := fun _ _ => ()
  one := ()
  mul_assoc := fun _ _ _ => rfl
  mul_comm := fun _ _ => rfl
  one_mul := fun _ => rfl

/-- The unique 𝔽₁-algebra map out of the base: `𝔽₁ → T`, `1 ↦ 1`. -/
def f1Init (T : CMon) : MHom F1 T where
  map := fun _ => T.one
  map_one := rfl
  map_mul := fun _ _ => (cmon_mul_one T T.one).symm

/-- `𝔽₁` is INITIAL: any hom `𝔽₁ → T` agrees with `f1Init T`. This is what makes the fiber
    coproduct over `𝔽₁` (the tensor `F ⊗_𝔽₁ F`) the PLAIN coproduct — the canonicality input
    for the square (`Square/Tensor.lean`). -/
theorem f1_initial (T : CMon) (h : MHom F1 T) : ∀ u : F1.carrier, h.map u = (f1Init T).map u :=
  fun _ => h.map_one

/-- Initiality, uniqueness form: any two homs `𝔽₁ → T` agree pointwise. -/
theorem f1_initial_unique (T : CMon) (h h' : MHom F1 T) : ∀ u : F1.carrier, h.map u = h'.map u :=
  fun u => (f1_initial T h u).trans (f1_initial T h' u).symm

/-- The POWER Frobenius `a ↦ aᵏ` on the curve — a genuine monoid endomorphism
    (the function-field-style Frobenius; over `𝔽_q` this is `x ↦ x^q`). -/
def frobPow (k : Nat) : MHom Curve Curve where
  map := fun a => ⟨a.val ^ k, by
    have := Nat.pos_pow_of_pos k (show 0 < a.val from a.property)
    omega⟩
  map_one := Subtype.ext (Nat.one_pow k)
  map_mul := fun a b => Subtype.ext (Nat.mul_pow a.val b.val k)

/-- The SCALING map at `n` (the Connes–Consani scaling flow): `a ↦ n·a`.
    In log coordinates this is the shift `x ↦ x + log n`. -/
def mScale (n : Nat) (hn : 1 ≤ n) (a : MPos) : MPos := mMul ⟨n, hn⟩ a

/-- The scaling map is NOT a monoid hom for `n ≥ 2` (it moves the unit: `1 ↦ n ≠ 1`).
    Its geometric carrier on the square is the graph CORRESPONDENCE `Γ_n`, not an
    endomorphism — the structural reason the arithmetic content sits in a PENCIL of
    correspondences (companion §2.3), not in a Frobenius endomorphism. -/
theorem mScale_not_hom (n : Nat) (hn : 2 ≤ n) :
    mScale n (by omega) mOne ≠ mOne := by
  intro h
  have hval : n * 1 = 1 := congrArg Subtype.val h
  omega

/-- The scaling maps COMPOSE LIKE THE FLOW: `mScale n ∘ mScale m = mScale (n·m)` — the
    pencil is an action of the curve monoid on itself (the "flow" structure that the
    shift lengths `log n` linearize, `Square/Pencil.lean`). -/
theorem mScale_comp (n m : Nat) (hn : 1 ≤ n) (hm : 1 ≤ m) (a : MPos) :
    mScale n hn (mScale m hm a) = mScale (n * m) (one_le_mul hn hm) a :=
  Subtype.ext (Nat.mul_assoc n m a.val).symm

end UOR.Bridge.F1Square.Square
