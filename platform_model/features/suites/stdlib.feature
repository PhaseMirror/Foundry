Feature: stdlib

  @ST-01 @build
  Scenario: Prism-stdlib defines core ISO 42010 architectural primitives in Foundation.Arch.
    Given stdlib/src/Foundation/Arch.lex.tex
    When processed by LexLean
    Then Component, Edge, Stakeholder, and Viewpoint primitives are defined

  @ST-02 @build
  Scenario: Prism-stdlib defines ISO 27034 security primitives in Foundation.Sec.
    Given stdlib/src/Foundation/Sec.lex.tex
    When processed by LexLean
    Then SecurityControl and Activity primitives are defined

  @ST-03 @build
  Scenario: Prism-stdlib defines ISO 27005 risk primitives in Foundation.Sec.
    Given stdlib/src/Foundation/Sec.lex.tex
    When processed by LexLean
    Then Asset, Threat, and Risk primitives are defined

  @ST-04 @build
  Scenario: Prism-stdlib defines ISO 25010 quality primitives in Foundation.Qual.
    Given stdlib/src/Foundation/Qual.lex.tex
    When processed by LexLean
    Then QualityCharacteristic and Measure primitives are defined

  @ST-05 @build
  Scenario: Prism-stdlib is authored strictly in .lex.tex with no handwritten Lean source.
    Given the stdlib/ directory tree
    When scanned for source files
    Then only .lex.tex files exist and no handwritten .lean files are present

  @ST-06 @build
  Scenario: Prism-stdlib models allow cyclic component graphs while rejecting dangling references.
    Given a component model with cycles and resolved endpoints
    When validated by Prism-stdlib validators
    Then cycles are accepted and dangling edges are rejected

  @ST-07 @build
  Scenario: Prism-stdlib proves cross-facet consistency theorems with empty observed axiom sets.
    Given cross-facet models in stdlib
    When verified with Lean
    Then all consistency theorems hold with empty observed axiom sets

  @ST-08 @build
  Scenario: Prism-stdlib exports registered runtime validator roots.
    Given Foundation.Holo validators
    When exported for compilation
    Then registered validator roots match exact specifications

  @ST-09 @build
  Scenario: Prism-stdlib includes golden test outputs for all published artifacts.
    Given stdlib expected outputs
    When build runs
    Then published artifacts equal committed oracles

  @ST-10 @build
  Scenario: Prism-stdlib models validate through the Holo projector and Lean kernel.
    Given stdlib models
    When projected to Holo and checked with Lean
    Then validation succeeds across all facets
