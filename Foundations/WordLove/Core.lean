import Lean

/-!
# Word Love Core (ADR-0031)

Formal core of the Word Love specification within the Prime-Recursive
Multiplicity Substrate (ADR-0031, Decision ID `ADR-WORDLOVE-001`,
`docs/ADR-0031-Word-Love.md`).

## Architecture & Foundational Invariants

This module formalizes the three distinct structural layers:
1. **Semantic Layer (`SemanticToken`)**:
   Represents semantic objects (e.g., אַהֲבָה / Ahavah / Love, אֶחָד / Echad / One).
2. **Encoding Layer (`Encoding`)**:
   Maps semantic tokens to positive natural numbers under explicitly declared
   gematria schemes (Standard / Mispar Hechrechi, Reduced / Mispar Katan, Ordinal / Mispar Siduri).
3. **Mathematical Substrate Layer (`PrimeMultiplicity`, `Trajectory`)**:
   Prime-factor multiplicity representation $M(n, p) = v_p(n)$, tracking finite prime
   support, prime count $\omega(n)$, and total multiplicity $\Omega(n)$.

## Key Decisions Formalized

- **Separation of Dimensions (ADR-0031 §1, §4)**:
  `Love` is not a raw natural number 13. 13 is an invariant of a specific encoding
  of the token `אהבה`.
- **Orthogonality of Semantic and Mathematical Equivalence (ADR-0031 §4, ADR-022)**:
  Semantic identity does not imply prime-factor identity ($\approx_{sem} \;\not\implies\; \equiv_{math}$),
  and prime-factor identity does not imply semantic identity ($\equiv_{math} \;\not\implies\; \approx_{sem}$).
- **Retraction of Digital-Root Normalization (ADR-022 in ADR-0031)**:
  Digital root modulo 9 reduces the infinite prime support space to 9 states, collapsing
  distinct prime factorizations (e.g. 13, 22, 31, 40, 49) and destroying global entropy.
  Standard and reduced gematria exist as mathematically distinct trajectories.
- **Multiplicity is Not Double Counting (ADR-0031 §3, §6)**:
  Canonical prime exponents represent genuine algebraic multiplicity ($p^k$),
  while "no double counting" is enforced by unique occurrence set inclusion.

## Conventions

Core Lean 4 only — no mathlib dependency. All definitions are computable.
Tags `@[wordlove_adr]` and `@[wordlove_proof]` mark formal artifacts and theorems.
-/

namespace Multiplicity.WordLove

/-! ### Project Tag Attributes

The `@[wordlove_adr]` / `@[wordlove_proof]` tag attributes live in
`Multiplicity.WordLove.Attrs` so this module stays free of `initialize`
blocks (required for the Rust-loaded export closure; see Attrs.lean).
-/

/-! ### 1. Semantic Layer -/

/-- A semantic token representing a concept or word in language.
    Carries canonical identifiers, source script, transliteration, and description. -/
structure SemanticToken where
  id              : String
  name            : String
  hebrew          : String
  transliteration : String
  description     : String
  deriving Repr, BEq, DecidableEq, Inhabited

instance : ToString SemanticToken := ⟨fun t =>
  s!"SemanticToken({t.id}, {t.hebrew} [{t.transliteration}] = \"{t.name}\")"⟩

/-- Semantic equivalence: two tokens are semantically equivalent iff their IDs match. -/
def SemanticEquiv (t1 t2 : SemanticToken) : Prop :=
  t1.id = t2.id

instance (t1 t2 : SemanticToken) : Decidable (SemanticEquiv t1 t2) :=
  inferInstanceAs (Decidable (t1.id = t2.id))

/-! ### 2. Gematria Schemes & Alphabet Tables -/

/-- Admissible numerical encoding schemes for Hebrew tokens. -/
inductive GematriaScheme where
  | Standard -- Mispar Hechrechi / Ragil (Alef=1, ..., Yod=10, ..., Qoph=100, ..., Tav=400)
  | Reduced  -- Mispar Katan (modulo 9 digit-reduction: Alef=1, ..., Yod=1, ..., Qoph=1, ..., Tav=4)
  | Ordinal  -- Mispar Siduri (alphabetical order index 1..22)
  deriving Repr, BEq, DecidableEq, Inhabited

