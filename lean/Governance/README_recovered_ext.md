# MOC v2: Lean Core + Lisp Frontend

This is the port of Multiplicity Operator Calculus (MOC) from version 1 (Python) to a formally verified Lean core with an ergonomic Lisp macro frontend.

## Directory Structure

- `lean/`: Lean 4 core specification and proofs.
  - `MOC/Core.lean`: Basic types and operator definitions.
  - `MOC/Resonance.lean`: Resonance components and aggregation logic.
  - `PIRTM/Default.lean`: Transition models and stability levels.
  - `Proofs.lean`: Formal proof targets for MOC/PIRTM logic.
- `lisp/`: Common Lisp macros for generating MOC words.
  - `moc.lisp`: Main macro and function definitions.
- `bridge/`: Interop between Lisp and Lean.
  - `sexpr_to_lean.py`: Converts Lisp S-expressions to Lean operator words.
- `docs/`: Documentation (linked from root).
- `Justfile`: Automation for bridge and testing.

## Getting Started

### Prerequisites

- [Lean 4](https://lean-lang.org/) and `lake`.
- Python 3 (for the bridge).
- A Common Lisp environment (optional, for the frontend).

### Workflow

1. **Compose** a MOC word in Lisp:
   ```lisp
   (moc-108-cycle :w0 1.2)
   ```
2. **Translate** to Lean using the bridge:
   ```bash
   just bridge "((subdivision 3 3) (subdivision 2 2) (accent 27 1.2 0))"
   ```
3. **Verify** in Lean:
   ```bash
   just run-lean
   ```

## Roadmap

See `MOC_LEAN_LISP_ROADMAP.md` in the root for the full implementation plan.
