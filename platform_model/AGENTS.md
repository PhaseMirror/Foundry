# Agent Guidelines for PrismPM

- SPEC.md is normative; README prose is explanatory.
- No handwritten `.lean` source or `lakefile.lean` may be committed in PrismPM. All Lean code is generated from `.lex.tex` by LexLean.
- Do not introduce placeholder URLs, wildcards in internal dependencies, unpinned toolchains, or unstaged modifications.
- Every public capability and diagnostic is registered in `model/*.toml` and covered by conformance fixtures.

