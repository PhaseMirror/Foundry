import Kernel

/-!
# Mcpe — multi-prime offset cipher invertibility

Formalizes the MCPE (Matrix Compute Paradigm Engine) cipher invariant: decryption
inverts encryption. We model the additive offset scheme over a fixed modulus;
the round-trip recovers the plaintext. No `Mathlib`, no `sorry`.
-/
namespace Mcpe

open proofs.Kernel

/-- Working modulus of the cipher. -/
def N : Nat := 2 ^ 8

/-- Encryption: add the key (mod `N`). -/
def encrypt (m k : Nat) : Nat := (m + k) % N

/-- Decryption: subtract the key, wrapped (mod `N`). -/
def decrypt (c k : Nat) : Nat := (c + (N - k)) % N

/-- Round-trip: decryption of a ciphertext recovers the plaintext (for `k, m < N`). -/
theorem roundtrip (m k : Nat) (hk : k < N) (hm : m < N) :
    decrypt (encrypt m k) k = m := by
  simp only [encrypt, decrypt]
  by_cases h : m + k < N
  · rw [Nat.mod_eq_of_lt h]
    have hkn : k ≤ N := Nat.le_of_lt hk
    have : k + (N - k) = N := Nat.add_sub_cancel' hkn
    rw [this]
    rw [Nat.add_mod, Nat.mod_self, Nat.zero_add, Nat.mod_eq_of_lt hm]
  · have : (m + k) % N = m + k - N := by
      apply Nat.mod_eq_of_lt
      omega
    rw [this]
    have : (m + k - N) + (N - k) = m := by omega
    rw [this]
    exact Nat.mod_eq_of_lt hm

end Mcpe
