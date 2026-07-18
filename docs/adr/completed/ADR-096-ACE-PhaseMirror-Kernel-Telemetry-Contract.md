# ADR-096: ACE–PhaseMirror Kernel Telemetry Contract

## Status
**Proposed**

## Context
ACE Track A currently owns the semantic definitions of drift and protection metrics, while Track B (Circom) verifies algebraic consistency and Poseidon2 commitments against witness values provided by Track A. The proposed PhaseMirror-HQ unification requires a formal, versioned contract through which the kernel supplies certified scalars to ACE's certificate and zero-knowledge pipelines.

Without a contract:
- Track A and Track B have no machine-readable schema for kernel-certified drift/protection values.
- Poseidon2 witness binding in Circom cannot distinguish kernel-provided telemetry from legacy ACE-computed values.
- Schema evolution (new metrics, changed field types) breaks circuit determinism and certificate replay.

The kernel telemetry contract must satisfy:
- **Determinism**: Given identical kernel state, the contract yields identical scalar values.
- **Schema evolution**: A version field allows backward-compatible extensions without breaking existing circuits.
- **Circuit compatibility**: All telemetry fields fit within the existing 5,087-constraint *architectural* budget (design target: 384 + 3,171 + 1,500 + 32; see ADR-046) and Poseidon2 (t=9, r=8) topology. The current `ace.circom` prototype compiles to 133 constraints with the Poseidon2 hash stubbed.

## Decision
We will define and adopt a **versioned `KernelTelemetry` schema** as the formal contract between PhaseMirror-HQ, ACE Track A, and ACE Track B (Circom). The contract specifies:

### 1. Schema Definition
A frozen `KernelTelemetry` record containing:
- `xn_kernel: f64` — normalized drift metric (off-support drift / proxy L1 norm).
- `wt_max_kernel: f64` — maximum windowed contraction statistic.
- `protection_zeta: f64` — protection index.
- `is_valid_kernel: bool` — certification gate (validity flag).
- `telemetry_version: u32` — schema version for forward/backward compatibility.

### 2. Python Contract (Track A)
```python
from dataclasses import dataclass
from typing import Protocol

@dataclass(frozen=True)
class KernelTelemetry:
    xn_kernel: float
    wt_max_kernel: float
    protection_zeta: float
    is_valid_kernel: bool
    telemetry_version: int = 1

class KernelTelemetryProvider(Protocol):
    def compute_kernel_telemetry(self, step_state) -> KernelTelemetry: ...

def load_kernel_telemetry(step_state) -> KernelTelemetry:
    return zeno.compute_kernel_telemetry(step_state)

def get_drift_metrics(step_state, parity_mode: bool = False) -> KernelTelemetry:
    kt = load_kernel_telemetry(step_state)
    if parity_mode:
        legacy_xn = compute_legacy_xn(step_state)
        assert abs(legacy_xn - kt.xn_kernel) < 1e-9
    return kt

def certificate_payload(theta_base, telemetry: KernelTelemetry, outputs: bytes) -> dict:
    return {
        "theta": serialize_theta(theta_base),
        "xn_kernel": telemetry.xn_kernel,
        "wt_max_kernel": telemetry.wt_max_kernel,
        "protection_zeta": telemetry.protection_zeta,
        "is_valid_kernel": int(telemetry.is_valid_kernel),
        "telemetry_version": telemetry.telemetry_version,
        "outputs": outputs.hex(),
    }
```

### 3. Circom Witness Binding (Track B)
Telemetry fields are bound into the existing Poseidon2 commitment topology without increasing the canonical 5,087-constraint *architectural* budget (design target; current `ace.circom` uses a Poseidon2 stub and compiles to 133 constraints):

```circom
component poseidon_gamma = Poseidon2(5, 9, 8);
poseidon_gamma.in[0] <== h_commitment;
poseidon_gamma.in[1] <== xn_kernel;
poseidon_gamma.in[2] <== retention_rate;     // derived from kernel telemetry
poseidon_gamma.in[3] <== max_wac_product;    // derived from kernel telemetry
poseidon_gamma.in[4] <== retry_nonce;
cas_commitment <== poseidon_gamma.out;
```

### 4. Rust Runtime Contract
```rust
// crates/ace-certify/src/telemetry_contract.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub telemetry_version: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ACECertificate {
    pub theta: Vec<u8>,
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: u8,
    pub telemetry_version: u32,
    pub outputs: Vec<u8>,
}

impl ACECertificate {
    pub fn from_telemetry(
        theta: &[u8],
        telemetry: KernelTelemetry,
        outputs: &[u8],
    ) -> Self {
        Self {
            theta: theta.to_vec(),
            xn_kernel: telemetry.xn_kernel,
            wt_max_kernel: telemetry.wt_max_kernel,
            protection_zeta: telemetry.protection_zeta,
            is_valid_kernel: telemetry.is_valid_kernel as u8,
            telemetry_version: telemetry.telemetry_version,
            outputs: outputs.to_vec(),
        }
    }

    pub fn validate_schema(&self) -> Result<(), CertificateSchemaError> {
        match self.telemetry_version {
            1 => {
                if self.theta.is_empty() || self.outputs.is_empty() {
                    return Err(CertificateSchemaError::EmptyField);
                }
                Ok(())
            }
            v => Err(CertificateSchemaError::UnsupportedVersion(v)),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum CertificateSchemaError {
    #[error("unsupported telemetry version: {0}")]
    UnsupportedVersion(u32),
    #[error("empty required field in certificate")]
    EmptyField,
}
```

