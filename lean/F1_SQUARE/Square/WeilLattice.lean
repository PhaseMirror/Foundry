/-
F1 square — v0.20.0 stage F, bricks A2 + A3: **the intrinsic `H¹` lattice and the FORCED
dictionary** — `⟨Cₙ,Cₙ⟩ = −2λₙ` derived from a genuine primitive projection, not assumed.

Companion ROADMAP §F (Group A, bricks A2/A3). v0.18.0's `Square.SpectralSquare` carried the
dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` as a structure FIELD (`dict`), supplied definitionally
(`cSq := −2λ`, `dict := rfl`). These bricks remove that assumption and DERIVE it, mirroring
`BridgeFF` column-for-column: a full Néron–Severi-style lattice with the two rulings, the
primitive projection, the orthogonality theorems (`primDG_perp_h/v`), and the self-pairing
computed from the Gram (`primDG_sq`).

THE LATTICE (A2). `hPair dd gg dg` is the symmetric bilinear form on the rank-4 lattice
`{F_h, F_v, Δ, Γ}` (the two rulings, the diagonal, a pencil member) with the standard
sourced/derived ruling intersections (`F_h² = F_v² = 0`, `F_h·F_v = 1`, `Δ·F_h = Δ·F_v = 1`,
`Γ·F_h = Γ·F_v = 1` — the §2.2 rulings, the PARALLEL pencil meeting each ruling once, recession
`(1,1)`) and the SPECTRAL intersection data carried as parameters: `Δ² = dd`, `Γ² = gg`,
`Δ·Γ = dg`. On `𝕊`'s coarse lattice this spectral data is `Δ² = Γ² = 0`
(`pair_diag_self_derived`, `pair_graph_self_derived` — DERIVED v0.17.0) and `Δ·Γₙ = 0`
(`square_hodge_pencil_blind` — pencil-blind); the `H¹` enrichment lifts `Δ·Γₙ` to the
explicit-formula value `λₙ` (`Square.genuineLamSeq`, built from `Λ` + the archimedean kernel
modulo the Stieltjes tail), leaving `Δ² = Γ² = 0`.

THE FORCED DICTIONARY (A3). The primitive spectral class is the **vanishing cycle**
`Cₙ = Δ − Γₙ` (coordinates `(0,0,1,−1)`). It is GENUINELY PRIMITIVE — orthogonal to both
rulings (`vanCyc_perp_Fh`, `vanCyc_perp_Fv`, for every parameter value, the `primDG_perp`
analog) — not a hand-picked class. Its self-pairing is `Δ² − 2(Δ·Γ) + Γ² = dd + gg − 2·dg`
(`vanCyc_selfpair_gen`, the `primDG_sq` analog). With the genuine geometric inputs
`Δ² = Γ² = 0` TIED to the built lattice (`vanCyc_selfpair_built`) and the trace datum
`Δ·Γₙ = λₙ`, this is `−2λₙ` — DERIVED, the `−2` being the lattice's own cross term.
`genuineSpectralSquare` is then a `SpectralSquare` whose `dict` is this THEOREM, supplied
through the assumption-free `IntrinsicH1` (whose only datum is `lam`; `cSq` is FORCED to the
pairing diagonal, so no false dictionary can be inhabited).

HONEST SCOPE. The trace datum `dg = λₙ` is the genuine closed-form Li value modulo the
Stieltjes tail (`Square.GenuineLi`); its identification with the genuine ζ explicit-formula
trace is [CLASSICAL], and the open content (the tail / the zeros) is untouched. NOTHING here
asserts positivity: `⟨Cₙ,Cₙ⟩ = −2λₙ` is a sign-free identity. The forced signature (= RH) is
Group B; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Spectral
import F1Square.Square.Cohomology
import F1Square.Square.Polarized
import F1Square.Analysis.GenuineLi

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Integer scaling of a constructive real (the bilinear-form coefficients).
-- ===========================================================================

/-- Integer scaling `m • x` of a real, built on `nsmulR` (no scalar layer): non-negative
    coefficients fold through `nsmulR`, negative ones through `Rneg`. -/
def zmulR : Int → Real → Real
  | Int.ofNat n, x => nsmulR n x
  | Int.negSucc n, x => Rneg (nsmulR (n + 1) x)

/-- `0 • x = 0`. -/
theorem zmulR_zero (x : Real) : zmulR 0 x = zero := rfl

/-- `1 • x = x`. -/
theorem zmulR_one (x : Real) : zmulR 1 x = x := rfl

/-- `(−2) • x = −(x + x)` — the cross-term coefficient of the vanishing cycle. -/
theorem zmulR_negTwo (x : Real) : zmulR (-2) x = Rneg (Radd x x) := rfl

/-- The coefficient may be rewritten when two integers are equal (the scaling depends only on
    the integer value). -/
theorem zmulR_congr_coeff {m m' : Int} (h : m = m') (x : Real) : zmulR m x = zmulR m' x := by
  rw [h]

/-- The real image of an integer, `RofInt m = m • 1` — used to feed the built integer-valued
    intersection numbers (`sqPair …`) into the real pairing. -/
def RofInt (m : Int) : Real := zmulR m one

/-- `RofInt 0 = 0`. -/
theorem RofInt_zero : RofInt 0 = zero := rfl

-- ===========================================================================
-- A2: the intrinsic H¹ lattice {F_h, F_v, Δ, Γ} and the trace datum.
-- ===========================================================================

/-- A class on the `H¹`-enriched rank-4 lattice: coordinates `(f, g, c, d)` for
    `f·F_h + g·F_v + c·Δ + d·Γ` (the two rulings, the diagonal, the pencil member). -/
abbrev HCls : Type := Int × Int × Int × Int

/-- The integer ruling part of the Gram (the `0/1` entries `F_h·F_v = Δ·F_h = Δ·F_v =
    Γ·F_h = Γ·F_v = 1`, all the rest of the rulings `0`): the bilinear contraction of the
    sourced/derived ruling intersections. -/
def hRuling (u v : HCls) : Int :=
  u.1 * v.2.1 + u.2.1 * v.1
    + u.2.2.1 * v.1 + u.1 * v.2.2.1
    + u.2.2.1 * v.2.1 + u.2.1 * v.2.2.1
    + u.2.2.2 * v.1 + u.1 * v.2.2.2
    + u.2.2.2 * v.2.1 + u.2.1 * v.2.2.2

/-- The **intrinsic `H¹` pairing** on `{F_h, F_v, Δ, Γ}` with spectral intersection data
    `Δ² = dd`, `Γ² = gg`, `Δ·Γ = dg` (the rulings fixed): the symmetric bilinear form. -/
def hPair (dd gg dg : Real) (u v : HCls) : Real :=
  Radd (Radd (Radd (zmulR (hRuling u v) one) (zmulR (u.2.2.1 * v.2.2.1) dd))
    (zmulR (u.2.2.2 * v.2.2.2) gg))
    (zmulR (u.2.2.1 * v.2.2.2 + u.2.2.2 * v.2.2.1) dg)

/-- The pairing is symmetric (the Gram is). -/
theorem hPair_symm (dd gg dg : Real) (u v : HCls) :
    hPair dd gg dg u v = hPair dd gg dg v u := by
  simp only [hPair]
  rw [zmulR_congr_coeff (show hRuling u v = hRuling v u by simp only [hRuling]; ring_uor) one,
      zmulR_congr_coeff (show u.2.2.1 * v.2.2.1 = v.2.2.1 * u.2.2.1 by ring_uor) dd,
      zmulR_congr_coeff (show u.2.2.2 * v.2.2.2 = v.2.2.2 * u.2.2.2 by ring_uor) gg,
      zmulR_congr_coeff
        (show u.2.2.1 * v.2.2.2 + u.2.2.2 * v.2.2.1 = v.2.2.1 * u.2.2.2 + v.2.2.2 * u.2.2.1
          by ring_uor) dg]

/-- The horizontal ruling `F_h = (1,0,0,0)`. -/
def eFh : HCls := (1, 0, 0, 0)
/-- The vertical ruling `F_v = (0,1,0,0)`. -/
def eFv : HCls := (0, 1, 0, 0)

/-- **The vanishing cycle** `Cₙ = Δ − Γₙ` (coordinates `(0,0,1,−1)`) — the primitive spectral
    class. -/
def vanCyc : HCls := (0, 0, 1, -1)

/-- **The vanishing cycle is GENUINELY PRIMITIVE — orthogonal to the horizontal ruling**:
    `⟨Δ−Γ, F_h⟩ = (Δ·F_h) − (Γ·F_h) = 1 − 1 = 0`, for EVERY value of the spectral data (the
    `BridgeFF.primDG_perp_h` analog — the cycle is projected out of the ample cone, not chosen). -/
theorem vanCyc_perp_Fh (dd gg dg : Real) : Req (hPair dd gg dg vanCyc eFh) zero := by
  simp only [hPair]
  rw [zmulR_congr_coeff (show hRuling vanCyc eFh = 0 by decide) one,
      zmulR_congr_coeff (show vanCyc.2.2.1 * eFh.2.2.1 = 0 by decide) dd,
      zmulR_congr_coeff (show vanCyc.2.2.2 * eFh.2.2.2 = 0 by decide) gg,
      zmulR_congr_coeff (show vanCyc.2.2.1 * eFh.2.2.2 + vanCyc.2.2.2 * eFh.2.2.1 = 0 by decide) dg,
      zmulR_zero, zmulR_zero, zmulR_zero, zmulR_zero]
  exact Req_trans (Radd_zero _) (Req_trans (Radd_zero _) (Radd_zero zero))

/-- **The vanishing cycle is orthogonal to the vertical ruling** too: `⟨Δ−Γ, F_v⟩ = 0`
    (`BridgeFF.primDG_perp_v` analog). With `vanCyc_perp_Fh`, `Δ−Γ` lies in the primitive
    complement of the ample cone — it is the genuine primitive class. -/
theorem vanCyc_perp_Fv (dd gg dg : Real) : Req (hPair dd gg dg vanCyc eFv) zero := by
  simp only [hPair]
  rw [zmulR_congr_coeff (show hRuling vanCyc eFv = 0 by decide) one,
      zmulR_congr_coeff (show vanCyc.2.2.1 * eFv.2.2.1 = 0 by decide) dd,
      zmulR_congr_coeff (show vanCyc.2.2.2 * eFv.2.2.2 = 0 by decide) gg,
      zmulR_congr_coeff (show vanCyc.2.2.1 * eFv.2.2.2 + vanCyc.2.2.2 * eFv.2.2.1 = 0 by decide) dg,
      zmulR_zero, zmulR_zero, zmulR_zero, zmulR_zero]
  exact Req_trans (Radd_zero _) (Req_trans (Radd_zero _) (Radd_zero zero))

/-- The vanishing-cycle self-pairing, in general spectral data: since `Δ−Γ` is primitive
    (`vanCyc_perp_Fh/v`), the ruling part drops and `⟨Δ−Γ, Δ−Γ⟩ = Δ² − 2(Δ·Γ) + Γ²
    = dd + gg − (dg + dg)` — the `BridgeFF.primDG_sq` analog. -/
theorem vanCyc_selfpair_gen (dd gg dg : Real) :
    Req (hPair dd gg dg vanCyc vanCyc) (Radd (Radd dd gg) (Rneg (Radd dg dg))) := by
  simp only [hPair]
  rw [zmulR_congr_coeff (show hRuling vanCyc vanCyc = 0 by decide) one,
      zmulR_congr_coeff (show vanCyc.2.2.1 * vanCyc.2.2.1 = 1 by decide) dd,
      zmulR_congr_coeff (show vanCyc.2.2.2 * vanCyc.2.2.2 = 1 by decide) gg,
      zmulR_congr_coeff
        (show vanCyc.2.2.1 * vanCyc.2.2.2 + vanCyc.2.2.2 * vanCyc.2.2.1 = -2 by decide) dg,
      zmulR_zero, zmulR_one, zmulR_one, zmulR_negTwo]
  exact Radd_congr
    (Radd_congr (Req_trans (Radd_comm zero dd) (Radd_zero dd)) (Req_refl gg))
    (Req_refl (Rneg (Radd dg dg)))

/-- **A2, pencil-blindness on the coarse lattice**: with the coarse spectral data
    `Δ² = Γ² = Δ·Γ = 0` (`pair_diag_self_derived`/`pair_graph_self_derived`/
    `square_hodge_pencil_blind`), the vanishing cycle is NULL — `⟨Δ−Γ, Δ−Γ⟩ = 0`. No spectral
    content. -/
theorem vanCyc_blind : Req (hPair zero zero zero vanCyc vanCyc) zero := by
  refine Req_trans (vanCyc_selfpair_gen zero zero zero) ?_
  refine Req_trans (Radd_congr (Radd_zero zero) ?_) (Radd_zero zero)
  exact Req_trans (Rneg_congr (Radd_zero zero)) Rneg_zero

-- ===========================================================================
-- A3: the FORCED dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` and `genuineSpectralSquare`.
-- ===========================================================================

