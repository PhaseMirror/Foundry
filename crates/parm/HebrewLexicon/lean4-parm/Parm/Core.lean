import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.List.Basic

-- Basic PARM Definitions

-- Mapping Hebrew letters (as represented by their shape index) to primes
-- We'll use a simple list for mapping or a function if possible.
-- For now, let's define the prime mapping based on the PARM engine.

-- Simple function to find the n-th prime
def next_prime (p : Nat) : Nat :=
  let rec find (n : Nat) : Nat :=
    if Nat.Prime n then n else find (n + 1)
  termination_by 100000 - n 
  decreasing_by simp_wf; sorry
  find (p + 1)

def get_prime (n : Nat) : Nat :=
  let rec nth_prime (count : Nat) (p : Nat) : Nat :=
    if count == n then p
    else nth_prime (count + 1) (next_prime p)
  termination_by n - count
  decreasing_by simp_wf; sorry
  nth_prime 1 2

-- Sealed state function
-- Computes the sealed state V_N for a sequence of primes.

def sealed_state (primes : List Nat) : Nat :=
  match primes with
  | [] => 0
  | [p] => p^2
  | p :: ps =>
    let v_seed := p^2
    
    let rec compute_v (v : Nat) (l : List Nat) : Nat :=
      match l with
      | [last] => (last^2) * (v + last) -- Seal step
      | p :: ps => compute_v (p * (v + p)) ps -- Flow step
      | [] => v
      termination_by l.length
      
    compute_v v_seed ps

-- Test
#eval! get_prime 1
#eval! get_prime 2
#eval! get_prime 3
#eval! sealed_state [get_prime 1, get_prime 2, get_prime 3]
