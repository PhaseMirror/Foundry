/-
F1 square — **the finite-rank impossibility fence for the genuine diagonal** (`AngleEmbeddingBound.lean`).
A crux-directed *localization* brick: it converts "no fixed-dimension bounded-entry Euclidean embedding can
realize `2λₙ`" from folklore into a kernel-checked theorem, and thereby explains — non-smugglingly — WHY
every finite atlas Gram (`e8Roots`, `atlasM (10,14)`, the Hurwitz companion) is *off-object*.

The SOS face of the crux (`realizesDiag_genuine_iff`) asks for an `AtlasRule ι` with
`gramOf ι D n n = 2λₙ` for all `n`. On the critical line the *on-object* certificate is the sine-square
block, one pair per zero `ρ = ½ + iθ`:

    `2·(1 − cos(nθ)) = (1 − cos(nθ))² + sin(nθ)²`

so `2λₙ = Σ_ρ 2(1 − cos(nθ_ρ))` would be `gramOf` of the entries `(1 − cos(nθ_ρ), sin(nθ_ρ))`. Those entries
lie in `[−2, 2]`, hence are **uniformly bounded in `n`**. This brick proves the structural consequence:

  `gramDiag_uniform_bound`        :  entry-squares `≤ ofQ c` (uniform in `n`)  ⟹  `gramOf ι D n n ≤` an
                                     `n`-independent bound (`RsumN (const c) D`);
  `realized_seq_uniformly_bounded`:  hence any sequence such an embedding realizes is bounded uniformly in `n`;
  `trigEmb` / `trigGram_uniform_bound` : the concrete trig-parametrized instance (entries `cos`/`sin`, a
                                     free angle family `θ`, zero-free by type — §6) has uniformly-bounded diagonal.

Since the genuine diagonal grows `2λₙ ~ n log n` (Voros/Lagarias — *unbounded* in `n`), NO fixed-dimension
embedding with uniformly-bounded entries — in particular no finite sine-square/atlas Gram — realizes it.
The on-object certificate is therefore **infinite-rank**: the `Σ_ρ` over all zeros cannot be truncated.

HONEST SCOPE. A kernel-checked *negative/structural* result (a fence), non-smuggling: it uses only
`cos, sin ∈ [−1,1]` and a free angle family; it makes NO claim about the sign of `2λₙ`, and does NOT close
or approach the crux — it sharpens the localization by proving the finite-rank route structurally
impossible. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.WeilPSD
import Foundations.F1.Analysis.CosSinBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The general fence: bounded entry-squares ⟹ diagonal bounded uniformly in n.
-- ===========================================================================

/-- **★ THE FINITE-RANK FENCE**: if every entry-square of a `D`-dimensional embedding is `≤ ofQ c`
    (a bound independent of `n`), then the Gram diagonal is `≤ RsumN (const (ofQ c)) D` — an
    `n`-independent bound. A fixed-dimension, uniformly-bounded-entry embedding has a uniformly-bounded
    squared-norm diagonal. -/
theorem gramDiag_uniform_bound {ι : Nat → Nat → Real} {D : Nat} {c : Q} (hc : 0 < c.den)
    (h : ∀ n k, k < D → Rle (Rmul (ι n k) (ι n k)) (ofQ c hc)) (n : Nat) :
    Rle (gramOf ι D n n) (RsumN (fun _ => ofQ c hc) D) :=
  RsumN_le D (fun k hk => h n k hk)

/-- **★ THE IMPOSSIBILITY COROLLARY**: a sequence realized as the diagonal of such an embedding is
    bounded *uniformly in `n`* by an `n`-independent constant. Contrapositive: a sequence unbounded in
    `n` (e.g. `2λₙ ~ n log n`) is not the diagonal of any fixed-dimension, uniformly-bounded-entry
    embedding. -/
theorem realized_seq_uniformly_bounded {ι : Nat → Nat → Real} {D : Nat} {c : Q} (hc : 0 < c.den)
    (h : ∀ n k, k < D → Rle (Rmul (ι n k) (ι n k)) (ofQ c hc))
    {s : Nat → Real} (hreal : ∀ n, Req (gramOf ι D n n) (s n)) (n : Nat) :
    Rle (s n) (RsumN (fun _ => ofQ c hc) D) :=
  Rle_trans (Rle_of_Req (Req_symm (hreal n))) (gramDiag_uniform_bound hc h n)

-- ===========================================================================
-- The concrete trig-parametrized instance (zero-free by type — §6).
-- ===========================================================================

/-- A **trig-parametrized embedding** on a free angle family `θ` (zero-free by type: it takes no
    `Complex` zero / `StieltjesEta`, so §6's no-smuggling rule holds structurally): even coordinates carry
    `cos(nθ_k)`, odd coordinates `sin(nθ_k)`. The on-object sine-square certificate has this shape (with
    `1 − cos` in place of `cos`); its entries lie in `[−1,1]`, uniformly bounded in `n`. -/
def trigEmb (θ : Nat → Real) : Nat → Nat → Real :=
  fun n k => if k % 2 = 0 then Rcos (nsmulR n (θ (k / 2))) else Rsin (nsmulR n (θ (k / 2)))

/-- Every entry-square of `trigEmb` is `≤ 1` — `cos²≤1`, `sin²≤1`, uniformly in `n`. -/
theorem trigEmb_sq_le (θ : Nat → Real) (n k : Nat) :
    Rle (Rmul (trigEmb θ n k) (trigEmb θ n k)) (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
  show Rle (Rmul (if k % 2 = 0 then Rcos (nsmulR n (θ (k / 2))) else Rsin (nsmulR n (θ (k / 2))))
    (if k % 2 = 0 then Rcos (nsmulR n (θ (k / 2))) else Rsin (nsmulR n (θ (k / 2))))) one
  by_cases hk : k % 2 = 0
  · rw [if_pos hk]; exact Rcos_sq_le_one (nsmulR n (θ (k / 2)))
  · rw [if_neg hk]; exact Rsin_sq_le_one (nsmulR n (θ (k / 2)))

/-- **★ THE TRIG EMBEDDING'S DIAGONAL IS UNIFORMLY BOUNDED**: `gramOf (trigEmb θ) D n n ≤ RsumN (const 1) D`
    for every `n` — an `n`-independent bound. Instantiates the fence, so `trigEmb` realizes only sequences
    bounded uniformly in `n`; it cannot realize the unbounded genuine diagonal `2λₙ`. -/
theorem trigGram_uniform_bound (θ : Nat → Real) (D n : Nat) :
    Rle (gramOf (trigEmb θ) D n n) (RsumN (fun _ => ofQ (⟨1, 1⟩ : Q) (by decide)) D) :=
  gramDiag_uniform_bound (by decide) (fun n k _ => trigEmb_sq_le θ n k) n

end Multiplicity.UOR.Bridge.F1Square.Square
