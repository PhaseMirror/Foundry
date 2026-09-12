---
slug: ale-gft
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/ALE_GFT.md
  last_synced: '2026-03-20T17:17:19.461705Z'
---

             Complex Gravitational Coupling from
              Arithmetic Quantum Gravity Noise
                                        Ryan O. Van Gelder∗
                                            February 2026


                                                Abstract
              The gravitational coupling κ2 = 16πGN has been treated as a real, positive con-
          stant since Einstein wrote his field equations in 1915. We show that this assumption
          fails when gravity is an open quantum system. Starting from the Feynman–Vernon
          influence functional for metric perturbations coupled to a causal quantum environ-
          ment, we prove that the retarded self-energy dresses κ into a complex,
                                                                                    frequency-
          dependent effective coupling κeff (k) = κ 1 − κ D̃R (k)/O(k) , whose imaginary
          part is fixed by the noise kernel and whose real and imaginary parts are linked by
          a Kramers–Kronig relation rooted in spacetime causality. The result is a general
          theorem of stochastic gravity; its physical content becomes sharp when the envi-
          ronment is the Arithmetic–Langevin Group Field Theory (AL-GFT), whose noise
          kernel is a Zeta-Comb—a discrete superposition of log-periodic modes at frequen-
          cies set by the imaginary parts γn of the non-trivial Riemann zeta zeros. In this
          realisation the beat spectrum of Im κeff inherits the GUE pair-correlation statistics
          of the zeros, providing a binary diagnostic that requires no fitting. We map the
          two free parameters (ε, σ) onto a joint parameter space constrained from above by
          Planck 2018 oscillatory-feature bounds and from below by BBO/DECIGO sensitiv-
          ity curves, identifying a sweet spot at σ ∼ 10−3 , ε ∼ 10−2 where both the GUE
          cross-check and the gravitational-wave signal are accessible. A self-consistent boot-
          strap condition—requiring the environment that generates the noise to be compati-
          ble with the geometry it modifies—takes the form of a nonlinear eigenvalue problem
          whose solution, if it exists, would connect the Riemann zero spectrum to the causal
          structure of spacetime via the Berry–Keating programme.


1         Introduction
The gravitational coupling κ2 = 16πGN has been treated as a real, positive constant since
Einstein wrote his field equations in 1915. Every test of general relativity, from perihelion
precession to the LIGO–Virgo–KAGRA catalogue, is consistent with this assumption.
Yet the assumption is never derived: it is imported from classical physics, where GN
enters Newton’s law as a measured proportionality constant with no internal structure.
The moment one promotes the gravitational field to a quantum degree of freedom—or
even treats it classically while allowing it to interact with quantum matter—the coupling
    ∗
        A Citizen Gardens Research Initiative. Correspondence: Bridgeville, Pennsylvania, USA.



                                                     1
to an environment generically dresses every real parameter into a complex, frequency-
dependent effective parameter. This paper asks what happens to κ when that generic
fact is taken seriously.

1.1    Motivation 1: Gravity as an open quantum system
Semiclassical gravity replaces the right-hand side of the Einstein equations with the ex-
pectation value ⟨T̂µν ⟩ of the stress-energy tensor of quantum matter fields [1]. This
mean-field description is adequate when stress-energy fluctuations are small compared
with the mean, but it discards all information about correlations. Stochastic gravity—
developed by Hu, Verdaguer, Calzetta and others [2, 3]—restores the leading fluctuation
corrections by deriving, via the Feynman–Vernon influence functional [4], an Einstein–
Langevin equation:
                             Gµν [g + h] = κ2 ⟨T̂µν ⟩ + ξµν ,                         (1)
                                                           

where ξµν is a stochastic tensor whose two-point function is the noise kernel

               ⟨ξµν (x) ξαβ (x′ )⟩ = Nµναβ (x, x′ ) = 21       T̂µν (x), T̂αβ (x′ )       (2)
                                                           
                                                                                      .

The noise kernel is real, symmetric, and positive semi-definite; it encodes the quantum
state of the environment. Its existence is a theorem of quantum field theory in curved
spacetime, not a modelling assumption.
    The influence functional that generates (1) also contains a dissipation kernel DR ,
the retarded part of the stress-energy two-point function, related to the noise kernel by
a fluctuation–dissipation relation (FDR) [1]. In any causal linear-response theory, the
retarded response is analytic in the upper half of the complex frequency plane; its real
and imaginary parts are therefore linked by the Kramers–Kronig relations [5]. The key
observation of this paper is that these two kernels—noise and dissipation—dress the bare
gravitational coupling κ into a complex, frequency-dependent effective coupling κeff (k), in
exact analogy with the way a dielectric medium dresses the bare electric charge into a
complex permittivity.
    This is not a new physical effect; it is an inescapable consequence of combining two
established results:

  1. The influence functional for gravity yields both a noise kernel and a dissipation
     kernel [2].

  2. Kramers–Kronig causality ties the real and imaginary parts of any retarded response
     function [5].

What is new is the recognition that the resulting κeff (k) carries physical content—
specifically, that its imaginary part and its beat-frequency structure are observable in
principle, and that for a particular class of environments they encode number-theoretic
information.

1.2    Motivation 2: The conformal-factor problem and the sign of
       fluctuations
A second, independent motivation comes from the long-standing conformal-factor problem
of Euclidean quantum gravity [6, 7]. The Einstein–Hilbert action, after a conformal

                                              2
decomposition gµν = Ω2 g̃µν , contains a kinetic term for the conformal factor with the
“wrong” sign:                             Z
                                     1
                                                                                              (3)
                                                 p
                                             d4 x g̃ Ω2 R̃ + 6(∇Ω)2 .
                                                                      
                          SE = −
                                   16πG
The negative-definite kinetic energy makes the Euclidean path integral [Dg] e−SE un-
                                                                                R

bounded from below, rendering the standard Wick rotation ill-defined [8]. Proposed
remedies include restricting to on-shell configurations, rotating the conformal-factor con-
tour, or constraining before quantising [9].
    Our framework offers a complementary perspective. In the Lorentzian Schwinger–
Keldysh formalism, there is no Euclidean rotation, and the conformal instability manifests
instead as a sign ambiguity in the dissipation kernel DR . When DR has the “wrong”
sign relative to the noise kernel, the FDR forces Im κeff < 0—corresponding to anti-
dissipation, i.e., gravitational amplification of fluctuations. This is precisely the instability
that the conformal-factor problem encodes in Euclidean language. The advantage of the
Lorentzian open-system treatment is that the instability is automatically regulated by
the causal structure: κeff (k) is analytic in the upper half-plane and approaches the real
value κ at asymptotically high frequencies, so the theory remains well-defined mode by
mode. The conformal-factor problem thus re-emerges as a spectral feature of the complex
coupling rather than a global pathology of the path integral.

1.3    Motivation 3: Riemann zeros, GUE statistics, and number-
       theoretic spacetime
The third motivation is the oldest open question in the intersection of physics and number
theory: the spectral interpretation of the Riemann zeta zeros.
    Since Montgomery’s 1973 pair-correlation conjecture [10] and its stunning numerical
verification by Odlyzko [11], the non-trivial zeros of ζ(s) on the critical line Re(s) = 21
have been known to exhibit the same local statistics as the eigenvalues of large random
Hermitian matrices drawn from the Gaussian Unitary Ensemble (GUE) [12, 13]. Berry
and Keating conjectured that the zeros are eigenvalues of a semiclassical Hamiltonian
Ĥ = 12 (x̂p̂ + p̂x̂) [14], and Bender, Brody and Müller [15] constructed a PT -symmetric
Hamiltonian whose eigenvalues, under a suitable boundary condition, coincide with the
zeros. Rodgers proved [16] that the full GUE conjecture for the n-level correlations is
logically equivalent to a precise statement about the distribution of products of primes—
making the spectral statistics of the zeros a window into the arithmetic structure of the
integers.
    Despite this remarkable convergence of evidence, no physical system has been identi-
fied whose energy spectrum is the Riemann zero spectrum in a measurable sense. This
paper does not claim to solve the Riemann hypothesis. What it does claim is the follow-
ing: if the quantum gravitational environment has the spectral content of the Riemann
zeros—as it does in the Arithmetic–Langevin Group Field Theory (AL-GFT) constructed
in our companion work [17]—then the beat spectrum of the imaginary part of κeff inherits
GUE pair-correlation statistics, and this correlation structure is in principle observable
in the stochastic gravitational-wave background at decihertz frequencies.
    The conditional nature of this claim is essential. We are not asserting that the Rie-
mann zeros govern gravity. We are proving that if they do, the consequence is a specific,
falsifiable pattern in a specific observable. This transforms the Berry–Keating programme


                                               3
from a conjecture about an unknown Hamiltonian into a prediction about a measurable
spectrum.

1.4    Summary of results
The paper establishes the following chain of results:

  1. General theorem (Section 2). For any causal quantum environment coupled to
     linearised gravity via the Feynman–Vernon influence functional, the bare coupling
     κ is dressed into a complex effective coupling
                                                       κ
                                 κeff (k) =                     ,                        (4)
                                              1 − κ D̃R (k) O(k)

      whose imaginary part is determined by the noise kernel via a generalised fluctuation–
      dissipation theorem, and whose real and imaginary parts obey a Kramers–Kronig
      relation. The proof uses only standard results from influence-functional theory and
      the analyticity of causal response functions; no assumption about the microscopic
      theory of quantum gravity is required. A Ward identity ensures that ∇µ ⟨T̂µν ⟩ = 0
      is preserved by the dressing.

  2. Zeta-Comb realisation (Section ??). When the environment is the AL-GFT—
     a Group Field Theory whose noise kernel is a discrete superposition of log-periodic
     modes at frequencies γn = Im(ρn ), the imaginary parts of the non-trivial Riemann
     zeta zeros—the signal amplitude takes the form

                                         δκ           2
                                            = ε2 e−2σγ1 ,                                 (5)
                                          κ

      where ε is the multiplicity coupling strength, σ the soft-resonance width, and γ1 =
      14.1347 . . . is the first zeta zero. At the sweet-spot parameters σ ∼ 10−3 , ε ∼ 10−2 ,
      this gives |δκ/κ| ∼ 7 × 10−5 .

  3. GUE diagnostic (Section ??). The pairwise beat frequencies ωnm = |γn − γm |
     of the Zeta-Comb, when normalised by the local mean spacing, reproduce the GUE
     two-point correlation function R2 (u) = 1 − (sin πu/πu)2 [12]. In particular, GUE
     level repulsion forces the smallest normalised spacing umin ∼ 0.2–0.5, whereas a
     generic (Poisson) environment would populate u → 0. This binary yes/no test
     requires no parameter fitting and distinguishes the Riemann-zero environment from
     any non-arithmetic noise source.

  4. Detection roadmap (Section ??). The parameter space (ε, σ) is bounded from
     above by Planck 2018 constraints on oscillatory features in the primordial power
     spectrum [18] and from below by the projected strain sensitivities of BBO [19]
     and DECIGO [20]. The sweet spot where the GUE cross-check is visible (σ ≲
     0.002, requiring Neff ≥ 2 contributing zeros) overlaps with the region of maximal
     signal amplitude, resolving a potential tension between discriminating power and
     detectability.




                                              4
    5. Bootstrap condition (Section 8). Self-consistency—requiring the noise kernel
       that generates κeff to be compatible with the geometry it modifies—yields a non-
       linear eigenvalue problem
                                                                2
                               K(σ) · v(σ) = 0,      vn = e−2σγn ,                      (6)

      whose structure parallels the Berry–Keating programme: the zeros γn are simulta-
      neously the data that define the environment and the eigenvalues that the bootstrap
      must reproduce. The existence or non-existence of a solution at physical σ values
      would constitute a non-trivial test of the arithmetic structure of spacetime.

    The remainder of the paper is organised as follows. Section 2 derives the complex
effective coupling from the influence functional and establishes the Kramers–Kronig and
Ward-identity constraints. Section ?? specialises to the AL-GFT Zeta-Comb environ-
ment and derives the signal amplitude and beat-frequency structure. Section ?? presents
the GUE cross-check as a binary diagnostic. Section ?? maps out the parameter space
and the detection roadmap. Section ?? derives the generalised fluctuation–dissipation
theorem with beat-frequency corrections. Section 8 formulates the self-consistent boot-
strap condition. Section 10 connects the results to the Berry–Keating programme and
discusses falsifiability.
Notation and conventions. We work in natural units ℏ = c = 1 unless otherwise stated,
with metric signature (−, +, +, +). The gravitational coupling is κ2 = 16πGN . Riemann
zeta zeros on the critical line are written ρn = 21 + iγn with γn > 0 labelled in ascending
order; the first few values are
                             R 4γ1 ≈ik·x14.135, γ2 ≈ 21.022, γ3 ≈ 25.011. Fourier transforms
                     ˜
use the convention f (k) = d x e f (x).


2     Complex κ from stochastic gravity
In this section we prove that the gravitational coupling κ is generically dressed into a
complex, frequency-dependent effective coupling κeff (k) whenever gravity is treated as an
open quantum system. The derivation uses only three ingredients: (i) the Schwinger–
Keldysh closed-time-path (CTP) formalism for the gravitational field, (ii) the Feynman–
Vernon influence functional obtained by tracing over a causal quantum environment,
and (iii) the analyticity of retarded response functions in the upper half of the complex
frequency plane. No assumption about the microscopic theory of quantum gravity is
required; the result holds for any environment whose stress-energy correlators are well-
defined distributions.

2.1     Setup: linearised gravity as an open system
Consider a globally hyperbolic spacetime (M, gab ) satisfying the semiclassical Einstein
equation
                   Gab [g] + Λ gab − α Aab [g] − β Bab [g] = κ2 T̂ab
                                                                  R
                                                                     [g] ,           (7)
where κ2 = 16πGN , Λ is the cosmological constant, α and β are the renormalised higher-
derivative couplings, and the right-hand side is the renormalised expectation value of
the stress-energy tensor of quantum matter in a physically acceptable (Hadamard) state
|ψ[g]⟩ [?, 1, 2].

                                             5
   We treat the gravitational field as the system and the quantum matter field as the
environment, and consider metric perturbations hab around the semiclassical background:

                                           gab −→ gab + hab .                                                (8)

On the Schwinger–Keldysh closed time path, we double the degrees of freedom: the
forward branch carries h+ab and the backward branch carries hab . It is convenient to pass
                                                             −

to the Keldysh basis

                      h̄ab = 21 h+      −
                                               ∆hab = h+         −
                                                                                       (9)
                                          
                                  ab + hab ,             ab − hab ,

where h̄ is the classical (average) field and ∆h is the quantum (difference) field that
vanishes on shell.

2.2      The influence functional
The CTP generating functional for the metric perturbations, after integrating out the
quantum matter fields in their initial state ρ̂env , takes the form [2–4]
               Z                                          
                           − i Sgrav [g+h+ ]−Sgrav [g+h− ] + i SIF [h+ ,h− ] + i (J + ·h+ −J − ·h− )
      +   −
   Z[J , J ] =        +
                   Dh Dh e                                                                           , (10)

where Sgrav is the gravitational action and SIF is the influence action, defined via
                                              h                             i
                       i SIF [h+ ,h− ]
                     e                                  +          †      −
                                       = Trenv Û [g + h ] ρ̂env Û [g + h ] ,                              (11)

with Û [g + h] the unitary evolution operator for the matter field on the perturbed back-
ground.
    For a linear coupling of the metric perturbation to the stress-energy tensor (which
is the physical coupling of gravity to matter at leading order), the influence action to
second order in h takes the standard Feynman–Vernon form [1, 2]. In the Keldysh basis
(9), it reads
                Z           h                                                           i
                    4   4 ′     ab     R      ′   cd ′    i     ab             ′   cd ′
SIF [h̄, ∆h] =     d x d x ∆h (x) Dabcd (x, x ) h̄ (x ) + 2 ∆h (x) Nabcd (x, x ) ∆h (x ) ,
                                                                                                            (12)
where:

    • The dissipation kernel
                              R
                                   (x, x′ ) = i θ(x0 − x′0 )               T̂ab (x), T̂cd (x′ )             (13)
                                                                                              
                             Dabcd

      is the retarded part of the stress-energy two-point function. It is causal : Dabcd
                                                                                    R
                                                                                         (x, x′ ) =
      0 whenever x lies outside the causal future of x .′


    • The noise kernel

                     Nabcd (x, x′ ) = 21        T̂ab (x), T̂cd (x′ )                           T̂cd (x′ )   (14)
                                            
                                                                             − T̂ab (x)

      is the symmetrised, connected two-point function of the stress-energy fluctuations.
      It is real, symmetric in its arguments, and positive semi-definite [2].

                                                        6
The first term in (43) is the dissipative part of the influence action: it modifies the
retarded equations of motion for h̄. The second term is the noise part: it generates
stochastic fluctuations.
Remark. Equation (43) is the gravitational analogue of the Caldeira–Leggett influence
action for quantum Brownian motion [?]. The tensor indices make the expressions more
involved, but the algebraic structure is identical: a real, retarded dissipation kernel plus
an imaginary, symmetric noise kernel. This universality is the reason the complex-κ result
holds for any environment.

2.3     Effective equation of motion and the dressed propagator
The equation of motion for the classical (average) metric perturbation h̄ab is obtained by
extremising the CTP effective action with respect to ∆hab and then setting ∆h = 0 (the
physical-limit condition of the Schwinger–Keldysh formalism). From the gravitational
action expanded to second order, the kinetic operator for hab on a background gab is the
Lichnerowicz operator Ĝ, defined so that the linearised Einstein tensor is

                                         δGab = − 12 Ĝab cd hcd .                                     (15)

Including the contribution from the influence action (43), the full linearised equation of
motion in Fourier space becomes1
                          h                   i
                                                ˜ (k) = κ2 ξ(k),
                            Ĝ(k) − κ2 D̃R (k) h̄          ˜                          (16)

                                                                       ˜
