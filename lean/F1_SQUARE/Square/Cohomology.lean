/-
F1 square — v0.20.0 stage F, brick A1: **the canonical `H¹`-object, named by its universal
property** — the Frobenius orbit of the fundamental spectral class.

Companion ROADMAP §F (Group A, brick A1). The crux's geometric face is the Hodge index of the
`H¹`-bearing pairing of `𝕊` (T4/T5). v0.18.0 carried that `H¹` as INTERFACE data
(`Square.SpectralSquare`, whose dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` is a structure FIELD). Group A
removes the dictionary as an input and *derives* it; this first brick names the object the
derivation runs on, the same way `Square.Tensor` named `𝕊` itself — by a universal property,
not by a hand-picked model.

THE CANONICAL OBJECT. The genuine `H¹` carries the scaling/Frobenius action with spectrum the
zeta zeros (T4). What is canonically CONSTRUCTIBLE — and all the dictionary derivation needs —
is the abstract carrier of that action: the **free Frobenius system on one generator**. A
Frobenius system `(M, φ, g)` is a carrier with a designated endomorphism `φ` (the scaling
shift) and a base point `g` (the fundamental class `C₁`); the canonical `H¹` is the free one,
`(ℕ, succ, 0)`, whose orbit `{φⁿ g}` is the primitive spectral classes `{Cₙ₊₁}`. Its universal
property (`H1_universal`, `H1_isFree`, `freeFrob_unique_upto_iso`) pins it exactly as
`Square.sq_isCoproduct`/`coproduct_unique_upto_iso` pinned `𝕊`: it is THE object with the
property, unique up to unique isomorphism — not a candidate.

THE ARITHMETIC TIE (the orbit IS the built pencil). At a prime `p` the Frobenius-at-`p` orbit
realizes as the prime-power pencil `{Γ_{pᵏ}}` of `Square.Pencil`: the `k`-th orbit class sits
at log-separation `k·log p = k·Λ(pᵏ)` from the diagonal (`orbit_shiftLength`, from the built
`pencil_separation_pow_vonMangoldt`) — the Connes–Consani closed orbit of length `log p`
traversed `k` times. So the abstract free system is not free-floating: its action is the
constructed scaling flow, and its shift lengths are the explicit-formula weights `Λ`.

HONEST SCOPE. This names and characterizes the carrier; it asserts NOTHING about positivity.
The trace datum that breaks pencil-blindness (A2) and the forced dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ`
(A3) are the next bricks; the forced signature (= RH) is Group B. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Pencil

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- A **Frobenius system** `(M, φ, g)`: a carrier `M` with a designated endomorphism `φ` (the
    scaling/Frobenius shift) and a base point `g` (the fundamental spectral class `C₁`). The
    canonical `H¹` is the FREE such system on one generator (`H1` below). -/
structure FrobSys where
  /-- the carrier (the spectral classes) -/
  carrier : Type
  /-- the Frobenius/scaling action -/
  phi : carrier → carrier
  /-- the fundamental class `C₁` -/
  g : carrier

/-- The **Frobenius orbit** of the fundamental class: `orbit S n = φⁿ(g)`. The orbit IS the
    family of primitive spectral classes (`Cₙ₊₁ = orbit n`). -/
def FrobSys.orbit (S : FrobSys) : Nat → S.carrier
  | 0 => S.g
  | n + 1 => S.phi (S.orbit n)

/-- A **morphism of Frobenius systems**: a map intertwining the actions and preserving the
    fundamental class (an equivariant pointed map). -/
structure FrobHom (S T : FrobSys) where
  /-- the underlying map of carriers -/
  map : S.carrier → T.carrier
  /-- preserves the fundamental class -/
  map_g : map S.g = T.g
  /-- intertwines the Frobenius actions -/
  map_phi : ∀ x, map (S.phi x) = T.phi (map x)

/-- **THE CANONICAL `H¹`-OBJECT**: carrier `ℕ` (the pencil index, `Cₙ₊₁ ↔ n`), Frobenius the
    shift `n ↦ n+1`, fundamental class `C₁ ↔ 0`. The free Frobenius system on one generator. -/
def H1 : FrobSys where
  carrier := Nat
  phi := Nat.succ
  g := 0

/-- On `H1` the orbit is the identity: `orbit n = n` (the index IS the orbit position). -/
theorem H1_orbit (n : Nat) : H1.orbit n = n := by
  induction n with
  | zero => rfl
  | succ k ih => show Nat.succ (H1.orbit k) = k + 1; rw [ih]

/-- The canonical mediating morphism `H1 → T`: the orbit map of `T`. -/
def H1.mediate (T : FrobSys) : FrobHom H1 T where
  map := T.orbit
  map_g := rfl
  map_phi := fun _ => rfl

/-- **THE UNIVERSAL PROPERTY** (uniqueness): every Frobenius morphism out of `H1` IS the orbit
    map — `h.map n = φ_T^n(g_T)`. Together with `H1.mediate` (existence) this is the freeness:
    `H1` is the free Frobenius system on one generator, so a morphism out of it is exactly a
    choice of image of the fundamental class, with the orbit determined by equivariance. -/
theorem H1_universal (T : FrobSys) (h : FrobHom H1 T) : ∀ n, h.map n = T.orbit n := by
  intro n
  induction n with
  | zero => exact h.map_g
  | succ k ih =>
      have hp : h.map (H1.phi k) = T.phi (h.map k) := h.map_phi k
      show h.map (k + 1) = T.phi (T.orbit k)
      rw [show (k + 1 : Nat) = H1.phi k from rfl, hp, ih]

/-- The freeness property, packaged as **initiality**: a Frobenius system is free on one
    generator iff every Frobenius system receives a UNIQUE morphism from it (a morphism is
    forced — it must send the fundamental class to the target's and intertwine the actions,
    which determines it on the whole orbit). This is the exact analog of `IsCoproduct` for
    the one-generator free object. -/
def IsFreeFrob (T : FrobSys) : Prop :=
  ∀ U : FrobSys, ∃ h : FrobHom T U, ∀ h' : FrobHom T U, ∀ x, h'.map x = h.map x

/-- **`H1` IS THE FREE Frobenius system on one generator** (initial) — its canonicality as a
    single proposition. Existence is `H1.mediate`; uniqueness is `H1_universal` (any morphism
    out of `H1` agrees with the orbit map on every `n = orbit n`, hence on every element). -/
theorem H1_isFree : IsFreeFrob H1 := by
  intro U
  refine ⟨H1.mediate U, ?_⟩
  intro h' x
  have e1 : h'.map x = U.orbit x := H1_universal U h' x
  have e2 : (H1.mediate U).map x = U.orbit x := rfl
  rw [e1, e2]

/-- **UNIQUENESS UP TO CANONICAL ISOMORPHISM**: any Frobenius system `T` whose underlying map
    `T.orbit` is a bijection of `ℕ` (i.e. a faithful free realization on one generator) is
    isomorphic to `H1` via the canonical mediating morphisms — so "the" `H¹`-carrier is
    well-defined. (We exhibit the iso through the orbit map and its inverse hypothesis.) -/
theorem freeFrob_unique_upto_iso (T : FrobSys)
    (inv : T.carrier → Nat) (hinv1 : ∀ n, inv (T.orbit n) = n)
    (hinv2 : ∀ x, T.orbit (inv x) = x) :
    ∃ (φ : FrobHom H1 T) (ψ : T.carrier → Nat),
      (∀ n, ψ (φ.map n) = n) ∧ (∀ x, φ.map (ψ x) = x) := by
  refine ⟨H1.mediate T, inv, ?_, ?_⟩
  · intro n
    show inv (T.orbit n) = n
    exact hinv1 n
  · intro x
    show T.orbit (inv x) = x
    exact hinv2 x

-- ===========================================================================
-- The arithmetic tie: the Frobenius orbit IS the built prime-power pencil.
-- ===========================================================================

/-- **The shift-length realization of the canonical `H¹`** at a prime `p`: the orbit position
    `k` is assigned its log-separation `k·log p` from the diagonal. This is the bridge from the
    abstract free action to the constructed scaling flow. -/
def orbitShift (p : Nat) (hp : 1 ≤ p) (k : Nat) : Real := Rnsmul k (logN p hp)

/-- **The realization is Frobenius-EQUIVARIANT**: one Frobenius step adds exactly `log p`,
    `orbitShift(k+1) = log p + orbitShift(k)` — the abstract shift `φ : k ↦ k+1` of `H1`
    realizes as translation by the explicit-formula weight `Λ(p) = log p`. -/
theorem orbitShift_succ (p : Nat) (hp : 1 ≤ p) (k : Nat) :
    Req (orbitShift p hp (k + 1)) (Radd (logN p hp) (orbitShift p hp k)) := by
  show Req (Rnsmul (k + 1) (logN p hp)) (Radd (logN p hp) (Rnsmul k (logN p hp)))
  rw [Rnsmul_succ]
  exact Req_refl _

/-- **THE ORBIT REALIZES THE BUILT PENCIL** (the arithmetic content of A1), as ONE structural
    identification — not a pair of separate facts: the log-separation of the built pencil
    member `Γ_{pᵏ}` (any point of `graph (pᵏ)`) from the diagonal EQUALS the shift-length
    realization `orbitShift p (H1.orbit k)` of the `k`-th orbit position (`H1.orbit k = k`
    feeding the abstract orbit into the geometry). With `orbitShift_succ`, the abstract free
    `H1`-action IS the constructed scaling flow, shift length `log p = Λ(pᵏ)` per step — the
    Connes–Consani closed orbit of length `log p` traversed `k` times
    (`Square.pencil_separation_pow`). -/
theorem orbit_realizes_pencil (p : Nat) (hp2 : 2 ≤ p) (k : Nat) (hpk : 1 ≤ p ^ k)
    (z : SqPt) (hz : graph (p ^ k) z) :
    Req (Rsub (logN z.2.val z.2.property) (logN z.1.val z.1.property))
      (orbitShift p (by omega) (H1.orbit k)) := by
  rw [H1_orbit]
  exact pencil_separation_pow p (by omega) k hpk z hz

end UOR.Bridge.F1Square.Square
