# PREP-2026 Conformance Kit

This kit provides the normative tools and specifications required to verify that an implementation of the Prime-Recursive Engine (PRE) is conformant with the **PREP-2026** standard.

## 1. Overview
The Prime-Recursive Engine Profile (PREP-2026) defines the execution layer for the Multiplicity substrate. Conformant implementations must satisfy strict mathematical invariants (I1–I4), maintain functorial integrity (Mult), and demonstrate a statistically significant structural signal (C4).

## 2. Prerequisites
- **Rust Toolchain**: 1.75 or later (stable).
- **Python 3.10+** (Optional, for cross-checking legacy C4 scripts).
- **Cargo**: Standard Rust package manager.

## 3. Build Instructions
To build the conformant reference implementation and the conformance runner:

```bash
cd PhaseMirror-HQ/packages/pirtm-rs
cargo build --release --bin prep_conform
```

The resulting binary will be located at `target/release/prep_conform`.

## 4. Execution (One-Shot Conformance)
To execute the full PREP-2026 compliance suite and generate an evidence bundle:

```bash
./target/release/prep_conform --out-dir ./conformance-evidence --json
```

## 5. Interpreting the Evidence Bundle
The runner produces an evidence bundle in the specified `--out-dir`. Verifiers should inspect the following artifacts:

### 5.1 `result.json`
The top-level summary of the run.
- `conformant`: Boolean indicating overall compliance.
- `violations`: A list of any PREP-Vxx codes encountered.
- `summary`: Per-invariant status (I1, I2, I3, I4, C4, Mult).

### 5.2 `c4_report.json`
The statistical proof of prime structural significance.
- **Pass Conditions**: `ks_p < 0.05` AND `cohens_d > 0.2`.
- Failure to meet these thresholds results in `PREP-C4F`.

### 5.3 `mult_witness.json`
Verification of the Multiplicity Functor laws (Additivity/Linearity).
- **Pass Condition**: `max_additivity_error <= 1e-12`.
- Failure results in `PREP-MULT`.

### 5.4 `invariants_log.jsonl`
A detailed trace of runtime assertions.
- Entries for I1 (Positive Cone), I2 (Banach Rails), I3 (Strong Commitments), and I4 (Truncation).

## 6. Violation Codes
| Code | Section | Description |
| :--- | :--- | :--- |
| **PREP-V01** | I1 | Positive cone violation (negative multiplicities detected). |
| **PREP-V02** | I2 | Contractivity bound violation ($L_{\text{eff}} \ge 1 - \epsilon$). |
| **PREP-V03** | I3 | Commitment collision detected (failed detectability). |
| **PREP-V04** | I4 | Prime index out of range ($i > 65,536$). |
| **PREP-C4F** | C4 | C4 Regression failure (insignificant structural signal). |
| **PREP-MULT**| Mult | Functorial law violation (additivity/linearity failure). |

## 7. Contact and Audit
For questions regarding the PREP-2026 standard or to submit signed evidence bundles for registry inclusion, contact the Multiplicity Foundation standards group.