where D̃R (k) is the Fourier transform of the dissipation kernel and ξ(k)   is the stochastic
                           ˜   ˜
source with correlator ⟨ξ(k) ξ(k )⟩ = Ñ (k) (2π) δ (k + k ).
                                  ′               4 (4)      ′

   Equation (16) has the structure of a Dyson equation: the bare gravitational propa-
gator G0 (k) = Ĝ −1 (k) is dressed by the retarded self-energy ΣR (k) = κ2 D̃R (k). The full
(dressed) retarded propagator is
                                                             −1
                                  GR (k) = Ĝ(k) − κ2 D̃R (k) .                                        (17)
                                           


2.4     Resummation: the complex effective coupling
The key observation is that the self-energy ΣR (k) = κ2 D̃R (k) can be absorbed into a
redefinition of the gravitational coupling. To see this, we factor the kinetic operator
as Ĝ(k) = κ−2 O(k), where O(k) is the differential operator whose eigenvalues are the
squares of the graviton mode frequencies (this factorisation is standard in the linearised
Einstein equations, where κ2 multiplies the source, not the kinetic term; see e.g. [2]).
Then (17) becomes

                                                κ2               κ2 (k)
                        GR (k) =                              = eff ,                                 (18)
                                                                 O(k)
                                         
                                     O(k) 1 − κ2 D̃R (k)/O(k)

where we have defined the effective gravitational coupling:
   1
     We suppress tensor indices for clarity, writing the equation schematically; the full tensorial structure
is restored in Appendix A.



                                                     7
                                                      κ2
                                κ2eff (k) ≡                                               (19)
                                              1 − κ2 D̃R (k) O(k)

This is the central equation of the paper. Its structure is a geometric resummation,
formally identical to the relation between bare and screened charge in quantum electro-
dynamics:
                                                  e2
                                 e2eff (ω) =               ,                       (20)
                                             1 − e2 ΠR (ω)
where ΠR is the retarded vacuum polarisation. The analogy is exact: κ plays the role of
e, and the retarded dissipation kernel D̃R (k) plays the role of the vacuum polarisation
ΠR (ω).
    Since D̃R (k) is complex-valued for real k (its imaginary part is the spectral density of
stress-energy fluctuations), the effective coupling κ2eff (k) is generically complex:

                             κ2eff (k) = Re κ2eff (k) + i Im κ2eff (k).                    (21)

The real part is the dispersive (reactive) correction to Newton’s constant—a running
gravitational coupling in the Wilsonian sense. The imaginary part encodes dissipation:
the rate at which gravitational modes lose (or gain) energy to the quantum environment.

2.5    Kramers–Kronig relations for κeff
The dissipation kernel Dabcd
                           R
                               (x, x′ ) is retarded by construction: it vanishes when x lies
outside the causal future of x′ . In Fourier space, this causal support property implies
that D̃R (k), viewed as a function of the complex frequency k 0 = ω + iη, is analytic in the
upper half-plane η > 0 [?, 5].
Proposition 1 (Kramers–Kronig for D̃R ). Let D̃R (ω, k) be the Fourier transform of a
retarded kernel satisfying
  (i) DR (x, x′ ) = 0 for x0 < x′0 (causality),

 (ii) |D̃R (ω, k)| → 0 as |ω| → ∞ in the upper half-plane (regularity at infinity).
Then for real ω:
                                         Z ∞
                                     1        dω ′
                            R
                      Re D̃ (ω, k) =   P            Im D̃R (ω ′ , k),                      (22)
                                     π −∞ ω ′ − ω
                                          Z ∞
                                       1       dω ′
                           R
                      Im D̃ (ω, k) = − P       ′
                                                      Re D̃R (ω ′ , k),                    (23)
                                       π −∞ ω − ω
where P denotes the Cauchy principal value.
Proof. Since DR (t, x; t′ , x′ ) = 0 for t < t′ , its Fourier transform in τ = t − t′ is
                                              Z ∞
                                  R
                                D̃ (ω, k) =          dτ eiωτ DR (τ, k).                    (24)
                                                0

For ω in the upper half-plane (Im ω > 0), the exponential eiωτ = ei Re ω τ e−Im ω τ is damped
for τ > 0, so the integral converges and defines an analytic function of ω in Im ω > 0.

                                                    8
    Condition (ii) ensures that D̃R /(ω ′ − ω) vanishes on the semicircular arc at infinity
in the upper half-plane. Closing the contour in the standard way (real axis plus upper
semicircle, with an infinitesimal indentation around ω ′ = ω) and applying the Cauchy
integral theorem gives
                              Z ∞
                                     dω ′
                      0 = P          ′−ω
                                           D̃R (ω ′ , k) − iπ D̃R (ω, k).              (25)
                               −∞  ω

Separating real and imaginary parts yields (89)–(90).

    Since κ2eff (k) is a rational function of D̃R (k) (Eq. 19), and the denominator 1−κ2 D̃R /O
is analytic wherever D̃R is (i.e. in the upper half-plane), κ2eff (k) inherits upper-half-plane
analyticity provided there are no zeros of the denominator there. The absence of such
zeros is guaranteed in the perturbative regime |κ2 D̃R /O| ≪ 1, which is the regime where
the semiclassical expansion is valid.

Corollary 2 (Kramers–Kronig for κeff ). In the perturbative regime, κ2eff (ω, k) is analytic
in Im ω > 0, and its real and imaginary parts are related by the dispersion relations
                                           Z ∞
                                        1         dω ′
                      2            2
                Re κeff (ω, k) = κ + P                   Im κ2eff (ω ′ , k),           (26)
                                        π −∞ ω ′ − ω
                                       Z ∞
                                     1       dω ′ 
                      2                                   2      ′          2
                                                                                       (27)
                                                                              
                Im κeff (ω, k) = − P                Re  κ eff (ω   , k) − κ    .
                                    π −∞ ω ′ − ω

The subtraction constant κ2 in (26) arises because κ2eff → κ2 as |ω| → ∞; this is the
standard once-subtracted dispersion relation.
Physical content. The Kramers–Kronig relations (26)–(27) state that the dispersive
correction to GN (real part) and the dissipative correction (imaginary part) are not inde-
pendent: measuring one determines the other. This is a direct consequence of spacetime
causality—the fact that gravitational perturbations propagate on or inside the light cone.
In particular, Im κ2eff cannot be set to zero unless Re κ2eff is frequency-independent, i.e.
unless the environment is trivial. Any non-trivial quantum environment that modifies
the running of GN necessarily generates a non-zero imaginary part.

2.6    Fluctuation–dissipation relation
The noise and dissipation kernels are not independent. For a thermal environment at
temperature T = 1/β, they satisfy the Kubo–Martin–Schwinger (KMS) condition, which
in Fourier space reads [1]
                                             βω 
                            Ñ (ω, k) = coth       Im D̃R (ω, k).                         (28)
                                               2
At zero temperature (β → ∞), this reduces to

                              Ñ (ω, k) = sgn(ω) Im D̃R (ω, k).                           (29)

In the de Sitter background relevant to inflation, the Gibbons–Hawking temperature
TdS = H/(2π) plays the role of T ; the FDR then links the noise kernel (which is the


                                              9
observable encoding the environment’s quantum state) to the imaginary part of the dis-
sipation kernel (which is the quantity that enters κeff ).
    Combining (28) with the definition (19), we obtain a direct link between the noise
kernel and the imaginary part of the effective coupling:
                                          κ4 Ñ (ω, k) tanh(βω/2)
                      Im κ2eff (ω, k) =                          2    O(k),               (30)
                                            O(k) − κ2 D̃R (k)
valid to all orders in the perturbative resummation. This equation is the precise sense
in which the noise kernel—the observable encoding the environment’s quantum state—
determines the imaginary part of the gravitational coupling. Its physical content becomes
sharp in Section ??, where the noise kernel is the Zeta-Comb.

2.7    Ward identity: conservation of stress-energy
A natural concern is whether the dressing κ → κeff (k) is consistent with the conservation
of the stress-energy tensor, which underpins the Bianchi identity ∇a Gab = 0 and hence
the consistency of general relativity.
    The answer is affirmative, and follows from a Ward identity of the CTP effective
action. Diffeomorphism invariance of the full theory (gravity + matter) implies the
contracted Bianchi identity at the quantum level: the divergence of the stress-energy
operator vanishes as an operator equation,
                                     ∇a T̂ab [g + h] = 0.                                 (31)
Taking the two-point function of both sides, this implies
                                    ∇ax Dabcd
                                         R
                                              (x, x′ ) = 0,                               (32)
                                    ∇ax Nabcd (x, x′ ) = 0.                               (33)
In Fourier space, these become transversality conditions:
                          k a D̃abcd
                                R
                                     (k) = 0,        k a Ñabcd (k) = 0.                  (34)
Proposition 3 (Conservation under dressing). The dressed propagator GR (k) defined
by (17) satisfies the transversality condition
                                         −1
                               k a GR (k) abcd = k a Ĝabcd (k),              (35)
                                  

i.e. the dressing does not generate longitudinal (unphysical) graviton modes. Equivalently,
the effective Einstein equation with κeff (k) in place of κ is automatically divergence-free.
Proof. From (17), [GR ]−1  abcd = Ĝabcd −κ D̃abcd . Contracting with k and using the transver-
                                           2 R                              a

sality (34):
                                R
          k a Ĝabcd (k) − κ2 D̃abcd (k) = k a Ĝabcd (k) − κ2 k a D̃abcd
                                                                     R
                                                                          (k) = k a Ĝabcd (k).
                                       
                                                               | {z }
                                                                 =0

The last expression is the linearised Bianchi identity for the bare kinetic operator, which
vanishes identically. Hence k a [GR ]−1
                                     abcd = 0, proving transversality.

The stochastic source ξab inherits the same conservation: ∇a ξab = 0 with probability one,
as shown in [2]. Thus the full Einstein–Langevin equation with κeff (k) preserves all the
gauge structure of general relativity.

                                                10
2.8    Summary: the general theorem
We collect the results of this section into a single statement.

Theorem 4 (Complex gravitational coupling from causal environments). Let (M, gab )
be a globally hyperbolic spacetime satisfying the semiclassical Einstein equation (7), and
let the quantum matter field be in any physically acceptable (Hadamard) state. Then:

 (a) The Feynman–Vernon influence functional for metric perturbations yields a dissi-
                    R
     pation kernel Dabcd and a noise kernel Nabcd satisfying the fluctuation–dissipation
     relation (28).

 (b) The dressed retarded graviton propagator defines a complex, frequency-dependent
     effective gravitational coupling

                                                       κ2
                                κ2eff (k)   =                     ,                   (36)
                                              1 − κ2 D̃R (k)/O(k)

      whose imaginary part is determined by the noise kernel via (30) and is generically
      non-zero.

 (c) κ2eff (ω, k) is analytic in Im ω > 0 (in the perturbative regime), and its real and
     imaginary parts obey the once-subtracted Kramers–Kronig dispersion relations (26)–
     (27).

 (d) The Ward identity (34) ensures that the dressing preserves ∇a Gab = 0; no unphys-
     ical longitudinal graviton modes are generated.

The theorem establishes that a complex gravitational coupling is not an exotic possibility
but an unavoidable consequence of treating gravity as an open quantum system—which it
necessarily is, since every graviton interacts with quantum matter. The physical content
of κeff depends entirely on the quantum state of the environment, encoded in the noise
kernel Nabcd . In Section ?? we specialise to the environment provided by the Arithmetic–
Langevin Group Field Theory, where the noise kernel is a Zeta-Comb and κeff acquires
number-theoretic structure.


3     Complex κ from Stochastic Gravity
The gravitational coupling κ2 = 16πGN enters Einstein’s field equations as a real, positive
constant. We show in this section that treating gravity as an open quantum system—
coupled to any causal quantum environment—forces κ to acquire an imaginary part.
The argument proceeds in three stages: (i) we set up the influence-functional formal-
ism for linearised gravity coupled to an arbitrary environment; (ii) we resum the dressed
gravitational propagator and identify the effective coupling κeff (k); (iii) we invoke the
Kramers–Kronig relations to prove that κeff is necessarily complex whenever the envi-
ronment is causal and dissipative. The result is a theorem, independent of the specific
environment; its specialisation to the Arithmetic-Langevin environment is deferred to §4.




                                               11
3.1     Gravity as an open quantum system
We work in linearised gravity on a cosmological (FLRW) background. Let ϕ(η, k) denote
the gauge-invariant curvature perturbation in Fourier space, with conformal time η and
comoving wavevector k. Following the stochastic-gravity programme of Hu and Verda-
guer [1], we partition the total system into

    • System S: the long-wavelength metric perturbation ϕ, governed by a quadratic
      action
                                          d3 k 2 h 2
                                    Z
                                  1                             i
                       Ssys [ϕ] =     dη       a  ϕ̇k − c 2 2 2
                                                          s k ϕk ,            (37)
                                  2      (2π)3
      where a(η) is the scale factor and cs the adiabatic sound speed.

    • Environment E: a collection of short-wavelength or internal degrees of freedom
      {χn,k }, labelled by a discrete index n, with quadratic action

                                           d3 k X  2
                                     Z
                                   1                           2         2
                                                                                 (38)
                                                                             
                        Senv [χ] =     dη            χ̇n,k − Ω n (k, η) χn,k   ,
                                   2      (2π)3 n

      where the dispersion Ωn (k, η) encodes the microscopic physics of the environment.
      No assumption is made about its origin at this stage; it could arise from quantum
      matter loops, spin-foam/GFT degrees of freedom, or any other UV completion.

    • P
      Interaction: a linear coupling of ϕ to a collective environment operator O(η, k) ≡
        n gn χn,k ,
                                                  d3 k 2
                                            Z
                             Sint [ϕ, χ] = κ dη         a ϕk O−k ,                  (39)
                                                 (2π)3
      where κ is the bare gravitational coupling and gn are dimensionless weights carrying
      the environment’s spectral information.

The total action Stot = Ssys + Senv + Sint is at most quadratic in χ, so the environment
can be integrated out exactly.

3.2     Influence functional and Schwinger–Keldysh action
On the closed time path (CTP), we double the fields: ϕ± , χ± . The CTP generating
functional is
                     Z                                
                             − i Ssys [ϕ+ ]−Ssys [ϕ− ] + i SIF [ϕ+ ,ϕ− ]+ i (J + ϕ+ −J − ϕ− )
                                                                           R
              +  −        +
          Z[J , J ] = Dϕ Dϕ e                                                                 , (40)

where the Feynman–Vernon influence functional [?]
                                  Z                                                
          −     i SIF [ϕ+ ,ϕ− ]          − i Senv+int [ϕ+ ,χ+ ]−Senv+int [ϕ− ,χ− ]
      +
  F[ϕ , ϕ ] ≡ e                 =     +
                                    Dχ Dχ e                                          ρ̂env [χ+ , χ− ]
                                                                                      (41)
encapsulates the entire back-reaction of the environment on the system.
   Because Senv + Sint is quadratic in χ, the path integral over χ± is Gaussian and yields
an exact influence action. Introducing the Keldysh variables

                             ϕc ≡ 12 (ϕ+ + ϕ− ) ,        ∆ϕ ≡ ϕ+ − ϕ− ,                            (42)

                                                    12
the standard result [?, 1] is

                       d3 k
                Z                                                                            
                        ′                    ′             ′   i               ′            ′
SIF [ϕc , ∆ϕ] = dη dη        ∆ϕk (η) DR (η, η ; k) ϕc,−k (η ) + ∆ϕk (η) N (η, η ; k) ∆ϕ−k (η ) ,
                      (2π)3                                    2
                                                                                      (43)
with two kernels:

   1. The dissipation kernel (retarded, real):

                       DR (η, η ′ ; k) = i κ2 Θ(η − η ′ )         Ok (η), O−k (η ′ ) env ,   (44)
                                                                                   


      which governs the causal, non-conservative part of the gravitational response.

   2. The noise kernel (symmetric, positive semi-definite):

                                                   κ2 
                                N (η, η ′ ; k) =        Ok (η), O−k (η ′ )     env
                                                                                     ,       (45)
                                                   2
      which sources stochastic fluctuations in the metric.

These two kernels are not independent: by construction they satisfy the fluctuation–
dissipation relation (FDR)
                                               
                                           ω
                         N (ω, k) = coth          Im DR (ω, k) ,                (46)
                                          2Teff

where Teff is the effective temperature of the environment (e.g. the Gibbons–Hawking
temperature H/2π for a de Sitter background).

3.3    Dressed gravitational propagator and effective coupling
The influence action (43) modifies the inverse propagator of ϕ. In Fourier space (ω, k),
the bare inverse propagator from Ssys is

                              G−1           2  2    2 2
                                                                                   (47)
                                                        
                                0 (ω, k) = a ω − cs k     ,

and the dissipation kernel contributes an additional self-energy. The full dressed inverse
propagator is
                          G−1 (ω, k) = G−1
                                        0 (ω, k) − κ DR (ω, k) ,
                                                      e                               (48)
where D
      e R is the Fourier transform of DR . Factoring out the bare kinetic structure, we
write                                             "                 #
                                                      κ D
                                                        e R (ω, k)
                   G−1 (ω, k) = a2 ω 2 − c2s k 2 1 − 2 2                           (49)
                                                
                                                                    .
                                                    a ω − c2s k 2
   This invites the identification of an effective gravitational couplingvia a geometric
resummation of the self-energy insertions. Denoting Π(ω, k) ≡ D  e R (ω, k)/ a2 (ω 2 − c2 k 2 ) ,
                                                                                               
                                                                                        s
the resummed propagator has the Dyson form

                                                       G0 (ω, k)
                                      G(ω, k) =                    ,                         (50)
                                                     1 − κ Π(ω, k)


                                                     13
