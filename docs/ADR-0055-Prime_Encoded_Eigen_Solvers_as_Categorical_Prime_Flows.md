 Prime-Encoded Eigen Solvers as Categorical Prime Flows:
 A Multiplicity-Theoretic and Tensor-Quantum Framework
                                    Citizen Gardens
                              The Prime Materia Commons

                                       Mayy 5, 2026


                                          Abstract
    This report presents a unified, multiplicity-theoretic, and categorical framework for prime-
encoded eigenvalue solvers, with particular focus on a prime-weighted Lanczos method and its
tensor/quantum extensions. Building on a base preprint introducing prime-encoded eigenvalue
decomposition (PEED), we formalize: (i) a category of prime-labelled Krylov modules for the
Lanczos recurrence, (ii) an endofunctor capturing the prime-weighted Lanczos flow as a “prime
move” on this category, (iii) spectral and dynamical invariants as functors and natural trans-
formations, and (iv) an analogous categorical treatment of the tensor/quantum layer, including
quantum phase estimation and prime-labelled tensor-network representations of eigenstates. We
include an executive summary, mathematical definitions and propositions, and a concrete code
sketch illustrating how a prime-weighted Lanczos prototype can be implemented in practice.
The goal is to provide a prior-art defensive publication around this family of prime-indexed,
recursively stable eigen-solvers and their categorical formalization.




                                               1
Contents
1 Executive Summary                                                                                  3
  1.1 Conceptual Overview . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    3
  1.2 Novelty and Prior-Art Value . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    3

2 Mathematical Overview                                                                              4
  2.1 Prime-Encoding of Matrices and Eigenvalues . . . . . . . . . . . . . . . . . . . . . .         4
  2.2 Prime-Weighted Lanczos Method . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        4
  2.3 Recursive Feedback and Quantum/Tensor Layer . . . . . . . . . . . . . . . . . . . .            5

3 Categorical Framework for Prime-Weighted Lanczos                                                   5
  3.1 Category of Prime-Labelled Krylov Modules . . . . . . . . . . . . . . . . . . . . . . .        5
  3.2 Prime-Weighted Lanczos Functor . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       6
  3.3 Invariants as Functors and Natural Quantities . . . . . . . . . . . . . . . . . . . . . .      7
      3.3.1 Trace . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    7
      3.3.2 Prime-Weighted Off-Diagonal Energy . . . . . . . . . . . . . . . . . . . . . .           7
      3.3.3 Coupling Ratios and Exponent Signature . . . . . . . . . . . . . . . . . . . .           7
  3.4 Recursive Feedback as a Derived Functor . . . . . . . . . . . . . . . . . . . . . . . .        7

4 Categorical Framework for Tensor/Quantum Layer                                                     8
  4.1 Category of Prime-Labelled Tensor Modules . . . . . . . . . . . . . . . . . . . . . . .        8
  4.2 Quantum Evolution and Phase Estimation Functors . . . . . . . . . . . . . . . . . .            8
  4.3 Tensor-Network Observables and Invariants . . . . . . . . . . . . . . . . . . . . . . .        9

5 Code Sketch: Prime-Weighted Lanczos Prototype                                                      9
  5.1 Prime-Weighted Lanczos in Python . . . . . . . . . . . . . . . . . . . . . . . . . . . .       9

6 Conclusions and Further Work                                                                      11

Mathematical Appendix                                                                               11

A Prime-Weighted Lanczos: Well-Posedness and Norm Bounds                                            11
  A.1 Well-Posedness of the Prime-Weighted Recurrence . . . . . . . . . . . . . . . . . . .         11
  A.2 Operator Norm Bounds for the Tridiagonal Matrix . . . . . . . . . . . . . . . . . . .         12
  A.3 Residual Norm Bounds and Ritz Error Estimates . . . . . . . . . . . . . . . . . . . .         13

B Categorical Invariants and Natural Transformations                                             13
  B.1 Trace and Energy as Functors . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
  B.2 Scale-Free Ratios and Exponent Signature . . . . . . . . . . . . . . . . . . . . . . . . 14

C Tensor/Quantum Layer: Compatibility and Bounds                                                    14
  C.1 Compatibility of Θ with A and U . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     14
  C.2 Norm Bounds for Tensor States . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     15
  C.3 Expectation-Value Bounds for Tensor Observables . . . . . . . . . . . . . . . . . . .         15




                                                  2
1     Executive Summary
1.1    Conceptual Overview
The underlying preprint introduces a prime-encoded eigenvalue decomposition (PEED) for an n×n
Hermitian matrix A:                           X
                                      P (A) =     αp p Ap ,
                                                 p∈PA

where PA is a finite set of primes, αp ∈ R, and Ap are linear operators encoding “interaction
components” associated with each prime.[?] Eigenvalues are also prime-encoded as
                                              Y eij
                                         λi =    pj
                                                      j

