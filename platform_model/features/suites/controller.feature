Feature: controller

  @CT-01 @build
  Scenario: The Controller API exposes owned request and result types for load, check, and build.
    Given the prismpm crate
    When Controller methods are invoked
    Then owned request and result types are returned

  @CT-02 @build
  Scenario: The Controller encapsulates LexLean Engine operations without exposing internal compiler types.
    Given Controller public interfaces
    When types are inspected
    Then LexLean internal IR types are not exposed

  @CT-03 @build
  Scenario: prismpm check validates models in memory without modifying the filesystem.
    Given a valid PrismPM project
    When prismpm check runs
    Then validation succeeds and the filesystem remains unmodified

  @CT-04 @build
  Scenario: prismpm build atomically publishes artifacts under content-addressed build directories.
    Given a valid PrismPM project
    When prismpm build runs
    Then artifacts are atomically published under .prism/build/<id>

  @CT-05 @build
  Scenario: The CLI produces structured machine-readable JSON output on stdout.
    Given prismpm CLI invocation with machine flag
    When command completes
    Then stdout contains valid canonical JSON

  @CT-06 @build
  Scenario: The Controller enforces positive resource and entity limits.
    Given project configuration with limits
    When limits are exceeded
    Then processing is halted with registered diagnostic codes

  @CT-07 @build
  Scenario: All public errors carry registered PP diagnostic codes.
    Given failure scenarios
    When diagnostics are emitted
    Then every error code belongs to the closed PP namespace

  @CT-08 @build
  Scenario: The Controller operates completely offline during build and check.
    Given network disabled
    When check or build is executed
    Then operations succeed without network requests

  @CT-09 @build
  Scenario: Project configuration is strictly validated against schemas/project.schema.json.
    Given prismpm.toml configuration
    When loaded by Controller
    Then unknown fields and invalid formats are rejected

  @CT-10 @build
  Scenario: The Controller preserves cause chains for underlying LexLean diagnostics.
    Given a LexLean syntax error
    When handled by Controller
    Then the original diagnostic cause is preserved in structured output

  @CT-11 @build
  Scenario: Controller cleanup removes only the configured real output directory and rejects a symlink target.
    Given a Prism project with a configured output directory
    When Controller cleanup is called
    Then only that real directory is removed and a symlink in its place is rejected
