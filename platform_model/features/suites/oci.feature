Feature: oci

  @OC-01 @build
  Scenario: Product releases use OCI 1.1 descriptors, manifests, indexes, subjects, annotations, and referrers with registered media types.
    Given the locked PrismPM production fixture
    When the OC-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OC-02 @build
  Scenario: A locked build atomically emits a verified root only after every declared source, proof, package, oracle, and release gate passes.
    Given the locked PrismPM production fixture
    When the OC-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OC-03 @build
  Scenario: The release graph closes over all artifacts and binds SBOM, provenance, validation, signature, policy, and deployment referrers to exact subjects.
    Given the locked PrismPM production fixture
    When the OC-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OC-04 @build
  Scenario: Push, pull, and inspect preserve and validate complete OCI graph closure without executing artifact content or rebuilding.
    Given the locked PrismPM production fixture
    When the OC-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OC-05 @build
  Scenario: Local and GHCR registry profiles pass claimed OCI distribution operations and fail safely under mutation, interruption, concurrency, and tag races.
    Given the locked PrismPM production fixture
    When the OC-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OC-06 @build
  Scenario: Promotion adds signed evidence around one immutable subject digest and never changes or rebuilds release content.
    Given the locked PrismPM production fixture
    When the OC-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