instance : ToString GematriaScheme := ⟨fun s => match s with
  | GematriaScheme.Standard => "Standard"
  | GematriaScheme.Reduced  => "Reduced"
  | GematriaScheme.Ordinal  => "Ordinal"
  ⟩

/-- Compute the gematria value of a single character under a given scheme. -/
def charGematria (scheme : GematriaScheme) (c : Char) : Nat :=
  match scheme with
  | GematriaScheme.Standard =>
    match c with
    | 'א' => 1   | 'ב' => 2   | 'ג' => 3   | 'ד' => 4   | 'ה' => 5
    | 'ו' => 6   | 'ז' => 7   | 'ח' => 8   | 'ט' => 9   | 'י' => 10
    | 'כ' => 20  | 'ך' => 20  | 'ל' => 30  | 'מ' => 40  | 'ם' => 40
    | 'נ' => 50  | 'ן' => 50  | 'ס' => 60  | 'ע' => 70  | 'פ' => 80
    | 'ף' => 80  | 'צ' => 90  | 'ץ' => 90  | 'ק' => 100 | 'ר' => 200
    | 'ש' => 300 | 'ת' => 400 | _ => 0
  | GematriaScheme.Reduced =>
    match c with
    | 'א' => 1 | 'ב' => 2 | 'ג' => 3 | 'ד' => 4 | 'ה' => 5
    | 'ו' => 6 | 'ז' => 7 | 'ח' => 8 | 'ט' => 9 | 'י' => 1
    | 'כ' => 2 | 'ך' => 2 | 'ל' => 3 | 'מ' => 4 | 'ם' => 4
    | 'נ' => 5 | 'ן' => 5 | 'ס' => 6 | 'ע' => 7 | 'פ' => 8
    | 'ף' => 8 | 'צ' => 9 | 'ץ' => 9 | 'ק' => 1 | 'ר' => 2
    | 'ש' => 3 | 'ת' => 4 | _ => 0
  | GematriaScheme.Ordinal =>
    match c with
    | 'א' => 1  | 'ב' => 2  | 'ג' => 3  | 'ד' => 4  | 'ה' => 5
    | 'ו' => 6  | 'ז' => 7  | 'ח' => 8  | 'ט' => 9  | 'י' => 10
    | 'כ' => 11 | 'ך' => 11 | 'ל' => 12 | 'מ' => 13 | 'ם' => 13
    | 'נ' => 14 | 'ן' => 14 | 'ס' => 15 | 'ע' => 16 | 'פ' => 17
    | 'ף' => 17 | 'צ' => 18 | 'ץ' => 18 | 'ק' => 19 | 'ר' => 20
    | 'ש' => 21 | 'ת' => 22 | _ => 0

/-- Digital root calculation: repeatedly sum base-10 digits until a single digit 1..9 remains. -/
def digitalRoot (n : Nat) : Nat :=
  if n == 0 then 0
  else
    let r := n % 9
    if r == 0 then 9 else r

/-- Compute the gematria value of a string by summing character values.
    For the Reduced scheme (Mispar Katan), the standard sum is reduced to its digital root. -/
def stringGematria (scheme : GematriaScheme) (s : String) : Nat :=
  match scheme with
  | GematriaScheme.Standard =>
    s.toList.foldl (fun acc c => acc + charGematria GematriaScheme.Standard c) 0
  | GematriaScheme.Reduced =>
    digitalRoot (s.toList.foldl (fun acc c => acc + charGematria GematriaScheme.Standard c) 0)
  | GematriaScheme.Ordinal =>
    s.toList.foldl (fun acc c => acc + charGematria GematriaScheme.Ordinal c) 0

/-! ### 3. Encoding Layer -/

/-- An explicit numerical encoding of a semantic token under a specific scheme. -/
structure Encoding where
  token    : SemanticToken
  scheme   : GematriaScheme
  value    : Nat
  positive : 0 < value
  deriving Repr, BEq, DecidableEq

