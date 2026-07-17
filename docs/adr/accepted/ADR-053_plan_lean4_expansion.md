# Architecture Decision Record (ADR): Lean 4 Formalization & Integration Strategy

## 1. Context and Problem Statement
Several new folders have been added to the `lean/` directory (e.g., `UMCPAROM`, `F1_SQUARE`, `ECHO_BRAID`, `MULTIPLICITY`, etc.). These folders currently contain `.tex` manuscripts detailing mathematical and physical theories. 
Our goal is to **uniformly expand these into Lean 4 proofing projects**, integrating them coherently into the overarching PhaseMirror ecosystem. The key decision is how to structure these projects architecturally: should they be isolated Lake projects, unified as packages within a monorepo, or reorganized differently?

## 2. Identified Sub-Domains (from `.tex` files)
Based on the file system, the following major domain clusters have been identified:
- **Core Mathematics & Logic**: `F1_SQUARE`, `UAC` (Universal Atomic Calculator)
- **Physics & Relativistic Systems**: `GENESIS_ODE`, `META_MATERIALS`, `H-BEC`, `LORENZ_ATRACTOR`
- **Multiplicity Framework**: A massive cluster under `MULTIPLICITY` with sub-theories (Bohmian Dynamics, Moonshine, Operator Calculus, Matrices, Knot Theory)
- **Emerging Paradigms**: `ALP` (Atomic Language Processing), `ECHO_BRAID`

## 3. Proposed Architecture Options

### Option 1: Decentralized, Independent Lake Projects
Each directory becomes a standalone Lean 4 project with its own `lakefile.toml` / `lakefile.lean`.
- **Pros**: Complete isolation, independent dependency management, parallel development.
- **Cons**: High overhead to maintain many `lakefile`s. Harder to share cross-cutting theorems (e.g., sharing Multiplicity axioms with Physics).

### Option 2: Unified "Monorepo" Lake Workspace (Recommended)
Transform the root `lean/` directory into a massive **Lake Workspace**. Each folder (like `UMCPAROM`, `ECHO_BRAID`) becomes a **Lake package** or **library target** within the single monolithic `PhaseMirror` Lean project.
- **Pros**: 
  - Cross-referencing is seamless (e.g., `import Multiplicity.KnotTheory`).
  - Single toolchain version to manage via `lean-toolchain`.
  - Unified CI/CD pipeline and uniform build times.
- **Cons**: Monolithic build could eventually slow down if the codebase grows massively without proper caching.

### Option 3: Segregation of Documentation vs. Code
Move all `.tex` files to a `docs/papers/` directory. Keep `lean/` purely for `.lean` source files structured by namespace (e.g., `lean/Math/F1Square/`, `lean/Physics/HBEC/`).
- **Pros**: Cleanest source tree. Follows standard software engineering practices.
- **Cons**: Disconnects the formal proof code from the human-readable theoretical manuscript it formalizes.

## 4. Proposed Strategy & Implementation Plan

We recommend a **Hybrid of Option 2 and Option 3**: A unified Lean 4 Workspace utilizing [Lean Blueprint](https://github.com/PatrickMassot/leanblueprint) architecture.

### Step-by-Step Implementation:
1. **Workspace Unification**: 
   - Define a root `lakefile.toml` in `lean/` that declares each sub-folder as a `[[lean_lib]]` or a sub-package.
2. **Directory Standardization**: 
   - Within each sub-folder (e.g., `lean/ECHO_BRAID/`), establish:
     - `src/` or `.lean` files at the root of the folder.
     - `blueprint/` or `docs/` where the `.tex` files will live.
3. **Mapping `.tex` to `.lean`**:
   - Parse the main definitions and theorems from the `.tex` documents.
   - Create `.lean` "stubs" (using `sorry` for proofs) that correspond 1:1 with the definitions in the `.tex` files.
4. **Integration into the Whole**:
   - Establish a `PhaseMirror.lean` (or similar) root file that imports all sub-modules to ensure the entire tree typechecks successfully.
   - Set up CI to compile the Lean code and generate the corresponding Blueprint web documentation, linking LaTeX math directly to Lean 4 formalizations.

## 5. Next Steps
- Do you agree with a unified Lake workspace approach (Option 2), or would you prefer them completely standalone?
- Should we begin executing the directory standardization and generating the `lakefile` configurations?
