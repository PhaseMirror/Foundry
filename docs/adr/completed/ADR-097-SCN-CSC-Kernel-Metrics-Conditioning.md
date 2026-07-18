# ADR-097: SCN/CSC Conditioning on Kernel Metrics Only

## Status
**Proposed**

## Context
The Structured Control Network (SCN) currently learns an amortized mapping from instance features to perturbation proposals. Its feature vector is `ϕ(A, ĝ)` — a function of the target operator A and the desired spectral gap ĝ. The SCN has no awareness of drift or protection metrics, which are computed separately in Track A and consumed by the Contraction Spectral Certificate (CSC) layer.

The proposed PhaseMirror-HQ unification requires:
1. SCN to condition its proposal distribution on kernel-defined drift and protection telemetry.
2. CSC to verify that telemetry values are properly bound into commitments without reimplementing semantic logic.
3. Both layers to treat PhaseMirror-HQ as the sole semantic authority for these metrics.

Currently:
- SCN feature map `ϕ(A, ĝ)` does not include drift/protection state.
- CSC circuit verifies algebraic invariants and Poseidon2 commitments, but does not distinguish kernel-certified telemetry from legacy ACE-computed values.
- The 5,087-constraint *architectural* budget is the design target (384 + 3,171 + 1,500 + 32; see ADR-046); the current `ace.circom` prototype compiles to 133 constraints with the Poseidon2 hash stubbed. Any conditioning must fit within the existing headroom (283 reserved constraints *in the target*).

## Decision
We will extend SCN conditioning and CSC witness binding to operate exclusively on **kernel-certified metrics**:

### 1. SCN Feature Map Extension
The SCN feature vector is extended from:
```
ϕ(A, ĝ)
```
to:
```
ϕ(A, ĝ, Θkernel)
```
where `Θkernel = (xn_kernel, wt_max_kernel, protection_zeta, is_valid_kernel)` is the `KernelTelemetry` record defined in ADR-096.

The SCN network architecture is unchanged; only the input dimensionality increases by the telemetry vector width (4 scalar fields + 1 boolean → 5 effective inputs after encoding).

### 2. Telemetry Conditioning Protocol
- SCN receives `KernelTelemetry` as read-only input at each inference step.
- The controller's policy distribution `π(∆ | A, ĝ, Θkernel)` is learned to react to kernel-defined drift/protection states.
- The feasibility map `F(∆0)` and spectral-control objective remain unchanged; only the policy distribution learned by SCN is conditioned on additional telemetry.

### 3. CSC Witness Binding
The CSC layer (Circom circuit) binds kernel telemetry into the existing Poseidon2 commitment topology:
```circom
component poseidon_gamma = Poseidon2(5, 9, 8);
poseidon_gamma.in[0] <== h_commitment;
poseidon_gamma.in[1] <== xn_kernel;
poseidon_gamma.in[2] <== retention_rate;
poseidon_gamma.in[3] <== max_wac_product;
poseidon_gamma.in[4] <== retry_nonce;
cas_commitment <== poseidon_gamma.out;
```

The circuit does not recompute `xn_kernel` or `protection_zeta`; it only verifies that the witness-provided values satisfy the algebraic invariants (drift quotient constraint, clamping consistency, validity booleanity).

### 4. Constraint Budget Enforcement
- `csc.py` in Track A is the **canonical constraint-budget authority**.
- Any modification to the Circom circuit must preserve the 5,087-constraint *architectural* lock (design target; current compiled circuits are below this pending full Poseidon2 integration).
- The Poseidon2 topology (t=9, r=8) is non-negotiable.
- 283 constraints remain reserved for future guard-rails and audit hooks.

