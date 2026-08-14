# ADR-SED-002: Lineage-Based Scoring and Admissibility Thresholds

## Status
Proposed

## Context
To guarantee that data-versioning layers (DVC) and prime-zero tracking files are untampered, we require an algorithmic framework to evaluate data quality before processing numerical updates.

## Decision Drivers
* **Data Integrity**: Preventing tampering with tracking files.
* **Autonomous Auditing**: Deterministic evaluation of data quality.
* **Fail-Closed Security**: Ensuring system aborts on sub-threshold data quality.

## Decision
Implement a deterministic scoring suite calculating explicit data metrics across three vectors: Freshness ($S_f$), Completeness ($S_c$), and Accuracy ($S_a$). If the aggregated compound score falls below the $p=7$ threshold (0.95), the state transformations are aborted under a strict **Fail-Closed** policy.

### Scoring Logic
* **Freshness ($S_f$)**: $S_f = \exp(-\text{age} / \text{max\_age})$
* **Completeness ($S_c$)**: $S_c = \text{active\_channels} / \text{total\_channels}$
* **Accuracy ($S_a$)**: $S_a = 1.0 / (1.0 + \text{variance})$
* **Composite Score**: $(S_f \cdot S_c \cdot S_a)^{1/3}$

## Consequences
### Positive
* Robust protection against stale or incomplete data.
* Quantifiable trust levels for all processed artifacts.
* Automated enforcement of $p=7$ lineage standards.

### Negative
* Requires careful tuning of max age and variance tolerances.
* Potential for "false halts" if thresholds are too aggressive for experimental setups.
