import Multiplicity.WordLove.Core
import Multiplicity.WordLove.Proofs
import Multiplicity.WordLove.Examples
import Multiplicity.WordLove.FFI

/-!
# Word Love Test Harness (ADR-0031)

Executable test runner verifying the complete Word Love formalization.
Run with `lake run word_love_test` (or `make word-love-test`).

## Verification Categories

1. **Positive Proofs (Gematria & Factorization)**:
   - Gematria values for אהבה (13), אחד (13), reduced אהבה (4), חסד (72), אמת (441), שלום (376), חיים (68).
   - Canonical prime factorizations and total multiplicity counts $\Omega(n)$ and $\omega(n)$.
2. **Orthogonality Invariants (ADR-0031 §4, ADR-022)**:
   - Standard and reduced Ahavah share `SemanticToken`, but possess distinct prime invariants ($\{13 \mapsto 1\} \neq \{2 \mapsto 2\}$).
   - Standard Ahavah and standard Echad have distinct `SemanticToken`s, but share prime invariant $\{13 \mapsto 1\}$.
3. **Retraction of Digital Root Collapse (ADR-022 in ADR-0031)**:
   - Verification that 13, 22, 31, 40, 49 possess distinct prime spectra yet collide under digital root 4.
4. **Substrate Exponent Additivity**:
   - Verification that $v_p(A + B) = v_p(A) + v_p(B)$ and $\Omega(A + B) = \Omega(A) + \Omega(B)$.
5. **No Double Counting Discipline**:
   - Event deduplication rejects duplicate event IDs while preserving arithmetic prime multiplicity.
6. **Multi-Token Pipelines**:
   - Love + Unity pipeline: $13^2$, $\Omega = 2$.
   - Divine Covenant Ensemble: $2^3 \cdot 3^4 \cdot 7^2 \cdot 13^1$, $\Omega = 10$.
-/

namespace Multiplicity.WordLove

open Multiplicity.WordLove
open Multiplicity.WordLove.Examples

/-! ### Decidable Boolean Checks Mirroring Proofs -/

/-- Check standard and reduced gematria values. -/
def check_gematria_values : Bool :=
  (stringGematria GematriaScheme.Standard "אהבה" == 13) &&
  (stringGematria GematriaScheme.Standard "אחד" == 13) &&
  (stringGematria GematriaScheme.Reduced "אהבה" == 4) &&
  (stringGematria GematriaScheme.Standard "חסד" == 72) &&
  (stringGematria GematriaScheme.Standard "אמת" == 441) &&
  (stringGematria GematriaScheme.Standard "שלום" == 376) &&
  (stringGematria GematriaScheme.Standard "חיים" == 68)

/-- Check prime factorizations for canonical values. -/
def check_prime_factorizations : Bool :=
  let f13 := factorize 13
  let f4  := factorize 4
  let f72 := factorize 72
  let f441 := factorize 441
  (f13.factors == [{ prime := 13, exponent := 1 }]) &&
  (f13.omega == 1 && f13.Omega == 1) &&
  (f4.factors == [{ prime := 2, exponent := 2 }]) &&
  (f4.omega == 1 && f4.Omega == 2) &&
  (f72.factors == [{ prime := 2, exponent := 3 }, { prime := 3, exponent := 2 }]) &&
  (f72.omega == 2 && f72.Omega == 5) &&
  (f441.factors == [{ prime := 3, exponent := 2 }, { prime := 7, exponent := 2 }]) &&
  (f441.omega == 2 && f441.Omega == 4)

/-- Check orthogonality between semantic and mathematical layers. -/
def check_orthogonality : Bool :=
  let tStd := Trajectory.ofEncoding encAhavahStd
  let tRed := Trajectory.ofEncoding encAhavahRed
  let tEch := Trajectory.ofEncoding encEchadStd
  -- 1. Same semantic token, distinct encodings and invariants
  (encAhavahStd.token.id == encAhavahRed.token.id) &&
  (encAhavahStd.value != encAhavahRed.value) &&
  (tStd.invariant != tRed.invariant) &&
  -- 2. Distinct semantic tokens, identical prime invariant
  (encAhavahStd.token.id != encEchadStd.token.id) &&
  (tStd.invariant == tEch.invariant)

