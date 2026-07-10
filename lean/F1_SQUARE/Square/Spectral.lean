/-
F1 square — v0.18.0 stage D, brick 3: the SPECTRAL SQUARE interface and **the bridge** —
the geometric and analytic faces of the crux are equivalent, as a theorem.

THE OBJECT (interface). v0.17.0 proved that canonical `𝕊`'s coarse numerical lattice is
pencil-blind (`Square.square_hodge_pencil_blind`): the trace datum that the function-field
mechanism runs on (`BridgeFF.ff_trace_datum`: `Δ·Γ = q+1−a` INSIDE the lattice) is absent,
relocated to the spectral side (T4: the `H¹` on which the scaling flow acts with spectrum =
the zeta zeros). `SpectralSquare` is that enrichment as an interface: it carries
  • `lam` — the Li/trace data of `H¹` (for the GENUINE instance, the Li coefficients
    `λₙ = Σ_ρ [1 − (1−1/ρ)ⁿ]` of ζ);
  • `cSq` — the self-intersections `⟨Cₙ, Cₙ⟩` of the primitive spectral classes;
  • `dict` — THE DICTIONARY: `⟨Cₙ, Cₙ⟩ = −2λₙ`, the Deninger-type Hodge-index reading of
    Li's criterion, stated here as INTERFACE DATA because that is its verified status: the
    number-field dictionary is conjectural, recorded by Connes–Consani (Selecta Math. 27
    (2021), art. 77 — the scaling kernel "corresponds geometrically to the divisor of the
    Frobenius correspondence", with the square's intersection theory explicitly "not yet
    in shape" for the explicit formula's principal values). The normalization is the
    function-field model's own: `BridgeFF.primDG_sq` gives `D°² = −2·(Hasse form)` — the
    `−2` is the lattice's, not a choice. For ζ the chain "RH ⟺ Weil positivity ⟺
    λₙ > 0 ∀n" is CLASSICAL: Weil 1952 (test class `C_c^∞(0,∞)`, the restricted-class
    equivalence proved directly by Burnol, arXiv math/9810169); Bombieri, *Remarks on
    Weil's quadratic functional*, Rend. Mat. Acc. Lincei 11 (2000) (the iff, and the
    finite Hermitian truncations); Li, J. Number Theory 65 (1997) (strict `λₙ > 0 ∀n ⟺
    RH`); Bombieri–Lagarias, J. Number Theory 77 (1999) (`λₙ` as the Guinand–Weil
    explicit-formula functional at specific test functions).

THE BRIDGE (theorems, the stage-D release goal): for ANY spectral square,
    `spectral_bridge_nonneg` :  Hodge-index negativity (semidefinite face) ⟺ `Li.LiNonneg lam`
    `spectral_bridge_pos`    :  Hodge-index negativity (definite face)     ⟺ `Li.LiPositive lam`
    `crux_faces_equivalent`  :  `SpectralCrux S ⟺ Li.LiCrux S.lam`
— the geometric and analytic faces of the crux are THE SAME proposition through the
dictionary. The equivalence is a genuine constructive theorem (the order algebra
`−2λ ≤ 0 ⟺ λ ≥ 0` on Bishop reals, with the doubling lemmas proved at sequence level).

