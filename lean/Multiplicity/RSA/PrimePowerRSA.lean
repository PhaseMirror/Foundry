import Multiplicity.RSA

/-!
# Prime-power RSA: correctness for a list of pairwise-coprime prime powers

The two-prime RSA scheme in `RSA.lean` generalizes to a modulus `N` that is a
product of pairwise-coprime *prime powers* `p₁^m₁ · p₂^m₂ · ⋯ · p_k^m_k`.
This is the classical "prime-power RSA": the totient of the scheme is the
product of the individual totients

    φ(pᵢ^mᵢ) = (pᵢ - 1) · pᵢ^(mᵢ - 1),

and decryption inverts encryption on every message coprime to `N`.

The proof reuses the machinery of the two-prime case:

* `PPFactor.totient_eq` identifies the *counted* totient `phi (p ^ m)` (from
  `Totient.phi_prime_power`) with the closed form `(p - 1) * p ^ (m - 1)`.
* `pow_modEq_euler` is the Euler-version of the Fermat lifting used in
  `RSA.lean`: if `e * d ≡ 1 [MOD phi n]` and `msg` is coprime to `n`, then
  `msg ^ (e * d) ≡ msg [MOD n]`. It replaces `fermat_little` with
  `euler_theorem`, so it needs coprimality of the message instead of
  primality of the modulus.
* `modEq_of_product` is the multi-modulus Chinese remainder theorem: congruent
  modulo every member of a pairwise-coprime list implies congruent modulo the
  product.

## Assumptions

For a factor `pᵢ^mᵢ`, textbook RSA only inverts messages *coprime to the
factor*. This is inherent: a message divisible by `pᵢ` reduces to `0` modulo
`pᵢ^mᵢ` only after an exponentiation of height at least `mᵢ`, which the
scheme does not guarantee. Hence `rsa_correctness_pp` requires
`Nat.Coprime msg (PPN fs)` (equivalently, coprimality to every factor), in
contrast with the two-prime theorem which covers *all* messages. When the
prime power is a single prime (`m = 1`) the two statements coincide.
-/

namespace Multiplicity.RSA

/-! ## Prime-power factors -/

/-- A prime-power factor `p ^ m` of the RSA modulus, carrying the primality
of `p` and the positivity of the exponent. -/
structure PPFactor where
  p : Nat
  m : Nat
  hp : Prime p
  hm : 1 ≤ m

/-- The modulus of a prime-power factor: `p ^ m`. -/
def PPFactor.modulus (f : PPFactor) : Nat := f.p ^ f.m

/-- The totient of a prime-power factor: `(p - 1) * p ^ (m - 1)`. -/
def PPFactor.totient (f : PPFactor) : Nat := (f.p - 1) * f.p ^ (f.m - 1)

/-- The modulus of a prime-power factor is positive. -/
theorem PPFactor.modulus_pos (f : PPFactor) : 0 < f.modulus := by
  unfold PPFactor.modulus
  have hp0 : 0 < f.p := by
    have hp1 : 1 < f.p := f.hp.1
    omega
  exact Nat.pow_pos hp0

/-- The counted totient of a prime-power factor equals its closed form:
`phi (p ^ m) = (p - 1) * p ^ (m - 1)`. -/
theorem PPFactor.totient_eq (f : PPFactor) : phi f.modulus = f.totient := by
  unfold PPFactor.modulus PPFactor.totient
  exact phi_prime_power f.hp f.hm

/-- The totient of a prime-power factor is positive. -/
theorem PPFactor.totient_pos (f : PPFactor) : 0 < f.totient := by
  unfold PPFactor.totient
  have hp0 : 0 < f.p := by
    have hp1 : 1 < f.p := f.hp.1
    omega
  have h1 : 0 < f.p - 1 := by
    have hp1 : 1 < f.p := f.hp.1
    omega
  have h2 : 0 < f.p ^ (f.m - 1) := Nat.pow_pos hp0
  exact Nat.mul_pos h1 h2

/-! ## Pairwise-coprime lists and the multi-modulus CRT -/

/-- A list of moduli is pairwise coprime when every two distinct entries are
coprime. Encoded as `List.Pairwise`, so the head is coprime to every tail
element and the tail is recursively pairwise coprime. -/
def PairwiseCoprime (ms : List Nat) : Prop := ms.Pairwise Nat.Coprime

/-- Each element of a list divides the list product. -/
theorem dvd_product_of_mem {l : List Nat} {i : Nat} (hi : i ∈ l) : i ∣ product l := by
  induction l with
  | nil => simp at hi
  | cons x t ih =>
      rw [List.mem_cons] at hi
      rcases hi with hix | hit
      · subst i
        rw [product_cons]
        exact Nat.dvd_mul_right x (product t)
      · rw [product_cons]
        exact Nat.dvd_trans (ih hit) (Nat.dvd_mul_left (product t) x)