instance : ToString Encoding := ⟨fun e =>
  s!"Encoding({e.token.id}, {e.scheme}, val={e.value})"⟩

/-- Evaluate an encoding directly from a token and scheme.
    Returns `none` if the string yields value 0. -/
def evalEncoding (token : SemanticToken) (scheme : GematriaScheme) : Option Encoding :=
  let v := stringGematria scheme token.hebrew
  if h : 0 < v then
    some { token := token, scheme := scheme, value := v, positive := h }
  else
    none

/-! ### 4. Mathematical Layer: Prime-Multiplicity Substrate -/

/-- A prime factor pair: $(p, e)$ representing $p^e$ where $p \ge 2$ and $e \ge 1$. -/
structure PrimeFactor where
  prime    : Nat
  exponent : Nat
  deriving Repr, BEq, DecidableEq, Inhabited

instance : ToString PrimeFactor := ⟨fun pf => s!"{pf.prime}^{pf.exponent}"⟩

/-- Prime Multiplicity vector: canonical representation of the prime exponent vector
    $\prod p_i^{e_i}$, stored as an ordered list of distinct prime factor pairs. -/
structure PrimeMultiplicity where
  factors : List PrimeFactor
  deriving Repr, BEq, DecidableEq, Inhabited

instance : ToString PrimeMultiplicity := ⟨fun pm =>
  if pm.factors.isEmpty then "1"
  else String.intercalate " * " (pm.factors.map toString)⟩

namespace PrimeMultiplicity

/-- Lookup the multiplicity exponent $v_p(n)$ for a given prime $p$. -/
def valAt (pm : PrimeMultiplicity) (p : Nat) : Nat :=
  match pm.factors.find? (fun pf => pf.prime == p) with
  | some pf => pf.exponent
  | none => 0

/-- The finite prime support set $\{p \mid v_p(n) > 0\}$ as a list. -/
def support (pm : PrimeMultiplicity) : List Nat :=
  pm.factors.map (fun pf => pf.prime)

/-- The number of distinct prime factors $\omega(n) = |\text{supp}(n)|$. -/
def omega (pm : PrimeMultiplicity) : Nat :=
  pm.factors.length

/-- Total prime multiplicity $\Omega(n) = \sum_{p \in \text{supp}(n)} v_p(n)$. -/
def Omega (pm : PrimeMultiplicity) : Nat :=
  pm.factors.foldl (fun acc pf => acc + pf.exponent) 0

/-- Reconstruct the integer product $\prod p_i^{e_i}$. -/
def product (pm : PrimeMultiplicity) : Nat :=
  pm.factors.foldl (fun acc pf => acc * (pf.prime ^ pf.exponent)) 1

/-- Construct a single prime factor multiplicity $p^e$. -/
def single (p : Nat) (e : Nat) : PrimeMultiplicity :=
  if e == 0 then { factors := [] }
  else { factors := [{ prime := p, exponent := e }] }

/-- Vector addition of two prime multiplicity representations.
    Combines exponents: $v_p(A + B) = v_p(A) + v_p(B)$. -/
def add (a b : PrimeMultiplicity) : PrimeMultiplicity :=
  let rec insertFactor (f : PrimeFactor) (l : List PrimeFactor) : List PrimeFactor :=
    match l with
    | [] => [f]
    | x :: xs =>
      if f.prime < x.prime then
        f :: x :: xs
      else if f.prime == x.prime then
        { prime := x.prime, exponent := x.exponent + f.exponent } :: xs
      else
        x :: insertFactor f xs
  let rec merge (l1 l2 : List PrimeFactor) : List PrimeFactor :=
    match l1 with
    | [] => l2
    | f :: fs => merge fs (insertFactor f l2)
  { factors := merge a.factors b.factors }

/-- Insert an element into a descending-sorted list of natural numbers. -/
def insertDescending (x : Nat) : List Nat → List Nat
  | [] => [x]
  | y :: ys =>
    if x >= y then
      x :: y :: ys
    else
      y :: insertDescending x ys