with integer exponents eij representing spectral multiplicity structure.[?]
   The preprint further develops:

    • a prime-based QR iteration,

    • a prime-weighted Lanczos method that inserts prime weights into the recurrence coefficients
      and the induced tridiagonal matrix,

    • a recursive feedback update on eigenvalue estimates,

    • quantum-inspired extensions including quantum phase estimation, and

    • a tensor representation of eigenstates Ψ(t) = i λi |pi ⟩ ⊗ |ei ⟩.[?]
                                                   P

    In this report, we:

    1. Recast the prime-weighted Lanczos procedure as a prime flow in a category of prime-labelled
       Krylov modules.

    2. Define an endofunctor that advances the Krylov subspace and records the prime weights,
       together with a natural transformation representing the stepwise inclusion.

    3. Identify invariants of this flow (trace, prime-weighted off-diagonal energy, coupling ratios,
       exponent signatures) as functors and natural quantities in the category.

    4. Develop an analogous category of prime-labelled tensor modules for the quantum/tensor layer,
       including a quantum evolution functor, a phase-estimation functor, and expectation-value
       functors for tensor-network observables.

    The resulting framework aligns with a multiplicity-theoretic viewpoint: mathematical objects
are recursively generated prime-labelled configurations, and algorithms such as Lanczos become
discrete flows on prime-indexed multiplicity spaces with well-defined invariants.

1.2    Novelty and Prior-Art Value
The combination of the following elements appears to be novel and thus worth documenting as
prior art:

    • Explicit use of prime labels at the level of:

                                                      3
                                   P
        – decomposition P (A) =   p αp pAp ,
                                  Q eij
        – eigenvalue encoding λi = j pj ,
        – recurrence coefficients βk pk in Lanczos,
                                P
        – tensor states Ψ(t) = i λi |pi ⟩ ⊗ |ei ⟩.

    • A categorical formulation of the prime-weighted Lanczos method:

        – objects: prime-labelled Krylov modules,
        – morphisms: maps preserving prime identity structure,
        – endofunctor: prime-weighted Lanczos step,
        – natural transformation: canonical inclusion (prime move).

    • Spectral and dynamical invariants (trace, prime-weighted energy, coupling ratios, exponent
      signatures) expressed as functors or natural quantities within this category.

    • A parallel categorical treatment for the tensor/quantum layer: prime-labelled tensor modules,
      quantum evolution functor, and phase-estimation functor.

    Together, these give a coherent, mathematically explicit backbone for prime-encoded eigenvalue
solvers that is suitable for defensive publication.


2     Mathematical Overview
2.1   Prime-Encoding of Matrices and Eigenvalues
We recall the basic setup from the preprint.[?] Let A be an n × n Hermitian matrix; consider the
eigenvalue problem
                                             Av = λv.
The prime-encoding of A is given by
                                                  X
                                        P (A) =          αp p Ap ,                              (1)
                                                  p∈PA

where PA is a finite set of distinct primes, αp ∈ R, and Ap are linear operators on the same space
as A.[?]
   Eigenvalues are encoded as prime products:
                                                  Y eij
                                             λi =    pj ,                                      (2)
                                                   j

where eij ∈ Z are exponents encoding spectral characteristics.[?]

2.2   Prime-Weighted Lanczos Method
The prime-weighted Lanczos method constructs the Krylov subspace

                             Km (A, v) = span{v, Av, A2 v, . . . , Am−1 v}                      (3)

and iteratively computes a tridiagonal matrix Tm .[?]

                                                   4
    Initialization (Eq. (11)):
                                         w1 = Av1 ,         α1 = v1T w1 .                      (4)
    Iterative prime-weighted recurrence (Eq. (12)-(13)):

                                       wk+1 = Avk − αk vk − βk vk−1 ,                          (5)
                                         βk = ∥wk ∥pk ,                                        (6)

with αk = vkT Avk (Eq. (14)).[?]
   The resulting prime-encoded tridiagonal matrix (Eq. (15)) is
                                                                                   
                                 α1 β1 p1  0       ...                         0
                             β1 p1 α2 β2 p2       ...                         0     
                                                                                    
                              0    β2 p2 α3       ...                         0
                       Tm =                                                         .        (7)
                                                                                     
                              ..     ..   ..       ..                               
                              .       .    .          .     β              m−1 pm−1 
                                   0       0      0         βm−1 pm−1         αm

2.3    Recursive Feedback and Quantum/Tensor Layer
Eigenvalues are further refined via a recursive feedback loop (Eq. (8)):
                                                    X
                                     λt+1 = λt + αt     pi e−βi t ,                            (8)
                                                              i

with learning rate αt and scaling parameters βi .[?]
   Quantum phase estimation is modeled via a unitary U with

                                               U |v⟩ = eiλ |v⟩,                                (9)

as in Eq. (9).[?]
    A tensor representation of eigenstates is given by
                                              X
                                      Ψ(t) =      λi |pi ⟩ ⊗ |ei ⟩,                          (10)
                                                   i

