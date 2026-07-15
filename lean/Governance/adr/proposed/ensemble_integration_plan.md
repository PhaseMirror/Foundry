# Ensemble Integration & Certification Plan

This plan outlines the systematic process for migrating the existing 90 directories within `ensembles/`, integrating them with our latest advancements, and certifying them as rooted additions to `substrates/`. 

We use `pweh-parser` as the archetype for this process.

## 1. The Substrate Rooting Standard (Based on `pweh-parser`)
For an ensemble to be certified and moved to `substrates/`, it must satisfy the following architectural and governance criteria:
*   **Rust Core Implementation**: A robust `Cargo.toml`, `src/`, and comprehensive `tests/` directory ensuring high-performance execution.
*   **Adapter Layer**: Python or WASM adapters (e.g., `pweh_adapter.py`) to bridge the Rust core with external interfaces or legacy workflows.
*   **Verification & Fidelity**: Generation of automated verification reports (e.g., `invalid_hash_format_report.json`, `invalid_resonance_report.json`) and an overall `Adapter_Fidelity_Report.md`.
*   **Formal Specifications**: Theoretical foundation documentation (e.g., LaTeX docs or rigorous Markdown) outlining the algorithms.
*   **Governance Compliance**: Strict adherence to the Sedona Spine Mandate. Any ESI retention, litigation hold, or constitutional invariants must pass through the ALP gate and generate Archivum witnesses.

## 2. Phase I: Audit & Triage
With 90 ensembles currently present, a blind migration is inefficient. 
*   **Action**: Conduct a broad scan of `ensembles/` to categorize them.
*   **Categories**:
    *   **Priority 1**: Core primitives and critical mathematical/cryptographic modules (e.g., `pasta-curves`, `hypercompute`, `kernel`).
    *   **Priority 2**: Operational and adapter layers (e.g., `adapter-core`, `l2-adapters`).
    *   **Priority 3**: Legacy or exploratory modules that may need deprecation or heavy refactoring (e.g., `chaos`, `moonshine`).
*   **Deliverable**: An `Ensemble_Triage_Matrix.md` tracking the status of all 90 items.

## 3. Phase II: The Migration Loop
For each prioritized ensemble, we will execute the following loop:
1.  **Extract & Refactor**: Port core logic to Rust (if not already), aligning with the `multiplicity-common` types.
2.  **Govern & Bind**: Wrap the core in the required policy checks. Ensure that execution adheres to L0 invariants (producing a `UnifiedWitness`).
3.  **Bridge**: Develop the necessary `adapter.py` or WASM bridges.
4.  **Test & Verify**: Run `cargo test --test governance` and generate the required JSON fidelity reports.
5.  **Document**: Write or update the formal specification document.

## 4. Phase III: Certification & Relocation
*   Once the Migration Loop is complete, the ensemble is reviewed against the Rooting Standard.
*   If all checks pass, the directory is moved from `ensembles/<name>` to `substrates/<name>`.
*   The `Archivum` ledger is updated with a certificate of migration.

## Next Steps to Begin
1.  Do you approve of this standard based on `pweh-parser`?
2.  Would you like me to run an automated script to generate the initial **Triage Matrix** for the 90 ensembles so we can pick our first target?
