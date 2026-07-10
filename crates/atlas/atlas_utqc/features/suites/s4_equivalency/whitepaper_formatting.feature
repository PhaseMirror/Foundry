@row:whitepaper-formatting
Feature: Whitepaper Formatting Standard

  Scenario: The academic paper conforms to the APS RevTeX standard
    Given the whitepaper source in "docs/paper/main.tex"
    Then it must use the "\documentclass[aps,pra,preprint,superscriptaddress,11pt,floatfix]{revtex4-2}" class
    And it must include tikz diagrams for mathematical visual aids
