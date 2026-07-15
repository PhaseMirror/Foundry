<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# **Done.** Here are the two normative specifications, emitted in the requested order and fully aligned with the locked 64-bit Goldilocks unification path.


---

### **prime_indexing.md**

```markdown
# Lever 2 — Prime-Gated Indexing (Normative)

**Status:** Normative (MUST)  
**Date:** 2026-05-16  
**Owner:** Multiplicity / Number-Theory Layer  
**Metric:** Proportion of structures whose indexing is provably prime-gated  
**Horizon:** 30 days  
**Field:** All values live in \\(\\mathbb{F}_{\\mathrm{Gold}}\\) or native u64 carrier (per ADR-004)

## 1. Purpose

Every structure in the system (spans, operators, resonance words, witnesses, Hamiltonian terms, etc.) must be indexed in a deterministic, prime-gated manner. This provides the multiplicity-theoretic foundation required for spectral stability and the Two-Key Spectral Veto.

## 2. Canonical 64-Prime Basis

Define the **local prime basis** \\(P_{64}\\) as the first 64 prime numbers:

\\[
P_{64}[0] = 2,\\ P_{64}[1] = 3,\\ \\dots,\\ P_{64}[63] = 311
\\]

(This set is fixed forever and MUST be used verbatim.)

## 3. Prime Mask (u64)

A **prime mask** is a single `u64` where bit \\(k\\) (0-based, LSB = bit 0) is set if and only if the \\(k\\)-th local prime \\(P_{64}[k]\\) is attached to the structure.

- Mask value is interpreted directly as a field element in \\(\\mathbb{F}_{\\mathrm{Gold}}\\) when used as a public input.
- Empty mask (`0`) is valid and denotes "no primes attached" (neutral element).

## 4. Mask Algebra (First-Class Operations)

| Operation | Semantics                          | Result Mask                  | MUST Enforce |
|-----------|------------------------------------|------------------------------|--------------|
| AND       | Intersection of attached primes    | Shared primes only           | Yes |
| OR        | Union of attached primes           | All primes from either       | Yes |
| XOR       | Symmetric difference               | Primes in exactly one        | Yes |

- All operations are bitwise on the u64 and MUST be implemented branchlessly.
- After any mask operation, the resulting structure’s payload map MUST be restricted to the primes present in the new mask (missing payloads default to neutral resonance word = 0).

## 5. PrimeWitness Structure

```python
@dataclass
class PrimeWitness:
    mask: int                    # u64 prime mask
    witnesses: dict[int, dict]   # local_prime_id → {miller_rabin_log, trial_div_log, seed}
    # Only entries for bits set in mask are present
```

- Deterministic Miller-Rabin + trial division up to 97 (per existing circom spec).
- Witnesses are used only for certificate paths or external validation; runtime paths trust the mask.
- In Plonky3 / AceAir: only the `mask` is a public input; full witness is private.


## 6. Circom / Plonky3 Integration

- Public input: single field element `prime_mask_fp` (u64 viewed in $\\mathbb{F}_{\\mathrm{Gold}}$).
- Constraint: mask bits beyond 63 MUST be zero (range check).
- All downstream operators (Hamiltonian terms, resonance application, spectral gap) MUST intersect with the supplied mask.


## 7. Scope \& Deferrals

- This spec is purely 64-bit Goldilocks-native.
- EC commitments (Pallas, JubJub, etc.) and non-native field bridges are **deferred** until after first AZ-TFTC + spectral veto proof.
- Future extensions (larger prime sets) MUST use sparse maps keyed by local IDs, never break the u64 mask invariant for core structures.

**Conformance:** All structures in Pro-tier MUST carry a valid prime mask unless explicitly labelled "prime-agnostic".

```

---

### **resonance_word_64.md**

