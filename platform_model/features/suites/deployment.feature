Feature: deployment

  @DP-01 @build
  Scenario: OCI-packaged target adapters consume canonical model, release, and plan documents without introducing application behavior.
    Given the locked PrismPM production fixture
    When the DP-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DP-02 @build
  Scenario: The Compose adapter emits and applies only pinned Compose Specification documents with declared values and capabilities.
    Given the locked PrismPM production fixture
    When the DP-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DP-03 @build
  Scenario: The Kubernetes adapter emits Kubernetes 1.36.4 resources validated by schema, decoding, dry-run admission, Kind, and supported skew.
    Given the locked PrismPM production fixture
    When the DP-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DP-04 @build
  Scenario: Deployment planning is deterministic, binds observed state, and reports every create, update, replacement, deletion, migration, risk, and rollback consequence.
    Given the locked PrismPM production fixture
    When the DP-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DP-05 @build
  Scenario: Deployment orders policy, backup, migration, rollout, readiness, contracts, SLOs, traffic, cleanup, and evidence and stops safely on partial failure.
    Given the locked PrismPM production fixture
    When the DP-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DP-06 @build
  Scenario: Status distinguishes desired, applied, and observed identity; rollback enforces data safety; destroy requires retention policy and authorization.
    Given the locked PrismPM production fixture
    When the DP-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