as in Eq. (10), realized in a tensor product Hilbert space I ⊗ E where {|pi ⟩} is a prime-labelled
basis and {|ei ⟩} are eigenvectors.[?]


3     Categorical Framework for Prime-Weighted Lanczos
3.1    Category of Prime-Labelled Krylov Modules
Base data
Let A be an n × n Hermitian matrix with prime encoding P (A) as in (1).[?] Fix a starting vector
v1 ∈ H and define Krylov subspaces Cm := Km (A, v1 ) as in (3).[?]
    Let                                      M
                                        L :=     R ep
                                                       p∈PA

be the prime identity module, a free R-module with basis indexed by primes.[?, ?]
   [Prime-labelled module] An object of PrimeModA is a triple M = (C, L, τ ) where:

                                                        5
   • C ⊆ H is a finite-dimensional subspace (typically Cm ),

   • L is the prime identity module above,

   • τ : L ⊗ C → H is linear and satisfies

                                    τ (ep ⊗ v) = Ap v   ∀p ∈ PA , v ∈ C.

    [Morphisms] A morphism ϕ : M1 = (C1 , L1 , τ1 ) → M2 = (C2 , L2 , τ2 ) in PrimeModA is a pair
(ϕC , ϕL ) where:

   • ϕC : C1 → C2 is linear,

   • ϕL : L1 → L2 is linear and satisfies ϕL (ep ) = cp ep for some cp ̸= 0,

   • the diagram
                                                       1τ
                                             L1 ⊗ C1 −→   H
                                             ↓ϕL ⊗ϕC     ↓idH
                                                      τ2
                                             L2 ⊗ C2 −→   H
      commutes.

    It is straightforward to verify that PrimeModA is indeed a category (identity and composition
respect the commutativity condition).[?]

3.2   Prime-Weighted Lanczos Functor
Fix a sequence p⃗ = (p1 , p2 , . . . ) of primes from PA , as used in the recurrence (5)–(6).[?]
   [Prime-weighted Lanczos functor] Define Fp⃗ : PrimeModA → PrimeModA as follows.

   • On objects Mm = (Cm , L, τm ): let Mm+1 = (Cm+1 , L, τm+1 ) where Cm+1 = Km+1 (A, v1 ) and
     τm+1 is the unique extension of τm satisfying

                                        τm+1 (ep ⊗ vm+1 ) = Ap vm+1

      for vm+1 produced by a single prime-weighted Lanczos step using pm+1 .[?]

   • On morphisms ϕ = (ϕC , ϕL ) : Mm → Nm , let Fp⃗ (ϕ) = (ϕ′C , ϕL ) where ϕ′C extends ϕC and
     sends vm+1 to the vector obtained via the same numerical recurrence in Nm , with identical
     scalars αk , βk and prime pm+1 .[?, ?]

   [Lanczos step as natural transformation] Let ιMm : Mm → Mm+1 be the canonical inclusion

                               (ιMm )C : Cm ,→ Cm+1 ,       (ιMm )L = idL .

Then the family {ιMm } is a natural transformation

                                       ι : IdPrimeModA ⇒ Fp⃗ .

In the basis induced by iterating ι and Fp⃗ , the matrix of A on Cm is precisely the tridiagonal matrix
Tm with diagonal entries αk and off-diagonals βk pk as in Eq. (7).[?, ?]




                                                   6
3.3     Invariants as Functors and Natural Quantities
3.3.1    Trace
[Trace functor] Define Tr : PrimeModA → R by
                                                          m
                                                          X
                                          Tr(Mm ) =             αk ,
                                                          k=1

where αk are the Lanczos diagonal coefficients for Cm .[?, ?]
   For isometric morphisms that intertwine A, Tr is invariant; under ι,
                                 Tr(Fp⃗ (Mm )) = Tr(Mm ) + αm+1 .

3.3.2    Prime-Weighted Off-Diagonal Energy
[Prime-weighted off-diagonal energy] Define
                                                      m−1
                                                      X
                                       E(Mm ) =             (βk pk )2 ,
                                                      k=1

the squared Frobenius norm of the off-diagonal part of Tm .[?, ?]
   E is invariant under morphisms preserving the products βk pk ; under ι,
                                E(Fp⃗ (Mm )) = E(Mm ) + (βm pm )2 .

3.3.3    Coupling Ratios and Exponent Signature
[Scale-free coupling ratios] For m ≥ 2, define
                                           βk pk
                                  rk =             ,      k = 2, . . . , m.
                                         βk−1 pk−1
   These ratios are invariant under prime-similarities: morphisms that rescale all ep by the same
constant and preserve all ∥wk ∥.
   [Prime-exponent signature] Define
                                                m−1
                                                X
                                         sm =         logpk |βk pk |.
                                                k=1

   Under morphisms that preserve βk pk up to prime powers, sm transforms linearly; once the
Lanczos process has converged on a spectral block, sm stabilizes up to bounded variation.

