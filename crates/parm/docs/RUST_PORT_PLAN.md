# Rust Porting Plan: Position-Aware Recursive Multiplicity (PARM)

## Objective
Rewrite the PARM (Position-Aware Recursive Multiplicity) project from Python to Rust.

## Core Components to Port
1. **PARM Engine (`parm.py`)**:
   - Gematria/Primes mappings.
   - `sealed_state` calculation (the algorithmic core).
   - Resonance Quotient (RQ) and coupled RQ calculations.
   - Word analysis pipeline.
2. **Data Processing**:
   - Lexicon parsing (`HebrewLexicon/*.xml`).
   - Corpus analysis (`parm_corpus.py`, `parm_frequency_analyzer.py`).
   - Semantic clustering (`parm_semantic_clustering.py`).
3. **Visualization/Outputs**:
   - Generation of plots (Rust crates: `plotters` or `plotly`).
   - CSV result generation (`csv` crate).

## Proposed Rust Architecture
- **Library (`lib.rs` / `parm_core` crate)**: Houses the `PARM` struct and logic.
- **CLI Tool (`main.rs` / `parm_cli` crate)**: Provides the interface to run analysis on words, files, or the full corpus.
- **Dependencies**:
  - `serde` / `quick-xml`: For XML lexicon parsing.
  - `serde` / `csv`: For CSV results.
  - `ndarray` / `nalgebra`: If complex linear algebra is needed (though current math seems scalar).
  - `plotters`: For generating visuals.

## Migration Strategy
1. **Phase 1: Core Logic**: Reimplement `parm.py` in Rust. Add comprehensive unit tests in Rust to verify parity with Python results (e.g., test cases from `test_parm.py`).
2. **Phase 2: Data Ingestion**: Reimplement XML parsing logic.
3. **Phase 3: Analysis Pipelines**: Port the corpus and clustering analysis.
4. **Phase 4: Visualization/Reporting**: Reimplement reporting functionality.

## Verification
- For each ported module, run both Python and Rust versions on identical test inputs (`test_corpus.csv`) to ensure bit-perfect or high-precision numerical parity.
