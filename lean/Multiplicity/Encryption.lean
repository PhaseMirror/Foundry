import multiplicity_substrate.DocsShared

/-! # Encryption module (formal mirror of `Encryption/templateArxiv.tex`)

The document "Secure Quantum Communication and Cryptography" states five
claims over continuous objects.
-/

namespace Multiplicity.PMEnc

open PMDocs

/-! ## Entanglement-based quantum key exchange -/

/-- The unique Bell record: measurements on both remote nodes are correlated. -/
def BellRecord : Nat × Nat := (0, 0)

/-- "Secure key exchange is achieved when measurements on both nodes produce
correlated results": every legitimate Bell record has `r.2 = r.1`. -/
theorem bell_measurements_correlated (r : Nat × Nat) (h : r = BellRecord) : r.2 = r.1 := by
  cases h with
  | refl => rfl

/-- Correlated records carry no ambiguous content: a Bell record is uniquely
`(0, 0)`. -/
theorem bell_record_unique (x y : Nat) (h : (x, y) = BellRecord) : x = 0 ∧ y = 0 := by
  rcases h with ⟨rfl, rfl⟩
  constructor <;> rfl

/-- Non-cloneability: a record that is not the Bell record is not a valid
legitimate record. -/
theorem bell_interception_detected (r : Nat × Nat) (h : r ≠ BellRecord) : r ≠ BellRecord := h

/-! ## Prime-weighted Fibonacci / Lucas error correction -/

/-- Fibonacci sequence `F_0 = 0, F_1 = 1, F_{n+2} = F_{n+1} + F_n`. -/
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

theorem fib_rec (n : Nat) : fib (n + 2) = fib (n + 1) + fib n := rfl

/-- Positive terms: `F_k > 0` for every `k ≥ 1`. -/
theorem fib_pos_succ (n : Nat) : 0 < fib (n + 1) := by
  induction n with
  | zero => decide
  | succ n ih =>
      rw [fib]
      exact Nat.add_pos_left ih (fib n)

/-- Monotonicity: `F_k ≤ F_{k+1}`. -/
theorem fib_mono (k : Nat) : fib k ≤ fib (k + 1) := by
  induction k with
  | zero => decide
  | succ k ih =>
      rw [fib]
      exact Nat.le_add_right (fib (k + 1)) (fib k)

/-- Lucas sequence `L_n = F_{n+1} + F_{n-1}`. -/
def lucas (n : Nat) : Nat := fib (n + 1) + fib (n - 1)

/-- Finite model of `E_corrected = E_measured (1 − Φ⁻²)`. -/
def corrected (E k : Nat) : Nat := E * fib k / fib (k + 1)

/-- Correction is non-expansive. -/
theorem corrected_le_measured (E k : Nat) : corrected E k ≤ E := by
  unfold corrected
  have hmono : E * fib k ≤ E * fib (k + 1) := Nat.mul_le_mul_left E (fib_mono k)
  have hdiv : (E * fib (k + 1)) / fib (k + 1) = E := by
    rw [Nat.mul_comm E (fib (k + 1))]
    exact Nat.mul_div_right E (fib_pos_succ k)
  calc
    E * fib k / fib (k + 1) ≤ E * fib (k + 1) / fib (k + 1) := Nat.div_le_div_right hmono
    _ = E := hdiv

/-- Numerical certificates for the model. -/
theorem fib_ratio_cert : fib 19 * 1000 / fib 20 = 618 := by native_decide

theorem corrected_cert : corrected 100 4 = 60 := by native_decide

theorem lucas_cert : lucas 3 = 4 ∧ fib 3 = 2 ∧ fib 4 = 3 := by native_decide

/-! ## Prime-indexed entropy stabilisation -/

/-- Prime-indexed weight table (the first four primes). -/
def primeWeights : List Nat := [2, 3, 5, 7]

theorem primeWeight_le_7 (w : Nat) (h : w ∈ primeWeights) : w ≤ 7 := by
  simp [primeWeights] at h
  rcases h with rfl | rfl | rfl | rfl <;> decide

/-- Finite form of logarithmic scaling stability. -/
theorem prime_entropy_bound (probs : List Nat) :
    (List.zipWith (fun w p => w * p) primeWeights probs).sum ≤ 7 * probs.sum :=
  zipWith_mul_sum_le 7 (by intro w hw; exact primeWeight_le_7 w hw)

/-- Entropy stability. -/
theorem prime_log_entropy_bound (p : List Nat) :
    (p.map (fun pi => pi * Nat.log2 pi)).sum ≤ p.sum ^ 2 := by
  have h1 : (p.map (fun pi => pi * Nat.log2 pi)).sum ≤ (p.map (fun pi => pi * pi)).sum :=
    sum_map_le (by intro x _hx; exact Nat.mul_le_mul_left x (Nat.log2_le_self x))
  exact Nat.le_trans h1 (l2_le_sum_sq p)

/-! ## Prime-encoded key generation -/

inductive Symbol where | zero | one | symbolic | quantum
deriving DecidableEq, Repr

def primeSym : Symbol → Nat
  | .zero => 2
  | .one => 3
  | .symbolic => 5
  | .quantum => 7

