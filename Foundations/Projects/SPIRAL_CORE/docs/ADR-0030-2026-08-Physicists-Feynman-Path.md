---
id: ADR-0030
title: "ADR-0030: 2026-08 Physicists Feynman Path Specification"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.FeynmanPath
rust_module: echonomics_engine::feynman_path
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0030: 2026-08 Physicists Feynman Path Specification

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for 2026-08 Physicists Feynman Path Specification.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0030
Title: 2026-08 Physicists Feynman Path Specification
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

Physicists finally put Feynman's path integral to the test

August 31 2026, by Sam Jarman

Experimental setup validates the predictions of Feynman's line integral for the first time. Credit: Yong-Li Wen et al.

For nearly 80 years, physicists have relied on a thought experiment

1/4

created by Richard Feynman to predict how quantum particles behave. For the first time, researchers in China have tested this trick directly in the lab.

Led by Shi-Liang Zhu at South China Normal University in Guangzhou, China, the team used single particles of light to show that Feynman's idea holds up in practical experiments.

Their results are published in Science Advances.

Feynman's thought experiment

Thought experiments have always been a key element of quantum mechanics. Famous examples like Schrödinger's cat and the double-slit experiment helped reveal that particles can exist in multiple states at once and how their behaviors change with direct measurement.

In 1948, Richard Feynman proposed a new thought experiment to describe how a quantum particle travels from one point to another. His "path integral" idea suggests a particle doesn't take a single route between two points. Instead, every conceivable path contributes, and they all add together to produce the outcome we observe.

Feynman also claimed each of these paths carries the same likelihood, differing only in the phase of their quantum wave functions. For decades, these were treated as reliable working assumptions—but had not been confirmed experimentally.

Single-photon experiment

Zhu's team set out to confirm this using single photons. Rather than tracking a photon's path directly, which is impossible without disturbing

2/4

it, they measured its probability amplitude: a value that captures how likely the photon is to take a given route, combining both size and timing information.

By sending photons through a setup of mirrors, lenses and crystals and carefully measuring how their properties shifted, the team reconstructed amplitudes for some 1,419,857 possible paths.

With so many paths involved, any small errors could snowball until the results became meaningless. To get around this, the team refined nearly every part of its measurement process, allowing it to combine data with high enough fidelity to make the comparison meaningful.

Validating Feynman

The results closely matched Feynman's predictions: Probabilities emerged from combining all the paths, the paths carried equal strength, and phases were set by the particle's classical trajectory.

This level of precision represents a promising advance in quantum measurement, validating decades of standard quantum calculations. Zhu's team now hopes other researchers can adapt the technique to different physical systems, for example, to test how paths combine when photons travel through materials rather than empty space. In turn, future studies could extend this newly confirmed foundation of quantum theory even further.

More information: Yong-Li Wen et al, Direct experimental test of Feynman's path integral postulates with single photons, Science Advances (2026). DOI: 10.1126/sciadv.aeh1011

© 2026 Science X Network

3/4

Citation: Physicists finally put Feynman's path integral to the test (2026, August 31) retrieved 1 September 2026 from https://phys.org/news/2026-08-physicists-feynman-path.html

This document is subject to copyright. Apart from any fair dealing for the purpose of private study or research, no part may be reproduced without the written permission. The content is provided for information purposes only.

4/4

Powered by TCPDF (www.tcpdf.org)

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