## Formal Proof Obligations

### 1. Schema Determinism
```lean
namespace ADR.ACE.KernelTelemetryContract

structure KernelTelemetry where
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Bool
  telemetry_version : Nat
  deriving Repr

theorem telemetry_determinism
  (kt₁ kt₂ : KernelTelemetry)
  (h_state : step_state_identical kt₁ kt₂) :
  kt₁.xn_kernel = kt₂.xn_kernel ∧
  kt₁.wt_max_kernel = kt₂.wt_max_kernel ∧
  kt₁.protection_zeta = kt₂.protection_zeta ∧
  kt₁.is_valid_kernel = kt₂.is_valid_kernel := by
  -- Proof: Zeno projection is deterministic given identical step_state;
  -- FZS-MK memory kernel state transition is functional.
  sorry

theorem schema_version_monotonic
  (cert : ACECertificate)
  (h_valid : cert.validate_schema = some ()) :
  cert.telemetry_version ≥ 1 := by
  -- Proof: version field is initialized to 1 and only incremented on schema evolution;
  -- validation rejects unknown versions.
  sorry

theorem certificate_fields_bound_to_telemetry
  (cert : ACECertificate)
  (kt : KernelTelemetry)
  (h_from : cert = ACECertificate.from_telemetry theta kt outputs) :
  cert.xn_kernel = kt.xn_kernel ∧
  cert.wt_max_kernel = kt.wt_max_kernel ∧
  cert.protection_zeta = kt.protection_zeta ∧
  cert.is_valid_kernel = bool_to_u8 kt.is_valid_kernel ∧
  cert.telemetry_version = kt.telemetry_version := by
  -- Proof: from_telemetry is a direct field copy; no transformation occurs.
  sorry

end ADR.ACE.KernelTelemetryContract
```

### 2. Circuit Budget Preservation
```lean
theorem circom_witness_binding_preserves_budget
  (layout : CircuitLayout)
  (h_base : layout.base_constraints = 5087)
  (h_telemetry : layout.telemetry_fields = 5) :
  layout.total_constraints = 5087 := by
  -- Proof goal: Poseidon2(5,9,8) witness binding is budgeted into the base
  -- circuit design (384 + 3171 + 1500 + 32 = 5087); telemetry fields replace
  -- existing witness slots, not add new ones. NOTE: 5087 is the architectural
  -- target, not the current compiled count (ace.circom = 133, langlandsCheck.circom = 170).
  sorry
```

## Consequences

### Positive
- **Deterministic replay**: Versioned schema allows archival certificates to be validated and replayed indefinitely.
- **Circuit compatibility**: Telemetry fields reuse existing Poseidon2 witness slots, preserving the 5,087-constraint *architectural* lock (design target; current compiled circuits are below this pending full Poseidon2 integration).
- **Type safety**: Frozen `KernelTelemetry` dataclass and Rust struct enforce field immutability at compile time.
- **Validation gate**: `validate_schema` rejects malformed or unsupported versions before they propagate to CSC or Archivum.

### Negative / Constraints
- **Schema management overhead**: Every schema change requires a new version, updated validation logic, and potentially updated Circom witness bindings.
- **Python/Rust sync**: The dataclass and Rust struct must be kept in sync manually or via code generation; drift here causes runtime serialization failures.
- **Circom slot exhaustion**: If future metrics exceed the 5 Poseidon2 input slots reserved for telemetry, the *architectural* 5,087-constraint budget (design target) must be renegotiated.
- **Lean formalization gap**: `telemetry_determinism` depends on a formal model of the Zeno projection, which may not exist in `adr-governance` yet.

## Implementation Steps

1. **Define `KernelTelemetry.lean`** in `Prime/lean/adr-governance/ADR/ACE/KernelTelemetryContract.lean`.
2. **Implement `crates/ace-certify/src/telemetry_contract.rs`** with `KernelTelemetry`, `ACECertificate`, and `validate_schema`.
3. **Add Python contract module** at `src/ace/governor.py` with `KernelTelemetry`, `load_kernel_telemetry`, `get_drift_metrics`, and `certificate_payload`.
4. **Update Circom witness adapter** in `crates/ace-scn-csc/circom/` to map `xn_kernel`, `wt_max_kernel`, `protection_zeta`, `is_valid_kernel` into the Poseidon2 commitment.
5. **Emit schema-validation tests** ensuring `ACECertificate::validate_schema` rejects version 0 and unknown versions.
6. **Add serialization round-trip tests** between Python dataclass and Rust struct.
7. **Update CI** to run `cargo test -p ace-certify` and schema-validation checks on every PR.

## References
- `docs/ACE_SCN_CSC_PhaseMirror_HQ_Integration.pdf` — Primary integration specification
- `docs/adr/ADR-065-ACE-Runtime-Production-Hardening.md` — ACE runtime hardening baseline
- `docs/adr/ADR-095-PhaseMirror-Kernel-Semantic-Authority.md` — Kernel authority ADR
- `crates/ace-zk/`, `crates/ace-scn-csc/` — Existing ACE crates
- `Prime/lean/adr-governance/` — Lean 4 ADR governance package
- `docs/adr/ADR-062-SigmaKernel-Production-Implementation.md` — SigmaKernel telemetry precedent
