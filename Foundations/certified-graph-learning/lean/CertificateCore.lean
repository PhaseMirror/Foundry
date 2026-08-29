import CertificateCore.Vector
import CertificateCore.Matrix
import CertificateCore.GraphLaplacian
import CertificateCore.SpectralContraction
import CertificateCore.FFI

/-!
# CertificateCore

The Lean4 certificate core for ADR-0027, "Certified Graph Learning".

Formally verifies the spectral contraction certificate for the graph heat-flow
smoothing operator `u ↦ u - α·L·u`:

  ‖P(u - α·L·u)‖² ≤ (1 - α·λ₂)² · ‖P(u)‖²

where `P` is the mean-zero projector, `λ₂` is the Fiedler (spectral gap) value,
and constructive machinery (eigen-decomposition, Cauchy–Schwarz) is summarized
by documented axioms — never `sorry`.

Module graph:
- `Vector`: ℚⁿ vectors, inner product, norm, mean-zero projection.
- `Matrix`: ℚⁿˣⁿ matrices, matrix-vector product, symmetric PSD definitions.
- `GraphLaplacian`: Laplacian structure + spectral axioms + heat step.
- `SpectralContraction`: the contraction bound and certificate soundness.
- `FFI`: the executable certificate check predicate.

No Mathlib dependency.
-/

namespace CertificateCore

end CertificateCore