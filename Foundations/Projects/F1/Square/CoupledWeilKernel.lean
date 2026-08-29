/-
F1 square — **the coupled Weil kernel: the off-diagonal assembly** (`CoupledWeilKernel.lean`),
closing the step 3→4 "diagonal-only" gap at the OBJECT level. Until now the only Weil kernel ever
instantiated was the strictly-diagonal `multForm α` (SonineProjection.lean), whose off-diagonal
vanishes by sifting; the prime side `weilPrimePart` was a SCALAR per single test. This file assembles
the genuine OFF-DIAGONAL coupled kernel

    `coupledWeil arch w v M (i,j) = (multForm arch)(i,j) − primeGram w v M (i,j)`,

the archimedean diagonal multiplier MINUS the **prime Gram** `primeGram w v M (i,j) = Σ_{m<M} w(m)·v(m,i)·v(m,j)`.
This is the faithful bilinear extension of the built prime side: `weilPrimePart T = Σ_{n<X} Λ(n+1)·(…)`
(`Analysis.Weil`) has von Mangoldt weights `Λ ≥ 0` on per-place test values, and the cross-correlation
`g_i ⋆ g_j^τ` has prime side `Σ_n Λ(n+1)·v_i(n)·v_j(n)` — exactly `primeGram (fun n ↦ Λ(n+1)) v X`. Here
`v m i` is the (interface) transform value `ĝ_i` at prime-power place `m`, exactly as `WeilTest.f` is
interface data; `weilPrimeGram` instantiates the weight from the built `vonMangoldt`.

THE STRUCTURAL LAWS (all genuine, kernel-checked):
  • `primeGram_sym` — the prime Gram is symmetric.
  • `weilQuad_primeGram_split` — the prime form is a **weighted sum of squares over prime-powers**:
        `weilQuad (primeGram w v M) c N = Σ_{m<M} w(m)·(Σ_{i<N} c_i·v(m,i))²`.
  • `WeilPSD_primeGram` — the prime Gram is PSD when `w ≥ 0` (NO sqrt: each weighted square is nonneg);
    `WeilPSD_weilPrimeGram` — UNCONDITIONAL on the genuine von Mangoldt weight (`vonMangoldt_nonneg`).
  • `weilQuad_coupledWeil_split` — **THE COUPLED FORM = arch spectral square − prime square-sum**:
        `weilQuad (coupledWeil arch w v M) c N = (Σ_i c_i²·arch_i) − (Σ_m w(m)·(Σ_i c_i v(m,i))²)`.
  • `coupledWeil_psd_iff_dominates` — **the honest capstone**: `WeilPSD (coupledWeil arch w v M)` holds
    IFF the arch spectral form dominates the prime Gram on every test (`ArchDominatesPrime`).

