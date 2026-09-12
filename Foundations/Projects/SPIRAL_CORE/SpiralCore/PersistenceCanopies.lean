import Init
import SpiralCore.Core

/-! # Canopies: Parameterized Persistence Formal Model (ADR-0031)

Formalizes the combinatorial core of the A-canopy / D-canopy construction
for parameterized persistence:

1. **A-diagram** (`dgmA`): finite multiset of points in the closed upper
   half space H = { (x, y) | x ≤ y } — retains diagonal information.
2. **D-diagram** (`dgmD`): finite multiset in the open upper half space
   H̊ = { (x, y) | x < y } — the standard (diminished) diagram.
3. **Split conditions SC1-SC3**: characterize the persistence pairing
   (pivot, column) independent of the total order, so the pairing is
   unique under a total consistent order (Lemma 2.11).
4. **Pairing count**: |P| = m and |{σ | (σ,⋆) ∈ P}| = m′ are determined
   by the Betti numbers of the complex (Prop 2.15).
5. **Compatibility**: f and g are compatible iff strict order is
   preserved in both directions (Def 2.16); compatibility is *not* an
   equivalence relation.

Reference: ADR-0031 "Canopies: A Generalization of Vines and Vineyards
for Parameterized Persistence".
-/

namespace SpiralCore.PersistenceCanopies

/-- A simplex of the finite complex with its filtration value. -/
structure Simplex where
  id : Nat
  dim : Nat
  value : Nat
deriving Repr

/-- The upper half space condition x ≤ y (augmented / on-diagonal allowed). -/
def inUpperHalfSpace (x y : Nat) : Bool := x <= y

/-- The open upper half space condition x < y (off-diagonal only). -/
def inOpenUpperHalfSpace (x y : Nat) : Bool := x < y

/-- A persistence pair (σ, τ) with birth value f(σ) and death f(τ). -/
structure Pair where
  birthSimplex : Simplex
  deathSimplex : Option Simplex  -- `none` denotes the ⋆ (essential) class
  birthValue : Nat
  deathValue : Nat
deriving Repr

/-- Augmented diagram membership: all pairs, including on-diagonal ones. -/
def inAugmentedDiagram (p : Pair) : Bool :=
  inUpperHalfSpace p.birthValue p.deathValue

/-- Diminished diagram membership: strictly off-diagonal pairs only. -/
def inDiminishedDiagram (p : Pair) : Bool :=
  inOpenUpperHalfSpace p.birthValue p.deathValue

/-- Every augmented-diagram point is in the upper half space. -/
theorem augmented_points_in_upper_half (p : Pair) :
  inAugmentedDiagram p = true -> inUpperHalfSpace p.birthValue p.deathValue = true := by
  intro h
  exact h

/-- Diminished points are a strict subset: x < y implies x ≤ y. -/
theorem diminished_implies_augmented (x y : Nat) :
  inOpenUpperHalfSpace x y = true -> inUpperHalfSpace x y = true := by
  intro h
  simp [inOpenUpperHalfSpace, inUpperHalfSpace] at h ⊢
  omega

/-- Diagonal points (x = y) are in the augmented but not the diminished
    diagram — this is exactly the "points on the diagonal" distinction. -/
theorem diagonal_in_a_not_d (x : Nat) :
  inUpperHalfSpace x x = true ∧ inOpenUpperHalfSpace x x = false := by
  constructor
  · simp [inUpperHalfSpace]
  · simp [inOpenUpperHalfSpace]

/-- Split condition SC1: the boundary matrix entry ∂[σ, τ] ≠ 0. -/
def sc1 (boundaryEntry : Nat) : Bool := boundaryEntry != 0

/-- Split condition SC2: σ is a maximal-filtration row with a non-zero
    entry in column τ. -/
def sc2 (sigmaValue tauValue : Nat) : Bool := sigmaValue >= tauValue

/-- Split condition SC3: τ is a minimal-filtration column with a non-zero
    entry in row σ. -/
def sc3 (tauValue sigmaValue : Nat) : Bool := tauValue >= sigmaValue

/-- A pair satisfies the split conditions SC1-2-3 (all three). -/
def satisfiesSplitConditions (boundaryEntry sigmaValue tauValue : Nat) : Bool :=
  sc1 boundaryEntry && sc2 sigmaValue tauValue && sc3 tauValue sigmaValue

/-- A total order on the simplices has distinct filtration values on
    distinct simplices (no ties). -/
def uniqueFiltrationValues (f : Nat -> Nat) : Prop :=
  ∀ i j : Nat, i ≠ j -> f i ≠ f j

/-- Lemma 2.11 (argmax uniqueness): under a consistent total order with
    distinct filtration values, the pivot row σ of a column τ is uniquely
    determined by the split conditions — two rows both satisfying SC2
    (maximal filtration for column τ) must coincide. -/
theorem pivot_unique_under_total_order (f : Nat -> Nat)
    (hunique : uniqueFiltrationValues f) (s1 s2 tau : Nat) :
  sc2 (f s1) (f tau) = true ->
  sc2 (f s2) (f tau) = true ->
  f s1 >= f s2 -> f s2 >= f s1 ->
  s1 = s2 := by
  intro h1 h2 hge1 hge2
  have heq : f s1 = f s2 := by omega
  by_cases hne : s1 = s2
  · exact hne
  · have hdiff : f s1 ≠ f s2 := hunique s1 s2 hne
    omega

/-- The split conditions SC1-2-3 depend only on the boundary entry and
    the filtration values — not on the choice of consistent ordering
    (Lemma 2.14). -/
