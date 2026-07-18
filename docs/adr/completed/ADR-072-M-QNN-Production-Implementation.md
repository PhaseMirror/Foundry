# ADR-072: M-QNN Production Implementation

## Status
**Adopted**

## Context
The publication `publications/M-QNN/` describes a **Multiplicity-Quantum Neural Network** architecture that integrates quantum computing primitives with multiplicity-theoretic neural dynamics. This is a **high-value target** because:
- It provides the **quantum substrate** for the Phase Mirror's next-generation compute layer
- It bridges **quantum circuits** (qudit operations, VQE, HSEC) with **classical neural networks** (multiplicity layers, contraction dynamics)
- It enables the **UAC substrate** to leverage quantum advantage for chemical-accuracy simulations

Currently, the `Prime/crates/quantum/` or `Prime/crates/hybrid-quantum/` crates exist but lack a production-grade ADR governing their implementation. The `Prime/lean/QUANTUM/` module exists in `PhaseMirror.lean` but lacks formalization in `adr-governance`.

Without formal ratification, the M-QNN risks:
- **Quantum-classical drift**: The quantum circuit output may not match the classical multiplicity layer's expectations
- **Decoherence without detection**: Quantum error correction (HSEC) may fail silently
- **No audit trail**: Quantum circuit executions lack `Archivum` provenance

## Decision
We will implement M-QNN as a **formally verified, production-grade quantum-classical neural architecture** with the following mandates:

### 1. Lean 4 Formalization of Quantum-Classical Interface
- Define `Prime/lean/QUANTUM/MQNN.lean` with:
  - `QuditState` — d-dimensional quantum state vector
  - `MultiplicityLayer` — classical neural layer with prime-gated weights
  - `MQNNForward` — combined quantum-classical forward pass
  - `HSECProtocol` — Hyperfine Subspace Error Correction protocol
- Prove:
  - `mqnn_preserves_contractivity`: The full forward pass preserves `c < 1.0`.
  - `hsec_detects_decoherence`: HSEC detects any qudit state with fidelity < threshold.
  - `quantum_classical_interface_sound`: The quantum output is correctly consumed by the classical layer.

### 2. Rust Implementation
- Expand `Prime/crates/hybrid-quantum/` to expose:
  - `MQNN::new(config: MQNNConfig) -> Result<MQNN, InitError>`
  - `MQNN::forward(qudit_state: &QuditState, classical_input: &Tensor) -> Result<Tensor, DecoherenceError>`
  - `MQNN::apply_hsec(state: &mut QuditState) -> Result<HSECReport, HSECError>`
- The Rust implementation must:
  - Use exact arithmetic for multiplicity weights
  - Emit `MQNNWitness` to `Archivum` on every forward pass
  - Reject any forward pass where HSEC detects decoherence

### 3. Kani Verification
- Implement Kani harnesses in `Prime/crates/hybrid-quantum/tests/kani/` proving:
  - `proof_forward_preserves_contractivity`: `forward` output satisfies `c < 1.0`.
  - `proof_hsec_sound`: `apply_hsec` detects all states below the fidelity threshold.
  - `proof_interface_sound`: Quantum output dimensions match classical input dimensions.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/QUANTUM/` and `cargo kani -p hybrid-quantum` on every PR.
- The Guardian lock must verify the `MQNNWitness` before approving quantum circuit execution.
- The Examiner lock must audit HSEC reports for decoherence events.
- The Publisher lock must sign quantum execution traces into the `Archivum` ledger.

## Formal Proof Obligations

### 1. M-QNN Preserves Contractivity
```lean
namespace ADR.MQNN

structure QuditState where
  dimension : Nat  -- d = 8 or d = 16
  amplitudes : List ℂ  -- quantum state vector
  h_normalized : amplitudes.norm = 1
  deriving Repr

structure MultiplicityLayer where
  input_dim : Nat
  output_dim : Nat
  weights : List ℝ  -- prime-gated weights
  h_contractive : weights.contractive_norm < 1.0
  deriving Repr

structure MQNNForward where
  qudit_output : List ℝ
  classical_output : List ℝ
  h_interface_match : qudit_output.length = classical_output.length
  deriving Repr

@[proof]
theorem mqnn_preserves_contractivity (mqnn : MQNN) (input : Tensor) :
  let output := mqnn.forward input
  output.classical_output.contractive_norm < 1.0 := by
  -- Proof that the quantum-classical forward pass preserves contraction
  sorry

