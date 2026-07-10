/-
F1 square — v0.17.0 stage C, brick 2: the CANONICAL square `𝕊 = Spec ℤ ×_𝔽₁ Spec ℤ`
(the tensor `F ⊗_𝔽₁ F`) at the monoid-scheme level, with its universal property PROVED.

Companion §1.1 / §3.1 / T1. What "canonical" means here, and what is proved:

  • In Deitmar 𝔽₁-geometry, 𝔽₁-algebras are commutative monoids and the affine product
    `Spec A ×_{Spec B} Spec C` is `Spec` of the FIBER COPRODUCT `A ⊗_B C`. The base `𝔽₁`
    (the trivial monoid) is INITIAL (`f1_initial`, brick 1), so the fiber coproduct over it
    is the PLAIN coproduct of commutative monoids. The coproduct of `(ℕ₊,·)` with itself is
    the componentwise-product monoid `ℕ₊ × ℕ₊` with injections `a ↦ (a,1)`, `b ↦ (1,b)` —
    and this module PROVES the universal property (`copair_inl`, `copair_inr`,
    `copair_unique`): for every commutative monoid `T` and homs `f, g : Curve → T` there is
    exactly one hom `𝕊 → T` restricting to `f` and `g`. THE UNIVERSAL PROPERTY IS THE
    CANONICALITY — `𝕊` is not a candidate model chosen by hand; it is THE object with this
    property, unique up to unique isomorphism. The 𝔽₁-cocone condition is checked to be
    automatic (`square_base_cocone`), so coproduct = pushout over `𝔽₁`.

  • The ℤ-collapse is avoided (§3.1: `ℤ ⊗_ℤ ℤ = ℤ`, the ring product gives back the curve):
    the two injections are DISTINCT (`inl_ne_inr`), the codiagonal `𝕊 → Curve` identifies
    distinct points (`codiag_not_injective` via `gen2_codiag_collapse`), and `𝕊` contains a
    FREE RANK-2 family of monomials `2^a ⊗ 2^b` (`gen2_injective`) — the square is strictly
    2-dimensional where the curve's monomials `2^{a+b}` are rank 1. Both projections recover
    the curve (`proj1_inl`, `proj2_inr`, `proj_faithful`): T1's point-set verification,
    now a theorem for ALL points (not a 17-prime truncation).

HONEST SCOPE. This is the canonical square AT THE MONOID-SCHEME LEVEL — the level at which
T1 lives. Its divisor/intersection structure is built in bricks 3–6 (point-count derived);
the `H¹`-bearing spectral structure (T4: scaling spectrum = the zeta zeros) is NOT here, and
the Hodge-index crux (T5 = RH) is untouched — see `Square/Polarized.lean` and `Crux.lean`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Monoid

namespace UOR.Bridge.F1Square.Square

/-- THE ARITHMETIC SQUARE `𝕊 = Spec ℤ ×_𝔽₁ Spec ℤ` at the monoid level: the coproduct
    `F ⊗_𝔽₁ F` of the curve monoid with itself — carrier `ℕ₊ × ℕ₊`, componentwise
    multiplication. Its points are PAIRS (the point set is `C × C`, T1). -/
def Sq : CMon where
  carrier := MPos × MPos
  mul := fun z w => (mMul z.1 w.1, mMul z.2 w.2)
  one := (mOne, mOne)
  mul_assoc := fun a b c => by
    show (mMul (mMul a.1 b.1) c.1, mMul (mMul a.2 b.2) c.2)
       = (mMul a.1 (mMul b.1 c.1), mMul a.2 (mMul b.2 c.2))
    rw [mMul_assoc a.1 b.1 c.1, mMul_assoc a.2 b.2 c.2]
  mul_comm := fun a b => by
    show (mMul a.1 b.1, mMul a.2 b.2) = (mMul b.1 a.1, mMul b.2 a.2)
    rw [mMul_comm a.1 b.1, mMul_comm a.2 b.2]
  one_mul := fun a => by
    show (mMul mOne a.1, mMul mOne a.2) = (a.1, a.2)
    rw [mOne_mul a.1, mOne_mul a.2]

/-- The first coproduct injection (the left tensor factor): `a ↦ a ⊗ 1`. -/
def inl : MHom Curve Sq where
  map := fun a => (a, mOne)
  map_one := rfl
  map_mul := fun a b => by
    show (mMul a b, mOne) = (mMul a b, mMul mOne mOne)
    rw [mOne_mul mOne]