/-- **A3, the forced dictionary at the trace datum**: with the genuine geometric inputs
    `Δ² = Γ² = 0` and the trace datum `Δ·Γₙ = t`, the vanishing-cycle self-pairing is `−2t` —
    DERIVED from the primitive projection (`dd + gg − 2dg` at `dd = gg = 0`), the `−2` being
    the lattice's own cross term. This is the dictionary, as a computation. -/
theorem vanCyc_selfpair (t : Real) :
    Req (hPair zero zero t vanCyc vanCyc) (Rneg (Radd t t)) := by
  refine Req_trans (vanCyc_selfpair_gen zero zero t) ?_
  refine Req_trans (Radd_congr (Radd_zero zero) (Req_refl (Rneg (Radd t t)))) ?_
  exact Req_trans (Radd_comm zero (Rneg (Radd t t))) (Radd_zero (Rneg (Radd t t)))

/-- **A3, the geometric inputs `Δ² = Γ² = 0` TIED TO THE BUILT LATTICE** (not plugged): feeding
    the v0.17.0 DERIVED self-intersections `sqPair clsDiag clsDiag` (`= 0`,
    `pair_diag_self_derived`) and `sqPair (clsGraph n) (clsGraph n)` (`= 0`,
    `pair_graph_self_derived`) as `Δ²` and `Γ²`, the vanishing-cycle self-pairing at the trace
    datum `t` is `−2t`. So the `dd = gg = 0` in `vanCyc_selfpair` is the constructed lattice's
    own value, derived — not an assumption. -/
