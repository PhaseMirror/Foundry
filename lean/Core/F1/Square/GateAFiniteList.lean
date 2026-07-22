/-
F1 square — the certificate front, workstream 2: **THE GATE-A FINITE-LIST TEMPLATE**
(`GateA_of_finiteList`), and the first candidate-class prune through it (workstream 1 record).

THE TEMPLATE (REMAINING_WORK "The certificate front", workstream 2). Gate A for the genuine
square is the uniform diagonal identity `gramOf ι D n n ≈ 2λₙ` for ALL `n > 0`
(`realizesDiag_genuine_iff`) — a `∀ n` statement, structurally different from any finite rung.
This brick specifies Gate A as a FINITE exact hypothesis list around a generating recurrence:
fix `D`, fix an order `K` and coefficients `a`, and require

  (base)     the K base identities   `gramOf ι D (1+i) (1+i) ≈ 2λ_{1+i}`, `i < K`;
  (gramRec)  the embedding's squared-norm diagonal satisfies the order-K linear recurrence;
  (lamRec)   the doubled genuine Li sequence satisfies the SAME recurrence.

`GateA_of_finiteList` proves: the list implies `RealizesDiag` — i.e. Gate A, i.e. (through
`gateA_is_liNonneg`) Li-nonnegativity of the genuine sequence. The reduction engine is
`linRec_unique`: two sequences satisfying one order-K linear recurrence over the constructive
reals with `≈`-equal initial K values are `≈`-equal everywhere (course-of-values induction —
kernel-checked, no analysis). Any candidate `(ι, D, K, a)` is henceforth checked against this
one list; each item is an exact kernel statement.

DIFFICULTY CONSERVATION (the honest ledger). The template does not manufacture positivity:
`lamRec` is a statement about the λ-sequence itself, and base+lamRec+gramRec together are
exactly as strong as Gate A on the candidate. NOTHING here asserts the list is satisfiable
for the genuine square — by `finiteList_is_liNonneg` a satisfiable instance would prove
`LiNonneg (genuineLamSeq)`, which is RH. The crux fields stay `none`.

TWO-SIDED GUARDS (the no-smuggling discipline of `GateA.lean`, extended to the list):
- `finiteList_satisfiable`: the list is not vacuously false — at the template square the
  constant rule passes the whole list and the reduction DELIVERS `RealizesDiag` end to end;
- `finiteList_can_fail`: the recurrence hypotheses alone never suffice — the zero rule
  satisfies both recurrences yet its base identity is REFUTED. The base carries content.