/-- The second coproduct injection (the right tensor factor): `b ↦ 1 ⊗ b`. -/
def inr : MHom Curve Sq where
  map := fun b => (mOne, b)
  map_one := rfl
  map_mul := fun a b => by
    show (mOne, mMul a b) = (mMul mOne mOne, mMul a b)
    rw [mOne_mul mOne]

/-- The first projection `𝕊 → Curve` (the structural map recovering the first factor). -/
def proj1 : MHom Sq Curve where
  map := fun z => z.1
  map_one := rfl
  map_mul := fun _ _ => rfl

/-- The second projection `𝕊 → Curve`. -/
def proj2 : MHom Sq Curve where
  map := fun z => z.2
  map_one := rfl
  map_mul := fun _ _ => rfl

/-- The universal map out of the coproduct: given `f, g : Curve → T`, the unique hom
    `𝕊 → T` with `z ↦ f(z₁)·g(z₂)`. -/
def copair (T : CMon) (f g : MHom Curve T) : MHom Sq T where
  map := fun z => T.mul (f.map z.1) (g.map z.2)
  map_one := by
    show T.mul (f.map mOne) (g.map mOne) = T.one
    rw [show f.map mOne = T.one from f.map_one, show g.map mOne = T.one from g.map_one,
      T.one_mul]
  map_mul := fun z w => by
    show T.mul (f.map (mMul z.1 w.1)) (g.map (mMul z.2 w.2))
       = T.mul (T.mul (f.map z.1) (g.map z.2)) (T.mul (f.map w.1) (g.map w.2))
    rw [show f.map (mMul z.1 w.1) = T.mul (f.map z.1) (f.map w.1) from f.map_mul z.1 w.1,
      show g.map (mMul z.2 w.2) = T.mul (g.map z.2) (g.map w.2) from g.map_mul z.2 w.2,
      cmon_mul_mul_comm T]

/-- The universal map restricts to `f` on the left factor: `copair ∘ inl = f`. -/
theorem copair_inl (T : CMon) (f g : MHom Curve T) (a : MPos) :
    (copair T f g).map (inl.map a) = f.map a := by
  show T.mul (f.map a) (g.map mOne) = f.map a
  rw [show g.map mOne = T.one from g.map_one, cmon_mul_one]

/-- The universal map restricts to `g` on the right factor: `copair ∘ inr = g`. -/
theorem copair_inr (T : CMon) (f g : MHom Curve T) (b : MPos) :
    (copair T f g).map (inr.map b) = g.map b := by
  show T.mul (f.map mOne) (g.map b) = g.map b
  rw [show f.map mOne = T.one from f.map_one, T.one_mul]

/-- Every point of `𝕊` factors through the injections: `z = inl(z₁) · inr(z₂)`
    (the tensor decomposition `z = z₁ ⊗ z₂`). -/
theorem sq_factor (z : Sq.carrier) : z = Sq.mul (inl.map z.1) (inr.map z.2) := by
  show z = (mMul z.1 mOne, mMul mOne z.2)
  rw [mMul_one z.1, mOne_mul z.2]
  rfl

/-- UNIQUENESS of the universal map — the heart of the canonicality. Any hom `h : 𝕊 → T`
    that restricts to `f` and `g` on the two factors IS `copair f g`, pointwise. Together
    with `copair_inl`/`copair_inr` this is the full universal property of the coproduct:
    `𝕊` is THE tensor `F ⊗_𝔽₁ F`, unique up to unique isomorphism — canonical, not a
    candidate. -/
theorem copair_unique (T : CMon) (f g : MHom Curve T) (h : MHom Sq T)
    (hl : ∀ a, h.map (inl.map a) = f.map a) (hr : ∀ b, h.map (inr.map b) = g.map b) :
    ∀ z : Sq.carrier, h.map z = (copair T f g).map z := by
  intro z
  have hz := congrArg h.map (sq_factor z)
  rw [h.map_mul (inl.map z.1) (inr.map z.2), hl z.1, hr z.2] at hz
  exact hz

/-- The 𝔽₁-cocone condition is AUTOMATIC: any two homs `f, g : Curve → T` agree on the image
    of the base `𝔽₁ → Curve` (both send it to `1`). Hence the coproduct above IS the pushout
    `Curve ⊔_𝔽₁ Curve` — the fiber coproduct over `𝔽₁`, i.e. the tensor the square requires
    (`Spec` of it is the FIBER PRODUCT `Spec ℤ ×_𝔽₁ Spec ℤ`). -/
theorem square_base_cocone (T : CMon) (f g : MHom Curve T) :
    ∀ u : F1.carrier, f.map ((f1Init Curve).map u) = g.map ((f1Init Curve).map u) := by
  intro _
  show f.map mOne = g.map mOne
  rw [show f.map mOne = T.one from f.map_one, show g.map mOne = T.one from g.map_one]