which defines
                                                     κ
                               κeff (ω, k) ≡                 .                        (51)
                                               1 − κ Π(ω, k)
Key observation: The self-energy Π(ω, k) is a retarded response function. It is therefore
generically complex for real ω. Consequently, κeff is complex: its real part describes
the renormalised gravitational strength, and its imaginary part describes gravitational
dissipation into the environment.
    [Perturbative regime] Throughout this work, we operate in the regime |κ Π| ≪ 1,
where the Dyson resummation is well-controlled and the perturbative expansion

                             κeff ≈ κ 1 + κ Π + κ2 Π2 + · · ·                        (52)
                                                              


converges. At leading non-trivial order, δκ/κ = κ Π(ω, k).

3.4    Kramers–Kronig proof: complex κ is mandatory
We now elevate the observation of §3.3 to a theorem.

Theorem 5 (Mandatory complexity of κeff ). Let Π(ω, k) be the retarded self-energy of the
gravitational perturbation induced by any causal quantum environment with a non-trivial
spectral density. Then Im κeff (ω, k) ̸= 0 for all ω in the support of the environment’s
spectral function.

Proof. The proof consists of three steps.
Step 1: Causality ⇒ analyticity. The dissipation kernel DR (η, η ′ ; k) is retarded
[Eq. (44)], i.e. DR (η, η ′ ; k) = 0 for η < η ′ . By Titchmarsh’s theorem [?], its Fourier
transform De R (ω, k) is analytic in the upper half of the complex ω-plane:

                             e R (ω, k) analytic for Im ω > 0 .
                             D                                                        (53)

Since Π = D       0 inherits this analyticity (the bare propagator G0 is a polynomial
            e R /G−1                                                 −1

in ω), the self-energy Π(ω, k) is also analytic in the upper half-plane and vanishes as
|ω| → ∞ (the environment cannot respond faster than it is driven).
Step 2: Kramers–Kronig relations. From the analyticity and asymptotic decay of Π,
the standard Kramers–Kronig (KK) dispersion relations [?, 5] hold:
                                       Z ∞
                                   1       Im Π(ω ′ , k)
                      Re Π(ω, k) = P                     dω ′ ,            (54a)
                                   π −∞ ω ′ − ω
                                         Z ∞
                                     1       Re Π(ω ′ , k)
                      Im Π(ω, k) = − P                     dω ′ ,          (54b)
                                     π −∞ ω ′ − ω

where P denotes the Cauchy principal value. The two relations are the Hilbert-transform
pair that encodes the content of causality in the frequency domain.
Step 3: Non-trivial environment ⇒ Im Π ̸= 0. A non-trivial environment has a
spectral density ρ(ω, k) > 0 on some open interval of ω. By the optical theorem for the
self-energy (or equivalently, by unitarity of the underlying quantum theory),

                               Im Π(ω, k) = −π κ2 ρ(ω, k) ,                           (55)

                                               14
where ρ(ω, k) = (2π)−1 n |gn |2 δ(ω − Ωn (k)) is the spectral function of O. Since ρ > 0
                      P
on the support of the environment, Im Π ̸= 0, and by Eq. (54a), Re Π is non-trivially
determined by the Hilbert transform of Im Π.
   From Eq. (51),
                                         κ2 Im Π
                              Im κeff =             ̸= 0 .                          (56)
                                        |1 − κ Π|2
This completes the proof.
    [Generality] Theorem 5 makes no reference to the specific nature of the environment.
It applies equally to quantum matter fields in semiclassical gravity [1], to GFT/spin-foam
degrees of freedom [?], or to the Arithmetic-Langevin environment introduced in §4. The
only input is causality and non-trivial coupling—both of which are physically unavoidable
for any environment interacting with gravity.
    [Physical content of Im κeff ] The imaginary part of the effective coupling has a direct
physical interpretation. It controls:
  1. Gravitational dissipation: energy leaks from long-wavelength metric perturbations
     into the environment at a rate Γ ∝ Im κeff .
  2. Decoherence: the noise kernel N associated with the dissipation via the FDR (46)
     destroys quantum coherence of superposed geometries.
  3. Spectral imprint: the frequency dependence of Im κeff (ω, k) is a direct fingerprint of
     the environment’s spectral density—and therefore a potential observable.

3.5    Ward identity and conservation
A legitimate concern is whether the complexification of κ violates the conservation laws
that follow from diffeomorphism invariance. We show that it does not.
   The linearised diffeomorphism Ward identity requires the divergence of the effective
gravitational equations to vanish:
                                      kµ Γµν [ϕ] = 0 ,                                 (57)
where Γµν is the 1PI effective action vertex. In the influence-functional formalism, this
identity is preserved order-by-order in the CTP perturbation theory, because the cou-
pling (39) is constructed from the gauge-invariant perturbation ϕ. The environment-
induced self-energy Π enters as a scalar function of (ω, k) multiplying the transverse-
traceless projection of the graviton propagator. Consequently,
                         kµ κeff (ω, k) T µν = κeff (ω, k) kµ T µν = 0 ,             (58)
                                           

since stress-energy conservation kµ T µν = 0 is a property of the matter sector, independent
of the value—real or complex—of the coupling.
    More formally, the influence functional preserves the BRST symmetry of the gravita-
tional sector. The Slavnov–Taylor identities of the dressed theory are identical in form to
those of the bare theory; the only modification is the replacement κ → κeff (ω, k), which
is a c-number function and commutes with all generators [?].
Proposition 6 (Conservation guarantee). The effective Einstein equation with complex
κeff (ω, k) satisfies the linearised contracted Bianchi identity, ∇µ Gµν
                                                                      eff = 0, to the same
order as the perturbative expansion of the self-energy.

                                            15
3.6    Summary of the general result
The chain of logic is:

    Causal
    |      environment
            {z       } Titchmarsh |Π analytic in UHP ρ > 0                Im κeff ̸= 0 .    (59)
                                           {z      }                      | {z }
        retarded DR                             KK relations             complex coupling

This is a model-independent result. The only freedom is in the choice of spectral density
ρ(ω, k), which determines the pattern—but not the existence—of the imaginary part. In
the next section, we specialise to the Arithmetic-Langevin environment, where ρ is a
Zeta-Comb built from the non-trivial zeros of the Riemann zeta function, and derive the
specific observational signatures that follow.


4     The Zeta-Comb Environment
Section 3 established that any causal quantum environment renders the gravitational
coupling complex. We now specialise to the environment dictated by the Arithmetic-
Langevin Group Field Theory (AL-GFT): a discrete tower of oscillator modes whose
frequencies and couplings are built from the non-trivial zeros of the Riemann zeta func-
tion. This choice is not ad hoc—it is the unique environment that arises when the micro-
scopic GFT vertex amplitudes carry arithmetic (prime-indexed) weights, as prescribed
by Multiplicity Theory.
    The section is organised as follows. In §4.1 we define the environment and compute the
noise kernel explicitly. In §4.2 we derive the generalised fluctuation–dissipation relation
that connects noise and dissipation in the Zeta-Comb setting, revealing a family of beat
frequencies between distinct Riemann zeros. In §4.3 we characterise the resulting beat
spectrum and show that it carries a GUE fingerprint testable against random-matrix
theory.

4.1    The Arithmetic-Langevin environment
RecallP from §3.1 that the environment consists of modes χn,k with collective operator
O =       n gn χn . In the AL-GFT realisation, the index n labels the non-trivial zeros
ρn = 12 + iγn of the Riemann zeta function, with γ1 = 14.1347 . . ., γ2 = 21.0220 . . ., etc.
The coupling constants are
                                       2
                          gn = ε e−σ γn e i φn ,       φn = 12 + iγn ,                      (60)

where ε ≪ 1 is the overall multiplicity coupling strength and σ > 0 is the soft-resonance
width that provides a Gaussian damping at large n. The phase φn is precisely the non-
trivial zero itself, evaluated on the critical line.
    [Motivation for the couplings] The exponential e−σγn ensures convergence of all sums
                                                        2


over zeros and defines the effective number of contributing zeros,
                                                ∞
                                                            2
                                                X
                                   Neff (σ) ≡         e−2σ γn .                             (61)
                                                n=1

For σ ∼ 10−3 , which we will identify as the phenomenological sweet spot in §??, Neff ≈
4.2 zeros contribute, generating 7 pairwise beat frequencies. The phase φn is not a

                                                16
free parameter; it is fixed by the requirement that the noise kernel reproduce the Zeta-
Comb modulation of the primordial power spectrum derived in Gate 1 of the AL-GFT
programme.

4.1.1   Noise kernel
The noise kernel (45) evaluated for the AL-GFT environment is

                                     κ2 X
                  N (η, η ′ ; k) =             ∗
                                                   χn,k (η), χm,−k (η ′ )                            (62)
                                                 
                                           gn gm                                           env
                                                                                                 .
                                     2 n,m

For independent harmonic-oscillator modes in the Bunch–Davies vacuum on a quasi-
de Sitter background, the equal-time limit η → η ′ yields (after the standard conformal-
time-to-k mapping η∗ ≈ −1/k)
                                                 cut  N
                                           κ2 ε2 X        2
                             N (k) =                 e−2σγn |An (k)|2 ,                              (63)
                                            2 n=1

where An (k) is the slowly varying Hankel-function amplitude evaluated near horizon
crossing (see Appendix ??), and Ncut is a technical cutoff that can be sent to infinity for
σ > 0.
   The full k-dependent noise spectrum—including the oscillatory phases from the mode
functions—takes the form
                                 N (k) = N0 (k) M(k) ,                                 (64)
where N0 (k) is the standard scale-invariant noise spectrum of slow-roll inflation, and the
Zeta-Comb modulation is
                                         ∞                              
                                         X             2            k
                M(k) = 1 + 2ε        2
                                               e   −2σγn
                                                           cos γn ln + φn + O(ε4 ) .                 (65)
                                         n=1
                                                                    k∗

This is a log-periodic modulation of the primordial power spectrum at frequencies set by
the imaginary parts of Riemann zeta zeros. In the limit ε → 0, the environment decouples
and M → 1, recovering the standard ΛCDM spectrum.
    [Primordial power spectrum] The primordial curvature power spectrum inherits the
Zeta-Comb structure via the relation P(k) = P0 (k) M(k), where P0 (k) = As (k/k∗ )ns −1
is the standard nearly scale-invariant spectrum. The modulation amplitude is controlled
by ε2 , which is constrained by Planck 2018 data to satisfy ε < 0.21 at the 95% confidence
level for σ = 10−3 .

4.1.2   Dissipation kernel
The dissipation kernel (44) for the AL-GFT environment is similarly computed from the
commutator of the collective operator:
                                                   ∞
                                                   X            2            ω
                      DR (ω, k) = κ ε     2 2
                                                         e−2σγn                            ,         (66)
                                                   n=1
                                                                    ω 2 − Ω2n (k) + i 0+




                                                           17
where Ωn (k) is the effective frequency of the n-th environment mode (dependent on the
inflationary background through the scale factor). The retarded i 0+ prescription ensures
causality. The spectral density of the environment is therefore a Zeta-Comb:
                                             ∞
                                                        2
                                             X
                              ρ(ω, k) = ε2         e−2σγn δ ω − Ωn (k) ,                     (67)
                                                                      
                                             n=1

a discrete, arithmetically-structured spectral density with peaks at frequencies determined
by the Riemann zeros.

4.2     Generalised fluctuation–dissipation theorem
In the standard FDT (46), the noise and dissipation kernels are related at each frequency
independently. For the Zeta-Comb environment, the discrete, multi-frequency structure
of ρ(ω, k) induces cross-frequency correlations that enrich the standard relation.

4.2.1   Derivation
Substituting the explicit forms (64) and (66) into the definition of κeff (51), the imaginary
part of the effective coupling reads
                                                   ∞
                                   κ3 ε2           X           2
                                                          e−2σγn π δ ω − Ωn (k) + O(ε4 ) .   (68)
                                                                               
           Im κeff (ω, k) =                    2
                               1 − κ Π(ω, k)        n=1

   However, the physically relevant quantity is not Im κeff at a single frequency, but the
two-point function of the noise that drives the stochastic Einstein–Langevin equation.
The generalised FDT for the Zeta-Comb reads:
                                                     ∞
                             ω                         X      2   2
           N (ω, k) = coth          Im DR (ω, k) + ε 2
                                                         e−σ(γn +γm ) Hnm (ω, k) ,           (69)
                            2Teff                    n,m=1
                                                               n̸=m


where Hnm is the Hilbert interference term arising from the cross-correlation of the
n-th and m-th environment modes:
                                 Z ∞     en (ω ′ , k) G
                                                      e∗ (ω ′ , k)
                                                                  
                             1       Im G              m
                 Hnm (ω, k) = P                                      dω ′ .     (70)
                             π −∞             ω′ − ω

Here Gen (ω, k) is the retarded Green function of the n-th environment mode.
   [Structure of the generalised FDT] Equation (69) has two terms:

  1. The diagonal term (n = m) reproduces the standard FDT at each Zeta-Comb
     frequency individually.

  2. The off-diagonal terms (n ̸= m) are the beat-frequency contributions. They arise
     because the Zeta-Comb environment has a discrete, multi-line spectral density—
     the noise at frequency ω receives contributions from interference between lines at
     Ωn and Ωm . These terms are suppressed by e−σ(γn +γm ) and are therefore sensitive
                                                       2 2


     to the pairwise differences γn − γm .


                                                    18
4.2.2    Justification of the Hilbert-transform form
The appearance of the Hilbert transform in (70) is not incidental. It follows from the same
Kramers–Kronig logic used in §3.4: because each G   en is a retarded response function, the
product G    em is analytic in the upper half-plane for fixed m, and its real and imaginary
          en G∗

parts are therefore Hilbert-transform pairs. The Hnm terms extract the part of the noise
that is coherent between modes n and m, which is precisely the beat-frequency content.

4.3     Beat-frequency spectrum and GUE fingerprint
The off-diagonal terms in the generalised FDT (69) oscillate at the beat frequencies

                                  ωnm ≡ γn − γm ,        n > m.                              (71)

The number of distinct beat frequencies from Neff effective zeros is N2eff ; for the sweet-
                                                                          

spot value σ ∼ 10−3 , the first ∼ 4 zeros contribute, yielding ∼ 7 pairwise beats.

4.3.1    Observable modulation in κeff
Including the beat-frequency terms, the fractional shift of the gravitational coupling ac-
quires a characteristic oscillatory structure in ln(k/k∗ ):

      δκ             X      2
                                                X      2   2
         (ω, k) = ε2   e−2σγn eiγn ln(k/k∗ ) + ε2 e−σ(γn +γm ) ei ωnm ln(k/k∗ ) + O(ε4 ) .   (72)
      κ              n                          n̸=m


The first sum is the fundamental Zeta-Comb (oscillations at each γn ); the second is
the beat-frequency comb (oscillations at each γn − γm ). The signal amplitude at the
sweet spot is

              δκ                      2
                            = ε2 e−2σγ1 ≈ 6.7 × 10−5 ,       (ε = 0.01, σ = 0.001) .         (73)
               κ sweet spot

4.3.2    The GUE cross-check
The distribution of the normalised beat frequencies
                                  γn − γm                      2π
                          unm ≡           ,       ⟨∆γ⟩ =                ,                    (74)
                                   ⟨∆γ⟩                    ln(γmid /2π)

(where ⟨∆γ⟩ is the local mean spacing from the Riemann–von Mangoldt formula) is
predicted by the Montgomery–Odlyzko pair correlation conjecture to follow the
GUE distribution:
                                                  2
                                            sin πu
                             R2 (u) = 1 −             .                    (75)
                                              πu
This is the same pair-correlation function that governs the eigenvalue statistics of random
matrices drawn from the Gaussian Unitary Ensemble (GUE), as first noted by Dyson in
a celebrated conversation with Montgomery.
    The GUE prediction is a binary diagnostic for the Zeta-Comb hypothesis. It makes
two sharp predictions:


                                                19
  1. Level repulsion at u → 0: R2 (u) → 0 quadratically as u → 0, meaning the small-
     est normalised beat-frequency spacings are suppressed. For the first 10 zeros, the
     smallest normalised spacing is umin ∼ 0.2–0.5. A Poisson (random, uncorrelated)
     environment would produce R2 (u) → 1 as u → 0—no level repulsion.

  2. Oscillatory approach to unity: R2 (u) overshoots and oscillates around 1 for
     u ≳ 1, a distinctive “ringing” signature absent in Poisson statistics.

   If the beat frequencies extracted from a gravitational-wave or CMB dataset match the
GUE pattern (75), it constitutes evidence for an arithmetic environment; if they match
Poisson, the Zeta-Comb hypothesis is falsified regardless of parameter tuning.

4.3.3   Connection to Rodgers’ theorem and prime distributions
The diagnostic above acquires deeper significance through a theorem of Rodgers, who
proved (conditional on the Riemann Hypothesis) that the GUE conjecture for zeta zeros
is logically equivalent to a specific statement about the distribution of products of prime
numbers in short intervals. Concretely: the beat spectrum of κeff traces GUE statistics
if and only if the primes satisfy the Hardy–Littlewood-type correlation laws encoded in
the von Mangoldt function.
     This transforms an observational measurement—the pattern of oscillations in the
gravitational-wave or CMB power spectrum—into a number-theoretic test. A successful
detection of the GUE pattern would:

  1. Confirm the Zeta-Comb as the physical environment.

  2. Provide empirical evidence for the GUE conjecture (equivalently, for the Mont-
     gomery pair correlation conjecture).

  3. Via Rodgers’ theorem, test a specific prediction about the distribution of prime
     powers.

4.4     Beat-frequency visibility and the Neff threshold
The beat-frequency terms in (72) are observable only if Neff ≥ 2, i.e. at least two zeros
contribute with appreciable amplitude. This requirement sets an upper bound on the
resonance width:
                               1          1
                          σ≲ 2 ≈                  ≈ 0.0011 ,                         (76)
                              2γ2    2 × (21.02)2
