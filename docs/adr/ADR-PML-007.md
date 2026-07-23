## Addendum: Production Concurrency Invariants (2026-07-22)

### L0 Invariants (Non-Negotiable)
1. **No Mathlib**: All Lean 4 specifications must import `Init` and `Std` only. `Mathlib` is explicitly forbidden in `lakefile.lean`.
2. **Sorry-Bounded**: Any `sorry`/`admit` in the `Core/Spec/` directory must be manifested in `alp_sorry_manifest.json`. Unmanifested sorrys block CI deployment. Proofs are discharged via Kani BMC harnesses (FFI-imported tokens).
3. **Concurrency Bound**: For any theoretical extension (e.g., Universal Completion), the completion algorithm (`rust/src/completion.rs`) **must** sustain:
   - \( N \le 100 \) concurrent requests
   - \( q \le 69 \) qudits per request
   - \( \varepsilon < 15 \) mHa energy error
   - \( S \le 6.0 \) entropy

### Decision: Concurrency First
- The Universal Completion category (UC) is deferred to ADR-008.
- UC work is frozen until the FeMoco_100_Concurrent_Load_Test passes.
- Rationale: The free-monoid initiality required for the NNO conjecture is *already structurally present* in Operator-First Arithmetic. We do not need a new category definition to unblock QaaS throughput.
