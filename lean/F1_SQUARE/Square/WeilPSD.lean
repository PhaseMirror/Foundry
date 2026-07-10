/-
F1 square — v0.21.0 stage G, brick **S (the substrate)**: the finite-truncation
positive-semidefinite predicate `WeilPSD`, the ground that the missing-object embedding
(ROADMAP §G, Gate B) stands on.

ROADMAP §7 (the infinite-dimensional definite-form substrate) and §8 (Stage S). The genuine
square already carries a finite bilinear form on a rank-4 lattice (`hPair`,
`Square/WeilLattice.lean`); what the program lacks — and what Gate B needs — is the
positive-definite case at every finite truncation, with the direct limit being "for all `N`".
This brick supplies it on the existing constructive `Real` API (`RsumN`/`Rmul`/`Rnonneg`),
choice-free and Mathlib-free, exactly as §7 budgets.

WHAT IS PROVED.
- `WeilPSD B := ∀ N c, Rnonneg (weilQuad B c N)` — the quadratic form `Σ_{i,j<N} cᵢcⱼ B(i,j)`
  is `≥ 0` for every finite test family `c` and every truncation `N` (the direct limit `= ∀N`).
- It is closed under `+` (`WeilPSD_add`), contains `0` (`WeilPSD_zero`), and — the load-bearing
  fact — **every rank-one Gram `B(i,j) = f(i)·f(j)` is PSD** (`WeilPSD_rankOne`: the form is the
  manifest square `(Σ cᵢ f(i))²`). Hence **any embedding into `ℝ^D` gives a PSD Gram**
  (`WeilPSD_gramOf`: `gramOf ι D` is `WeilPSD` for every `ι, D`) — this is **Gate B made free**:
  a finite Euclidean target is positive-definite by construction, the difficulty does not live here.
- `WeilPSD_diag`: a PSD form has nonnegative diagonal (test with the coordinate indicator).

THE EMBEDDING BRIDGE (§4, the `⟹` direction). `RealizesDiag S ι D` says the Gram of `ι` matches
`−⟨Cₙ,Cₙ⟩` on the diagonal; `embeds_to_hodgeNeg`/`embeds_to_liNonneg` then deliver
`SpectralHodgeNeg`/`LiNonneg`. Because Gate B (`WeilPSD_gramOf`) is free, **all of the content is
in `RealizesDiag`** (Gate A) — exactly §4.1's difficulty conservation: the diagonal match for the
GENUINE square (`realizesDiag_genuine_iff`, which reuses the derived dictionary
`genuine_vanCyc_normal`/`vanCyc_selfpair`) is `gramOf ι D n n ≈ 2λₙ`, a manifest sum of squares
equal to `2λₙ` — i.e. RH itself. NOTHING here asserts that such an `ι` exists; the predicate is
shown only to be inhabited at a template (`realizesDiag_satisfiable`, the two-sided guard). This is
the `⟹` direction only, and at FIXED finite `D` it cannot close the crux (the form is not its
diagonal — the off-diagonal forces infinite rank; §4, §10). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.WeilLattice
import F1Square.Square.Forced
import F1Square.Analysis.RSum
import F1Square.Analysis.RMulNF

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- Generic finite-sum algebra (reusable: distributivity over `RsumN`, the
-- product-of-sums identity, additive split, the all-zero collapse, the
-- coordinate-indicator collapse). Each is elementary induction on the length.
-- ===========================================================================

/-- A constant factor pulls out of a finite sum: `x·(Σ G) ≈ Σ (x·G)`. -/
theorem Rmul_RsumN_left (x : Real) (G : Nat → Real) (M : Nat) :
    Req (Rmul x (RsumN G M)) (RsumN (fun j => Rmul x (G j)) M) := by
  induction M with
  | zero => exact Rmul_zero x
  | succ m ih =>
    refine Req_trans (Rmul_distrib x (RsumN G m) (G m)) ?_
    exact Radd_congr ih (Req_refl _)

/-- The product-of-sums identity `(Σ a)(Σ b) ≈ Σᵢ Σⱼ aᵢ bⱼ`. -/
theorem RsumN_mul_RsumN (a b : Nat → Real) (N M : Nat) :
    Req (Rmul (RsumN a N) (RsumN b M))
        (RsumN (fun i => RsumN (fun j => Rmul (a i) (b j)) M) N) := by
  induction N with
  | zero => exact Req_trans (Rmul_comm zero (RsumN b M)) (Rmul_zero (RsumN b M))
  | succ n ih =>
    refine Req_trans (Rmul_distrib_right (RsumN a n) (a n) (RsumN b M)) ?_
    exact Radd_congr ih (Rmul_RsumN_left (a n) b M)