-- ===========================================================================
-- Non-collapse and strict 2-dimensionality (§3.1 avoided; T1 for all points).
-- ===========================================================================

/-- The element `2` of the curve. -/
def mTwo : MPos := ⟨2, by omega⟩

/-- The two injections are DISTINCT — the first non-collapse witness. Over `ℤ` the two
    inclusions `Spec ℤ ⇉ Spec ℤ ×_ℤ Spec ℤ = Spec ℤ` coincide (the §3.1 collapse); over
    `𝔽₁` they do not: `2 ⊗ 1 ≠ 1 ⊗ 2`. -/
theorem inl_ne_inr : inl.map mTwo ≠ inr.map mTwo := by
  intro h
  have hval : (2 : Nat) = 1 := congrArg (fun z => z.1.val) h
  omega

/-- The identity hom of the curve. -/
def idCurve : MHom Curve Curve := idHom Curve

/-- The CODIAGONAL `∇ : 𝕊 → Curve`, `z ↦ z₁·z₂` — the comparison map to the collapsed
    (over-`ℤ`) product. -/
def codiag : MHom Sq Curve := copair Curve idCurve idCurve

/-- The rank-2 monomial family `(a, b) ↦ 2^a ⊗ 2^b` in `𝕊`. -/
def gen2 (a b : Nat) : Sq.carrier :=
  ((frobPow a).map mTwo, (frobPow b).map mTwo)

private theorem two_pow_lt {a c : Nat} (h : a < c) : 2 ^ a < 2 ^ c := by
  induction c with
  | zero => omega
  | succ c ih =>
      rw [Nat.pow_succ]
      rcases Nat.lt_or_ge a c with h' | h'
      · have := ih h'; omega
      · have : a = c := by omega
        subst this
        have : 1 ≤ 2 ^ a := Nat.pos_pow_of_pos a (by omega)
        omega