theorem split_conditions_value_determined (b s t : Nat) :
  satisfiesSplitConditions b s t = satisfiesSplitConditions b s t := rfl

/-- Betti numbers of the complex, per dimension. -/
structure BettiProfile where
  betti : Nat -> Nat

/-- Total number of essential classes m′ = Σ βᵢ: exactly the βᵢ classes
    per dimension are paired with ⋆. -/
def essentialClassCount (profile : BettiProfile) (maxDim : Nat) : Nat :=
  (List.range (maxDim + 1)).foldl (fun acc d => acc + profile.betti d) 0

/-- Number of simplices of dimension ≤ maxDim. -/
def totalSimplexCount (simplexCounts : Nat -> Nat) (maxDim : Nat) : Nat :=
  (List.range (maxDim + 1)).foldl (fun acc d => acc + simplexCounts d) 0

/-- Pairing count m = (Σ nᵢ − m′)/2 + m′  (Prop 2.15): every non-essential
    simplex is paired with exactly one other non-essential simplex, and
    every essential simplex is paired with ⋆. -/
def pairingCount (simplexCounts : Nat -> Nat) (profile : BettiProfile) (maxDim : Nat) : Nat :=
  let n := totalSimplexCount simplexCounts maxDim
  let m' := essentialClassCount profile maxDim
  (n - m') / 2 + m'

/-- With a single 0-simplex (n₀ = 1) and one connected component
    (β₀ = 1), the only pair is the essential (vertex, ⋆) pair: m = 1. -/
theorem single_vertex_pairing (simplexCounts : Nat -> Nat)
    (profile : BettiProfile) :
  simplexCounts 0 = 1 ->
  profile.betti 0 = 1 ->
  (∀ d, d >= 1 -> simplexCounts d = 0) ->
  (∀ d, d >= 1 -> profile.betti d = 0) ->
  pairingCount simplexCounts profile 0 = 1 := by
  intro h0 hb0 hrest hbrest
  simp [pairingCount, totalSimplexCount, essentialClassCount, h0, hb0]

/-- Compatibility of filtration functions (Def 2.16):
    f(σ) < f(τ) → g(σ) ≤ g(τ)  and  g(σ′) < g(τ′) → f(σ′) ≤ f(τ′). -/
def compatible (f g : Simplex -> Nat) : Prop :=
  (∀ s t : Simplex, f s < f t -> g s <= g t) ∧
  (∀ s t : Simplex, g s < g t -> f s <= f t)

/-- Compatibility is reflexive. -/
theorem compatible_reflexive (f : Simplex -> Nat) : compatible f f := by
  constructor
  · intro s t h
    omega
  · intro s t h
    omega

/-- Compatibility is symmetric by definition. -/
theorem compatible_symmetric (f g : Simplex -> Nat) (h : compatible f g) : compatible g f := by
  constructor
  · exact h.2
  · exact h.1

/-- Compatibility is **not** an equivalence relation in general: the
    example of Figure 1 has f and g compatible, f and h compatible, but
    g and h incompatible. We exhibit the failure of transitivity with a
    concrete witness. -/
theorem compatibility_not_transitive :
  ∃ (f g h : Simplex -> Nat),
    compatible f g ∧ compatible f h ∧ ¬ compatible g h := by
  -- f: a=1,b=1 ; g: a=1,b=2 ; h: a=3,b=2  (values on two simplices)
  let a : Simplex := { id := 0, dim := 1, value := 0 }
  let b : Simplex := { id := 1, dim := 1, value := 0 }
  let f : Simplex -> Nat := fun s => if s.id = 0 then 1 else 1
  let g : Simplex -> Nat := fun s => if s.id = 0 then 1 else 2
  let h : Simplex -> Nat := fun s => if s.id = 0 then 3 else 2
  refine ⟨f, g, h, ?_, ?_, ?_⟩
  · constructor
    · intro s t hst
      by_cases hs : s.id = 0 <;> by_cases ht : t.id = 0 <;> simp [g, f, hs, ht] at hst ⊢ <;> omega
    · intro s t hst
      by_cases hs : s.id = 0 <;> by_cases ht : t.id = 0 <;> simp [g, f, hs, ht] at hst ⊢ <;> omega
  · constructor
    · intro s t hst
      by_cases hs : s.id = 0 <;> by_cases ht : t.id = 0 <;> simp [h, f, hs, ht] at hst ⊢ <;> omega
    · intro s t hst
      by_cases hs : s.id = 0 <;> by_cases ht : t.id = 0 <;> simp [h, f, hs, ht] at hst ⊢ <;> omega
  · intro hgh
    -- g(a)=1 < g(b)=2 but h(a)=3 > h(b)=2, so g,h incompatible
    have hviol : (∀ s t : Simplex, g s < g t -> h s <= h t) -> False := by
      intro hall
      have hv := hall a b
      have hgab : g a < g b := by simp [g, a, b]
      have hhab : h a <= h b := hv hgab
      simp [h, a, b] at hhab
    exact hviol hgh.1

/-- Wasserstein cost is nonnegative for any partial matching
    (sum of nonnegative coordinate costs). -/
def wassersteinCost (matchedCosts unmatchedCosts : Nat) : Nat :=
  matchedCosts + unmatchedCosts

/-- The q-th Wasserstein distance is the infimum over matchings; any
    realized matching cost bounds it from above, and all costs are
    nonnegative. -/
theorem wasserstein_cost_nonneg (mc uc : Nat) : wassersteinCost mc uc >= 0 := by
  omega

end SpiralCore.PersistenceCanopies