/-- `(a+b)+(c+d) ≈ (a+c)+(b+d)` — abelian-group rearrangement, explicit/choice-free. -/
theorem Radd_rearrange4 (a b c d : Real) :
    Req (Radd (Radd a b) (Radd c d)) (Radd (Radd a c) (Radd b d)) := by
  refine Req_trans (Radd_assoc a b (Radd c d)) ?_
  refine Req_trans (Radd_congr (Req_refl a) (Req_symm (Radd_assoc b c d))) ?_
  refine Req_trans (Radd_congr (Req_refl a) (Radd_congr (Radd_comm b c) (Req_refl d))) ?_
  refine Req_trans (Radd_congr (Req_refl a) (Radd_assoc c b d)) ?_
  exact Req_symm (Radd_assoc a c (Radd b d))

/-- Finite sums split over `Radd`: `Σ (F + G) ≈ (Σ F) + (Σ G)`. -/
theorem RsumN_add (F G : Nat → Real) (N : Nat) :
    Req (RsumN (fun i => Radd (F i) (G i)) N) (Radd (RsumN F N) (RsumN G N)) := by
  induction N with
  | zero => exact Req_symm (Radd_zero zero)
  | succ n ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    -- `(Σ F + Σ G) + (F n + G n) ≈ (Σ F + F n) + (Σ G + G n)`
    exact Radd_rearrange4 (RsumN F n) (RsumN G n) (F n) (G n)

/-- A termwise-zero sum is zero. -/
theorem RsumN_zero {F : Nat → Real} (N : Nat) (h : ∀ i, i < N → Req (F i) zero) :
    Req (RsumN F N) zero := by
  induction N with
  | zero => exact Req_refl zero
  | succ n ih =>
    refine Req_trans (Radd_congr (ih (fun i hi => h i (Nat.lt_succ_of_lt hi)))
      (h n (Nat.lt_succ_self n))) ?_
    exact Radd_zero zero

-- ===========================================================================
-- The coordinate indicator and the delta-collapse `Σⱼ δₙ(j)·G(j) ≈ G(n)`.
-- ===========================================================================

/-- The `n`-th coordinate indicator `δₙ` over the constructive reals. -/
def indic (n : Nat) : Nat → Real := fun k => if k = n then one else zero

theorem indic_eq_one (n : Nat) : indic n n = one := if_pos rfl
theorem indic_eq_zero {n j : Nat} (h : j ≠ n) : indic n j = zero := if_neg h

/-- Sifting: `Σ_{j<N} δₙ(j)·G(j) ≈ G(n)` for `n < N`. -/
theorem RsumN_indic_mul (n : Nat) (G : Nat → Real) :
    ∀ N, n < N → Req (RsumN (fun j => Rmul (indic n j) (G j)) N) (G n) := by
  intro N
  induction N with
  | zero => intro h; exact absurd h (Nat.not_lt_zero n)
  | succ m ih =>
    intro h
    by_cases hnm : n = m
    · subst hnm
      have hearlier : Req (RsumN (fun j => Rmul (indic n j) (G j)) n) zero := by
        refine RsumN_zero n (fun j hj => ?_)
        rw [indic_eq_zero (by omega : j ≠ n)]
        exact Req_trans (Rmul_comm zero (G j)) (Rmul_zero (G j))
      have hlast : Req (Rmul (indic n n) (G n)) (G n) := by
        rw [indic_eq_one n]
        exact Req_trans (Rmul_comm one (G n)) (Rmul_one (G n))
      refine Req_trans (Radd_congr hearlier hlast) ?_
      exact Req_trans (Radd_comm zero (G n)) (Radd_zero (G n))
    · have hlt : n < m := by omega
      have hlast : Req (Rmul (indic n m) (G m)) zero := by
        rw [indic_eq_zero (by omega : m ≠ n)]
        exact Req_trans (Rmul_comm zero (G m)) (Rmul_zero (G m))
      refine Req_trans (Radd_congr (ih hlt) hlast) ?_
      exact Radd_zero (G n)

-- ===========================================================================
-- The quadratic form and the PSD predicate.
-- ===========================================================================

/-- The quadratic form `Σ_{i<N} Σ_{j<N} cᵢ · cⱼ · B(i,j)` of a bilinear kernel `B` on a finite
    test family `c`, truncated at `N`. -/
def weilQuad (B : Nat → Nat → Real) (c : Nat → Real) (N : Nat) : Real :=
  RsumN (fun i => RsumN (fun j => Rmul (c i) (Rmul (c j) (B i j))) N) N

/-- **Finite-truncation positive-semidefiniteness** of a bilinear kernel `B`: the quadratic form
    is `≥ 0` for every finite test family `c` and every truncation `N`. The direct limit (§8,
    Stage S) is exactly the `∀ N` here. -/
def WeilPSD (B : Nat → Nat → Real) : Prop :=
  ∀ (N : Nat) (c : Nat → Real), Rnonneg (weilQuad B c N)

