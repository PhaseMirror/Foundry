import Lean

/-!
# ADR-0036: Satyendra Nath Bose Multiplicity Core

Formal Lean 4 implementation of Bose Multiplicity and Bose-Einstein
Arithmetic Statistics (ADR-0036, docs/ADR-0036-Satyendra Nath BOse.md).

## Conceptual Spine

1. **Shift in Multiplicity**:
   From *identity of distinguishable constituents* $(A_1, B_2) \neq (A_2, B_1)$
   to *multiplicity of occupancy* $(n_1, n_2, \dots, n_g)$.

2. **The Bose-Prime Correspondence**:
   Assign a distinct prime $p_i$ to each one-particle mode $i$.
   An occupation vector $\mathbf{n} = (n_1, \dots, n_g)$ is uniquely mapped
   to the integer:
   $$\mathcal{P}(\mathbf{n}) = \prod_{i=1}^g p_i^{n_i}$$

3. **Arithmetic Invariants**:
   - Total Boson Number: $N = \Omega(\mathcal{P}(\mathbf{n})) = \sum_i n_i$.
   - Occupied Modes Count: $\omega(\mathcal{P}(\mathbf{n})) = |\{i : n_i > 0\}|$.
   - Condensation Order Parameter: $C(\mathbf{n}) = \frac{\max_i n_i}{N}$.
   - Occupancy Fragmentation Index: $F(\mathbf{n}) = \frac{\omega(\mathbf{n})}{N}$.

4. **Multiplicity Counting Comparison**:
   - Maxwell-Boltzmann: $\Omega_{\mathrm{MB}}(N, g) = g^N$
   - Fermi-Dirac: $\Omega_{\mathrm{FD}}(N, g) = \binom{g}{N}$
   - Bose-Einstein: $\Omega_{\mathrm{BE}}(N, g) = \binom{N+g-1}{N}$

This module is **100% axiom-clean, zero-sorry, and zero-Mathlib**.
-/

namespace Multiplicity.Bose

/-! ## Registry Attributes -/

initialize boseAdrAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `bose_adr "Bose ADR registry tag (ADR-0036)" (fun _ => pure ())

initialize boseProofAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `bose_proof "Bose theorem tag (ADR-0036)" (fun _ => pure ())

/-! ## 1. Mode and Occupation Types -/

/-- Mode index representing a 1-particle quantum state (1-indexed). -/
abbrev ModeIdx := Nat

/-- Occupation vector representing $(n_1, n_2, \dots, n_g) \in \mathbb{N}_0^g$. -/
abbrev OccupationVector := List Nat

/-- Total number of bosons in a given occupation configuration: $N = \sum_i n_i$. -/
def totalBosons (occ : OccupationVector) : Nat :=
  occ.foldl (· + ·) 0

/-- Number of occupied modes: $\omega(\mathbf{n}) = |\{i : n_i > 0\}|$. -/
def occupiedModesCount (occ : OccupationVector) : Nat :=
  (occ.filter (fun n => n > 0)).length

/-- Maximum single-mode occupancy: $\max_i n_i$. -/
def maxOccupation (occ : OccupationVector) : Nat :=
  occ.foldl Nat.max 0

/-! ## 2. Prime Basis and Arithmetic Encoding -/

