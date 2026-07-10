# Genesis ODE Engine

This directory contains the Lean 4 formalization of the **Genesis Ordinary Differential Equations (ODE)**.

## Overview

The Genesis ODE module defines the fundamental continuous stability dynamics underlying the Multiplicity ecosystem. While the `Phase Mirror` operates on discrete state transitions (`ExactRat`), the underlying theoretical bounds of the `MOC` (Multiplicity Operator Calculus) and `Affine Core` are governed by continuous differential limits.

Features:
- **Contraction Dynamics:** Formal models of contractive phase spaces.
- **Stability Thresholds:** ODE-derived invariant bounds for state drift and multiplicity conservation.
- **Transition Flows:** Mathematical guarantees that discrete timestep execution stays within the stable envelope dictated by the continuous system.

## Sedona Spine Compliance

The Genesis ODE parameters define the absolute maximum drift and entropy limits allowed by the `ALP` engine's circuit breakers. The Rust execution environment strictly relies on these theoretical upper bounds to enforce its "fail-close" mechanisms.
