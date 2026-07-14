import Lean.Data.Json
import SemanticArithmetic.Core
import SemanticArithmetic.Operator
import SemanticArithmetic.Proofs

open Lean.Json
open SemanticArithmetic.Core
open SemanticArithmetic.Operator

-- Define a structure for the basis entry
structure BasisEntry where
  n : Nat
  exponents : List Nat
  deriving DecidableEq, Repr, Lean.FromJson

-- Define the full basis structure
structure BasisData where
  primes : List Nat
  max_exp : Nat
  basis : List BasisEntry
  deriving DecidableEq, Repr, Lean.FromJson

/-- Reconstruct a multi-set (list) of primes given the ordered exponents -/
def reconstruct_trace (primes : List Nat) (exponents : List Nat) : List Nat :=
  match primes, exponents with
  | [], _ => []
  | _, [] => []
  | p::ps, e::es => (List.replicate e p) ++ reconstruct_trace ps es

def verify_entry (primes : List Nat) (entry : BasisEntry) : Prop :=
  -- if n is not 0, we can construct the node
  if h : entry.n > 0 then
    let node : SemanticNode := ⟨entry.n, h⟩
    let trace := Xi_trace node
    -- Check if trace matches the reconstructed list of primes from the exponent vector
    trace = reconstruct_trace primes entry.exponents
  else True

def verify_basis (data : BasisData) : Prop :=
  ∀ entry ∈ data.basis, verify_entry data.primes entry

-- A test function that loads JSON from a file and verifies it
-- For simplicity, we just return true if it passes the runtime check
def check_entry_runtime (primes : List Nat) (entry : BasisEntry) : Bool :=
  if h : entry.n > 0 then
    let node : SemanticNode := ⟨entry.n, h⟩
    let trace := Xi_trace node
    trace == reconstruct_trace primes entry.exponents
  else true

def load_and_verify (filename : String) : IO (Option BasisData) := do
  let content ← IO.FS.readFile filename
  match Lean.Json.parse content with
  | .ok json => 
    match Lean.FromJson.fromJson? json with
    | .ok data =>
      let mut all_valid := true
      for entry in data.basis do
        if not (check_entry_runtime data.primes entry) then
          IO.println s!"Verification failed for n={entry.n}"
          all_valid := false
      if all_valid then
        return some data
      else
        return none
    | .error e =>
      IO.println s!"JSON parsing error: {e}"
      return none
  | .error e =>
    IO.println s!"Invalid JSON: {e}"
    return none