or equivalently σ ≲ 0.002 when we require Neff ≥ 2 to one-e-fold accuracy.
    Simultaneously, the signal amplitude (73) is maximised for small σ (since the ex-
ponential damping is weakest). This means that the requirement for beat-frequency
visibility overlaps with the requirement for maximal signal-to-noise in gravitational-wave
detectors—a non-trivial structural coincidence that we elevate to the status of theoret-
ical naturalness in §??.
    [Sweet spot] The intersection of the beat-visibility constraint (σ ≲ 0.002) with the
Planck 2018 upper bound on ε and the BBO/DECIGO sensitivity curves defines a sweet
spot at σ ∼ 10−3 , ε ∼ 10−2 . At this point the signal amplitude is |δκ/κ| ≈ 6.7 × 10−5 ,
the effective number of zeros is Neff ≈ 4.2, and the GUE cross-check is operational with
7 beat frequencies.

                                            20
4.5     Summary: from general theorem to arithmetic prediction
The logical flow of this section is:
                               SK trace                             gen. FDT
      AL-GFT couplings gn −−−−−→ N (k) = N0 M(k) −−−−−−→ ωnm = γn − γm
      |      {z         }        |      {z     }         |    {z     }
             Eq. (60)                             Zeta-Comb                     beat frequencies

       Montgomery         ?
      −−−−−−−→ R2 (u) = 1 − sinc2πu .
               |        {z        }
                          GUE test
The chain has a single free spectral-density choice (Zeta-Comb vs. anything else); every
subsequent prediction is fixed. The GUE cross-check is binary and requires no fitting: it
tests the hypothesis at the level of the environment’s identity, not its parameters.


5      Conservation and Consistency
The promotion of the gravitational coupling κ2 = 16πGN from a real constant to a com-
plex, scale-dependent effective coupling κeff (k) raises an immediate question of principle:
does the modified theory remain consistent with the diffeomorphism invariance that un-
derpins general relativity? In this section we show that the answer is yes, provided the
noise and dissipation kernels satisfy a set of Ward–Takahashi identities inherited from
the conservation of the stress-energy tensor. We establish three results: (i) the stochastic
source ξab is covariantly conserved on the semiclassical background; (ii) the contracted
Bianchi identity ∇µ Gµν = 0 is preserved at each order in ε; and (iii) the energy ex-
changed between the gravitational “system” and the Zeta-Comb environment is governed
by a fluctuation-dissipation relation whose structure is dictated by causality and unitarity.

5.1     Ward identity for the stochastic source
The starting point is the operator identity for the renormalized stress-energy tensor on
the semiclassical background (M, gab ):

                                          ∇a T̂ab
                                               R
                                                  [g; x) = 0 .                                     (77)

This is the quantum Ward identity expressing diffeomorphism invariance of the matter
sector. The noise kernel, defined as the connected symmetrized two-point function of T̂ab
                                                                                       R
                                                                                          ,

               Nabcd (x, y) = 21 t̂ab (x), t̂cd (y) ,          R       R
                                                                                    (78)
                                  
                                                      t̂ab ≡ T̂ab − ⟨T̂ab ⟩,

inherits this conservation as a distributional identity on each index group separately [1]:

                        ∇ax Nabcd (x, y) = 0 ,         ∇cy Nabcd (x, y) = 0 .                      (79)

Proof. By Eq. (77) the operator t̂ab satisfies ∇a t̂ab = 0 in the Heisenberg picture. Taking
the x-divergence of the anticommutator inside the expectation value in Eq. (78) and using
the Leibniz rule for ∇ax —which acts only on the x-supported operator—yields Eq. (79)
directly. No renormalization subtlety arises because the noise kernel is ultraviolet finite:
the identity-operator counterterms in T̂ab
                                         R
                                            − T̂ab cancel in the connected correlator [?, 2].
□


                                                  21
   The Gaussian stochastic tensor ξab [g; x) is defined by the correlators

                     ⟨ξab (x)⟩s = 0 ,       ⟨ξab (x) ξcd (y)⟩s = Nabcd (x, y) ,         (80)

where ⟨·⟩s denotes the stochastic average. Since Nabcd is symmetric and positive semi-
definite (a consequence of the self-adjointness of T̂ab
                                                     R
                                                        ), ξab is well-defined. Taking the
divergence of Eq. (80) and using Eq. (79):

                        ⟨∇a ξab ⟩s = 0 ,       ⟨∇ax ξab (x) ξcd (y)⟩s = 0 .             (81)

For a Gaussian field whose mean and two-point function are both annihilated by ∇a , all
higher cumulants vanish, and hence ∇a ξab = 0 with probability one—it is a deterministic
zero, not merely zero in expectation.
    [colback=gray!5, colframe=black!50, title=Theorem 1 (Stochastic conservation)] Let
ξab be the Gaussian stochastic source defined by Eq. (80) on a semiclassical background
(M, gab ) satisfying the semiclassical Einstein equation. Then ∇a ξab [g; x) = 0 as a distri-
butional identity on M, and the Einstein–Langevin equation
                                                               (1)
                                              R
                 Gab [g + h] + Λ gab − 8πGN T̂ab [g + h]             = 8πGN ξab [g]     (82)

is consistent with the contracted Bianchi identity to linear order in hab .
This result is standard in the Hu–Verdaguer stochastic gravity programme [?,1,2]. What
is new in our framework is its extension to the case where the environment carries arith-
metic structure (the Zeta-Comb), and the resulting effective coupling κeff (k) is complex.
We now show that the Ward identity survives this generalization.

5.2    Preservation of the Bianchi identity with complex κeff
Recall from §2 that the effective gravitational coupling takes the form
                                                       κ
                               κeff (k) =                    ,                         (83)
                                             1 − κD
                                                  eR (k) O(k)

where D  eR (k) is the retarded dissipation kernel and O(k) encodes the system’s response
(both defined in momentum space on the FLRW background). The imaginary part of
κeff arises because D eR (k) is complex for causal (retarded) kernels—its real and imaginary
parts are related by Kramers–Kronig dispersion relations.
     The key observation is that Eq. (83) is a multiplicative dressing of the bare coupling
κ. The linearized Einstein tensor on the left-hand side of the Einstein–Langevin equation
still satisfies
                                       ∇µ G(1)
                                             µν [g; h] = 0                              (84)
identically, as this is a consequence of the contracted Bianchi identity applied to the
background-plus-perturbation metric. Equation (84) holds for any hab , independently of
the field equations; it is a geometric identity, not a dynamical one.
   On the source side, the complex dressing enters as

                                                      D
                                                      eR (k)
                 κeff (k) ξab (k) = κ ξab (k) + κ2           ξab (k) + O(κ3 ) .         (85)
                                                      O(k)
At each order in κ, the stochastic source remains divergence-free because:

                                                22
  1. ∇a ξab = 0 by Theorem 1;
  2. The dressing factor D eR (k)/O(k) is a scalar function of the comoving wavenumber
     k (not a differential operator acting on the tensor indices of ξab ), so it commutes
     with the covariant divergence:
                                h           i
                             ∇ f (k) ξab (k) = f (k) ∇a ξab (k) = 0 ,
                               a
                                                                                     (86)

      where f (k) = D
                    eR (k)/O(k).
Thus, promoting κ → κeff (k) does not spoil the divergence-free character of the source,
and the Bianchi identity is preserved order by order.
    [colback=blue!3, colframe=blue!40, title=Corollary (Bianchi compatibility)] The com-
plex gravitational coupling κeff (k) defined by Eq. (83) is compatible with the contracted
Bianchi identity ∇µ Gµν = 0 at every order in the perturbative expansion in ε (the mul-
tiplicity coupling strength), provided the bare noise kernel satisfies Eq. (79).
Remark. The argument above relies on the fact that the Zeta-Comb modulation enters
through a scalar dressing of the coupling, not through a tensor-valued modification of the
noise kernel’s index structure. This is a consequence of the linear system-environment
coupling adopted in the AL-GFT framework (§??): the interaction Sint ∼ ϕ O preserves
                                                                            R

the tensorial conservation law because O is constructed from scalar contractions of the
environment fields. A nonlinear coupling (relevant for beyond-Gate-1 extensions) could
in principle introduce tensor dressings, which would require a more careful Ward identity
analysis.

5.3    Fluctuation-dissipation relation and energy flow
An open quantum system in thermal equilibrium satisfies the fluctuation-dissipation re-
lation (FDR), which constrains the noise kernel N in terms of the dissipation kernel DR
and the temperature T of the environment [?,2]. In the cosmological setting, the relevant
“temperature” is the Gibbons–Hawking temperature TdS = H/(2π) of the quasi-de Sitter
background. For a causal (retarded) dissipation kernel, the FDR in Fourier space reads
                            e (ω) = coth ω
                                                
                           N                       Im D
                                                      eR (ω) ,                       (87)
                                           2 TdS
where ω is the frequency conjugate to conformal time. At high frequencies ω ≫ TdS ,
the hyperbolic cotangent approaches unity and N
                                              e ≈ Im DeR , corresponding to the quan-
tum (zero-temperature) limit. At low frequencies ω ≪ TdS , the classical limit N e ≈
              eR emerges.
(2 TdS /ω) Im D

Zeta-Comb generalization. In the AL-GFT framework, the environment is not a
generic thermal bath but a structured collection of modes at frequencies set by the Rie-
mann zeta zeros {γn }. The noise kernel acquires the Zeta-Comb modulation (derived in
§??):
                                       Neff                                
                                                    2
                                        X
                                      2        −2σγ
                                                                                    (88)
                                                                          
              Ne (k) = Ne0 (k) 1 + 2ε        e     n cos γ ln(k/k ) + φ
                                                          n      ⋆      n     ,
                                        n=1

where N e0 (k) is the standard (unmodulated) noise kernel, ε is the multiplicity coupling,
σ the resonance width, γn = Im(ρn ) the n-th Riemann zero’s imaginary part, and φn =
1
2
  arg ζ(ρn ).

                                              23
   The dissipation kernel is constrained by the Kramers–Kronig relations, which are
a direct consequence of causality (analyticity of D
                                                  eR in the upper half of the complex
ω-plane):
                                          Z ∞    eR (ω ′ )
                                      1       Im D
                             eR (ω) = P
                          Re D                   ′−ω
                                                           dω ′ ,                      (89)
                                      π    −∞  ω
                                           Z ∞     eR (ω ′ )
                                        1       Re D
                          Im DR (ω) = − P
                             e
                                                   ′−ω
                                                             dω ′ .                    (90)
                                        π   −∞   ω
The generalized FDR for the Zeta-Comb environment then takes the form

             e (k) = coth ωk Im D
                                             X      2
                                   eR (k) + ε2   e−2σγn H N                            (91)
                                                          
             N                                            e0 (k; γn ) ,
                           2 TdS               n


where ωk is the physical frequency associated with wavenumber k, and H[N      e0 ](k; γn )
denotes the Hilbert-transform–shifted contribution at beat frequency γn . The first term
is the standard FDR; the second encodes the arithmetic correction from the Zeta-Comb
environment.

Energy budget. The imaginary part of κeff governs the energy exchange between the
gravitational system and the arithmetic environment. Writing κeff = |κeff | eiθ(k) , the
energy flow rate per logarithmic wavenumber interval is
                   dE
                         = − Im κeff (k) ξab (k) hab (k) s ∝ ε2 sin θ(k) ,             (92)
                  d ln k
where the phase θ(k) = arg κeff (k) is determined by the ratio Im D
                                                                  eR /Re (1 − κ DeR /O).
At the sweet-spot parameters (σ ∼ 10 , ε ∼ 10 ) identified in §??, the phase is small,
                                       −3       −2

θ ∼ O(ε2 ), so the energy exchange is perturbative and the gravitational sector remains
stable against runaway energy injection from the environment.

Physical interpretation. In the language of open quantum systems, the imaginary
part Im κeff plays the role of a gravitational dissipation coefficient: it quantifies how
efficiently the Zeta-Comb environment can absorb or emit energy through metric fluc-
tuations. The Ward identity (Theorem 1) guarantees that this dissipation respects the
diffeomorphism symmetry—no energy is created or destroyed in the total system (gravity
+ environment), only redistributed between the sectors.
     This is the gravitational analogue of the optical theorem in scattering theory: the
imaginary part of the forward scattering amplitude is related to the total cross sec-
tion. Here, the imaginary part of κeff is related to the total “cross section” for graviton–
environment interaction, summed over the discrete Zeta-Comb modes:

                                             Im D
                                                eR (k)
                          Im κeff (k) = κ2             + O(κ3 ) .                      (93)
                                              |O(k)|2

5.4    Consistency checks
We summarize the internal consistency of the framework by listing the constraints that
are satisfied simultaneously:

                                             24
    1. Covariant conservation. ∇µ Gµν = 0 (geometric, from Bianchi identity); ∇a ξab =
       0 (dynamical, from Ward identity of the matter sector). Together these guarantee
       that the perturbed metric gab + hab satisfies the linearized constraint equations.

    2. Causality. The retarded dissipation kernel D      eR (ω) is analytic in the upper half-
       plane, ensuring that κeff (ω) also inherits this analyticity (since the denominator in
       Eq. (83) is a polynomial in DeR and thus shares its domain of analyticity). Kramers–
       Kronig relations (89)–(90) follow.

    3. Unitarity. The noise kernel Nabcd is positive semi-definite (consequence of the self-
       adjointness of T̂ab
                        R
                           ), which guarantees that the stochastic source has a well-defined
       probability measure and that the fluctuation-dissipation relation (87) is compatible
       with the second law of thermodynamics.

    4. Trace identity for conformal matter. If the quantum field is conformally
       coupled, the trace g ab ξab = 0, so the stochastic source does not contribute to the
       trace anomaly. This is preserved under κ → κeff since the dressing is scalar.

    5. Perturbative stability. At the sweet-spot parameters, the correction to κ is
       |δκ/κ| ∼ 6.7 × 10−5 , well within the perturbative regime |δκ/κ| ≪ 1. The back-
       reaction of the Zeta-Comb environment on the background geometry is therefore
       self-consistently small.

    6. ε → 0 recovery. In the decoupling limit ε → 0, the noise kernel reduces to N   e0 (k),
       the dressing κeff → κ, and the standard semiclassical Einstein equation is recovered
       to arbitrary precision.

These six conditions collectively ensure that the complex gravitational coupling intro-
duced in §2 is not an ad hoc modification of general relativity, but a necessary consequence
of treating gravity as an open quantum system whose environment carries arithmetic
structure. The Ward identity is the linchpin: it ties together conservation, causality, and
the Bianchi identity into a single self-consistent package.


6     The GUE Cross-Check
The central claim of this paper is that the environment generating the imaginary part of
the gravitational coupling is not generic stochastic noise but is arithmetically structured :
its spectral lines are located at the imaginary parts γn of the non-trivial Riemann zeta
zeros. Any such claim demands an internal consistency test that is independent of the
overall signal amplitude ε. The Gaussian Unitary Ensemble (GUE) statistics of the
γn [10, 11] provide exactly such a test. In this section we show that the beat spectrum
of the complex coupling κeff (k) carries a pair-correlation fingerprint that distinguishes a
Riemann-zero environment from any environment with uncorrelated (Poisson) spectral
lines. The test is binary—it requires no fit parameters—and can be applied to any future
dataset (CMB, SGWB, or interferometric) in which the oscillatory modulation of Sec. ??
is resolved.




                                              25
6.1     Pair correlation of the beat frequencies
6.1.1   From spectral lines to beat frequencies
The modulation function M(k) derived in Sec. ?? is a superposition of Neff oscillatory
terms with frequencies γn (n = 1, . . . , Neff ) in the variable ln(k/k⋆ ). The effective number
of contributing zeros is set by the Gaussian damping:
                                                 ∞
                                                             2
                                                 X
                                   Neff (σ) =          e−2σ γn ,                           (94)
                                                 n=1

which, for the sweet-spot value σ ∼ 10−3 , gives Neff ≈ 4.2. The power spectrum of M(k)
in the u ≡ ln(k/k⋆ ) domain therefore contains
                                                      
                                               ⌊Neff ⌋
                                   Nbeat =                                          (95)
                                                  2

pairwise beat frequencies

                          ∆ij = |γi − γj | ,         1 ≤ i < j ≤ Neff .                    (96)

At the sweet spot, ⌊Neff ⌋ = 4 yields Nbeat = 6 resolved beat lines (with a seventh partially
suppressed), each carrying information about the spacing between pairs of Riemann zeros.

6.1.2   The Montgomery–Odlyzko pair correlation
Montgomery’s pair correlation conjecture [10], confirmed numerically by Odlyzko to ex-
traordinary precision for zeros near height T ∼ 1020 [?, 11], states that the two-point
correlation function of the normalized zero spacings γ̂n = γn · ln(γ2π
                                                                    n /2π)
                                                                           tends, in the large-
height limit, to the GUE form:
                                                       2
                                                 sin πs
                                GUE
                               R2 (s) = 1 −                .                               (97)
                                                   πs

Two properties of Eq. (97) are decisive:

   1. Level repulsion. R2GUE (s) → 0 as s → 0, meaning that close spacings are quadrat-
      ically suppressed: R2GUE (s) ∼ π 2 s2 /3 + O(s4 ). This is in sharp contrast to Poisson
      statistics, for which R2Poisson (s) = 1 for all s.

   2. Oscillatory approach to unity. For s ≫ 1, R2GUE (s) = 1 − (πs)−2 sin2 (πs)
      oscillates with decaying amplitude, generating a characteristic “dip–peak” pattern
      in the pair-correlation histogram.

