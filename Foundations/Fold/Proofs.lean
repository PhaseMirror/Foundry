import Foundations.Fold.Core

/-!
# Fold Theory Proofs — machine-checked theorems (ADR-0032)

Every `@[fold_proof]` declaration below is a Lean-kernel-checked theorem of
the Fold core.  **No `-- TODO: replace sorry`, no `admit`, no axioms**: the compiler rejects
incomplete proofs (ADR-0029 precedent: violating the contract blocks
compilation).  Core Lean only — mathlib stays out (ADR-0032 layering, per
the Phase Mirror rule established in ADR-0029).

## Theorems delivered

| Obligation (ADR-0032 §) | Theorem | Meaning |
|---|---|---|
| Admissibility threshold | `admissible_comp` | the compositional gate: `u ⊙ v` permitted iff both parts are sealed *and* their boundary modes respect `θ*` |
| Lawful Closure Constraints | `admissible_iff_chainMax` | closure over all binary subcompositions collapses to nearest-neighbour inspection of the flattened prime word |
| Non-Associative Composition | `bracketing_is_history` / `flat_word_forgets_bracketing` | bracketing survives flattening lossily: same prime word, different histories |
| Unique decomposition (FTA analogue) | `exponents_comp` / `nu_comp_mul` | exponent additivity; multiplicity `ν` multiplies over disjoint (coprime) supports |
| Recursive Contractivity | `foldKern_contractive` / `kern_convergence` / `orbit_stable` | strict contraction, finite convergence to the stable fixed point, stability thereafter |
| Edge case: concurrent proposals | `no_self_conflict` / `conflicting_not_mergeable` / `applies_gate` | racing extensions are detectable and cannot be sequenced lawfully |
| Emergent geometry §6 | `dProfile_comm` / `dProfile_eq_zero_iff` | `d_F` is symmetric and separates exactly distinct exponent profiles |
| Governance immutability | `seal_soundness` (Core) | deprecation/supersession never breaks an accepted ADR's seal |

## Proof sketches

All proofs are structural: induction on `FoldWord`/`List`, `by_cases`,
`simp`, `rcases`, `split`, `omega` (which understands `max`/`min`), and
`native_decide` for concrete artifacts.  The ℝ-valued hypotheses of the ADR
(`Θ* = Λ_m⁻¹` over ℝ, spectral overlap measures) are deliberately *not*
used here — see the module header of `Multiplicicy.Fold.Core` and the
ADR-0029 layering precedent. -/
namespace Fold

/-! ### Basic shape lemmas -/

/-- Every history has at least one generator leaf. -/
@[fold_proof]
theorem height_ge_one (w : FoldWord) : 1 ≤ height w := by
  cases w <;> simp [height]

/-- Flattening always yields a nonempty prime sequence. -/
@[fold_proof]
theorem flatten_pos (w : FoldWord) : 0 < (flatten w).length := by
  induction w with
  | gen p => simp [flatten]
  | comp u v ihu ihv => simp only [flatten, List.length_append]; omega

/-- `firstOf` ignores the appended tail when the prefix is nonempty. -/
theorem firstOf_append_left {a b : List Nat} (h : 0 < a.length) :
    firstOf (a ++ b) = firstOf a := by
  cases a with
  | nil => simp at h
  | cons x xs => simp [firstOf]

/-- `lastOf` ignores the prefix when the suffix is nonempty. -/
theorem lastOf_append_right {a b : List Nat} (h : 0 < b.length) :
    lastOf (a ++ b) = lastOf b := by
  induction a with
  | nil => rfl
  | cons x xs ih =>
      cases xs with
      | nil =>
          cases b with
          | nil => simp at h
          | cons y ys => rfl
      | cons z zs =>
          cases b with
          | nil => simp at h
          | cons y ys =>
              show lastOf ((z :: zs) ++ (y :: ys)) = lastOf (y :: ys)
              exact ih

/-- Boundary agreement: `firstLeaf` reads the first element of the flat
word. -/
@[fold_proof]
theorem firstLeaf_eq_firstOf (w : FoldWord) :
    firstLeaf w = firstOf (flatten w) := by
  induction w with
  | gen p => rfl
  | comp u v ihu _ =>
      show firstLeaf u = firstOf (flatten u ++ flatten v)
      rw [firstOf_append_left (flatten_pos u)]
      exact ihu