HONEST SCOPE. The coupled kernel is a genuinely off-diagonal Weil form (its `i≠j` entries
`w(m)v(m,i)v(m,j)` are real and nonzero), abstract over the interface data `arch, w, v` — no `λ`, no
zeros. Its full positivity `WeilPSD (coupledWeil …)` is `ArchDominatesPrime` = the archimedean trend
dominating the prime oscillation = Weil positivity on the test span, which **IS RH**
[CLASSICAL: Weil 1952; the dominance face `Dominance.Dominated`]. It is NEVER asserted here — the crux
fields stay `none`. What this file delivers is the missing OBJECT (step 4's kernel) and its exact
quadratic split, honestly locating the remaining content as one dominance inequality. A difference of
PSD forms is not PSD in general (which is why `WeilPSD_add` has no subtraction analog) — that failure
is exactly the crux.

FAITHFULNESS, precisely scoped. The place-value data `v` is **abstract interface data** (exactly as
`WeilTest.f` is): faithfulness to the built prime side is earned at the **weight + shape** level — the
genuine `vonMangoldt` weights and the weighted-SOS-over-prime-powers form `Σ_m Λ(m+1)(Σ_i c_i v(m,i))²`
matching `weilPrimePart`'s `Σ_n Λ(n+1)·(…)`. The diagonal-recovery law tying `primeGram(n,n)` to the
concrete scalar `weilPrimePart`, and the wiring of the capstone's `ArchDominatesPrime` into the built
pairing faces (`weilSpectralSquare` / `weil_strict_iff_crux` / `Dominance.dominance_crux_equivalent`),
are the NEXT bricks — not yet mechanized here. Neither is smuggling; both are the disciplined interface
pattern, and the crux stays `none` throughout.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.SelfAdjoint
import Foundations.F1.Analysis.Mangoldt

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Generic algebra: the quadratic form scales and subtracts in the kernel.
-- ===========================================================================

/-- The quadratic form is **subtractive in the kernel**: `weilQuad (B − B') = weilQuad B − weilQuad B'`
    (the subtraction analog of `weilQuad_add`; PSD is NOT closed under this — the crux). -/
theorem weilQuad_sub (B B' : Nat → Nat → Real) (c : Nat → Real) (N : Nat) :
    Req (weilQuad (fun i j => Rsub (B i j) (B' i j)) c N)
        (Rsub (weilQuad B c N) (weilQuad B' c N)) := by
  refine Req_trans (RsumN_congr N (fun i _ => ?_)) (RsumN_sub _ _ N)
  refine Req_trans (RsumN_congr N (fun j _ => ?_)) (RsumN_sub _ _ N)
  refine Req_trans (Rmul_congr (Req_refl (c i)) (Rmul_sub_distrib (c j) (B i j) (B' i j))) ?_
  exact Rmul_sub_distrib (c i) (Rmul (c j) (B i j)) (Rmul (c j) (B' i j))

/-- Pull a scalar out from a left-nested triple product: `x·(y·(a·z)) ≈ a·(x·(y·z))`
    (pure commutative-ring rearrangement; used to factor the scalar `a` out of the quadratic form). -/
theorem Rmul_pull2 (a x y z : Real) :
    Req (Rmul x (Rmul y (Rmul a z))) (Rmul a (Rmul x (Rmul y z))) := by
  have h1 : Req (Rmul y (Rmul a z)) (Rmul a (Rmul y z)) :=
    Req_trans (Req_symm (Rmul_assoc y a z))
      (Req_trans (Rmul_congr (Rmul_comm y a) (Req_refl z)) (Rmul_assoc a y z))
  refine Req_trans (Rmul_congr (Req_refl x) h1) ?_
  refine Req_trans (Req_symm (Rmul_assoc x a (Rmul y z))) ?_
  exact Req_trans (Rmul_congr (Rmul_comm x a) (Req_refl (Rmul y z))) (Rmul_assoc a x (Rmul y z))

/-- The quadratic form **scales in the kernel**: `weilQuad (a·B) = a·weilQuad B`. -/
theorem weilQuad_scale (a : Real) (B : Nat → Nat → Real) (c : Nat → Real) (N : Nat) :
    Req (weilQuad (fun i j => Rmul a (B i j)) c N) (Rmul a (weilQuad B c N)) := by
  refine Req_trans (RsumN_congr N (fun i _ => ?_))
    (Req_symm (Rmul_RsumN_left a (fun i => RsumN (fun j => Rmul (c i) (Rmul (c j) (B i j))) N) N))
  refine Req_trans (RsumN_congr N (fun j _ => Rmul_pull2 a (c i) (c j) (B i j)))
    (Req_symm (Rmul_RsumN_left a (fun j => Rmul (c i) (Rmul (c j) (B i j))) N))

-- ===========================================================================
-- The weighted rank-one form and the prime Gram.
-- ===========================================================================

/-- The rank-one Gram's quadratic form is a square: `weilQuad (fᵢfⱼ) c N = (Σ cₖfₖ)²`
    (extracted from `WeilPSD_rankOne`'s computation). -/
theorem weilQuad_rankOne_eq (f c : Nat → Real) (N : Nat) :
    Req (weilQuad (fun i j => Rmul (f i) (f j)) c N)
        (Rmul (RsumN (fun k => Rmul (c k) (f k)) N) (RsumN (fun k => Rmul (c k) (f k)) N)) := by
  refine Req_trans (RsumN_congr N (fun i _ => RsumN_congr N (fun j _ =>
    rankOne_term_reassoc (c i) (c j) (f i) (f j)))) ?_
  exact Req_symm (RsumN_mul_RsumN (fun k => Rmul (c k) (f k)) (fun k => Rmul (c k) (f k)) N N)

/-- The **weighted** rank-one form: `weilQuad (a·fᵢfⱼ) c N = a·(Σ cₖfₖ)²`. -/
theorem weilQuad_wRankOne (a : Real) (f c : Nat → Real) (N : Nat) :
    Req (weilQuad (fun i j => Rmul a (Rmul (f i) (f j))) c N)
        (Rmul a (Rmul (RsumN (fun k => Rmul (c k) (f k)) N)
                      (RsumN (fun k => Rmul (c k) (f k)) N))) :=
  Req_trans (weilQuad_scale a (fun i j => Rmul (f i) (f j)) c N)
    (Rmul_congr (Req_refl a) (weilQuad_rankOne_eq f c N))

/-- **The prime Gram** `primeGram w v M (i,j) = Σ_{m<M} w(m)·v(m,i)·v(m,j)` — the bilinear prime side
    on the interface place-value data `v` (`v m i = ĝᵢ` at prime-power place `m`) with weights `w`. -/
def primeGram (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) : Nat → Nat → Real :=
  fun i j => RsumN (fun m => Rmul (w m) (Rmul (v m i) (v m j))) M

/-- The prime Gram is **symmetric**. -/
theorem primeGram_sym (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) (i j : Nat) :
    Req (primeGram w v M i j) (primeGram w v M j i) :=
  RsumN_congr M (fun m _ => Rmul_congr (Req_refl (w m)) (Rmul_comm (v m i) (v m j)))

/-- **Quadratic form is additive over a finite sum of kernels** (the finite-Fubini interchange):
    `weilQuad (Σ_{m<M} K m) c N = Σ_{m<M} weilQuad (K m) c N`. -/
theorem weilQuad_sumKernel (K : Nat → Nat → Nat → Real) (c : Nat → Real) (N M : Nat) :
    Req (weilQuad (fun i j => RsumN (fun m => K m i j) M) c N)
        (RsumN (fun m => weilQuad (K m) c N) M) := by
  -- push the inner c-factors through the m-sum, then swap m outward across the i- and j-sums
  have step : Req (weilQuad (fun i j => RsumN (fun m => K m i j) M) c N)
      (RsumN (fun i => RsumN (fun m => RsumN (fun j => Rmul (c i) (Rmul (c j) (K m i j))) N) M) N) := by
    refine RsumN_congr N (fun i _ => ?_)
    -- Σⱼ cᵢ·(cⱼ·Σₘ Kₘᵢⱼ) = Σⱼ Σₘ cᵢ·(cⱼ·Kₘᵢⱼ) = Σₘ Σⱼ …
    refine Req_trans (RsumN_congr N (fun j _ => ?_)) (RsumN_swap
      (fun j m => Rmul (c i) (Rmul (c j) (K m i j))) N M)
    refine Req_trans (Rmul_congr (Req_refl (c i))
      (Rmul_RsumN_left (c j) (fun m => K m i j) M)) ?_
    exact Rmul_RsumN_left (c i) (fun m => Rmul (c j) (K m i j)) M
  refine Req_trans step ?_
  -- Σᵢ Σₘ (…) = Σₘ Σᵢ (…) = Σₘ weilQuad (K m)
  exact RsumN_swap (fun i m => RsumN (fun j => Rmul (c i) (Rmul (c j) (K m i j))) N) N M

/-- **★ THE PRIME-FORM SPLIT**: the prime Gram's quadratic form is a **weighted sum of squares over
    prime-powers** — `weilQuad (primeGram w v M) c N = Σ_{m<M} w(m)·(Σ_{i<N} c_i·v(m,i))²`. -/
theorem weilQuad_primeGram_split (w : Nat → Real) (v : Nat → Nat → Real) (c : Nat → Real) (N M : Nat) :
    Req (weilQuad (primeGram w v M) c N)
        (RsumN (fun m => Rmul (w m)
          (Rmul (RsumN (fun i => Rmul (c i) (v m i)) N)
                (RsumN (fun i => Rmul (c i) (v m i)) N))) M) := by
  refine Req_trans (weilQuad_sumKernel (fun m i j => Rmul (w m) (Rmul (v m i) (v m j))) c N M) ?_
  exact RsumN_congr M (fun m _ => weilQuad_wRankOne (w m) (v m) c N)

/-- **The prime Gram is PSD when the weights are nonnegative** — each weighted square is `≥ 0`,
    NO sqrt (the weight multiplies a manifest square). -/
theorem WeilPSD_primeGram (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (hw : ∀ m, Rnonneg (w m)) : WeilPSD (primeGram w v M) := by
  intro N c
  refine Rnonneg_congr (Req_symm (weilQuad_primeGram_split w v c N M)) ?_
  refine Rnonneg_RsumN M (fun m _ => ?_)
  exact Rnonneg_Rmul (hw m) (Rnonneg_Rmul_self (RsumN (fun i => Rmul (c i) (v m i)) N))

-- ===========================================================================
-- The genuine prime Gram on the von Mangoldt weight (unconditional PSD).
-- ===========================================================================

/-- **The genuine prime Gram** on the built von Mangoldt weight: `weilPrimeGram v M (i,j) =
    Σ_{m<M} Λ(m+1)·v(m,i)·v(m,j)` — the exact bilinear extension of `Analysis.Weil.weilPrimePart`. -/
def weilPrimeGram (v : Nat → Nat → Real) (M : Nat) : Nat → Nat → Real :=
  primeGram (fun m => vonMangoldt (m + 1)) v M

/-- **The genuine prime Gram is PSD, UNCONDITIONALLY** — von Mangoldt weights are `≥ 0`
    (`vonMangoldt_nonneg`), so the prime side is a genuine positive-semidefinite Gram, no RH input. -/
theorem WeilPSD_weilPrimeGram (v : Nat → Nat → Real) (M : Nat) : WeilPSD (weilPrimeGram v M) :=
  WeilPSD_primeGram (fun m => vonMangoldt (m + 1)) v M (fun m => vonMangoldt_nonneg (m + 1))

-- ===========================================================================
-- The coupled Weil kernel and its quadratic split.
-- ===========================================================================

/-- **THE COUPLED WEIL KERNEL**: `coupledWeil arch w v M (i,j) = (multForm arch)(i,j) −
    primeGram w v M (i,j)` — the archimedean diagonal multiplier MINUS the prime Gram. Genuinely
    off-diagonal (the `i≠j` entries are `−w(m)v(m,i)v(m,j)`). -/
def coupledWeil (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) : Nat → Nat → Real :=
  fun i j => Rsub (multForm arch i j) (primeGram w v M i j)

/-- **★ THE COUPLED SPLIT**: the coupled quadratic form is the **archimedean spectral square minus the
    prime square-sum** —
        `weilQuad (coupledWeil arch w v M) c N =
           (Σ_{i<N} c_i²·arch_i) − (Σ_{m<M} w(m)·(Σ_{i<N} c_i·v(m,i))²)`.
    Positivity of this difference is the whole of step 4. -/
theorem weilQuad_coupledWeil_split (arch w : Nat → Real) (v : Nat → Nat → Real)
    (c : Nat → Real) (N M : Nat) :
    Req (weilQuad (coupledWeil arch w v M) c N)
        (Rsub (RsumN (fun i => Rmul (c i) (Rmul (c i) (arch i))) N)
              (RsumN (fun m => Rmul (w m)
                (Rmul (RsumN (fun i => Rmul (c i) (v m i)) N)
                      (RsumN (fun i => Rmul (c i) (v m i)) N))) M)) := by
  refine Req_trans (weilQuad_sub (multForm arch) (primeGram w v M) c N) ?_
  exact Rsub_congr (weilQuad_multForm arch c N) (weilQuad_primeGram_split w v c N M)

-- ===========================================================================
-- The honest capstone: WeilPSD (coupledWeil) ⟺ arch dominates prime = RH.
-- ===========================================================================

/-- **The dominance predicate**: the archimedean spectral form dominates the prime Gram on every finite
    test — `∀ N c, weilQuad (primeGram w v M) c N ≤ weilQuad (multForm arch) c N`. For the genuine data
    this is Weil positivity on the test span; it **IS RH** (`Dominance.Dominated` at the quadratic
    level). Never asserted. -/
def ArchDominatesPrime (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) : Prop :=
  ∀ (N : Nat) (c : Nat → Real),
    Rle (weilQuad (primeGram w v M) c N) (weilQuad (multForm arch) c N)

/-- **THE HONEST CAPSTONE**: the coupled Weil kernel is PSD IFF the archimedean form dominates the
    prime Gram — `WeilPSD (coupledWeil arch w v M) ⟺ ArchDominatesPrime arch w v M`. The whole of the
    remaining crux is this one dominance inequality; assembling the kernel does NOT close it (that is
    RH). NOTHING here asserts the dominance holds. -/
theorem coupledWeil_psd_iff_dominates (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) :
    WeilPSD (coupledWeil arch w v M) ↔ ArchDominatesPrime arch w v M := by
  constructor
  · intro h N c
    have hnn : Rnonneg (weilQuad (coupledWeil arch w v M) c N) := h N c
    have hsplit := weilQuad_sub (multForm arch) (primeGram w v M) c N
    exact Rle_of_Rnonneg_Rsub (Rnonneg_congr hsplit hnn)
  · intro h N c
    have hd : Rnonneg (Rsub (weilQuad (multForm arch) c N) (weilQuad (primeGram w v M) c N)) :=
      Rnonneg_Rsub_of_Rle (h N c)
    exact Rnonneg_congr (Req_symm (weilQuad_sub (multForm arch) (primeGram w v M) c N)) hd

end Multiplicity.UOR.Bridge.F1Square.Square
