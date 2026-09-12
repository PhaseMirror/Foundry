/-!
# Foundations.Recursive.Core — Core Recursive Types and Functions

Defines foundational recursive types: natural numbers with induction,
lists with recursion, and binary trees.
All definitions are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Recursive.Core

/-! ## Natural Numbers — Peano Axioms -/

inductive PNat where
  | zero : PNat
  | succ : PNat → PNat
  deriving Repr, DecidableEq

open PNat

/-- Addition: `n + m`. -/
def add (n m : PNat) : PNat :=
  match n with
  | zero => m
  | succ p => succ (add p m)

/-- Multiplication: `n * m`. -/
def mul (n m : PNat) : PNat :=
  match n with
  | zero => zero
  | succ p => add m (mul p m)

/-- Predecessor: `pred n`. -/
def pred (n : PNat) : PNat :=
  match n with
  | zero => zero
  | succ p => p

/-- Subtraction: `n - m` (truncated at zero). -/
def sub (n m : PNat) : PNat :=
  match m with
  | zero => n
  | succ q => sub (pred n) q

/-- Less than or equal: `n ≤ m`. -/
def le (n m : PNat) : Prop :=
  match n with
  | zero => True
  | succ p =>
    match m with
    | zero => False
    | succ q => le p q

/-! ### Theorems -/

theorem add_zero (n : PNat) : add n zero = n := by
  induction n with
  | zero => rfl
  | succ p ih => simp [add, ih]

theorem add_succ (n m : PNat) : add n (succ m) = succ (add n m) := by
  induction n with
  | zero => rfl
  | succ p ih => simp [add, ih]

theorem add_assoc (n m k : PNat) : add (add n m) k = add n (add m k) := by
  induction n with
  | zero => rfl
  | succ p ih => simp [add, ih]

theorem zero_add (n : PNat) : add zero n = n := rfl

theorem add_comm (n m : PNat) : add n m = add m n := by
  induction n with
  | zero => rw [add_zero, zero_add]
  | succ p ih => rw [add_succ, ← ih]; rfl

theorem mul_zero (n : PNat) : mul n zero = zero := by
  induction n with
  | zero => rfl
  | succ p ih => simp [mul, ih, add_zero]

theorem le_refl (n : PNat) : le n n := by
  induction n with
  | zero => trivial
  | succ p ih => exact ih

/-! ## Lists — Recursive Data Structure -/

inductive PList (α : Type) where
  | nil : PList α
  | cons : α → PList α → PList α
  deriving Repr, DecidableEq

open PList

variable {α : Type}

/-- Append: `xs ++ ys`. -/
def append (xs ys : PList α) : PList α :=
  match xs with
  | nil => ys
  | cons x xs' => cons x (append xs' ys)

/-- Length: `length xs`. -/
def length (xs : PList α) : PNat :=
  match xs with
  | nil => zero
  | cons _ xs' => succ (length xs')

/-- Map: `map f xs`. -/
def pmap {β : Type} (f : α → β) (xs : PList α) : PList β :=
  match xs with
  | nil => nil
  | cons x xs' => cons (f x) (pmap f xs')

/-- Fold right: `foldr f z xs`. -/
def foldr {β : Type} (f : α → β → β) (z : β) (xs : PList α) : β :=
  match xs with
  | nil => z
  | cons x xs' => f x (foldr f z xs')

/-! ### List Theorems -/

theorem length_nil : length (@nil α) = zero := rfl

theorem length_cons (x : α) (xs : PList α) : length (cons x xs) = succ (length xs) := rfl

theorem append_nil (xs : PList α) : append xs nil = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [append, ih]

theorem append_assoc (xs ys zs : PList α) :
    append (append xs ys) zs = append xs (append ys zs) := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [append, ih]

theorem pmap_id (xs : PList α) : pmap (fun x => x) xs = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [pmap, ih]

theorem length_pmap {β : Type} (f : α → β) (xs : PList α) :
    length (pmap f xs) = length xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [pmap, length, ih]

/-! ## Binary Trees -/

inductive PTree (α : Type) where
  | leaf : PTree α
  | node : α → PTree α → PTree α → PTree α
  deriving Repr, DecidableEq

open PTree

/-- Size: `size t` (number of nodes). -/
def size (t : PTree α) : PNat :=
  match t with
  | leaf => zero
  | node _ l r => succ (add (size l) (size r))

/-- Maximum of two natural numbers. -/
def pmax (n m : PNat) : PNat :=
  match n, m with
  | zero, _ => m
  | _, zero => n
  | succ p, succ q => succ (pmax p q)

/-- Depth: `depth t` (length of longest path). -/
def depth (t : PTree α) : PNat :=
  match t with
  | leaf => zero
  | node _ l r => succ (pmax (depth l) (depth r))

/-- Map: `ptree_map f t`. -/
def ptree_map {β : Type} (f : α → β) (t : PTree α) : PTree β :=
  match t with
  | leaf => leaf
  | node x l r => node (f x) (ptree_map f l) (ptree_map f r)

/-! ### Tree Theorems -/

theorem size_leaf : size (leaf : PTree α) = zero := rfl

theorem size_node (x : α) (l r : PTree α) :
    size (node x l r) = succ (add (size l) (size r)) := rfl

theorem depth_leaf : depth (leaf : PTree α) = zero := rfl

theorem depth_node (x : α) (l r : PTree α) :
    depth (node x l r) = succ (pmax (depth l) (depth r)) := rfl

theorem ptree_map_id (t : PTree α) : ptree_map (fun x => x) t = t := by
  induction t with
  | leaf => rfl
  | node x l r ih_l ih_r => simp [ptree_map, ih_l, ih_r]

end Foundations.Recursive.Core