theorem vanCyc_selfpair_built (n : Nat) (t : Real) :
    Req (hPair (RofInt (sqPair clsDiag clsDiag)) (RofInt (sqPair (clsGraph n) (clsGraph n))) t
        vanCyc vanCyc)
      (Rneg (Radd t t)) := by
  rw [(pair_diag_self_derived).1, (pair_graph_self_derived n n).1, RofInt_zero]
  exact vanCyc_selfpair t

/-- **THE INTRINSIC `H¹` SQUARE — assumption-free by construction.** Its ONLY datum is the
    trace data `lam` (the per-class value `Δ·Γₙ = λₙ`); there is NO dictionary field to supply.
    Contrast `SpectralSquare`, whose `dict : ⟨Cₙ,Cₙ⟩ = −2λₙ` is a structure FIELD an instance
    could satisfy with any `cSq` (e.g. `cSq := −2λ` by `rfl`). Here `cSq` is FORCED to be the
    intrinsic-pairing diagonal (at the built geometric inputs `Δ² = Γ² = 0`) and the dictionary
    is FORCED to be a theorem (`intrinsicH1_dict`). This is the structural elimination of the
    v0.18.0 interface assumption: not that a true dictionary is supplied, but that no false one
    CAN be. -/
structure IntrinsicH1 where
  /-- the trace data of the `H¹` pairing: `Δ·Γₙ = λₙ` (the explicit-formula value) -/
  lam : Nat → Real