## Rust Runtime Contract
```rust
// crates/ace-scn-csc/src/conditioning.rs
use crate::kernel_telemetry::KernelTelemetry;

pub struct SCNConditioningLayer {
    pub feature_dim_base: usize,
    pub telemetry_dim: usize,
}

impl SCNConditioningLayer {
    pub fn new() -> Self {
        Self {
            feature_dim_base: 0, // computed from operator A and gap ĝ
            telemetry_dim: 5,    // xn, wt_max, zeta, is_valid, version
        }
    }

    pub fn extend_feature_vector(
        &self,
        base_features: &[f64],
        telemetry: &KernelTelemetry,
    ) -> Vec<f64> {
        let mut extended = base_features.to_vec();
        extended.push(telemetry.xn_kernel);
        extended.push(telemetry.wt_max_kernel);
        extended.push(telemetry.protection_zeta);
        extended.push(if telemetry.is_valid_kernel { 1.0 } else { 0.0 });
        extended.push(telemetry.telemetry_version as f64);
        extended
    }

    pub fn policy_logits(
        &self,
        features: &[f64],
        weights: &SCNWeights,
    ) -> Vec<f64> {
        // SCN forward pass conditioned on extended feature vector.
        // The network architecture is unchanged; only input width increases.
        weights.forward(features)
    }
}

#[derive(Debug, Clone)]
pub struct CSCWitnessBinding {
    pub h_commitment: [u8; 32],
    pub xn_kernel: f64,
    pub retention_rate: f64,
    pub max_wac_product: f64,
    pub retry_nonce: u64,
    pub cas_commitment: [u8; 32],
}

impl CSCWitnessBinding {
    pub fn bind_telemetry(
        &self,
        telemetry: &KernelTelemetry,
    ) -> Result<Self, CSCBindingError> {
        // Verify that witness fields match kernel telemetry within quantization tolerance.
        let xn_tolerance = 1e-9;
        if (self.xn_kernel - telemetry.xn_kernel).abs() > xn_tolerance {
            return Err(CSCBindingError::TelemetryMismatch {
                field: "xn_kernel",
                witness: self.xn_kernel,
                kernel: telemetry.xn_kernel,
            });
        }
        // Similar checks for other fields...
        Ok(Self {
            xn_kernel: telemetry.xn_kernel,
            ..self.clone()
        })
    }
}

#[derive(Debug, thiserror::Error)]
pub enum CSCBindingError {
    #[error("telemetry mismatch on {field}: witness={witness}, kernel={kernel}")]
    TelemetryMismatch { field: &'static str, witness: f64, kernel: f64 },
    #[error("constraint budget exceeded: {0} > 5087 (architectural target; current compiled circuits are below this)")]
    ConstraintBudgetExceeded(usize),
    #[error("Poseidon2 topology violation")]
    Poseidon2TopologyViolation,
}
```

## Formal Proof Obligations

### 1. SCN Conditioning Soundness
```lean
namespace ADR.ACE.SCNConditioning

structure KernelTelemetry where
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Bool
  telemetry_version : Nat

def telemetry_vector (kt : KernelTelemetry) : List Float :=
  [kt.xn_kernel, kt.wt_max_kernel, kt.protection_zeta,
   if kt.is_valid_kernel then 1.0 else 0.0, kt.telemetry_version]

theorem conditioning_preserves_policy_space
  (base_features : List Float)
  (kt₁ kt₂ : KernelTelemetry)
  (h_same : base_features = base_features ∧ kt₁ = kt₂) :
  policy_logits (extend_features base_features kt₁) =
  policy_logits (extend_features base_features kt₂) := by
  -- Proof: extend_features is deterministic; equal inputs yield equal logits.
  sorry

theorem conditioning_increases_feature_dimension_by_telemetry
  (base_features : List Float)
  (kt : KernelTelemetry) :
  (extend_features base_features kt).length = base_features.length + 5 := by
  -- Proof: 5 fields are appended (xn, wt_max, zeta, is_valid, version).
  sorry

end ADR.ACE.SCNConditioning
```

