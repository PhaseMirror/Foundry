@row:inner-product @stage:S1 @status:some-true @oracle:f1-atlas
Feature: Inner product (the definite Euclidean companion)
  The UTQC inner product is the definite Euclidean companion <x,x> = sum x_i^2 — a manifest
  sum of squares, deliberately distinct from the signed prime form (the RH crux).

  Scenario: the inner product is a definite sum of squares
    Given the UOR Atlas use-case
    Then the inner product is the definite Euclidean companion
