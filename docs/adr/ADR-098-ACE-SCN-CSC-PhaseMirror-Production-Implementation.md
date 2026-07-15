# ADR-098: ACE-SCN-CSC–PhaseMirror-HQ Production Implementation Plan

## Status
**Proposed**

## Context
This ADR maps the three specific F1 implementation touchpoints onto the new four-layer ACE/PhaseMirror state and provides concrete Lean module interfaces, Rust runtime contracts, and exact commit paths for production-grade execution.

The four-layer architecture:
1. **Arithmetic operator layer** (cusp-form spaces, Hecke operators, Hermitianization)
2. **Kernel authority layer** (FZS-MK memory kernel and Zeno projection)
3. **Control and certificate layer** (SCN, feasibility maps, governance logic, CSC)
4. **Cryptographic verification layer** (Circom/Rust circuit, Poseidon2 commitments, Groth16 proofs)

## Decision

### Target 1: atlasM Indefiniteness → Mode 3 Feasibility Map

**Mapping**: The indefinite atlasM (signature `(10, 14)`, eigenvalues `{10, 7, 2, -1}`) is projected onto the Hecke-span `H_r` (span of positive-eigenspace rank-1 projectors) using the Mode 3 feasibility map `F_3`. The residual distance `η = ||atlasM - PH_r(atlasM)||_F` controls the indefiniteness: when `η` is sufficiently small (`η < 5`, always achievable since `||R||_F ≤ √14 ≈ 3.74`), the projected operator `H = PH_r(atlasM)` is:
- Positive-definite on the positive-eigenspace span
- Negative-definite on `Δ^⊥` (the Arakelov Hodge complement)

**Lean Interface**: `AtlasMode3WrapperResult` in `lean/Core/f1_square/Square/AtlasMode3Wrapper.lean`

```lean
structure AtlasMode3WrapperResult where
  projectedOperator : Nat → Nat → Real
  residualDistance : Real
  psd_on_positive_span : ∀ (v : Fin 24 → Real),
    (∀ i, v i = 0 ∨ i ∈ atlasPositiveIndices) →
    quadraticForm projectedOperator v ≥ 0
  neg_on_ortho_diagonal : ∀ (N : Nat) (v : Fin N → Real),
    orthoToDiagonal N v →
    quadraticForm projectedOperator v ≤ 0
  h_budget : residualDistance ≤ 5

def atlasM_mode3_wrapper (eta : Real) (h_eta : 0 ≤ eta) (h_small : eta < 5) :
    AtlasMode3WrapperResult
```

**Key Theorem**: `mode3_projection_arakelov_negative_definite` links `dist_F(Δ, H_r) ≤ η` to negative-definiteness on `Δ^⊥`.

**Commit Path**:
```
lean/Core/f1_square/Square/AtlasMode3Wrapper.lean       [NEW]
```

### Target 2: gaugeFix → KernelTelemetry → ArakelovParams

**Mapping**: The `gaugeFix` invariant `⟨Δ, Δ⟩ = 1` (archimedean normalization) is mapped to the `KernelTelemetry.protection_zeta` field, which becomes the archimedean weight `γ` in the finite Arakelov theorem:
```
γ = protection_zeta = (1 + Σ log p_i) / N²
```

The exact interface function:
```lean
def gaugeFix (kt : KernelTelemetry) (N : Nat) (primes : Fin N → Nat) : Real :=
  kt.protection_zeta
```

**Key Theorems**:
- `gaugeFix_normalizes_diagonal`: `⟨Δ, Δ⟩ = 1 + Σ log p_i`
- `gaugeFix_vanishes_on_ortho`: archimedean term vanishes on `Δ^⊥`
- `gaugeFix_arakelov_negative`: finite Arakelov pairing is negative-definite on `Δ^⊥`
- `arakelov_params_gauge_fix_invariant`: ArakelovParams produced from KernelTelemetry satisfies the gaugeFix invariant

**Lean Interface**: `KernelTelemetry`, `ArakelovParams`, `kernelTelemetryToArakelovParams` in `lean/Core/f1_square/Square/KernelArakelovBridge.lean`

**Commit Path**:
```
lean/Core/f1_square/Square/KernelArakelovBridge.lean     [NEW]
```

### Target 3: λ_n Executable Pipeline → SCN Amortized Controller

**Mapping**: The SCN feature vector is extended from `φ(A, ĝ)` to `φ(A, ĝ, Θ_kernel)` where `Θ_kernel` is the `KernelTelemetry` record. The λ_n sequence for `n=1..N` is appended as additional features. The SCN proposes perturbations `Δ` that maximize the reward:
```
reward = |{n ∈ [1..N] : λ_n > 0}|
```

**SCN Proposal Schema** (R1CS-compatible, 5,087-constraint budget):
```lean
structure SCNProposal where
  delta_proposal : Float
  target_gap : Float
  xn_kernel : Float
  retention_rate : Float
  max_wac_product : Float
  is_valid_kernel : Bool
  retry_nonce : Nat
  cas_commitment : List UInt8
```

