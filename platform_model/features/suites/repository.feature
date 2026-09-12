Feature: repository

  @RP-01 @build
  Scenario: PrismPM is structured as a virtual Rust workspace with pinned toolchains.
    Given a clean repository checkout
    When cargo metadata is evaluated
    Then the workspace contains crates/prismpm, crates/model, crates/conformance, and xtask

  @RP-02 @build
  Scenario: Toolchain versions for Rust and Lean are pinned in rust-toolchain.toml and lean-toolchain.
    Given the repository root
    When rust-toolchain.toml and lean-toolchain are inspected
    Then Rust is pinned to 1.97.1 and Lean is pinned to leanprover/lean4:v4.32.1

  @RP-03 @build
  Scenario: Every model claim is authored in model/*.toml and validated by cargo xtask validate-model.
    Given the model/ directory
    When cargo xtask validate-model runs
    Then all registers check without inconsistency

  @RP-04 @build
  Scenario: The devcontainer and CI enforce hermetic build and test environments.
    Given .devcontainer/devcontainer.json and .github/workflows/vv.yml
    When container definitions are verified
    Then toolchains and dependencies are hermetically provisioned

  @RP-05 @build
  Scenario: All public crates forbid unsafe code and enforce strict lints.
    Given workspace crate manifests
    When lints are checked
    Then missing_docs, unsafe_op_in_unsafe_fn, and unsafe code are forbidden

  @RP-06 @build
  Scenario: The Justfile exposes vv as the primary acceptance gate.
    Given the Justfile at repository root
    When recipe vv is executed
    Then it orchestrates the full acceptance pipeline

  @RP-07 @build
  Scenario: The SPEC.md capability table and model/ids.toml are bijective and consistent.
    Given SPEC.md and model/ids.toml
    When cargo xtask validate-spec-links runs
    Then every capability ID matches exactly one specification entry

  @RP-08 @build
  Scenario: Every public capability has exactly one Gherkin scenario and one named conformance test.
    Given the suite of .feature files
    When the honesty meta-gate scans tests
    Then every ID has one matching scenario and one conformance test

  @RP-09 @build
  Scenario: Two clean builds in distinct absolute directories produce byte-identical platform-independent outputs.
    Given two distinct temporary directories
    When prismpm build is executed in both
    Then all published platform-independent artifacts are byte-identical

  @RP-10 @build
  Scenario: All generated documentation is regenerated and validated against model registers.
    Given CONFORMANCE.md and ERRORS.md
    When cargo xtask validate-model runs
    Then committed files equal generated markdown bytes

  @RP-11 @build
  Scenario: License metadata and files conform to dual MIT/Apache-2.0 requirements.
    Given LICENSE-MIT, LICENSE-APACHE, and workspace manifests
    When cargo deny checks licenses
    Then dual licensing holds across all crates

  @RP-12 @build
  Scenario: Release artifacts are refused unless all release criteria and verifications hold.
    Given cargo xtask release-check
    When unverified or incomplete criteria exist
    Then release is refused with specific unmet criteria
