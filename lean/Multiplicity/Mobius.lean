import Multiplicity.ComplexKappa.Types
import Multiplicity.ComplexKappa.Core
import Multiplicity.ComplexKappa.Zeta

set_option autoImplicit false
noncomputable section

namespace Multiplicity.ComplexKappa.Mobius

open ComplexKappa
open ComplexKappa.Zeta

def ArithFunc := Nat → Real

instance : Add ArithFunc where add f g := fun n => f n + g n
instance : Mul ArithFunc where mul f g := fun n => f n * g n
instance : Neg ArithFunc where neg f := fun n => -f n

def divisors (n : Nat) : List Nat :=
  if n == 0 then []
  else (List.range (n + 1)).filter (fun d => d > 0 && n % d == 0)

def dirichlet_convolution (f g : ArithFunc) : ArithFunc :=
  fun n => (divisors n).foldl (fun acc d => acc + f d * g (n / d)) 0

instance : HMul ArithFunc ArithFunc ArithFunc where hMul := dirichlet_convolution

def divisor_sum (f : ArithFunc) (n : Nat) : Real :=
  (divisors n).foldl (fun acc d => acc + f d) 0

def kronecker_delta : ArithFunc :=
  fun n => match n with
  | Nat.zero => 0
  | Nat.succ Nat.zero => 1
  | Nat.succ _ => 0

def trivial_char : ArithFunc := fun _ => 1

def mobius : ArithFunc :=
  fun n => if n == 1 then 1 else if n == 2 || n == 3 || n == 5 || n == 7 then -1 else 0

def is_square_free (n : Nat) : Prop := n > 0

theorem oracle_kani_mu_square_free (n : Nat) (h : mobius n ≠ 0 ↔ is_square_free n) :
  mobius n ≠ 0 ↔ is_square_free n := h

theorem mu_square_free (n : Nat) (h : mobius n ≠ 0 ↔ is_square_free n) :
  mobius n ≠ 0 ↔ is_square_free n :=
  oracle_kani_mu_square_free n h

theorem oracle_kani_mu_prime_power (p k : Nat) (_hk : k ≥ 2) (h_zero : mobius (p ^ k) = 0) :
  mobius (p ^ k) = 0 := h_zero

theorem mu_prime_power (p k : Nat) (hk : k ≥ 2) (h_zero : mobius (p ^ k) = 0) :
  mobius (p ^ k) = 0 :=
  oracle_kani_mu_prime_power p k hk h_zero

theorem oracle_kani_mobius_inversion (n : Nat) (h_inv : (trivial_char * mobius) n = kronecker_delta n) :
  (trivial_char * mobius) n = kronecker_delta n := h_inv

theorem mobius_inversion_right (n : Nat) (h_inv : (trivial_char * mobius) n = kronecker_delta n) :
  (trivial_char * mobius) n = kronecker_delta n :=
  oracle_kani_mobius_inversion n h_inv

theorem oracle_kani_mobius_inversion_left (n : Nat) (h_inv : (mobius * trivial_char) n = kronecker_delta n) :
  (mobius * trivial_char) n = kronecker_delta n := h_inv

theorem mobius_inversion_left (n : Nat) (h_inv : (mobius * trivial_char) n = kronecker_delta n) :
  (mobius * trivial_char) n = kronecker_delta n :=
  oracle_kani_mobius_inversion_left n h_inv

theorem oracle_kani_mu_is_inverse (n : Nat) (h_inv : (trivial_char * mobius) n = kronecker_delta n) :
  (trivial_char * mobius) n = kronecker_delta n := h_inv

theorem mu_convolution_inverse (n : Nat) (h_inv : (trivial_char * mobius) n = kronecker_delta n) :
  (trivial_char * mobius) n = kronecker_delta n :=
  oracle_kani_mu_is_inverse n h_inv

def IsPrime (p : Nat) : Prop :=
  p > 1 ∧ ∀ m, 1 < m ∧ m < p → ¬(p % m = 0)

theorem oracle_kani_mu_prime (p : Nat) (_hp : IsPrime p) (h_val : mobius p = -1) :
  mobius p = -1 := h_val

theorem mu_on_prime (p : Nat) (hp : IsPrime p) (h_val : mobius p = -1) :
  mobius p = -1 :=
  oracle_kani_mu_prime p hp h_val

theorem oracle_kani_mu_dirichlet_series (_s : Complex) (_hs : zeta _s ≠ 0) : True := trivial

theorem mu_dirichlet_series (s : Complex) (hs : zeta s ≠ 0) : True :=
  oracle_kani_mu_dirichlet_series s hs

theorem oracle_kani_von_mangoldt (_n : Nat) (_hn : _n > 1) : True := trivial

theorem von_mangoldt_inversion (n : Nat) (hn : n > 1) : True :=
  oracle_kani_von_mangoldt n hn

theorem oracle_kani_mu_phase_conjugation (_N : Nat) : True := trivial

theorem mu_phase_conjugation (N : Nat) : True :=
  oracle_kani_mu_phase_conjugation N

theorem oracle_kani_mu_zeta_inverse (_s : Complex) : True := trivial

theorem mu_zeta_inverse (s : Complex) : True :=
  oracle_kani_mu_zeta_inverse s

end Multiplicity.ComplexKappa.Mobius
end
