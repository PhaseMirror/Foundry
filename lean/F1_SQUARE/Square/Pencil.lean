/-
F1 square — v0.17.0 stage C, brick 4: the PARALLEL PENCIL on canonical `𝕊`, with its
shift lengths `log n` as constructive reals — the §2.3 structural finding lifted from the
candidate bi-tropical model to theorems on the constructed square.

Companion §2.3. The finding, in three theorem layers on canonical `𝕊` (brick 2/3):

  1. POINT LEVEL (brick 3): the Frobenius correspondences `Γ_n` are the flow translates of
     the diagonal (`graph_translate_diag`), pairwise disjoint (`graph_disjoint`), and `Δ`
     meets none of them transversally (`diag_inter_graph_empty`) — a PARALLEL PENCIL with
     no transverse fixed points.

  2. LOG/TROPICAL LEVEL (this brick): in the tropical coordinate `log` (the constructive
     `logN` of the analysis layer), every `Γ_n` is the AFFINE SHIFT `y = x + log n`
     (`pencil_shift`) of slope 1 (`pencil_parallel` — the recession direction is `(1,1)`,
     the diagonal's own; hence the stable-intersection multiplicity
     `Δ·Γ_n = |det((1,1),(1,1))| = 0`, `pencil_det_zero`, tying to the mechanized
     `Tropical.Signature.parallel_pencil`).

  3. ARITHMETIC CONTENT (this brick): the pencil member `Γ_n` sits at the CONSTANT
     separation `log n` from `Δ` (`pencil_separation`) — and at a PRIME `p` that
     separation is exactly the von Mangoldt weight `Λ(p) = log p`
     (`pencil_separation_vonMangoldt`), the explicit-formula prime-side weight
     (`Analysis/Mangoldt.lean`); at a prime power `p^k` it is `k·log p`
     (`pencil_separation_pow`) — the closed orbit of length `log p` traversed `k` times.
     THIS is the precise sense in which "the arithmetic content relocates to the shift
     length": the function-field fixed-point count `Δ·Γ_q = q+1−a` has no transverse
     counterpart on `𝕊` (layer 1), and what indexes the pencil is the explicit formula's
     prime weights.

  The technical key is `logN_mul_general` — `log(ab) = log a + log b` for ALL positive
  naturals (the base-2 case shipped in v0.15.2; the general case is proved here by the same
  exp-injectivity route) — and `logN_pow_general` (`log(pᵏ) = k·log p`).

HONEST SCOPE (= the §2.3 control, `Bridge.control_psd`): the pencil's POSITIVITY — whether
the shift-length structure carries the Weil positivity — is equivalent to RH and stays OPEN;
nothing here bears on it. These are structure theorems, not positivity theorems.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Divisors
import F1Square.Tropical.Signature
import F1Square.Analysis.Mangoldt

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

private theorem ofQ_natmul (a b : Nat) :
    Req (ofQ (mul (⟨(a : Int), 1⟩ : Q) ⟨(b : Int), 1⟩) (Qmul_den_pos Nat.one_pos Nat.one_pos))
      (ofQ (⟨((a * b : Nat) : Int), 1⟩ : Q) Nat.one_pos) :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (mul (⟨(a : Int), 1⟩ : Q) ⟨(b : Int), 1⟩) ⟨((a * b : Nat) : Int), 1⟩
    simp only [Qeq, mul]; push_cast; ring_uor)

/-- **`log(ab) = log a + log b` for all positive naturals** — the general
    log-multiplicativity, by `exp` injectivity (`exp(log a + log b) = exp(log a)·exp(log b)
    = a·b = exp(log ab)`). Generalizes the v0.15.2 base-2 keystone `logN_mul`. -/
theorem logN_mul_general (a b : Nat) (ha : 1 ≤ a) (hb : 1 ≤ b) (hab : 1 ≤ a * b) :
    Req (Radd (logN a ha) (logN b hb)) (logN (a * b) hab) := by
  refine RexpReal_inj (Rnonneg_Radd (Rnonneg_logN a ha) (Rnonneg_logN b hb))
    (Rnonneg_logN (a * b) hab) ?_
  refine Req_trans (RexpReal_add (logN a ha) (logN b hb)) ?_
  refine Req_trans (Rmul_congr (Rexp_logN a ha) (Rexp_logN b hb)) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos) ?_
  exact Req_trans (ofQ_natmul a b) (Req_symm (Rexp_logN (a * b) hab))