/-- `WeilPSD` transports along a pointwise `≈` of kernels. -/
theorem WeilPSD_congr {B B' : Nat → Nat → Real} (h : ∀ i j, Req (B i j) (B' i j))
    (hB : WeilPSD B) : WeilPSD B' := by
  intro N c
  refine Rnonneg_congr ?_ (hB N c)
  exact RsumN_congr N (fun i _ => RsumN_congr N
    (fun j _ => Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _) (h i j))))

/-- The zero kernel is PSD. -/
theorem WeilPSD_zero : WeilPSD (fun _ _ => zero) := by
  intro N c
  refine Rnonneg_congr (Req_symm ?_) Rnonneg_zero
  refine RsumN_zero N (fun i _ => RsumN_zero N (fun j _ => ?_))
  exact Req_trans (Rmul_congr (Req_refl _) (Rmul_zero (c j))) (Rmul_zero (c i))

/-- The quadratic form is additive in the kernel. -/
theorem weilQuad_add (B B' : Nat → Nat → Real) (c : Nat → Real) (N : Nat) :
    Req (weilQuad (fun i j => Radd (B i j) (B' i j)) c N)
        (Radd (weilQuad B c N) (weilQuad B' c N)) := by
  refine Req_trans (RsumN_congr N (fun i _ => ?_)) (RsumN_add _ _ N)
  refine Req_trans (RsumN_congr N (fun j _ => ?_)) (RsumN_add _ _ N)
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_distrib (c j) (B i j) (B' i j))) ?_
  exact Rmul_distrib (c i) (Rmul (c j) (B i j)) (Rmul (c j) (B' i j))

/-- PSD kernels are closed under sum. -/
theorem WeilPSD_add {B B' : Nat → Nat → Real} (hB : WeilPSD B) (hB' : WeilPSD B') :
    WeilPSD (fun i j => Radd (B i j) (B' i j)) := by
  intro N c
  exact Rnonneg_congr (Req_symm (weilQuad_add B B' c N)) (Rnonneg_Radd (hB N c) (hB' N c))

/-- The degree-4 monomial rearrangement `cᵢ·(cⱼ·(fᵢ·fⱼ)) ≈ (cᵢ·fᵢ)·(cⱼ·fⱼ)` (same factor
    multiset), the per-term step that exhibits the rank-one form as a square. -/
theorem rankOne_term_reassoc (ci cj fi fj : Real) :
    Req (Rmul ci (Rmul cj (Rmul fi fj))) (Rmul (Rmul ci fi) (Rmul cj fj)) := by
  have hL : Req (Rmul ci (Rmul cj (Rmul fi fj))) (RprodL [ci, cj, fi, fj]) :=
    Rmul_congr (Req_refl ci) (Rmul_congr (Req_refl cj) (Rmul_eq_RprodL fi fj))
  have hR : Req (Rmul (Rmul ci fi) (Rmul cj fj)) (RprodL [ci, fi, cj, fj]) :=
    Rmul_pair_eq_RprodL4 ci fi cj fj
  have hperm : Req (RprodL [ci, cj, fi, fj]) (RprodL [ci, fi, cj, fj]) :=
    RprodL_perm (List.Perm.cons ci (List.Perm.swap fi cj [fj]))
  exact Req_trans hL (Req_trans hperm (Req_symm hR))

/-- **The load-bearing fact: every rank-one Gram is PSD.** `B(i,j) = f(i)·f(j)` gives the
    quadratic form `(Σ cᵢ f(i))²`, a manifest square. -/
theorem WeilPSD_rankOne (f : Nat → Real) : WeilPSD (fun i j => Rmul (f i) (f j)) := by
  intro N c
  refine Rnonneg_congr (Req_symm ?_)
    (Rnonneg_Rmul_self (RsumN (fun k => Rmul (c k) (f k)) N))
  refine Req_trans (RsumN_congr N (fun i _ => RsumN_congr N (fun j _ =>
    rankOne_term_reassoc (c i) (c j) (f i) (f j)))) ?_
  exact Req_symm (RsumN_mul_RsumN (fun k => Rmul (c k) (f k)) (fun k => Rmul (c k) (f k)) N N)

-- ===========================================================================
-- The embedding Gram and Gate B (free).
-- ===========================================================================

/-- The Gram of an embedding `ι : Cₙ ↦ ℝ^D` (each class sent to its `D` coordinates):
    `gramOf ι D i j = Σ_{k<D} (ι i k)·(ι j k)`, the Euclidean inner product in `ℝ^D`. -/
def gramOf (ι : Nat → Nat → Real) (D : Nat) : Nat → Nat → Real :=
  fun i j => RsumN (fun k => Rmul (ι i k) (ι j k)) D

/-- **Gate B is free: an embedding into a finite Euclidean space gives a PSD Gram**, for every
    `ι` and every dimension `D`. The Euclidean target is positive-definite by construction —
    the program's difficulty is not here (§4.1). -/
theorem WeilPSD_gramOf (ι : Nat → Nat → Real) (D : Nat) : WeilPSD (gramOf ι D) := by
  induction D with
  | zero => exact WeilPSD_congr (fun _ _ => Req_refl _) WeilPSD_zero
  | succ d ih =>
    exact WeilPSD_congr (fun _ _ => Req_refl _)
      (WeilPSD_add ih (WeilPSD_rankOne (fun k => ι k d)))

/-- A PSD kernel has a nonnegative diagonal — test with the coordinate indicator `δₙ`. -/
theorem WeilPSD_diag {B : Nat → Nat → Real} (hB : WeilPSD B) (n : Nat) : Rnonneg (B n n) := by
  have hinner : ∀ i, Req (RsumN (fun j => Rmul (indic n i) (Rmul (indic n j) (B i j))) (n + 1))
      (Rmul (indic n i) (B i n)) := by
    intro i
    refine Req_trans (Req_symm (Rmul_RsumN_left (indic n i)
      (fun j => Rmul (indic n j) (B i j)) (n + 1))) ?_
    exact Rmul_congr (Req_refl _) (RsumN_indic_mul n (fun j => B i j) (n + 1) (Nat.lt_succ_self n))
  have key : Req (weilQuad B (indic n) (n + 1)) (B n n) :=
    Req_trans (RsumN_congr (n + 1) (fun i _ => hinner i))
      (RsumN_indic_mul n (fun i => B i n) (n + 1) (Nat.lt_succ_self n))
  exact Rnonneg_congr key (hB (n + 1) (indic n))

-- ===========================================================================
-- The embedding bridge (ROADMAP §4, the `⟹` direction).
-- ===========================================================================

/-- An embedding `ι : Cₙ ↦ ℝ^D` **realizes the Hodge-negative diagonal** of a spectral square `S`
    if its Gram matches `−⟨Cₙ,Cₙ⟩` on the diagonal. This is Gate A: an exact identity between the
    manifestly-nonnegative `gramOf ι D n n` and the spectral datum `−⟨Cₙ,Cₙ⟩`. -/
def RealizesDiag (S : SpectralSquare) (ι : Nat → Nat → Real) (D : Nat) : Prop :=
  ∀ n, 0 < n → Req (gramOf ι D n n) (Rneg (S.cSq n))

/-- **The embedding `⟹` Hodge-negativity** (§4): if `ι` realizes the diagonal, then every
    `−⟨Cₙ,Cₙ⟩ ≥ 0`. Gate B is supplied for free by `WeilPSD_gramOf`; the whole content is the
    diagonal match `RealizesDiag`. -/
theorem embeds_to_hodgeNeg (S : SpectralSquare) (ι : Nat → Nat → Real) (D : Nat)
    (h : RealizesDiag S ι D) : SpectralHodgeNeg S :=
  fun n hn => Rnonneg_congr (h n hn) (WeilPSD_diag (WeilPSD_gramOf ι D) n)

/-- … hence Li-nonnegativity, through the v0.18.0 bridge. (The `⟹` direction only; §4.) -/
theorem embeds_to_liNonneg (S : SpectralSquare) (ι : Nat → Nat → Real) (D : Nat)
    (h : RealizesDiag S ι D) : LiNonneg S.lam :=
  (spectral_bridge_nonneg S).mp (embeds_to_hodgeNeg S ι D h)

/-- **The diagonal match for the GENUINE square is `gramOf ι D n n ≈ 2λₙ`** — reusing the derived
    dictionary (`genuine_vanCyc_normal`, the `vanCyc_selfpair` lineage), `−⟨Cₙ,Cₙ⟩ = 2λₙ`. So
    `RealizesDiag` of the genuine square is: write `2λₙ` as a manifest sum of `D` squares for all
    `n`. By `embeds_to_liNonneg` this is `LiNonneg (genuineLamSeq)` = RH — the difficulty did not
    leave Gate A (§4.1). NOTHING here asserts such an `ι` exists. -/
theorem realizesDiag_genuine_iff (E : StieltjesEta) (ι : Nat → Nat → Real) (D : Nat) :
    RealizesDiag (genuineSpectralSquare E) ι D
      ↔ ∀ n, 0 < n → Req (gramOf ι D n n)
          (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n)) := by
  constructor
  · intro h n hn
    exact Req_trans (h n hn) (genuine_vanCyc_normal E n)
  · intro h n hn
    exact Req_trans (h n hn) (Req_symm (genuine_vanCyc_normal E n))

end UOR.Bridge.F1Square.Square
