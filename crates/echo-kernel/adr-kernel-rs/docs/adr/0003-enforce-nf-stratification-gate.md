# 0003. Enforce NF stratification gate

Date: 2026-05-24

## Status
Accepted

## Context
Type-dynamic rule systems can admit recursive evaluation loops unless membership-like edges preserve strict level ascent.

## Decision
Admit rule sets only when they satisfy a solvable level assignment where `member(x,y)` implies `level(y)=level(x)+1` and `equal(x,y)` implies equal levels.

## Consequences
Some expressive but unsafe rule sets remain explorable but not executable.
The validator becomes a non-negotiable kernel gate.