/-- Standard canonical prime basis for the first $g$ modes. -/
def canonicalPrimes : List Nat :=
  [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

/-- Get the prime assigned to mode index $i$ (1-indexed). -/
def modePrime (i : ModeIdx) : Nat :=
  let rec nth (l : List Nat) (idx : Nat) : Nat :=
    match l, idx with
    | [], _ => 2
    | p :: _, 0 => p
    | _ :: rest, k + 1 => nth rest k
  if i == 0 then 2 else nth canonicalPrimes (i - 1)

/-- Canonical prime encoding of an occupation vector: $\Phi(\mathbf{n}) = \prod_i p_i^{n_i}$. -/
def encodeBoseState (occ : OccupationVector) (primes : List Nat := canonicalPrimes) : Nat :=
  let rec loop (os ps : List Nat) (acc : Nat) : Nat :=
    match os, ps with
    | [], _ => acc
    | _, [] => acc
    | n :: nrest, p :: prest =>
      loop nrest prest (acc * (p ^ n))
  loop occ primes 1

/-- Compute $p$-adic valuation $v_p(n)$: the exact exponent of prime $p$ dividing $n$. -/
def primeValuation (p : Nat) (n : Nat) : Nat :=
  if p < 2 || n == 0 then 0
  else
    let rec count (val fuel : Nat) : Nat :=
      match fuel with
      | 0 => 0
      | f + 1 =>
        if val % p == 0 then 1 + count (val / p) f
        else 0
    count n (n + 1)

/-- Canonical decoding (valuation extraction) $\Psi(m) = (v_{p_1}(m), \dots, v_{p_g}(m))$. -/
def decodeBoseState (m : Nat) (g : Nat) (primes : List Nat := canonicalPrimes) : OccupationVector :=
  (primes.take g).map (fun p => primeValuation p m)

/-- Compute Big-Omega $\Omega(n)$: total prime factors counted with multiplicity.
    For $n = \prod p_i^{n_i}$, $\Omega(n) = \sum n_i$. -/
def bigOmegaOfEncoded (occ : OccupationVector) : Nat :=
  totalBosons occ

/-- Compute Little-Omega $\omega(n)$: number of distinct prime factors dividing $n$.
    For $n = \prod p_i^{n_i}$, $\omega(n) = |\{i : n_i > 0\}|$. -/
def littleOmegaOfEncoded (occ : OccupationVector) : Nat :=
  occupiedModesCount occ

/-! ## 3. Bose Multiplicity Counts and Combinatorics -/

/-- Binomial coefficient $\binom{n}{k}$ with structural recursion on $n$. -/
def choose : Nat → Nat → Nat
  | _, 0 => 1
  | 0, _ + 1 => 0
  | n + 1, k + 1 => choose n k + choose n (k + 1)

/-- Bose-Einstein multiplicity (Stars-and-Bars):
    $$\Omega_{\mathrm{BE}}(N, g) = \binom{N+g-1}{N} = \binom{N+g-1}{g-1}$$ -/
def boseMultiplicity (N g : Nat) : Nat :=
  if g == 0 then (if N == 0 then 1 else 0)
  else choose (N + g - 1) N

/-- Maxwell-Boltzmann multiplicity (Distinguishable particles):
    $$\Omega_{\mathrm{MB}}(N, g) = g^N$$ -/
def maxwellBoltzmannMultiplicity (N g : Nat) : Nat :=
  g ^ N

/-- Fermi-Dirac multiplicity (Pauli exclusion $n_i \in \{0, 1\}$):
    $$\Omega_{\mathrm{FD}}(N, g) = \binom{g}{N}$$ -/
def fermiDiracMultiplicity (N g : Nat) : Nat :=
  choose g N

/-! ## 4. Energy and Logarithmic Spectrum -/

/-- Total energy under an arbitrary discrete one-particle energy spectrum $\epsilon_i$:
    $$E(\mathbf{n}) = \sum_i n_i \epsilon_i$$ -/
def discreteEnergy (occ : OccupationVector) (epsilons : List Nat) : Nat :=
  let rec loop (os es : List Nat) (acc : Nat) : Nat :=
    match os, es with
    | [], _ => acc
    | _, [] => acc
    | n :: nrest, e :: erest => loop nrest erest (acc + n * e)
  loop occ epsilons 0

/-- Logarithmic prime energy: when $\epsilon_i = \ln(p_i)$,
    $$E_{\log}(\mathbf{n}) = \sum n_i \ln(p_i) = \ln(\mathcal{P}(\mathbf{n}))$$ -/
def logPrimeEnergyFloat (occ : OccupationVector) (primes : List Nat := canonicalPrimes) : Float :=
  let rec loop (os ps : List Nat) (acc : Float) : Float :=
    match os, ps with
    | [], _ => acc
    | _, [] => acc
    | n :: nrest, p :: prest =>
      loop nrest prest (acc + (Float.ofNat n) * (Float.log (Float.ofNat p)))
  loop occ primes 0.0

/-! ## 5. Condensation (C) and Fragmentation (F) Invariants -/

/-- Arithmetic condensation statistic $C(\mathbf{n}) = \frac{\max_i n_i}{N}$.
    Returns rational `(max_n, N)`. -/
def condensationRatio (occ : OccupationVector) : Nat × Nat :=
  (maxOccupation occ, totalBosons occ)

/-- Float value of the condensation order parameter $C(\mathbf{n}) \in [0, 1]$. -/
def condensationFloat (occ : OccupationVector) : Float :=
  let (m, N) := condensationRatio occ
  if N == 0 then 0.0
  else Float.ofNat m / Float.ofNat N

/-- Arithmetic occupancy fragmentation index $F(\mathbf{n}) = \frac{\omega(\mathbf{n})}{N}$.
    Returns rational `(occupied_modes, N)`. -/
def fragmentationRatio (occ : OccupationVector) : Nat × Nat :=
  (occupiedModesCount occ, totalBosons occ)

/-- Float value of the fragmentation index $F(\mathbf{n}) \in [0, 1]$. -/
def fragmentationFloat (occ : OccupationVector) : Float :=
  let (w, N) := fragmentationRatio occ
  if N == 0 then 0.0
  else Float.ofNat w / Float.ofNat N

/-- Predicate for a completely condensed state: all $N$ bosons occupy exactly one mode ($C=1, F=1/N$). -/
def isCompleteCondensate (occ : OccupationVector) : Bool :=
  let (m, N) := condensationRatio occ
  N > 0 && m == N

/-! ## 6. Finite-Mode Euler Product (ADR-0037 Interface) -/

/-- Single Euler factor: $(1 - p^{-\beta})^{-1}$ for finite mode calculation. -/
def bosePartitionEulerFactor (p : Nat) (beta : Float) : Float :=
  1.0 / (1.0 - (Float.pow (Float.ofNat p) (-beta)))

/-- Finite-mode bosonic partition function:
    $$Z_g(\beta) = \prod_{i=1}^g \frac{1}{1 - p_i^{-\beta}}$$ -/
def finiteBosePartition (primes : List Nat) (beta : Float) : Float :=
  primes.foldl (fun acc p => acc * bosePartitionEulerFactor p beta) 1.0

/-! ## 7. State Space Enumeration -/

/-- Recursively enumerate all occupation vectors of $N$ bosons across $g$ modes:
    $\{\mathbf{n} \in \mathbb{N}_0^g : \sum n_i = N\}$. -/
def enumerateBoseStates (N : Nat) : (g : Nat) → List OccupationVector
  | 0 => if N == 0 then [[]] else []
  | 1 => [[N]]
  | g + 1 =>
    (List.range (N + 1)).foldl (fun acc k =>
      acc ++ (enumerateBoseStates (N - k) g).map (fun sub => k :: sub)
    ) []

/-- Full structured record of a Bose-Multiplicity state with $(C, F)$ coordinates. -/
structure BoseStateRecord where
  modesCount       : Nat
  totalParticles   : Nat
  occupations      : OccupationVector
  primeSignature   : Nat
  bigOmega         : Nat
  littleOmega      : Nat
  maxOcc           : Nat
  condensation     : Nat × Nat
  fragmentation    : Nat × Nat
  isCondensate     : Bool
  deriving Repr, BEq, Inhabited

/-- Construct a full `BoseStateRecord` from an occupation vector. -/
def makeBoseRecord (occ : OccupationVector) (primes : List Nat := canonicalPrimes) : BoseStateRecord :=
  let sig := encodeBoseState occ primes
  let N := totalBosons occ
  let maxO := maxOccupation occ
  let cRatio := condensationRatio occ
  let fRatio := fragmentationRatio occ
  {
    modesCount     := occ.length
    totalParticles := N
    occupations    := occ
    primeSignature := sig
    bigOmega       := bigOmegaOfEncoded occ
    littleOmega    := littleOmegaOfEncoded occ
    maxOcc         := maxO
    condensation   := cRatio
    fragmentation  := fRatio
    isCondensate   := (N > 0 && maxO == N)
  }

end Multiplicity.Bose