3.4     Recursive Feedback as a Derived Functor
Let Dyn(R) denote the category of discrete-time dynamical systems on R.
   [Feedback functor] Given Mm with primes and scalars (ατ , βi ), define
                                                       t−1
                                                       X           X
                                R(Mm )(t) = λ0 +              ατ       pi e−βi τ
                                                       τ =0        i

with initialization λ0 . This yields a map R : PrimeModA → Dyn(R).
    Morphisms preserving the scalar data induce identical dynamical systems under R, making the
feedback update functorial.

                                                      7
4     Categorical Framework for Tensor/Quantum Layer
4.1    Category of Prime-Labelled Tensor Modules
Base data
Let A have prime encoding P (A) as in (1) and eigen-decomposition A|ei ⟩ = λi |ei ⟩ with prime
encodings λi as in (2).[?] Let I be a Hilbert space with orthonormal basis {|p⟩ : p ∈ PA } and E the
eigenspace spanned by {|ei ⟩}.[?]
    [Prime-tensor module] An object of PrimeTenA is a triple N = (E, I, Θ) where:
    • E ⊆ H is a finite-dimensional eigenspace,

    • I is the prime identity Hilbert space,

    • Θ : I ⊗ E → H is linear and satisfies

                                            Θ(|pi ⟩ ⊗ |ei ⟩) = λi |ei ⟩

      for each eigenpair (λi , |ei ⟩).
    The prime-labelled tensor state Ψ(t) from (10) lies naturally in I ⊗ E.
    [Morphisms] A morphism Φ : N1 = (E1 , I1 , Θ1 ) → N2 = (E2 , I2 , Θ2 ) is a pair (ΦE , ΦI ) where:
    • ΦE : E1 → E2 is linear and intertwines A,

    • ΦI : I1 → I2 is linear and satisfies ΦI (|p⟩) = eiθp |p⟩,

    • the diagram
                                                        1 Θ
                                              I1 ⊗ E1 −−→  H
                                              ↓ΦI ⊗ΦE     ↓idH
                                                        2 Θ
                                              I2 ⊗ E2 −−→         H
      commutes.

4.2    Quantum Evolution and Phase Estimation Functors
Let U = eiA be the unitary such that U |ei ⟩ = eiλi |ei ⟩ as in Eq. (9).[?]
   [Quantum evolution functor] Define Q : PrimeTenA → PrimeTenA by:
    • on objects N = (E, I, Θ),
                                              Q(N ) = (E, I, ΘU )
      with
                                         ΘU (|pi ⟩ ⊗ |ei ⟩) = eiλi λi |ei ⟩,

    • on morphisms, Q(Φ) = (ΦE , ΦI ), since ΦE intertwines A and thus U .
    Let QCirc denote a suitable category of quantum circuits and measurement outcomes.
    [Phase-estimation functor] A phase-estimation functor P : PrimeTenA → QCirc assigns to
each N = (E, I, Θ) a quantum circuit implementing phase estimation for U on states in E, with
measurement outcomes labelled by the prime basis states |pi ⟩.
    [Functoriality of phase estimation] For any morphism Φ : N1 → N2 in PrimeTenA that inter-
twines U , the corresponding circuits P(N1 ) and P(N2 ) produce identical phase distributions up to
relabelling via ΦI .

                                                      8
4.3    Tensor-Network Observables and Invariants
The tensor state Ψ(t) admits tensor-network representations such as matrix product states.[?] Prime
labels may appear on physical or bond indices.
   [Expectation-value functor] Let O be an observable on I ⊗ E. Define EO : PrimeTenA → R by

                                     EO (N ) = ⟨Ψ(t)|O|Ψ(t)⟩,

where Ψ(t) is determined by Θ.
   When Φ preserves O (up to conjugation), EO (N ) is invariant, providing a tensor-network ana-
logue of the Lanczos invariants (trace, E(Mm ), rk , sm ).


5     Code Sketch: Prime-Weighted Lanczos Prototype
This section illustrates how a research prototype of the prime-weighted Lanczos method can be
implemented in Python/NumPy. The code is presented as an illustrative sketch, not a production-
ready solver.

5.1    Prime-Weighted Lanczos in Python
import numpy as np

