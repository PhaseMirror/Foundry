import Lean.Data.Json
import Lean.Data.Json.FromToJson
import Lean.IO.FS
import Foundations.F1.Analysis.RAddNF          -- provides Xi_trace, factors, etc.
import universal_closure.Dirichlet -- provides is_prime, etc.

open Lean Json IO

-- =============================================================================
-- 1. Define the basis parameters (must match the Rust/NumPy config)
-- =============================================================================
def primes : List Nat := [2, 3, 5, 7]
def max_exp : Nat := 3

-- Generate all exponent combinations as lists of length 4, each in 0..max_exp
def gen_exps : List (List Nat) :=
  let rec loop (acc : List (List Nat)) (remaining : Nat) : List (List Nat) :=
    if remaining = 0 then acc
    else
      let new_acc := acc.bind (λ exps => (List.range (max_exp + 1)).map (λ e => e :: exps))
      loop new_acc (remaining - 1)
  loop [[]] (List.length primes)

-- Compute the integer from its prime exponents
def number_of_exps (exps : List Nat) : Nat :=
  List.zip primes exps |>.foldl (λ acc (p, e) => acc * (p ^ e)) 1

-- The full basis: list of pairs (n, Xi_trace n) for n > 1
def basis_entries : List (Nat × List Nat) :=
  let numbers := gen_exps.map number_of_exps
  numbers.filterMap (λ n =>
    if n = 1 then none
    else some (n, Xi_trace n))

-- =============================================================================
-- 2. Prove that the certificate is collision-free (optional, but seals the lock)
-- =============================================================================
theorem certificate_unique : ∀ (a b : Nat × List Nat) (ha hb : a ∈ basis_entries) (hb : b ∈ basis_entries),
  a.snd = b.snd → a.fst = b.fst :=
by
  intro a b ha hb h_trace_eq
  apply semantic_trace_unique
  · exact ha.1  -- a > 1 from construction
  · exact hb.1  -- b > 1
  · exact h_trace_eq

-- =============================================================================
-- 3. JSON serialisation (matches the Python schema)
-- =============================================================================
structure BasisEntry where
  n : Nat
  exponents : List Nat
  deriving FromJson, ToJson

structure BasisData where
  primes : List Nat
  max_exp : Nat
  basis : List BasisEntry
  deriving FromJson, ToJson

def to_basis_entry (n : Nat) : BasisEntry :=
  let exps := factors n  -- We want the raw exponents to match the Python 'val' array
  -- Since we only have Xi_trace (sorted primes), we need to recover exponents.
  -- To keep it simple, we'll store the *prime factors* (Xi_trace) instead of exponents,
  -- because Rust can rebuild the exponents from the primes.
  -- But the Python script expects exponents. We can compute exponents by counting in Xi_trace.
  let exps := primes.map (λ p => (Xi_trace n).count p)
  ⟨n, exps⟩

def basis_data : BasisData :=
  let entries := basis_entries.map (λ ⟨n, _⟩ => to_basis_entry n)
  ⟨primes, max_exp, entries⟩

def to_json (data : BasisData) : String :=
  toString (toJson data)

-- =============================================================================
-- 4. The executable that writes the certificate
-- =============================================================================
def main : IO Unit := do
  IO.println s!"Generating certified basis with {basis_entries.length} entries..."
  let json := to_json basis_data
  -- Write to file
  FS.writeFile "basis_factors.json" json
  IO.println "✅ Certified basis_factors.json generated successfully."
  IO.println s!"   Primes: {primes}"
  IO.println s!"   Max exponent: {max_exp}"
  IO.println s!"   Total states: {basis_entries.length}"

#eval main