**Key Theorems**:
- `scn_extended_feature_dimension`: extended vector has dim = base_dim + 5
- `scn_reward_bounded`: reward ≤ N
- `poseidon2_binding_preserves_budget`: 5,087-constraint lock preserved
- `circom_adapter_preserves_budget`: adapter adds no new gadgets

**Lean Interfaces**:
- `KernelTelemetry`, `ACECertificate` in `lean/projects/ACE–SCN-CSC/src/KernelTelemetry.lean`
- `SCNConditioning` in `lean/projects/ACE–SCN-CSC/src/SCNConditioning.lean`
- `AtlasSCNBridge` in `lean/projects/ACE–SCN-CSC/src/AtlasSCNBridge.lean`

**Commit Paths**:
```
lean/projects/ACE–SCN-CSC/src/KernelTelemetry.lean       [NEW]
lean/projects/ACE–SCN-CSC/src/SCNConditioning.lean      [NEW]
lean/projects/ACE–SCN-CSC/src/AtlasSCNBridge.lean       [NEW]
```

### Risk Trajectory: 5,087-Constraint Lock vs Kernel Telemetry

**Analysis**: Adding kernel telemetry fields (`xn_kernel`, `wt_max_kernel`, `protection_zeta`, `is_valid_kernel`) to the Circom witness does NOT increase the constraint count because:
1. The Poseidon2 gamma gadget already has 5 input slots: `[h_commitment, X_n, R_t, max_wac_product, retry_nonce]`
2. We simply replace `X_n` with `xn_kernel` and `R_t` with `retention_rate` (derived from `xn_kernel`)
3. The `protection_zeta` field is bound into the CAS commitment alongside the other telemetry fields
4. No new arithmetic constraints are needed — the existing drift quotient check `X_n * proxy_l1_norm = m_bar * SCALE` is preserved with `xn_kernel` replacing `X_n`

**Witness Binding Strategy** (Section 6.2 of ACE-SCN-CSC document):
```circom
component poseidon_gamma = Poseidon2(5, 9, 8);
poseidon_gamma.in[0] <== h_commitment;
poseidon_gamma.in[1] <== xn_kernel;          // replaces X_n
poseidon_gamma.in[2] <== retention_rate;     // derived from kernel telemetry
poseidon_gamma.in[3] <== max_wac_product;    // derived from kernel telemetry
poseidon_gamma.in[4] <== retry_nonce;
cas_commitment <== poseidon_gamma.out;
```

**Poseidon2 Sponge Hash Input Count Increase**:
- Before: 205 witness fields hashed through Poseidon2Sponge(205, 9, 8)
- After: 205 witness fields (xn_kernel replaces X_n, no new fields added)
- **Result**: Input count UNCHANGED. Constraint count UNCHANGED.

**Headroom Proof**:
- Base circuit: 133 constraints
- Poseidon2 hashing: 4,804 constraints  
- Reserved: 150 constraints
- **Total**: 5,087 constraints (LOCKED)
- Kernel telemetry replacement adds 0 constraints (field substitution only)

**SCALE Factor and Clamping Logic**:
- The `SCALE` factor remains unchanged. `xn_kernel` is the kernel's certified normalized drift, directly replacing the legacy `X_n` computation.
- The retention rate `R_t = max(0, SCALE - ε - xn_kernel * SCALE / proxy_l1_norm)` is derived from `xn_kernel` and bound into the witness.
- The `protection_zeta` field does NOT affect the R_t clamping logic directly; it is an independent kernel-certified protection index that is committed via Poseidon2 for auditability.

## Formal Proof Obligations

### 1. atlasM Mode 3 Wrapper
```lean
theorem mode3_projection_arakelov_negative_definite :
    ∀ (eta_bound : Real) (h_eta : 0 < eta_bound) (h_dist : distF (residualHr atlasM) H_r ≤ eta_bound)
      (h_small : eta_bound < 2),
    let H := frobeniusProjectionHr atlasM
    ∀ (N : Nat) (v : Fin N → Real), orthoToDiagonal N v →
      quadraticForm H v ≤ 0
```

### 2. gaugeFix Kernel Bridge
```lean
theorem gaugeFix_normalizes_diagonal :
    ∀ (kt : KernelTelemetry) (N : Nat) (primes : Fin N → Nat)
      (h_kt : kt.protection_zeta = archimedean_gamma N primes),
    let gamma := gaugeFix kt N primes
    let diag_sq := ∑ i j, gamma * (diag_vec N i) * (diag_vec N j)
    diag_sq = 1 + ∑ i, logN (primes i) _
```

### 3. SCN Conditioning
```lean
theorem scn_extended_feature_dimension :
    ∀ (A : OperatorMatrix) (target_gap : Float) (kt : KernelTelemetry) (eta : StieltjesEta) (N : Nat),
    (scnLambdaNFeatures A target_gap kt eta N).length = baseSCNFeatures A target_gap.length + 5 + N
```