/-- Canonical sort for prime sequences: sorts a list of prime numbers in monotone descending order.
    Enforces a strict total order prior to PARM position-aware sealing. -/
def canonicalPrimeSort : List Nat → List Nat
  | [] => []
  | x :: xs => insertDescending x (canonicalPrimeSort xs)

/-- Expand the prime multiplicity vector into a flat sequence of prime factors.
    For example, {2 ↦ 3, 3 ↦ 2} becomes [2, 2, 2, 3, 3]. -/
def toPrimeList (pm : PrimeMultiplicity) : List Nat :=
  let rec expand (pf : PrimeFactor) (n : Nat) (acc : List Nat) : List Nat :=
    match n with
    | 0 => acc
    | n' + 1 => expand pf n' (pf.prime :: acc)
  pm.factors.foldr (fun pf acc => expand pf pf.exponent acc) []

/-- Sort prime factors in strictly descending order of prime bases. -/
def sortFactorsDescending (l : List PrimeFactor) : List PrimeFactor :=
  let rec insert (f : PrimeFactor) : List PrimeFactor → List PrimeFactor
    | [] => [f]
    | x :: xs =>
      if f.prime >= x.prime then
        f :: x :: xs
      else
        x :: insert f xs
  l.foldr insert []

/-- Expand a PrimeMultiplicity into its canonical, strictly descending prime factor list.
    Guarantees unique, deterministic sequencing matching the PARM 108-cycle convention. -/
def toCanonicalPrimeList (pm : PrimeMultiplicity) : List Nat :=
  let sortedFactors := sortFactorsDescending pm.factors
  let rec expand (pf : PrimeFactor) (n : Nat) (acc : List Nat) : List Nat :=
    match n with
    | 0 => acc
    | n' + 1 => expand pf n' (pf.prime :: acc)
  sortedFactors.foldr (fun pf acc => expand pf pf.exponent acc) []

end PrimeMultiplicity

/-- Computable prime factorization via trial division. -/
def factorize (n : Nat) : PrimeMultiplicity :=
  if n < 2 then { factors := [] }
  else
    let rec countDiv (p m acc fuel : Nat) : Nat × Nat :=
      match fuel with
      | 0 => (acc, m)
      | f + 1 =>
        if m % p == 0 && m > 0 then
          countDiv p (m / p) (acc + 1) f
        else
          (acc, m)
    let rec loop (m p fuel : Nat) (acc : List PrimeFactor) : List PrimeFactor :=
      match fuel with
      | 0 => if m > 1 then acc ++ [{ prime := m, exponent := 1 }] else acc
      | f + 1 =>
        if m <= 1 then acc
        else if p * p > m then
          acc ++ [{ prime := m, exponent := 1 }]
        else if m % p == 0 then
          let (exp, rem) := countDiv p m 0 (m + 1)
          loop rem (p + 1) f (acc ++ [{ prime := p, exponent := exp }])
        else
          loop m (p + 1) f acc
    { factors := loop n 2 (n + 10) [] }

/-! ### 5. Trajectory Layer -/

/-- A trajectory couples an explicit Encoding with its verifiable PrimeMultiplicity invariant. -/
structure Trajectory where
  encoding  : Encoding
  invariant : PrimeMultiplicity
  deriving Repr, BEq, DecidableEq

instance : ToString Trajectory := ⟨fun t =>
  s!"Trajectory({t.encoding.token.id} [{t.encoding.scheme}] -> {t.encoding.value} => {t.invariant})"⟩

/-- Create a canonical trajectory from an encoding by computing its prime factorization. -/
def Trajectory.ofEncoding (e : Encoding) : Trajectory :=
  { encoding := e, invariant := factorize e.value }

/-- Position-Aware Recursive Multiplicity (PARM) accumulator loop.
    Mirrors the canonical Core.PARM.sealed_state_loop commitment primitive. -/
def parmSealedStateLoop (v : Nat) : List Nat → Nat
  | [] => v
  | [last] => (last * last) * (v + last)
  | p :: ps => parmSealedStateLoop (p * (v + p)) ps

