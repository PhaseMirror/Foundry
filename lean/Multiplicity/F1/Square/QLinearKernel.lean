/-
F1 square — **an over-determined homogeneous `ℚ`-system has a nonzero solution** (`QLinearKernel.lean`),
co-support depth-existence sub-brick N₂. This is the Gaussian-elimination fact the layer never had — the
doc's "hypergeometric identity the layer cannot reach", solved instead by row reduction:

  `#equations < #variables  ⟹  ∃ nonzero c with every equation `Σᵢ (row i)·(c i) = 0``   (`qkernel_exists`).

The proof is a division-free elimination by induction on the equation list. With a pivot variable `p`
(coefficient `e₀ p ≉ 0` in the first equation `e₀`), the remaining equations are *scaled* — `e' = (e₀ p)·e
− (e p)·e₀`, so `e'(p) = 0` and no division is needed — the reduced system lives on `vars.erase p` (one
fewer variable, still one fewer than its equations), the IH supplies a nonzero `c'`, and it lifts to a
nonzero `c` on `vars` by `c i := (e₀ p)·c' i` off the pivot and `c p := −Σ_{vars.erase p} (e₀ i)·c' i`.
The four sum identities are the `qsumL` linearity laws (N₁) composed with the pivot split.

HONEST SCOPE. Pure finite rational linear algebra — a constructive nonzero-kernel theorem. No members,
no co-support, no positivity yet; those are the following bricks. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.QSumList

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Membership-restricted congruence: agreement on `vars` suffices for the sum. -/
theorem qsumL_congr_mem {f g : Nat → Q} :
    ∀ vars : List Nat, (∀ i ∈ vars, Qeq (f i) (g i)) → Qeq (qsumL f vars) (qsumL g vars)
  | [], _ => Qeq_refl _
  | i :: rest, h =>
      Qadd_congr (h i (List.mem_cons_self i rest))
        (qsumL_congr_mem rest (fun j hj => h j (List.mem_cons_of_mem i hj)))

/-- Membership-restricted vanishing: pointwise `≈ 0` on `vars` gives `Σ ≈ 0`. -/
theorem qsumL_zero_mem {f : Nat → Q} (vars : List Nat)
    (h : ∀ i ∈ vars, Qeq (f i) (⟨0, 1⟩ : Q)) : Qeq (qsumL f vars) (⟨0, 1⟩ : Q) :=
  Qeq_trans (b := qsumL (fun _ => (⟨0, 1⟩ : Q)) vars) (qsumL_den _ (fun _ => Nat.one_pos) vars)
    (qsumL_congr_mem vars h) (qsumL_zero (fun _ => Qeq_refl _) vars)

/-- A rational is `≈ 0` exactly when its numerator is `0`. -/
theorem Qeq_zero_iff (a : Q) : Qeq a (⟨0, 1⟩ : Q) ↔ a.num = 0 := by
  constructor
  · intro h
    have : a.num * (1 : Int) = 0 * (a.den : Int) := h
    simpa using this
  · intro h
    show a.num * (1 : Int) = 0 * (a.den : Int)
    rw [h]; ring_uor

/-- No zero divisors: a product of two apart-from-zero rationals is apart from zero. -/
theorem Qmul_ne_zero {a b : Q} (ha : ¬ Qeq a (⟨0, 1⟩ : Q)) (hb : ¬ Qeq b (⟨0, 1⟩ : Q)) :
    ¬ Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  rw [Qeq_zero_iff] at ha hb ⊢
  show a.num * b.num ≠ 0
  exact Int.mul_ne_zero ha hb

/-- A left factor `≈ 0` makes the product `≈ 0`. -/
theorem Qmul_zero_left {a b : Q} (h : Qeq a (⟨0, 1⟩ : Q)) : Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  rw [Qeq_zero_iff] at h ⊢
  show a.num * b.num = 0
  rw [h]; ring_uor

