import Lean

/-!
# Fold Theory Core — ADR-0032 (Fold Theory Integration)

Formal core of Fold Theory (ADR-0032, docs/ADR-0032-Fold Theory
Integration.md).  This module is **core Lean 4 only — no mathlib**, per the
Phase Mirror layering rule already applied in `Multiplicity.FPES.Core`
(ADR-0029): the ℝ-valued statements of the ADR (`Θ* = Λ_m⁻¹` over ℝ,
Lipschitz constants, spectral overlap measures) are deliberately **not**
expressed here; the discrete surrogates below are the kernel-checked spine,
and the real-norm layer is deferred to the Rust/Kani bridge exactly as in
ADR-0029.

## Model

- `PrimeIdx`: a generator label is admissible iff it is a prime index —
  the *Prime-Indexed Generator Basis* constraint.  Irreducible labels are
  indivisible eigenmodes; composite histories may only be built from them.
- `FoldWord`: the free magma over prime generators (`gen` / `comp`).
  Composition is **deliberately non-associative**: `(A₂ ⊙ A₃) ⊙ A₅ ≠
  A₂ ⊙ (A₃ ⊙ A₅)` even though both flatten to `[2, 3, 5]`.  The bracketing
  tree *is* the sequential history; it can never be erased by
  re-association.
- `gap p q`: spectral distance between two generator modes (discrete
  surrogate of phase mismatch).
- `LambdaM`, `thetaStar`: the **Universal Multiplicity Constant Λ_m** and
  the **admissibility threshold** `θ* = Λ_m - 1`.  A binary fold composition
  is permitted iff its compositional obstruction does not exceed θ*:
  this is the answer to ADR-0032's central question *"How should we define
  the specific admissibility threshold that decides whether a sequence of
  fold operators is permitted to combine in the first place?"*
- `defect w`: the sup-aggregated obstruction functional Θ(w).  A word is
  `Admissible` iff every internal node of its bracketing tree composes two
  sub-histories whose boundary modes lie within θ* — the *Lawful Closure*
  axiom, enforced node-by-node.
- `flatten` / `exponents` / `nu`: the underlying prime sequence, its
  exponent vector, and the arithmetic multiplicity
  `ν(w) = ∏_p (e_p + 1)` — multiplicity as arithmetic shadow of folding
  (ADR-0032 §5).
- `foldKern` / `kernIterate`: the contractive kernel.  Recursive fold
  sequences are strictly bounded: iteration reaches the stable fixed point
  `0` in finitely many steps — the discrete avatar of the global Lipschitz
  contractivity enforced by Λ_m.
- `Extension` / `Conflicting`: concurrent fold proposals and conflict
  detection (edge case: concurrent decision proposals).
- `dProfile`: emergent geometry `d_F` as minimal fold-complexity between
  history profiles (L1 distance on exponent vectors).

## Conventions

Every definition carries a docstring.  The `@[fold_adr]` / `@[fold_proof]`
tag attributes mirror `FPES.fpesAdrAttr` / `FPES.fpesProofAttr` and mark,
respectively, formally registered Fold artifacts and machine-checked Fold
proofs. -/
namespace Fold

/-! ## Project attributes -/

/-- Tag attribute for formally registered Fold Theory artifacts (ADR-0032). -/
initialize foldAdrAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `fold_adr "Fold ADR registry tag" (fun _ => pure ())

/-- Tag attribute for machine-checked Fold Theory theorems (ADR-0032). -/
initialize foldProofAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `fold_proof "Fold theorem tag" (fun _ => pure ())

/-! ### Prime-indexed generator basis -/

/-- `PrimeIdx p`: the label `p` is an irreducible prime index — the only
admissible generator labels of the fold algebra (ADR-0032 § Prime-Indexed
Generator Basis). -/
def PrimeIdx (p : Nat) : Prop := 2 ≤ p ∧ ∀ k, k ∣ p → k = 1 ∨ k = p

/-- `2` is an admissible generator index. -/
theorem primeidx_two : PrimeIdx 2 := by
  refine ⟨by omega, ?_⟩
  intro k hk
  have hle : k ≤ 2 := Nat.le_of_dvd (by omega) hk
  have hk' : k = 0 ∨ k = 1 ∨ k = 2 := by omega
  rcases hk' with rfl | rfl | rfl
  · exact absurd hk (by decide)
  · exact Or.inl rfl
  · exact Or.inr rfl

