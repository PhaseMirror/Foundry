# ADR-002: Cross-Fibre Multiplicity Contractivity Proof

## Status
Proposed / Accepted

## Context
Following the formal mechanization of the single-fibre deterministic backbone of the ROC Multiplicity Engine (ADR-001), the next logical step is validating the "conscious-regime signature": simultaneous lawful behavior across coupled fibres (e.g., physical, social, neural). We must rigorously prove that small symmetric couplings between independently contractive fibres preserve a joint Fejér-monotone descent.

## Decision
We will introduce `RocEngine/CrossFiber.lean` into the existing Lean 4 Substrates project. 
The module will:
1. Define a `JointState` containing two independent discrete `State` fibres (e.g., Physical and Social).
2. Introduce a joint Lyapunov functional `V_joint(js) = V(js.phys) + V(js.soc)`.
3. Introduce a joint update operator `joint_T` featuring bounded cross-talk (coupling) states $K_{phys}$ and $K_{soc}$.
4. Prove `cross_fiber_descent`: If the isolated fibres' contractivity margin is large enough to absorb the incoming cross-talk from the coupling, the joint system preserves the Fejér-monotone descent ($V_{joint}(joint\_T) \le V_{joint}(js)$).

## Consequences
- **Positive**: Provides a machine-checked mathematical guarantee that inter-fibre resonance does not break the $\Lambda_m$-contractivity schema. This unifies the algebraic foundation of the conscious-regime signature across the entire multiplicity stack.
- **Negative**: Adds combinatorial complexity to the Lean codebase. The discrete addition models the continuous coupling operator linearly, which requires careful alignment when porting metrics back to the Python simulation layer.