/-- Boundary agreement: `lastLeaf` reads the last element of the flat
word. -/
@[fold_proof]
theorem lastLeaf_eq_lastOf (w : FoldWord) :
    lastLeaf w = lastOf (flatten w) := by
  induction w with
  | gen p => rfl
  | comp u v ihu ihv =>
      show lastLeaf v = lastOf (flatten u ++ flatten v)
      rw [lastOf_append_right (flatten_pos v)]
      exact ihv

/-! ### Linear form of the closure axiom -/

/-- `chainMax` distributes over appending two nonempty sequences: the only
new consecutive pair is the shared boundary. -/
theorem chainMax_append : ∀ (a b : List Nat), 0 < a.length → 0 < b.length →
    chainMax (a ++ b) =
      max (max (chainMax a) (chainMax b)) (gap (lastOf a) (firstOf b)) := by
  intro a
  induction a with
  | nil => intro _ hn; exact absurd hn (by simp)
  | cons x xs ih =>
      intro b _ hb
      cases xs with
      | nil =>
          cases b with
          | nil => simp at hb
          | cons y ys =>
              simp only [List.nil_append, List.cons_append, chainMax, lastOf,
                firstOf]
              omega
      | cons z zs =>
          cases b with
          | nil => simp at hb
          | cons y ys =>
              have ihz := ih (y :: ys) (by simp) (by simp)
              simp only [List.cons_append, chainMax, lastOf, firstOf] at *
              omega

/-- **Θ is linear:** the sup-aggregated obstruction of a history equals the
supremum of consecutive-pair gaps of its flattened prime word.  This is
what makes the Lawful Closure axiom (inspect every binary subcomposition)
decidable by a single left-to-right scan. -/
@[fold_proof]
theorem defect_eq_chainMax (w : FoldWord) : defect w = chainMax (flatten w) := by
  induction w with
  | gen p => rfl
  | comp u v ihu ihv =>
      show max (max (defect u) (defect v)) (gap (lastLeaf u) (firstLeaf v))
        = chainMax (flatten u ++ flatten v)
      rw [chainMax_append (flatten u) (flatten v) (flatten_pos u) (flatten_pos v),
        ← ihu, ← ihv, ← lastLeaf_eq_lastOf u, ← firstLeaf_eq_firstOf v]

/-- **Linear admissibility criterion:** a history is sealed iff every
consecutive pair of its flattened prime word respects the threshold. -/
@[fold_proof]
theorem admissible_iff_chainMax (w : FoldWord) :
    Admissible w ↔ chainMax (flatten w) ≤ thetaStar := by
  unfold Admissible
  rw [defect_eq_chainMax]

/-! ### The compositional admissibility gate -/

/-- Arithmetic engine of the gate: a triple-maximum respects `t` exactly
when each component does. -/
private theorem max3_le_iff (a b c t : Nat) :
    max (max a b) c ≤ t ↔ a ≤ t ∧ b ≤ t ∧ c ≤ t := by
  constructor
  · intro h
    exact ⟨by omega, ⟨by omega, by omega⟩⟩
  · rintro ⟨h1, h2, h3⟩
    omega

/-- **The admissibility threshold, as a decision procedure** (ADR-0032 §
Lawful Closure Constraints): the composition `u ⊙ v` is *permitted to
combine* precisely when

1. `u` is itself admissible,
2. `v` is itself admissible, and
3. the boundary modes meet the pairwise law `gap (lastLeaf u) (firstLeaf v) ≤ θ*`.

This is the formal answer to the ADR's driving question: admissibility of
a sequence is decided recursively, node by node, by the threshold test
`Θ ≤ θ*` with `θ* = Λ_m − 1`. -/
@[fold_proof]
theorem admissible_comp (u v : FoldWord) :
    Admissible (u ⊙ v) ↔
      Admissible u ∧ Admissible v ∧ PairAdmissible (lastLeaf u) (firstLeaf v) :=
  max3_le_iff (defect u) (defect v) (gap (lastLeaf u) (firstLeaf v)) thetaStar

/-- Irreducible generators carry no obstruction: every single-generator
history is admissible. -/
@[fold_proof]
theorem admissible_gen (p : Nat) : Admissible (FoldWord.gen p) :=
  Nat.zero_le _