def prime_weighted_lanczos(A, v1, primes, m_max):
    """
    Prime-weighted Lanczos prototype.

      Parameters
      ----------
      A : (n, n) Hermitian numpy array
      v1 : (n,) initial vector, will be normalized
      primes : list or array of primes [p_1, p_2, ...]
      m_max : maximum Krylov depth

      Returns
      -------
      alphas : array of length m
      betas : array of length m-1
      T      : (m, m) tridiagonal matrix with off-diagonals beta_k * p_k
      V      : (n, m) Lanczos basis vectors
      """

      n = A.shape[0]
      v1 = v1 / np.linalg.norm(v1)
      V = np.zeros((n, m_max), dtype=A.dtype)
      V[:, 0] = v1

      alphas = np.zeros(m_max, dtype=float)
      betas = np.zeros(m_max - 1, dtype=float)


                                                9
 w = A @ V[:, 0]
 alphas[0] = np.vdot(V[:, 0], w).real

 for k in range(m_max - 1):
     if k > 0:
         w = A @ V[:, k] - alphas[k] * V[:, k] - betas[k-1] * V[:, k-1]
     else:
         w = A @ V[:, k] - alphas[k] * V[:, k]

      # prime-weighted beta
      p_k = primes[k]
      beta_k_norm = np.linalg.norm(w)
      betas[k] = beta_k_norm * p_k

      if beta_k_norm == 0:
          # early termination
          m = k + 1
          alphas = alphas[:m]
          betas = betas[:m-1]
          V = V[:, :m]
          break

      V[:, k+1] = w / beta_k_norm
      alphas[k+1] = np.vdot(V[:, k+1], A @ V[:, k+1]).real

 # construct T
 m = V.shape[1]
 T = np.diag(alphas[:m])
 for k in range(m - 1):
     p_k = primes[k]
     off = betas[k] # already includes p_k
     T[k, k+1] = off
     T[k+1, k] = off

 return alphas[:m], betas[:m-1], T, V

This prototype:
• Implements the recurrence (5)–(6) with βk = ∥wk ∥pk .

• Constructs the tridiagonal matrix Tm of (7) with off-diagonals βk pk embedded in betas.

• Produces the Lanczos basis V for Krylov subspaces Cm .
Extensions can:
• track invariants E(Mm ), rk , sm at each iteration,

• plug Tm into a tensor-network representation (e.g., MPS/MPO),

• connect to a symbolic or categorical library that reflects the PrimeModA structure directly.

                                             10
6     Conclusions and Further Work
This report consolidates the developments in prime-encoded eigenvalue solvers into a unified multiplicity-
theoretic and categorical framework. The prime-weighted Lanczos method is cast as a prime
flow in PrimeModA with well-defined invariants, and the tensor/ quantum layer is described
in PrimeTenA with quantum evolution and phase-estimation functors.
    Future work could extend these ideas to:

    • Category-theoretic treatments of the prime-based QR iteration,

    • Hybrid quantum-classical prime flows, where classical Lanczos and quantum phase estimation
      are combined as interconnected functors,

    • Practical benchmarks comparing prime-encoded solvers with standard methods in high-dimensional
      settings.


Mathematical Appendix
This appendix collects explicit proofs, norm bounds, and auxiliary lemmas underpinning the prime-
weighted Lanczos framework and its tensor/quantum extensions. We focus on:

    • well-posedness and stability of the prime-weighted Lanczos recurrence,

    • operator-norm bounds for the induced tridiagonal Tm and associated residuals,

    • invariance properties of the prime-labelled categorical structures,

    • compatibility of the tensor representation with quantum evolution and phase estimation.

    Throughout, A ∈ Cn×n is Hermitian and prime-encoded as in Eq. (2), and the Lanczos algorithm
is as in Eqs. (11)–(15) of the main text.[?, ?, ?]


A      Prime-Weighted Lanczos: Well-Posedness and Norm Bounds
A.1     Well-Posedness of the Prime-Weighted Recurrence
Recall the prime-weighted recurrence (Eqs. (11)–(14)):

                                       w1 = Av1 ,        α1 = v1∗ w1 ,                             (11)
                                    wk+1 = Avk − αk vk − βk vk−1 ,                                 (12)
                                       βk = ∥wk ∥ pk ,                                             (13)
                                       αk = vk∗ Avk ,                                              (14)

with v0 := 0 and pk the k-th prime in a fixed sequence p⃗.[?]
   [Nondegeneracy and early termination] Assume v1 ̸= 0 and A Hermitian.

    1. If wk ̸= 0 for k = 1, . . . , m, then the recurrence uniquely defines nonzero βk and unit vectors
       vk+1 up to phase.

    2. If wk0 = 0 for some minimal k0 , the algorithm terminates with Ck0 = Kk0 (A, v1 ) invariant
       under A and exact on that subspace.

                                                    11
Proof. (1) For a given k, if wk ̸= 0, then ∥wk ∥ > 0 and hence βk = ∥wk ∥pk ̸= 0 since pk > 0.
Defining vk+1 = wk+1 /∥wk+1 ∥ produces a unit vector uniquely determined up to a complex phase
factor, as in the standard Lanczos algorithm.[?, ?]
    (2) If wk0 = 0, the recurrence gives Avk0 = αk0 vk0 + βk0 vk0 −1 ; since wk0 = 0 implies ∥wk0 ∥ = 0,
we have βk0 = 0 and thus Avk0 = αk0 vk0 , so vk0 is an eigenvector. Standard arguments for Lanczos
show that span{v1 , . . . , vk0 } is A-invariant and that the restriction of A to Ck0 is represented exactly
by the tridiagonal Tk0 .[?, ?]

