import Foundations.WordLove.Core
import Foundations.WordLove.Fixtures

/-!
# Word Love FFI — Lean 4 Side (ADR-0031 §4)

Exported C ABI symbols callable from Rust and external environments via FFI.
Provides verified runtime evaluation of gematria, prime factor multiplicity,
orthogonality checks, and pipeline validation.
-/

set_option compiler.ignoreBorrowAnnotation true

namespace Foundations.WordLove.FFI

open Foundations.WordLove

/-- `wordlove_gematria_standard_ffi`: compute standard gematria for a Hebrew string. -/
@[export wordlove_gematria_standard_ffi]
def wordloveGematriaStandard (s : String) : UInt32 :=
  (stringGematria GematriaScheme.Standard s).toUInt32

/-- `wordlove_gematria_reduced_ffi`: compute reduced gematria for a Hebrew string. -/
@[export wordlove_gematria_reduced_ffi]
def wordloveGematriaReduced (s : String) : UInt32 :=
  (stringGematria GematriaScheme.Reduced s).toUInt32

/-- `wordlove_prime_omega_ffi`: compute distinct prime count ω(n). -/
@[export wordlove_prime_omega_ffi]
def wordlovePrimeOmega (n : UInt32) : UInt32 :=
  (factorize n.toNat).omega.toUInt32

/-- `wordlove_prime_Omega_ffi`: compute total prime multiplicity Ω(n). -/
@[export wordlove_prime_Omega_ffi]
def wordlovePrimeOmegaTotal (n : UInt32) : UInt32 :=
  (factorize n.toNat).Omega.toUInt32

/-- `wordlove_is_prime_ffi`: check if n is prime. -/
@[export wordlove_is_prime_ffi]
def wordloveIsPrime (n : UInt32) : Bool :=
  let pm := factorize n.toNat
  pm.omega == 1 && pm.Omega == 1

/-- `wordlove_verify_orthogonality_ffi`: runtime verification of the orthogonality invariant. -/
@[export wordlove_verify_orthogonality_ffi]
def wordloveVerifyOrthogonality (_ : UInt32) : Bool :=
  let tStd := Trajectory.ofEncoding encAhavahStd
  let tRed := Trajectory.ofEncoding encAhavahRed
  let tEch := Trajectory.ofEncoding encEchadStd
  -- Same token, distinct invariants
  (encAhavahStd.token.id == encAhavahRed.token.id) &&
  (tStd.invariant != tRed.invariant) &&
  -- Distinct tokens, shared invariant
  (encAhavahStd.token.id != encEchadStd.token.id) &&
  (tStd.invariant == tEch.invariant)

/-- `wordlove_verify_ahavah_echad_ffi`: runtime check that Ahavah and Echad both evaluate to 13. -/
@[export wordlove_verify_ahavah_echad_ffi]
def wordloveVerifyAhavahEchad (_ : UInt32) : Bool :=
  (stringGematria GematriaScheme.Standard "אהבה" == 13) &&
  (stringGematria GematriaScheme.Standard "אחד" == 13)

/-- `wordlove_parm_sealed_state_108_ffi`: compute canonical PARM sealed root for the 108-cycle. -/
@[export wordlove_parm_sealed_state_108_ffi]
def wordloveParmSealedState108 (_ : UInt32) : UInt64 :=
  (parmSealedState [3, 3, 3, 2, 2]).toUInt64

/-- `wordlove_is_hybrid_prime_fast_ffi`: check Tier-1 or known large prime primality. -/
@[export wordlove_is_hybrid_prime_fast_ffi]
def wordloveIsHybridPrimeFast (n : UInt64) : Bool :=
  if n.toNat <= 65536 then
    isPrimeNat n.toNat
  else if n.toNat == 65537 then
    verifyPrattCertificate cert65537
  else if n.toNat == 131071 then
    verifyPrattCertificate cert131071
  else
    false

/-- Normalized prime coupling with fixed-point scale N = 1024.
    Decays with index separation $|p - n|$:
    decay(0)=1024, decay(1)=376, decay(2)=138, decay(3)=50, decay(4)=18, decay(5)=6, decay(6)=2, decay(d>=7)=0. -/
def careDecay : Nat → Nat
  | 0 => 1024 | 1 => 376 | 2 => 138 | 3 => 50
  | 4 => 18 | 5 => 6 | 6 => 2 | _ => 0

/-- Certified coupling $\gamma_{pn}$ in fixed-point scale 1024.
    Collapses to 0 if either orbital fails hybrid primality. -/
def gammaCertified (p n trust : Nat) (certP certN : Option PrattCertificate := none) : Nat :=
  if !isHybridPrime p certP || !isHybridPrime n certN then
    0
  else
    let minVal := if p < n then p else n
    let maxVal := if p < n then n else p
    if maxVal == 0 then 0
    else
      let sep := if p >= n then p - n else n - p
      let att := careDecay sep
      -- gamma = (min / max) * decay(sep) * trust / 1024
      (minVal * att * trust) / (maxVal * 1024)

/-- `wordlove_gamma_certified_ffi`: C-ABI export for certified coupling. -/
@[export wordlove_gamma_certified_ffi]
def wordloveGammaCertified (p n trust : UInt32) : UInt32 :=
  let certP := if p.toNat == 65537 then some cert65537 else if p.toNat == 131071 then some cert131071 else none
  let certN := if n.toNat == 65537 then some cert65537 else if n.toNat == 131071 then some cert131071 else none
  (gammaCertified p.toNat n.toNat trust.toNat certP certN).toUInt32

/-- C-ABI Export Record for Sedona Spine Binding. -/
structure SedonaSpineExport where
  gematria_std     : String → UInt32
  prime_omega      : UInt32 → UInt32
  prime_Omega      : UInt32 → UInt32
  hybrid_prime     : UInt64 → Bool
  sealed_root_108  : UInt32 → UInt64
  gamma_certified  : UInt32 → UInt32 → UInt32 → UInt32

/-- Global Sedona Spine C-ABI Export Instance. -/
def spineExportInstance : SedonaSpineExport :=
  { gematria_std    := wordloveGematriaStandard
  , prime_omega     := wordlovePrimeOmega
  , prime_Omega     := wordlovePrimeOmegaTotal
  , hybrid_prime    := wordloveIsHybridPrimeFast
  , sealed_root_108 := wordloveParmSealedState108
  , gamma_certified := wordloveGammaCertified }

end Foundations.WordLove.FFI
