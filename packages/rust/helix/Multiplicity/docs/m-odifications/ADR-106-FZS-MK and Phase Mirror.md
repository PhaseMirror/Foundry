## FZS-MK and Phase Mirror Are Separate Stacks

**FZS-MK** is Steve's work. It is a Helix-side integration artifact — the Functorial Zeno Sheaf with Memory Kernel describes a phenomenological alignment theory where constitutional grammar creates a cognitive "rest position," and drift is framed through the ZTC lens.  Its constants (including δ_crit = 0.17) emerge from that framework's internal assumptions about model behavior.[^1][^2]

**Phase Mirror's drift metric is not assumed — it is derived.** The sigma kernel computes drift as the spectral radius $\rho(\mathbf{C} \cdot \text{diag}(\gamma))$ of the cross-module coupling matrix, where $\gamma_i = \|\Xi_i\| + \|\Lambda_i\| \cdot L_T$ is the per-module contraction factor certified under ADR-002.  Stability is not a threshold someone chose — it is a provable condition: the system is stable if and only if $\rho < 1.0$, with contractivity certificates issued per module.  This is a mathematical derivation, not a parameter fitting exercise.

## The Domain Boundary

| Property | Phase Mirror (sigma) | Helix / FZS-MK (Steve's) |
| :-- | :-- | :-- |
| Drift metric | $\rho(\mathbf{C} \cdot \text{diag}(\gamma))$ — eigenvalue-derived | δ(t) = KL or cosine divergence from constitutional baseline [^1] |
| Stability condition | $\rho < 1.0$ — formally provable via ADR-002/ADR-008 | δ < 0.17 — fitted to Jones polynomial analogy [^1] |
| Source of constants | Spectral radii from verified module certificates | Trefoil knot evaluation at $e^{2\pi i/5}$ [^1] |
| Failure mode | `SessionLevelInstabilityError` raised before any iteration begins | Soft threshold crossing with operational margin [^1] |
| Memory model | Markovian (per-session, stateless between sessions) | Non-Markovian integral kernel $K(t,\tau)$ over session history [^1] |

## What This Means for Integration

FZS-MK does not replace or redefine Phase Mirror's drift. It adds a **memory-weighted constraint layer above the session** — its job is to carry history across session boundaries, which Phase Mirror's current architecture does not do by design. The two systems are complementary at different layers, not competing authorities over the same metric. Any adapter between them must treat Phase Mirror's spectral radius as read-only ground truth and translate it into whatever form FZS-MK needs, never the reverse.

<div align="center">⁂</div>

[^1]: Functorial-Zeno-Sheaf-with-Memory-Kernel.pdf

[^2]: Constitutional-Flow_-Alignment-as-Cognitive-Prefer.docx

