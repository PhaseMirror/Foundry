# Kani Harnesses Design Spec

**Date**: 2026-07-21
**Status**: Implemented

## Overview

Seven Kani bounded model checking harnesses verify properties of the Rust
implementation within bounded domains.

## Harness Specifications

### 1. verify_composition_preserved

**Property**: If `compose_p(x, y) = some(z)`, then after `complete()`,
`Comp(x, y)` and `Var(z)` are in the same equivalence class.

**Approach**: Set up a partial system with one composition rule, run completion,
verify find(Comp(x,y)) == find(Var(z)).

### 2. verify_congruence_closure

**Property**: For all indices i, j in the Union-Find, if `find(i) == find(j)`,
then `find(Close(i)) == find(Close(j))`.

**Approach**: Run completion on empty system, verify the invariant holds
for all pairs.

### 3. verify_termination

**Property**: `complete()` terminates without panic or overflow.

**Approach**: Call complete() on a default system; Kani verifies no unwinding
or assertion failure.

### 4. verify_associator_bounded

**Property**: `associator_defect(x, y, z)` returns a finite, non-negative value.

**Approach**: Construct three gates, compute associator, assert >= 0 and <= 10.

### 5. verify_blockade_enforced

**Property**: If two qubits are within the Rydberg blockade radius, their
composition is NOT equivalent to the declared result.

**Approach**: Set blockade_radius = 5.0, place qubits at distance 4.9,
verify Comp(0,1) and Var(2) are in different classes.

### 6. verify_union_find_no_panic

**Property**: Union-Find with MAX_TERMS nodes, all pairwise unions, all finds,
never panics.

**Approach**: Create 32 nodes, union all pairs, find all indices.

### 7. verify_no_index_out_of_bounds

**Property**: Completion with 8 vars and saturated definitions never accesses
out-of-bounds array indices.

**Approach**: Create maximal partial system, run completion, verify all
find operations succeed within bounds.

## Bounds

- MAX_TERMS = 32
- MAX_QUBITS = 4
- Kani unwind bound = 1025