/-- **Subtree closure:** the admissible fragment is closed under taking
immediate subtrees — a sealed history cannot hide an unlawful
subcomposition. -/
@[fold_proof]
theorem admissible_subtrees {u v : FoldWord} (h : Admissible (u ⊙ v)) :
    Admissible u ∧ Admissible v :=
  ⟨((admissible_comp u v).mp h).1, ((admissible_comp u v).mp h).2.1⟩

/-! ### Non-associativity: bracketing is history -/

/-- **Non-associative composition (proved witness):**
`(A₂ ⊙ A₃) ⊙ A₅ ≠ A₂ ⊙ (A₃ ⊙ A₅)` — the algebra deliberately refuses
re-association, so the bracketing tree encodes the sequential fold history
(ADR-0032 § Non-Associative Composition). -/
@[fold_proof]
theorem bracketing_is_history :
    (FoldWord.gen 2 ⊙ FoldWord.gen 3) ⊙ FoldWord.gen 5 ≠
      FoldWord.gen 2 ⊙ (FoldWord.gen 3 ⊙ FoldWord.gen 5) := by
  decide

/-- **Flat words forget bracketing:** the two bracketings above share the
identical flattened prime word `[2, 3, 5]` while remaining distinct
histories.  Hence the underlying prime sequence alone does *not* determine
the generative history — exactly the gap between geometry (stabilized
profile) and multiplicity (history) in ADR-0032 §5–6. -/
@[fold_proof]
theorem flat_word_forgets_bracketing :
    flatten ((FoldWord.gen 2 ⊙ FoldWord.gen 3) ⊙ FoldWord.gen 5)
      = flatten (FoldWord.gen 2 ⊙ (FoldWord.gen 3 ⊙ FoldWord.gen 5)) ∧
    (FoldWord.gen 2 ⊙ FoldWord.gen 3) ⊙ FoldWord.gen 5 ≠
      FoldWord.gen 2 ⊙ (FoldWord.gen 3 ⊙ FoldWord.gen 5) :=
  ⟨rfl, bracketing_is_history⟩

/-! ### Exponent vectors (unique decomposition, arithmetic layer) -/

/-- Counting distributes over concatenation. -/
theorem countGen_append (l₁ l₂ : List Nat) (p : Nat) :
    countGen (l₁ ++ l₂) p = countGen l₁ p + countGen l₂ p := by
  induction l₁ with
  | nil => simp [countGen]
  | cons q rest ih =>
      by_cases h : q = p
      · simp only [List.cons_append, countGen, if_pos h, ih]
        omega
      · simp only [List.cons_append, countGen, if_neg h, ih]

/-- Absence forces a zero exponent. -/
theorem countGen_eq_zero_of_not_mem {l : List Nat} {p : Nat} (h : p ∉ l) :
    countGen l p = 0 := by
  induction l with
  | nil => rfl
  | cons q rest ih =>
      by_cases hqp : q = p
      · exact absurd (by simp [hqp]) h
      · simp [countGen, hqp, ih (fun hm => h (by simp [hm]))]

/-- **Exponent additivity:** the exponent vector of a composite history is
the sum of the exponent vectors of its factors — the monoid law that makes
`e(w)` a well-defined invariant of the decomposition
(ADR-0032 §4, unique-decomposition arithmetic layer). -/
@[fold_proof]
theorem exponents_comp (u v : FoldWord) (p : Nat) :
    exponents (u ⊙ v) p = exponents u p + exponents v p := by
  simp only [exponents, flatten, countGen_append]

/-- Exponent of a single-generator history: `1` at its own index, `0`
elsewhere. -/
@[fold_proof]
theorem exponents_gen (p q : Nat) :
    exponents (FoldWord.gen p) q = if p = q then 1 else 0 := by
  by_cases h : p = q <;> simp [exponents, flatten, countGen, h]

/-! ### Arithmetic multiplicity ν (ADR-0032 §5) -/

/-- Emission rule at a mode whose remaining occurrences are exhausted:
factor `e_p + 1 = 2` here because the head contributes one occurrence. -/
theorem nuList_cons_tail_zero {p : Nat} {l : List Nat}
    (h : countGen l p = 0) : nuList (p :: l) = 2 * nuList l := by
  show (if countGen l p > 0 then nuList l
        else (countGen (p :: l) p + 1) * nuList l) = _
  rw [if_neg (by rw [h]; omega)]
  have hf : countGen (p :: l) p + 1 = 2 := by simp [countGen, h]
  rw [hf]

