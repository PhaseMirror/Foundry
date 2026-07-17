# ADR 0002: Collatz Conjecture Computational Verification

## Status
Accepted

## Context
Based on the `publications/Collatz Conjecture/` documents, we need to implement a massive-scale computational verification system for the Collatz (3n+1) conjecture. The system must verify starting values to the largest possible bounds. Efficiency and parallelization are critical for this component.

## Decision
We will build a highly parallelized Rust engine using SIMD instructions and GPU acceleration for Collatz sequence computations.
1. **Parallelization**: Utilize `rayon` for CPU-based multithreading, chunking the search space.
2. **GPU Acceleration**: Implement OpenCL or CUDA compute kernels for bulk trajectory calculations, drastically increasing throughput.
3. **Data Types**: Use native 128-bit integers (`u128`) for the search space to delay the need for arbitrary precision arithmetic.
4. **Optimization**: Implement a lookup table (memoization) and bitwise operations to optimize the $ 3n+1 $ and $ n/2 $ steps.

## Consequences
- **Positive**: 
  - Massive speedup over naive implementations.
  - Efficiently uses both CPU and GPU resources.
- **Negative**:
  - Managing GPU compute via Rust introduces additional build complexity and hardware dependencies.
  - When sequences exceed `u128` bounds (approx $ 3.4 \times 10^{38} $), performance will drop sharply as we switch to big integers.

## Compliance
All core verification will reside strictly in the Rust Engine, ensuring alignment with the Sedona Spine Mandate. The UI will only consume certified trajectory bounds and cycle absence reports.