A.2    Operator Norm Bounds for the Tridiagonal Matrix
Let Qm = [v1 , . . . , vm ] ∈ Cn×m be the orthonormal basis of Cm generated by the recurrence. We
have the tridiagonal reduction
                                            Q∗m AQm = Tm                                      (15)
with Tm as in Eq. (15).[?, ?]
   [Spectral inclusion] For Hermitian A, we have

                                          σ(Tm ) ⊂ conv(σ(A)),

where σ(·) denotes spectrum and conv the convex hull.

Proof. This is standard for Lanczos: Tm is the representation of A on the Krylov subspace with an
orthonormal basis, hence its eigenvalues are Ritz values for A and lie in the convex hull of σ(A) by
the variational characterization of eigenvalues and the Rayleigh quotient bounds.[?, ?]

   [Spectral norm bound] Let ∥ · ∥2 denote the spectral norm. Then

                                                ∥Tm ∥2 ≤ ∥A∥2 .

Proof. Since Tm = Q∗m AQm with Qm having orthonormal columns,

                         ∥Tm ∥2 = ∥Q∗m AQm ∥2 ≤ ∥Q∗m ∥2 ∥A∥2 ∥Qm ∥2 = ∥A∥2 ,

as ∥Qm ∥2 = ∥Q∗m ∥2 = 1.[?]

    The prime weights appear only in the off-diagonal entries βk pk . A crude but explicit bound in
terms of primes is:
    [Prime-weighted Gershgorin bound] Let Tm be as in Eq. (15). Then every eigenvalue θ ∈ σ(Tm )
satisfies
                                 |θ − αk | ≤ |βk−1 pk−1 | + |βk pk |
for some k, with the convention β0 p0 := 0. Consequently,

                              max |θ| ≤ max (|αk | + |βk−1 pk−1 | + |βk pk |) .
                            θ∈σ(Tm )        k

Proof. This follows from Gershgorin’s circle theorem applied to the tridiagonal matrix Tm .[?] The
k-th row has diagonal αk and off-diagonal entries at most |βk−1 pk−1 | and |βk pk | in magnitude. The
spectrum lies in the union of those disks, yielding the bound.




                                                      12
A.3     Residual Norm Bounds and Ritz Error Estimates
      (m)                                                                                 (m)
Let θj be an eigenvalue of Tm (a Ritz value of A), with associated Ritz vector uj               = Qm yj where
yj is a unit eigenvector of Tm . The residual for this Ritz pair is
                                      (m)              (m)      (m) (m)
                                     rj     = Auj            − θj  uj .

    [Residual norm formula] For Hermitian A and tridiagonal Tm , we have
                                          (m)
                                      ∥rj       ∥2 = |βm pm | |eTm yj |,

where em is the m-th standard basis vector in Rm .
                                                                              (m)
Proof. In the classical Lanczos setting, the residual norm is ∥rj ∥2 = |βm ||eTm yj |.[?, ?] In the
prime-weighted case, Tm has off-diagonal entries βk pk , and the coupling to the (m + 1)-st basis
vector in the recurrence is scaled accordingly. Direct computation of AQm − Qm Tm gives the
residual term at the last basis vector proportional to βm pm vm+1 ; projecting onto yj yields the
stated expression.
                                                                                                   (m)
    [A priori Ritz error bound] Let λ1 ≥ λ2 ≥ · · · ≥ λn be the eigenvalues of A, and let θ1             be the
largest Ritz value of Tm . Then
                                             (m)        (m)
                                       λ1 − θ1 ≤ ∥r1 ∥2 .
In particular,
                                                (m)
                                     λ 1 − θ1         ≤ |βm pm | |eTm y1 |.
                                                                                    (m)
Proof. This is a standard bound for symmetric Lanczos: the Ritz value θ1 is the maximum of
the Rayleigh quotient on the Krylov subspace, and the residual norm bounds the distance to a true
eigenpair.[?, ?] The second inequality comes from the previous lemma.

   These bounds show how the prime factors pm enter the residual error and thus affect conver-
gence; they also motivate normalisation or rescaling strategies if pm grows too quickly.


B     Categorical Invariants and Natural Transformations
B.1    Trace and Energy as Functors
We recall the trace functor Tr(Mm ) = m
                                      P                                Pm−1         2
                                        k=1 αk and the energy E(Mm ) =  k=1 (βk pk ) .[?]
   [Functoriality of trace] Let ϕ : Mm → Nm be a morphism in PrimeModA such that ϕC is an
isometric isomorphism onto its image and intertwines A. Then

                                          Tr(Mm ) = Tr(Nm ).

Proof. Since ϕC is isometric and intertwines A, it induces a unitary similarity between the restric-
tions A|Cm and A|ϕC (Cm ) , hence their traces coincide. The Lanczos tridiagonals Tm and Tm   ′ are

unitarily similar and share the same diagonal sum.[?]

    [Prime-weighted energy monotonicity] Under the inclusion ιMm : Mm → Mm+1 , we have

                            E(Mm+1 ) = E(Mm ) + (βm pm )2 ≥ E(Mm ).



                                                        13
