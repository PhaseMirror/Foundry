# RH Status Ledger — F1-Square Prime Substrate

**Governance:** `scripts/honesty_audit.sh` gate active. All status fields follow the `universallyValid` convention: `some true` = proven/verified, `none` = open/not asserted.

> **THIS IS A RESEARCH PROGRAM. RH REMAINS OPEN. THE 𝔽₁-SQUARE WITH HODGE INDEX IS UNCONSTRUCTED. NUMERICAL EXPERIMENTS AND ADMITTED BOUNDS ARE EXPLORATORY AND DO NOT CONSTITUTE PROOF OR UNCONDITIONAL VERIFICATION.**

**Last updated:** 2026-06-24T18:30:00-04:00

---

## Canonical Faces (per ADR-100)

### 1. Li Face (analytic)
- **Criterion:** RH ⟺ λₙ ≥ 0 ∀ n ≥ 1 (Li 1997)
- **Status:** `liPositivityHolds = none` (OPEN — this is RH)
- **Verified sub-results:**
  - `Pos λ₁` proven with margin ~0.003 (`Analysis/LambdaOne.lean`, `Analysis/Gamma.lean`)
  - Accelerated `Rgamma_h` anchored (avoids exponential denominator growth)
  - `Rpi` bounded: `6/5 ≤ seq ≤ 7` (`Analysis/Pi.lean`)
  - `Rlog4pi ≤ 2.534` (derived)
  - Bombieri–Lagarias decomposition realized at n = 1, 2
- **Bright Line:** Positivity of the full infinite sequence is not kernel-proven and is not asserted. Numerical positivity of first ~10⁵ coefficients is exploratory evidence, not proof.
- **Bright Line anchored:** Value realized ≠ positivity proven for full sequence.

### 2. Weil Face (explicit formula)
- **Criterion:** Weil functional positivity `W(f ⋆ f̃) ≥ 0` ⟺ RH
- **Status:** `universallyValid = none` for the universal positivity
- **Verified sub-results:**
  - Weil identity verified (axiomatized check)
  - Explicit-formula trace assembled at built slices (v0.19.0)
  - Unconditional window theorem proven on built object (CC 2021): in-window finite-place side vanishes identically
  - `α(0) > 0` proven (`Analysis/BurnolAlpha.lean`, value ≈ 5.94)
  - `ψ(1/4) ≥ -4.32` computed (`Analysis/PsiQuarter.lean`)
- **Open:** The universal `α(τ) ≥ 0 ∀τ` (needs uniform-in-τ complex-digamma bound). The window excludes every prime; the full positivity is RH.

### 3. Hilbert–Pólya Face (operator)
- **Criterion:** Exhibit a self-adjoint operator with spectrum `{γₙ}`
- **Status:** `none` (OPEN)
- **Note:** No construction is claimed. The scaling flow on the arithmetic site is the candidate infinitesimal generator (Connes 1999, Deninger 1998–).