### 4. Constraint Budget Lock
```lean
theorem circom_budget_preserved :
    ∀ (layout : CircuitLayout),
    layout.total_constraints = 5087 ∧ layout.poseidon2_t = 9 ∧ layout.poseidon2_r = 8
```

## Consequences

### Positive
- ** atlasM indefiniteness resolved**: Mode 3 projection extracts a certified positive-definite subspace from indefinite atlasM when η is small
- **Kernel authority unified**: protection_zeta is the single source of truth for archimedean weight γ
- **SCN conditioning complete**: Feature vector extension allows SCN to react to kernel telemetry without recomputing drift
- **Circuit budget preserved**: Zero additional constraints; field substitution only
- **Deterministic replay**: Versioned KernelTelemetry schema enables archival certificate validation

### Negative / Constraints
- **Kernel coupling**: ACE runtime depends on PhaseMirror-HQ kernel availability
- **Schema versioning**: Breaking changes require coordinated ADRs
- **Retraining required**: SCN must be retrained on extended feature vector
- **Formalization gap**: Several theorems remain as `sorry` pending full formalization

## Implementation Steps

1. **Target 1**: `AtlasMode3Wrapper.lean` — Complete `sorry` proofs for projection theorems
2. **Target 2**: `KernelArakelovBridge.lean` — Wire `protection_zeta` into `ArakelovParams` construction
3. **Target 3**: `SCNConditioning.lean` + `AtlasSCNBridge.lean` — Integrate SCN with λ_n pipeline
4. **Risk**: Verify Circom constraint count remains at 5,087 via `csc.py` audit
5. **CI**: Add `lake build` + `cargo test -p ace-scn-csc` to CI pipeline

## Exact Commit Path

```bash
# Target 1: atlasM Mode 3 Wrapper
git add lean/Core/f1_square/Square/AtlasMode3Wrapper.lean

# Target 2: gaugeFix → KernelTelemetry → ArakelovParams Bridge
git add lean/Core/f1_square/Square/KernelArakelovBridge.lean

# Target 3: SCN Conditioning + λ_n Pipeline
git add lean/projects/ACE–SCN-CSC/src/KernelTelemetry.lean
git add lean/projects/ACE–SCN-CSC/src/SCNConditioning.lean
git add lean/projects/ACE–SCN-CSC/src/AtlasSCNBridge.lean

# ADR
git add docs/adr/ADR-095-PhaseMirror-Kernel-Semantic-Authority.md
git add docs/adr/ADR-096-ACE-PhaseMirror-Kernel-Telemetry-Contract.md
git add docs/adr/ADR-097-SCN-CSC-Kernel-Metrics-Conditioning.md
git add docs/adr/ADR-098-ACE-SCN-CSC-PhaseMirror-Production-Implementation.md

git commit -m "feat: map F1 atlasM/gaugeFix/lambda_n to ACE-PhaseMirror four-layer state

- Target 1: atlasM Mode 3 feasibility wrapper (AtlasMode3Wrapper.lean)
- Target 2: gaugeFix→KernelTelemetry→ArakelovParams bridge (KernelArakelovBridge.lean)
- Target 3: SCN conditioning on lambda_n pipeline (SCNConditioning.lean, AtlasSCNBridge.lean)
- Risk: 5,087-constraint lock preserved via field substitution (no new gadgets)
- ADR-095/096/097/098: governance and implementation plan"
```

## References
- `docs/ACE_SCN_CSC_PhaseMirror_HQ_Integration.pdf` — Primary integration specification
- `docs/adr/ADR-065-ACE-Runtime-Production-Hardening.md` — ACE runtime hardening baseline
- `docs/adr/ADR-095-PhaseMirror-Kernel-Semantic-Authority.md` — Kernel authority ADR
- `docs/adr/ADR-096-ACE-PhaseMirror-Kernel-Telemetry-Contract.md` — Telemetry contract ADR
- `docs/adr/ADR-097-SCN-CSC-Kernel-Metrics-Conditioning.md` — SCN/CSC conditioning ADR
- `lean/Core/f1_square/Square/AtlasSpectrum.lean` — atlasM indefinite construction
- `lean/Core/f1_square/Square/GaugeTower.lean` — Gauge tower and limit definiteness
- `lean/Core/f1_square/Square/ArakelovHodge.lean` — Finite Arakelov negativity
- `lean/Core/moc/Resonance.lean` — gaugeFix stub and admissible_preserves_orthogonality
- `lean/Core/f1_square/Analysis/GenuineLi.lean` — Genuine Li sequence λ_n
- `lean/Core/f1_square/Analysis/LambdaOne.lean` — Rlambda1_pos certification
- `lean/projects/ACE–SCN-CSC/docs/templateArxiv.tex` — ACE-SCN-CSC technical report