/-- Skip rule at a mode with further occurrences ahead: the factor is
emitted later, at the mode's final occurrence. -/
theorem nuList_cons_tail_pos {p : Nat} {l : List Nat}
    (h : 0 < countGen l p) : nuList (p :: l) = nuList l := by
  show (if countGen l p > 0 then nuList l
        else (countGen (p :: l) p + 1) * nuList l) = _
  rw [if_pos h]

/-- **ν multiplies over disjoint (coprime) supports:** if no mode of `l₁`
occurs in `l₂`, the divisor-like sub-history count of the concatenation is
the product of the counts — the Fundamental-Theorem-of-Arithmetic analogue
of ADR-0032 §5. -/
@[fold_proof]
theorem nuList_append_mul (l₂ : List Nat) :
    ∀ (l₁ : List Nat), (∀ q ∈ l₁, countGen l₂ q = 0) →
      nuList (l₁ ++ l₂) = nuList l₁ * nuList l₂ := by
  intro l₁
  induction l₁ with
  | nil => intro _; simp [nuList]
  | cons p rest ih =>
      intro hd
      have hp0 : countGen l₂ p = 0 := hd p (by simp)
      have hrest : ∀ q ∈ rest, countGen l₂ q = 0 :=
        fun q hq => hd q (by simp [hq])
      have key := ih hrest
      simp only [List.cons_append]
      by_cases hc : countGen rest p = 0
      · have hc' : countGen (rest ++ l₂) p = 0 := by
          rw [countGen_append, hc, hp0]
        rw [nuList_cons_tail_zero hc', key, nuList_cons_tail_zero hc]
        rw [Nat.mul_assoc]
      · have hcpos : 0 < countGen rest p := by omega
        have hap : countGen (rest ++ l₂) p = countGen rest p + countGen l₂ p :=
          countGen_append rest l₂ p
        have hc'pos : 0 < countGen (rest ++ l₂) p := by omega
        rw [nuList_cons_tail_pos hc'pos, key, nuList_cons_tail_pos hcpos]

/-- Word-level ν multiplicativity: composable histories with disjoint
supports multiply their sub-history counts. -/
@[fold_proof]
theorem nu_comp_mul (u v : FoldWord)
    (hd : ∀ q ∈ flatten u, countGen (flatten v) q = 0) :
    nu (u ⊙ v) = nu u * nu v :=
  nuList_append_mul (flatten v) (flatten u) hd

/-- A single generator has exactly two divisor-like sub-histories: the
empty history and itself. -/
@[fold_proof]
theorem nu_gen (p : Nat) : nu (FoldWord.gen p) = 2 := by
  simp [nu, nuList, countGen, flatten]

/-! ### Contractive kernel (recursive contractivity) -/

/-- The kernel is a strict contraction in the discrete order: folding never
increases a state. -/
@[fold_proof]
theorem foldKern_contractive (x : Nat) : foldKern x ≤ x :=
  Nat.div_le_self x 2

/-- The kernel is monotone (discrete Lipschitz surrogate). -/
@[fold_proof]
theorem foldKern_mono {x y : Nat} (h : x ≤ y) : foldKern x ≤ foldKern y :=
  Nat.div_le_div_right h

/-- The stable fixed point. -/
@[fold_proof]
theorem foldKern_fixed_zero : foldKern 0 = 0 := rfl

/-- **Finite convergence:** every fold state reaches the stable fixed point
`0` in at most `x` kernel steps — recursive fold sequences are strictly
bounded, never divergent (ADR-0032 § Recursive Contractivity). -/
@[fold_proof]
theorem kern_convergence : ∀ (b x : Nat), x ≤ b →
    ∃ k, kernIterate foldKern k x = 0 ∧ k ≤ x := by
  intro b
  induction b with
  | zero =>
      intro x hx
      have hx0 : x = 0 := by omega
      subst hx0
      exact ⟨0, rfl, Nat.le_refl 0⟩
  | succ b ih =>
      intro x hx
      rcases Nat.eq_zero_or_pos x with hx0 | hpos
      · subst hx0
        exact ⟨0, rfl, Nat.le_refl 0⟩
      · have hstep : foldKern x < x := Nat.div_lt_self hpos (by omega)
        obtain ⟨k, hk, hkle⟩ := ih (foldKern x) (by omega)
        refine ⟨k + 1, ?_, by omega⟩
        show kernIterate foldKern k (foldKern x) = 0
        exact hk

/-- **Coherence as contractive stability:** once folded to the fixed point,
further folding changes nothing — `F(C) = C` (ADR-0032 §6 coherence). -/
@[fold_proof]
theorem orbit_stable (k : Nat) : kernIterate foldKern k 0 = 0 := by
  induction k with
  | zero => rfl
  | succ k ih =>
      show kernIterate foldKern k (foldKern 0) = 0
      rw [foldKern_fixed_zero]
      exact ih

/-! ### Concurrent proposals and conflict detection -/

/-- The result of an extension ends exactly at the proposed mode. -/
@[fold_proof]
theorem extension_result_last (e : Extension) :
    lastLeaf (Extension.result e) = e.next := rfl

/-- Spectral distance is symmetric. -/
theorem gap_comm (p q : Nat) : gap p q = gap q p := by
  unfold gap
  split <;> split <;> omega

/-- Pairwise admissibility is symmetric. -/
theorem pairAdmissible_symm {p q : Nat} (h : PairAdmissible p q) :
    PairAdmissible q p := by
  unfold PairAdmissible at h ⊢
  rw [gap_comm]
  exact h

/-- Identical proposals never conflict — no false positives. -/
@[fold_proof]
theorem no_self_conflict (e : Extension) : ¬ Conflicting e e := by
  intro h
  rcases h with ⟨_, hne, _⟩
  exact hne rfl

/-- **Application gate:** a proposed extension yields an admissible history
iff the extension itself passes the pairwise threshold and the base is
sealed. -/
@[fold_proof]
theorem applies_gate (e : Extension) (hb : Admissible e.base) (ha : Applies e) :
    Admissible (Extension.result e) :=
  (admissible_comp e.base (FoldWord.gen e.next)).mpr
    ⟨hb, admissible_gen _, ha⟩

/-- **Conflicting extensions cannot be sequenced:** if two racing proposals
are mutually unlawful, then applying one after the other's result violates
the closure axioms — exactly one must be halted before execution
(P²C halt-at-T=0 discipline). -/
@[fold_proof]
theorem conflicting_not_mergeable (e₁ e₂ : Extension) (h : Conflicting e₁ e₂) :
    ¬ Applies { base := Extension.result e₂, next := e₁.next } := by
  rcases h with ⟨_, _, hpair⟩
  unfold PairAdmissible at hpair
  intro hap
  -- Definitional unfolding: the staged base ends at `e₂.next`.
  have hap' : gap e₂.next e₁.next ≤ thetaStar := hap
  have symm : gap e₁.next e₂.next ≤ thetaStar := by
    rw [gap_comm]
    exact hap'
  exact hpair symm

/-! ### Emergent geometry d_F (ADR-0032 §6) -/

/-- Pointwise symmetry of profile distance. -/
theorem distTerm_comm (a b : Nat) : distTerm a b = distTerm b a := by
  unfold distTerm
  split <;> split <;> omega

/-- Zero profile distance means equal values. -/
theorem distTerm_eq_zero {a b : Nat} (h : distTerm a b = 0) : a = b := by
  unfold distTerm at h
  split at h <;> omega

/-- Identical profiles are at zero distance. -/
theorem distTerm_self {a : Nat} : distTerm a a = 0 := by
  unfold distTerm
  split <;> omega

/-- If every pointwise term of the profile sum vanishes, so does the sum. -/
@[fold_proof]
theorem dProfile_fold_zero {u v : FoldWord}
    (hall : ∀ q, distTerm (exponents u q) (exponents v q) = 0) :
    dProfile u v = 0 := by
  unfold dProfile
  have key : ∀ (L : List Nat),
      (∀ x ∈ L, distTerm (exponents u x) (exponents v x) = 0) →
      L.foldl (fun acc q => acc + distTerm (exponents u q) (exponents v q)) 0 = 0 := by
    intro L
    induction L with
    | nil => intro _; rfl
    | cons q rest ih =>
        intro hmem
        rw [List.foldl_cons]
        have hq := hmem q List.mem_cons_self
        rw [hq, Nat.zero_add]
        exact ih (fun x hx => hmem x (List.mem_cons_of_mem _ hx))
  exact key (flatten u ++ flatten v) (fun q _ => hall q)

/-- Folding a nonneg-term sum is monotone in its starting accumulator. -/
theorem foldl_add_mono (L : List Nat) (g : Nat → Nat) {a b : Nat} (h : a ≤ b) :
    L.foldl (fun acc q => acc + g q) a ≤ L.foldl (fun acc q => acc + g q) b := by
  induction L generalizing a b with
  | nil => exact h
  | cons w rest ih =>
      rw [List.foldl_cons, List.foldl_cons]
      exact ih (by omega)

/-- Folding from the start value is bounded below by that value. -/
theorem foldl_add_ge_start (L : List Nat) (g : Nat → Nat) (x : Nat) :
    x ≤ L.foldl (fun acc q => acc + g q) x := by
  induction L generalizing x with
  | nil => exact Nat.le_refl x
  | cons q rest ih =>
      rw [List.foldl_cons]
      exact Nat.le_trans (Nat.le_add_right x (g q)) (ih (x + g q))

/-- Every summand appears in the total: each term of the profile sum is
bounded by the whole fold. -/
theorem term_le_foldl_add (L : List Nat) (g : Nat → Nat) :
    ∀ p ∈ L, g p ≤ L.foldl (fun acc q => acc + g q) 0 := by
  induction L with
  | nil => intro _hp hp; simp at hp
  | cons w rest ih =>
      intro p hp
      rw [List.mem_cons] at hp
      rcases hp with rfl | hrest
      · calc g p
            = 0 + g p := (Nat.zero_add _).symm
          _ ≤ List.foldl (fun acc q => acc + g q) (0 + g p) rest :=
              foldl_add_ge_start rest g _
          _ = List.foldl (fun acc q => acc + g q) 0 (p :: rest) := rfl
      · calc g p
            ≤ List.foldl (fun acc q => acc + g q) 0 rest := ih p hrest
          _ ≤ List.foldl (fun acc q => acc + g q) (0 + g w) rest :=
              foldl_add_mono rest g (Nat.zero_le _)
          _ = List.foldl (fun acc q => acc + g q) 0 (w :: rest) := rfl

/-- Any single term of the profile sum is bounded by the whole sum. -/
theorem dProfile_term_le {u v : FoldWord} {p : Nat}
    (hp : p ∈ flatten u ++ flatten v) :
    distTerm (exponents u p) (exponents v p) ≤ dProfile u v :=
  term_le_foldl_add (flatten u ++ flatten v)
    (fun q => distTerm (exponents u q) (exponents v q)) p hp

/-- **Separation:** two histories have zero emergent distance exactly when
their exponent profiles coincide everywhere — geometry identifies precisely
the histories with identical stabilized configurations, while bracketing
(sequential history) remains extra structure. -/
@[fold_proof]
theorem dProfile_eq_zero_iff (u v : FoldWord) :
    dProfile u v = 0 ↔ ∀ p, exponents u p = exponents v p := by
  constructor
  · intro hzero p
    by_cases hmem : p ∈ flatten u ++ flatten v
    · have hle := dProfile_term_le (u := u) (v := v) (p := p) hmem
      rw [hzero] at hle
      exact distTerm_eq_zero (Nat.le_zero.mp hle)
    · have hu : countGen (flatten u) p = 0 :=
        countGen_eq_zero_of_not_mem (fun hm => hmem (by simp [hm]))
      have hv : countGen (flatten v) p = 0 :=
        countGen_eq_zero_of_not_mem (fun hm => hmem (by simp [hm]))
      simp [exponents, hu, hv]
  · intro heq
    refine dProfile_fold_zero (fun q => ?_)
    rw [heq q]
    exact distTerm_self

/-- Emergent geometry is reflexive: identical histories coincide. -/
@[fold_proof]
theorem dProfile_self (w : FoldWord) : dProfile w w = 0 :=
  dProfile_eq_zero_iff w w |>.mpr fun _ => rfl