@[proof]
theorem hsec_detects_decoherence (state : QuditState) (threshold : ℝ)
  (h_fidelity : state.fidelity < threshold) :
  mqnn.apply_hsec state = HSECResult.DecoherenceDetected := by
  -- Proof that HSEC flags all states below the fidelity threshold
  sorry

end ADR.MQNN
```

### 2. Rust Runtime Contract
```rust
// crates/hybrid-quantum/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuditState {
    pub dimension: usize,
    pub amplitudes: Vec<Complex64>, // or exact complex type
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityLayer {
    pub input_dim: usize,
    pub output_dim: usize,
    pub weights: Vec<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MQNNWitness {
    pub qudit_output_hash: [u8; 32],
    pub classical_output_hash: [u8; 32],
    pub hsec_report: HSECReport,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum DecoherenceError {
    #[error("HSEC detected decoherence: fidelity {fidelity} < threshold {threshold}")]
    DecoherenceDetected { fidelity: f64, threshold: f64 },
    #[error("dimension mismatch: qudit {qdim} vs classical {cdim}")]
    DimensionMismatch { qdim: usize, cdim: usize },
}

pub struct MQNN {
    multiplicity_layer: MultiplicityLayer,
    hsec_threshold: f64,
}

impl MQNN {
    pub fn forward(
        &self,
        qudit_state: &QuditState,
        classical_input: &Tensor,
    ) -> Result<Tensor, DecoherenceError> {
        let hsec_report = self.apply_hsec(qudit_state)?;
        let qudit_output = extract_classical_embedding(qudit_state);
        if qudit_output.len() != classical_input.len() {
            return Err(DecoherenceError::DimensionMismatch {
                qdim: qudit_output.len(),
                cdim: classical_input.len(),
            });
        }
        let combined: Vec<f64> = qudit_output.iter()
            .zip(classical_input.iter())
            .map(|(q, c)| q * c)
            .collect();
        Ok(Tensor::from(combined))
    }

    pub fn apply_hsec(&self, state: &QuditState) -> Result<HSECReport, DecoherenceError> {
        let fidelity = compute_fidelity(state);
        if fidelity < self.hsec_threshold {
            return Err(DecoherenceError::DecoherenceDetected {
                fidelity,
                threshold: self.hsec_threshold,
            });
        }
        Ok(HSECReport { fidelity, threshold: self.hsec_threshold, passed: true })
    }
}
```

## Consequences

### Positive
- **Verified Quantum-Classical Interface**: Lean 4 + Kani guarantees that quantum outputs are correctly consumed by classical multiplicity layers.
- **Decoherence Detection**: HSEC is mechanized to catch all fidelity violations before they propagate.
- **Audit-Ready Execution**: Every quantum circuit execution emits an `MQNNWitness` to `Archivum`.
- **Quantum Advantage for UAC**: M-QNN enables quantum-accelerated chemical simulations within the UAC substrate.

### Negative
- **Quantum Simulation Overhead**: Simulating qudit states in Rust (without real quantum hardware) is computationally expensive.
- **Formalization Gap**: The `QUANTUM` Lean module lacks the M-QNN-specific formalization required for production.
- **Hardware Dependency**: Real quantum execution requires neutral-atom qudit hardware; simulation fidelity may not match physical fidelity.

## Implementation Steps

1. **Define `MQNN.lean`** in `Prime/lean/QUANTUM/` with `QuditState`, `MultiplicityLayer`, `MQNNForward`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/MQNNProofs.lean`.
3. **Expand `Prime/crates/hybrid-quantum/`** with `MQNN`, `HSECProtocol`, and forward pass APIs.
4. **Implement Kani harness** proving forward pass and HSEC soundness.
5. **Wire Triple-Lock integration**: Guardian → quantum execution approval → Examiner → `MQNNWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p hybrid-quantum`.
7. **Emit Archivum witness** `MQNNExecutionProof` on every forward pass.
8. **Benchmark against UAC thresholds** (error <15 mHa, entropy ≤6.0).

## References
- `publications/M-QNN/templatePRIME.tex` — Publication template
- `Prime/crates/hybrid-quantum/` — Existing Rust crate
- `Prime/lean/QUANTUM/` — Existing Lean module
- ADR-060 (SnapKitty/UAC) — QCFI, MA-VQE, HSEC integration
- ADR-064 (MatrixEngine) — Tensor kernel formalization
- ADR-068 (MOC/CRMF) — Contraction certificates
- `publications/Quantum-AGI Claims/` — Quantum AGI architecture