THE FIRST PRUNE (workstream 1 record, as REMAINING_WORK prescribes: "failure of any
hypothesis is recorded and prunes the candidate class"). The order-1 CONSTANT class
`(K, a) = (1, 1)` — every rule whose diagonal is eventually constant from `n = 1`, i.e.
period-one candidates — forces `2λ₂ ≈ 2λ₁` through `lamRec`. The certified gap
`λ₁ ≉ λ₂` (`Rlambda1_ne_Rlambda2`, `Analysis/LambdaGap.lean`) refutes that for EVERY
anchored η-data, every rule `ι`, and every dimension `D` at once
(`constantClass_pruned`). This is the template doing its job: one finite certified fact
kills an infinite candidate class.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Square.GateA
import Core.F1.Analysis.LambdaGap
import Core.F1.Analysis.LambdaThreeUpper
import Core.F1.Analysis.LambdaTwoThreePrecision
import Core.F1.Analysis.LambdaFourUpper
import Core.F1.Analysis.LambdaFivePos
import Core.F1.Analysis.LambdaFourThreeGap

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The generating recurrence over the constructive reals.
-- ===========================================================================

/-- A sequence `s` **satisfies the order-`K` linear recurrence** with coefficient family `a`:
    `s(n+K) ≈ Σ_{i<K} aᵢ · s(n+i)` for every `n`. (`K = 0` degenerates to `s ≈ 0`.) -/
def SatisfiesRec (a : Nat → Real) (K : Nat) (s : Nat → Real) : Prop :=
  ∀ n, Req (s (n + K)) (RsumN (fun i => Rmul (a i) (s (n + i))) K)

/-- `SatisfiesRec` transports along a pointwise `≈` of sequences. -/
theorem SatisfiesRec_congr {a : Nat → Real} {K : Nat} {s t : Nat → Real}
    (hst : ∀ n, Req (s n) (t n)) (hs : SatisfiesRec a K s) : SatisfiesRec a K t :=
  fun n => Req_trans (Req_symm (hst (n + K))) (Req_trans (hs n)
    (RsumN_congr K (fun i _ => Rmul_congr (Req_refl (a i)) (hst (n + i)))))

/-- **THE REDUCTION ENGINE**: two sequences satisfying the SAME order-`K` recurrence with
    `≈`-equal initial `K` values are `≈`-equal at every index — course-of-values induction,
    entirely finite/kernel-checked. This is what turns the `∀ n` diagonal identity into a
    finite hypothesis list. -/
theorem linRec_unique {a : Nat → Real} {K : Nat} {s t : Nat → Real}
    (hs : SatisfiesRec a K s) (ht : SatisfiesRec a K t)
    (hbase : ∀ i, i < K → Req (s i) (t i)) : ∀ n, Req (s n) (t n) := by
  have H : ∀ N n, n < N → Req (s n) (t n) := by
    intro N
    induction N with
    | zero => exact fun n hn => absurd hn (Nat.not_lt_zero n)
    | succ N ih =>
      intro n hn
      by_cases hK : n < K
      · exact hbase n hK
      · by_cases hlt : n < N
        · exact ih n hlt
        · obtain ⟨p, hp⟩ : ∃ p, n = p + K := ⟨n - K, by omega⟩
          subst hp
          refine Req_trans (hs p) (Req_trans (RsumN_congr K (fun i hi =>
            Rmul_congr (Req_refl (a i)) (ih (p + i) (by omega)))) (Req_symm (ht p)))
  exact fun n => H (n + 1) n (Nat.lt_succ_self n)

/-- The order-1 constant recurrence (`a = 1`) holds for a step-wise constant sequence. -/
theorem satisfiesRec_const {s : Nat → Real} (hconst : ∀ n, Req (s (n + 1)) (s n)) :
    SatisfiesRec (fun _ => one) 1 s := by
  intro n
  refine Req_trans (hconst n) ?_
  exact Req_symm (Req_trans (Radd_comm zero (Rmul one (s n)))
    (Req_trans (Radd_zero (Rmul one (s n))) (Req_trans (Rmul_comm one (s n)) (Rmul_one (s n)))))

/-- Conversely, the order-1 constant recurrence forces consecutive `≈`-equality. -/
theorem satisfiesRec_const_step {s : Nat → Real}
    (h : SatisfiesRec (fun _ => one) 1 s) (n : Nat) : Req (s (n + 1)) (s n) := by
  refine Req_trans (h n) ?_
  exact Req_trans (Radd_comm zero (Rmul one (s n)))
    (Req_trans (Radd_zero (Rmul one (s n))) (Req_trans (Rmul_comm one (s n)) (Rmul_one (s n))))

/-- An order-1 recurrence with ANY coefficient `c` forces the one-step multiplicative relation
    `s(n+1) ≈ c·s(n)`. -/
theorem satisfiesRec_order1_step {c : Real} {s : Nat → Real}
    (h : SatisfiesRec (fun _ => c) 1 s) (n : Nat) : Req (s (n + 1)) (Rmul c (s n)) :=
  Req_trans (h n) (Req_trans (Radd_comm zero (Rmul c (s n))) (Radd_zero (Rmul c (s n))))

-- ===========================================================================
-- The reduction: finite list ⟹ RealizesDiag (generic square, then Gate A).
-- ===========================================================================

/-- **The finite list implies the diagonal realization** — generic in the spectral square:
    `K` base identities + the two recurrence facts reduce the `∀ n` to `linRec_unique`. -/
theorem realizesDiag_of_finiteList (S : SpectralSquare) (ι : AtlasRule) (D K : Nat)
    (a : Nat → Real)
    (hbase : ∀ i, i < K → Req (gramOf ι D (1 + i) (1 + i)) (Rneg (S.cSq (1 + i))))
    (hgram : SatisfiesRec a K (fun m => gramOf ι D (1 + m) (1 + m)))
    (htarget : SatisfiesRec a K (fun m => Rneg (S.cSq (1 + m)))) :
    RealizesDiag S ι D := by
  intro n hn
  obtain ⟨m, hm⟩ : ∃ m, n = 1 + m := ⟨n - 1, by omega⟩
  subst hm
  exact linRec_unique hgram htarget hbase m

/-- **THE GATE-A FINITE LIST** for the genuine square, in the `2λ` form a candidate targets:
    the `K` base identities, the recurrence on the embedding diagonal, and the SAME recurrence
    on the doubled genuine Li sequence. Each field is an exact kernel statement. -/
structure GateAList (E : StieltjesEta) (ι : AtlasRule) (D K : Nat) (a : Nat → Real) : Prop where
  /-- base identities: `gramOf ι D (1+i) (1+i) ≈ 2λ_{1+i}` for `i < K` -/
  base : ∀ i, i < K → Req (gramOf ι D (1 + i) (1 + i))
      (Radd (genuineLamSeq E.eta (1 + i)) (genuineLamSeq E.eta (1 + i)))
  /-- the embedding's squared-norm diagonal satisfies the generating recurrence -/
  gramRec : SatisfiesRec a K (fun m => gramOf ι D (1 + m) (1 + m))
  /-- the doubled genuine Li sequence satisfies the SAME recurrence -/
  lamRec : SatisfiesRec a K
      (fun m => Radd (genuineLamSeq E.eta (1 + m)) (genuineLamSeq E.eta (1 + m)))

/-- **`GateA_of_finiteList` — the workstream-2 deliverable**: the finite list implies Gate A.
    (Gate B is free, so with `gateA_is_liNonneg` the list implies `LiNonneg (genuineLamSeq)`;
    NOTHING asserts the list is satisfiable for the genuine square — that is RH.) -/
theorem GateA_of_finiteList {E : StieltjesEta} {ι : AtlasRule} {D K : Nat} {a : Nat → Real}
    (h : GateAList E ι D K a) : GateA E ι D := by
  refine (realizesDiag_genuine_iff E ι D).mpr ?_
  intro n hn
  obtain ⟨m, hm⟩ : ∃ m, n = 1 + m := ⟨n - 1, by omega⟩
  subst hm
  exact linRec_unique h.gramRec h.lamRec h.base m

/-- **The honest ledger, explicit**: a satisfied list IS Li-nonnegativity of the genuine
    sequence (= the crux content). This is what "the difficulty did not leave Gate A" means
    at the template level: `lamRec` + `base` carry the full weight. NEVER asserted. -/
theorem finiteList_is_liNonneg {E : StieltjesEta} {ι : AtlasRule} {D K : Nat} {a : Nat → Real}
    (h : GateAList E ι D K a) : LiNonneg (genuineLamSeq E.eta) :=
  gateA_is_liNonneg E ι D (GateA_of_finiteList h)

-- ===========================================================================
-- The two-sided guards: the list is a real constraint, and the reduction really fires.
-- ===========================================================================

/-- **Guard #1 (SATISFIABLE, end to end)**: at the template square the constant rule passes
    the whole list — and the reduction DELIVERS `RealizesDiag`. The template is not
    vacuously false, and `GateA_of_finiteList`'s engine genuinely fires. -/
theorem finiteList_satisfiable :
    ∃ (S : SpectralSquare) (ι : AtlasRule) (D K : Nat) (a : Nat → Real),
      (∀ i, i < K → Req (gramOf ι D (1 + i) (1 + i)) (Rneg (S.cSq (1 + i))))
      ∧ SatisfiesRec a K (fun m => gramOf ι D (1 + m) (1 + m))
      ∧ SatisfiesRec a K (fun m => Rneg (S.cSq (1 + m)))
      ∧ RealizesDiag S ι D := by
  have hb : ∀ i, i < 1 → Req (gramOf (fun _ _ => one) 2 (1 + i) (1 + i))
      (Rneg (spectralTemplate.cSq (1 + i))) := by
    intro i _
    -- gramOf 2 = (0 + 1·1) + 1·1 ≈ 1 + 1 ; −cSq = −−(1+1) ≈ 1 + 1
    have hzo : Req (Radd zero one) one := Req_trans (Radd_comm zero one) (Radd_zero one)
    have hL : Req (Radd (Radd zero (Rmul one one)) (Rmul one one)) (Radd one one) :=
      Radd_congr (Req_trans (Radd_congr (Req_refl zero) (Rmul_one one)) hzo) (Rmul_one one)
    exact Req_trans hL (Req_symm (Rneg_neg (Radd one one)))
  have hg : SatisfiesRec (fun _ => one) 1
      (fun m => gramOf (fun _ _ => one) 2 (1 + m) (1 + m)) :=
    satisfiesRec_const (fun _ => Req_refl _)
  have ht : SatisfiesRec (fun _ => one) 1
      (fun m => Rneg (spectralTemplate.cSq (1 + m))) :=
    satisfiesRec_const (fun _ => Req_refl _)
  exact ⟨spectralTemplate, (fun _ _ => one), 2, 1, (fun _ => one), hb, hg, ht,
    realizesDiag_of_finiteList spectralTemplate (fun _ _ => one) 2 1 (fun _ => one) hb hg ht⟩

/-- **Guard #2 (NON-TRIVIAL)**: the recurrence hypotheses alone never suffice — the zero rule
    satisfies BOTH recurrences at the template square, yet its base identity is refuted
    (`0 ≉ 2`). The base list carries content; nothing is definitional. -/
theorem finiteList_can_fail :
    ∃ (S : SpectralSquare) (ι : AtlasRule) (D K : Nat) (a : Nat → Real),
      SatisfiesRec a K (fun m => gramOf ι D (1 + m) (1 + m))
      ∧ SatisfiesRec a K (fun m => Rneg (S.cSq (1 + m)))
      ∧ ¬ (∀ i, i < K → Req (gramOf ι D (1 + i) (1 + i)) (Rneg (S.cSq (1 + i)))) := by
  refine ⟨spectralTemplate, (fun _ _ => zero), 1, 1, (fun _ => one),
    satisfiesRec_const (fun _ => Req_refl _), satisfiesRec_const (fun _ => Req_refl _), ?_⟩
  intro h
  have h0 := h 0 (by omega)
  have hg : Req (Radd zero (Rmul zero zero)) (Radd zero zero) :=
    Radd_congr (Req_refl zero) (Rmul_zero zero)
  have hc : Req (Rneg (spectralTemplate.cSq 1)) (Radd one one) := Rneg_neg (Radd one one)
  have hbad : Req (Radd zero zero) (Radd one one) :=
    Req_trans (Req_symm hg) (Req_trans h0 hc)
  exact not_Pos_zero_double (Pos_congr (Req_symm hbad) (Pos_Radd_self Pos_one))

-- ===========================================================================
-- The first prune (workstream 1 record): the constant class is dead.
-- ===========================================================================

/-- **The constant class fails `lamRec`**: the order-1 constant recurrence on the doubled
    genuine Li sequence forces `2λ₂ ≈ 2λ₁`, refuted by the certified gap
    `λ₁ ≉ λ₂` (`Rlambda1_ne_Rlambda2`) — for EVERY anchored η-data. -/
theorem constantClass_lamRec_fails (E : StieltjesEta) :
    ¬ SatisfiesRec (fun _ => one) 1
        (fun m => Radd (genuineLamSeq E.eta (1 + m)) (genuineLamSeq E.eta (1 + m))) := by
  intro h
  have h10 : Req (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))
      (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1)) := satisfiesRec_const_step h 0
  have h21 : Req (Radd Rlambda2 Rlambda2) (Radd Rlambda1 Rlambda1) :=
    Req_trans (Radd_congr (Req_symm (genuineLam_two E)) (Req_symm (genuineLam_two E)))
      (Req_trans h10 (Radd_congr (genuineLam_one E) (genuineLam_one E)))
  exact Rlambda1_ne_Rlambda2 (Rdouble_inj (Req_symm h21))