### 2. CSC Witness Binding Integrity
```lean
namespace ADR.ACE.CSCWitnessBinding

structure CSCWitness where
  h_commitment : List UInt8
  xn_kernel : Float
  retention_rate : Float
  max_wac_product : Float
  retry_nonce : Nat
  cas_commitment : List UInt8

structure KernelTelemetry where
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Bool
  telemetry_version : Nat

theorem witness_matches_telemetry_within_tolerance
  (w : CSCWitness)
  (kt : KernelTelemetry)
  (h_bound : abs (w.xn_kernel - kt.xn_kernel) < 1e-9) :
  bind_telemetry w kt = some w' := by
  -- Proof: witness binding succeeds iff all telemetry fields match within tolerance.
  sorry

theorem constraint_budget_lock
  (layout : CircuitLayout) :
  layout.total_constraints = 5087 ∧
  layout.poseidon2_topology = (t := 9, r := 8) := by
  -- Proof goal: csc.py enforces the lock against the 5087 architectural target.
  -- NOTE: 5087 is the design target; the current ace.circom prototype compiles
  -- to 133 constraints (Poseidon2 stubbed) and langlandsCheck.circom to 170.
  sorry
```

### 3. Circom Topology Preservation
```lean
theorem circom_topology_unchanged
  (circuit_before circuit_after : CircomCircuit)
  (h_telemetry : circuit_after.telemetry_bound = true) :
  circuit_before.poseidon2_t = circuit_after.poseidon2_t ∧
  circuit_before.poseidon2_r = circuit_after.poseidon2_r ∧
  circuit_before.total_constraints = circuit_after.total_constraints := by
  -- Proof: telemetry binding reuses existing Poseidon2 input slots;
  -- no new gadgets are added, so topology and budget are unchanged.
  sorry
```

## Consequences

### Positive
- **Unified conditioning**: SCN reacts to kernel-defined drift/protection states, closing the feedback loop between memory-kernel telemetry and spectral control.
- **CSC simplification**: CSC no longer needs to verify semantic correctness of drift logic; it only verifies algebraic consistency of kernel-provided values.
- **Budget compliance**: Telemetry fields fit within existing Poseidon2 witness slots and the 5,087-constraint *architectural* lock (design target; current compiled circuits are below this pending full Poseidon2 integration).
- **Audit trail**: Every SCN proposal and CSC certificate explicitly references kernel telemetry version, enabling deterministic replay.

### Negative / Constraints
- **Retraining required**: SCN must be retrained or fine-tuned on the extended feature vector `ϕ(A, ĝ, Θkernel)`.
- **Input width change**: Increasing SCN input dimensionality may require architecture changes (e.g., wider first layer) and affect inference latency.
- **CSC adapter work**: The Circom witness adapter must be updated to accept and validate kernel telemetry fields.
- **Telemetry availability**: SCN inference now depends on PhaseMirror-HQ kernel availability; kernel outages could stall the controller.

## Implementation Steps

1. **Define `SCNConditioning.lean`** and `CSCWitnessBinding.lean` in `Prime/lean/adr-governance/ADR/ACE/`.
2. **Implement `crates/ace-scn-csc/src/conditioning.rs`** with `SCNConditioningLayer::extend_feature_vector` and `policy_logits`.
3. **Implement `crates/ace-scn-csc/src/witness_binding.rs`** with `CSCWitnessBinding::bind_telemetry` and tolerance checks.
4. **Update SCN training pipeline** to consume `KernelTelemetry` as part of the feature vector.
5. **Update Circom circuit** in `crates/ace-scn-csc/circom/` to map telemetry fields into Poseidon2 commitment.
6. **Run constraint budget audit** using `csc.py` to confirm total remains within the 5,087-constraint *architectural* target.
7. **Add integration tests** verifying SCN conditioning produces valid proposals given kernel telemetry.
8. **Update CI** to enforce `cargo test -p ace-scn-csc`, `lake build`, and Circom constraint verification.

## References
- `docs/ACE_SCN_CSC_PhaseMirror_HQ_Integration.pdf` — Primary integration specification
- `docs/adr/ADR-065-ACE-Runtime-Production-Hardening.md` — ACE runtime hardening baseline
- `docs/adr/ADR-095-PhaseMirror-Kernel-Semantic-Authority.md` — Kernel authority ADR
- `docs/adr/ADR-096-ACE-PhaseMirror-Kernel-Telemetry-Contract.md` — Telemetry contract ADR
- `crates/ace-scn-csc/` — Existing ACE SCN/CSC crate
- `Prime/lean/adr-governance/` — Lean 4 ADR governance package
- `docs/adr/ADR-062-SigmaKernel-Production-Implementation.md` — SigmaKernel telemetry precedent
