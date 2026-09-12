Feature: authorities

  @AU-01 @build
  Scenario: Every standards claim uses a typed immutable authority binding distinct from its executable oracle.
    Given the locked PrismPM production fixture
    When the AU-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @AU-02 @build
  Scenario: Authority resolution writes a canonical reviewable lock and locked resolution rejects drift.
    Given the locked PrismPM production fixture
    When the AU-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @AU-03 @build
  Scenario: Fetch verifies signatures and digests before atomically publishing immutable cached inputs.
    Given the locked PrismPM production fixture
    When the AU-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @AU-04 @build
  Scenario: Authority and oracle verification reproduces from a populated cache with network access disabled.
    Given the locked PrismPM production fixture
    When the AU-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @AU-05 @build
  Scenario: Oracle runners are digest-bound, resource-bounded, networkless, and report exact covered and uncovered requirements.
    Given the locked PrismPM production fixture
    When the AU-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @AU-06 @build
  Scenario: Official positive and negative corpora plus Prism mutations detect stale, bypassed, changed, or always-passing oracles.
    Given the locked PrismPM production fixture
    When the AU-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
