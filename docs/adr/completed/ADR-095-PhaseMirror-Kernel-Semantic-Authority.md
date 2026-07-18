# ADR-095: PhaseMirror-HQ as Single Semantic Authority for Drift and Protection Metrics

## Status
**Proposed**

## Context
The Arithmetic Control Engine (ACE) currently defines drift and protection metrics (normalized drift Xn, windowed contraction WAC, retention rate Rt, and validity flag is_valid) internally within Track A. The Structured Control Network (SCN) proposes perturbations, and the Contraction Spectral Certificate (CSC) verifies algebraic invariants and Poseidon2 commitments, but neither layer has a single source of truth for semantic drift/protection definitions.

This duplication creates three failure modes:
- **Semantic drift**: Track A drift logic can diverge from runtime telemetry consumed by SCN conditioning or CSC witness binding.
- **Duplication risk**: Other systems interacting with ACE may reimplement or partial-reimplement drift metrics, undermining governance clarity.
- **Audit ambiguity**: The CSC circuit (Track B) verifies algebraic consistency but cannot independently validate that the semantic definitions it certifies remain canonical.

The PhaseMirror-HQ memory-kernel layer (FZS-MK with Zeno projection) provides a natural candidate to assume sole semantic authority. Under this model, ACE and SCN treat drift and protection metrics as read-only telemetry, and CSC verifies that these telemetry values are properly bound into commitments without redefining their semantics.

## Decision
We will declare the PhaseMirror-HQ FZS-MK/Zeno layer the **sole semantic authority** for all drift and protection metrics consumed by ACE, SCN, and CSC. This means:

### 1. Kernel Authority Mandate
- PhaseMirror-HQ's FZS-MK memory kernel with Zeno projection defines all drift metrics (Xn), windowed contraction statistics (Wt, Rt), protection indices (ζprotect), and validity flags.
- ACE Track A may compute and emit these values, but only by delegating to the kernel telemetry contract.
- ACE Track B (Circom circuit) binds kernel-certified scalars into witness commitments without reimplementing semantic logic.

### 2. Deprecation of Duplicate Logic
- All ACE-side drift formulas (`compute_legacy_xn`, `compute_wac`, etc.) are marked deprecated.
- During migration, a parity mode (`parity_mode: bool = True`) asserts numerical agreement between kernel and legacy logic within a strict tolerance (1e-9).
- After parity is confirmed across the benchmark corpus, legacy drift functions are removed from Track A.

### 3. Kernel as Read-Only Telemetry Source
- ACE and SCN treat the kernel as a read-only provider of `KernelTelemetry` records.
- SCN conditioning extends its feature map from `ϕ(A, ĝ)` to `ϕ(A, ĝ, Θkernel)`, allowing the controller to react to kernel-defined drift states without recomputing them.

## Formal Proof Obligations

### 1. Single-Authority Preservation
```lean
namespace ADR.ACE.PhaseMirrorKernelAuthority

structure KernelTelemetry where
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Bool
  telemetry_version : Nat
  deriving Repr

inductive TelemetrySource
  | LegacyACE
  | PhaseMirrorKernel

def authoritative_source : TelemetrySource := TelemetrySource.PhaseMirrorKernel

theorem kernel_authority_exclusive
  (kt : KernelTelemetry)
  (h_source : telemetry_source kt = TelemetrySource.PhaseMirrorKernel) :
  ¬ ∃ legacy_computation, drift_value(legacy_computation) = kt.xn_kernel ∧
    telemetry_source kt = TelemetrySource.LegacyACE := by
  -- Proof: once migration completes, legacy drift logic is removed;
  -- any equality with legacy computation is structurally impossible.
  sorry

theorem parity_mode_converges
  (step_state : StepState)
  (h_parity : parity_mode = true) :
  abs (legacy_xn step_state - (load_kernel_telemetry step_state).xn_kernel) < 1e-9 := by
  -- Proof by induction on parity test corpus:
  -- all benchmark states satisfy the tolerance bound.
  sorry

end ADR.ACE.PhaseMirrorKernelAuthority
```

### 2. Semantic Preservation Invariant
```lean
theorem semantic_preservation
  (env : ACEEnvelope) (kt : KernelTelemetry)
  (h_kernel : is_authoritative kt) :
  certificate_payload(env, kt).xn_kernel = kt.xn_kernel ∧
  certificate_payload(env, kt).wt_max_kernel = kt.wt_max_kernel ∧
  certificate_payload(env, kt).protection_zeta = kt.protection_zeta ∧
  certificate_payload(env, kt).is_valid_kernel = kt.is_valid_kernel := by
  -- Proof: certificate payload is constructed directly from KernelTelemetry fields;
  -- no intermediate recomputation occurs.
  sorry
```