/-- **THE PRUNE, RECORDED**: no Gate-A finite list exists in the constant class
    `(K, a) = (1, 1)` — for every anchored η-data `E`, every atlas rule `ι`, and every
    dimension `D`. Period-one diagonals are dead as Gate-A candidates; the growth of `2λₙ`
    is already felt at `n = 2`. One finite certified fact kills the whole class. -/
theorem constantClass_pruned (E : StieltjesEta) (ι : AtlasRule) (D : Nat) :
    ¬ GateAList E ι D 1 (fun _ => one) :=
  fun h => constantClass_lamRec_fails E h.lamRec

-- ===========================================================================
-- The second prune: the entire CONTRACTION class (order 1, any coefficient ≤ 1).
-- ===========================================================================

/-- **The contraction class fails `lamRec`**: an order-1 recurrence with ANY real coefficient
    `c ≤ 1` forces `2λ₂ ≈ c·2λ₁ ≤ 2λ₁` (using `Pos λ₁`, so the doubled `λ₁` is non-negative),
    contradicting the certified gap `2λ₂ − 2λ₁ > 0` (`lambda_gap_pos_double`) through the order clash
    `not_Pos_of_Rnonneg_Rneg`. -/
theorem contractionClass_lamRec_fails (E : StieltjesEta) {c : Real} (hc : Rle c one) :
    ¬ SatisfiesRec (fun _ => c) 1
        (fun m => Radd (genuineLamSeq E.eta (1 + m)) (genuineLamSeq E.eta (1 + m))) := by
  intro h
  -- the one-step relation at n = 0, transported to the certified λ's
  have hstep : Req (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))
      (Rmul c (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))) :=
    satisfiesRec_order1_step h 0
  have h2 : Req (Radd Rlambda2 Rlambda2) (Rmul c (Radd Rlambda1 Rlambda1)) :=
    Req_trans (Radd_congr (Req_symm (genuineLam_two E)) (Req_symm (genuineLam_two E)))
      (Req_trans hstep (Rmul_congr (Req_refl c)
        (Radd_congr (genuineLam_one E) (genuineLam_one E))))
  -- contraction: c·(λ₁+λ₁) ≤ 1·(λ₁+λ₁) ≈ λ₁+λ₁ (the doubled λ₁ is non-negative)
  have h1n : Rnonneg (Radd Rlambda1 Rlambda1) :=
    Rnonneg_Radd (Rnonneg_of_Pos Rlambda1_pos) (Rnonneg_of_Pos Rlambda1_pos)
  have hb : Rle (Rmul c (Radd Rlambda1 Rlambda1)) (Radd Rlambda1 Rlambda1) :=
    Rle_trans (Rmul_le_Rmul_right h1n hc)
      (Rle_of_Req (Req_trans (Rmul_comm one (Radd Rlambda1 Rlambda1))
        (Rmul_one (Radd Rlambda1 Rlambda1))))
  have hle : Rle (Radd Rlambda2 Rlambda2) (Radd Rlambda1 Rlambda1) :=
    Rle_trans (Rle_of_Req h2) hb
  -- the clash with the certified gap
  have hneg : Rnonneg (Rneg (Rsub (Radd Rlambda2 Rlambda2) (Radd Rlambda1 Rlambda1))) := by
    refine Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle hle)
    exact Req_symm (Req_trans
      (Rneg_Radd (Radd Rlambda2 Rlambda2) (Rneg (Radd Rlambda1 Rlambda1)))
      (Req_trans (Radd_congr (Req_refl (Rneg (Radd Rlambda2 Rlambda2)))
        (Rneg_neg (Radd Rlambda1 Rlambda1)))
        (Radd_comm (Rneg (Radd Rlambda2 Rlambda2)) (Radd Rlambda1 Rlambda1))))
  exact not_Pos_of_Rnonneg_Rneg hneg lambda_gap_pos_double

/-- **THE SECOND PRUNE, RECORDED — the contraction class is dead**: no Gate-A finite list
    exists with order 1 and ANY coefficient `c ≤ 1` — for every anchored η-data, every atlas
    rule, and every dimension. This strictly generalizes `constantClass_pruned` (`c = 1`):
    the doubled Li sequence certifiably EXPANDS at the first step (`2λ₂ > 2λ₁ ≥ 0`), so no
    non-expanding order-1 rule can carry the Gate-A diagonal. The surviving order-1 candidates
    are the strict expansions `c > 1`; killing those needs `λ₃λ₁ vs λ₂²` (a `λ₃` upper — the
    next bracket on the certificate front). -/
theorem contractionClass_pruned (E : StieltjesEta) (ι : AtlasRule) (D : Nat) {c : Real}
    (hc : Rle c one) : ¬ GateAList E ι D 1 (fun _ => c) :=
  fun h => contractionClass_lamRec_fails E hc h.lamRec

-- ===========================================================================
-- The third prune: the ENTIRE order-1 family, any real coefficient.
-- ===========================================================================

/-- Two rationals with `p > q + 2/(n+1)` at some witness index `n` refute `ofQ p ≤ ofQ q`. -/
theorem not_Rle_ofQ_of_witness {p q : Q} (hp : 0 < p.den) (hq : 0 < q.den) (n : Nat)
    (hwit : ¬ Qle p (add q ⟨2, n + 1⟩)) : ¬ Rle (ofQ p hp) (ofQ q hq) :=
  fun h => hwit (h n)

/-- **The whole order-1 family fails `lamRec`** — for ANY real coefficient `c`, and every
    η-data anchored through `η₂`. The recurrence at `n = 0, 1` forces the coefficient-free
    product identity `(2λ₂)² ≈ (2λ₃)(2λ₁)` (associativity/commutativity eliminate `c`), and
    the certified brackets refute it:
    `(2λ₂)² ≥ (0.1594)² = 0.02540836 > 0.02433 ≥ 0.5108·0.04762 ≥ (2λ₃)(2λ₁)`
    (`Rlambda2_ge`, `Rlambda3_le`, `Rlambda1_le`, witness index `n = 2000`). -/