/-- The gcd with `a` respects divisibility on the right argument. -/
theorem gcd_dvd_gcd_of_dvd {a b c : Nat} (h : b ∣ c) : a.gcd b ∣ a.gcd c := by
  exact Nat.dvd_gcd (Nat.gcd_dvd_left a b) (Nat.dvd_trans (Nat.gcd_dvd_right a b) h)

/-- If `b` divides `c` and `a` is coprime to `c`, then `a` is coprime to
`b`. -/
theorem coprime_dvd {a b c : Nat} (hbc : b ∣ c) (hc : Nat.Coprime a c) : Nat.Coprime a b := by
  have hle : a.gcd b ∣ a.gcd c := gcd_dvd_gcd_of_dvd hbc
  have h1 : a.gcd b ∣ 1 := by simpa [hc] using hle
  exact Nat.eq_one_of_dvd_one h1

/-- In a pairwise-coprime list, the head is coprime to the product of the
tail. -/
theorem coprime_head_product {m : Nat} {ms : List Nat}
    (hp : PairwiseCoprime (m :: ms)) : Nat.Coprime m (product ms) := by
  rw [PairwiseCoprime] at hp
  rw [List.pairwise_cons] at hp
  exact (coprime_product (n := m) (l := ms) (fun x hx => (hp.1 x hx).symm)).symm

/-- **Multi-modulus Chinese remainder theorem.** If `a` is congruent to `b`
modulo every member of a pairwise-coprime list, then `a` is congruent to `b`
modulo the product of the list. -/
theorem modEq_of_product {a b : Nat} :
    ∀ ms : List Nat, PairwiseCoprime ms → (∀ i ∈ ms, a ≡ b [MOD i]) →
      a ≡ b [MOD product ms] := by
  intro ms
  induction ms with
  | nil =>
      intro _ _
      simp [ModEq, Nat.mod_one]
  | cons m t ih =>
      intro hp hmod
      rw [PairwiseCoprime] at hp
      rw [List.pairwise_cons] at hp
      have hm : a ≡ b [MOD m] := hmod m (by simp)
      have hrest : a ≡ b [MOD product t] := ih hp.2 (fun i hi => hmod i (by simp [hi]))
      have hmn : Nat.Coprime m (product t) := coprime_head_product (m := m) (ms := t)
        (List.Pairwise.cons hp.1 hp.2)
      have hres := modEq_of_modEq_mul hm hrest hmn
      simpa [product_cons] using hres

/-! ## Euler lifting -/