/-- Check ADR-022 digital root entropy collapse counterexample. -/
def check_digital_root_collapse : Bool :=
  let testNums := [13, 22, 31, 40, 49]
  let allMod9Four := testNums.all (fun n => digitalRoot n == 4)
  let f13 := factorize 13
  let f22 := factorize 22
  let f31 := factorize 31
  let f40 := factorize 40
  let f49 := factorize 49
  let distinctPrimes :=
    f13 != f22 && f22 != f31 && f31 != f40 && f40 != f49
  allMod9Four && distinctPrimes

/-- Check exponent additivity in the substrate. -/
def check_exponent_additivity : Bool :=
  let a := PrimeMultiplicity.single 13 1
  let b := PrimeMultiplicity.single 13 1
  let sum := PrimeMultiplicity.add a b
  (sum.factors == [{ prime := 13, exponent := 2 }]) &&
  (sum.Omega == 2) &&
  (sum.valAt 13 == 2)

/-- Check no double counting discipline. -/
def check_no_double_counting : Bool :=
  let duplicateEvents := [
    { eventId := 101, token := tokenAhavah },
    { eventId := 101, token := tokenAhavah }
  ]
  let distinctEvents := [
    { eventId := 101, token := tokenAhavah },
    { eventId := 102, token := tokenAhavah }
  ]
  (countUniqueEvents duplicateEvents == 1) &&
  (countUniqueEvents distinctEvents == 2)

/-- Check aggregated multi-token pipelines. -/
def check_pipelines : Bool :=
  (pipelineLoveAndUnity.Omega == 2) &&
  (pipelineLoveAndGrace.Omega == 6) &&
  (pipelineDivineCovenant.Omega == 10) &&
  (pipelineHarmony.Omega == 8)

/-- Check PARM sealed state integration and multiset permutation invariance. -/
def check_parm_integration : Bool :=
  let tStd := Trajectory.ofEncoding encAhavahStd
  let tRed := Trajectory.ofEncoding encAhavahRed
  let tEch := Trajectory.ofEncoding encEchadStd
  let perm1 := canonicalSealedState [2, 2, 3, 3, 3]
  let perm2 := canonicalSealedState [3, 2, 3, 2, 3]
  let perm3 := canonicalSealedState [2, 3, 3, 3, 2]
  let perm4 := canonicalSealedState [3, 3, 3, 2, 2]
  (tStd.sealedState == 169) &&
  (tRed.sealedState == 24) &&
  (tEch.sealedState == 169) &&
  (tStd.sealedState != tRed.sealedState) &&
  (parmSealedState [13, 13] == 30758) &&
  -- Permutation Invariance: all permutations of 108-cycle factors map to 960
  (perm1 == 960 && perm2 == 960 && perm3 == 960 && perm4 == 960)

/-! ### Main Test Runner -/

