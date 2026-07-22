namespace F1.ConstructiveAnalysis

inductive Finset (α : Type) where
  | ofList : (l : List α) → List.Nodup l → Finset α
  | univ : Finset α

def Finset.elems {α : Type} (s : Finset α) : List α :=
  match s with
  | ofList l nd => l
  | univ => []

def Finset.mem {α : Type} (s : Finset α) (a : α) : Prop :=
  match s with
  | ofList l nd => a ∈ l
  | univ => True

instance {α : Type} : Membership α (Finset α) := ⟨Finset.mem⟩

def Finset.union {α : Type} (s t : Finset α) : Finset α := sorry


def Finset.sum {α : Type} (s : Finset α) (f : α → Int) : Int :=
  List.foldl (fun acc a => acc + f a) 0 (elems s)

theorem Finset.mem_univ {α : Type} (a : α) : a ∈ (univ : Finset α) := by
  sorry

theorem Finset.mem_union {α : Type} (a : α) (s t : Finset α) :
    a ∈ union s t ↔ a ∈ s ∨ a ∈ t := by
  sorry

theorem Finset.mem_union_left {α : Type} (a : α) (s t : Finset α) :
    a ∈ s → a ∈ union s t := by
  sorry

theorem Finset.sum_congr {α : Type} {s₁ s₂ : Finset α} (h : elems s₁ = elems s₂)
    (f : α → Int) : sum s₁ f = sum s₂ f := by
  unfold sum
  rw [h]

theorem Finset.single_pos_sum {α : Type} {s : Finset α} {a : α} {f : α → Int}
    (ha : a ∈ s) (hpos : 0 < f a) (h_nonneg : ∀ b ∈ s, 0 ≤ f b) :
    0 < sum s f := by
  sorry

theorem Finset.sum_add_distrib {α : Type}
    {s : Finset α} {f g : α → Int} :
    sum s (fun a => f a + g a) = sum s f + sum s g := by
  sorry

theorem Finset.mul_sum {α : Type}
    {s : Finset α} (c : Int) (f : α → Int) (g : α → Int) :
    c * sum s g = sum s (fun a => c * g a) := by
  sorry

theorem Finset.fold_le_fold_max_of_le {α : Type}
    {s : Finset α} {f : α → Nat} {a : α} (ha : a ∈ s) :
    f a ≤ List.foldl max 0 (List.map f (elems s)) := by
  sorry

end F1.ConstructiveAnalysis
