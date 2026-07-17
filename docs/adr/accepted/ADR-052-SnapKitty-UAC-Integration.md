# ADR-060: SnapKitty / UAC Integration

## Status
Proposed

## Context
The Universal Atomic Calculator (UAC) utilizes neutral-atom qudit architectures (e.g., $^{87}$Sr, $^{133}$Cs) for atomic self-simulation. Key components include the Qudit-Classical Feedback Interface (QCFI) for dimension shifting, MA-VQE for compilation, and Hyperfine Subspace Error Correction (HSEC) for leak detection.

Simultaneously, the SnapKitty Sovereign OS Math Engine provides compiler-proven formalisms for thermodynamic windows, quantum monad operations, entropy tracking, and mirror symmetry (the 49th Call). Currently, UAC heuristics for scaling dimensions and pruning VQE branches lack thermodynamic rigor, exposing the system to edge-case vulnerabilities and drift.

## Decision
We will formally integrate SnapKitty's pure-math models into the UAC architecture to replace operational heuristics with compiler-proven physics constraints, strictly adhering to the Sedona Spine mandate.

### 1. QCFI & Thermodynamic Window
- **Current:** QCFI shifts dimensions ($d=16 \leftrightarrow d=8$) based on a heuristic error threshold $\varepsilon_0$.
- **New:** QCFI will ingest SnapKitty's EMA friction model. The dimension $d$ will be deterministically bound by the `ThermalWindow` ($\mathrm{lo}(f) < \mathrm{hi}(f)$). High friction narrows the window, logically enforcing a dimension reduction equivalent to cooling into a ground state.

### 2. MA-VQE & The Quantum Monad
- **Current:** MA-VQE partitions dimensions algorithmically.
- **New:** The variational search tree will be modeled as a SnapKitty Quantum Superposition Monad. The "no-cloning" corollary natively destroys failed or unphysical branches during the `bind` operation, mathematically pruning the search space.

### 3. HSEC & Entropy Bounds
- **Current:** HSEC monitors variance in the auxiliary subspace to detect leakage.
- **New:** The auxiliary subspace will be evaluated using SnapKitty's Von Neumann entropy and KL Divergence models. Leakage will be mathematically quantified as entropy, and error correction will only proceed if $S(\rho) \leq H_{\max}$ (6.0 bits).

### 4. Gate Fidelity & The 49th Call
- **Current:** Unitarity verification requires expensive classical simulation.
- **New:** The system will utilize SnapKitty's $\operatorname{call}_{49}(\mathcal{S}) = \operatorname{reverse}(\mathcal{S})$ to enforce mirror identity $C(C(X)) = X$. This provides a zero-cost topological audit of microwave pulse sequence symmetry.

## Consequences
- **Positive:** Replaces heuristics with strict, provable physics boundaries. Ensures Sedona Spine compliance by routing all quantum state decisions through the formal `ALP` and `MOC` paths.
- **Negative:** Increased upfront engineering effort required to bridge the Rust UAC SDK with the newly defined SnapKitty Lean axioms.

## Next Steps
- [x] Expand `lean/SNAPKITTY/SnapKitty/Core.lean` to formally define `ThermalWindow`, `call49`, and `VonNeumannEntropy`.
- [ ] Extract these bounds via `build.rs` to inform the Rust UAC controller.
- [ ] Update the `QCFI` Rust implementation to respect the compiled `ThermalWindow` constraints.