/-- **Euler lifting.** If `a ≡ 1 [MOD phi n]` and `msg` is coprime to `n`,
then `msg ^ a ≡ msg [MOD n]`. This is the Euler-analogue of the Fermat
lifting `pow_modEq_of_modEq_one` in `RSA.lean`: it applies to composite
moduli at the price of requiring the message to be a unit. -/
theorem pow_modEq_euler {n a msg : Nat} (hn : 0 < n) (hc : Nat.Coprime msg n) (h1 : 1 ≤ a)
    (hφ : a ≡ 1 [MOD phi n]) : msg ^ a ≡ msg [MOD n] := by
  have hdvd0 : phi n ∣ a - 1 := dvd_sub_of_modEq hφ h1
  rcases hdvd0 with ⟨k, hk⟩
  have hk' : phi n * k = k * phi n := Nat.mul_comm (phi n) k
  have ha : a = 1 + k * phi n := by
    calc
      a = (a - 1) + 1 := by omega
      _ = (phi n) * k + 1 := by rw [hk]
      _ = k * (phi n) + 1 := by rw [hk']
      _ = 1 + k * phi n := by omega
  have heuler : msg ^ (phi n) ≡ 1 [MOD n] := euler_theorem hc hn
  have heuler' : (msg ^ (phi n)) ^ k ≡ 1 [MOD n] := by
    have hk1 : 1 ^ k ≡ 1 [MOD n] := modEq_of_eq (Nat.one_pow k)
    exact modEq_trans (modEq_pow k heuler) hk1
  have hmain : msg * (msg ^ phi n) ^ k ≡ msg [MOD n] := by
    have h1' : msg * (msg ^ phi n) ^ k ≡ msg * 1 [MOD n] := modEq_mul_left heuler'
    have h2' : msg * 1 ≡ msg [MOD n] := modEq_of_eq (Nat.mul_one msg)
    exact modEq_trans h1' h2'
  have hpow : msg ^ a = msg * (msg ^ phi n) ^ k := by
    rw [ha, ← hk', Nat.pow_add, Nat.pow_mul]
    simp
  exact modEq_trans (modEq_of_eq hpow) hmain

/-! ## The scheme -/

/-- The RSA modulus of a factor list: the product of the factor moduli. -/
def PPN (fs : List PPFactor) : Nat := product (fs.map PPFactor.modulus)

/-- The totient of a factor list: the product of the factor totients. -/
def PPφ (fs : List PPFactor) : Nat := product (fs.map PPFactor.totient)

/-- A public prime-power RSA key: the factor list, the modulus and the
encryption exponent. -/
structure PPRSAPublicKey where
  factors : List PPFactor
  N : Nat
  e : Nat

/-- A private prime-power RSA key: the factor list, the modulus and the
decryption exponent. -/
structure PPRSAPrivateKey where
  factors : List PPFactor
  N : Nat
  d : Nat

/-- Key generation from a factor list and the exponents `e`, `d`. -/
def ppKeyGen (fs : List PPFactor) (e d : Nat) : PPRSAPublicKey × PPRSAPrivateKey :=
  (PPRSAPublicKey.mk fs (PPN fs) e, PPRSAPrivateKey.mk fs (PPN fs) d)

/-- A decryption exponent inverse of `e` modulo the scheme totient `PPφ fs`,
chosen classically via `modInv`. `ppModInv_spec` witnesses the inverse when
`e` is coprime to the totient and `1 < PPφ fs`. -/
noncomputable def ppModInv (fs : List PPFactor) (e : Nat) : Nat := modInv e (PPφ fs)

/-- **Modular inverse specification.** If `e` is coprime to the scheme
totient with `1 < PPφ fs`, then `ppModInv` really inverts `e` modulo it. -/
theorem ppModInv_spec {fs : List PPFactor} {e : Nat} (hc : Nat.Coprime (PPφ fs) e)
    (hφ : 1 < PPφ fs) : e * ppModInv fs e ≡ 1 [MOD PPφ fs] := by
  unfold ppModInv
  exact modInv_spec hc hφ

/-- **Key generation.** If `e` is coprime to the scheme totient
`PPφ fs`, a decryption exponent `d` exists with `e * d ≡ 1 [MOD PPφ fs]`. -/
theorem ppKeygen_inverse_exists {fs : List PPFactor} {e : Nat} (hc : Nat.Coprime e (PPφ fs))
    (hφ : 1 < PPφ fs) : ∃ d, e * d ≡ 1 [MOD PPφ fs] := by
  have hc' : Nat.Coprime (PPφ fs) e := by
    simpa [Nat.Coprime, Nat.gcd_comm] using hc
  exact cop_mod_inv_exists hc' hφ

/-- **Prime-power RSA correctness.** If the factor moduli are pairwise
coprime and `e * d ≡ 1 [MOD PPφ fs]`, then decryption inverts encryption on
every message coprime to the modulus `PPN fs`. The per-factor congruences
come from the Euler lifting, and the multi-modulus CRT assembles them. -/
theorem rsa_correctness_pp {fs : List PPFactor} {e d : Nat}
    (hpair : PairwiseCoprime (fs.map PPFactor.modulus))
    (he₁ : 1 ≤ e) (hd₁ : 1 ≤ d) (hed : e * d ≡ 1 [MOD PPφ fs]) :
    ∀ msg, Nat.Coprime msg (PPN fs) →
      decrypt (RSAPrivateKey.mk (PPN fs) d) (encrypt (RSAPublicKey.mk (PPN fs) e) msg)
        ≡ msg [MOD PPN fs] := by
  intro msg hcop
  have hed1 : 1 ≤ e * d := by
    have h0 : 0 < e * d := Nat.mul_pos (by omega) (by omega)
    omega
  have hperms : ∀ f ∈ fs, msg ^ (e * d) ≡ msg [MOD f.modulus] := by
    intro f hf
    have hφf : e * d ≡ 1 [MOD phi f.modulus] := by
      have hfφ : f.totient ∈ fs.map PPFactor.totient := List.mem_map.mpr ⟨f, hf, rfl⟩
      have htd : f.totient ∣ PPφ fs := dvd_product_of_mem (l := fs.map PPFactor.totient) hfφ
      have hdvd0 : PPφ fs ∣ e * d - 1 := dvd_sub_of_modEq hed hed1
      have hdvd : f.totient ∣ e * d - 1 := Nat.dvd_trans htd hdvd0
      have hmod : e * d ≡ 1 [MOD f.totient] := modEq_of_dvd_sub hed1 hdvd
      have hteq : phi f.modulus = f.totient := PPFactor.totient_eq f
      simpa [hteq] using hmod
    have hcf : Nat.Coprime msg f.modulus := by
      have hfm : f.modulus ∈ fs.map PPFactor.modulus := List.mem_map.mpr ⟨f, hf, rfl⟩
      have hfd : f.modulus ∣ PPN fs := dvd_product_of_mem (l := fs.map PPFactor.modulus) hfm
      exact coprime_dvd hfd hcop
    exact pow_modEq_euler (PPFactor.modulus_pos f) hcf hed1 hφf
  have hcr : msg ^ (e * d) ≡ msg [MOD PPN fs] := by
    have hcrt : msg ^ (e * d) ≡ msg [MOD product (fs.map PPFactor.modulus)] := by
      apply modEq_of_product (a := msg ^ (e * d)) (b := msg) (ms := fs.map PPFactor.modulus) hpair
      intro i hi
      rcases List.mem_map.mp hi with ⟨f, hf, hfix⟩
      have hp := hperms f hf
      simpa [hfix] using hp
    simpa [PPN] using hcrt
  have hpowmod : (msg ^ e % PPN fs) ^ d ≡ msg ^ (e * d) [MOD PPN fs] :=
    modEq_trans (modEq_pow d (modEq_mod_eq (msg ^ e) (PPN fs)))
      (modEq_of_eq (Nat.pow_mul msg e d).symm)
  unfold decrypt encrypt
  change ((msg ^ e % PPN fs) ^ d % PPN fs) ≡ msg [MOD PPN fs]
  unfold ModEq
  rw [Nat.mod_mod]
  exact modEq_trans hpowmod hcr

/-- **Factoring reduces to breaking prime-power RSA.** Given the pairwise
coprime factorization of the modulus, the decryption exponent `d` is
available and the private key decrypts every ciphertext with a coprime
message. Hence an adversary who can factor `N` can invert `encrypt`. -/
theorem factoring_implies_rsa_break_pp {fs : List PPFactor} {e d : Nat}
    (hpair : PairwiseCoprime (fs.map PPFactor.modulus))
    (he₁ : 1 ≤ e) (hd₁ : 1 ≤ d) (hed : e * d ≡ 1 [MOD PPφ fs]) :
    ∀ msg, Nat.Coprime msg (PPN fs) →
      decrypt (RSAPrivateKey.mk (PPN fs) d) (encrypt (RSAPublicKey.mk (PPN fs) e) msg)
        ≡ msg [MOD PPN fs] :=
  rsa_correctness_pp hpair he₁ hd₁ hed

/-- **Euler-based two-prime RSA correctness.** For distinct primes `p` and
`q` with `e * d ≡ 1 [MOD phi (p * q)]` — the congruence written against the
*counted* totient `phi (p * q)` rather than the closed form
`(p - 1) * (q - 1)` — decryption inverts encryption on every message coprime
to the modulus `p * q`. The lift comes from Euler's theorem
(`pow_modEq_euler`), so like `rsa_correctness_pp` it requires the message to
be a unit; the totient rewrite `phi_prime_mul` supplies the link between the
counted totient and the two-prime closed form used by `rsa_correctness`. -/
theorem rsa_correctness_phi {p q e d : Nat} (hp : Prime p) (hq : Prime q) (_hneq : p ≠ q)
    (he₁ : 1 ≤ e) (hd₁ : 1 ≤ d) (hed : e * d ≡ 1 [MOD phi (p * q)]) :
    ∀ msg, Nat.Coprime msg (p * q) →
      decrypt (RSAPrivateKey.mk (p * q) d) (encrypt (RSAPublicKey.mk (p * q) e) msg)
        ≡ msg [MOD p * q] := by
  intro msg hcop
  have hed1 : 1 ≤ e * d := by
    have h0 : 0 < e * d := Nat.mul_pos (by omega) (by omega)
    omega
  have hp0 : 0 < p := by
    have hp1 : 1 < p := hp.1
    omega
  have hq0 : 0 < q := by
    have hq1 : 1 < q := hq.1
    omega
  have hN : 0 < p * q := Nat.mul_pos hp0 hq0
  have hpow : msg ^ (e * d) ≡ msg [MOD p * q] := pow_modEq_euler hN hcop hed1 hed
  have hpowmod : (msg ^ e % (p * q)) ^ d ≡ msg ^ (e * d) [MOD p * q] :=
    modEq_trans (modEq_pow d (modEq_mod_eq (msg ^ e) (p * q)))
      (modEq_of_eq (Nat.pow_mul msg e d).symm)
  unfold decrypt encrypt
  change ((msg ^ e % (p * q)) ^ d % (p * q)) ≡ msg [MOD p * q]
  unfold ModEq
  rw [Nat.mod_mod]
  exact modEq_trans hpowmod hpow

end Multiplicity.RSA