FAITHFULNESS (the standing cautions, all enforced):
  • The crux is `SpectralCrux` of the GENUINE instance — whose `lam` is the Li sequence of
    ζ and whose `cSq` comes from the actual `H¹` pairing. NEITHER is constructed here
    (`T4`/§3.4: that construction is the program's remaining frontier). The fields
    `hodgeIndexHolds`/`liPositivityHolds` stay `none`.
  • `spectralTwoSlice` below is the INHABITING instance: its `lam` carries the genuine
    certified `λ₁, λ₂` (v0.14.0/v0.16.0; certified `λ₁ ≥ 0.0042`, `λ₂ ≥ 0.0043` — the
    true values are `λ₁ ≈ 0.0230957`, `λ₂ ≈ 0.0923457`, Keiper 1992/Coffey 2005,
    independently re-verified) and its `cSq` is defined THROUGH the dictionary —
    it demonstrates the interface is real and gives the geometric face its first two
    genuine negativity slices (`spectral_evidence_two`). It is NOT the crux, and that is
    itself a THEOREM (`spectralTwoSlice_not_crux`: its `n ≥ 3` slices vanish, so its
    strict positivity provably FAILS — no instance built from finitely many certified
    slices can be passed off as RH).
  • The finite-check guard transfers to the geometric face (`spectral_iff_all_upTo`):
    no finite run of negativity checks reaches the crux.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.LiTwo
import F1Square.Li

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **The spectral enrichment of `𝕊`** (interface): the Li/trace data `lam` of `H¹`, the
    primitive-class self-intersections `cSq`, and the dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ`
    (see the module docstring for provenance and normalization). -/
structure SpectralSquare where
  /-- the Li/trace data attached to `H¹` (`λₙ` for the genuine instance) -/
  lam : Nat → Real
  /-- the self-intersection `⟨Cₙ, Cₙ⟩` of the `n`-th primitive spectral class -/
  cSq : Nat → Real
  /-- the dictionary: `⟨Cₙ, Cₙ⟩ = −2λₙ` (the Deninger-type Hodge-index reading of Li's
      criterion — conjectural at number fields, hence interface DATA, per the verified
      Connes–Consani 2021 account; normalized as `BridgeFF.primDG_sq` derives on the
      function-field model) -/
  dict : ∀ n : Nat, 0 < n → Req (cSq n) (Rneg (Radd (lam n) (lam n)))

-- ===========================================================================
-- The constructive doubling lemmas (`2x ≥ 0 ⟺ x ≥ 0`, `2x > 0 ⟺ x > 0`).
-- ===========================================================================

private theorem radd_sub_cancel_left (x c : Real) : Req (Rsub (Radd x c) x) c := by
  refine Req_trans (Rsub_congr (Req_refl (Radd x c)) (Req_symm (Radd_zero x))) ?_
  refine Req_trans (Rsub_Radd_Radd x c x zero) ?_
  refine Req_trans (Radd_congr (Radd_neg x) (Rsub_zero c)) ?_
  exact Req_trans (Radd_comm zero c) (Radd_zero c)

/-- `x > 0 ⟹ x + x > 0` (monotonicity: `x + x ≥ x`). -/
theorem Pos_Radd_self {x : Real} (h : Pos x) : Pos (Radd x x) := by
  refine Pos_mono (Rle_of_Rnonneg_Rsub ?_) h
  exact Rnonneg_congr (Req_symm (radd_sub_cancel_left x x)) (Rnonneg_of_Pos h)

private theorem double_key_int (T D N : Int) :
    (T * D + T * D) * (N + 1) = T * (2 * N + 2) * D := by
  ring_uor

/-- `x + x > 0 ⟹ x > 0`, at the sequence level: a witness `1/(n+1) < 2·x_{2n+1}` yields the
    witness `1/(2n+2) < x_{2n+1}` (the `Radd` reindex is `2n+1`). -/
theorem Pos_of_Radd_self {x : Real} (h : Pos (Radd x x)) : Pos x := by
  obtain ⟨n, hn⟩ := h
  refine ⟨2 * n + 1, ?_⟩
  -- hn : Qlt ⟨1, n+1⟩ (add t t) with t = x.seq (2n+1); goal : Qlt ⟨1, 2n+2⟩ t
  simp only [Qlt, Radd, add, Qbound] at hn ⊢
  push_cast at hn ⊢
  rw [double_key_int] at hn
  -- hn : td·td < (tn·(2n+2))·td  ⟹ cancel td:  td < tn·(2n+2)
  have hdle : (0 : Int) ≤ ((x.seq (2 * n + 1)).den : Int) := by exact_mod_cast Nat.zero_le _
  have hn' : ((x.seq (2 * n + 1)).den : Int) * ((x.seq (2 * n + 1)).den : Int)
      < ((x.seq (2 * n + 1)).num * (2 * (n : Int) + 2)) * ((x.seq (2 * n + 1)).den : Int) := by
    omega
  have hlt := Int.lt_of_mul_lt_mul_right hn' hdle
  have e : 2 * (n : Int) + 1 + 1 = 2 * (n : Int) + 2 := by omega
  rw [e]
  omega

/-- `x ≥ 0 ⟹ x + x ≥ 0`. -/
theorem Rnonneg_Radd_self {x : Real} (h : Rnonneg x) : Rnonneg (Radd x x) :=
  Rnonneg_Radd h h

/-- `x + x ≥ 0 ⟹ x ≥ 0` (halve: `x ≈ ½(x+x)`). -/
theorem Rnonneg_of_Radd_self {x : Real} (h : Rnonneg (Radd x x)) : Rnonneg x := by
  refine Rnonneg_congr ?_ (Rhalf_nonneg h)
  exact Req_trans (Rhalf_Radd x x) (Rhalf_double x)

-- ===========================================================================
-- The two faces and THE BRIDGE.
-- ===========================================================================

/-- The geometric face, semidefinite form: every primitive spectral class has
    non-positive self-intersection — `−⟨Cₙ,Cₙ⟩ ≥ 0` for all `n ≥ 1` (the Hodge-index
    negativity on the spectral enrichment; the constructive statement of `⟨Cₙ,Cₙ⟩ ≤ 0`). -/
def SpectralHodgeNeg (S : SpectralSquare) : Prop :=
  ∀ n : Nat, 0 < n → Rnonneg (Rneg (S.cSq n))

/-- The geometric face, definite form: `−⟨Cₙ,Cₙ⟩ > 0` for all `n ≥ 1`. -/
def SpectralHodgeNegStrict (S : SpectralSquare) : Prop :=
  ∀ n : Nat, 0 < n → Pos (Rneg (S.cSq n))

private theorem neg_cSq_eq_double (S : SpectralSquare) (n : Nat) (hn : 0 < n) :
    Req (Radd (S.lam n) (S.lam n)) (Rneg (S.cSq n)) :=
  Req_trans (Req_symm (Rneg_Rneg (Radd (S.lam n) (S.lam n)))) (Rneg_congr (Req_symm (S.dict n hn)))

/-- **THE BRIDGE, semidefinite form** (the stage-D equivalence, non-strict face): for any
    spectral square, Hodge-index negativity of the primitive classes is EQUIVALENT to
    Li non-negativity of its trace data — `⟨Cₙ,Cₙ⟩ ≤ 0 ∀n ⟺ λₙ ≥ 0 ∀n`. (For the genuine
    instance both sides are RH: Bombieri–Lagarias 1999 on the right.) -/
theorem spectral_bridge_nonneg (S : SpectralSquare) :
    SpectralHodgeNeg S ↔ LiNonneg S.lam := by
  constructor
  · intro h n hn
    refine Rnonneg_of_Radd_self (x := S.lam n) ?_
    exact Rnonneg_congr (Req_symm (neg_cSq_eq_double S n hn)) (h n hn)
  · intro h n hn
    exact Rnonneg_congr (neg_cSq_eq_double S n hn) (Rnonneg_Radd_self (h n hn))

/-- The bridge, one slice at a time: `⟨Cₙ,Cₙ⟩ < 0 ⟺ λₙ > 0` for each individual `n ≥ 1`. -/
theorem spectral_bridge_pos_slice (S : SpectralSquare) (n : Nat) (hn : 0 < n) :
    Pos (Rneg (S.cSq n)) ↔ Pos (S.lam n) := by
  constructor
  · intro h
    refine Pos_of_Radd_self (x := S.lam n) ?_
    exact Pos_congr (Req_symm (neg_cSq_eq_double S n hn)) h
  · intro h
    exact Pos_congr (neg_cSq_eq_double S n hn) (Pos_Radd_self h)

/-- **THE BRIDGE, definite form** (the strict face): `⟨Cₙ,Cₙ⟩ < 0 ∀n ⟺ λₙ > 0 ∀n`
    (for the genuine instance the right side is Li's criterion, Li 1997 — RH). -/
theorem spectral_bridge_pos (S : SpectralSquare) :
    SpectralHodgeNegStrict S ↔ LiPositive S.lam := by
  constructor
  · intro h n hn
    exact (spectral_bridge_pos_slice S n hn).mp (h n hn)
  · intro h n hn
    exact (spectral_bridge_pos_slice S n hn).mpr (h n hn)

/-- **THE CRUX, geometric face on the spectral enrichment**: strict Hodge-index negativity.
    For the GENUINE instance (the unbuilt `H¹` pairing with the Li data of ζ) this is RH. -/
def SpectralCrux (S : SpectralSquare) : Prop := SpectralHodgeNegStrict S

/-- **THE TWO FACES OF THE CRUX ARE EQUIVALENT** — the v0.18.0 release goal: for any
    spectral square, the geometric crux (`SpectralCrux`, Hodge-index negativity) and the
    analytic crux (`Li.LiCrux`, Li positivity) are the same proposition through the
    dictionary. The links: this equivalence is a constructive THEOREM; the identification
    of the genuine instance's `lam` with the Li coefficients of ζ and of `LiCrux λ` with
    RH is CLASSICAL (Li 1997, Bombieri–Lagarias 1999); the genuine `cSq`/`H¹` is the open
    construction (T4/§3.4). The crux itself stays OPEN — fields `none`. -/
theorem crux_faces_equivalent (S : SpectralSquare) :
    SpectralCrux S ↔ LiCrux S.lam :=
  spectral_bridge_pos S

-- ===========================================================================
-- The inhabiting instance (genuine λ₁, λ₂), its evidence, and its honesty guards.
-- ===========================================================================

/-- The two-slice spectral square: `lam` is the v0.18.0 realized Li sequence (genuine
    `λ₁, λ₂`; trivial-split values beyond), `cSq` is defined THROUGH the dictionary.
    This inhabits the interface and carries the genuine slices; the GENUINE instance
    differs exactly where `H¹` is needed (its `cSq` comes from the actual pairing, its
    `lam` from the actual zeros). NOT the crux — see `spectralTwoSlice_not_crux`. -/
def spectralTwoSlice : SpectralSquare where
  lam := liLamSeqTwo
  cSq := fun n => Rneg (Radd (liLamSeqTwo n) (liLamSeqTwo n))
  dict := fun _ _ => Req_refl _

/-- **The geometric face's first two genuine negativity slices** (the stage-D evidence):
    the primitive classes attached to the certified `λ₁` and `λ₂` (certified lower bounds
    `0.0042` and `0.0043`; true values `≈ 0.0231` and `≈ 0.0923`) have strictly negative
    self-intersection — `⟨C₁,C₁⟩ < 0` and `⟨C₂,C₂⟩ < 0`, through the bridge from
    `Rlambda1_pos`/`Rlambda2_pos`. Evidence, not the crux. -/
theorem spectral_evidence_two :
    Pos (Rneg (spectralTwoSlice.cSq 1)) ∧ Pos (Rneg (spectralTwoSlice.cSq 2)) := by
  constructor
  · exact Pos_congr (neg_cSq_eq_double spectralTwoSlice 1 (by omega))
      (Pos_Radd_self liTwo_evidence.1)
  · exact Pos_congr (neg_cSq_eq_double spectralTwoSlice 2 (by omega))
      (Pos_Radd_self liTwo_evidence.2)

/-- `0 + 0` is not strictly positive (the `n ≥ 3` slices of the two-slice instance vanish). -/
theorem not_Pos_zero_double : ¬ Pos (Radd zero zero) := by
  intro ⟨n, hn⟩
  simp only [Qlt, Radd, add, Qbound, zero_seq] at hn
  omega

/-- **THE HONESTY GUARD, as a theorem**: the two-slice instance provably does NOT satisfy
    the crux — its `n = 3` slice vanishes, so strict positivity FAILS. No instance
    assembled from finitely many certified slices can be passed off as RH; the crux needs
    the GENUINE sequence, all `n`. (The geometric mirror of the `Li` faithfulness caution
    (c)/(d) and of the §2.3 control.) -/
theorem spectralTwoSlice_not_crux : ¬ SpectralCrux spectralTwoSlice := by
  intro h
  have h3 := (spectral_bridge_pos spectralTwoSlice).mp h 3 (by omega)
  have hz : Req (liLamSeqTwo 3) (Radd zero zero) := Req_refl _
  exact not_Pos_zero_double (Pos_congr hz h3)

/-- The template spectral square: the constant-`1` Li data (the geometric mirror of
    `Li.template_liPositive`'s sequence). -/
def spectralTemplate : SpectralSquare where
  lam := fun _ => one
  cSq := fun _ => Rneg (Radd one one)
  dict := fun _ _ => Req_refl _

/-- **THE TWO-SIDEDNESS GUARD**: the geometric crux PROPERTY is satisfiable —
    `SpectralCrux spectralTemplate` holds (the constant-`1` instance has every
    `⟨Cₙ,Cₙ⟩ = −2 < 0`). Two consequences, both load-bearing for honesty:
    (1) the interface contains NO hidden impossibility — the encoding does not bias the
    attempt toward failure; openness is a fact about the GENUINE instance, not a defect of
    the formulation; and (2) the loose existential `∃ S, SpectralCrux S` is TRUE and hence
    NOT RH — the exact geometric mirror of the `Li.template_liPositive` caution: the crux
    must be the genuine instance, never an existential. -/
theorem spectral_template_crux : SpectralCrux spectralTemplate := by
  intro n hn
  exact Pos_congr (neg_cSq_eq_double spectralTemplate n hn) (Pos_Radd_self Pos_one)

/-- The checkable finite approximant of the geometric face. -/
def SpectralHodgeNegUpTo (S : SpectralSquare) (N : Nat) : Prop :=
  ∀ n : Nat, 0 < n → n ≤ N → Rnonneg (Rneg (S.cSq n))

/-- **The finite-check guard transfers to the geometric face**: spectral Hodge negativity
    is exactly the conjunction of ALL its finite truncations — no finite run of negativity
    checks (no `decide` over `n ≤ N`) reaches the crux, exactly as `liPositive_iff_all_upTo`
    on the analytic face. -/
theorem spectral_iff_all_upTo (S : SpectralSquare) :
    SpectralHodgeNeg S ↔ ∀ N, SpectralHodgeNegUpTo S N := by
  constructor
  · intro h _ n hn _
    exact h n hn
  · intro h n hn
    exact h n n hn (Nat.le_refl n)

end UOR.Bridge.F1Square.Square