Proof. By definition,
                             m
                             X                  m−1
                                                X
                                         2
              E(Mm+1 ) =           (βk pk ) =         (βk pk )2 + (βm pm )2 = E(Mm ) + (βm pm )2 .
                             k=1                k=1




B.2    Scale-Free Ratios and Exponent Signature
[Invariance under prime-similarity] Let ϕ : Mm → Nm be a morphism in PrimeModA such that:

    • ϕL (ep ) = cep for the same c ̸= 0 and all primes p,

    • ϕC preserves all ∥wk ∥.

Then the scale-free ratios rk = (βk pk )/(βk−1 pk−1 ) are invariant.

Proof. Under the stated assumptions, both βk and pk are scaled in such a way that the products
βk pk are multiplied by a common factor, which cancels in the ratio. Preservation of ∥wk ∥ ensures
that the norm-derived parts of βk are unchanged; the global scaling factor c affects all primes
equally and cancels in the ratio.[?]

   [Exponent signature stability] Assume the Lanczos process has converged on an invariant sub-
space corresponding to a cluster of eigenvalues {λi }. Then the quantity
                                                      m−1
                                                      X
                                             sm =            logpk |βk pk |
                                                       k=1

stabilizes as m increases (up to bounded fluctuations).

Sketch. Once the Krylov subspace captures the invariant subspace, the recursion coefficients (αk , βk )
converge to asymptotic values that depend only on the spectral block.[?, ?] The additional prime
factors pk are fixed by the chosen sequence, hence the growth of |βk pk | becomes regular, and their
log sum behaves like a linear function of m plus bounded fluctuations. The precise constant depends
on the asymptotic values of βk and the distribution of pk .


C     Tensor/Quantum Layer: Compatibility and Bounds
C.1    Compatibility of Θ with A and U
In the tensor/quantum category PrimeTenA , objects N = (E, I, Θ) satisfy Θ(|pi ⟩ ⊗ |ei ⟩) = λi |ei ⟩.
    [Intertwining with A] For any N in PrimeTenA , we have

                                     A Θ(|pi ⟩ ⊗ |ei ⟩) = λi Θ(|pi ⟩ ⊗ |ei ⟩).

Proof. By definition, Θ(|pi ⟩ ⊗ |ei ⟩) = λi |ei ⟩ and A|ei ⟩ = λi |ei ⟩. Thus

                        A Θ(|pi ⟩ ⊗ |ei ⟩) = A(λi |ei ⟩) = λ2i |ei ⟩ = λi Θ(|pi ⟩ ⊗ |ei ⟩),

so Θ acts as a prime-labelled eigenvalue insertion operator.



                                                             14
    Let U = eiA be the unitary used in phase estimation.[?]
    [Intertwining with U ] We have
                                 U Θ(|pi ⟩ ⊗ |ei ⟩) = eiλi λi |ei ⟩ = ΘU (|pi ⟩ ⊗ |ei ⟩),
where ΘU defines the quantum evolution functor Q in the main text.

Proof. Since U |ei ⟩ = eiλi |ei ⟩,
                                     U Θ(|pi ⟩ ⊗ |ei ⟩) = U (λi |ei ⟩) = eiλi λi |ei ⟩,
which is precisely the action of ΘU on the same basis element.

C.2      Norm Bounds for Tensor States
                       P
The tensor state Ψ(t) = i λi |pi ⟩ ⊗ |ei ⟩ satisfies:
   [Norm of prime-labelled tensor state] Assume {|pi ⟩} and {|ei ⟩} are orthonormal bases. Then
                                                      X
                                          ∥Ψ(t)∥2 =     |λi |2 .
                                                                    i

Proof. Orthogonality of the tensor product basis implies
                                 *                                   +
                                   X                  X                 X
                              2
                      ∥Ψ(t)∥ =         λi |pi , ei ⟩,   λj |pj , ej ⟩ =   |λi |2 ,
                                               i                j                    i

where |pi , ei ⟩ := |pi ⟩ ⊗ |ei ⟩.

  [Bound in terms of ∥A∥2 ] If A is Hermitian with eigenvalues λi and spectral norm ∥A∥2 =
maxi |λi |, then
                                     ∥Ψ(t)∥2 ≤ n∥A∥22 .

Proof. We have |λi | ≤ ∥A∥2 for all i, so
                                                         n
                                                         X
                                           ∥Ψ(t)∥2 =           |λi |2 ≤ n∥A∥22 .
                                                         i=1




C.3      Expectation-Value Bounds for Tensor Observables
Let O be a bounded operator on I ⊗ E.
   [Expectation-value bound] We have
                                         |⟨Ψ(t)|O|Ψ(t)⟩| ≤ ∥O∥2 ∥Ψ(t)∥2 .
