Feature: verification

  @VR-01 @build
  Scenario: LexLean verifies formal models against the Lean 4.32.1 kernel.
    Given generated Lean declarations
    When Lean 4.32.1 elaborates the modules
    Then type-checking succeeds in the kernel

  @VR-02 @build
  Scenario: Verification records executable digests and normalized toolchain commands.
    Given a completed verification run
    When process records are produced
    Then toolchain digests and normalized arguments are recorded

  @VR-03 @build
  Scenario: Lake stages generated Lean modules in isolated temporary workspaces.
    Given generated modules for verification
    When Lake environment is staged
    Then isolated temporary workspaces are used without host pollution

  @VR-04 @build
  Scenario: leanchecker replays compiled module environments independently.
    Given compiled olean modules
    When leanchecker replays the environment
    Then kernel replay succeeds

  @VR-05 @build
  Scenario: Axiom audits enforce that all PrismPM-owned theorems have empty observed axiom sets.
    Given verified PrismPM theorems
    When #print axioms is audited
    Then the observed axiom set is empty

  @VR-06 @build
  Scenario: Controller::verify publishes verified attestations under .prism/verified/<id>.
    Given a full verification pass
    When publication completes
    Then an attestation manifest is atomically published under .prism/verified/<id>

  @VR-07 @build
  Scenario: Verification manifests bind the Prism model document, Lean, LCNF, and Rust execution evidence.
    Given a published verification manifest
    When manifest contents are inspected
    Then all artifact digests and execution results are bound together

  @VR-08 @build
  Scenario: Verification fails if any Lean elaboration, replay, or axiom check fails.
    Given an invalid proof or unapproved axiom
    When verification executes
    Then the verification pipeline halts and publishes no attestation

  @VR-09 @build
  Scenario: Verification performs no hidden network access.
    Given verification running offline
    When Lean and Lake execute
    Then all operations succeed without network access

  @VR-10 @build
  Scenario: Process execution limits output size and execution time strictly.
    Given child process execution
    When output exceeds buffer limits or times out
    Then process is terminated and failure diagnostic is recorded

  @VR-11 @build
  Scenario: Planted defects in proofs or validators reliably trigger verification failure.
    Given an intentionally flawed theorem or validator
    When verification executes
    Then the exact failure is caught and reported

  @VR-12 @build
  Scenario: Repeated fixed-seed verification runs produce identical attestation digests.
    Given repeated verification runs with identical inputs
    When attestation digests are compared
    Then identical SHA-256 digests are produced