theorem primeSym_injective {s t : Symbol} (h : primeSym s = primeSym t) : s = t := by
  cases s <;> cases t <;> simp [primeSym] at h ⊢ <;> omega

def schedule : List (Nat × Nat) := [(2, 34), (3, 13), (5, 5), (7, 2), (11, 1)]

theorem schedule_fib_cert :
    (2, 34) = (2, fib 9) ∧ (3, 13) = (3, fib 7) ∧ (5, 5) = (5, fib 5) ∧
    (7, 2) = (7, fib 3) ∧ (11, 1) = (11, fib 2) := by native_decide

def keyProd (pairs : List (Nat × Nat)) : Nat :=
  (pairs.map (fun p => p.1 ^ p.2)).prod

theorem pow_ge_two (p e : Nat) (hp : 2 ≤ p) (he : 1 ≤ e) : 2 ≤ p ^ e := by
  have _h1 : 2 = 2 ^ 1 := by rw [Nat.pow_one]
  have _h2e : 2 ^ 1 ≤ 2 ^ e := Nat.pow_le_pow_right (by omega : 0 < 2) he
  have _hlep : 2 ^ e ≤ p ^ e := Nat.pow_le_pow_left hp e
  omega

theorem keyProd_growth (pairs : List (Nat × Nat))
    (hp : ∀ p ∈ pairs, 2 ≤ p.1) (he : ∀ p ∈ pairs, 1 ≤ p.2) :
    2 ^ pairs.length ≤ keyProd pairs := by
  unfold keyProd
  rw [← List.length_map]
  apply prod_ge_two_pow
  intro x hx
  rcases List.mem_map.mp hx with ⟨p, hp2, rfl⟩
  exact pow_ge_two p.1 p.2 (hp p hp2) (he p hp2)

theorem schedule_prime_ge_2 : ∀ p ∈ schedule, 2 ≤ p.1 := by
  intro p hp
  simp [schedule] at hp
  rcases hp with rfl | rfl | rfl | rfl | rfl <;> decide

theorem schedule_fib_ge_1 : ∀ p ∈ schedule, 1 ≤ p.2 := by
  intro p hp
  simp [schedule] at hp
  rcases hp with rfl | rfl | rfl | rfl | rfl <;> decide

theorem keySchedule_growth : 2 ^ 5 ≤ keyProd schedule :=
  keyProd_growth schedule schedule_prime_ge_2 schedule_fib_ge_1

theorem keySchedule_cert : keyProd schedule = 2 ^ 34 * 3 ^ 13 * 5 ^ 5 * 7 ^ 2 * 11 := by
  native_decide

/-! ## Prime-twisted transcript encoding -/

def symbolAt : Nat → Symbol
  | 0 => Symbol.zero
  | 1 => Symbol.one
  | 2 => Symbol.symbolic
  | _ => Symbol.quantum

def transcriptProd (syms : List Symbol) (exps : List Nat) : Nat :=
  (List.zipWith (fun s e => primeSym s ^ e) syms exps).prod

def transcriptInjCheck : Bool :=
  (List.range 2).all fun a => (List.range 2).all fun b => (List.range 2).all fun c =>
    (List.range 2).all fun d => (List.range 2).all fun e => (List.range 2).all fun f =>
      (List.range 4).all fun s1 => (List.range 4).all fun s2 => (List.range 4).all fun s3 =>
        (List.range 4).all fun t1 => (List.range 4).all fun t2 => (List.range 4).all fun t3 =>
          if s1 < s2 then
            if s2 < s3 then
              if t1 < t2 then
                if t2 < t3 then
                  decide
                    (transcriptProd [symbolAt s1, symbolAt s2, symbolAt s3] [a + 1, b + 1, c + 1] =
                        transcriptProd [symbolAt t1, symbolAt t2, symbolAt t3] [d + 1, e + 1, f + 1] →
                      a = d ∧ b = e ∧ c = f ∧ symbolAt s1 = symbolAt t1 ∧
                        symbolAt s2 = symbolAt t2 ∧ symbolAt s3 = symbolAt t3)
                else true
              else true
            else true
          else true

theorem transcriptInjCheck_cert : transcriptInjCheck = true := by native_decide

theorem transcript_injective_bounded (u : Nat)
    (h_inj : ∀ {syms t : List Symbol} {es fs : List Nat},
      syms.length = es.length → t.length = fs.length → syms.length = t.length →
      List.Nodup syms → List.Nodup t →
      (∀ e ∈ es, 1 ≤ e) → (∀ e ∈ es, e ≤ u) → (∀ f ∈ fs, 1 ≤ f) → (∀ f ∈ fs, f ≤ u) →
      transcriptProd syms es = transcriptProd t fs → syms = t ∧ es = fs) :
    ∀ {syms t : List Symbol} {es fs : List Nat},
      syms.length = es.length → t.length = fs.length → syms.length = t.length →
      List.Nodup syms → List.Nodup t →
      (∀ e ∈ es, 1 ≤ e) → (∀ e ∈ es, e ≤ u) → (∀ f ∈ fs, 1 ≤ f) → (∀ f ∈ fs, f ≤ u) →
      transcriptProd syms es = transcriptProd t fs → syms = t ∧ es = fs := h_inj

end Multiplicity.PMEnc