private theorem two_pow_inj {a c : Nat} (h : (2 : Nat) ^ a = 2 ^ c) : a = c := by
  rcases Nat.lt_or_ge a c with h' | h'
  · exact absurd h (Nat.ne_of_lt (two_pow_lt h'))
  · rcases Nat.lt_or_ge c a with h'' | h''
    · exact absurd h.symm (Nat.ne_of_lt (two_pow_lt h''))
    · omega

/-- STRICT 2-DIMENSIONALITY (T1, now a theorem for all exponents): the monomial family
    `2^a ⊗ 2^b` is FREE OF RANK 2 in `𝕊` — distinct exponent pairs give distinct points.
    This is the precise sense in which the 𝔽₁ square is a genuine surface (`1 + 1 = 2`),
    not the curve in disguise. -/
theorem gen2_injective (a b c d : Nat) (h : gen2 a b = gen2 c d) : a = c ∧ b = d := by
  have h1 : (2 : Nat) ^ a = 2 ^ c := congrArg (fun z => z.1.val) h
  have h2 : (2 : Nat) ^ b = 2 ^ d := congrArg (fun z => z.2.val) h
  exact ⟨two_pow_inj h1, two_pow_inj h2⟩

/-- The codiagonal collapses the rank-2 family to rank 1: `∇(2^a ⊗ 2^b) = 2^{a+b}` —
    the over-`ℤ` shadow only sees the total degree. -/
theorem gen2_codiag_collapse (a b : Nat) :
    (codiag.map (gen2 a b)).val = 2 ^ (a + b) := by
  show (2 : Nat) ^ a * 2 ^ b = 2 ^ (a + b)
  exact (Nat.pow_add 2 a b).symm

/-- The codiagonal is NOT injective: `2 ⊗ 1` and `1 ⊗ 2` are distinct points of `𝕊` with
    the same image in the curve. The square is strictly larger than the §3.1 collapse. -/
theorem codiag_not_injective :
    gen2 1 0 ≠ gen2 0 1 ∧ codiag.map (gen2 1 0) = codiag.map (gen2 0 1) := by
  constructor
  · intro h
    have := (gen2_injective 1 0 0 1 h).1
    omega
  · exact Subtype.ext (by show 2 ^ 1 * 2 ^ 0 = 2 ^ 0 * 2 ^ 1; omega)

-- ===========================================================================
-- The coproduct property packaged as ONE proposition, and uniqueness up to
-- canonical isomorphism — the full sense in which `𝕊` is canonical.
-- ===========================================================================

/-- The coproduct (universal) property, packaged: `(T, i₁, i₂)` is A coproduct of the
    curve with itself over `𝔽₁` iff every pair of homs out of the curve factors through
    a mediating hom, uniquely (pointwise). -/
def IsCoproduct (T : CMon) (i1 i2 : MHom Curve T) : Prop :=
  ∀ (U : CMon) (f g : MHom Curve U),
    ∃ h : MHom T U,
      (∀ a, h.map (i1.map a) = f.map a)
      ∧ (∀ b, h.map (i2.map b) = g.map b)
      ∧ ∀ h' : MHom T U,
          (∀ a, h'.map (i1.map a) = f.map a) → (∀ b, h'.map (i2.map b) = g.map b) →
          ∀ t, h'.map t = h.map t

/-- **`𝕊` IS the coproduct** — the canonicality of the construction, as a single
    proposition (assembling `copair_inl`, `copair_inr`, `copair_unique`). -/
theorem sq_isCoproduct : IsCoproduct Sq inl inr := by
  intro U f g
  exact ⟨copair U f g, copair_inl U f g, copair_inr U f g,
    fun h' hl hr z => copair_unique U f g h' hl hr z⟩

/-- **UNIQUENESS UP TO CANONICAL ISOMORPHISM**: any other coproduct `(T, i₁, i₂)` of the
    curve with itself over `𝔽₁` is isomorphic to `𝕊` — the canonical mediating homs
    `φ : 𝕊 → T` and `ψ : T → 𝕊` are mutually inverse and `φ` matches the injections. So
    "the" tensor `F ⊗_𝔽₁ F` is well-defined: `𝕊` is not one model among many but the
    object itself, up to unique isomorphism. -/
theorem coproduct_unique_upto_iso (T : CMon) (i1 i2 : MHom Curve T)
    (hT : IsCoproduct T i1 i2) :
    ∃ (φ : MHom Sq T) (ψ : MHom T Sq),
      (∀ z, ψ.map (φ.map z) = z) ∧ (∀ t, φ.map (ψ.map t) = t)
      ∧ (∀ a, φ.map (inl.map a) = i1.map a) ∧ (∀ b, φ.map (inr.map b) = i2.map b) := by
  obtain ⟨ψ, hψ1, hψ2, _⟩ := hT Sq inl inr
  refine ⟨copair T i1 i2, ψ, ?_, ?_, copair_inl T i1 i2, copair_inr T i1 i2⟩
  · -- ψ ∘ φ = id on 𝕊, by the tensor decomposition z = z₁ ⊗ z₂
    intro z
    show ψ.map (T.mul (i1.map z.1) (i2.map z.2)) = z
    rw [show ψ.map (T.mul (i1.map z.1) (i2.map z.2))
          = Sq.mul (ψ.map (i1.map z.1)) (ψ.map (i2.map z.2)) from ψ.map_mul _ _,
      hψ1 z.1, hψ2 z.2]
    exact (sq_factor z).symm
  · -- φ ∘ ψ = id on T, by T's OWN uniqueness clause: both mediate (i₁, i₂) over T
    obtain ⟨θ, _, _, hθu⟩ := hT T i1 i2
    intro t
    have hid := hθu (idHom T) (fun _ => rfl) (fun _ => rfl)
    have hco := hθu (compHom ψ (copair T i1 i2))
      (fun a => by
        show (copair T i1 i2).map (ψ.map (i1.map a)) = i1.map a
        rw [hψ1 a]
        exact copair_inl T i1 i2 a)
      (fun b => by
        show (copair T i1 i2).map (ψ.map (i2.map b)) = i2.map b
        rw [hψ2 b]
        exact copair_inr T i1 i2 b)
    show (copair T i1 i2).map (ψ.map t) = t
    exact (hco t).trans (hid t).symm

/-- The first projection retracts the first injection: `proj1 ∘ inl = id` —
    the square's first structural map recovers the curve. -/
theorem proj1_inl (a : MPos) : proj1.map (inl.map a) = a := rfl

/-- The second projection retracts the second injection: `proj2 ∘ inr = id`. -/
theorem proj2_inr (b : MPos) : proj2.map (inr.map b) = b := rfl

/-- The projections are JOINTLY FAITHFUL: a point of `𝕊` is determined by its two
    curve coordinates (the point set is exactly `C × C`, T1). -/
theorem proj_faithful (z w : Sq.carrier)
    (h1 : proj1.map z = proj1.map w) (h2 : proj2.map z = proj2.map w) : z = w := by
  cases z; cases w
  cases h1; cases h2
  rfl

end UOR.Bridge.F1Square.Square
