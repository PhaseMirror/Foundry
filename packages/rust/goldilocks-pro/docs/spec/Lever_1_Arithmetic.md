# Lever 1: Goldilocks Arithmetic (Normative)

**Field:** $\mathbb{F}_{p}$ where $p = 2^{64} - 2^{32} + 1$.

## 1. Reduction Pattern
The kernel MUST use the canonical reduction pattern for the Goldilocks prime:
$2^{64} \equiv 2^{32} - 1 \pmod p$.

## 2. Scalar Operations
*   `add(a, b)`: If $a+b \ge p$ return $a+b-p$.
*   `sub(a, b)`: If $a < b$ return $a-b+p$.
*   `mul(a, b)`: Full 128-bit product reduced via the pattern above.
*   `inv(a)`: Computed as $a^{p-2} \pmod p$.

## 3. Scale Factor
The normative scale factor for all floating-point fixed representations is $2^{40}$.

## 4. SIMD Implementation
Vectorized kernels for AVX-512 and NEON MUST produce bit-perfect results identical to the scalar reference.
- Pattern for branchless add: `sum = a + b; eps = 2^32 - 1; res = select(sum + eps < sum, sum + eps, sum)`.
