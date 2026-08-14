# ADR 0003: Corpus-Scale Frequency Analysis Architecture

## Status
Accepted

## Context
To move PARM from a theoretical prototype to a production-grade analytical tool, we required statistical baselines. Defining Resonance Quotient bands (Phase 0, Phase 1, Phase 2) using arbitrary cutoffs on 12 curated words was insufficient. We needed to process the entire lexical corpus to map empirical percentiles and investigate large-scale semantic clustering. *(Reference: `docs/Corpus-Scale Frequency Analyzer.md`)*

## Decision
We implemented a high-throughput corpus analysis pipeline leveraging the **Open Scriptures Hebrew Lexicon (OSHL)** (and eventually OSHB / ETCBC/BHSA for morphological frequency). 

The pipeline:
1. Ingests canonical lexical entries (`HebrewStrong.xml`).
2. Cleans text by stripping non-Hebrew diacritics and applying Sofit normalization.
3. Computes the five core multi-channel metrics: $RQ_s$, $RQ_n$, $C$, $\Delta$, and $Ratio$.
4. Exports normalized structural metrics for statistical analysis and mapping (e.g., 2D scatter plots).

## Consequences
- **Statistical Anchoring**: Allowed us to define phase boundaries using true percentiles (e.g., Phase 2 = $\ge 90$th percentile).
- **Tooling Expansion**: Introduced external dependencies like `xml.etree.ElementTree`, `csv`, and `matplotlib`.
- **Validation**: Demonstrated that the Extremal Heuristic (ADR 0002) performs robustly over 6,242 unique entries in real-time.
- **Future Integration**: Next steps will map semantic frequency weighting ($f \cdot C$) across biblical occurrences, requiring integration with frequency dictionaries.
