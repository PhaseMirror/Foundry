@row:complex-amplitude-encoding @stage:S0 @status:some-true @oracle:holospaces-cc
Feature: Complex amplitude encoding
  The substrate stores bytes, not amplitudes; this is the defined content-addressed encoding.
  An amplitude-space vector { label -> complex amplitude } encodes to canonical bytes, round-trips
  through the content-addressed store (CC-1), and its Euclidean composition norm sum|c_i|^2
  equals the inner product on the encoded form. (status: build)

  Scenario: amplitudes round-trip and preserve the norm for the Atlas
    Given the UOR Atlas use-case
    Then the complex amplitude encoding round-trips and preserves the norm

  Scenario Outline: the amplitude encoding holds for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the complex amplitude encoding round-trips and preserves the norm

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