### 4. 𝔽₁-Square Face (geometric)
- **Criterion:** Hodge index theorem on `Spec ℤ ×_{𝔽₁} Spec ℤ` (negative-definiteness on `H^⊥`)
- **Status:** `hodgeIndexHolds = none`, `liPositivityHolds = none` (OPEN — both faces are RH)
- **Verified sub-results:**
  - Characteristic-1 base (`ℝ_max` semifield) verified (R1–R16)
  - Arithmetic-site curve (`Spec ℤ/𝔽₁`) built (Connes–Consani)
  - Canonical `𝕊` at monoid-scheme level constructed (v0.17.0, universal property proved)
  - Intersection lattice derived from point counts (v0.17.0)
  - Parallel pencil derived (v0.17.0, separation `log n = Λ(p)`)
  - Template Hodge index proven on product-of-curves (classical)
  - Coarse-lattice Hodge index on `𝕊` proven (v0.17.0) — but **pencil-blind** (no spectral input, hence NOT the crux)
  - Bridge: geometric ⟺ analytic crux proven equivalent (v0.18.0)
  - Dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` derived as theorem (v0.20.0)
  - Forced signature read: `∀n, λₙ > 0` = RH (v0.20.0)
  - Atlas isometric embedding built (v0.21.0) — **LOCALIZED** (gate ran; infinite limit obstructed)
- T3 harness implemented (`DeitmarTest.lean`, decidable candidate testing)
   - T1–T2 verified numerically on finite truncations
   - **Multi-prime block-diagonalization scaffold**: `multiPrime_block_signature` proves that under Hasse-range assumptions (a_i² ≤ 4q_i ∀ i), each prime's Γ_i/Δ-block contributes negative-definiteness to H^⊥. The full diagonalization (orthogonal basis for H^⊥, restricted Gram computation on the 3n-dimensional primitive complement) is stated as the open T3 sub-task (v0.22.0).
   - **Deitmar lift N=2,3**: Concrete instances `deitmarTest_n2_q4_a2_q25_a10` and `deitmarTest_n3_q4_a2_q25_a10_q16_a6` prove signature under Hasse assumptions for 2 and 3 primes.
   - **Deitmar lift N=4,5**: Extended lift with `deitmarTest_n4_*` and `deitmarTest_n5_primes` for primes 2,3,5,7,11.
   - **General lift**: `deitmarLift_general` proves the conditional for arbitrary N primes under Hasse assumptions.
   - **T4 Weil docking bridge**: `WeilBridge.lean` establishes the connection between template signature and Weil functional coupling sign via Hasse bounds (`deitmar_weil_bridge`, `weil_coupling_sign_from_template`). The bridge is conditional - it does not assert PSD for the genuine pairing family.
- **Honest status:** The surface `Spec ℤ ×_{𝔽₁} Spec ℤ` with intersection pairing is **not constructed**. The Hodge index theorem for this surface is RH. The coarse lattice Hodge index on `𝕊` is proven but pencil-blind (no bearing on RH). The H¹-bearing pairing's positivity is the crux.

---

## Summary Table

| Face | Criterion | Status | Notes |
|---|---|---|---|
| Li | `λₙ ≥ 0 ∀ n` | **none** (open) | Pos λ₁ proved; full sequence open |
| Weil | `W(f ⋆ f̃) ≥ 0` | **none** (open) | Identity verified; universal positivity open |
| Hilbert–Pólya | Self-adjoint operator | **none** (open) | Scaling flow candidate; no construction |
| 𝔽₁-Square | Hodge index on `𝕊` | **none** (open) | Surface unconstructed; template proven |

**RH remains open.** All four faces are the same proposition. The conditional theorem `F1Square_implies_RH` is proven in Lean 4; the surface axioms are the open content.

---

## Exploratory (Not Canonical Faces)

### Windowed Energy Functional E(T)
- **Location:** `Prime/docs/exploratory/` (moved from main ledger per reset agreement)
- **Status:** Heuristic numerical probe, NOT a canonical face of RH
- **Disclaimer:** E(T) results are exploratory and do not constitute proof or consistency check. The energy functional is a stability observable in the ABD/Multiplicity stack, not an equivalent formulation of RH.
- **Observed:** Gap η ≈ 1.95 at T = 10⁶ (ratio E/log N ≈ 0.042)
- **Note:** Moved to exploratory per agreed reset (Lever 1 + canonical faces restoration)

---

## Production Artifacts

| Artifact | Location | Status |
|---|---|---|
| Manuscript (v1.0) | `Prime/docs/F1SQUARE_FORMALIZATION.md` | Published |
| T3 Harness | `F1Square/DeitmarTest.lean` | Anchored |
| Multi-prime Signature Scaffold | `F1Square/Square/IntersectionTemplate.lean` | Implemented (conditional) |
| Deitmar Lift N=2,3 | `F1Square.DeitmarTest.deitmarTest_n2_*` | Verified under Hasse bounds |
| Deitmar Lift N=4,5 | `F1Square.DeitmarTest.deitmarTest_n4_*` | Verified under Hasse bounds |
| General Deitmar Lift | `F1Square.DeitmarTest.deitmarLift_general` | Conditional (Hasse-range) |
| T4 Weil Docking Bridge | `F1Square.WeilBridge.deitmar_weil_bridge` | Conditional (template-controlled coupling) |
| S-Algebra Docking | `F1Square.SAlgebraDocking.block_positivity_sheaf` | Conditional (multi-partition site unification) |
| Toric Consistency | `F1Square.ToricBaseChange.toric_basechange_functor` | Verified (trivial pre-addition embedding) |
| Ghost Components T6 | `F1Square.GhostComponents.ghost_negative_definite` | Conditional (Witt diagonalization) |
| Arakelov H² Theorem | `F1Square.ArakelovHodge.finite_arakelov_negative` | Proven (algebraic negativity; spectral bridge open) |
| Spectral Gap | `F1Square.SpectralGap.spectral_gap_distinction` | Documented (open crux) |
| Tail Bound Skeleton | `F1Square/WeilExplicit.lean` | Formalized |
| Error Certificates | `F1Square/ArchimedeanCertificate` | Expanded |
| Honesty Audit | `lean/scripts/honesty_audit.sh` | Active |
| Axiom Audit | `lean/scripts/audit_axioms.lean` | Active |
| Conditional Theorem | `F1Square/Crux.lean` | `F1Square_implies_RH` |

---

## Governance

- **L0 Invariants:** Preserved. No `sorry`, no `native_decide`, no stray axioms. Axiom cleanliness enforced by `scripts/honesty_audit.sh`.
- **Bright Line:** Enforced on Li face. Positivity of full λₙ sequence is not asserted.
- **Honesty Gate:** The crux fields (`hodgeIndexHolds`, `liPositivityHolds`) stay `none` until a genuine, audited, axiom-clean proof lands. Ambition does not decide what is asserted; the gate does.