/-- The self-intersection `⟨Cₙ,Cₙ⟩`, FORCED to be the primitive-projection diagonal at the
    trace datum (not free data). -/
def IntrinsicH1.cSq (M : IntrinsicH1) (n : Nat) : Real :=
  hPair zero zero (M.lam n) vanCyc vanCyc

/-- **The dictionary is a THEOREM, not a field**: `⟨Cₙ,Cₙ⟩ = −2λₙ` holds for every intrinsic
    `H¹` square by the vanishing-cycle computation — there is no way to inhabit `IntrinsicH1`
    with a different self-pairing. -/
theorem intrinsicH1_dict (M : IntrinsicH1) (n : Nat) :
    Req (M.cSq n) (Rneg (Radd (M.lam n) (M.lam n))) :=
  vanCyc_selfpair (M.lam n)

/-- The forgetful map to the v0.18.0 interface: an intrinsic `H¹` square IS a `SpectralSquare`,
    with its `dict` field discharged by the theorem `intrinsicH1_dict` (never assumed). So every
    bridge theorem about `SpectralSquare` applies, with no assumption introduced. -/
def IntrinsicH1.toSpectral (M : IntrinsicH1) : SpectralSquare where
  lam := M.lam
  cSq := M.cSq
  dict := fun n _ => intrinsicH1_dict M n

