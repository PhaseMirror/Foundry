import CulturalMath.Base

namespace CulturalMath.African

-- Self-similarity
def fractalIterate' (k T0 : Nat) : Nat → Nat
  | 0     => T0
  | n + 1 => fractalIterate' k T0 n / k

theorem fractal_selfSimilar (k T0 : Nat) :
    ∀ n, fractalIterate' k T0 (n + 1) = fractalIterate' k T0 n / k := by
  intro n; simp [fractalIterate']

-- Proportional ratio
def africanRatio (a b : Nat) : Nat := a / b

-- Halving
def africanHalve (n : Nat) : Nat := n / 2

theorem halve_double_even (n : Nat) (h : n % 2 = 0) : africanHalve (n + n) = n := by
  simp [africanHalve]; omega

theorem halve_reduces (n : Nat) (hn : n ≥ 1) : africanHalve n ≤ n := by
  simp [africanHalve]; omega

private theorem repeat_shift (k : Nat) (a : Nat) :
    Nat.repeat africanHalve (k + 1) a = Nat.repeat africanHalve k (africanHalve a) := by
  induction k generalizing a with
  | zero => rfl
  | succ k ih =>
    show africanHalve (Nat.repeat africanHalve (k + 1) a) = africanHalve (Nat.repeat africanHalve k (africanHalve a))
    rw [ih]

theorem halve_converges (n : Nat) : ∃ k, Nat.repeat africanHalve k n = 0 := by
  suffices h : ∀ m, m ≤ n → ∃ k, Nat.repeat africanHalve k m = 0 from h n (Nat.le_refl n)
  induction n with
  | zero => intro m hm; exact ⟨0, by simp [Nat.repeat]; omega⟩
  | succ n ih =>
    intro m hm
    by_cases h0 : m = 0
    · subst h0; exact ⟨0, by simp [Nat.repeat]⟩
    · have hm1 : m / 2 ≤ n := by omega
      obtain ⟨k, hk⟩ := ih (m / 2) hm1
      exact ⟨k + 1, by rw [repeat_shift]; simp [africanHalve]; exact hk⟩

-- Symbolic state
def symbolicState (primes coeffs : List Nat) : Nat :=
  (primes.zip coeffs).foldl (fun acc (p, c) => acc + c * p) 0

private theorem foldl_add_base {α : Type} (f : Nat → α → Nat) (g : α → Nat)
    (h : ∀ acc x, f acc x = acc + g x) :
    ∀ (xs : List α) (base : Nat),
      List.foldl f base xs = base + List.foldl f 0 xs
  | [], _ => by simp [List.foldl]
  | x :: xs, base => by
    have ih := foldl_add_base f g h xs
    simp only [List.foldl_cons, h base x, h 0 x]
    rw [ih (base + g x), Nat.zero_add, ih (g x)]
    omega

theorem symbolicState_nil : symbolicState [] [] = 0 := by simp [symbolicState]
theorem symbolicState_cons (p c : Nat) (ps cs : List Nat) :
    symbolicState (p :: ps) (c :: cs) = c * p + symbolicState ps cs := by
  simp only [symbolicState, List.zip_cons_cons, List.foldl_cons, Nat.zero_add]
  exact foldl_add_base (fun acc x => acc + x.snd * x.fst) (fun x => x.snd * x.fst)
    (fun _ _ => rfl) (ps.zip cs) (c * p)

-- Cyclic tensor
def cyclicTensor (T₀ period : Nat) : Nat → Nat
  | t => if t % period < period / 2 then T₀ else 0

theorem cyclicTensor_bounded (T₀ period t : Nat) (_hp : period ≥ 1) :
    cyclicTensor T₀ period t ≤ T₀ := by
  simp [cyclicTensor]; split <;> omega

end CulturalMath.African