/-- Position-Aware Recursive Multiplicity (PARM) sealed state.
    Computes the canonical position-aware cryptographic commitment root
    from an ordered sequence of prime factors. -/
def parmSealedState (primes : List Nat) : Nat :=
  match primes with
  | [] => 0
  | [p] => p * p
  | p :: ps => parmSealedStateLoop (p * p) ps

/-- Canonical PARM sealed state of an arbitrary prime list: applies the canonical
    descending sort before feeding into the position-aware PARM accumulator. -/
def canonicalSealedState (primes : List Nat) : Nat :=
  parmSealedState (PrimeMultiplicity.canonicalPrimeSort primes)

/-- Canonical PARM sealed state of a trajectory: extracts the canonical descending
    prime sequence from the multiplicity multiset and computes the PARM commitment root. -/
def Trajectory.sealedState (t : Trajectory) : Nat :=
  parmSealedState t.invariant.toCanonicalPrimeList

/-! ### 5.1 Zero-Knowledge Circuit Constraints -/

/-- Computable decision procedure for monotonic descending sequence constraint:
    $p_i \ge p_{i+1}$ for all adjacent elements in the sequence. -/
def isMonotonicDescendingBool : List Nat → Bool
  | [] => true
  | [_] => true
  | p1 :: p2 :: ps => (p1 >= p2) && isMonotonicDescendingBool (p2 :: ps)

/-- Formal proposition that a prime list is monotonically descending. -/
def IsMonotonicDescending (primes : List Nat) : Prop :=
  isMonotonicDescendingBool primes = true

/-- Compute the sequence of non-negative differences $\Delta_i = p_i - p_{i+1}$
    used by the SNARK circuit for $O(1)$ range-check lookups. -/
def adjacentDifferences : List Nat → List Nat
  | [] => []
  | [_] => []
  | p1 :: p2 :: ps => (p1 - p2) :: adjacentDifferences (p2 :: ps)

/-- Computable grand product of a list of primes: $\prod p_i$. -/
def listProduct (primes : List Nat) : Nat :=
  primes.foldl (· * ·) 1

/-- Running product accumulator wire trace for the arithmetic circuit:
    $\pi_0 = p_0$, $\pi_i = \pi_{i-1} \cdot p_i$, with final constraint $\pi_{k-1} = E_{\text{raw}}$. -/
def runningProductStates : List Nat → List Nat
  | [] => []
  | p :: ps =>
    let rec loop (cur : Nat) : List Nat → List Nat
      | [] => [cur]
      | x :: xs => cur :: loop (cur * x) xs
    loop p ps

/-- Computable primality test: checks $n \ge 2$ and no divisors $2 \le d \le \sqrt{n}$.
    Models the in-circuit prime lookup table $\mathcal{T}_{\text{Primes}}$ ($O(1)$ table lookup). -/
def isPrimeNat (n : Nat) : Bool :=
  if n < 2 then false
  else if n == 2 then true
  else if n % 2 == 0 then false
  else
    let rec checkDiv (d : Nat) (fuel : Nat) : Bool :=
      match fuel with
      | 0 => true
      | f + 1 =>
        if d * d > n then true
        else if n % d == 0 then false
        else checkDiv (d + 2) f
    checkDiv 3 (n / 2)

/-- Check that every element in the list is a valid prime ($p_i \ge 2$, $p_i \in \mathbb{P}$).
    Strictly excludes composite integers and unit padding (1). -/
def allPrimesBool (primes : List Nat) : Bool :=
  primes.all isPrimeNat

/-- Zero-Knowledge Circuit Witness for Fully Authenticated PARM Sealing.
    Enforces the complete triad of SNARK constraints:
    1. Monotonic descending order: $p_i \ge p_{i+1}$ (ordering security).
    2. Primality & unit exclusion: $p_i \in \mathbb{P} \wedge p_i \ge 2$ (algebraic domain security).
    3. Grand product equivalence: $\prod p_i = E_{\text{raw}}$ (origin authenticity). -/