## Rust Runtime Contract
```rust
// crates/ace-governance/src/kernel_telemetry.rs
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub telemetry_version: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TelemetrySource {
    LegacyACE,
    PhaseMirrorKernel,
}

pub struct ACEGovernanceLayer {
    source: TelemetrySource,
    parity_mode: bool,
    legacy_drift_logic: Option<LegacyDriftEngine>,
}

impl ACEGovernanceLayer {
    pub fn new(source: TelemetrySource, parity_mode: bool) -> Self {
        Self {
            source,
            parity_mode,
            legacy_drift_logic: if parity_mode {
                Some(LegacyDriftEngine::new())
            } else {
                None
            },
        }
    }

    pub fn get_drift_metrics(&self, step_state: &StepState) -> Result<KernelTelemetry, GovernanceError> {
        match self.source {
            TelemetrySource.PhaseMirrorKernel => {
                let kt = zeno::compute_kernel_telemetry(step_state)?;
                if self.parity_mode {
                    if let Some(ref legacy) = self.legacy_drift_logic {
                        let legacy_xn = legacy.compute_xn(step_state);
                        assert!(
                            (legacy_xn - kt.xn_kernel).abs() < 1e-9,
                            "Parity violation: legacy={}, kernel={}",
                            legacy_xn,
                            kt.xn_kernel
                        );
                    }
                }
                Ok(kt)
            }
            TelemetrySource.LegacyACE => Err(GovernanceError::DeprecatedAuthority),
        }
    }

    pub fn certificate_payload(&self, telemetry: KernelTelemetry, outputs: &[u8]) -> ACECertificate {
        ACECertificate {
            xn_kernel: telemetry.xn_kernel,
            wt_max_kernel: telemetry.wt_max_kernel,
            protection_zeta: telemetry.protection_zeta,
            is_valid_kernel: telemetry.is_valid_kernel,
            telemetry_version: telemetry.telemetry_version,
            outputs: outputs.to_vec(),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum GovernanceError {
    #[error("Legacy ACE authority is deprecated; use PhaseMirrorKernel")]
    DeprecatedAuthority,
    #[error("Kernel telemetry computation failed: {0}")]
    KernelTelemetryError(String),
    #[error("Parity mode assertion failed")]
    ParityViolation,
}
```

## Consequences

### Positive
- **Single source of truth**: Drift and protection semantics are defined exactly once, eliminating semantic drift across pipelines.
- **Audit clarity**: CSC certificates explicitly reference kernel-certified scalars with versioned schemas, enabling deterministic replay and compliance review.
- **Modular migration**: Parity mode allows incremental deprecation of legacy ACE drift logic without breaking existing consumers.
- **Circuit budget preserved**: Kernel telemetry fields fit within the existing 5,087-constraint *architectural* budget (design target: 384 + 3,171 + 1,500 + 32; see ADR-046) and Poseidon2 (t=9, r=8) witness-binding topology. The current `ace.circom` prototype compiles to 133 constraints with the Poseidon2 hash stubbed; the target is reached only after full Poseidon2 instantiation.

### Negative / Constraints
- **Kernel coupling**: ACE runtime now depends on PhaseMirror-HQ kernel release cycles and availability.
- **Schema versioning burden**: The `telemetry_version` field must be managed across deployments; breaking schema changes require coordinated ADRs.
- **Performance overhead**: Kernel telemetry round-trip adds latency to ACE Track A; the Rust wrapper must avoid recomputation.
- **Formalization gap**: Lean 4 proof of `kernel_authority_exclusive` requires a formal model of the FZS-MK kernel and Zeno projection, which may not exist yet.

## Implementation Steps

1. **Define `KernelTelemetry.lean`** in `Prime/lean/adr-governance/ADR/ACE/PhaseMirrorKernelAuthority.lean` with the telemetry record and authority theorems.
2. **Implement `crates/ace-governance/src/kernel_telemetry.rs`** with the `KernelTelemetry` struct, `get_drift_metrics`, and `certificate_payload`.
3. **Add parity test suite** in `crates/ace-governance/tests/parity/` comparing kernel telemetry against legacy ACE drift logic on benchmark datasets.
4. **Update `crates/ace-scn-csc/src/`** to condition SCN feature maps on `KernelTelemetry` without recomputing drift.
5. **Wire Circom witness binding** to accept kernel telemetry fields (`xn_kernel`, `wt_max_kernel`, `protection_zeta`, `is_valid_kernel`) within the 5,087-constraint *architectural* budget (design target; current compiled circuits are below this pending full Poseidon2 integration).
6. **Deprecate legacy drift functions** after parity is confirmed; follow up with ADR to remove `compute_legacy_xn`, `compute_wac`, etc.
7. **Update CI** to enforce `cargo test -p ace-governance --test parity` and `lake build` on `PhaseMirrorKernelAuthority.lean`.

## References
- `docs/ACE_SCN_CSC_PhaseMirror_HQ_Integration.pdf` — Primary integration specification
- `docs/adr/ADR-065-ACE-Runtime-Production-Hardening.md` — ACE runtime hardening baseline
- `crates/ace-zk/`, `crates/ace-scn-csc/` — Existing ACE crates
- `Prime/lean/adr-governance/` — Lean 4 ADR governance package
- `docs/adr/ADR-062-SigmaKernel-Production-Implementation.md` — SigmaKernel production integration
- ADR-077 (PIRTM Fock Space) — Constitutional contractivity precedent
