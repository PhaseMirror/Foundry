# ACE-ZK: Track B Rust/Circom Implementation

**Phase 2 of Track B: Circuit Definition in Progress**

## Project Structure

```
ace-zk/
├── Cargo.toml              # Rust package configuration
├── circuits/
│   ├── ace.circom          # Main governance circuit skeleton
│   ├── poseidon2.circom    # Poseidon2 topology lock (t=9, r=8)
│   └── constraints.circom  # Canonical 5,087 budget lock
├── src/
│   ├── lib.rs             # Library root + module declarations
│   ├── types.rs           # ThetaBase, ThetaC6, StepInfo (Python ports)
│   ├── parity.rs          # Mathematical equivalence tests
│   ├── ffi.rs             # PyO3 FFI bindings for Python interop
│   └── csc.rs             # Canonical circuit budget lock (Rust mirror)
└── tests/
  ├── test_parity.py         # Python-side integration tests
  └── test_circuit_topology.rs # Rust topology and budget lock tests
```

## Status

✅ **Phase 1 Infrastructure Complete**
✅ **Phase 2 Circuit Scaffolding Started**

### Circuit Layer (Phase 2 In Progress)
- `circuits/ace.circom`: Main signal layout and invariant skeleton
- `circuits/poseidon2.circom`: Hard lock for Poseidon2(t=9, r=8)
- `circuits/constraints.circom`: Canonical budget lock (384 + 3171 + 1500 + 32 = 5087)
- `src/csc.rs`: Rust-side fail-closed enforcement of topology and constraint target
- `tests/test_circuit_topology.rs`: Validation that circuit and Rust constants stay aligned

### Types (Completed)
- `ThetaBase`: 11 fields with IFMD v0.1 invariant validation
  - Strict L0 validation: beta ∈ (0,1), tau_min > 0, epsilon/supp_epsilon ∈ (0,1)
  - WAC mode enforcement: Strict (M≥1) or Windowed (M≥2)
  - Immutable via Rust struct (equivalent to Python frozen dataclass)

- `ThetaC6`: Stage 3 bundle (base + Fiat-Shamir shuffle_seed)
  - Serializable via serde (serde_json)
  - Full Python FFI binding

- `StepInfo`: Recurrence diagnostics (10 fields)
  - Per-step telemetry from three-split protocol
  - WAC product, convergence metrics, projection flags

### Parity Layer (Completed)
- Reference test vectors matching Python golden outputs
- Mathematical equivalence tolerance: ε < 1e-9
- `float_parity()` function for robust floating-point comparison
- Test harness validating Rust ≡ Python behavior

### FFI Layer (Completed)
- PyO3 bindings for all type classes
- Python-side constructor validation with proper error handling
- Property getters for all fields
- `__repr__()` for debugging
- Ready for WASM compilation (Phase 3)

## Building

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt-get install rustc cargo libpython3-dev

# macOS
brew install rust python3
```

### Compilation
```bash
cd ace-zk
cargo build --release
```

### Python Bindings (Requires maturin)
```bash
pip install maturin
maturin develop
```

## Testing

### Rust Unit Tests
```bash
cargo test --lib
```

### Python Parity Tests (Post-compilation)
```bash
cd ..
python -m pytest tests/test_parity.py -v
```

## Dependencies

| Crate | Version | Purpose |
|-------|---------|---------|
| `serde` | 1.0 | Serialization/deserialization |
| `serde_json` | 1.0 | JSON support for test vectors |
| `ndarray` | 0.16 | Array operations (future phases) |
| `pyo3` | 0.20 | Python FFI bindings |
| `thiserror` | 1.0 | Error handling |
| `hex` | 0.4 | Hex encoding for debugging |

## Next Steps: Phase 2 (Circom Circuits)

After Phase 1 validation:

1. **Circom Circuit Definition** (`ace.circom`)
   - Inputs: theta_base, trajectories (from Track A)
   - Outputs: X_n metric, R_t ratio, is_valid flag, max_wac_product
   - Constraint count: **exactly 5,087** (hard anchor)
   - Poseidon2(t=9, r=8) topology lock

2. **Constraint Validation**
   ```bash
   circom ace.circom --r1cs --wasm
   # Verify: num_constraints = 5087
   ```

3. **Parity Tests**
   - Generate witness vectors from Python Track A
   - Validate Rust governor/monitor equivalence
   - Ensure numerical match ε < 1e-9

4. **Circuit Compiler Target**
   - snarkjs-compatible R1CS format
   - RapidSNARK integration for proof generation

## Mathematical Guarantees

### Invariants Enforced
✅ ThetaBase L0 validation (IFMD v0.1)
✅ WAC mode M constraints
✅ Holdout split beta ∈ (0,1)
✅ Governor tau_min > 0 constraint

### Parity Properties
✅ Rust → Python round-trip (JSON serialization)
✅ Numerical equivalence: |rust_value - python_value| < 1e-9 × |python_value|
✅ No precision loss in type conversions (f64 → f64)

## FFI Contract (Python ↔ Rust)

```python
# Python Track A
from ace_zk import ThetaBase, ThetaC6, StepInfo

# Create validated configuration
theta = ThetaBase(
    epsilon=0.5,
    supp_epsilon=0.05,
    delta=1.0,
    n_0=100,
    k=10,
    m=2,
    beta=0.8,
    tau_min=0.1,
    alpha_m=0.95,
    wac_mode="windowed"
)

# Stage 3 registry with seed
tc6 = ThetaC6(theta, shuffle_seed=b'\x01\x02\x03...')

# Diagnostics from recurrence loop
step = StepInfo(
    step=1,
    q=0.95,
    epsilon=0.5,
    kkt_residual=1e-6,
    wac_product=0.98,
    xi_telemetry=0.01,
    delta_sigma=0.002,
    delta_m=0.003,
    projected=False,
    residual=1e-7
)
```

## Implementation Details

### Type Conversions
- `WacMode::Windowed` ↔ `"windowed"` (case-insensitive)
- `shuffle_seed: Vec<u8>` ↔ `bytes` (bidirectional)
- All f64 values maintain full precision (no quantization)

### Error Handling
All Python-side validation errors are translated to PyValueError:
```python
try:
    theta = ThetaBase(epsilon=0.0)  # Invalid: must be in (0,1)
except ValueError as e:
    # e = "Contraction gap epsilon must be in (0, 1)"
```

### Serialization Support
ThetaC6 and derivatives are fully serializable:
```python
import json
json_str = json.dumps(tc6.__dict__)  # Works post-binding
```

## Integration with Track A

Track B Phase 1 provides the foundation for:
- `governor.rs`: Port of `governor.py` with L1 norm computation
- `monitor.rs`: Port of `monitor.py` with WAC telescoping
- `recurrence.rs`: Port of `recurrence.py` with three-split protocol
- `audit.rs`: Port of `audit.py` with IFMD §6 whitelist enforcement

All functions maintain mathematical equivalence to Python, validated via:
- Unit tests in Rust (`#[test]`)
- Integration tests in Python (parity tests)
- Continuous numerical verification pipeline (Track B → Track A → Verify)

## References

- [IFMD v0.1 Specification](../docs/math_spec.md)
- [Track B Planning](../docs/TRACK_B_PLAN.md)
- [Groth16 Decision](../docs/TRACK_B_PLAN.md#zk-proof-system-decision-groth16-primary-plonk-secondary)
- [Circom Documentation](https://docs.circom.io/)
- [PyO3 User Guide](https://pyo3.rs/)
- [Poseidon Hash](https://www.poseidon-hash.info/)
