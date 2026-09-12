# Sovereign Twin Operator Specification

## Purpose
The `sovereign-twin-operator` crate establishes the core models and behaviors for sovereign autonomous operators running within simulated (twinned) PhaseSpace environments.

## Core Components
1. **Operator Traits**: Standardized interfaces representing the behavioral constraints of an autonomous entity.
2. **Twin Decoupling Logic**: Ensures simulated actions generate speculative states without side-effecting ground truth reality until explicitly anchored.

## Invariants
- A twin operator may never bypass the `ALP` boundary.
- Simulated states must remain fully orthogonal to the real state until committed by an authenticated external process.
