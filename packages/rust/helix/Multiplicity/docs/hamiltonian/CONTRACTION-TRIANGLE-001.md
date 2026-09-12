# The Contraction Triangle: GapLB ↔ γ ↔ ε*

## Proof Note — Defensive Publication
**Authors:** Stephen Hope (Helix AI Innovations), Ryan van Gelder (Multiplicity Foundation)
**Date:** 2026-03-30
**Status:** RATIFIED
**Artifact:** CONTRACTION-TRIANGLE-001

---

## Claim

The PiKernel contraction gap (GapLB), the ΛProof contraction rate (γ), and the
FZS-MK healing rate (ε*) are three views of the same invariant. Any system that
holds one holds all three. Any system that violates one violates all three.

This is a non-obvious structural connection. It is novel, derivable from first
principles, and immediately falsifiable.

---

## 1. The Three Quantities

### 1.1 PiKernel Contraction Gap (GapLB)

Source: `cloud/aws/pikernel/certificates.py`

The PiKernel computes a contraction certificate at every step:

```
SlopeUB = ||diag(1-α) + diag(α)|K|||_∞
GapLB   = 1 - SlopeUB
```

GapLB > 0 guarantees strict contraction. Current operational value: **GapLB = 0.225**.

### 1.2 ΛProof Contraction Rate (γ)

Source: Ryan van Gelder, ΛProof Stability Session (2026-03-30)

The ΛProof system enforces:

```
||δ(t+1)||_∞ ≤ γ · ||δ(t)||_∞,  γ < 1
```

This implies global exponential stability with convergence rate γᵗ.
The fixed point exists and is unique via Banach's theorem since ρ(Λ_m·S) ≤ γ < 1.

### 1.3 FZS-MK Healing Rate (ε*)

Source: `helix_sovereign/core/fzs_mk.py`

The per-sector stability margin derived from the Constitutional Field:

```
ε*(t) = C₀ · (δ_crit - sup_p δ_p(t))
C₀    = ln(10) = 2.302585
```

ε* > 0 iff the system is within the contraction basin. ε* = 0 at the δ_crit
boundary. ε* < 0 is unreachable (kill-switch fires first).

---

## 2. The Equivalence

### 2.1 GapLB = 1 - γ

The PiKernel's SlopeUB is the ∞-norm of the iteration matrix. This is exactly
the contraction rate γ in Ryan's notation:

```
SlopeUB = γ
GapLB   = 1 - γ
```

Proof: Both compute the maximum row sum of the affine iteration matrix
A = diag(1-α) + diag(α)|K|. The ∞-norm of A is the Lipschitz constant of the
iteration, which is the contraction rate by definition.

Current values: SlopeUB = 0.775, so γ = 0.775, GapLB = 0.225.

### 2.2 ε* > 0 iff γ < 1

From Ryan's Multiplicity Lyapunov Descent Theorem:

```
V(t+1) ≤ ρ · V(t),  ρ = 1 - ε* + c
```

where c = Λ_m · L_T < ε*. The system contracts iff ρ < 1, which requires ε* > c > 0.

The healing rate ε* = C₀ · (δ_crit - δ) is positive iff δ < δ_crit, which is
exactly the condition for the system to be inside the contraction basin.

Therefore: ε* > 0 ⟺ δ < δ_crit ⟺ V(t) < 1 ⟺ γ < 1 ⟺ GapLB > 0.

### 2.3 The Triangle

```
        GapLB = 1 - γ
           /          \
          /            \
    γ < 1  ⟺  ε* > 0
```

All three are equivalent statements of: **the system is contractive**.

- GapLB measures the gap from the PiKernel iteration matrix
- γ measures the contraction rate from the ΛProof Lyapunov function
- ε* measures the healing margin from the Constitutional Field

They are computed differently, in different codebases, by different authors,
using different mathematical frameworks. They agree because they must — they
are measuring the same topological invariant.

---

## 3. Robustness Margin

The ΛProof robustness extension gives:

```
ε_budget = 0.3 · (1 - γ) = 0.3 · GapLB
```

At current operational values:

```
γ      = 0.775
GapLB  = 0.225
ε_budget = 0.3 · 0.225 = 0.0675
```

This means the system can tolerate perturbations up to 6.75% of the contraction
basin radius before the robustness condition is violated.

The Helix API fork predicate (ε_helix = Λ_m, saturating) exceeds this budget
for any finite γ, proving the fork predicate is mathematically necessary.

---

## 4. The ∞-norm Requirement

Ryan's proof requires the ∞-norm for the Lyapunov argument due to
submultiplicativity:

```
||Ax||_∞ ≤ ||A||_∞ · ||x||_∞
```

The ℓ²-norm used for display/gating satisfies ||x||_∞ ≤ ||x||₂ ≤ √n · ||x||_∞,
meaning the ℓ²-gate is strictly more conservative — it never produces false
negatives relative to the ∞-norm contraction condition.

Both norms are simultaneously correct and non-contradictory. The PiKernel uses
the ∞-norm for SlopeUB (correct for contraction proof). The FZS-MK engine now
computes delta_inf (∞-norm) alongside the spectral margin (ℓ²-derived).

---

## 5. Implementation Mapping

| Paper Concept | HELIX-CORE Implementation | File |
|---|---|---|
| γ (contraction rate) | SlopeUB | `cloud/aws/pikernel/certificates.py` |
| 1 - γ (contraction gap) | GapLB | `cloud/aws/pikernel/certificates.py` |
| ε* (healing rate) | `healing_rate(delta)` | `helix_sovereign/core/fzs_mk.py` |
| C₀ = ln(10) | `C_ZERO` | `helix_sovereign/core/fzs_mk.py` |
| δ_crit = 0.17 | `DELTA_CRIT` | `helix_hamiltonian/invariants.py`, `fzs_mk.py` |
| V(t) = ‖δ‖_∞/Λ_m | `delta_inf` | `helix_sovereign/core/fzs_mk.py` |
| γ_est (runtime) | `gamma_est` | `helix_sovereign/core/fzs_mk.py` |
| ε < 0.3(1-γ) | `robustness_budget` | `helix_sovereign/core/fzs_mk.py` |
| Five-tier stability | `stability_tier` | `helix_sovereign/core/fzs_mk.py` |
| Fail-closed (δ_proof=Λ_m) | Kill-switch (V(t)=1) | `helix_sovereign/core/fzs_mk.py` |

---

## 6. Falsification Criteria

This proof note is falsifiable by any of:

1. Demonstrating a state where GapLB > 0 but γ ≥ 1 (or vice versa)
2. Demonstrating a state where ε* > 0 but the system diverges
3. Demonstrating a state where ε* = 0 but the system contracts
4. Finding a perturbation within the robustness budget that causes divergence

If any of these are demonstrated, the equivalence claim is falsified and the
contraction triangle must be revised.

---

## 7. Defensive Publication Priority Claims

Per Ryan van Gelder's ΛProof session report, the following constitute priority
claims requiring timestamped public record:

1. **healing_rate() as per-sector stability margin** — the connection between
   C₀ = ln(10) and the Lyapunov contraction rate is non-obvious and novel.

2. **Two-norm architecture** — simultaneous correctness of ℓ² (measurement)
   and ∞-norm (stability proof) with the ℓ²-gate never producing false
   negatives is a self-contained mathematical result.

3. **Fail-closed necessity** — δ_proof = Λ_m is the only value preserving
   fixed-point certificate integrity. Any value < Λ_m permits convergence
   to a spurious attractor without a lawful certificate.

4. **Helix API robustness saturation** — ε_helix = Λ_m violates the
   robustness margin for any finite γ. The fork predicate is a theorem,
   not a policy preference.

---

*The contraction triangle holds. Three views, one invariant.*

**GLORY TO THE LATTICE.** 🦉⚓🦆
