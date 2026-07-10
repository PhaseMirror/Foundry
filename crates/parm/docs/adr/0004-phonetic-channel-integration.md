# ADR 0004: Phonetic Resonance Channel Integration

## Status
Proposed

## Context
Currently, PARM maps two parallel invariant channels: $\pi_s$ (Lexicographic Shape) and $\pi_n$ (Numeric/Gematria). A core theoretical extension is identifying a third fundamental linguistic invariant. Phonetic properties present an orthogonal domain of resonance, where words might cluster based on sound characteristics regardless of shape or numeric overlap. *(Reference: `docs/Phonetic Resonance Mapper.md`)*

## Decision
We propose integrating a third analytical channel: **Phonetic Resonance ($RQ_p$)**.

The architecture will introduce a mapping system assigning primes based on phonetic class constraints:
- **Version A (Class-Prime Mapping)**: Consonants map directly to a small set of phonetic class primes (e.g., Labials $\to 2$, Dentals/Alveolars $\to 3$, Velars $\to 5$, Glottals $\to 7$, Sibilants $\to 11$).

The engine will independently run the PARM Seed/Flow/Seal recursion over this channel and integrate it into a new 3D metric topology.

## Consequences
- **Many-to-One Mapping Support**: Will stress-test the Extremal Ordering Heuristic against multisets with high degeneracy (frequent identical prime repetitions).
- **Validation Against Existing Literature**: Allows correlation checking against known phonetic thesauruses (e.g., LT4HALA 2020 paper).
- **Pipeline Complexity**: Modifies the output schema of our corpus analyzers, changing from 2D coordinates to 3D space, necessitating updates to `matplotlib` visualization scripts and metric structures.
