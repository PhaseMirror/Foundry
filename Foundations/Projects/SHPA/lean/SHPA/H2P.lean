import SHPA.Types

set_option autoImplicit false

/-!
# Stateless Hash-to-Prime (H2P) Derivation & Offset Pinning
-/

namespace SHPA

/-- Max offset allowed by Cramér heuristic bound: k_max = 65536. -/
def K_MAX : Nat := 65536

/-- Derive odd seed N from 256-bit hash. -/
def hash_to_odd_seed (h : Hash256) : Nat :=
  if h.val % 2 == 1 then h.val else h.val + 1

/-- Primality predicate (abstract or verified). -/
def is_valid_prime_candidate (n : Nat) (is_prime_fn : Nat → Bool) : Bool :=
  n > 1 && is_prime_fn n

/-- Minimal offset property: k is the smallest even offset such that N + k is prime. -/
def is_first_prime_offset (N k : Nat) (is_prime_fn : Nat → Bool) : Prop :=
  is_valid_prime_candidate (N + k) is_prime_fn = true ∧
  k % 2 = 0 ∧
  k ≤ K_MAX ∧
  ∀ l : Nat, l < k → l % 2 = 0 → is_valid_prime_candidate (N + l) is_prime_fn = false

/-- Theorem: If k is the first prime offset for N, any alternative offset k' with k' < k cannot be prime. -/
theorem first_prime_offset_uniqueness (N k k' : Nat) (is_prime_fn : Nat → Bool)
    (h_first : is_first_prime_offset N k is_prime_fn)
    (h_even : k' % 2 = 0)
    (h_lt : k' < k) :
    is_valid_prime_candidate (N + k') is_prime_fn = false := by
  rcases h_first with ⟨_, _, _, h_gap⟩
  exact h_gap k' h_lt h_even

/-- Theorem: Two identical seeds yield identical first-prime assignments under the same primality oracle. -/
theorem h2p_deterministic (N k1 k2 : Nat) (is_prime_fn : Nat → Bool)
    (h1 : is_first_prime_offset N k1 is_prime_fn)
    (h2 : is_first_prime_offset N k2 is_prime_fn) :
    k1 = k2 := by
  rcases h1 with ⟨h_cand1, h_even1, _, h_gap1⟩
  rcases h2 with ⟨h_cand2, h_even2, _, h_gap2⟩
  by_cases h_lt : k1 < k2
  · have h_false := h_gap2 k1 h_lt h_even1
    rw [h_cand1] at h_false
    contradiction
  · by_cases h_gt : k2 < k1
    · have h_false := h_gap1 k2 h_gt h_even2
      rw [h_cand2] at h_false
      contradiction
    · omega

end SHPA