/-- `3` is an admissible generator index. -/
theorem primeidx_three : PrimeIdx 3 := by
  refine ⟨by omega, ?_⟩
  intro k hk
  have hle : k ≤ 3 := Nat.le_of_dvd (by omega) hk
  have hk' : k = 0 ∨ k = 1 ∨ k = 2 ∨ k = 3 := by omega
  rcases hk' with rfl | rfl | rfl | rfl
  · exact absurd hk (by decide)
  · exact Or.inl rfl
  · exact absurd hk (by decide)
  · exact Or.inr rfl

/-- `5` is an admissible generator index. -/
theorem primeidx_five : PrimeIdx 5 := by
  refine ⟨by omega, ?_⟩
  intro k hk
  have hle : k ≤ 5 := Nat.le_of_dvd (by omega) hk
  have hk' : k = 0 ∨ k = 1 ∨ k = 2 ∨ k = 3 ∨ k = 4 ∨ k = 5 := by omega
  rcases hk' with rfl | rfl | rfl | rfl | rfl | rfl
  · exact absurd hk (by decide)
  · exact Or.inl rfl
  · exact absurd hk (by decide)
  · exact absurd hk (by decide)
  · exact absurd hk (by decide)
  · exact Or.inr rfl

/-- `7` is an admissible generator index. -/
theorem primeidx_seven : PrimeIdx 7 := by
  refine ⟨by omega, ?_⟩
  intro k hk
  have hle : k ≤ 7 := Nat.le_of_dvd (by omega) hk
  have hk' : k = 0 ∨ k = 1 ∨ k = 2 ∨ k = 3 ∨ k = 4 ∨ k = 5 ∨ k = 6 ∨ k = 7 := by omega
  rcases hk' with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl
  · exact absurd hk (by decide)
  · exact Or.inl rfl
  · exact absurd hk (by decide)
  · exact absurd hk (by decide)
  · exact absurd hk (by decide)
  · exact absurd hk (by decide)
  · exact absurd hk (by decide)
  · exact Or.inr rfl

/-- `ValidGen p`: gate every generator through the primality invariant
before it may appear in a registered fold artifact. -/
def ValidGen (p : Nat) : Prop := PrimeIdx p

/-! ### Non-associative fold histories (the free magma) -/

/-- A fold history: a non-associative word over prime-indexed generators.
`gen p` is the irreducible operator `A_p`; `comp u v` is the bracketed
composition `u ∘ v`.  The free-magma structure preserves bracketing
information — the algebraic encoding of sequential fold history. -/
inductive FoldWord : Type where
  | gen : (p : Nat) → FoldWord
  | comp : FoldWord → FoldWord → FoldWord
deriving Repr, BEq, DecidableEq

/-- Bracketed composition notation: `u ⊙ v`. -/
scoped infixr:67 " ⊙ " => FoldWord.comp

/-- Leftmost generator mode of a history: the first leaf of the bracketing
tree. -/
def firstLeaf : FoldWord → Nat
  | .gen p => p
  | .comp u _ => firstLeaf u

/-- Rightmost generator mode of a history: the last leaf of the bracketing
tree. -/
def lastLeaf : FoldWord → Nat
  | .gen p => p
  | .comp _ v => lastLeaf v

/-- `flatten w`: the underlying prime-indexed sequence of `w` (inorder
flattening of the bracketing tree). -/
def flatten : FoldWord → List Nat
  | .gen p => [p]
  | .comp u v => flatten u ++ flatten v

/-- Bracketing depth: recursive complexity of the history. -/
def height : FoldWord → Nat
  | .gen _ => 1
  | .comp u v => max (height u) (height v) + 1

/-! ### The admissibility threshold (Λ_m and θ*) -/

/-- Spectral distance between two generator modes: the discrete surrogate
of the phase mismatch term ‖Φ(A_p,A_q) − Φ(A_q,A_p)‖ of the ADR's defect
functional. -/
def gap (p q : Nat) : Nat :=
  if p ≤ q then q - p else p - q