structure FullyConstrainedParmWitness where
  primes      : List Nat
  rawEncoding : Nat
  is_sorted   : isMonotonicDescendingBool primes = true
  all_primes  : allPrimesBool primes = true
  product_eq  : listProduct primes = rawEncoding
  deriving Repr

/-- Circuit Sealing Function on Fully Constrained Witness. -/
def FullyConstrainedParmWitness.sealedState (w : FullyConstrainedParmWitness) : Nat :=
  parmSealedState w.primes

/-- Circuit Constraint Evaluator with Grand Product Anchoring:
    Checks monotonicity, grand product, and 16-bit range bound. -/
def evaluateAnchoredCircuitConstraint (primes : List Nat) (rawEncoding : Nat) (bit_bound : Nat := 65536) : Bool :=
  isMonotonicDescendingBool primes && (listProduct primes == rawEncoding) && primes.all (· < bit_bound)

/-- Circuit Constraint Evaluator with Complete Triad Enforcement:
    Checks monotonicity, primality/unit exclusion, grand product, and 16-bit range bound. -/
def evaluateFullyConstrainedCircuit (primes : List Nat) (rawEncoding : Nat) (bit_bound : Nat := 65536) : Bool :=
  isMonotonicDescendingBool primes &&
  allPrimesBool primes &&
  (listProduct primes == rawEncoding) &&
  primes.all (· < bit_bound)

/-! ### 5.2 Large-Prime Verification Circuit (Pratt Primality Certificates) -/

/-- Fast modular exponentiation $base^{exp} \pmod m$ using square-and-multiply.
    Models in-circuit non-native modular exponentiation gates ($O(\log exp)$ constraints). -/
def modPow (base exp m : Nat) : Nat :=
  if m == 0 then 0
  else if m == 1 then 0
  else
    let rec loop (b e acc : Nat) (fuel : Nat) : Nat :=
      match fuel with
      | 0 => acc
      | f + 1 =>
        if e == 0 then acc
        else
          let acc' := if e % 2 == 1 then (acc * b) % m else acc
          let b' := (b * b) % m
          let e' := e / 2
          loop b' e' acc' f
    loop (base % m) exp 1 128

/-- Non-deterministic Pratt Primality Certificate for large primes $p > 2^{16}$.
    Contains:
    - $p$: candidate large prime
    - $g$: primitive root witness ($1 < g < p$)
    - $factors$: prime factorization of $p - 1$ as list of $(q, e)$ pairs. -/
structure PrattCertificate where
  p       : Nat
  g       : Nat
  factors : List (Nat × Nat)
  deriving Repr, DecidableEq

/-- Compute the product of prime powers: $\prod q_i^{e_i}$. -/
def primePowersProduct : List (Nat × Nat) → Nat
  | [] => 1
  | (q, e) :: rest => (q ^ e) * primePowersProduct rest

/-- Verifier for Pratt Primality Certificates inside the circuit.
    Enforces:
    1. $p > 2$, $1 < g < p$.
    2. $\prod q_i^{e_i} = p - 1$ (completeness of $p-1$ factorization).
    3. Fermat check: $g^{p-1} \equiv 1 \pmod p$.
    4. Lucas non-degeneracy checks: $\forall q_i, g^{(p-1)/q_i} \not\equiv 1 \pmod p$.
    5. Base-case primality: each factor $q_i \le 65536 \implies \texttt{isPrimeNat } q_i = \text{true}$. -/
def verifyPrattCertificate (cert : PrattCertificate) : Bool :=
  let p := cert.p
  let g := cert.g
  if p <= 2 || g <= 1 || g >= p then false
  else
    let factorsProd := primePowersProduct cert.factors
    if factorsProd != p - 1 then false
    else
      -- 1. Fermat check: g^(p-1) == 1 (mod p)
      let fermatCheck := modPow g (p - 1) p == 1
      -- 2. Lucas checks: g^((p-1)/q) != 1 (mod p)
      let lucasChecks := cert.factors.all (fun (q, _) =>
        q > 0 && isPrimeNat q && modPow g ((p - 1) / q) p != 1
      )
      fermatCheck && lucasChecks