/-- Negation respects ℚ value-equality. -/
private theorem Qneg_congr {X Y : Q} (h : Qeq X Y) : Qeq (neg X) (neg Y) := by
  show (-X.num) * (Y.den : Int) = (-Y.num) * (X.den : Int)
  have h' : X.num * (Y.den : Int) = Y.num * (X.den : Int) := h
  calc (-X.num) * (Y.den : Int) = -(X.num * (Y.den : Int)) := by ring_uor
    _ = -(Y.num * (X.den : Int)) := by rw [h']
    _ = (-Y.num) * (X.den : Int) := by ring_uor

/-- A vanishing difference is an equality: `X − Y ≈ 0 ⟹ X ≈ Y`. -/
private theorem Qeq_of_Qsub_zero {X Y : Q} (h : Qeq (Qsub X Y) (⟨0, 1⟩ : Q)) : Qeq X Y := by
  have key : (Qsub X Y).num = X.num * (Y.den : Int) - Y.num * (X.den : Int) := by
    simp only [Qsub, add, neg]; ring_uor
  have h0 : (Qsub X Y).num = 0 := (Qeq_zero_iff (Qsub X Y)).mp h
  rw [key] at h0
  show X.num * (Y.den : Int) = Y.num * (X.den : Int)
  omega

/-- Decidable dichotomy over a list: either the predicate holds on every member, or some member
    violates it. The `Prop`-level `∀/∃` split that drives the pivot search. -/
theorem ball_or_exists_not {P : Nat → Prop} [DecidablePred P] (vars : List Nat) :
    (∀ i ∈ vars, P i) ∨ (∃ i ∈ vars, ¬ P i) := by
  induction vars with
  | nil => exact Or.inl (fun i hi => absurd hi (List.not_mem_nil i))
  | cons i rest ih =>
    by_cases hi : P i
    · rcases ih with hall | ⟨j, hj, hnj⟩
      · refine Or.inl (fun k hk => ?_)
        rcases List.mem_cons.mp hk with h | h
        · subst h; exact hi
        · exact hall k h
      · exact Or.inr ⟨j, List.mem_cons_of_mem i hj, hnj⟩
    · exact Or.inr ⟨i, List.mem_cons_self i rest, hi⟩

/-- The pivot row operation: from a pivot row `e₀` (with pivot `p`), scale row `e` to kill its `p`
    coefficient, `e' i := (e₀ p)·(e i) − (e p)·(e₀ i)`, so `e'(p) ≈ 0` — the division-free elimination
    step. -/
def redEqRow (e₀ : Nat → Q) (p : Nat) (e : Nat → Q) : Nat → Q :=
  fun i => Qsub (mul (e₀ p) (e i)) (mul (e p) (e₀ i))

/-- Erasing a member drops the length by exactly one (choice-free, by structural induction — the
    core `List.length_erase_of_mem` pulls `Classical.choice`). `private` so it stays out of the
    honesty-audit coverage gate. -/
private theorem length_erase_mem (p : Nat) : ∀ (vars : List Nat), p ∈ vars →
    (vars.erase p).length = vars.length - 1
  | [], hp => absurd hp (List.not_mem_nil p)
  | a :: rest, hp => by
    by_cases hap : a = p
    · subst hap; simp [List.erase_cons]
    · have hprest : p ∈ rest := (List.mem_cons.mp hp).resolve_left (fun h => hap h.symm)
      have hpos : 0 < rest.length := by
        cases rest with
        | nil => exact absurd hprest (List.not_mem_nil p)
        | cons b bs => exact Nat.succ_pos _
      have herase : (a :: rest).erase p = a :: rest.erase p := by simp [List.erase_cons, hap]
      rw [herase, List.length_cons, length_erase_mem p rest hprest, List.length_cons]
      omega

/-- In a `Nodup` list, the erased element is genuinely gone (choice-free — the core
    `List.Nodup.not_mem_erase` pulls `Classical.choice`). `private` so it stays out of the
    honesty-audit coverage gate. -/
private theorem not_mem_erase_nodup (p : Nat) : ∀ (vars : List Nat), vars.Nodup →
    p ∉ vars.erase p
  | [], _ => by simp
  | a :: rest, hnd => by
    by_cases hap : a = p
    · subst hap
      rw [show (a :: rest).erase a = rest by simp [List.erase_cons]]
      exact (List.nodup_cons.mp hnd).1
    · have herase : (a :: rest).erase p = a :: rest.erase p := by simp [List.erase_cons, hap]
      rw [herase]
      intro hmem
      rcases List.mem_cons.mp hmem with h | h
      · exact hap h.symm
      · exact not_mem_erase_nodup p rest (List.nodup_cons.mp hnd).2 h

/-- **AN OVER-DETERMINED HOMOGENEOUS ℚ-SYSTEM HAS A NONZERO SOLUTION**: if there are fewer equations
    than variables, there is a nonzero `c` making every equation `Σ_{i∈vars} (row i)·(c i) ≈ 0`. -/
theorem qkernel_exists (eqns : List (Nat → Q)) (hden : ∀ e ∈ eqns, ∀ i, 0 < (e i).den)
    (vars : List Nat) (hnd : vars.Nodup) (hlt : eqns.length < vars.length) :
    ∃ c : Nat → Q, (∀ i, 0 < (c i).den) ∧
      (∃ v ∈ vars, ¬ Qeq (c v) (⟨0, 1⟩ : Q)) ∧
      (∀ e ∈ eqns, Qeq (qsumL (fun i => mul (e i) (c i)) vars) (⟨0, 1⟩ : Q)) := by
  match eqns, hden, hlt with
  | [], _, hlt =>
      -- Base: no equations, take the all-ones vector; `vars ≠ []`.
      cases vars with
      | nil => exact absurd hlt (by decide)
      | cons v₀ vrest =>
          exact ⟨fun _ => (⟨1, 1⟩ : Q), fun _ => Nat.one_pos,
            ⟨v₀, List.mem_cons_self v₀ vrest, (by decide : ¬ Qeq (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q))⟩,
            fun e he => absurd he (List.not_mem_nil e)⟩
  | e₀ :: rest, hden, hlt =>
      have he₀den : ∀ i, 0 < (e₀ i).den := hden e₀ (List.mem_cons_self e₀ rest)
      have hrestden : ∀ e, e ∈ rest → ∀ i, 0 < (e i).den :=
        fun e he i => hden e (List.mem_cons_of_mem e₀ he) i
      rcases ball_or_exists_not (P := fun i => Qeq (e₀ i) (⟨0, 1⟩ : Q)) vars with hall | ⟨p, hpv, hpnz⟩
      · -- Case A: the first row is identically `≈ 0` on `vars`; recurse on the rest.
        rcases qkernel_exists rest hrestden vars hnd (Nat.lt_of_succ_lt hlt) with
          ⟨c, hcden, ⟨v, hv, hvnz⟩, hsat⟩
        refine ⟨c, hcden, ⟨v, hv, hvnz⟩, ?_⟩
        intro e he
        rcases List.mem_cons.mp he with rfl | he'
        · exact qsumL_zero_mem vars (fun i hi => Qmul_zero_left (hall i hi))
        · exact hsat e he'
      · -- Case B: pivot `p` with `e₀ p ≉ 0`; eliminate it and recurse on `vars.erase p`.
        have hden' : ∀ re, re ∈ rest.map (redEqRow e₀ p) → ∀ i, 0 < (re i).den := by
          intro re hre i
          rcases List.mem_map.mp hre with ⟨e, he, rfl⟩
          show 0 < (Qsub (mul (e₀ p) (e i)) (mul (e p) (e₀ i))).den
          exact Qsub_den_pos (Qmul_den_pos (he₀den p) (hrestden e he i))
            (Qmul_den_pos (hrestden e he p) (he₀den i))
        have hnd' : (vars.erase p).Nodup := hnd.erase p
        have hlen : (vars.erase p).length = vars.length - 1 := length_erase_mem p vars hpv
        have hlt' : (rest.map (redEqRow e₀ p)).length < (vars.erase p).length := by
          rw [List.length_map]
          simp only [List.length_cons] at hlt
          omega
        rcases qkernel_exists (rest.map (redEqRow e₀ p)) hden' (vars.erase p) hnd' hlt' with
          ⟨c', hc'den, ⟨w, hw', hw'nz⟩, hc'sat⟩
        -- The lifted solution.
        let S : Q := qsumL (fun i => mul (e₀ i) (c' i)) (vars.erase p)
        have hSden : 0 < S.den :=
          qsumL_den _ (fun i => Qmul_den_pos (he₀den i) (hc'den i)) (vars.erase p)
        let c : Nat → Q := fun i => if i = p then neg S else mul (e₀ p) (c' i)
        have hcp : c p = neg S := by
          show (if p = p then neg S else mul (e₀ p) (c' p)) = neg S; rw [if_pos rfl]
        have hcoff : ∀ i, i ≠ p → c i = mul (e₀ p) (c' i) := by
          intro i hi
          show (if i = p then neg S else mul (e₀ p) (c' i)) = mul (e₀ p) (c' i); rw [if_neg hi]
        have hcden : ∀ i, 0 < (c i).den := by
          intro i; by_cases hip : i = p
          · show 0 < (if i = p then neg S else mul (e₀ p) (c' i)).den
            rw [if_pos hip]; exact neg_den_pos hSden
          · show 0 < (if i = p then neg S else mul (e₀ p) (c' i)).den
            rw [if_neg hip]; exact Qmul_den_pos (he₀den p) (hc'den i)
        have hne_of_mem : ∀ i, i ∈ vars.erase p → i ≠ p := by
          intro i hi heq; exact not_mem_erase_nodup p vars hnd (heq ▸ hi)
        -- Pivot split for a general row `d`: peel off `p`, replace `c` by `(e₀ p)·c'` off-pivot.
        have gsplit : ∀ (d : Nat → Q), (∀ i, 0 < (d i).den) →
            Qeq (qsumL (fun i => mul (d i) (c i)) vars)
              (add (mul (d p) (neg S))
                (mul (e₀ p) (qsumL (fun i => mul (d i) (c' i)) (vars.erase p)))) := by
          intro d hdden
          have hrowden : ∀ i, 0 < (mul (d i) (c i)).den := fun i => Qmul_den_pos (hdden i) (hcden i)
          have h1 := qsumL_erase (fun i => mul (d i) (c i)) hrowden p vars hpv
          have hcongr :
              Qeq (qsumL (fun i => mul (d i) (c i)) (vars.erase p))
                (qsumL (fun i => mul (e₀ p) (mul (d i) (c' i))) (vars.erase p)) := by
            apply qsumL_congr_mem
            intro i hi
            have hne := hne_of_mem i hi
            have key : Qeq (mul (d i) (mul (e₀ p) (c' i))) (mul (e₀ p) (mul (d i) (c' i))) := by
              simp only [Qeq, mul]; push_cast; ring_uor
            rw [hcoff i hne]; exact key
          have hsmul := qsumL_smul (e₀ p) (fun i => mul (d i) (c' i)) (he₀den p)
            (fun i => Qmul_den_pos (hdden i) (hc'den i)) (vars.erase p)
          have hvars' :
              Qeq (qsumL (fun i => mul (d i) (c i)) (vars.erase p))
                (mul (e₀ p) (qsumL (fun i => mul (d i) (c' i)) (vars.erase p))) :=
            Qeq_trans (qsumL_den _
                (fun i => Qmul_den_pos (he₀den p) (Qmul_den_pos (hdden i) (hc'den i))) (vars.erase p))
              hcongr hsmul
          have hstep2 :
              Qeq (add (mul (d p) (c p)) (qsumL (fun i => mul (d i) (c i)) (vars.erase p)))
                (add (mul (d p) (neg S))
                  (mul (e₀ p) (qsumL (fun i => mul (d i) (c' i)) (vars.erase p)))) := by
            apply Qadd_congr
            · rw [hcp]; exact Qeq_refl _
            · exact hvars'
          exact Qeq_trans
            (add_den_pos (Qmul_den_pos (hdden p) (hcden p)) (qsumL_den _ hrowden (vars.erase p)))
            h1 hstep2
        -- The witness: `w` is nonzero, lives off the pivot, so `c w = (e₀ p)·c' w ≉ 0`.
        have hwne : w ≠ p := fun heq => not_mem_erase_nodup p vars hnd (heq ▸ hw')
        have hwmem : w ∈ vars := List.mem_of_mem_erase hw'
        have hcwnz : ¬ Qeq (c w) (⟨0, 1⟩ : Q) := by
          rw [hcoff w hwne]; exact Qmul_ne_zero hpnz hw'nz
        refine ⟨c, hcden, ⟨w, hwmem, hcwnz⟩, ?_⟩
        intro e he
        rcases List.mem_cons.mp he with heq | he'
        · -- Pivot row `e₀`: `(e₀ p)·(−S) + (e₀ p)·S ≈ 0`.
          rw [heq]
          have g0 := gsplit e₀ he₀den
          have hfin0 : Qeq (add (mul (e₀ p) (neg S)) (mul (e₀ p) S)) (⟨0, 1⟩ : Q) := by
            simp only [Qeq, add, mul, neg]; push_cast; ring_uor
          exact Qeq_trans
            (add_den_pos (Qmul_den_pos (he₀den p) (neg_den_pos hSden))
              (Qmul_den_pos (he₀den p) hSden))
            g0 hfin0
        · -- A remaining row `e`: the reduced equation forces `(e₀ p)·T ≈ (e p)·S`, cancelling.
          have heden := hrestden e he'
          have ge := gsplit e heden
          have hfA : ∀ i, 0 < (mul (e₀ p) (mul (e i) (c' i))).den :=
            fun i => Qmul_den_pos (he₀den p) (Qmul_den_pos (heden i) (hc'den i))
          have hgB : ∀ i, 0 < (neg (mul (e p) (mul (e₀ i) (c' i)))).den :=
            fun i => neg_den_pos (Qmul_den_pos (heden p) (Qmul_den_pos (he₀den i) (hc'den i)))
          have hRsat : Qeq (qsumL (fun i => mul (redEqRow e₀ p e i) (c' i)) (vars.erase p))
              (⟨0, 1⟩ : Q) :=
            hc'sat (redEqRow e₀ p e) (List.mem_map_of_mem (redEqRow e₀ p) he')
          have s1 :
              Qeq (qsumL (fun i => mul (redEqRow e₀ p e i) (c' i)) (vars.erase p))
                (qsumL (fun i => add (mul (e₀ p) (mul (e i) (c' i)))
                  (neg (mul (e p) (mul (e₀ i) (c' i))))) (vars.erase p)) := by
            apply qsumL_congr
            intro i
            simp only [redEqRow, Qeq, Qsub, add, mul, neg]; push_cast; ring_uor
          have s2 := qsumL_add (fun i => mul (e₀ p) (mul (e i) (c' i)))
            (fun i => neg (mul (e p) (mul (e₀ i) (c' i)))) hfA hgB (vars.erase p)
          have pa := qsumL_smul (e₀ p) (fun i => mul (e i) (c' i)) (he₀den p)
            (fun i => Qmul_den_pos (heden i) (hc'den i)) (vars.erase p)
          have pb : Qeq (qsumL (fun i => neg (mul (e p) (mul (e₀ i) (c' i)))) (vars.erase p))
              (neg (mul (e p) (qsumL (fun i => mul (e₀ i) (c' i)) (vars.erase p)))) := by
            have hneg := qsumL_neg (fun i => mul (e p) (mul (e₀ i) (c' i)))
              (fun i => Qmul_den_pos (heden p) (Qmul_den_pos (he₀den i) (hc'den i))) (vars.erase p)
            have hsm := qsumL_smul (e p) (fun i => mul (e₀ i) (c' i)) (heden p)
              (fun i => Qmul_den_pos (he₀den i) (hc'den i)) (vars.erase p)
            exact Qeq_trans (neg_den_pos (qsumL_den _
                (fun i => Qmul_den_pos (heden p) (Qmul_den_pos (he₀den i) (hc'den i))) (vars.erase p)))
              hneg (Qneg_congr hsm)
          have s3 :
              Qeq (add (qsumL (fun i => mul (e₀ p) (mul (e i) (c' i))) (vars.erase p))
                    (qsumL (fun i => neg (mul (e p) (mul (e₀ i) (c' i)))) (vars.erase p)))
                (add (mul (e₀ p) (qsumL (fun i => mul (e i) (c' i)) (vars.erase p)))
                    (neg (mul (e p) (qsumL (fun i => mul (e₀ i) (c' i)) (vars.erase p))))) :=
            Qadd_congr pa pb
          have hdist :
              Qeq (qsumL (fun i => mul (redEqRow e₀ p e i) (c' i)) (vars.erase p))
                (Qsub (mul (e₀ p) (qsumL (fun i => mul (e i) (c' i)) (vars.erase p)))
                      (mul (e p) (qsumL (fun i => mul (e₀ i) (c' i)) (vars.erase p)))) := by
            have m1den : 0 < (qsumL (fun i => add (mul (e₀ p) (mul (e i) (c' i)))
                (neg (mul (e p) (mul (e₀ i) (c' i))))) (vars.erase p)).den :=
              qsumL_den _ (fun i => add_den_pos (hfA i) (hgB i)) (vars.erase p)
            have m2den : 0 < (add (qsumL (fun i => mul (e₀ p) (mul (e i) (c' i))) (vars.erase p))
                (qsumL (fun i => neg (mul (e p) (mul (e₀ i) (c' i)))) (vars.erase p))).den :=
              add_den_pos (qsumL_den _ hfA (vars.erase p)) (qsumL_den _ hgB (vars.erase p))
            exact Qeq_trans m1den s1 (Qeq_trans m2den s2 s3)
          have hsub0 :
              Qeq (Qsub (mul (e₀ p) (qsumL (fun i => mul (e i) (c' i)) (vars.erase p)))
                        (mul (e p) (qsumL (fun i => mul (e₀ i) (c' i)) (vars.erase p)))) (⟨0, 1⟩ : Q) := by
            have hd : 0 < (qsumL (fun i => mul (redEqRow e₀ p e i) (c' i)) (vars.erase p)).den :=
              qsumL_den _ (fun i => Qmul_den_pos (by
                show 0 < (Qsub (mul (e₀ p) (e i)) (mul (e p) (e₀ i))).den
                exact Qsub_den_pos (Qmul_den_pos (he₀den p) (heden i))
                  (Qmul_den_pos (heden p) (he₀den i))) (hc'den i)) (vars.erase p)
            exact Qeq_trans hd (Qeq_symm hdist) hRsat
          have hkey :
              Qeq (mul (e₀ p) (qsumL (fun i => mul (e i) (c' i)) (vars.erase p)))
                  (mul (e p) (qsumL (fun i => mul (e₀ i) (c' i)) (vars.erase p))) :=
            Qeq_of_Qsub_zero hsub0
          have hfin :
              Qeq (add (mul (e p) (neg S))
                  (mul (e₀ p) (qsumL (fun i => mul (e i) (c' i)) (vars.erase p)))) (⟨0, 1⟩ : Q) := by
            have step : Qeq (add (mul (e p) (neg S))
                (mul (e₀ p) (qsumL (fun i => mul (e i) (c' i)) (vars.erase p))))
                (add (mul (e p) (neg S)) (mul (e p) S)) := Qadd_congr (Qeq_refl _) hkey
            have fin2 : Qeq (add (mul (e p) (neg S)) (mul (e p) S)) (⟨0, 1⟩ : Q) := by
              simp only [Qeq, add, mul, neg]; push_cast; ring_uor
            exact Qeq_trans
              (add_den_pos (Qmul_den_pos (heden p) (neg_den_pos hSden))
                (Qmul_den_pos (heden p) hSden))
              step fin2
          exact Qeq_trans
            (add_den_pos (Qmul_den_pos (heden p) (neg_den_pos hSden))
              (Qmul_den_pos (he₀den p)
                (qsumL_den _ (fun i => Qmul_den_pos (heden i) (hc'den i)) (vars.erase p))))
            ge hfin
termination_by eqns.length
decreasing_by all_goals simp_wf

end Multiplicity.UOR.Bridge.F1Square.Square