Proof. By Cauchy–Schwarz,
                            |⟨Ψ(t)|O|Ψ(t)⟩| ≤ ∥O|Ψ(t)⟩∥2 ∥Ψ(t)∥2 ≤ ∥O∥2 ∥Ψ(t)∥22 .


    Combining with the previous proposition yields:
                                          |⟨Ψ(t)|O|Ψ(t)⟩| ≤ n∥O∥2 ∥A∥22 .
    This provides explicit operator-norm bounds for prime-labelled tensor-network observables.

                                                            15
References
 [1] Cornelius Lanczos. An iteration method for the solution of the eigenvalue problem of linear
     differential and integral operators. Journal of Research of the National Bureau of Standards,
     45(4):255–282, 1950.

 [2] Gene H. Golub and Charles F. Van Loan. Matrix Computations. Johns Hopkins University
     Press, 4 edition, 2013.

 [3] Michael A. Nielsen and Isaac L. Chuang. Quantum Computation and Quantum Information.
     Cambridge University Press, 10th anniversary edition, 2010.

 [4] Peter W. Shor. Algorithms for quantum computation: Discrete logarithms and factoring. In
     Proceedings 35th Annual Symposium on Foundations of Computer Science, pages 124–134,
     1994.

 [5] Steven R. White. Density matrix formulation for quantum renormalization groups. Physical
     Review Letters, 69(19):2863–2866, 1992.

 [6] Frank Verstraete and J. Ignacio Cirac. Matrix product states representations. Scopus, 10:1–23,
     2008.

 [7] Nadav Cohen, Or Sharir, and Amnon Shashua. On the expressive power of deep learning: A
     tensor analysis. arXiv preprint, 2016.

 [8] Lloyd N. Trefethen and David Bau. Numerical Linear Algebra. SIAM, 1997.

 [9] Yousef Saad. Numerical Methods for Large Eigenvalue Problems. SIAM, 2 edition, 2011.

[10] Yousef Saad. Iterative Methods for Sparse Linear Systems. SIAM, 2 edition, 2003.

[11] Hermann Voss. Krylov Subspace Methods. 2012. Lecture notes, Technische Universität Ham-
     burg.

[12] Zlatko Drmač et al. Templates for the solution of algebraic eigenvalue problems. In Z. Bai,
     J. Demmel, J. Dongarra, A. Ruhe, and H. van der Vorst, editors, Templates for the Solution
     of Algebraic Eigenvalue Problems. SIAM, 2000.

[13] John Urschel and Arieh Iserles. Uniform error estimates for the lanczos method. Preprint,
     2021.

[14] Andreas Frommer and Valeria Simoncini. Error bounds for krylov subspace methods for matrix
     functions. SIAM Journal on Matrix Analysis and Applications, 38(4):1075–1109, 2017.

[15] Michael H. Gutknecht. A tour of the lanczos algorithm and its convergence. Lecture Notes,
     2014. Available via University lecture notes.

[16] nLab authors. Module. https://ncatlab.org/nlab/show/module. Accessed 2025.

[17] Saunders Mac Lane. Categories for the Working Mathematician. Springer, 2 edition, 1998.

[18] Emily Riehl. Category Theory in Context. Dover Publications, 2016.

[19] R. Orús. A practical introduction to tensor networks: Matrix product states and projected
     entangled pair states. Annals of Physics, 349:117–158, 2014.

                                                16
                                                                            √
[20] Michel Crouzeix and Cristian Palencia. The numerical range is a (1 +       2)-spectral set. SIAM
     Journal on Matrix Analysis and Applications, 38(2):649–655, 2017.

[21] Roger A. Horn and Charles R. Johnson. Matrix Analysis. Cambridge University Press, 2
     edition, 2012.

[22] Roger A. Horn and Charles R. Johnson. Topics in Matrix Analysis. Cambridge University
     Press, 1991.

[23] Frank Verstraete and J. Ignacio Cirac. Renormalization algorithms for quantum-many body
     systems in two and higher dimensions. arXiv preprint, 2004.

[24] Zongkang Zhang and coauthors. Measurement-efficient quantum krylov subspace diagonalisa-
     tion. arXiv preprint, 2021.

[25] Lanczos Iterator developers. Lanczos iterator: Lanczos program for large sparse hermitian
     matrices. https://github.com/lanczos-iterator/Lanczos_Iterator, 2024.

[26] V. Hernández, J. E. Román, and A. Tomás. Lanczos methods in slepc. https://slepc.upv.
     es/release/_downloads/8490a05b338bc35c615595cdc1b41c1f/str5.pdf, 2015.

[27] QuTiP developers. Krylov subspace methods for time evolution. https://github.com/qutip/
     qutip/blob/qutip-4.7.X/doc/guide/dynamics/dynamics-krylov.rst, 2012.

[28] Wikipedia contributors. Lanczos algorithm. https://en.wikipedia.org/wiki/Lanczos_
     algorithm, 2025. Online encyclopedia.

[29] Ryan O. Van Gelder. Prime-encoded parallelized eigenvalue solvers: A mathematical frame-
     work, 2024. Preprint, Citizen Gardens – The Foundation of Multiplicity.




                                               17