theorem order1Class_lamRec_fails (E : StieltjesEta3) (c : Real) :
    ¬ SatisfiesRec (fun _ => c) 1
        (fun m => Radd (genuineLamSeq E.eta (1 + m)) (genuineLamSeq E.eta (1 + m))) := by
  intro h
  -- the two one-step relations, transported to the certified λ's
  have r0 : Req (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))
      (Rmul c (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))) :=
    satisfiesRec_order1_step h 0
  have r1 : Req (Radd (genuineLamSeq E.eta 3) (genuineLamSeq E.eta 3))
      (Rmul c (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))) :=
    satisfiesRec_order1_step h 1
  have t0 : Req (Radd Rlambda2 Rlambda2) (Rmul c (Radd Rlambda1 Rlambda1)) :=
    Req_trans (Radd_congr (Req_symm (genuineLam_two E.toStieltjesEta))
        (Req_symm (genuineLam_two E.toStieltjesEta)))
      (Req_trans r0 (Rmul_congr (Req_refl c)
        (Radd_congr (genuineLam_one E.toStieltjesEta) (genuineLam_one E.toStieltjesEta))))
  have t1 : Req (Radd Rlambda3 Rlambda3) (Rmul c (Radd Rlambda2 Rlambda2)) :=
    Req_trans (Radd_congr (Req_symm (genuineLam_three E)) (Req_symm (genuineLam_three E)))
      (Req_trans r1 (Rmul_congr (Req_refl c)
        (Radd_congr (genuineLam_two E.toStieltjesEta) (genuineLam_two E.toStieltjesEta))))
  -- the coefficient-free product identity (c is eliminated by assoc/comm)
  have hprod : Req (Rmul (Radd Rlambda2 Rlambda2) (Radd Rlambda2 Rlambda2))
      (Rmul (Radd Rlambda3 Rlambda3) (Radd Rlambda1 Rlambda1)) := by
    refine Req_trans (Rmul_congr t0 (Req_refl (Radd Rlambda2 Rlambda2))) ?_
    refine Req_trans (Rmul_assoc c (Radd Rlambda1 Rlambda1) (Radd Rlambda2 Rlambda2)) ?_
    refine Req_trans (Rmul_congr (Req_refl c)
      (Rmul_comm (Radd Rlambda1 Rlambda1) (Radd Rlambda2 Rlambda2))) ?_
    refine Req_trans (Req_symm (Rmul_assoc c (Radd Rlambda2 Rlambda2)
      (Radd Rlambda1 Rlambda1))) ?_
    exact Rmul_congr (Req_symm t1) (Req_refl (Radd Rlambda1 Rlambda1))
  -- the doubled brackets
  have h2lo : Rle (ofQ (⟨1594, 10000⟩ : Q) (by decide)) (Radd Rlambda2 Rlambda2) := by
    have hstep : Rle (Radd (ofQ (⟨797, 10000⟩ : Q) (by decide))
        (ofQ (⟨797, 10000⟩ : Q) (by decide))) (Radd Rlambda2 Rlambda2) :=
      Radd_le_add Rlambda2_ge Rlambda2_ge
    exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
      (Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) hstep)
  have h3hi : Rle (Radd Rlambda3 Rlambda3) (ofQ (⟨5108, 10000⟩ : Q) (by decide)) := by
    have hstep : Rle (Radd Rlambda3 Rlambda3)
        (ofQ (add (⟨2554, 10000⟩ : Q) (⟨2554, 10000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add Rlambda3_le Rlambda3_le)
        (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans hstep (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h1hi : Rle (Radd Rlambda1 Rlambda1) (ofQ (⟨4762, 100000⟩ : Q) (by decide)) := by
    have hstep : Rle (Radd Rlambda1 Rlambda1)
        (ofQ (add (⟨2381, 100000⟩ : Q) (⟨2381, 100000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add Rlambda1_le Rlambda1_le)
        (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans hstep (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h2nn : Rnonneg (Radd Rlambda2 Rlambda2) :=
    Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg
      (Rnonneg_ofQ (by decide) (by decide))) h2lo)
  have h1nn : Rnonneg (Radd Rlambda1 Rlambda1) :=
    Rnonneg_Radd (Rnonneg_of_Pos Rlambda1_pos) (Rnonneg_of_Pos Rlambda1_pos)
  -- the two product bounds
  have hA : Rle (ofQ (mul (⟨1594, 10000⟩ : Q) (⟨1594, 10000⟩ : Q)) (by decide))
      (Rmul (Radd Rlambda2 Rlambda2) (Radd Rlambda2 Rlambda2)) := by
    have s1 : Rle (Rmul (ofQ (⟨1594, 10000⟩ : Q) (by decide))
        (ofQ (⟨1594, 10000⟩ : Q) (by decide)))
        (Rmul (Radd Rlambda2 Rlambda2) (ofQ (⟨1594, 10000⟩ : Q) (by decide))) :=
      Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) h2lo
    have s2 : Rle (Rmul (Radd Rlambda2 Rlambda2) (ofQ (⟨1594, 10000⟩ : Q) (by decide)))
        (Rmul (Radd Rlambda2 Rlambda2) (Radd Rlambda2 Rlambda2)) :=
      Rmul_le_Rmul_left h2nn h2lo
    exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rle_trans s1 s2)
  have hB : Rle (Rmul (Radd Rlambda3 Rlambda3) (Radd Rlambda1 Rlambda1))
      (ofQ (mul (⟨5108, 10000⟩ : Q) (⟨4762, 100000⟩ : Q)) (by decide)) := by
    have s1 : Rle (Rmul (Radd Rlambda3 Rlambda3) (Radd Rlambda1 Rlambda1))
        (Rmul (ofQ (⟨5108, 10000⟩ : Q) (by decide)) (Radd Rlambda1 Rlambda1)) :=
      Rmul_le_Rmul_right h1nn h3hi
    have s2 : Rle (Rmul (ofQ (⟨5108, 10000⟩ : Q) (by decide)) (Radd Rlambda1 Rlambda1))
        (Rmul (ofQ (⟨5108, 10000⟩ : Q) (by decide)) (ofQ (⟨4762, 100000⟩ : Q) (by decide))) :=
      Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) h1hi
    exact Rle_trans s1 (Rle_trans s2 (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))))
  -- the clash: 0.02540836 ≤ (2λ₂)² ≈ (2λ₃)(2λ₁) ≤ 0.02432430, refuted at witness n = 2000
  have hfinal : Rle (ofQ (mul (⟨1594, 10000⟩ : Q) (⟨1594, 10000⟩ : Q)) (by decide))
      (ofQ (mul (⟨5108, 10000⟩ : Q) (⟨4762, 100000⟩ : Q)) (by decide)) :=
    Rle_trans hA (Rle_trans (Rle_of_Req hprod) hB)
  exact not_Rle_ofQ_of_witness (by decide) (by decide) 2000 (by decide) hfinal

/-- **THE THIRD PRUNE, RECORDED — the ENTIRE order-1 family is dead**: for every η-data
    anchored through `η₂`, every atlas rule, every dimension, and EVERY real coefficient `c`,
    there is no Gate-A finite list of order 1. No single-term generating recurrence carries
    the Gate-A diagonal: the certified `λ₁, λ₂, λ₃` brackets refute the forced geometric
    relation `λ₂² = λ₃λ₁` outright. (Subsumes `constantClass_pruned` and
    `contractionClass_pruned` on η₂-anchored data; the kill consumed one more anchor than the
    contraction kill — order-K classes consume the first K+1 λ's, i.e. anchors through η_K.)
    The surviving frontier is order `K ≥ 2`. -/
theorem order1Class_pruned (E : StieltjesEta3) (ι : AtlasRule) (D : Nat) (c : Real) :
    ¬ GateAList E.toStieltjesEta ι D 1 (fun _ => c) :=
  fun h => order1Class_lamRec_fails E c h.lamRec

-- ===========================================================================
-- The fourth prune: the order-2 CONTRACTION class (both coefficients ≤ 1).
-- ===========================================================================

/-- **The order-2 contraction class fails `lamRec`**: with both coefficients `≤ 1` and the
    doubled λ's non-negative, the recurrence at `n = 0` forces
    `2λ₃ ≈ a₀·2λ₁ + a₁·2λ₂ ≤ 2λ₁ + 2λ₂ ≤ 0.25082`, refuted by `2λ₃ ≥ 0.2872`
    (`Rlambda1_le`, `Rlambda2_le`, `Rlambda3_ge`; witness index `n = 100`). This contains the
    shift candidate `(a₀, a₁) = (0, 1)` — the period-one-from-`n = 2` diagonals — as a special
    case. -/
theorem contractionClass2_lamRec_fails (E : StieltjesEta3) {a : Nat → Real}
    (h0 : Rle (a 0) one) (h1 : Rle (a 1) one) :
    ¬ SatisfiesRec a 2
        (fun m => Radd (genuineLamSeq E.eta (1 + m)) (genuineLamSeq E.eta (1 + m))) := by
  intro h
  have hstep : Req (Radd (genuineLamSeq E.eta 3) (genuineLamSeq E.eta 3))
      (Radd (Radd zero (Rmul (a 0) (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))))
        (Rmul (a 1) (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2)))) := h 0
  -- term 0: a₀·2λ'₁ ≤ 1·2λ'₁ ≈ 2λ'₁ ≤ 0.04762
  have hs0nn : Rnonneg (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1)) :=
    Rnonneg_congr (Req_symm (Radd_congr (genuineLam_one E.toStieltjesEta)
        (genuineLam_one E.toStieltjesEta)))
      (Rnonneg_Radd (Rnonneg_of_Pos Rlambda1_pos) (Rnonneg_of_Pos Rlambda1_pos))
  have hs0hi : Rle (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))
      (ofQ (⟨4762, 100000⟩ : Q) (by decide)) := by
    have hdb : Rle (Radd Rlambda1 Rlambda1)
        (ofQ (add (⟨2381, 100000⟩ : Q) (⟨2381, 100000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add Rlambda1_le Rlambda1_le)
        (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans (Rle_of_Req (Radd_congr (genuineLam_one E.toStieltjesEta)
        (genuineLam_one E.toStieltjesEta)))
      (Rle_trans hdb (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have ht0 : Rle (Rmul (a 0) (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1)))
      (ofQ (⟨4762, 100000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_right hs0nn h0)
      (Rle_trans (Rle_of_Req (Req_trans
          (Rmul_comm one (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1)))
          (Rmul_one (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))))) hs0hi)
  -- term 1: a₁·2λ'₂ ≤ 1·2λ'₂ ≈ 2λ'₂ ≤ 0.2032
  have hs1nn : Rnonneg (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2)) :=
    Rnonneg_congr (Req_symm (Radd_congr (genuineLam_two E.toStieltjesEta)
        (genuineLam_two E.toStieltjesEta)))
      (Rnonneg_Radd (Rnonneg_of_Pos Rlambda2_pos) (Rnonneg_of_Pos Rlambda2_pos))
  have hs1hi : Rle (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))
      (ofQ (⟨2032, 10000⟩ : Q) (by decide)) := by
    have hdb : Rle (Radd Rlambda2 Rlambda2)
        (ofQ (add (⟨1016, 10000⟩ : Q) (⟨1016, 10000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add Rlambda2_le Rlambda2_le)
        (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans (Rle_of_Req (Radd_congr (genuineLam_two E.toStieltjesEta)
        (genuineLam_two E.toStieltjesEta)))
      (Rle_trans hdb (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have ht1 : Rle (Rmul (a 1) (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2)))
      (ofQ (⟨2032, 10000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_right hs1nn h1)
      (Rle_trans (Rle_of_Req (Req_trans
          (Rmul_comm one (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2)))
          (Rmul_one (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))))) hs1hi)
  -- the whole right-hand side ≤ 0.25082
  have hz : Rle zero (ofQ (⟨0, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl zero)
  have hin : Rle (Radd zero (Rmul (a 0)
      (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))))
      (ofQ (add (⟨0, 1⟩ : Q) (⟨4762, 100000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add hz ht0) (Radd_Rle_ofQ_add (by decide) (by decide))
  have hup : Rle (Radd (Radd zero (Rmul (a 0)
      (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))))
      (Rmul (a 1) (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))))
      (ofQ (⟨25082, 100000⟩ : Q) (by decide)) := by
    have hsum : Rle (Radd (Radd zero (Rmul (a 0)
        (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))))
        (Rmul (a 1) (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))))
        (ofQ (add (add (⟨0, 1⟩ : Q) (⟨4762, 100000⟩ : Q)) (⟨2032, 10000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add hin ht1) (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  -- the left-hand side ≥ 0.2872
  have hlo : Rle (ofQ (⟨2872, 10000⟩ : Q) (by decide))
      (Radd (genuineLamSeq E.eta 3) (genuineLamSeq E.eta 3)) := by
    have hdb : Rle (ofQ (add (⟨1436, 10000⟩ : Q) (⟨1436, 10000⟩ : Q)) (by decide))
        (Radd Rlambda3 Rlambda3) :=
      Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
        (Radd_le_add Rlambda3_ge Rlambda3_ge)
    exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
      (Rle_trans hdb (Rle_of_Req (Req_symm
        (Radd_congr (genuineLam_three E) (genuineLam_three E)))))
  -- the clash: 0.2872 ≤ 2λ'₃ ≈ RHS ≤ 0.25082, refuted at witness n = 100
  have hfinal : Rle (ofQ (⟨2872, 10000⟩ : Q) (by decide))
      (ofQ (⟨25082, 100000⟩ : Q) (by decide)) :=
    Rle_trans hlo (Rle_trans (Rle_of_Req hstep) hup)
  exact not_Rle_ofQ_of_witness (by decide) (by decide) 100 (by decide) hfinal

/-- **THE FOURTH PRUNE, RECORDED — the order-2 contraction class is dead**: no Gate-A finite
    list exists at order 2 with BOTH coefficients `≤ 1` — for every η₂-anchored η-data, every
    atlas rule, and every dimension. The doubled Li sequence certifiably outruns any convex-ish
    combination of its two predecessors (`λ₃ ≥ 0.1436 > 0.12541 ≥ λ₁ + λ₂`). Contains the
    canonical shift class `(0, 1)`. The surviving order-2 candidates need a coefficient `> 1`;
    their kill (the 3×3 Hankel determinant on `λ₁..λ₅`) needs `λ₄, λ₅` uppers — the `γ₄`
    upper campaign, the next big numeric brick. -/
theorem contractionClass2_pruned (E : StieltjesEta3) (ι : AtlasRule) (D : Nat)
    {a : Nat → Real} (h0 : Rle (a 0) one) (h1 : Rle (a 1) one) :
    ¬ GateAList E.toStieltjesEta ι D 2 a :=
  fun h => contractionClass2_lamRec_fails E h0 h1 h.lamRec

-- ===========================================================================
-- The fifth prune: NON-POSITIVE coefficients, at EVERY order `K = 1..4`.
--
-- WHY THIS SHAPE, and where the contraction route stops. The two contraction prunes above
-- exploit `λ_{K+1} > λ₁ + … + λ_K`. That inequality is TRUE at `K = 1, 2` (proven above) and
-- true-but-razor-thin at `K = 3` (`λ₄ ≈ 0.3858` vs `λ₁+λ₂+λ₃ ≈ 0.3230`, needing the `λ₄` lower
-- to within ~1% of truth — far beyond the current bracket), and it is **FALSE from `K = 4` on**
-- (`λ₅ ≈ 0.518 < λ₁+λ₂+λ₃+λ₄ ≈ 0.7088`). So the contraction lever is mathematically exhausted,
-- not merely under-certified — recorded here so the route is not re-attempted.
--
-- The lever that DOES generalize over the order is the sign of the coefficients: a combination
-- of non-negative terms with non-positive coefficients is non-positive, while every doubled Li
-- value in reach is strictly positive. This kills one direction of the coefficient space at
-- every order at once, with no per-order numerics.
-- ===========================================================================

/-- A non-positive coefficient against a non-negative term gives a non-positive product. -/
theorem Rmul_nonpos_of_nonpos {c s : Real} (hc : Rle c zero) (hs : Rnonneg s) :
    Rle (Rmul c s) zero :=
  Rle_trans (Rmul_le_Rmul_right hs hc)
    (Rle_of_Req (Req_trans (Rmul_comm zero s) (Rmul_zero s)))

/-- A linear combination of non-negative terms with non-positive coefficients is non-positive. -/
theorem RsumN_nonpos {a s : Nat → Real} (K : Nat)
    (ha : ∀ i, i < K → Rle (a i) zero) (hs : ∀ i, i < K → Rnonneg (s i)) :
    Rle (RsumN (fun i => Rmul (a i) (s i)) K) zero :=
  Rle_trans (RsumN_le (G := fun _ => zero) K
      (fun i hi => Rmul_nonpos_of_nonpos (ha i hi) (hs i hi)))
    (Rle_of_Req (RsumN_zero K (fun _ _ => Req_refl zero)))

/-- A real bounded above by `0` is not strictly positive. -/
theorem not_Pos_of_Rle_zero {z : Real} (h : Rle z zero) : ¬ Pos z := by
  refine not_Pos_of_Rnonneg_Rneg (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  exact Req_trans (Radd_comm zero (Rneg z)) (Radd_zero (Rneg z))

/-- **THE NON-POSITIVE-COEFFICIENT CORE, general in the order `K`**: if every coefficient is
    `≤ 0` and the first `K` terms are non-negative, the recurrence forces `s K ≤ 0` — refuting
    any strictly positive `s K`. No numerics, no bound on `K`. -/
theorem nonPositive_lamRec_fails {a s : Nat → Real} (K : Nat)
    (ha : ∀ i, i < K → Rle (a i) zero) (hs : ∀ i, i < K → Rnonneg (s i))
    (hpos : Pos (s K)) : ¬ SatisfiesRec a K s := by
  intro h
  have h0 := h 0
  simp only [Nat.zero_add] at h0
  exact not_Pos_of_Rle_zero (Rle_trans (Rle_of_Req h0) (RsumN_nonpos K ha hs)) hpos

/-- The doubled genuine Li values are non-negative at `n = 1..4` (from `Pos λ₁..λ₄`). -/
private theorem dblLam_nonneg (E : StieltjesEta5) : ∀ i, i < 4 →
    Rnonneg (Radd (genuineLamSeq E.eta (1 + i)) (genuineLamSeq E.eta (1 + i)))
  | 0, _ => Rnonneg_of_Pos (Pos_congr
      (Radd_congr (Req_symm (genuineLam_one E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta))
        (Req_symm (genuineLam_one E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta)))
      (Pos_Radd_self Rlambda1_pos))
  | 1, _ => Rnonneg_of_Pos (Pos_congr
      (Radd_congr (Req_symm (genuineLam_two E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta))
        (Req_symm (genuineLam_two E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta)))
      (Pos_Radd_self Rlambda2_pos))
  | 2, _ => Rnonneg_of_Pos (Pos_congr
      (Radd_congr (Req_symm (genuineLam_three E.toStieltjesEta4.toStieltjesEta3))
        (Req_symm (genuineLam_three E.toStieltjesEta4.toStieltjesEta3)))
      (Pos_Radd_self Rlambda3_pos))
  | 3, _ => Rnonneg_of_Pos (Pos_congr
      (Radd_congr (Req_symm (genuineLam_four E.toStieltjesEta4))
        (Req_symm (genuineLam_four E.toStieltjesEta4)))
      (Pos_Radd_self Rlambda4_pos))
  | (n + 4), h => absurd h (by omega)

/-- The doubled genuine Li value is strictly positive at `n = 2..5` (from `Pos λ₂..λ₅`). -/
private theorem dblLam_pos (E : StieltjesEta5) : ∀ K, 0 < K → K ≤ 4 →
    Pos (Radd (genuineLamSeq E.eta (1 + K)) (genuineLamSeq E.eta (1 + K)))
  | 0, h, _ => absurd h (by omega)
  | 1, _, _ => Pos_congr
      (Radd_congr (Req_symm (genuineLam_two E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta))
        (Req_symm (genuineLam_two E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta)))
      (Pos_Radd_self Rlambda2_pos)
  | 2, _, _ => Pos_congr
      (Radd_congr (Req_symm (genuineLam_three E.toStieltjesEta4.toStieltjesEta3))
        (Req_symm (genuineLam_three E.toStieltjesEta4.toStieltjesEta3)))
      (Pos_Radd_self Rlambda3_pos)
  | 3, _, _ => Pos_congr
      (Radd_congr (Req_symm (genuineLam_four E.toStieltjesEta4))
        (Req_symm (genuineLam_four E.toStieltjesEta4)))
      (Pos_Radd_self Rlambda4_pos)
  | 4, _, _ => Pos_congr
      (Radd_congr (Req_symm (genuineLam_five E)) (Req_symm (genuineLam_five E)))
      (Pos_Radd_self Rlambda5_pos)
  | (n + 5), _, h => absurd h (by omega)

/-- **THE FIFTH PRUNE, RECORDED — no Gate-A finite list has all-non-positive coefficients, at
    EVERY order `K = 1..4`**: for every η₄-anchored η-data, every atlas rule, every dimension,
    and every coefficient family with `aᵢ ≤ 0` for all `i < K`. Unlike the contraction prunes
    this is uniform in the order and needs no numerics — only the certified positivity of
    `λ₁..λ₅`. (The `K ≤ 4` ceiling is exactly the reach of the certified `Pos λₙ` rungs: the
    argument extends to any `K` for which `Pos λ_{K+1}` is proven, so each future rung widens
    this prune by one order for free.) -/
theorem nonPositiveClass_pruned (E : StieltjesEta5) (ι : AtlasRule) (D : Nat) {K : Nat}
    (hK : 0 < K) (hK4 : K ≤ 4) {a : Nat → Real} (ha : ∀ i, i < K → Rle (a i) zero) :
    ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D K a :=
  fun h => nonPositive_lamRec_fails K ha
    (fun i hi => dblLam_nonneg E i (by omega)) (dblLam_pos E K hK hK4) h.lamRec

/-- **The degenerate order `K = 0` is dead**, for free and for every coefficient family: the
    empty recurrence forces `2λₙ ≈ 0` at every index, refuted by `Pos λ₁`. (Recorded so the
    prune ledger covers the order axis with no gap at its base.) -/
theorem orderZeroClass_pruned (E : StieltjesEta) (ι : AtlasRule) (D : Nat) (a : Nat → Real) :
    ¬ GateAList E ι D 0 a := by
  intro h
  have h0 := h.lamRec 0
  simp only [Nat.zero_add] at h0
  exact not_Pos_of_Rle_zero (Rle_of_Req h0)
    (Pos_congr (Radd_congr (Req_symm (genuineLam_one E)) (Req_symm (genuineLam_one E)))
      (Pos_Radd_self Rlambda1_pos))

-- ===========================================================================
-- The sixth prune: the CONVEX-COMBINATION lever, general in the order.
--
-- The cheapest lever available, and the one that scales: if the coefficients are non-negative
-- with `Σ aᵢ ≤ 1`, the recurrence caps `s K` by the MAXIMUM of the first `K` terms — so a
-- sequence that strictly exceeds that maximum kills the class. Against the doubled Li sequence
-- the required input is just `λ_K < λ_{K+1}` (certified at `K = 1, 2` by
-- `Rlambda_head_increasing`), instead of the contraction lever's far heavier
-- `λ_{K+1} > λ₁ + … + λ_K`.
-- ===========================================================================

/-- `Σ (F i · M) ≈ (Σ F) · M` — the right-scalar pull-out. -/
theorem RsumN_mul_right (F : Nat → Real) (M : Real) (N : Nat) :
    Req (RsumN (fun i => Rmul (F i) M) N) (Rmul (RsumN F N) M) := by
  induction N with
  | zero => exact Req_symm (Req_trans (Rmul_comm zero M) (Rmul_zero M))
  | succ n ih =>
    exact Req_trans (Radd_congr ih (Req_refl _))
      (Req_symm (Rmul_distrib_right (RsumN F n) (F n) M))

/-- `x ≤ y` gives `x − y ≤ 0`. -/
theorem Rle_Rsub_zero_of_Rle {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero :=
  Rle_trans (Radd_le_add h (Rle_refl (Rneg y))) (Rle_of_Req (Radd_neg y))

/-- **THE CONVEX CAP**: non-negative coefficients summing to at most `1`, against terms all
    bounded by a non-negative `M`, cap the next term by `M`. General in the order `K`. -/
theorem convex_cap {a s : Nat → Real} (K : Nat) {M : Real} (hM : Rnonneg M)
    (ha : ∀ i, i < K → Rnonneg (a i)) (hsum : Rle (RsumN a K) one)
    (hs : ∀ i, i < K → Rle (s i) M) (h : SatisfiesRec a K s) : Rle (s K) M := by
  have h0 := h 0
  simp only [Nat.zero_add] at h0
  refine Rle_trans (Rle_of_Req h0) ?_
  refine Rle_trans (RsumN_le K (fun i hi => Rmul_le_Rmul_left (ha i hi) (hs i hi))) ?_
  refine Rle_trans (Rle_of_Req (RsumN_mul_right a M K)) ?_
  exact Rle_trans (Rmul_le_Rmul_right hM hsum)
    (Rle_of_Req (Req_trans (Rmul_comm one M) (Rmul_one M)))

/-- **THE CONVEX-COMBINATION CORE**: a convex coefficient family cannot drive a sequence
    strictly above the maximum of its own window. General in the order `K`; the only numeric
    input is the strict growth `Pos (s K − M)`. -/
theorem convex_lamRec_fails {a s : Nat → Real} (K : Nat) {M : Real} (hM : Rnonneg M)
    (ha : ∀ i, i < K → Rnonneg (a i)) (hsum : Rle (RsumN a K) one)
    (hs : ∀ i, i < K → Rle (s i) M) (hgrow : Pos (Rsub (s K) M)) :
    ¬ SatisfiesRec a K s :=
  fun h => not_Pos_of_Rle_zero (Rle_Rsub_zero_of_Rle (convex_cap K hM ha hsum hs h)) hgrow

/-- Doubling a difference: `2a − 2b ≈ (a−b) + (a−b)`. -/
theorem Rsub_double (a b : Real) :
    Req (Rsub (Radd a a) (Radd b b)) (Radd (Rsub a b) (Rsub a b)) :=
  Req_trans (Radd_congr (Req_refl (Radd a a)) (Rneg_Radd b b))
    (Radd_rearrange4 a a (Rneg b) (Rneg b))

/-- A strict gap doubles. -/
theorem Pos_Rsub_double {a b : Real} (h : Pos (Rsub a b)) :
    Pos (Rsub (Radd a a) (Radd b b)) :=
  Pos_congr (Req_symm (Rsub_double a b)) (Pos_Radd_self h)

/-- **THE SIXTH PRUNE — the convex class is dead at orders `K = 1, 2`**: no Gate-A finite list
    has non-negative coefficients summing to at most `1`, for every η₂-anchored η-data, every
    rule, and every dimension. (At `K = 1, 2` this is implied by the contraction prunes; it is
    stated because the LEVER, unlike those, scales: `convex_lamRec_fails` is general in `K` and
    needs only `λ_K < λ_{K+1}`. The `K = 3` instance is a one-liner the moment
    `Pos (λ₄ − λ₃)` is certified — an arithmetic check confirms
    `λ₄ − λ₃ ≥ 0.047033` is already reachable from brackets IN STOCK, through the difference
    identity `λ₄ − λ₃ = γ − 3η₁ − 3η₂ − η₃ − ½(γ+log4π) + (9/4)ζ(2) − (21/8)ζ(3) + (15/16)ζ(4)`,
    whose additive-cancellation mechanization is the outstanding work; bounding `λ₄` and `λ₃`
    separately does NOT suffice — `0.2185 < 0.2486` — because it pays each `η` bracket width
    twice.) -/
theorem convexClass12_pruned (E : StieltjesEta3) (ι : AtlasRule) (D : Nat)
    {a : Nat → Real} {K : Nat} (hK : 0 < K) (hK2 : K ≤ 2)
    (ha : ∀ i, i < K → Rnonneg (a i)) (hsum : Rle (RsumN a K) one) :
    ¬ GateAList E.toStieltjesEta ι D K a := by
  intro h
  -- the doubled genuine head, transported to the certified λ's
  have e1 : Req (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1)) (Radd Rlambda1 Rlambda1) :=
    Radd_congr (genuineLam_one E.toStieltjesEta) (genuineLam_one E.toStieltjesEta)
  have e2 : Req (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2)) (Radd Rlambda2 Rlambda2) :=
    Radd_congr (genuineLam_two E.toStieltjesEta) (genuineLam_two E.toStieltjesEta)
  have e3 : Req (Radd (genuineLamSeq E.eta 3) (genuineLamSeq E.eta 3)) (Radd Rlambda3 Rlambda3) :=
    Radd_congr (genuineLam_three E) (genuineLam_three E)
  have g12 : Pos (Rsub (Radd Rlambda2 Rlambda2) (Radd Rlambda1 Rlambda1)) :=
    Pos_Rsub_double Rlambda1_lt_Rlambda2
  have g23 : Pos (Rsub (Radd Rlambda3 Rlambda3) (Radd Rlambda2 Rlambda2)) :=
    Pos_Rsub_double Rlambda2_lt_Rlambda3
  have n1 : Rnonneg (Radd Rlambda1 Rlambda1) :=
    Rnonneg_Radd (Rnonneg_of_Pos Rlambda1_pos) (Rnonneg_of_Pos Rlambda1_pos)
  have n2 : Rnonneg (Radd Rlambda2 Rlambda2) :=
    Rnonneg_Radd (Rnonneg_of_Pos Rlambda2_pos) (Rnonneg_of_Pos Rlambda2_pos)
  match K, hK, hK2 with
  | 1, _, _ =>
    refine convex_lamRec_fails 1 (M := Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1))
      (Rnonneg_congr (Req_symm e1) n1) ha hsum (fun i hi => ?_) ?_ h.lamRec
    · exact (by omega : i = 0) ▸ Rle_refl _
    · exact Pos_congr (Req_symm (Radd_congr e2 (Rneg_congr e1))) g12
  | 2, _, _ =>
    refine convex_lamRec_fails 2 (M := Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2))
      (Rnonneg_congr (Req_symm e2) n2) ha hsum (fun i hi => ?_) ?_ h.lamRec
    · match i, hi with
      | 0, _ =>
        exact Rle_trans (Rle_of_Req e1) (Rle_trans
          (Rle_of_Rnonneg_Rsub (Rnonneg_of_Pos g12)) (Rle_of_Req (Req_symm e2)))
      | 1, _ => exact Rle_refl _
      | (n + 2), hn => exact absurd hn (by omega)
    · exact Pos_congr (Req_symm (Radd_congr e3 (Rneg_congr e2))) g23

/-- **THE CONVEX CLASS AT ORDER 3 — now certified**, on the strength of `Rlambda3_lt_Rlambda4`
    (`Analysis/LambdaFourThreeGap.lean`): no Gate-A finite list of order `3` has non-negative
    coefficients summing to at most `1`. This is the first kill at order `3`, and it is NOT
    reachable by the contraction lever, whose order-3 form `λ₄ > λ₁+λ₂+λ₃` is true only by
    `1.3%` — far beyond the bracket. The convex lever needs only `λ₃ < λ₄`, a `34%` margin. -/
theorem convexClass3_pruned (E : StieltjesEta4) (ι : AtlasRule) (D : Nat)
    {a : Nat → Real} (ha : ∀ i, i < 3 → Rnonneg (a i)) (hsum : Rle (RsumN a 3) one) :
    ¬ GateAList E.toStieltjesEta3.toStieltjesEta ι D 3 a := by
  intro h
  have e1 : Req (Radd (genuineLamSeq E.eta 1) (genuineLamSeq E.eta 1)) (Radd Rlambda1 Rlambda1) :=
    Radd_congr (genuineLam_one E.toStieltjesEta3.toStieltjesEta)
      (genuineLam_one E.toStieltjesEta3.toStieltjesEta)
  have e2 : Req (Radd (genuineLamSeq E.eta 2) (genuineLamSeq E.eta 2)) (Radd Rlambda2 Rlambda2) :=
    Radd_congr (genuineLam_two E.toStieltjesEta3.toStieltjesEta)
      (genuineLam_two E.toStieltjesEta3.toStieltjesEta)
  have e3 : Req (Radd (genuineLamSeq E.eta 3) (genuineLamSeq E.eta 3)) (Radd Rlambda3 Rlambda3) :=
    Radd_congr (genuineLam_three E.toStieltjesEta3) (genuineLam_three E.toStieltjesEta3)
  have e4 : Req (Radd (genuineLamSeq E.eta 4) (genuineLamSeq E.eta 4)) (Radd Rlambda4 Rlambda4) :=
    Radd_congr (genuineLam_four E) (genuineLam_four E)
  have n3 : Rnonneg (Radd Rlambda3 Rlambda3) :=
    Rnonneg_Radd (Rnonneg_of_Pos Rlambda3_pos) (Rnonneg_of_Pos Rlambda3_pos)
  have le12 : Rle (Radd Rlambda1 Rlambda1) (Radd Rlambda2 Rlambda2) :=
    Rle_of_Rnonneg_Rsub (Rnonneg_of_Pos (Pos_Rsub_double Rlambda1_lt_Rlambda2))
  have le23 : Rle (Radd Rlambda2 Rlambda2) (Radd Rlambda3 Rlambda3) :=
    Rle_of_Rnonneg_Rsub (Rnonneg_of_Pos (Pos_Rsub_double Rlambda2_lt_Rlambda3))
  refine convex_lamRec_fails 3 (M := Radd (genuineLamSeq E.eta 3) (genuineLamSeq E.eta 3))
    (Rnonneg_congr (Req_symm e3) n3) ha hsum (fun i hi => ?_) ?_ h.lamRec
  · match i, hi with
    | 0, _ =>
      exact Rle_trans (Rle_of_Req e1)
        (Rle_trans (Rle_trans le12 le23) (Rle_of_Req (Req_symm e3)))
    | 1, _ =>
      exact Rle_trans (Rle_of_Req e2) (Rle_trans le23 (Rle_of_Req (Req_symm e3)))
    | 2, _ => exact Rle_refl _
    | (n + 3), hn => exact absurd hn (by omega)
  · exact Pos_congr (Req_symm (Radd_congr e4 (Rneg_congr e3)))
      (Pos_Rsub_double Rlambda3_lt_Rlambda4)

/-- **The convex class is dead at every order `K = 1, 2, 3`** — the three instantiations of
    `convex_lamRec_fails` the certified head `λ₁ < λ₂ < λ₃ < λ₄` supports. -/
theorem convexClass123_pruned (E : StieltjesEta5) (ι : AtlasRule) (D : Nat) {K : Nat}
    (hK : 0 < K) (hK3 : K ≤ 3) {a : Nat → Real} (ha : ∀ i, i < K → Rnonneg (a i))
    (hsum : Rle (RsumN a K) one) :
    ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D K a := by
  match K, hK, hK3 with
  | 1, _, _ =>
    exact convexClass12_pruned E.toStieltjesEta4.toStieltjesEta3 ι D
      (by omega) (by omega) ha hsum
  | 2, _, _ =>
    exact convexClass12_pruned E.toStieltjesEta4.toStieltjesEta3 ι D
      (by omega) (by omega) ha hsum
  | 3, _, _ => exact convexClass3_pruned E.toStieltjesEta4 ι D ha hsum

-- ===========================================================================
-- The prune ledger, as one kernel-checked statement.
-- ===========================================================================

/-- **THE GATE-A PRUNE LEDGER** — everything the certificate front has killed, in one place.
    For every η₄-anchored η-data `E`, every atlas rule `ι`, and every dimension `D`, NO Gate-A
    finite list exists in any of these classes:

    1. order `0` (any coefficients) — the degenerate empty recurrence;
    2. order `1`, ANY real coefficient — the Hankel-2 clash `(2λ₂)² ≉ (2λ₃)(2λ₁)`;
    3. order `2` with both coefficients `≤ 1` (contains the shift class `(0,1)`) —
       `λ₁ + λ₂ < λ₃`;
    4. order `K = 1..4` with ALL coefficients `≤ 0` — the sign lever, uniform in the order.

    5. orders `K = 1, 2, 3` with non-negative coefficients summing to at most `1` — the convex
       lever, on the certified strictly-increasing head `λ₁ < λ₂ < λ₃ < λ₄`.

    What SURVIVES: order `2` with an expanding coefficient, orders `3, 4` with a coefficient
    outside the convex/non-positive regions, and every order `K ≥ 5`.

    THE THREE LEVERS AND WHERE EACH STOPS (recorded so none is re-attempted blindly):
    - the SIGN lever (item 4) is free and uniform, and each future rung `Pos λ_{K+1}` widens it
      by one order at no cost;
    - the CONTRACTION lever (item 3) is mathematically exhausted at `K ≥ 4`
      (`λ₅ ≈ 0.518 < λ₁+λ₂+λ₃+λ₄ ≈ 0.709`), and already only `1.3%`-true at `K = 3`;
    - the CONVEX lever (item 5) needs `λ_K < λ_{K+1}`. It reaches `K = 3` on
      `Rlambda3_lt_Rlambda4`. Extending to `K = 4` needs `λ₄ < λ₅`, and an exact rational check
      of the same difference route gives only `λ₅ − λ₄ ≥ −0.195` (true `+0.132`): the slack is
      dominated by `4η₃` (the `γ₃ ∈ [−1/20, 1/40]` width, `≈ 0.126`) and by `η₄`, which carries
      `γ₄` with NO upper bracket built. So `K = 4` is blocked on the `γ₃` tightening and the
      `γ₄`-upper campaign — a numeric program, not a mechanization gap.

    NOTHING here approaches the crux: pruning candidate classes narrows the search for the
    single certificate, it never produces one. The crux fields stay `none`. -/
theorem gateA_prune_ledger (E : StieltjesEta5) (ι : AtlasRule) (D : Nat) :
    (∀ a : Nat → Real,
        ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D 0 a)
    ∧ (∀ c : Real,
        ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D 1 (fun _ => c))
    ∧ (∀ a : Nat → Real, Rle (a 0) one → Rle (a 1) one →
        ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D 2 a)
    ∧ (∀ (K : Nat) (a : Nat → Real), 0 < K → K ≤ 4 → (∀ i, i < K → Rle (a i) zero) →
        ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D K a)
    ∧ (∀ (K : Nat) (a : Nat → Real), 0 < K → K ≤ 3 → (∀ i, i < K → Rnonneg (a i)) →
        Rle (RsumN a K) one →
        ¬ GateAList E.toStieltjesEta4.toStieltjesEta3.toStieltjesEta ι D K a) :=
  ⟨fun a => orderZeroClass_pruned _ ι D a,
   fun c => order1Class_pruned E.toStieltjesEta4.toStieltjesEta3 ι D c,
   fun _a h0 h1 => contractionClass2_pruned E.toStieltjesEta4.toStieltjesEta3 ι D h0 h1,
   fun _K _a hK hK4 ha => nonPositiveClass_pruned E ι D hK hK4 ha,
   fun K a hK hK3 ha hsum => convexClass123_pruned E ι D hK hK3 ha hsum⟩

end UOR.Bridge.F1Square.Square
