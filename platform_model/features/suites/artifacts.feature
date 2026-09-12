Feature: artifacts

  @AR-01 @build
  Scenario: Build artifacts are published under content-addressed .prism/build/<id> paths.
    Given a successful build
    When published directory is inspected
    Then directory name matches the computed build ID

  @AR-02 @build
  Scenario: Every build directory contains a canonical manifest of file paths, sizes, and hashes.
    Given a published build directory
    When manifest.json is inspected
    Then all published files are listed with exact sizes and SHA-256 hashes

  @AR-03 @build
  Scenario: Artifact content IDs are derived from deterministic SHA-256 digests.
    Given generated build artifacts
    When content IDs are computed
    Then they equal the SHA-256 digests of canonical artifact bytes

  @AR-04 @build
  Scenario: Published artifacts contain no absolute paths, timestamps, or host identifiers.
    Given published build artifacts
    When scanned for host-specific tokens
    Then no timestamps, absolute paths, or hostnames are found

  @AR-05 @build
  Scenario: Artifact publication is atomic and leaves no partial state on failure.
    Given an induced failure during publication
    When publication fails
    Then no partial directory remains under .prism/build/

  @AR-06 @build
  Scenario: Rebuilding an identical project verifies existing artifacts before reuse.
    Given an existing published build
    When rebuild is requested
    Then existing artifacts are validated before reuse

  @AR-07 @build
  Scenario: Tampered build artifacts are detected and rejected.
    Given an existing build with modified artifact bytes
    When rebuild is attempted
    Then tampering is detected and publication fails

  @AR-08 @build
  Scenario: Canonical LaTeX and Lean artifacts reproduce byte-for-byte across runs.
    Given repeated builds of identical models
    When outputs are compared
    Then LaTeX and Lean files are byte-identical

  @AR-09 @build
  Scenario: Source maps provide complete token traceability between .lex.tex and generated Lean.
    Given generated Lean artifacts
    When source maps are queried
    Then every Lean declaration maps back to source .lex.tex tokens

  @AR-10 @build
  Scenario: Coverage reports document all modeled and unmodeled elements.
    Given a completed build
    When coverage.md is inspected
    Then all standards requirements and model entities are categorized
