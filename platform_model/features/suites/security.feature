Feature: security

  @SE-01 @build
  Scenario: All filesystem operations are confined within configured output roots.
    Given file read and write requests
    When paths are resolved
    Then all writes remain strictly within the configured build or target directory

  @SE-02 @build
  Scenario: Symlinks and relative paths that escape project boundaries are rejected.
    Given symlinks or relative paths pointing outside repository root
    When resolved by the engine
    Then the escaping path is rejected with error PP8001

  @SE-03 @build
  Scenario: Process execution executes child binaries directly without invoking a shell.
    Given command execution for external tools
    When processes are spawned
    Then std::process::Command executes the target binary directly with argv array

  @SE-04 @build
  Scenario: Environment variables passed to child processes are sanitized and normalized.
    Given child process invocation
    When environment is configured
    Then unnecessary host variables are cleared and required paths are normalized

  @SE-05 @build
  Scenario: File publications use atomic rename operations to prevent partial writes.
    Given artifact publication steps
    When writing files to disk
    Then temporary files are written first and atomically renamed into place

  @SE-06 @build
  Scenario: Memory safety is enforced across all Rust crates with unsafe code forbidden.
    Given all Rust source files in workspace
    When scanned for unsafe keyword
    Then no unsafe blocks exist and forbid(unsafe_code) is active

  @SE-07 @build
  Scenario: Input parsing rejects excessively large inputs before memory exhaustion.
    Given oversized or deeply nested input documents
    When parsed by Holo or configuration parsers
    Then limits are enforced before allocating excessive memory

  @SE-08 @build
  Scenario: Dependency audits with cargo-deny enforce license and advisory policies.
    Given the workspace Cargo.lock
    When cargo-deny checks dependencies
    Then zero advisories, bans, or unauthorized licenses exist
