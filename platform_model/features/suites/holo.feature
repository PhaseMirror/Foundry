Feature: holo

  @HO-01 @build
  Scenario: A Holo/1 artifact is a strict binary Hologram archive with physical version 4 and the HOLO header.
    Given a modeled application archive
    When its physical bytes are emitted
    Then they begin with HOLO and little-endian physical version 4

  @HO-02 @build
  Scenario: The non-Holo Prism model document uses the closed prismpm/model-document/1 schema and model.prism.json name.
    Given a projected Prism model document
    When its build artifact and schema are inspected
    Then the closed schema and non-Holo filename agree

  @HO-03 @build
  Scenario: Prism model documents use deterministic canonical JSON and an exact SHA-256 model identity.
    Given canonical model.prism.json bytes
    When canonical encoding and SHA-256 identity are checked
    Then the bytes and declared model identity agree

  @HO-04 @build
  Scenario: The model-document projector is a total deterministic function from valid LexLean semantic snapshots.
    Given a valid LexLean semantic snapshot
    When the model-document projector runs
    Then a complete Prism model document is produced deterministically

  @HO-05 @build
  Scenario: Model entity identifiers are qualified strings assigned deterministic zero-based indexes.
    Given a projected Prism model document
    When runtime index assignment occurs
    Then entities receive unique, consecutive zero-based Nat indexes

  @HO-06 @build
  Scenario: Platform-independent Prism model and Holo artifacts exclude host paths, timestamps, and unstable environment data.
    Given generated Prism model and application artifacts
    When their platform-independent contents are inspected
    Then no timestamps, absolute paths, or host identifiers are present

  @HO-07 @build
  Scenario: Holo decoding rejects legacy JSON, noncanonical archives, malformed values, and unsupported physical versions.
    Given legacy JSON or malformed Holo archive bytes
    When the strict Holo/1 validator parses input
    Then validation fails at a registered archive diagnostic

  @HO-08 @build
  Scenario: The emitter-semantics ID uniquely identifies the model-document projector inputs.
    Given model/emitter-inputs.toml
    When input files are hashed
    Then the computed tree digest equals the declared emitter-semantics ID

  @HO-09 @build
  Scenario: Shared goldens bind generated Lean, canonical model documents, and binary Holo application projections to their sources.
    Given committed source-bound golden vectors
    When their manifests and artifact bytes are checked
    Then generated declarations and both projection formats are traceable to the same model

  @HO-10 @build
  Scenario: Holo/1 validation checks canonical sections, identities, content closure, directory derivation, and closed Prism provenance.
    Given a valid archive and one-field-at-a-time mutations
    When Holo/1 validation executes
    Then every disagreement is rejected before acceptance