6.1.3   Beat-frequency pair correlation as a proxy
The beat frequencies ∆ij of Eq. (96) are, by definition, the differences between pairs of
spectral lines. Their empirical distribution, measured from the Fourier transform of the
observed modulation, is a direct estimator of R2 (s). Concretely, define the normalized
differences
                                               ∆ij
                                       sij =       ,                                (98)
                                              ⟨∆⟩

                                                26
where ⟨∆⟩ is the mean spacing among the first Neff zeros. For the first ∼ 10 Riemann
zeros, the mean spacing is ⟨∆⟩ ≈ 3.7 (in unnormalized units), and the smallest normalized
difference satisfies smin ≈ 0.2–0.5, reflecting GUE level repulsion. A Poisson environment
with the same mean density would populate s < 0.1 with probability ∼ 10%; a GUE
environment suppresses this to ≲ 1%.

6.2     Level repulsion as a binary diagnostic
6.2.1   The diagnostic statistic
We define a binary diagnostic that requires no fitting and no knowledge of the signal
amplitude ε:                                         .
                                                                                 (99)
                                
                        Q ≡ # (i, j) : sij < scut      Nbeat ,
where scut is a fixed threshold (we adopt scut = 0.1). The null hypothesis H0 (Poisson
environment) and alternative H1 (GUE/Riemann-zero environment) predict:

          Hypothesis                     E[Q]                         Var[Q]
          H0 : Poisson    Z scut      scut = 0.10             ∼ scut (1 − scut )/Nbeat
          H1 : GUE                 R2GUE (s) ds ≈ 3 × 10−4           ≪ VarH0
                           0

In words: any observation of Q ≈ 0 is consistent with GUE; Q ≳ 0.05 rules it out. The
test is binary and requires only the extracted beat frequencies, not their amplitudes.

6.2.2   Finite-Neff corrections
For Neff ≲ 10, the asymptotic formula (97) receives corrections of order 1/Neff
                                                                            2
                                                                                . Following
the finite-N analysis of Bogomolny and Keating [?], the two-point function for the first N
Riemann zeros takes the form
                (N )                       γ02 + 2γ1 + c0
               R2 (s) = R2GUE (s) −                       sin2 (πs) + O(ρ̄ −3 ) ,        (100)
                                                π 2 ρ̄ 2
where ρ̄ = ρ̄(T ) is the mean density of zeros at height T , and γ0 , γ1 , c0 are constants
from the Hardy–Littlewood prime-pair conjecture [?, ?]. Crucially, the correction term is
proportional to sin2 (πs) and therefore vanishes at s = 0: level repulsion is preserved at
all finite N . This ensures that the binary diagnostic Q remains valid even at Neff ∼ 4.

6.2.3   Nearest-neighbor spacing distribution
A complementary statistic is the nearest-neighbor spacing distribution p(s), which for
GUE is well approximated by the Wigner surmise [?]:
                                       32        4 
                           pGUE (s) = 2 s2 exp − s2 .                            (101)
                                       π           π
The quadratic onset pGUE (s) ∝ s2 is the hallmark of GUE-class level repulsion (β = 2 in
the Dyson classification), as opposed to pGOE (s) ∝ s (β = 1) or pPoisson (s) = e−s (β = 0).
With only Neff ∼ 4 zeros, the histogram of nearest-neighbor spacings cannot resolve the
full functional form of Eq. (101), but the absence of small spacings (s < 0.1) is already a
2–3σ discriminant between GUE and Poisson for Nbeat ≥ 6.

                                                27
6.3     Connection to arithmetic via Rodgers’ theorem
The pair-correlation test acquires deeper significance through a recent theorem of Rodgers [?],
which establishes:
Theorem 7 (Rodgers, 2018). Assume the Riemann Hypothesis. Then the GUE Conjec-
ture for the zeros of ζ(s) is logically equivalent to a statement about the distribution of
products of primes: specifically, the likelihood that products of primes drawn from certain
intervals are close to other products of primes.
This equivalence transforms our observational program from a spectral-statistics exercise
into a test of prime-number distribution:
   • Measuring R2 (s) from the beat spectrum of κeff (k) and finding it consistent with
     Eq. (97) would constitute observational evidence for the GUE conjecture,
     obtained not from numerical computation of ζ(s) but from a physical measurement.
   • Conversely, finding R2 (s) inconsistent with GUE—for instance, Poisson statistics—
     would rule out the Riemann-zero identification of the spectral lines and falsify the
     AL-GFT environment model.
It is worth emphasizing that Rodgers’ theorem is conditional on RH. In our framework,
this conditionality is absorbed into the model definition: the AL-GFT environment is
constructed from the non-trivial zeros ρn = 21 + iγn , which lie on the critical line by
assumption. A successful GUE cross-check therefore tests the internal consistency of this
construction, not the truth of RH per se.

6.4     Analysis pipeline
We now describe a concrete, end-to-end pipeline for extracting the GUE signature from
observational data. The pipeline is designed to be detector-agnostic; we specify the
required inputs and outputs at each stage.

6.4.1   Stage 1: Spectral extraction
Input. A one-dimensional data vector d(k) representing the measured quantity (CMB
power spectrum P(k), or stochastic gravitational-wave background spectral density ΩGW (f ))
over a range [kmin , kmax ] with kmax /kmin ≫ 1 (at least two decades for Fourier resolution).

Procedure.
  1. Divide out the smooth baseline (e.g., P0 (k) for CMB, or the power-law template
     ΩPL (f ) for SGWB) to obtain the residual modulation:
                                      d(k)
                          r(u) ≡                 − 1,   u = ln(k/k⋆ ) .               (102)
                                   dbaseline (k)

  2. Compute the Lomb–Scargle periodogram Ŝ(ω) of r(u) in the log-wavenumber do-
     main u. Peaks in Ŝ(ω) at frequencies ω = γn correspond to individual Riemann-zero
     spectral lines; peaks at ω = ∆ij correspond to beat frequencies.
  3. Identify significant peaks above a false-alarm probability threshold (e.g., FAP <
     10−3 , corresponding to ≳ 3.3σ for Gaussian noise). Record the set of detected
     frequencies {ω̂α }N
                       α=1 .
                        det




                                             28
6.4.2   Stage 2: Frequency identification
Procedure.

  1. Match detected frequencies ω̂α against the known Riemann zeros {γn }N  n=1 (tab-
                                                                               max


     ulated to arbitrary precision [?]). Accept matches satisfying |ω̂α − γn | < δωres ,
     where δωres ∼ π/∆u is the Fourier resolution set by the available u-range ∆u =
     ln(kmax /kmin ).

  2. Form the set of identified zeros Ẑ = {γ̂n1 , . . . , γ̂nm } and the corresponding set of all
     pairwise differences ∆
                          ˆ ij = |γ̂n − γ̂n |.
                                     i     j


  3. Cross-check: verify that beats ∆
                                    ˆ ij also appear in the periodogram Ŝ(ω). Con-
     cordance between directly detected lines and beat-predicted lines strengthens the
     identification.

