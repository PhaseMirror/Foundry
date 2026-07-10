@row:finite-closure
Feature: Finite Braid Closure
  Scenario: the generated braiding subgroup is finite
    Given the UOR Atlas use-case
    Then the generated braiding subgroup is measured as mathematically finite
