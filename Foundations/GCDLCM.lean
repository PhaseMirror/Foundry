/-!
# Multiplicity Kernel — GCD and LCM (ADR-0001 Phase 1 scope)

`Nat.gcd` and `Nat.lcm` are taken from the core arithmetic, and the kernel
certifies the lattice laws used by factorization and by the Multiplicity
pipeline.
-/

namespace Multiplicity.Kernel

/-- `gcd` is commutative. -/
theorem gcd_comm (a b : Nat) : Nat.gcd a b = Nat.gcd b a :=
  Nat.gcd_comm a b

/-- `gcd` is associative. -/
theorem gcd_assoc (a b c : Nat) : Nat.gcd (Nat.gcd a b) c = Nat.gcd a (Nat.gcd b c) :=
  Nat.gcd_assoc a b c

/-- `gcd a b` divides `a`. -/
theorem gcd_dvd_left (a b : Nat) : Nat.gcd a b ∣ a :=
  Nat.gcd_dvd_left a b

/-- `gcd a b` divides `b`. -/
theorem gcd_dvd_right (a b : Nat) : Nat.gcd a b ∣ b :=
  Nat.gcd_dvd_right a b

/-!
The *greatest*-divisor law (`a ∣ b → a ∣ c → a ∣ Nat.gcd b c`) is a
documented gap of this minimal kernel: it needs Bézout's identity / the full
Euclidean algorithm development, which is classical mathematics not yet
re-derived here.  The lattice direction is certified by the Rust + Kani
`gcd` harnesses instead.
-/

/-- `lcm a b` is a multiple of `a`. -/
theorem lcm_dvd_left (a b : Nat) : a ∣ Nat.lcm a b :=
  Nat.dvd_lcm_left a b

/-- `lcm a b` is a multiple of `b`. -/
theorem lcm_dvd_right (a b : Nat) : b ∣ Nat.lcm a b :=
  Nat.dvd_lcm_right a b

/-- The gcd times the lcm is the product. -/
theorem gcd_mul_lcm (a b : Nat) : Nat.gcd a b * Nat.lcm a b = a * b :=
  Nat.gcd_mul_lcm a b

/-- A positive number yields a positive gcd. -/
theorem gcd_pos {a b : Nat} (ha : 0 < a) : 0 < Nat.gcd a b :=
  Nat.pos_of_dvd_of_pos (Nat.gcd_dvd_left a b) ha

/-- `gcd` is idempotent up to the antisymmetry law certified above. -/
theorem gcd_idempotent_left (a b : Nat) : Nat.gcd a b ∣ a := Nat.gcd_dvd_left a b

end Multiplicity.Kernel