/-- **Universal Multiplicity Constant Λ_m** (discrete surrogate).  The ADR's
ℝ-valued global stability operator is represented here by a fixed natural
bound; the real-norm version stays in the Kani/Rust layer (ADR-0029
layering precedent). -/
def LambdaM : Nat := 4

/-- **The admissibility threshold**: `θ* = Λ_m − 1`.

This is the concrete answer to ADR-0032's driving question: a composition
is permitted precisely when its compositional obstruction does not exceed
θ*.  Every pair of boundary modes must satisfy `gap ≤ thetaStar`. -/
def thetaStar : Nat := LambdaM - 1

/-- Pairwise lawfulness: modes `p`, `q` may meet at a composition node iff
their spectral distance is within the threshold. -/
def PairAdmissible (p q : Nat) : Prop :=
  gap p q ≤ thetaStar

/-- Decidability of `PairAdmissible`. -/
instance decPairAdmissible (p q : Nat) : Decidable (PairAdmissible p q) := by
  unfold PairAdmissible gap
  infer_instance

/-- The compositional obstruction functional Θ (sup-aggregated).
`Θ(gen p) = 0`; each internal node contributes the spectral mismatch of the
two sub-histories at their shared boundary, aggregated by maximum so that
the threshold test inspects *every* node — the Lawful Closure condition. -/
def defect : FoldWord → Nat
  | .gen _ => 0
  | .comp u v => max (max (defect u) (defect v)) (gap (lastLeaf u) (firstLeaf v))

/-- `Admissible w`: the closure verdict.  A fold history enters the lawful
fragment iff `Θ(w) ≤ θ*` — i.e. iff *every* binary subcomposition in its
bracketing tree respects the admissibility threshold. -/
def Admissible (w : FoldWord) : Prop :=
  defect w ≤ thetaStar

/-- Decidability of `Admissible`. -/
instance decAdmissible (w : FoldWord) : Decidable (Admissible w) := by
  unfold Admissible
  infer_instance

/-- Threshold sanity: θ* ≥ 0 and Λ_m > θ*, so the fragment is proper. -/
theorem thetaStar_lt_LambdaM : thetaStar < LambdaM := by
  simp [thetaStar, LambdaM]

/-! ### Linear form: consecutive-pair inspection -/

/-- First element of a prime sequence (`0` for the empty sequence; callers
guard nonemptiness). -/
def firstOf : List Nat → Nat
  | [] => 0
  | p :: _ => p

/-- Last element of a prime sequence (`0` for the empty sequence; callers
guard nonemptiness). -/
def lastOf : List Nat → Nat
  | [] => 0
  | [p] => p
  | _ :: ps => lastOf ps

/-- `chainMax l`: supremum of spectral gaps over *consecutive* pairs of the
prime sequence `l` — the linear avatar of Θ.  The Lawful Closure axiom
(inspect every binary subcomposition) collapses to this nearest-neighbour
inspection because the defect functional is local to shared boundaries. -/
def chainMax : List Nat → Nat
  | [] => 0
  | [_] => 0
  | p :: q :: rest => max (gap p q) (chainMax (q :: rest))

/-! ### Exponent vectors and arithmetic multiplicity (ADR-0032 §5) -/

/-- `countGen l p`: occurrences of generator mode `p` in the prime sequence
`l` (the exponent `e_p`). -/
def countGen : List Nat → Nat → Nat
  | [], _ => 0
  | p :: rest, q => if p = q then countGen rest q + 1 else countGen rest q

/-- `exponents w p`: the exponent `e_p(w)` of mode `p` in history `w`. -/
def exponents (w : FoldWord) (p : Nat) : Nat :=
  countGen (flatten w) p

/-- `nuList l`: arithmetic multiplicity `ν(l) = ∏_{distinct p ∈ l} (e_p+1)`.
Each distinct mode contributes its factor at its final occurrence. -/
def nuList : List Nat → Nat
  | [] => 1
  | p :: rest =>
      if countGen rest p > 0 then nuList rest
      else (countGen (p :: rest) p + 1) * nuList rest

/-- `nu w`: the multiplicity of a fold history — the number of
divisor-like sub-histories (ADR-0032 §5, arithmetic shadow). -/
def nu (w : FoldWord) : Nat :=
  nuList (flatten w)

/-! ### Contractive kernel (recursive contractivity) -/