/-- Hybrid Primality Decider:
    - Tier 1 ($n \le 65536$): $O(1)$ static table lookup via `isPrimeNat`.
    - Tier 2 ($n > 65536$): $O(\log n)$ Pratt Certificate verification via `verifyPrattCertificate`. -/
def isHybridPrime (n : Nat) (cert : Option PrattCertificate := none) : Bool :=
  if n <= 65536 then
    isPrimeNat n
  else
    match cert with
    | some c => (c.p == n) && verifyPrattCertificate c
    | none => false

/-- Check that all elements in a prime list satisfy the hybrid primality verifier. -/
def allHybridPrimesBool (primes : List Nat) (certs : List (Option PrattCertificate)) : Bool :=
  if primes.length != certs.length then false
  else
    (primes.zip certs).all (fun (p, c) => isHybridPrime p c)

/-- Unbounded Circuit Witness for Arbitrary Prime Multiplicity Trajectories.
    Supports primes of ANY scale using Tier-1 table lookups and Tier-2 Pratt certificates. -/
structure UnboundedParmCircuitWitness where
  primes      : List Nat
  certs       : List (Option PrattCertificate)
  rawEncoding : Nat
  is_sorted   : isMonotonicDescendingBool primes = true
  all_primes  : allHybridPrimesBool primes certs = true
  product_eq  : listProduct primes = rawEncoding
  deriving Repr

/-- Circuit Sealing Function on Unbounded Witness. -/
def UnboundedParmCircuitWitness.sealedState (w : UnboundedParmCircuitWitness) : Nat :=
  parmSealedState w.primes

/-- Circuit Constraint Evaluator with Unbounded Scale Support. -/
def evaluateUnboundedCircuit (primes : List Nat) (certs : List (Option PrattCertificate)) (rawEncoding : Nat) : Bool :=
  isMonotonicDescendingBool primes &&
  allHybridPrimesBool primes certs &&
  (listProduct primes == rawEncoding)

/-! ### 6. Equivalence Relations -/

/-- Semantic Equivalence ($\approx_{sem}$): Two encodings refer to the same semantic token. -/
def SemanticEquivEncoding (e1 e2 : Encoding) : Prop :=
  e1.token.id = e2.token.id

/-- Mathematical Equivalence ($\equiv_{math}$): Two trajectories share the exact prime multiplicity vector. -/
def MathEquivTrajectory (t1 t2 : Trajectory) : Prop :=
  t1.invariant = t2.invariant

/-- Numerical Value Equivalence: Two encodings yield identical integer values. -/
def ValueEquivEncoding (e1 e2 : Encoding) : Prop :=
  e1.value = e2.value

/-! ### 7. Digital-Root Analysis & Retraction (ADR-022) -/

/-- Digital root prime multiplicity invariant: factorize (digitalRoot n).
    Retracted by ADR-022 due to finite-state collapse of infinite prime entropy. -/
def digitalRootInvariant (n : Nat) : PrimeMultiplicity :=
  factorize (digitalRoot n)

/-! ### 8. Event Deduplication & Arithmetic Multiplicity -/

/-- A semantic occurrence event in a corpus or discourse.
    Carries a globally unique event ID and the associated semantic token. -/
structure SemanticEvent where
  eventId : Nat
  token   : SemanticToken
  deriving Repr, BEq, DecidableEq

/-- Count unique events in a list, rejecting duplicates by eventId. -/
def countUniqueEvents (events : List SemanticEvent) : Nat :=
  let rec loop (l : List SemanticEvent) (seen : List Nat) : Nat :=
    match l with
    | [] => seen.length
    | e :: es =>
      if seen.contains e.eventId then
        loop es seen
      else
        loop es (e.eventId :: seen)
  loop events []

/-- Substrate combining two encodings multiplicatively.
    The resulting prime multiplicity is the vector sum of prime exponents. -/
def combineTrajectories (t1 t2 : Trajectory) : PrimeMultiplicity :=
  PrimeMultiplicity.add t1.invariant t2.invariant

end Multiplicity.WordLove
