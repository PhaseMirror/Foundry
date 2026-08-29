/-!
# Automorphic Learning: Core Type Definitions

Prime-structured inductive bias, AGL(1,p) group actions, and CRT embeddings.
All proofs are complete (no `sorry`).
-/

namespace Automorphic

/-! ## Primes -/

def isPrime (n : Nat) : Prop :=
  n ≥ 2 ∧ ∀ d, d ∣ n → d = 1 ∨ d = n

/-- A finite prime. -/
structure Prime where
  val : Nat
  isPrime : isPrime val
  gt2 : val > 2

/-! ## CRT Embeddings -/

/-- CRT embedding from natural numbers to a pair of prime residue fields. -/
structure CrtEmbedding (p1 p2 : Nat) where
  embed : Fin (p1 * p2) → Fin p1 × Fin p2
  embed_inj : Function.Injective embed

/-! ## AGL(1,p) -/

/-- AGL(1,p) group element: x ↦ u·x + k (mod p). -/
structure AglElement (p : Nat) where
  u : Fin p
  k : Fin p
  u_nonzero : u.val ≠ 0

/-- Apply an AGL(1,p) element to a residue class. -/
def AglElement.apply {p : Nat} (hp : p > 0) (g : AglElement p) (x : Fin p) : Fin p :=
  ⟨(g.u.val * x.val + g.k.val) % p, Nat.mod_lt _ hp⟩

/-- Composition of AGL(1,p) elements. -/
def AglElement.compose {p : Nat} (hp : p > 0) (g h : AglElement p) (h_u : (g.u.val * h.u.val) % p ≠ 0) : AglElement p :=
  ⟨⟨(g.u.val * h.u.val) % p, Nat.mod_lt _ hp⟩,
   ⟨(g.u.val * h.k.val + g.k.val) % p, Nat.mod_lt _ hp⟩,
   h_u⟩

/-- Identity element of AGL(1,p) for p ≥ 2. -/
def AglElement.id (p : Nat) (hp : p ≥ 2) : AglElement p :=
  ⟨⟨1, by omega⟩, ⟨0, by omega⟩, by intro h; cases h⟩

/-! ## Legendre Symbol -/

/-- Legendre symbol χ_p(a) via Euler's criterion. -/
def legendreSymbol (a p : Nat) : Int :=
  if a % p = 0 then 0
  else if (a % p) ^ ((p - 1) / 2) % p = 1 then 1
  else -1

/-- Legendre symbol is in {-1, 0, 1}. -/
theorem legendreSymbol_mem_ternary (a p : Nat) :
    legendreSymbol a p = 0 ∨ legendreSymbol a p = 1 ∨ legendreSymbol a p = -1 := by
  unfold legendreSymbol
  split
  · left; rfl
  · split
    · right; left; rfl
    · right; right; rfl

/-! ## Residue Mask -/

/-- Residue mask from CRT embedding. -/
def residueMask (p1 p2 : Nat) (n : Nat) (h_n : n = p1 * p2)
    (emb : CrtEmbedding p1 p2) :
    Fin n → Fin n → Bool :=
  fun i j =>
    let i_fin : Fin (p1 * p2) := ⟨i.val, by omega⟩
    let j_fin : Fin (p1 * p2) := ⟨j.val, by omega⟩
    let (a1, _) := emb.embed i_fin
    let (a2, b2) := emb.embed j_fin
    (legendreSymbol (a1.val - a2.val) p1 == 1) &&
    (legendreSymbol (a2.val - b2.val) p2 == 1)

end Automorphic
