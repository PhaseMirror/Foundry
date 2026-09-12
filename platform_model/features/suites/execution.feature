Feature: execution

  @EX-01 @build
  Scenario: lean4-prod exports compilable LCNF from LexLean-generated Lean modules.
    Given verified generated Lean modules
    When lean4-prod extracts LCNF
    Then valid kernel.ir s-expressions are produced

  @EX-02 @build
  Scenario: lean4-prod transitive closure extraction resolves all dependencies without opaque gaps.
    Given registered runtime roots
    When transitive closure is computed
    Then all compilable callees are resolved with zero opaque gaps

  @EX-03 @build
  Scenario: Generated Rust validators are no_std compatible and perform no heap allocation during validator calls.
    Given LCNF IR from lean4-prod
    When prod-codegen generates Rust
    Then the output is no_std compatible and contains no heap allocations

  @EX-04 @build
  Scenario: The Rust host strictly decodes canonical Holo and normalizes string IDs to indexes.
    Given a canonical Holo document
    When decoded by the Rust host
    Then string IDs are normalized to consecutive zero-based Nat indexes

  @EX-05 @build
  Scenario: Generated Rust validators correctly evaluate normalized Holo models.
    Given normalized model data
    When passed to generated Rust validator functions
    Then validation results match Lean formal semantics

  @EX-06 @build
  Scenario: Exhaustive generated-Rust evaluation matches the expected truth tables stated and proved in .lex.tex for the fixed small-model bounds.
    Given an exhaustive corpus of small bounded models
    When generated Rust is compared with the committed formal truth-table oracle
    Then all outcomes are identical

  @EX-07 @build
  Scenario: Deterministic property tests with committed seeds exercise validator behavior within the recorded finite strategies and bounds.
    Given property-based test suites with fixed seeds
    When proptests execute
    Then all invariant properties hold across generated models

  @EX-08 @build
  Scenario: Generated Rust validators never panic on caller-controlled inputs.
    Given arbitrary, malformed, or out-of-bounds input data
    When passed to validator entry points
    Then validators return structured error codes without panicking

  @EX-09 @build
  Scenario: Erased proof fields are not claimed as runtime checks.
    Given compiled Rust validators
    When proof fields are erased
    Then host adapters recheck runtime preconditions explicitly

  @EX-10 @build
  Scenario: Type boundary conversions between Lean Nat and Rust u64 are explicitly bounded.
    Given numeric conversions at the FFI boundary
    When large values are passed
    Then overflows are detected and handled without wrapping