/-- **`log(pᵏ) = k·log p`** for every positive base — the flow linearization
    (generalizes the dyadic `logN_pow_two`). -/
theorem logN_pow_general (p : Nat) (hp : 1 ≤ p) (k : Nat) (hpk : 1 ≤ p ^ k) :
    Req (logN (p ^ k) hpk) (Rnsmul k (logN p hp)) := by
  induction k with
  | zero =>
      refine Req_trans (logN_eq_of_eq (show p ^ 0 = 1 from rfl) hpk (by omega)) ?_
      rw [Rnsmul_zero]
      exact logN_one
  | succ k ih =>
      have hpk' : 1 ≤ p ^ k := Nat.pos_pow_of_pos k (by omega)
      refine Req_trans (logN_eq_of_eq (Nat.pow_succ p k) hpk (one_le_mul hpk' hp)) ?_
      refine Req_trans (Req_symm (logN_mul_general (p ^ k) p hpk' hp
        (one_le_mul hpk' hp))) ?_
      refine Req_trans (Radd_congr (ih hpk') (Req_refl (logN p hp))) ?_
      rw [Rnsmul_succ]
      exact Radd_comm (Rnsmul k (logN p hp)) (logN p hp)

private theorem rsub_self_zero (x : Real) : Req (Rsub x x) zero := Radd_neg x

private theorem radd_sub_cancel (x c : Real) : Req (Rsub (Radd x c) x) c := by
  refine Req_trans (Rsub_congr (Req_refl (Radd x c)) (Req_symm (Radd_zero x))) ?_
  refine Req_trans (Rsub_Radd_Radd x c x zero) ?_
  refine Req_trans (Radd_congr (rsub_self_zero x) (Rsub_zero c)) ?_
  exact Req_trans (Radd_comm zero c) (Radd_zero c)

/-- **THE AFFINE SHIFT** (§2.3, layer 2): on `Γ_n`, the tropical (log) coordinates satisfy
    `log y = log x + log n` — the graph of the scaling Frobenius is the shift of the
    diagonal by `log n`, EXACTLY (a constructive-real identity, not a model assumption). -/
theorem pencil_shift (n : Nat) (hn : 1 ≤ n) (z : SqPt) (hz : graph n z) :
    Req (logN z.2.val z.2.property)
      (Radd (logN z.1.val z.1.property) (logN n hn)) := by
  have hv : z.2.val = n * z.1.val := hz
  refine Req_trans (logN_eq_of_eq hv z.2.property (one_le_mul hn z.1.property)) ?_
  refine Req_trans (Req_symm (logN_mul_general n z.1.val hn z.1.property
    (one_le_mul hn z.1.property))) ?_
  exact Radd_comm (logN n hn) (logN z.1.val z.1.property)

/-- **SLOPE 1 / PARALLELISM** (§2.3, layer 2): between any two points of the same `Γ_n`,
    the log-rise equals the log-run — every pencil member has recession direction `(1,1)`,
    the diagonal's own. -/
theorem pencil_parallel (n : Nat) (hn : 1 ≤ n) (z w : SqPt)
    (hz : graph n z) (hw : graph n w) :
    Req (Rsub (logN z.2.val z.2.property) (logN w.2.val w.2.property))
      (Rsub (logN z.1.val z.1.property) (logN w.1.val w.1.property)) := by
  refine Req_trans (Rsub_congr (pencil_shift n hn z hz) (pencil_shift n hn w hw)) ?_
  refine Req_trans (Rsub_Radd_Radd (logN z.1.val z.1.property) (logN n hn)
    (logN w.1.val w.1.property) (logN n hn)) ?_
  refine Req_trans (Radd_congr
    (Req_refl (Rsub (logN z.1.val z.1.property) (logN w.1.val w.1.property)))
    (rsub_self_zero (logN n hn))) ?_
  exact Radd_zero (Rsub (logN z.1.val z.1.property) (logN w.1.val w.1.property))

/-- **THE STABLE-INTERSECTION COUNT** (§2.3): both `Δ` and every `Γ_n` have tropical
    direction `(1,1)` (`pencil_parallel`), so the stable-intersection multiplicity is
    `Δ·Γ_n = |det((1,1),(1,1))| = 0` — the mechanized `Tropical.Signature.parallel_pencil`,
    now ATTACHED to the canonical square's pencil (whose point-level counterpart is
    `diag_inter_graph_empty`: no transverse fixed points). -/
theorem pencil_det_zero : Tropical.Signature.det2 1 1 1 1 = 0 :=
  Tropical.Signature.parallel_pencil

/-- **CONSTANT SEPARATION `log n`** (§2.3, layer 3): every point of `Γ_n` sits at the same
    log-distance `log n` above the diagonal — the pencil is indexed by the shift length. -/
theorem pencil_separation (n : Nat) (hn : 1 ≤ n) (z : SqPt) (hz : graph n z) :
    Req (Rsub (logN z.2.val z.2.property) (logN z.1.val z.1.property)) (logN n hn) := by
  refine Req_trans (Rsub_congr (pencil_shift n hn z hz)
    (Req_refl (logN z.1.val z.1.property))) ?_
  exact radd_sub_cancel (logN z.1.val z.1.property) (logN n hn)

/-- **THE ARITHMETIC CONTENT IS THE PRIME WEIGHT** (§2.3, layer 3): at a prime `p`, the
    separation of `Γ_p` from `Δ` is exactly the von Mangoldt weight `Λ(p) = log p` — the
    explicit-formula prime-side weight (`Analysis.primeSide`). The function-field
    fixed-point count `Δ·Γ_q = q+1−a` has NO transverse counterpart on `𝕊`
    (`diag_inter_graph_empty`); what the pencil carries instead is `Λ`. -/
theorem pencil_separation_vonMangoldt (p : Nat) (hp2 : 2 ≤ p)
    (hp : ∀ d, d ∣ p → d = 1 ∨ d = p) (z : SqPt) (hz : graph p z) :
    Req (Rsub (logN z.2.val z.2.property) (logN z.1.val z.1.property))
      (vonMangoldt p) :=
  Req_trans (pencil_separation p (by omega) z hz)
    (Req_symm (vonMangoldt_prime hp2 hp))

/-- **PRIME-POWER SEPARATION `k·log p`** (§2.3, layer 3): the pencil member `Γ_{pᵏ}` sits
    at separation `k·log p` — the closed orbit of length `log p` traversed `k` times
    (the Connes–Consani orbit picture, companion §0.2). -/
theorem pencil_separation_pow (p : Nat) (hp : 1 ≤ p) (k : Nat) (hpk : 1 ≤ p ^ k)
    (z : SqPt) (hz : graph (p ^ k) z) :
    Req (Rsub (logN z.2.val z.2.property) (logN z.1.val z.1.property))
      (Rnsmul k (logN p hp)) :=
  Req_trans (pencil_separation (p ^ k) hpk z hz) (logN_pow_general p hp k hpk)

private theorem rnsmul_congr {x y : Real} (h : Req x y) :
    ∀ k : Nat, Req (Rnsmul k x) (Rnsmul k y) := by
  intro k
  induction k with
  | zero => exact Req_refl zero
  | succ j ih =>
    rw [Rnsmul_succ, Rnsmul_succ]
    exact Radd_congr h ih

/-- **THE PENCIL SEPARATION IS `k·Λ(pᵏ)` AT EVERY PRIME POWER** (§2.3, layer 3, the general
    Λ-tie): for a prime `p` and any `k ≥ 1`, every point of `Γ_{pᵏ}` sits at log-separation
    `k·Λ(pᵏ)` from the diagonal — since `Λ(pᵏ) = log p` in general
    (`vonMangoldt_prime_pow`, via the from-scratch Euclid's lemma `prime_dvd_mul`). With
    `pencil_separation_vonMangoldt` (the `k = 1` case) this closes the identification of
    the pencil's shift lengths with the explicit-formula weights on the FULL prime-power
    support of `Λ`, not merely at primes. -/
theorem pencil_separation_pow_vonMangoldt (p : Nat) (hp2 : 2 ≤ p)
    (hp : ∀ d, d ∣ p → d = 1 ∨ d = p) (k : Nat) (hk : 1 ≤ k) (hpk : 1 ≤ p ^ k)
    (z : SqPt) (hz : graph (p ^ k) z) :
    Req (Rsub (logN z.2.val z.2.property) (logN z.1.val z.1.property))
      (Rnsmul k (vonMangoldt (p ^ k))) :=
  Req_trans (pencil_separation_pow p (by omega) k hpk z hz)
    (rnsmul_congr (Req_symm (vonMangoldt_prime_pow hp2 hp hk)) k)

end UOR.Bridge.F1Square.Square
