# ADR 101: Tree-sitter Grammar for PIRTM-lang

## Status
Accepted

## Context
PIRTM operators require strict adherence to the **Prime Successor Predicate**. Conventional parsers do not support state-level dependencies on prime numbers.

## Decision
We define the PIRTM grammar using `tree-sitter`, enforcing structural validity of operator sequences. Semantic prime-successor checks are delegated to the post-parsing `AdmissibilityValidator` to maintain parser performance while guaranteeing adherence to the prime-index continuity rule.

## Consequences
- **Pros**: Enables robust AST generation; provides a standard interface for IDEs (LSP support).
- **Cons**: Requires a two-pass validation (Parsing -> Semantic Semantic) to fully enforce the Successor Predicate.
- **Sedona Spine Alignment**: Directly satisfies the governance requirement that all ESI-related ESI-related operator words must be admissible.