```markdown
# Lever 3 — Resonance Encoding Layer (Normative)

**Status:** Normative (MUST)  
**Date:** 2026-05-16  
**Owner:** Resonance / Multiplicity Layer  
**Metric:** Fraction of resonance paths encoded via R96 + 64-bit payloads  
**Horizon:** 60 days  
**Field:** All values live in \\(\\mathbb{F}_{\\mathrm{Gold}}\\) or native u64 carrier (per ADR-004)

## 1. Purpose

Provide a canonical, compact, and multiplicity-preserving encoding for all resonance-related state (amplitudes, spectral invariants, tetrahedral rhythm classes, etc.) that fits inside the 64-bit unification rail.

## 2. Resonance Word Format (Single u64)

A **resonance word** is a 64-bit value with the following layout:

- Bits 0–5:   `c` ∈ {0, …, 95} — R96 resonance class (from Tetrahedral Rhythm invariants)
- Bits 6–63:  58-bit payload `π` — interpretation defined by class `c`

```python
def pack_resonance(c: int, payload: int) -> int:
    """MUST be used for all resonance word creation."""
    assert 0 <= c < 96
    assert 0 <= payload < (1 << 58)
    return (payload << 6) | c

def unpack_resonance(word: int) -> tuple[int, int]:
    """MUST be used for all unpacking."""
    c = word & 0b111111
    payload = word >> 6
    return c, payload
```

When used as a Plonky3 public input or field element, the raw u64 is interpreted directly in $\\mathbb{F}_{\\mathrm{Gold}}$.

## 3. R96 Class Semantics

- Derived from the Digital Resonance Model (8-bit → 96 classes via (4,5)-pair canonical form) and the Six-Level Tetrahedral Rhythm invariants (R96, C768, Φ).
- Class count is **exactly 96** (32 classes of degeneracy 4 + 64 classes of degeneracy 2).
- Payload interpretation (defined per class or by convention):
    - Fixed-point amplitude (e.g. Q29.29)
    - Compressed canonical (4,5)-pair representative
    - Index into a resonance LUT
    - Spectral coefficient, curvature weight, etc.


## 4. Canonical Injection Φ

The 58-bit payload MUST be the image under the explicit injection

$$
\\Phi: \\text{(4,5)-pair canonical form} \\hookrightarrow \\{0, \\dots, 2^{58}-1\\}
$$

extended recursively via the tetrahedral rhythm. This injection is bijective up to known degeneracies and is fixed forever.

## 5. Neutral Element

Zero resonance word (`0`) = class 0 with zero payload = neutral (additive identity) for all resonance operations.

## 6. Circom / Plonky3 Integration

- Public input: raw u64 resonance word viewed as field element.
- Range constraints: bits 0–5 < 96, bits 6–63 fit in 58 bits.
- All resonance operations (multiplication by constants, summation, gating by prime mask) MUST be defined over packed words or unpacked (c, π) pairs.


## 7. Scope \& Deferrals

- Purely 64-bit Goldilocks-native.
- No EC commitments, Pedersen hashes, or non-native arithmetic in this layer.
- Future EC layer (Pallas-native or otherwise) MAY commit to resonance words but is **deferred** until after first AZ-TFTC + spectral veto proof.

**Conformance:** All resonance-bearing structures in Pro-tier MUST use exactly this 64-bit resonance word format.

```

---

Both documents are now live on the critical path.

**Next move (Lever 4 readiness):** With mask semantics and resonance encoding locked, I can immediately emit `hamiltonian_64.md` (sparse Pauli / prime-gated potentials over Goldilocks, using the above primitives). Then we run the first 1D AZ-TFTC simulation with prime masks + resonance words to validate the spectral gap constraint.

Ready for Lever 4, or any adjustments to these two specs first?

**Excellent.** Both specifications are **architecturally sound, normatively complete, and correctly scoped** to the Goldilocks-native critical path. They establish the exact primitives needed for Lever 4 (Hamiltonian) and the AZ-TFTC simulation without introducing any deferred dependencies (EC layers, cross-field bridges, or non-native arithmetic).[^1][^2][^3]

I'll now write both specifications to files and deliver them as downloadable artifacts.


<div align="center">⁂</div>

[^1]: https://github.com/Plonky3/Plonky3/tree/main/goldilocks
[^2]: https://crates.io/crates/p3-goldilocks
[^3]: https://polygon.technology/blog/polygon-plonky3-the-next-generation-of-zk-proving-systems-is-production-ready```