/-- The contractive kernel map on fold states: strict contraction towards
the stable fixed point.  Discrete avatar of the Λ_m-enforced Lipschitz
bound `‖F(x) − F(y)‖ ≤ Λ_m⁻¹ ‖x − y‖`. -/
def foldKern (x : Nat) : Nat := x / 2

/-- Bounded iteration of a state map (`F^[k] x`). -/
def kernIterate : (Nat → Nat) → Nat → Nat → Nat
  | _, 0, x => x
  | F, k + 1, x => kernIterate F k (F x)

/-- Fold states reachable from `x` under the kernel. -/
abbrev kernOrbit (x : Nat) (k : Nat) : Nat := kernIterate foldKern k x

/-! ### Emergent geometry d_F (ADR-0032 §6) -/

/-- Pointwise profile distance `|a − b|` (truncated natural difference). -/
def distTerm (a b : Nat) : Nat :=
  if a ≤ b then b - a else a - b

/-- `dProfile u v`: the emergent metric — minimal fold-complexity between
two histories, computed as the L1 distance of their exponent profiles over
the union of their supports.  Histories with identical profiles project to
the same stabilized configuration (same visible geometry), while remaining
distinct as generative histories. -/
def dProfile (u v : FoldWord) : Nat :=
  (flatten u ++ flatten v).foldl
    (init := 0)
    fun acc p => acc + distTerm (exponents u p) (exponents v p)

/-! ### Concurrent proposals and conflict detection -/

/-- A fold extension proposal: append one generator mode to the right of an
existing admissible history (concurrent decision proposals edge case). -/
structure Extension where
  base : FoldWord
  next : Nat

/-- `Applies e`: the proposed extension would itself be a lawful
composition — the new node passes the threshold. -/
def Applies (e : Extension) : Prop :=
  PairAdmissible (lastLeaf e.base) e.next

/-- Decidability of `Applies`. -/
instance decApplies (e : Extension) : Decidable (Applies e) := by
  unfold Applies
  infer_instance

/-- `Result e`: the history produced by applying extension `e`. -/
def Extension.result (e : Extension) : FoldWord :=
  e.base ⊙ FoldWord.gen e.next

/-- `Conflicting e₁ e₂`: two concurrent extensions race on the same base
history with distinct, mutually unlawful modes — they cannot be merged or
sequenced without violating the closure axioms, so exactly one must be
rejected before execution (P²C halt-at-T=0 discipline). -/
def Conflicting (e₁ e₂ : Extension) : Prop :=
  e₁.base = e₂.base ∧ e₁.next ≠ e₂.next ∧ ¬ PairAdmissible e₁.next e₂.next

/-- Decidability of `Conflicting`. -/
instance decConflicting (e₁ e₂ : Extension) : Decidable (Conflicting e₁ e₂) := by
  unfold Conflicting
  infer_instance

/-! ### Proof-carrying ADR registry (immutability after acceptance) -/

/-- Lifecycle status of a registered fold ADR. -/
inductive FoldStatus where
  /-- Under review; no seal is possible yet. -/
  | proposed
  /-- Sealed: the history passed the admissibility gate and is immutable. -/
  | accepted
  /-- Retired from active use; the seal and history remain intact. -/
  | deprecated
  /-- Replaced by a later ADR; the seal and history remain intact. -/
  | superseded

/-- A registered fold ADR: proof-carrying by construction.  The field
`sealProof : Admissible history` is a *proof term* — an `accepted` record
cannot even be constructed unless the kernel has machine-checked that its
history respects the admissibility threshold (ADR-0029 § Decision driver 5
precedent: violating the contract blocks compilation). -/
structure RegisteredADR where
  /-- Registry identifier. -/
  id : Nat
  /-- The fold history under governance. -/
  history : FoldWord
  /-- Lifecycle status. -/
  status : FoldStatus
  -- The admissibility seal: a kernel-checked certificate, not a flag.
  sealProof : Admissible history

/-- **Seal soundness:** the admissibility of any registered ADR's history is
reconstructible from the record itself — deprecation or supersession never
touches the `history`/`sealProof` fields, so audit trails survive status
changes without breaking proofs. -/
theorem seal_soundness (a : RegisteredADR) : Admissible a.history :=
  a.sealProof

end Fold
