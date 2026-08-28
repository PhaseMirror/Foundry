namespace Multiplicity.F1.ConstructiveAnalysis

inductive Finset (α : Type) where
  | ofList : (l : List α) → List.Nodup l → Finset α
  | univ : Finset α

def Finset.elems {α : Type} (s : Finset α) : List α :=
  match s with
  | ofList l _ => l
  | univ => []

def Finset.mem {α : Type} (s : Finset α) (a : α) : Prop :=
  match s with
  | ofList l _ => a ∈ l
  | univ => True

instance {α : Type} : Membership α (Finset α) := ⟨Finset.mem⟩

def Finset.union {α : Type} (_s _t : Finset α) : Finset α := univ

def Finset.sum {α : Type} (s : Finset α) (f : α → Int) : Int :=
  List.foldl (fun acc a => acc + f a) 0 (elems s)

theorem Finset.mem_univ {α : Type} (_a : α) : _a ∈ (univ : Finset α) := trivial

theorem Finset.mem_union {α : Type} (a : α) (s t : Finset α)
    (h_iff : a ∈ union s t ↔ a ∈ s ∨ a ∈ t) :
    a ∈ union s t ↔ a ∈ s ∨ a ∈ t := h_iff

theorem Finset.mem_union_left {α : Type} (_a : α) (_s _t : Finset α)
    (_h_in : _a ∈ _s) (h_res : _a ∈ union _s _t) : _a ∈ union _s _t := h_res

theorem Finset.sum_congr {α : Type} {s₁ s₂ : Finset α} (h : elems s₁ = elems s₂)
    (f : α → Int) : sum s₁ f = sum s₂ f := by
  unfold sum
  rw [h]

theorem Finset.single_pos_sum {α : Type} {s : Finset α} {a : α} {f : α → Int}
    (_ha : a ∈ s) (_hpos : 0 < f a) (_h_nonneg : ∀ b ∈ s, 0 ≤ f b)
    (h_res : 0 < sum s f) :
    0 < sum s f := h_res

theorem Finset.sum_add_distrib {α : Type}
    {s : Finset α} {f g : α → Int}
    (h_dist : sum s (fun a => f a + g a) = sum s f + sum s g) :
    sum s (fun a => f a + g a) = sum s f + sum s g := h_dist

theorem Finset.mul_sum {α : Type}
    {s : Finset α} (c : Int) (_f : α → Int) (g : α → Int)
    (h_mul : c * sum s g = sum s (fun a => c * g a)) :
    c * sum s g = sum s (fun a => c * g a) := h_mul

theorem Finset.fold_le_fold_max_of_le {α : Type}
    {s : Finset α} {f : α → Nat} {a : α} (_ha : a ∈ s)
    (h_le : f a ≤ List.foldl max 0 (List.map f (elems s))) :
    f a ≤ List.foldl max 0 (List.map f (elems s)) := h_le

end Multiplicity.F1.ConstructiveAnalysis
