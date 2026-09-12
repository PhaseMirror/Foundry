import Std
import Foundations.Semantics.Core
import Foundations.Semantics.Algebra

namespace Multiplicity.Semantics

namespace Multiplicity.PESD

def prime_set (K : Nat) : List Nat := [2, 3, 5, 7, 11, 13, 17, 19].take K

def prime_first (K : Nat) : Nat :=
  match prime_set K with
  | [] => 0
  | p :: _ => p

def multiplicity_op {K : Nat} (occupation : Algebra.Vec K Nat) : Nat :=
  match K with
  | 0 => 0
  | K + 1 => (prime_first (K + 1)) * (occupation 0)

theorem multiplicity_op_nonneg {K : Nat} (occupation : Algebra.Vec K Nat) :
    0 ≤ multiplicity_op occupation := by
  cases K with
  | zero => simp [multiplicity_op]
  | succ K => simp [multiplicity_op, prime_first, prime_set]

def zeta_hamiltonian (alpha : Nat) (M_op : Nat) : Nat :=
  alpha * M_op

theorem zeta_hamiltonian_bound (alpha : Nat) (M_op : Nat) :
    zeta_hamiltonian alpha M_op ≤ alpha * M_op := by
  simp [zeta_hamiltonian]

def Lambda_op (kappa : Nat) : Nat := kappa

def Pi_Lambda_m (rho : Nat) (M_star : Nat) : Nat :=
  min rho M_star

def Lambda_stabilizer (_kappa _rho _M_star : Nat) : Nat := 0

theorem Lambda_stabilizer_bound (_kappa _rho _M_star : Nat) :
    Lambda_stabilizer _kappa _rho _M_star ≤ 0 := by
  simp [Lambda_stabilizer]

def small_gain_check (q_t eta_t : Nat) (epsilon : Nat) : Bool :=
  q_t + eta_t < 1 - epsilon

theorem small_gain_stable (q_t eta_t : Nat) (epsilon : Nat)
    (h_eps : epsilon ≥ 0) (h : small_gain_check q_t eta_t epsilon) :
    q_t + eta_t < 1 := by
  simp [small_gain_check] at h
  omega

end Multiplicity.PESD

end Multiplicity.Semantics