/-- **THE GENUINE SPECTRAL SQUARE** — the `H¹` enrichment as an assumption-free CONSTRUCTION:
    the intrinsic `H¹` square on the genuine closed-form Li sequence (`Square.genuineLamSeq`,
    built from `Λ` + archimedean kernel modulo the Stieltjes tail), forgotten to a
    `SpectralSquare`. `lam` is the only datum; `cSq` is the primitive-projection diagonal at the
    trace datum `Δ·Γₙ = λₙ`; the dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` is the THEOREM `intrinsicH1_dict`,
    not a field. This is the v0.18.0 bridge's interface converted to construction (ROADMAP §F,
    A3). -/
def genuineSpectralSquare (E : StieltjesEta) : SpectralSquare :=
  (IntrinsicH1.mk (genuineLamSeq E.eta)).toSpectral

/-- The construction's `lam` IS the genuine closed-form Li sequence (definitional check). -/
theorem genuineSpectralSquare_lam (E : StieltjesEta) (n : Nat) :
    (genuineSpectralSquare E).lam n = genuineLamSeq E.eta n := rfl

/-- **THE DICTIONARY IS DERIVED, not assumed**: on `genuineSpectralSquare`, the geometric
    self-intersection of the vanishing cycle equals `−2λₙ` BY the pairing computation — the
    `cSq` is the `hPair` diagonal at the trace datum, never the sequence `−2λ` plugged in by
    hand. -/
theorem genuineSpectralSquare_dict (E : StieltjesEta) (n : Nat) :
    Req ((genuineSpectralSquare E).cSq n)
      (Rneg (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))) :=
  vanCyc_selfpair (genuineLamSeq E.eta n)

end UOR.Bridge.F1Square.Square
