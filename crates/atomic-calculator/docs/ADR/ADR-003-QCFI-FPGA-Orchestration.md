# ADR-003: QCFI FPGA Orchestration & Hardware Pulse Calibration

## Status
Proposed

## Context
The Qudit-Classical Feedback Interface (QCFI) requires real-time bidirectional feedback to reconfigure qudit dimensions (e.g., $d=16 \leftrightarrow d=8$) dynamically based on the calculated `ThermalWindow`. To ensure qudit coherence times are not exceeded during these feedback loops, we must minimize latency. Additionally, the HSEC (Hyperfine Subspace Error Correction) relies on hardware-native pulse calibration to utilize auxiliary manifolds (such as $F=7/2$ in $^{133}$Cs) without destructive projective readout.

## Decision
We will deploy a tightly coupled FPGA-based control system collocated with the QPU to handle QCFI logic natively.
1. The primary hardware backend is standardized to **Infleqtion ($^{133}$Cs, $d=16$)** to leverage the maximum qudit manifold space for HSEC buffer allocation.
2. The Rust SDK will implement a hardware pulse calibration layer (`fpga_pulse.rs`) that safely bridges the MA-VQE logical instructions to FPGA microwave pulse outputs.
3. HSEC calibration will occur directly on the FPGA edge node before evaluating mid-circuit states against the SnapKitty $S(\rho) \leq H_{\max}$ bound.
4. All bindings will continue to route through the Sedona Spine ALP policy gates, ensuring no agent can independently alter calibration thresholds.

## Consequences
- **Positive**: Near-zero latency for QCFI dimension shifting, ensuring coherence boundaries are respected. Secures stable auxiliary manifolds for HSEC.
- **Negative**: High complexity in edge-node deployment and tight hardware coupling requiring vendor-specific pulse APIs.

## Next Steps
1. Wire `qcfi.rs` outputs to the new FPGA pulse calibration layer.
2. Formally assert pulse bounds on the $^{133}$Cs manifold.