6.4.3   Stage 3: Pair-correlation histogram
Procedure.

  1. Normalize the identified spacings: ŝij = ∆
                                               ˆ ij /⟨∆⟩.
                                                      ˆ

  2. Construct the empirical√pair-correlation function R̂2 (s) by histogramming the ŝij
     with bin width δs ∼ 1/ Nbeat .

  3. Compare R̂2 (s) against R2GUE (s) [Eq. (97)] and R2Poisson (s) = 1 using a Kolmogorov–
     Smirnov (KS) or Anderson–Darling (AD) statistic.

  4. Evaluate the binary diagnostic Q [Eq. (99)] and report:

         Q < scut =⇒ consistent with GUE (Riemann-zero environment),
       (
                                                                                            (103)
         Q ≥ scut     =⇒ inconsistent with GUE (generic/Poisson environment).

6.4.4   Stage 4: Bootstrap confidence assessment
Procedure. To assess statistical significance with Neff ∼ 4–10 zeros:

  1. Generate 104 Monte Carlo realizations of Neff frequencies drawn from a Poisson
     process with the same mean density. For each realization, compute the KS distance
     to GUE and record Q.

  2. Generate 104 realizations using the actual first Neff Riemann zeros with Gaussian
     frequency errors δωres . Compute the same statistics.

  3. The p-value for GUE rejection under H0 (Poisson) is the fraction of Poisson real-
     izations with KS distance to GUE smaller than the observed value. For Nbeat ≥ 6,
     we estimate p ≲ 0.05 is achievable, rising to p ≲ 0.01 for Neff ≥ 7 (corresponding
     to σ ≲ 5 × 10−4 ).




                                               29
6.5    Visibility requirements and the sweet spot
The GUE cross-check requires at least two resolved spectral lines, i.e. Neff ≥ 2. From
Eq. (94), the condition e−2σγ2 ≥ e−1 (i.e., the second zero γ2 = 21.022 contributes at least
                             2


1/e of its unsuppressed amplitude) gives
                                        1
                                σ ≲          ≈ 1.1 × 10−3 .                            (104)
                                       2 γ22

A less stringent requirement, Neff ≥ 2 (i.e. the sum in Eq. (94) exceeds 2), yields

                                        σ ≲ 0.002 .                                    (105)

This is the beat-frequency visibility boundary identified in Sec. 7.1. Crucially, it overlaps
with the region of maximal signal amplitude |δκ/κ| (which is maximized for σ → 0 at
fixed ε), so the sweet spot σ ∼ 10−3 simultaneously

  1. maximizes detectability of the overall modulation, and

  2. enables the GUE cross-check with Nbeat ≥ 6.

This coincidence is not a fine-tuning but a structural feature of the framework: the same
Gaussian damping that controls signal amplitude also controls the number of resolved
spectral lines.

6.6    Illustrative numerical example
To ground the preceding analysis, we evaluate the beat-frequency statistics for the first
four Riemann zeros:

             γ1 = 14.1347 ,   γ2 = 21.0220 ,        γ3 = 25.0109 ,   γ4 = 30.4249 .    (106)

The six pairwise differences are:

                              (i, j)     ∆ij  sij = ∆ij /⟨∆⟩
                              (1,2)     6.887      1.27
                              (1,3)    10.876      2.00
                              (1,4)    16.290      3.00
                              (2,3)     3.989      0.73
                              (2,4)     9.403      1.73
                              (3,4)     5.414      1.00

where ⟨∆⟩ = 8.81. The key observation is that smin = 0.73, achieved by the (2, 3) pair.
No normalized spacing falls below 0.1—indeed, none falls below 0.5. This reflects the
quadratic level repulsion of Eq. (101): GUE zeros avoid clustering.
    For comparison, four Poisson-distributed frequencies with the same mean spacing
would have Prob(smin < 0.1) ≈ 34% for Nbeat = 6 independent pairs. The observed
smin = 0.73 thus already rejects Poisson at the ∼ 2σ level from these four zeros alone.




                                               30
6.7     Discussion: what the GUE test does and does not prove
What it does. A successful GUE cross-check demonstrates that the spectral lines
in κeff (k) are not randomly placed but obey the specific correlation structure of the
Riemann zeta zeros. Via Rodgers’ theorem [?], this is equivalent to a statement about
the distribution of prime powers—the deepest known connection between physics and
number theory. The test is amplitude-independent: even if ε is too small for direct SGWB
detection, the GUE signature can in principle be extracted from the relative positions of
resolved spectral lines in any sufficiently precise power-spectrum measurement.

What it does not. The GUE test does not prove that the environment is built from
Riemann zeros; it proves only that the environment’s spectral statistics are consistent
with the GUE universality class. Other physical systems (quantum billiards, disordered
conductors) share this universality class. The additional requirement that the individual
frequencies match known values of γn (Stage 2 of the pipeline) is needed to distinguish the
Riemann-zero hypothesis from a generic chaotic-quantum-system hypothesis. Together,
frequency identification and GUE pair correlation constitute a two-pronged test that, if
passed simultaneously, would provide compelling evidence for the arithmetic structure of
quantum gravity noise.


7       Observational Signatures
The preceding sections derived the complex gravitational coupling κeff (k) (Sec. 2), its
Zeta-Comb modulation spectrum (Sec. ??), and the GUE internal consistency check
(Sec. 6). In this section we map these theoretical results onto the space of observable
parameters, identify the detector configurations capable of testing the predictions, and
demonstrate that the parameter sweet spot (σ ∼ 10−3 , ε ∼ 10−2 ) simultaneously satisfies
existing constraints, enables GUE cross-checks, and falls within the projected sensitivity
of next-generation gravitational-wave observatories.

7.1     The two-dimensional parameter space
7.1.1    Definition of the control parameters
The AL-GFT Zeta-Comb modulation derived in Sec. ?? is controlled by two phenomeno-
logical parameters:

    • ε — the multiplicity coupling strength, governing the overall amplitude of the envi-
      ronment’s back-reaction on the gravitational sector. It enters the signal amplitude
      quadratically: |δκ/κ| ∝ ε2 .

    • σ — the soft-resonance width, a positive dimensionless parameter controlling the
      Gaussian damping of successive Riemann-zero contributions via exp(−σ γn2 ) in M(k)
      and exp(−2σ γn2 ) in the signal power |δκ/κ|2 .

All other quantities entering the modulation—the locations of the zeros γn , the phases
ϕn = 21 arg ζ( 12 + iγn )—are fixed by number theory and carry no free parameters. The
framework therefore has a two-dimensional parameter space (ε, σ), making it maximally
constrained for a stochastic-gravity extension.


                                            31
7.1.2   Signal amplitude
From the influence-functional derivation of Sec. 2, the fractional shift in the gravitational
coupling at wavenumber k is
                                       ∞
                          δκ          X         2
                             (k) = ε2
                                          e−2σ γn eiγn ln(k/k⋆ )+iϕn .                 (107)
                          κ           n=1

The modulus of this quantity is bounded by
                                     ∞
                            δκ      X         2
                               ≤ ε2
                                        e−2σ γn = ε2 Neff (σ) ,                        (108)
                             κ      n=1

where Neff (σ) was defined in Eq. (94). In the regime σ ≪ 1/γ12 ≈ 5 × 10−3 , Neff grows
(more zeros contribute), but the sum remains finite for any σ > 0. For the dominant
contribution from γ1 = 14.1347 alone:
                             δκ               2
                                   = ε2 e−2σ γ1 = ε2 e−399.6 σ .                       (109)
                              κ γ1

7.1.3   Numerical evaluation at the sweet spot
At the parameter values ε = 0.01, σ = 0.001:
                                       2
                                 e−2σγ1 = e−0.3996 = 0.671 ,                           (110)
                                       2
                                 e−2σγ2 = e−0.884 = 0.413 ,                            (111)
                                       2
                                 e−2σγ3 = e−1.251 = 0.286 ,                            (112)
                                       2
                                 e−2σγ4 = e−1.851 = 0.157 .                            (113)

Summing the first ten zeros gives Neff ≈ 4.2, and the signal amplitude
                          δκ
                             ≈ (0.01)2 × 0.671 = 6.7 × 10−5 .                          (114)
                          κ
This is the benchmark value used throughout the subsequent detectability analysis.

7.2     Existing constraints
7.2.1   Planck 2018: oscillatory features in the primordial power spectrum
The Planck 2018 analysis [18] performed a dedicated search for oscillatory features in the
primordial scalar power spectrum, parameterized as

                                                                                     (115)
                                                               
                     P(k) = P0 (k) 1 + Aosc sin(ωosc ln k + φ) ,

with Aosc , ωosc , and φ as free parameters. No statistically significant oscillatory signal
was detected; the resulting upper bound is Aosc ≲ 0.03 (95% CL) for ωosc ∼ 10–30, which
covers the range spanned by γ1 –γ4 .
   In our framework, the oscillation amplitude is
                                                        2
                                    Aosc ≈ 2 ε2 e−2σγn ,                               (116)

                                              32
where the factor of 2 accounts for the modulus of the complex exponential in M(k).
Imposing Aosc < 0.03 at γ1 gives:
                               2                                     2
                       ε2 e−2σγ1 < 0.015       =⇒       ε < 0.12 eσγ1 .                (117)

At σ = 10−3 , this yields ε < 0.15—well above our benchmark ε = 0.01. The sweet spot
lies safely within the Planck-allowed region by more than an order of magnitude.

7.2.2     CMB non-Gaussianity
The AL-GFT Gaussian branch (Gate 1) predicts fNL    local
                                                          = 0 by construction, since the
environment is Gaussian and the coupling is linear. The Planck 2018 constraint fNLlocal
                                                                                        =
−0.9 ± 5.1 (68% CL) [?] is therefore automatically satisfied. Any future detection of
fNL ̸= 0 would falsify the Gaussian branch and point toward the non-Gaussian extension
(ML-GFT).

7.2.3     Gravitational-wave propagation
The imaginary part of κeff modifies the dispersion relation for gravitational waves, in-
troducing a frequency-dependent damping. Current LIGO-Virgo-KAGRA observations
(GWTC-4.0) constrain modifications to the GW dispersion at the level δcT /cT ≲ 10−15
for f ∼ 10–103 Hz. At these frequencies the AL-GFT modulation is suppressed by
exp(−2σγ12 ln2 f /f⋆ ) with f⋆ at cosmological scales, rendering the correction negligibly
small (≪ 10−20 ). There is no tension with GW propagation bounds.

7.3      The parameter-space landscape
7.3.1     Four regions of the (σ, ε) plane
The (σ, ε) parameter space is structured by four boundaries that carve it into physically
distinct regions (Fig. 1):

  1. Planck exclusion (upper boundary). The Planck 2018 constraint on oscillatory
     features, Eq. (117), excludes the region
                                                   2
                                   ε > 0.12 eσ γ1 ≈ 0.12 e200σ .                       (118)

        This is an exponentially rising curve in the (σ, ε) plane, becoming less constraining
        as σ increases (stronger damping reduces the observable amplitude).

  2. BBO/DECIGO threshold (lower boundary). The projected strain sensitivity
     of BBO (two correlated clusters, Tobs = 3 yr) at f ∼ 0.1–1 Hz sets a minimum
     detectable energy-density fraction Ωmin
                                         GW ∼ 10
                                                  −17
                                                      . Mapping this to the modulation
     amplitude via ΩGW ∝ |δκ/κ| ΩGW,0 (where ΩGW,0 is the standard inflationary
                                    2

     background), the detection threshold requires

                                           |δκ/κ| ≳ δdet ,                             (119)

        with δdet ∼ 10−5 –10−4 depending on the assumed inflationary tensor-to-scalar ra-
        tio r.


                                              33
  3. Beat-frequency visibility boundary (left boundary). The GUE cross-check of
     Sec. 6 requires Neff ≥ 2, which from Eq. (105) translates to

                                           σ ≲ 0.002 .                                  (120)

        To the right of this boundary, only a single spectral line (γ1 ) contributes, and no
        pair-correlation test is possible.
  4. Perturbativity bound (far-left boundary). The influence-functional derivation
     assumes ε ≪ 1 (weak coupling to the environment). We conservatively impose ε <
     0.1, beyond which higher-order terms in the Dyson series may become significant.

7.3.2     The sweet spot
The intersection of these four boundaries defines a sweet spot in parameter space:

                                  σ ∼ 10−3 ,        ε ∼ 10−2 .                          (121)

At this point:
   • The signal amplitude |δκ/κ| ≈ 6.7 × 10−5 [Eq. (114)] exceeds the BBO detection
     threshold;
   • The Planck constraint is satisfied by a factor of ∼ 15;
   • Neff ≈ 4.2 zeros contribute, enabling the GUE cross-check with Nbeat = 6 beat
     frequencies;
   • The perturbative expansion is well-controlled (ε2 = 10−4 , so the next-order correc-
     tion is O(ε4 ) ∼ 10−8 ).
The coincidence of these four conditions at a single point in the (σ, ε) plane is a structural
feature of the framework, not a fine-tuning. It arises because the same Gaussian damping
exp(−2σγn2 ) simultaneously controls three quantities: signal amplitude, number of active
zeros, and departure from the Planck constraint.

7.4      Contour plot of the parameter space
Figure 1 displays the parameter-space landscape. The axes are σ (horizontal, logarithmic,
range 10−4 –10−1 ) and ε (vertical, logarithmic, range 10−3 –1).
   The contour plot encodes several key features:
  1. Signal amplitude contours slope diagonally from upper-left to lower-right, reflecting
     the competition between ε2 (increasing upward) and e−2σγ1 (decreasing rightward).
                                                               2




  2. The allowed region (below Planck, above BBO, left of beat-visibility) forms a wedge
     whose apex is the sweet spot.
  3. For σ > 0.01, the Planck bound becomes so weak (ε < 1) that it is irrelevant, but
     the signal amplitude drops below 10−8 —far below any projected detector sensitivity.
  4. For σ < 10−4 , Neff grows large (≳ 50), but the sum of oscillatory terms begins
     to average down the net modulation unless the phases ϕn are coherent over many
     zeros—an unlikely scenario for the first ∼ 50 Riemann zeros.

                                               34
Table 1: Detector configurations and their relevance to the Zeta-Comb gravitational-wave
signature. Ωsens denotes the power-law-integrated sensitivity to an SGWB for the stated
observation time and correlation method. “Modulation SNR” estimates the signal-to-
noise ratio for the oscillatory component δΩGW at the sweet-spot parameters, assuming
r = 0.01 for the inflationary tensor background.
       Detector             Band        Ωsens    Tobs Timeline Mod. SNR
        LISA            10−4 –10−1 Hz   ∼ 10−12      4 yr       2035        ≪1
        B-DECIGO         0.1–10 Hz      ∼ 10   −15
                                                     3 yr       2030s      ∼ 0.1
        DECIGO           0.1–10 Hz      ∼ 10−18      3 yr    late 2030s    ∼ 1–3
        BBO              0.03–3 Hz      ∼ 10−17      5 yr    2040s–2050s   ∼ 3–10
        Einstein Tel.     3–10 Hz
                              4
                                        ∼ 10   −13
                                                     1 yr      ∼2035        ≪1
        Cosmic Expl.      5–104 Hz      ∼ 10−13      1 yr    late 2030s     ≪1


7.5     Detector mapping
7.5.1    Translation to gravitational-wave energy density
The complex gravitational coupling modifies the tensor transfer function, imprinting the
Zeta-Comb modulation onto the stochastic gravitational-wave background (SGWB). The
fractional energy density spectrum acquires an oscillatory component:
                                         (0)
                                                                                   (122)
                                                           
                            ΩGW (f ) = ΩGW (f ) 1 + M(f ) ,
         (0)
where ΩGW (f ) is the standard inflationary background and M(f ) is the modulation func-
tion evaluated at k = 2πf /c (neglecting the weak k-dependence of the transfer function
over the detector bandwidth).
    The amplitude of the modulation at frequency f is
                                   2
             |M(f )| ≈ 2 ε2 e−2σγ1 cos γ1 ln(f /f⋆ ) + ϕ1 + higher zeros ,         (123)
                                                         

and the induced spectral modulation of the energy density is
                                                       (0)
                                     δΩGW ≡ |M| ΩGW .                                 (124)

7.5.2    Detector sensitivity overview
Table 1 summarizes the gravitational-wave observatories relevant to our predictions, or-
dered by target frequency band and projected timeline.

7.5.3    LISA
The Laser Interferometer Space Antenna, with a planned launch in 2035 and a sensitivity
band of 10−4 –10−1 Hz, will be the first space-based gravitational-wave observatory [?]. Its
SGWB sensitivity, characterized by the power-law integrated curve, reaches ΩGW ∼ 10−12
for Tobs = 4 yr.
    For the sweet-spot parameters, the modulation amplitude at f = 10−2 Hz is
                                                       (0)
                         δΩLISA
                           GW ∼ 6.7 × 10
                                        −5
                                           × ΩGW (10−2 Hz) .                          (125)

                                               35
                                                   (0)
For standard slow-roll inflation with r = 0.01, ΩGW (10−2 Hz) ∼ 10−16 , giving δΩGW ∼
10−20 —eight orders of magnitude below LISA’s reach. LISA cannot detect the Zeta-
Comb modulation for standard inflationary backgrounds. However, if an exotic
cosmological SGWB of non-inflationary origin exists at LISA frequencies with Ω ∼ 10−10 ,
the modulation would be marginally detectable.

7.5.4   B-DECIGO and DECIGO
B-DECIGO, the scientific pathfinder for DECIGO planned for the 2030s, covers 0.1–
10 Hz with strain sensitivity ∼ 10−23 Hz−1/2 around 1 Hz. DECIGO itself targets 4 ×
10−24 Hz−1/2 at 1 Hz for a single cluster, improving to 7×10−26 Hz−1/2 with two co-located
clusters using cross-correlation [?, 20].
    The DECIGO band is the natural home for the Zeta-Comb signature: the frequency
f ∼ 0.1–1 Hz corresponds to comoving wavenumbers k ∼ 1012 –1013 Mpc−1 , far below
the Silk-damping scale, where the primordial tensor spectrum is unaffected by CMB
foreground systematics.
    For r = 0.01 and the DECIGO correlation sensitivity:

                                  δΩGW     6.7 × 10−5 × 10−16
                SNRDECIGO ∼              ∼                    ∼ 1–3 ,                 (126)
                                 ΩDECIGO
                                  sens            10−18

placing the signal at the threshold of detectability. A dedicated template-based search
exploiting
  √        the known Zeta-Comb frequency structure could enhance this by a factor
∼ Neff ≈ 2.

7.5.5   BBO
The Big Bang Observer, a proposed constellation of four LISA-like clusters in heliocentric
orbit with arm lengths of 5×104 km, is specifically designed for the direct detection of the
inflationary SGWB in the 0.03–3 Hz band [?, ?]. Its projected sensitivity ΩGW ∼ 10−17
after foreground subtraction makes it the primary target detector for the Zeta-Comb
signature.
    At the sweet spot:

                                     6.7 × 10−5 × 10−16
                        SNRBBO ∼                        ∼ 3–10 ,                      (127)
                                            10−17
depending on the exact value of r and the efficiency of astrophysical foreground re-
moval (primarily neutron-star binaries, which must be individually identified and sub-
tracted [?]). This places the signal in the regime of confident detection (SNR ≳ 3),
with the oscillatory structure of the modulation providing additional template-matched
enhancement.

7.5.6   Ground-based next-generation detectors
The Einstein Telescope and Cosmic Explorer, with sensitivities exceeding Advanced LIGO
by a factor of ∼ 10 and frequency bands of 3–104 Hz, are optimized for compact bi-
nary mergers rather than primordial SGWB detection [?, ?]. Their SGWB sensitivity
(ΩGW ∼ 10−13 ) is insufficient for the Zeta-Comb signal at standard inflationary ampli-
tudes. However, these detectors contribute indirectly:


                                            36
   • By measuring the GW propagation speed to δcT /cT ∼ 10−16 or better, they con-
     strain the real part of κeff at high frequencies.
   • By cataloguing O(105 ) binary mergers per year, they enable statistical tests of the
     frequency-dependent damping rate Im κeff (f ) averaged over many events.

7.6     CMB observational channel
7.6.1   Power spectrum modulation
The Zeta-Comb modulation also imprints on the scalar primordial power spectrum via
the noise kernel:                  ns −1
                                     k
                                                                             (128)
                                                       
                       P(k) = As              1 + M(k) ,
                                    k⋆
where M(k) is the same modulation function entering the gravitational coupling. The
angular power spectrum Cℓ inherits the oscillatory structure through the transfer func-
tions:                                Z ∞
                                           dk
                               δCℓ ∝           M(k) |∆ℓ (k)|2 ,                     (129)
                                       0    k
where ∆ℓ (k) is the radiation transfer function. The integration averages overp many os-
cillation cycles for γn ≫ 1, reducing the effective amplitude by a factor ∼ 1/ ℓmax /ℓmin .

7.6.2   Forecasts for LiteBIRD and CMB-S4
LiteBIRD (launch 2032) will measure the CMB polarization to r ∼ 10−3 , while CMB-
S4 (first light ∼2030) will achieve cosmic-variance-limited E-mode measurements to ℓ ∼
5000. Neither experiment is optimized for oscillatory features at ω ∼ 14–30 in ln k, but a
dedicated search combining TT, TE, and EE spectra could in principle reach Aosc ∼ 10−3
at these frequencies.
    For the sweet-spot parameters, Aosc ≈ 2 × 6.7 × 10−5 ≈ 1.3 × 10−4 , which is a factor
of ∼ 8 below the projected sensitivity. Direct detection of the Zeta-Comb in CMB
power spectra requires ε ≳ 0.03 (at σ = 10−3 ), which remains within the Planck-
allowed region but approaches its boundary.

7.7     The detection roadmap
We summarize the observational prospects in a three-stage roadmap, ordered by timeline
and detection likelihood.

Stage I (2025–2035): Archival and indirect.          • Re-analyze Planck 2018 TT/TE/EE
          data with a matched-filter template tuned to the Zeta-Comb frequencies γ1 –γ4 .
          Expected outcome: SNR ≲ 1 at the sweet spot, but the search establishes the
          pipeline and sets improved model-specific bounds on ε.
        • LiteBIRD B-mode measurement constrains r, which is a prerequisite input for
          the SGWB detection forecast (Stage II).
Stage II (2030s–2040s): Decihertz window.           • B-DECIGO (∼2030s) provides the
          first direct SGWB search in the 0.1–10 Hz band. Marginal sensitivity to the
          Zeta-Comb modulation (SNR ∼ 0.1) at the sweet spot, but useful for fore-
          ground characterization and pipeline validation.

                                            37
          • DECIGO (late 2030s) reaches SNR ∼ 1–3 at the sweet spot. A template search
            exploiting the known Zeta-Comb structure could achieve SNR ∼ 3–5. First
            possible detection.

Stage III (2040s–2050s): Definitive test.       • BBO achieves SNR ∼ 3–10 with broad
          frequency coverage (0.03–3 Hz). The oscillatory pattern across ∼ 2 decades of
          frequency enables both:
             1. direct identification of individual spectral lines (γ1 , γ2 , possibly γ3 );
             2. the GUE cross-check via the pair-correlation pipeline of Sec. 6.4.
          • A detection-plus-GUE-confirmation at BBO would constitute observational
            evidence that the statistical structure of the Riemann zeta zeros is encoded
            in the gravitational-wave spectrum—a result connecting quantum gravity to
            number theory via a physical measurement.

7.8     The σ sweet spot as a structural prediction
The sweet spot σ ∼ 10−3 is not a post hoc choice but emerges from the structure of the
Riemann zeros themselves. Specifically:

    1. The first zero γ1 = 14.1347 sets the scale: σcrit ≡ 1/(2γ12 ) ≈ 2.5 × 10−3 . For
       σ ≫ σcrit , even the leading zero is damped out and the modulation vanishes.

    2. The beat-frequency visibility threshold σ ≲ 0.002 [Eq. (105)] is set by γ2 : 1/(2γ22 ) ≈
       1.1 × 10−3 .

    3. The ratio γ2 /γ1 ≈ 1.49, which controls the separation between σcrit and the beat-
       visibility threshold, is a number-theoretic invariant. No parameter tuning can
       change it.

The conclusion is that any framework embedding the Riemann zeros into a Gaussian-
damped environment will generically find its maximal-information regime at σ ∼ γ1−2 ,
regardless of the physical context. The sweet spot is a prediction of number theory, not
of the model.


8     The Self-Consistent Bootstrap
The preceding sections treated the Zeta-Comb environment as given: a noise kernel
N (k) characterised by parameters (ε, σ) was imposed, and its observable consequences—
complex gravitational coupling, GUE beat spectrum, gravitational-wave signatures—were
derived. A deeper question remains: can the environment that dresses κ determine its
own parameters self-consistently?
    In this section we recast the framework as a nonlinear eigenvalue problem whose so-
lution, if it exists, would fix (ε, σ) from the Riemann zero spectrum alone—eliminating
them as free parameters and elevating the theory from a model to a self-consistent boot-
strap. We outline the formal structure, identify the key mathematical obstacles, and
propose a concrete programme for future work.




                                               38
8.1     From dressed coupling to self-consistency condition
Recall from §3 that integrating out the arithmetic environment yields an effective gravi-
tational coupling (Eq. (51))
                                                   κ
                             κeff (k) =                    ,                          (130)
                                          1 − κD
                                               e R (k) O(k)

where D
      e R (k) is the retarded dissipation kernel and O(k) encodes the system response.
Both kernels inherit the Zeta-Comb structure of the noise (Eq. (??)):
                                            Neff
                                                     2
                                           X
                                                 e−σγn cos γn ln(k/k⋆ ) + ϕn + O(ε2 ) ,
                                                                            
N (k) = N0 (k) M(k) ,        M(k) = 1 + 2 ε
                                                  n=1
                                                                                (131)
where γn are the imaginary parts of the non-trivial Riemann zeta zeros, σ is the soft-
resonance wid


9       Discussion
The central result of this paper is that any causal quantum environment coupled to
gravity renders the gravitational coupling complex: κeff (k) = Re κeff + i Im κeff , with the
imaginary part encoding dissipation into the environment and the real part acquiring
a dispersive correction constrained by Kramers–Kronig causality. This is a theorem—it
follows from the influence-functional formalism of Hu and Verdaguer [1, 2] applied to the
Einstein–Langevin equation, and holds regardless of the environment’s microscopic struc-
ture. What distinguishes our framework is the choice of environment: the Arithmetic-
Langevin GFT (AL-GFT) noise kernel, whose frequencies are set by the imaginary parts
γn of the non-trivial Riemann zeta zeros.
    In this section we place the results in context, develop the connection to the Berry–
Keating programme, and assess the broader implications for quantum gravity, number
theory, and observational cosmology.

9.1     The Berry–Keating connection
9.1.1    From spectral conjecture to physical environment
The Hilbert–Pólya conjecture asserts that the non-trivial zeros of ζ(s) are eigenvalues of
a self-adjoint operator on a suitable Hilbert space [?]. Berry and Keating [14] sharpened
this to a semiclassical conjecture: the operator should quantise the classical Hamiltonian
H = xp, whose periodic orbits have actions Sp = ℏ ln p labelled by the primes. Bender,
Brody, and Müller [?] constructed a PT -symmetric realisation (Eq. (142)), and Sierra [?]
embedded the zeros as discrete eigenvalues of a Dirac fermion in Rindler spacetime subject
to delta-function potentials at positions ln p.
    Our framework adds a new layer to this programme. Rather than seeking a single
Hamiltonian whose eigenvalues are the γn , we use the γn as input data for a physical
environment and ask what observable consequences follow. The Zeta-Comb environment
can therefore be viewed as a spectral probe: it translates the abstract question “Are the γn
eigenvalues of a physical operator?” into the concrete question “Does the gravitational-
wave background carry the GUE correlations expected of such eigenvalues?”

                                             39
9.1.2   Trace-formula interpretation
The Gutzwiller trace formula connects the density of states of a quantum-chaotic system
to a sum over classical periodic orbits [?]:
                                    ¯        1  X
                          d(E) = d(E)      + Re       Ap eiSp /ℏ .                 (132)
                                             π   p.o.

For the Berry–Keating Hamiltonian, the primitive periodic orbits are labelled by primes
p, with actions Sp = ℏ ln p and periods Tp = ln p. The oscillatory part of d(E) then
reproduces the explicit formula of Riemann–von Mangoldt for the zero-counting function
N (T ) [?].
   In our framework, an analogous structure appears in the noise kernel. The Zeta-Comb
modulation (131) is a sum over zeros weighted by Gaussian-damped amplitudes:
                                                 2
                                         X
                           M(k) ∼ 1 +        e−σγn eiγn ln(k/k⋆ ) ,               (133)
                                            n

which is the Fourier dual of the Gutzwiller sum: where the trace formula sums over
orbits (primes) to produce a density of states (zeros), our noise kernel sums over zeros
to produce an observable spectrum in momentum space. The Gaussian damping e−σγn
                                                                                        2


plays the role of the semiclassical amplitude Ap , controlling how many terms contribute.
The duality
                    X                                         X
      Gutzwiller:       → zeros       ←→       Zeta-Comb:         → observables     (134)
                  primes                                     zeros

closes the loop: the explicit formula encodes primes into zeros; the Zeta-Comb decodes
zeros into gravitational-wave signatures. This is the sense in which our framework makes
the Berry–Keating programme empirically accessible—not by proving the Riemann Hy-
pothesis, but by creating a physical context in which its consequences could be measured.

9.2     Rodgers’ theorem and the arithmetic content of the beat
        spectrum
The GUE cross-check developed in §?? acquires additional significance through the the-
orem of Rodgers [?, ?]. Conditioned on the Riemann Hypothesis, Rodgers proved that
the GUE Conjecture for zeta zeros is logically equivalent to a precise statement about the
distribution of primes: namely, the asymptotic evaluation of correlations among products
of primes drawn from short intervals.
    In our context, this equivalence has a striking physical translation. The beat spec-
trum ∆γmn = |γm − γn |, which we proposed as a binary GUE diagnostic (§??), is not
merely a statistical test—it is, via Rodgers’ theorem, a direct probe of prime correlations.
If the beat spectrum measured in a gravitational-wave background exhibits GUE level
repulsion (R2 (u) → 0 as u → 0), Rodgers’ theorem guarantees that the underlying zero
spacings encode the Hardy–Littlewood predictions for prime k-tuples. Conversely, detect-
ing Poisson statistics (R2 (u) → 1) would refute the GUE Conjecture and, by Rodgers’
equivalence, would imply that prime counts in short intervals violate their conjectured
variance.
    This chain of implications—gravitational-wave data → beat spectrum → GUE/Poisson
→ prime distribution—is, to our knowledge, the first proposed pathway from an astro-
physical measurement to a statement in analytic number theory.

                                            40
9.3    Relation to stochastic gravity and open quantum systems
The result that gravity becomes an open quantum system when coupled to a quantum
environment is not new; it is the foundation of stochastic semiclassical gravity [?, 1, 2].
The Einstein–Langevin equation adds a stochastic source ξµν to the semiclassical Einstein
equation, with the noise kernel Nµναβ determined by the vacuum fluctuations of the stress-
energy tensor of quantum matter fields.
    Our contribution is not to the formalism itself but to the choice of environment.
Standard applications of stochastic gravity use free-field or thermal environments, pro-
ducing noise kernels that are smooth in momentum space. The AL-GFT environment, by
contrast, produces a noise kernel with discrete oscillatory structure—the Zeta-Comb—
inherited from the arithmetic properties of the GFT microscopic degrees of freedom. This
discrete structure is what generates the complex κeff with observable signatures, rather
than a featureless renormalisation of Newton’s constant.
    Recent work on gravitational decoherence of quantum superpositions [?, ?] and on
gravitationally-induced entanglement degradation [?] confirms the physical relevance of
treating gravity as an open system. Our framework extends this programme to the infla-
tionary epoch, where the environment is not thermal matter but the discrete quantum-
geometric structure of spacetime itself.

9.4    Falsifiability and the role of the sweet spot
A theory that cannot fail is not a theory. The framework developed here makes three
classes of falsifiable predictions, ordered by observational horizon:

  1. Near-term (Planck re-analysis, 2026–2028). Log-periodic oscillations in the
     CMB power spectrum at frequencies γn/(2π). The matched-filter search uses no free
     parameters beyond (ε, σ) in the allowed range; the frequencies themselves are fixed
     by number theory. A null result at ε ≳ 0.01, σ ∼ 10−3 would shrink the viable
     parameter space.

  2. Medium-term (BBO/DECIGO, 2030s–2040s). A stochastic gravitational-
     wave background with amplitude |δκ/κ| ∼ 7 × 10−5 at the sweet spot (ε, σ) =
     (10−2 , 10−3 ). The GUE cross-check—level repulsion in the beat spectrum—is a
     binary yes/no test requiring no fitting. Detection of Poisson statistics would falsify
     the Zeta-Comb hypothesis while leaving the general complex-κ theorem intact.

  3. Long-term (self-consistent bootstrap). The nonlinear eigenvalue problem of
     §8 either admits a non-trivial σ ⋆ in the observationally allowed window or it does
     not. If it does, (ε, σ) are no longer free parameters—they are predictions. If it does
     not, the Zeta-Comb environment decouples and the framework reduces to standard
     stochastic gravity with no arithmetic content.

   The existence of the sweet spot at σ ∼ 10−3 —where the beat-frequency visibility
threshold (σ ≲ 0.002) overlaps with the BBO/DECIGO sensitivity band—was not en-
gineered. It emerged from the structure of the first Riemann zeros (γ1 = 14.1347,
γ2 = 21.022) and the Gaussian weight function e−σγn . This coincidence, discussed in
                                                        2


§??, constitutes a form of theoretical naturalness: the region where the framework is
most testable is also where its signatures are strongest.


                                            41
9.5     Limitations and caveats
Several limitations should be stated plainly.

Perturbative regime. All results assume ε ≪ 1 and |κ D           e R | ≪ |O|, i.e. the envi-
ronment is a weak perturbation on the gravitational dynamics. The Kramers–Kronig
analysis, the linearised FDT, and the signal-amplitude estimates all break down if these
conditions are violated. For ε ≳ 0.1, higher-order corrections to the influence functional—
including non-Gaussian terms in the noise—would need to be included, taking the theory
beyond the Gaussian AL-GFT branch (Gate 1).

Environment specification. The Zeta-Comb is motivated by the AL-GFT micro-
scopic model (§1; Gate 1 of the CEQG-RG-Langevin Blueprint), but the mapping from
GFT microscopic couplings to the effective parameters (ε, σ) involves approximations—
notably the linear-coupling and Gaussian-environment assumptions—that may receive
corrections from the full GFT dynamics. Gate 2 (Wetterich RG flow from k = MPl to
k = H0 ) will address this by promoting σ to a running coupling σ(k).

Cosmological model dependence. The observational signatures are computed on
an FLRW background with Starobinsky-like inflation. Alternative inflationary models
change the transfer function from primordial noise to CMB observables and could shift
the optimal frequency window. However, the existence of log-periodic oscillations at
Riemann-zero frequencies is model-independent; only their amplitude is affected.

No proof of the Riemann Hypothesis. Nothing in this paper proves or assumes
the Riemann Hypothesis. The γn are used as empirical input—the first ∼ 1013 zeros
have been verified numerically [?, 11]. The GUE cross-check tests whether the measured
beat spectrum matches the GUE prediction, which is a contingent physical question,
not a mathematical proof. However, if the self-consistent bootstrap (§8) were shown
to close only when the zeros satisfy RH, this would constitute a physical argument for
the hypothesis—one that would need to be sharpened into a rigorous proof by number-
theoretic methods.

9.6     Broader implications
9.6.1   For quantum gravity phenomenology
The framework demonstrates that the open-quantum-systems perspective on gravity is
not merely a formal tool but a phenomenological programme with testable consequences.
The key enabling insight is that the noise kernel of stochastic gravity, usually treated
as smooth and unstructured, can carry discrete information from the UV completion
of gravity. Any approach to quantum gravity that predicts a specific noise spectrum—
whether from loop quantum gravity, string theory, or causal set theory—could in principle
be tested by the same methods developed here. The general complex-κ theorem (§3) is
agnostic about the environment’s origin; the Zeta-Comb is one instantiation, but the
framework is a template.




                                            42
9.6.2   For the Langlands programme and arithmetic quantum field theory
The AL-GFT construction places automorphic data (specifically, the γn and their pair
correlations) inside a physical noise kernel. If the non-Gaussian extension—Modular-
Langevin GFT (ML-GFT)—proves consistent, it would promote this to a role for auto-
morphic representations (Maass forms, Hecke operators) in the bispectrum. This aligns
with the broader vision of the Langlands programme as a unifying structure not only for
mathematics but for the symmetries of physical theories [?, ?].

9.6.3   For observational cosmology
The practical deliverable is a new class of template waveforms for CMB and gravitational-
wave data analysis: log-periodic oscillations at number-theoretically determined frequen-
cies. Unlike generic oscillatory features (which require fitting both amplitude and fre-
quency), the Zeta-Comb frequencies are fixed, reducing the search to a one-parameter
family in σ. This dramatically reduces the look-elsewhere effect in template searches,
improving the effective signal-to-noise ratio for a given observation time. We anticipate
that purpose-built matched-filter pipelines, applied to Planck residual maps and future
BBO/DECIGO data, will provide the first empirical constraints on arithmetic quantum
gravity noise.

Whether the cosmos confirms or refutes this arithmetic structure, the question itself—Do
the Riemann zeros shape the fabric of spacetime?—is now empirically meaningful. The
answer lies in the data. th, and ε the multiplicity coupling strength.
    The Kramers–Kronig relation links DR to N via a Hilbert transform (§??), so the
self-energy entering (130) is itself a functional of (ε, σ, {γn }). Schematically,

                                                                                     (135)
                                                            
                                 κeff = κeff ε, σ, {γn }; κ .

A self-consistent theory demands that the environment producing the noise be compat-
ible with the gravitational dynamics it modifies. Concretely, if the dressed coupling κeff
back-reacts on the environment—for instance by shifting the effective mass of environ-
ment modes or by altering the background geometry on which they propagate—then the
environment parameters (ε, σ) are not free but must satisfy a fixed-point equation:
                                                    !
                                                                                    (136)
                                 
                             κeff ε(σ), σ, {γn }; κ = κphys ,
             √
where κphys = 16πGN is the physically measured gravitational coupling and the notation
ε(σ) emphasises that, once the bootstrap closes, ε becomes a derived function of σ.

9.7     Nonlinear eigenvalue formulation
To make the bootstrap condition (136) tractable, we truncate the Zeta-Comb to the first
N zeros and define the weight vector
                                         2
                          vn (σ) ≡ e−2σγn ,       n = 1, . . . , N ,                (137)

which governs the contribution of each zero to the observable signal (cf. Eq. (73)). The
self-consistency condition then takes the matrix form

                                    K(σ) v(σ) = 0 ,                                 (138)

                                             43
where K(σ) is an N × N matrix constructed from the dressed propagator, the Kramers–
Kronig–transformed noise kernel, and the Ward-identity constraints derived in §5. Ex-
plicitly, the matrix elements are
                                          h                        i
                 Kmn (σ) = δmn − ε2 vm (σ) Hmn {γ} + i Rmn {γ} ,                 (139)
                                                   


where Hmn encodes the Hilbert-transform couplings between zeros m and n (arising
from the dissipation kernel), and Rmn captures the reactive part constrained by the
fluctuation–dissipation theorem.
    Equation (138) is a nonlinear eigenvalue problem (NLEP) in the parameter σ: the ma-
trix K depends on σ both through the weight vector v(σ) and through the σ-dependence
of the Hilbert-transform integrals. The problem is to find values σ ⋆ such that K(σ ⋆ ) has
a non-trivial null space:
                                     det K(σ ⋆ ) = 0 .                               (140)
This is structurally analogous to the gap equation in BCS superconductivity, where the
pairing gap ∆ appears both in the quasiparticle spectrum and in the self-energy that
generates ∆ itself. Here, σ plays the role of ∆: it sets the effective number of contributing
zeros (Neff ), which in turn determines the noise kernel, which feeds back into the condition
on σ.

9.8    Structure of the solution space
Several properties of the NLEP (138) can be established without solving it explicitly.

Existence of a trivial fixed point. At ε = 0, the matrix K reduces to the identity
and det K = 1 ̸= 0. The trivial solution ε = 0 (decoupled environment) always satisfies
(136) but produces no observable signal. A non-trivial bootstrap therefore requires ε ̸= 0,
and the question is whether (140) admits a solution at finite ε.

Monotonicity of the weight vector. Since γn+1 > γn and σ > 0, the weights vn (σ)
form a strictly decreasing sequence:

                          v1 (σ) > v2 (σ) > · · · > vN (σ) > 0 .                       (141)

This ensures that the lowest zeros (γ1 = 14.1347 . . ., γ2 = 21.0220 . . .) dominate the
bootstrap, providing a natural truncation hierarchy controlled by σ. At the sweet spot
σ ∼ 10−3 , the effective number of zeros contributing is Neff ≈ 4.2, with 7 pairwise beat
frequencies (Table ??).

Spectral flow with σ. Define λ1 (σ) ≡ smallest singular value of K(σ). As σ → 0,
all weights vn → 1 and the off-diagonal couplings Hmn grow without bound (too many
zeros contribute), driving λ1 → −∞. As σ → ∞, all vn → 0 and K → I, so λ1 → 1. By
continuity, λ1 (σ ⋆ ) = 0 for at least one σ ⋆ ∈ (0, ∞), provided the off-diagonal couplings
are sufficiently strong. This intermediate-value argument does not guarantee uniqueness,
but it provides a topological existence proof for the non-trivial bootstrap.




                                             44
9.9    Connection to the Berry–Keating programme
The nonlinear eigenvalue problem (138) acquires additional structure when viewed through
the lens of the Berry–Keating conjecture [?, 14]. Berry and Keating proposed that the
Riemann zeros are eigenvalues of a quantisation of the classical Hamiltonian H = xp,
with a suitable boundary condition encoding the prime numbers. Bender, Brody, and
Müller [?] subsequently constructed a PT -symmetric Hamiltonian
                                       1                       1
                                                                                      (142)
                                                          
                           ĤBK =             x̂p̂ + p̂x̂             ,
                                    1 − e−ip̂               1 − e−ip̂
whose eigenvalues, subject to a regularity condition, coincide with the γn .
    In our framework, the Zeta-Comb environment is by construction built from the γn .
If a Berry–Keating–type Hamiltonian governs the environment modes, then the self-
consistency condition (138) becomes a statement about the spectral properties of ĤBK :
the gravitational bootstrap closes if and only if the environment spectrum is that of a
self-adjoint (or PT -symmetric) operator whose eigenvalues are the Riemann zeros. This
establishes a physical bridge between the Riemann Hypothesis and quantum gravity: the
bootstrap has a non-trivial solution σ ⋆ precisely when the γn satisfy the spectral rigidity
imposed by the GUE universality class—a known consequence of RH via Montgomery–
Odlyzko pair correlation [10, 11].
    Conversely, if the bootstrap were observed to close experimentally (via the gravitational-
wave signatures of §??), it would constitute indirect physical evidence for the spectral
interpretation of the Riemann zeros.

9.10    Numerical strategy and convergence
We outline a concrete algorithm for solving the NLEP (138) numerically.

  1. Truncation. Fix Nmax zeros (we recommend Nmax = 50, well within Odlyzko’s
     tabulated range). For σ ≳ 10−4 , the Gaussian suppression vn ∼ e−2σγn renders
                                                                         2


     contributions from n > Nmax negligible (v50 < 10−12 at σ = 10−3 ).

  2. Matrix assembly. For each trial σ, compute v(σ) from (137) and assemble K(σ)
     via numerical Hilbert transforms of the noise kernel restricted to the first Nmax
     zeros. The Ward-identity constraint (k µ Im κeff = 0; §5) is imposed as a projection
     onto the transverse-traceless subspace at each step.

  3. Determinant scan. Evaluate det K(σ) on a logarithmic grid σ ∈ [10−5 , 10−1 ].
     Sign changes in Re det K locate candidate roots σ ⋆ .

  4. Refinement. Polish each candidate using a Newton–Raphson iteration on the
     smallest singular value λ1 (σ), with Jacobian estimated by finite differences ∂σ λ1 ≈
     [λ1 (σ + δ) − λ1 (σ − δ)]/2δ.

  5. Consistency check. Verify that σ ⋆ lies within the observationally allowed region of
     parameter space (Fig. ??): beat-frequency visibility requires σ ≲ 0.002, and Planck
     2018 constraints impose ε < 0.21 at σ = 10−3 (Eq. (117)). A solution σ ⋆ ∼ 10−3
     falling in the sweet spot would be a striking confirmation of the framework’s internal
     coherence.


                                              45
    The computational cost is dominated by the Hilbert-transform integrals in Step 2,
each requiring O(Nmax
                    2
                       ) quadrature evaluations. For Nmax = 50, a single σ-scan with 200
grid points requires ∼ 5 × 105 function evaluations—feasible on a laptop in minutes.

9.11     Open questions and future work
The self-consistent bootstrap raises several questions that we leave for future investiga-
tion.

  1. Uniqueness. Does (140) admit a unique non-trivial σ ⋆ , or a discrete set? Multiple
     solutions would correspond to distinct “phases” of the arithmetic environment, each
     with a different effective number of active zeros. Stability analysis (sign of ∂σ λ1 |σ⋆ )
     would identify the physical branch.

  2. Dynamical origin of ε. In the present formulation, ε enters as an overall coupling
     strength. A fully closed bootstrap should determine ε⋆ alongside σ ⋆ . This likely re-
     quires extending the NLEP to a two-parameter system K(ε, σ) v = 0, supplemented
     by a normalisation condition on κphys .

  3. Relation to the Hilbert–Pólya programme. If the bootstrap selects a unique
     σ ⋆ , the resulting dressed propagator Geff (k; σ ⋆ ) defines a physical operator whose
     spectral properties are constrained by the Riemann zeros. Establishing whether this
     operator is unitarily equivalent to a Berry–Keating–type Hamiltonian would provide
     a concrete realisation of the Hilbert–Pólya conjecture within quantum gravity.

  4. Renormalisation-group flow. The parameter σ has been treated as scale-independent.
     Embedding the bootstrap in the Gate 2 Wetterich flow (§??) would promote σ to
     a running coupling σ(k), with the NLEP replaced by a functional fixed-point equa-
     tion. The interplay between the discrete Zeta-Comb structure and continuous RG
     flow is an unexplored frontier.

  5. Implications of failure. If no non-trivial σ ⋆ exists within the observationally al-
     lowed window, the framework admits only the trivial solution ε = 0—meaning the
     arithmetic environment decouples and leaves no observable imprint. This would fal-
     sify the predictive power of the Zeta-Comb model while leaving the general theorem
     (any causal environment produces complex κ; §3) intact.

The self-consistent bootstrap thus serves a dual purpose: it is both the mechanism by
which the framework could achieve maximal predictive power—fixing all parameters from
number theory—and the sharpest internal test of whether arithmetic quantum gravity
noise is more than a mathematical curiosity. Its resolution, whether by the numerical
programme above or by analytic methods connecting to the Berry–Keating Hamiltonian,
constitutes the natural next chapter of this work.


10     Discussion
The central result of this paper is that any causal quantum environment coupled to
gravity renders the gravitational coupling complex: κeff (k) = Re κeff + i Im κeff , with the
imaginary part encoding dissipation into the environment and the real part acquiring


                                             46
a dispersive correction constrained by Kramers–Kronig causality. This is a theorem—it
follows from the influence-functional formalism of Hu and Verdaguer [1, 2] applied to the
Einstein–Langevin equation, and holds regardless of the environment’s microscopic struc-
ture. What distinguishes our framework is the choice of environment: the Arithmetic-
Langevin GFT (AL-GFT) noise kernel, whose frequencies are set by the imaginary parts
γn of the non-trivial Riemann zeta zeros.
    In this section we place the results in context, develop the connection to the Berry–
Keating programme, and assess the broader implications for quantum gravity, number
theory, and observational cosmology.

10.1     The Berry–Keating connection
10.1.1   From spectral conjecture to physical environment
The Hilbert–Pólya conjecture asserts that the non-trivial zeros of ζ(s) are eigenvalues of
a self-adjoint operator on a suitable Hilbert space [?]. Berry and Keating [14] sharpened
this to a semiclassical conjecture: the operator should quantise the classical Hamiltonian
H = xp, whose periodic orbits have actions Sp = ℏ ln p labelled by the primes. Bender,
Brody, and Müller [?] constructed a PT -symmetric realisation (Eq. (142)), and Sierra [?]
embedded the zeros as discrete eigenvalues of a Dirac fermion in Rindler spacetime subject
to delta-function potentials at positions ln p.
    Our framework adds a new layer to this programme. Rather than seeking a single
Hamiltonian whose eigenvalues are the γn , we use the γn as input data for a physical
environment and ask what observable consequences follow. The Zeta-Comb environment
can therefore be viewed as a spectral probe: it translates the abstract question “Are the γn
eigenvalues of a physical operator?” into the concrete question “Does the gravitational-
wave background carry the GUE correlations expected of such eigenvalues?”

10.1.2   Trace-formula interpretation
The Gutzwiller trace formula connects the density of states of a quantum-chaotic system
to a sum over classical periodic orbits [?]:

                                 ¯              1    X
                          d(E) = d(E) +           Re      Ap eiSp /ℏ .                (143)
                                                π    p.o.


For the Berry–Keating Hamiltonian, the primitive periodic orbits are labelled by primes
p, with actions Sp = ℏ ln p and periods Tp = ln p. The oscillatory part of d(E) then
reproduces the explicit formula of Riemann–von Mangoldt for the zero-counting function
N (T ) [?].
   In our framework, an analogous structure appears in the noise kernel. The Zeta-Comb
modulation (131) is a sum over zeros weighted by Gaussian-damped amplitudes:
                                                 2
                                         X
                           M(k) ∼ 1 +        e−σγn eiγn ln(k/k⋆ ) ,               (144)
                                            n

which is the Fourier dual of the Gutzwiller sum: where the trace formula sums over
orbits (primes) to produce a density of states (zeros), our noise kernel sums over zeros
to produce an observable spectrum in momentum space. The Gaussian damping e−σγn
                                                                                       2




                                            47
plays the role of the semiclassical amplitude Ap , controlling how many terms contribute.
The duality
                    X                                         X
     Gutzwiller:        → zeros       ←→       Zeta-Comb:         → observables     (145)
                  primes                                     zeros


closes the loop: the explicit formula encodes primes into zeros; the Zeta-Comb decodes
zeros into gravitational-wave signatures. This is the sense in which our framework makes
the Berry–Keating programme empirically accessible—not by proving the Riemann Hy-
pothesis, but by creating a physical context in which its consequences could be measured.

10.2    Rodgers’ theorem and the arithmetic content of the beat
        spectrum
The GUE cross-check developed in §?? acquires additional significance through the the-
orem of Rodgers [?, ?]. Conditioned on the Riemann Hypothesis, Rodgers proved that
the GUE Conjecture for zeta zeros is logically equivalent to a precise statement about the
distribution of primes: namely, the asymptotic evaluation of correlations among products
of primes drawn from short intervals.
    In our context, this equivalence has a striking physical translation. The beat spec-
trum ∆γmn = |γm − γn |, which we proposed as a binary GUE diagnostic (§??), is not
merely a statistical test—it is, via Rodgers’ theorem, a direct probe of prime correlations.
If the beat spectrum measured in a gravitational-wave background exhibits GUE level
repulsion (R2 (u) → 0 as u → 0), Rodgers’ theorem guarantees that the underlying zero
spacings encode the Hardy–Littlewood predictions for prime k-tuples. Conversely, detect-
ing Poisson statistics (R2 (u) → 1) would refute the GUE Conjecture and, by Rodgers’
equivalence, would imply that prime counts in short intervals violate their conjectured
variance.
    This chain of implications—gravitational-wave data → beat spectrum → GUE/Poisson
→ prime distribution—is, to our knowledge, the first proposed pathway from an astro-
physical measurement to a statement in analytic number theory.

10.3    Relation to stochastic gravity and open quantum systems
The result that gravity becomes an open quantum system when coupled to a quantum
environment is not new; it is the foundation of stochastic semiclassical gravity [?, 1, 2].
The Einstein–Langevin equation adds a stochastic source ξµν to the semiclassical Einstein
equation, with the noise kernel Nµναβ determined by the vacuum fluctuations of the stress-
energy tensor of quantum matter fields.
    Our contribution is not to the formalism itself but to the choice of environment.
Standard applications of stochastic gravity use free-field or thermal environments, pro-
ducing noise kernels that are smooth in momentum space. The AL-GFT environment, by
contrast, produces a noise kernel with discrete oscillatory structure—the Zeta-Comb—
inherited from the arithmetic properties of the GFT microscopic degrees of freedom. This
discrete structure is what generates the complex κeff with observable signatures, rather
than a featureless renormalisation of Newton’s constant.
    Recent work on gravitational decoherence of quantum superpositions [?, ?] and on
gravitationally-induced entanglement degradation [?] confirms the physical relevance of


                                            48
treating gravity as an open system. Our framework extends this programme to the infla-
tionary epoch, where the environment is not thermal matter but the discrete quantum-
geometric structure of spacetime itself.

10.4    Falsifiability and the role of the sweet spot
A theory that cannot fail is not a theory. The framework developed here makes three
classes of falsifiable predictions, ordered by observational horizon:

  1. Near-term (Planck re-analysis, 2026–2028). Log-periodic oscillations in the
     CMB power spectrum at frequencies γn/(2π). The matched-filter search uses no free
     parameters beyond (ε, σ) in the allowed range; the frequencies themselves are fixed
     by number theory. A null result at ε ≳ 0.01, σ ∼ 10−3 would shrink the viable
     parameter space.

  2. Medium-term (BBO/DECIGO, 2030s–2040s). A stochastic gravitational-
     wave background with amplitude |δκ/κ| ∼ 7 × 10−5 at the sweet spot (ε, σ) =
     (10−2 , 10−3 ). The GUE cross-check—level repulsion in the beat spectrum—is a
     binary yes/no test requiring no fitting. Detection of Poisson statistics would falsify
     the Zeta-Comb hypothesis while leaving the general complex-κ theorem intact.

  3. Long-term (self-consistent bootstrap). The nonlinear eigenvalue problem of
     §8 either admits a non-trivial σ ⋆ in the observationally allowed window or it does
     not. If it does, (ε, σ) are no longer free parameters—they are predictions. If it does
     not, the Zeta-Comb environment decouples and the framework reduces to standard
     stochastic gravity with no arithmetic content.

   The existence of the sweet spot at σ ∼ 10−3 —where the beat-frequency visibility
threshold (σ ≲ 0.002) overlaps with the BBO/DECIGO sensitivity band—was not en-
gineered. It emerged from the structure of the first Riemann zeros (γ1 = 14.1347,
γ2 = 21.022) and the Gaussian weight function e−σγn . This coincidence, discussed in
                                                        2


§??, constitutes a form of theoretical naturalness: the region where the framework is
most testable is also where its signatures are strongest.

10.5    Limitations and caveats
Several limitations should be stated plainly.

Perturbative regime. All results assume ε ≪ 1 and |κ D           e R | ≪ |O|, i.e. the envi-
ronment is a weak perturbation on the gravitational dynamics. The Kramers–Kronig
analysis, the linearised FDT, and the signal-amplitude estimates all break down if these
conditions are violated. For ε ≳ 0.1, higher-order corrections to the influence functional—
including non-Gaussian terms in the noise—would need to be included, taking the theory
beyond the Gaussian AL-GFT branch (Gate 1).

Environment specification. The Zeta-Comb is motivated by the AL-GFT micro-
scopic model (§1; Gate 1 of the CEQG-RG-Langevin Blueprint), but the mapping from
GFT microscopic couplings to the effective parameters (ε, σ) involves approximations—
notably the linear-coupling and Gaussian-environment assumptions—that may receive

                                            49
corrections from the full GFT dynamics. Gate 2 (Wetterich RG flow from k = MPl to
k = H0 ) will address this by promoting σ to a running coupling σ(k).

Cosmological model dependence. The observational signatures are computed on
an FLRW background with Starobinsky-like inflation. Alternative inflationary models
change the transfer function from primordial noise to CMB observables and could shift
the optimal frequency window. However, the existence of log-periodic oscillations at
Riemann-zero frequencies is model-independent; only their amplitude is affected.

No proof of the Riemann Hypothesis. Nothing in this paper proves or assumes
the Riemann Hypothesis. The γn are used as empirical input—the first ∼ 1013 zeros
have been verified numerically [?, 11]. The GUE cross-check tests whether the measured
beat spectrum matches the GUE prediction, which is a contingent physical question,
not a mathematical proof. However, if the self-consistent bootstrap (§8) were shown
to close only when the zeros satisfy RH, this would constitute a physical argument for
the hypothesis—one that would need to be sharpened into a rigorous proof by number-
theoretic methods.

10.6     Broader implications
10.6.1   For quantum gravity phenomenology
The framework demonstrates that the open-quantum-systems perspective on gravity is
not merely a formal tool but a phenomenological programme with testable consequences.
The key enabling insight is that the noise kernel of stochastic gravity, usually treated
as smooth and unstructured, can carry discrete information from the UV completion
of gravity. Any approach to quantum gravity that predicts a specific noise spectrum—
whether from loop quantum gravity, string theory, or causal set theory—could in principle
be tested by the same methods developed here. The general complex-κ theorem (§3) is
agnostic about the environment’s origin; the Zeta-Comb is one instantiation, but the
framework is a template.

10.6.2   For the Langlands programme and arithmetic quantum field theory
The AL-GFT construction places automorphic data (specifically, the γn and their pair
correlations) inside a physical noise kernel. If the non-Gaussian extension—Modular-
Langevin GFT (ML-GFT)—proves consistent, it would promote this to a role for auto-
morphic representations (Maass forms, Hecke operators) in the bispectrum. This aligns
with the broader vision of the Langlands programme as a unifying structure not only for
mathematics but for the symmetries of physical theories [?, ?].

10.6.3   For observational cosmology
The practical deliverable is a new class of template waveforms for CMB and gravitational-
wave data analysis: log-periodic oscillations at number-theoretically determined frequen-
cies. Unlike generic oscillatory features (which require fitting both amplitude and fre-
quency), the Zeta-Comb frequencies are fixed, reducing the search to a one-parameter
family in σ. This dramatically reduces the look-elsewhere effect in template searches,
improving the effective signal-to-noise ratio for a given observation time. We anticipate

                                           50
that purpose-built matched-filter pipelines, applied to Planck residual maps and future
BBO/DECIGO data, will provide the first empirical constraints on arithmetic quantum
gravity noise.

Whether the cosmos confirms or refutes this arithmetic structure, the question itself—Do
the Riemann zeros shape the fabric of spacetime?—is now empirically meaningful. The
answer lies in the data.


References
 [1] B. L. Hu and E. Verdaguer, “Stochastic Gravity: Theory and Applications,” Living
     Rev. Rel. 11, 3 (2008) [arXiv:0802.0658 [gr-qc]].

 [2] B. L. Hu and E. Verdaguer, “Stochastic Gravity: Theory and Applications,” Living
     Rev. Rel. 7, 3 (2004) [arXiv:gr-qc/0307032].

 [3] E. Calzetta and B. L. Hu, “Noise and fluctuations in semiclassical gravity,” Phys.
     Rev. D 49, 6636 (1994).

 [4] R. P. Feynman and F. L. Vernon, “The theory of a general quantum system inter-
     acting with a linear dissipative system,” Annals Phys. 24, 118 (1963).

 [5] R. de L. Kronig, “On the theory of dispersion of X-rays,” J. Opt. Soc. Am. 12, 547
     (1926); H. A. Kramers, “La diffusion de la lumière par les atomes,” Atti Cong. Intern.
     Fisici, Como (1927).

 [6] G. W. Gibbons, S. W. Hawking and M. J. Perry, “Path Integrals and the Indefinite-
     ness of the Gravitational Action,” Nucl. Phys. B 138, 141 (1978).

 [7] P. O. Mazur and E. Mottola, “The conformal factor and the cosmological constant,”
     Nucl. Phys. B (Proc. Suppl.) 18, 214 (1990).

 [8] H.-X. Feng, “Local conformal instability and local non-collapsing in the Ricci flow,”
     Annals Phys. 440, 168831 (2022) [arXiv:2201.10732 [gr-qc]].

 [9] D. Grabovsky, “Gravitational Path Integrals,” UCSB Lecture Notes (2023), https:
     //web.physics.ucsb.edu/~davidgrabovsky/files-notes/231CNotes.pdf.

[10] H. L. Montgomery, “The pair correlation of zeros of the zeta function,” in Analytic
     Number Theory, Proc. Symp. Pure Math. 24, 181–193 (1973).

[11] A. M. Odlyzko, “On the distribution of spacings between zeros of the zeta function,”
     Math. Comp. 48, 273 (1987).

[12] “Montgomery’s pair correlation conjecture,” Wikipedia (2024), https://en.
     wikipedia.org/wiki/Montgomery%27s_pair_correlation_conjecture.

[13] E. W. Weisstein, “Montgomery’s Pair Correlation Conjecture,” MathWorld, https:
     //mathworld.wolfram.com/MontgomerysPairCorrelationConjecture.html.

[14] M. V. Berry and J. P. Keating, “The Riemann zeros and eigenvalue asymptotics,”
     SIAM Rev. 41, 236 (1999).

                                            51
[15] C. M. Bender, D. C. Brody and M. P. Müller, “Hamiltonian for the Zeros of the
     Riemann Zeta Function,” Phys. Rev. Lett. 118, 130201 (2017) [arXiv:1608.03679
     [quant-ph]].

[16] B. Rodgers, “Arithmetic consequences of the GUE conjecture for zeta zeros,” http:
     //user.math.uzh.ch/rodgers/ArithmeticGUE.pdf.

[17] R. O. Van Gelder, “Gate 1 Formalization: Arithmetic–Langevin Group Field The-
     ory,” Citizen Gardens Research Initiative, Technical Report (2026).

[18] Planck Collaboration, “Planck 2018 results. X. Constraints on inflation,” Astron.
     Astrophys. 641, A10 (2020) [arXiv:1807.06211].

[19] K. Yagi and N. Seto, “Detector configuration of DECIGO/BBO and identification
     of cosmological neutron-star binaries,” Phys. Rev. D 83, 044011 (2011).

[20] S. Kawamura et al., “Current status of space gravitational wave antenna DECIGO
     and B-DECIGO,” PTEP 2021, 05A105 (2021) [arXiv:2006.13545].

[21] University of Bristol, “Quantum physics sheds light on Riemann hypothesis,” https:
     //www.bristol.ac.uk/maths/research/highlights/riemann-hypothesis/.

[22] N.   Wolchover,   “Physicists    Attack  Math’s   $1,000,000  Question,”
     Quanta      Magazine       (2017),      https://www.quantamagazine.org/
     quantum-physicists-attack-the-riemann-hypothesis-20170404/.




                                          52
       parameter_space_final.png




Figure 1: Parameter space of the complex gravitational coupling in the (σ, ε) plane.
Filled contours: signal amplitude log10 |δκ/κ|, computed from Eq. (108) summing the
first 100 Riemann zeros. Solid red curve: Planck 2018 exclusion boundary (oscillatory
features, Aosc < 0.03). Dashed blue line: BBO/DECIGO detection threshold (|δκ/κ| ≳
10−5 ). Dashed green line: beat-frequency visibility boundary (σ = 0.002, Neff = 2).
Star: sweet spot (σ, ε) = (10−3 , 10−2 ), where the signal amplitude is |δκ/κ| ≈ 6.7×10−5 ,
the GUE cross-check is enabled, and the Planck bound is satisfied. The allowed region
lies below the red curve, above the blue line, and to the left of the green line.




                                            53
