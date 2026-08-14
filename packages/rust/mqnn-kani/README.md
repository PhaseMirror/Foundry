# M-QNN Multiplicity Theory (Kani Verifier)

This crate (`mqnn-kani`) implements the adaptive shot-allocation loop and Hoeffding early-exit oracle for the M-QNN framework, formally verified via Kani Bounded Model Checking.

## Verified Properties (Kani Proofs)
- **No Panic:** The `step` function never overflows (enforced by `saturating_add`), and `is_better_certified_than` never divides by zero.
- **Shot-Sufficiency:** Certification requires $shots \ge threshold$. Kani mechanically proves that no candidate can exit early without physical execution cycles.
- **Algebraic Consistency:** The deterministic integer inequalities faithfully mirror the continuous Hoeffding inequality limits across all bounded states.

## Integration Architecture
This verified core acts as the unalterable truth for adaptive sampling. It is designed to be bound via PyO3/Maturin to Qiskit runtime programs. When the classical Python controller needs to decide whether to stop or allocate another shot, it queries this compiled, zero-drift Rust oracle.

## Boundary of Probabilistic Guarantees
Because Kani exclusively evaluates deterministic state trees, the probabilistic guarantee (e.g., "with probability $\ge 1-\delta$ the selected neighbor is optimal") is relegated to an external pen-and-paper theorem mapping. Kani's role is to ensure that the *implementation* of the derived scaling factor never deviates from the algebraic definition under any arbitrary shot count.