/-- Run the Word Love test harness; returns 0 on success, 1 on failure. -/
def runTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "   Running Word Love Test Harness (ADR-0031)"
  IO.println "   Prime-Recursive Multiplicity Substrate Verification"
  IO.println "============================================================"
  IO.println ""

  let ok (name : String) (cond : Bool) : IO Bool := do
    if cond then
      IO.println s!"  ✓ {name}"
      pure true
    else
      IO.println s!"  ✗ {name}"
      pure false

  let mut pass : Bool := true

  -- 1. Gematria Verification
  pass := (← ok "WL-GEMATRIA-001: Hebrew gematria values (Ahavah=13, Echad=13, Reduced=4, Hesed=72, Emet=441, Shalom=376, Hayyim=68)" check_gematria_values) && pass

  -- 2. Factorization Verification
  pass := (← ok "WL-FACTOR-002: Prime factorization and multiplicity (13=>13^1 [Ω=1], 4=>2^2 [Ω=2], 72=>2^3*3^2 [Ω=5], 441=>3^2*7^2 [Ω=4])" check_prime_factorizations) && pass

  -- 3. Orthogonality Verification
  pass := (← ok "WL-ORTHOGONALITY-003: Orthogonality (SemanticEquiv != MathEquiv; Standard/Reduced distinct; Ahavah/Echad shared invariant)" check_orthogonality) && pass

  -- 4. ADR-022 Retraction Verification
  pass := (← ok "WL-RETRACTION-004: ADR-022 Digital Root collapse counterexamples (13, 22, 31, 40, 49 all map to 4, destroying prime entropy)" check_digital_root_collapse) && pass

  -- 5. Substrate Exponent Additivity
  pass := (← ok "WL-ADDITIVITY-005: Exponent additivity in substrate (vp(A + B) = vp(A) + vp(B), single 13 1 + single 13 1 = single 13 2)" check_exponent_additivity) && pass

  -- 6. No Double Counting Discipline
  pass := (← ok "WL-NODUP-006: No double counting (event deduplication count=1 while arithmetic prime multiplicity=2)" check_no_double_counting) && pass

  -- 7. Multi-Token Pipelines
  pass := (← ok "WL-PIPELINES-007: Composite pipelines (Love+Unity Ω=2, Love+Grace Ω=6, Covenant Ω=10, Harmony Ω=8)" check_pipelines) && pass

  -- 8. PARM Sealed State Integration
  pass := (← ok "WL-PARM-008: PARM sealed state integration (Ahavah Std=169, Red=24, Echad Std=169, Love+Unity=30758)" check_parm_integration) && pass

  -- 9. Zero-Knowledge Circuit Monotonicity Constraints
  let check_circuit : Bool :=
    (isMonotonicDescendingBool [3, 3, 3, 2, 2] == true) &&
    (isMonotonicDescendingBool [2, 2, 3, 3, 3] == false) &&
    (isMonotonicDescendingBool [3, 2, 3, 2, 3] == false) &&
    (adjacentDifferences [3, 3, 3, 2, 2] == [0, 0, 1, 0])
  pass := (← ok "WL-CIRCUIT-009: ZK Circuit Constraints (assert pi >= pi+1; rejects unsorted permutations; delta=[0,0,1,0])" check_circuit) && pass

  -- 10. Grand Product Equivalence and Origin Anchoring
  let check_grand_product : Bool :=
    (listProduct [13] == 13) &&
    (listProduct [2, 2] == 4) &&
    (listProduct [3, 3, 2, 2, 2] == 72) &&
    (listProduct [3, 3, 3, 2, 2] == 108) &&
    (runningProductStates [3, 3, 3, 2, 2] == [3, 9, 27, 54, 108]) &&
    (evaluateFullyConstrainedCircuit [3, 3, 3, 2, 2] 108 65536 == true) &&
    (evaluateFullyConstrainedCircuit [7, 5] 13 65536 == false) &&
    (evaluateFullyConstrainedCircuit [5, 5, 2, 2] 108 65536 == false)
  pass := (← ok "WL-ANCHOR-010: Grand Product Equivalence (prod pi = E_raw; rejects forged sorted primes [7,5] for Ahavah)" check_grand_product) && pass

  -- 11. In-Circuit Primality and Unit Exclusion Constraints
  let check_primality : Bool :=
    (isPrimeNat 2 == true) &&
    (isPrimeNat 3 == true) &&
    (isPrimeNat 13 == true) &&
    (isPrimeNat 12 == false) &&
    (isPrimeNat 9 == false) &&
    (isPrimeNat 54 == false) &&
    (isPrimeNat 1 == false) &&
    (evaluateFullyConstrainedCircuit [12, 9] 108 65536 == false) &&
    (evaluateFullyConstrainedCircuit [54, 2] 108 65536 == false) &&
    (evaluateFullyConstrainedCircuit [108, 1] 108 65536 == false) &&
    (evaluateFullyConstrainedCircuit [3, 3, 3, 2, 2, 1] 108 65536 == false) &&
    (evaluateFullyConstrainedCircuit [3, 3, 3, 2, 2] 108 65536 == true)
  pass := (← ok "WL-PRIME-011: Primality & Unit Exclusion (rejects composites [12,9], [54,2] and units [108,1], [3,3,3,2,2,1])" check_primality) && pass

  -- 12. Large-Prime Pratt Certificate Circuit Verification
  let check_large_primes : Bool :=
    (verifyPrattCertificate cert65537 == true) &&
    (verifyPrattCertificate cert131071 == true) &&
    (isHybridPrime 65537 (some cert65537) == true) &&
    (isHybridPrime 131071 (some cert131071) == true) &&
    (isHybridPrime 65535 none == false) &&
    (evaluateUnboundedCircuit [65537] [some cert65537] 65537 == true) &&
    (evaluateUnboundedCircuit [65537, 2] [some cert65537, none] (65537 * 2) == true)
  pass := (← ok "WL-LARGEPRIME-012: Large-Prime Pratt Certificates (authenticates Fermat prime 65537 and Mersenne prime 131071 > 2^16)" check_large_primes) && pass

  -- 13. Sedona Spine Rust Binding & Certified Coupling FFI
  let check_spine_ffi : Bool :=
    (FFI.wordloveParmSealedState108 0 == 960) &&
    (FFI.wordloveIsHybridPrimeFast 65537 == true) &&
    (FFI.wordloveIsHybridPrimeFast 131071 == true) &&
    (FFI.wordloveIsHybridPrimeFast 65535 == false) &&
    -- Certified coupling with full trust (1024): identical orbitals p=n=13 => sep=0, att=1024, gamma = 1024
    (FFI.wordloveGammaCertified 13 13 1024 == 1024) &&
    -- Inadmissible orbital (composite 12): collapses to 0
    (FFI.wordloveGammaCertified 12 13 1024 == 0) &&
    -- Large prime orbital 65537: valid certified coupling
    (FFI.wordloveGammaCertified 65537 65537 1024 == 1024)
  pass := (← ok "WL-SPINE-013: Sedona Spine FFI & Certified Coupling (p=n=13 => 1024, composite 12 => 0, large prime 65537 => 1024)" check_spine_ffi) && pass

  IO.println ""
  IO.println s!"  [Diagnostics] Ahavah Standard Trajectory: {trajAhavahStd}"
  IO.println s!"  [Diagnostics] Ahavah Reduced Trajectory:  {trajAhavahRed}"
  IO.println s!"  [Diagnostics] Echad Standard Trajectory:  {trajEchadStd}"
  IO.println s!"  [Diagnostics] Love + Unity Pipeline:     {pipelineLoveAndUnity} (Ω = {pipelineLoveAndUnity.Omega})"
  IO.println s!"  [Diagnostics] Divine Covenant Pipeline:  {pipelineDivineCovenant} (Ω = {pipelineDivineCovenant.Omega})"
  IO.println ""
  IO.println "  Kernel-Checked Proofs at import time (no -- TODO: replace sorry, no admit, no axiom):"
  IO.println "    - ahavah_standard_gematria       : stringGematria Standard \"אהבה\" = 13"
  IO.println "    - echad_standard_gematria        : stringGematria Standard \"אחד\" = 13"
  IO.println "    - ahavah_standard_factors        : factorize 13 = {13 ↦ 1}"
  IO.println "    - same_semantic_token_ahavah     : encAhavahStd.token = encAhavahRed.token"
  IO.println "    - trajectories_distinct_ahavah   : trajAhavahStd.invariant ≠ trajAhavahRed.invariant"
  IO.println "    - shared_invariant_ahavah_echad  : trajAhavahStd.invariant = trajEchadStd.invariant"
  IO.println "    - digital_root_entropy_collapse  : Mod 9 collapses distinct prime spectra"
  IO.println "    - multiplicity_vs_double_counting: Multiplicity 2 ≠ event duplication"
  IO.println "    - universal_parm_invariance      : ∀ L₁ L₂ : List ℕ, L₁ ~ L₂ → canonicalSealedState L₁ = canonicalSealedState L₂"
  IO.println "    - circuit_monotonicity_constraint: isMonotonicDescendingBool [3,3,3,2,2]=true ∧ [2,2,3,3,3]=false"
  IO.println "    - grand_product_origin_anchoring : listProduct [3,3,3,2,2]=108 ∧ [7,5]≠13 rejected"
  IO.println "    - primality_unit_exclusion_check : composite [12,9] and unit [108,1] rejected"
  IO.println "    - pratt_large_prime_verification : 65537 and 131071 verified via Pratt certificates"
  IO.println "    - sedona_spine_certified_coupling: γ_certified(13,13)=1024, γ_certified(12,13)=0"
  IO.println ""

  if pass then
    IO.println "============================================================"
    IO.println "  ALL WORD LOVE (ADR-0031) VERIFICATION TESTS PASSED (0 FAILURES)"
    IO.println "============================================================"
    return 0
  else
    IO.println "============================================================"
    IO.println "  WORD LOVE TEST FAILURES DETECTED"
    IO.println "============================================================"
    return 1

end Multiplicity.WordLove

/-- Root entry point (Lake `lean_exe word_love_test` links `_root_.main`). -/
def main : IO UInt32 := Multiplicity.WordLove.runTests
