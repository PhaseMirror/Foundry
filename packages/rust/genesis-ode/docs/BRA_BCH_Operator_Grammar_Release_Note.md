BRA / BCH Operator Grammar Release Note
We have completed the Bounded Reconstruction Asymmetry and Baker-Campbell-Hausdorff

operator grammar phase. The system now has a validated research protocol, a guarded

upgrade policy, runtime enforcement in the daemon, ledger-backed ratification, and a Lean 4

proof layer for the core invariants.[1][2]


What changed


Prototype and controller

The operator grammar maps internal generators 𝑃𝑖 and external overlay generators 𝑄𝑗 into a

non-commutative Lie setting, with an adaptive BCH controller that raises truncation order only

when ∆𝐵𝑅𝐴 becomes unstable or ambiguous. The cost functional remains

𝐶(𝑊) = ℓ(𝑊) + α𝑟(𝑊) + β𝑞(𝑊), so overlay histories pay a measurable reconstruction penalty

beyond simple tag counting.[1]


Empirical validation

Across baseline and adversarial fixtures, the prototype shows positive separation ∆𝐵𝑅𝐴 > 0,

and the adversarial tests expose a real divergence between full coupling and partial

decoupling. In the partial-decoupling control condition, the controller can halt early at order 2

with zero residual, while full coupling preserves higher-order activity and forces deeper

truncation. That means the controller is sensitive to embedding geometry, not just to static

penalties.[2][1]


Governance and regression policy

ADR-035 defines the operator Lie grammar as a validated research protocol, not a universal

final rule. ADR-036 adds the regression and generalization policy, which requires future matrix

families to preserve structure constants, cross-coupling asymmetry, truncation-order

divergence, and observability of the cost path. This keeps future upgrades from silently

collapsing the recomputation gap.[2][1]
Runtime enforcement

The generalization checks are now wired into the self-modification daemon’s validation gates,

so degenerate generator changes are blocked before they can alter the operator grammar. The

governance ledger also anchors the ratified ADRs, so the protocol is auditable rather than

informal.[2]


Formal proof

The Lean 4 formalization now proves the key invariants: partial decoupling halts early, while

full coupling preserves non-vanishing higher-order behavior. That gives the project three

layers of assurance: empirical tests, daemon-level enforcement, and machine-checked

invariants.[1][2]


Why it matters

The main result is not just that the prototype “works.” It now separates three things that were

previously easy to conflate: reconstruction cost, non-commutative geometry, and controller

behavior. The system can distinguish borrowed stability from independent recomputation,

which is the actual boundary the BRA work was aiming to measure. This is the point where the

prototype stops being a demo and starts behaving like a guarded protocol.[1][2]


Remaining assumption

The remaining assumption is that the chosen generator family and coupling policy are still the

right semantic model of the underlying problem. Lean proves the stated invariants, but it does

not prove that no other representation would be more suitable. So the right status is: validated

within the current protocol, not universally settled.[2][1]


Current state

The project is now complete for this phase:


  ●​ prototype implemented,
 ●​ adversarial tests passing,

 ●​ generalization policy enforced,

 ●​ daemon gate active,

 ●​ ledger ratified,

 ●​ and Lean 4 proofs compiled.[1][2]

If you want the next deliverable, the clean next step is a short handoff note for operations: what

the daemon enforces, what the ledger ratifies, and what future changes must reopen the

regression gate.[2]




What is enforced

 ●​ The daemon blocks generator changes that fail the operator grammar regression policy.[2]

 ●​ The generalization gate requires preserved structure constants, nonzero cross-coupling in

     the stress baseline, truncation-order divergence, and observable cost paths.[2]

 ●​ Partial decoupling remains a control condition only, not a default baseline.[1][2]


What is ratified

 ●​ ADR-035 defines the operator Lie grammar and adaptive BCH protocol as a validated

     research protocol.[1]

 ●​ ADR-036 defines the regression and generalization policy for future embedding

     upgrades.[2]

 ●​ The governance ledger records the ratified ADR hashes, so the current protocol is

     auditable.[2]


What is proven

 ●​ Lean 4 proves the early-halt condition under partial decoupling.

 ●​ Lean 4 proves truncation-order divergence under full coupling.
 ●​ These proofs cover the current protocol, not all possible future matrix families.[1][2]


What reopens the gate

A future change must reopen the regression gate if it:


 ●​ changes the generator set,

 ●​ changes the matrix family,

 ●​ weakens cross-coupling asymmetry,

 ●​ collapses truncation-order divergence,

 ●​ or hides the cost path or truncation depth.[2]


Operational note

The current status is stable for routine use. Any attempt to optimize or generalize the

embedding should be treated as a protocol change, not a routine refactor.[1][2]
