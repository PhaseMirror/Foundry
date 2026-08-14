---
slug: spin-foam-microfoundations-gate-1
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Spin_Foam_Microfoundations__Gate_1_.md
  last_synced: '2026-03-20T17:17:19.196660Z'
---

      AL-GFT Gate 1 Track A:
  Schwinger-Keldysh Derivation of the
       Zeta-Comb Noise Kernel
                     Ryan O. van Gelder
                        March 17, 2026


                             Abstract
    This article presents a gated research framework for Complet-
ing Einstein’s Quantum Gravity (CEQG) by integrating Renormal-
ization Group (RG) running, Langevin stochastic gravity, spin-foam
microfoundations, and Group Field Theory (GFT) cumulant flows.
The framework is designed for modular falsifiability, with five manda-
tory validation gates that enforce a rigorous chain from microscopic
dynamics to cosmological observables, anchored to 2024–2026 data
from DESI, Planck, and GWTC-4.0. Gate 1 is implemented via the
Arithmetic-Langevin GFT (AL-GFT) Gaussian branch, which derives
an explicitly Gaussian Zeta-Comb noise kernel producing log-periodic
oscillations in the primordial power spectrum, while predicting vanish-
ing primordial bispectrum fNL ≃ 0 at this level. Subsequent gates use
AL-GFT-derived UV data as boundary conditions for GFT Wetterich
flows, yielding RG-based priors for late-time running and correlated
predictions for power-spectrum features and large-scale-structure ob-
servables, rather than generic scale-dependent non-Gaussianity. The
resulting framework emphasizes transparent pass/fail criteria over mono-
lithic claims, providing a concrete route to testing quantum-gravity-
induced structure in cosmology with current and near-future surveys.




                                  1
1     System + Environment Definition (Fourier
      space for ζk (η) on FLRW)
1.1     System Action (Quadratic in ζ)
Following the Starobinsky-like form:
                            Z
                          1
                              dη d3 k a2 (η) |ζk′ |2 − c2s k 2 |ζk |2 .
                                                                    
               Ssys [ζ] =                                                  (1)
                          2
This defines the free evolution of the curvature perturbation ζ, matching the
conventions used in the AL-GFT primordial spectrum code.

1.2     Environment: Tower of Multiplicity Modes
We introduce a discrete tower of environment modes ϕn,k (η), labeled by an
index n that will encode the prime/zeta structure. Each mode has a simple
quadratic action:
                         Z         ∞
                       1       3
                                  X    ′ 2
                                       |ϕn,k | − Ω2n (k, η) |ϕn,k |2 .
                                                                    
            Senv [ϕ] =     dη d k                                      (2)
                       2          n=1

The dispersion Ωn (k, η) can be chosen later to incorporate GFT-inspired
physics; for the minimal Track A, we may take it to be simple (e.g., Ω2n =
ωn2 + k 2 ).

1.3     Interaction (Linear, Gaussian Track A)
The system and environment are coupled linearly. Define a collective envi-
ronment operator:
                                X∞
                       Ok (η) ≡     gn ϕn,k (η),                       (3)
                                          n=1

where the coupling constants gn will carry the arithmetic information (prime
weights, zeta phases). The interaction action is then:
                               Z
                  Sint [ζ, ϕ] = dη d3 k a2 (η) ζk (η) O−k (η).            (4)

This form ensures the total action Stot = Ssys +Senv +Sint is at most quadratic
in ϕ, making the path integral over ϕ exactly solvable (Gaussian).

                                           2
1.4    Initial Environment State
We choose a Gaussian initial density matrix for the environment, with a
spectrum weighted by the prime/zeta structure:
                                           !
                             X
               ρenv ∝ exp −     βn |ϕn,k |2 , βn ∼ ϵ wn ,           (5)
                                  n,k


where ϵ is the multiplicity coupling strength and wn encodes the arithmetic
weights (e.g., built from the von Mangoldt function or directly from the
imaginary parts ωn of Riemann zeta zeros). The specific choice of wn will be
detailed in Section 4.


2     Closed-Time-Path (CTP) Generating Func-
      tional
2.1    Field Doubling
On the closed time path, we introduce two copies of each field: ζ+ , ζ− (for
the forward and backward branches) and similarly ϕ+ , ϕ− .

2.2    Path Integral
The CTP generating functional is:
             Z
Z[J+ , J− ] = Dζ+ Dζ− Dϕ+ Dϕ−
                                                         Z         Z     
               exp iStot [ζ+ , ϕ+ ] − iStot [ζ− , ϕ− ] + i J+ ζ+ − i J− ζ− ρenv [ϕ+ , ϕ− ].
                                                                              (6)

The integral over ϕ± is Gaussian because Senv + Sint is quadratic in ϕ. Per-
forming this integral yields the influence functional.




                                        3
2.3      Influence Functional
Define the influence functional F[ζ+ , ζ− ] via:
                                Z
                iSIF [ζ+ ,ζ− ]
F[ζ+ , ζ− ] ≡ e                = Dϕ+ Dϕ− ei(Senv+int [ζ+ ,ϕ+ ]−Senv+int [ζ− ,ϕ− ]) ρenv [ϕ+ , ϕ− ].
                                                                            (7)
The influence action SIF captures the effect of the environment on the system.

2.4      Resulting Effective Theory for ζ
After integrating out the environment, the generating functional becomes:
             Z                                                    Z        Z     
Z[J+ , J− ] = Dζ+ Dζ− exp iSsys [ζ+ ]−iSsys [ζ− ]+iSIF [ζ+ , ζ− ]+i J+ ζ+ −i J− ζ− .
                                                                                              (8)


3      Standard Form of the Influence Action for
       a Linear Coupling to a Gaussian Environ-
       ment
For our setup, the influence action takes the well-known Feynman-Vernon
form. Introducing the average and difference variables:
                                    ζ+ + ζ−
                             ζc =           ,       ζ∆ = ζ+ − ζ− ,                            (9)
                                       2
the influence action is:
                Z                                                                          
                     ′ 3                   ′         ′      i                ′         ′
SIF [ζc , ζ∆ ] = dηdη d k ζ∆ (η, k)DR (η, η ; k)ζc (η , k) + ζ∆ (η, k)N (η, η ; k)ζ∆ (η , k) .
                                                            2
                                                                             (10)
Here:

    • DR (η, η ′ ; k) is the dissipation kernel (real and retarded).

    • N (η, η ′ ; k) is the **noise kernel** (real, symmetric, and positive semi-
      definite).



                                                4
3.1      Kernels in Terms of Environment Correlators
                                        P
For our collective operator Ok =          n gn ϕn,k , and given the Gaussian initial
state ρenv , the kernels are:
                                 1
                 N (η, η ′ ; k) =  ⟨{Ok (η), O−k (η ′ )}⟩ρenv ,                (11)
                                 2
               DR (η, η ′ ; k) = iθ(η − η ′ ) ⟨[Ok (η), O−k (η ′ )]⟩ρenv .     (12)

The brackets ⟨·⟩ρenv denote expectation values with respect to the initial
environment state.


4     Imprinting the Zeta-Comb: Analytic Deriva-
      tion of N (k)
4.1      Choice of Couplings gn
To encode the arithmetic structure, we follow the prescription from the AL-
GFT code and set:
                                    2
                      gn = ϵ e−γωn eiϕn ,       for n = 1, 2, . . . ,          (13)

where:
    • ωn are the imaginary parts of the first N non-trivial Riemann zeta zeros
      (e.g., ω1 = 14.1347, ω2 = 21.0220, . . . ).

    • ϕn = arg ζ(1/2 + iωn ) are the corresponding phases.

    • ϵ is the overall multiplicity coupling strength.

    • γ ∼ 1/σ 2 provides a Gaussian damping from the soft resonance width
      σ.

4.2      Noise Kernel Calculation
We need to compute the anti-commutator in Eq. (11). For simplicity in this
minimal Track A, we make two standard approximations: 1. The environ-
ment modes ϕn,k are taken as independent harmonic oscillators. 2. Their
two-point functions, in the inflationary background, lead to phase factors

                                            5
exp(±iωn log(k/k⋆ )) after a Fourier transform to momentum space. This is a
standard result for mode functions on a quasi-de Sitter background, mapping
conformal time to log k.                                                         R
      Under these approximations, the equal-time noise spectrum N (k) ≡ d(η−
             ′
η ′ ) eik(η−η ) N (η, η ′ ; k) becomes:
                X
      N (k) ∝        |gn |2 cos (ωn log(k/k⋆ ) + ϕn ) + (non-oscillatory terms). (14)
             n

The constant of proportionality is fixed by matching the standard scale-
invariant spectrum in the ϵ → 0 limit.

4.3    Final Zeta-Comb Modulation M (k)
The primordial power spectrum Pζ (k) is related to the noise kernel via the
Green function of the system. For a weakly coupled environment, the dom-
inant effect is a multiplicative modulation of the standard spectrum. The
result matches the form implemented numerically:

                             Pζ (k) = P0 (k) × M (k),                         (15)

with
                           N     2
                           X e−γωn
          M (k) = 1 + 2ϵ               cos (ωn log(k/k⋆ ) + ϕn ) + O(ϵ2 ).    (16)
                           n=1
                                 ωn2
Here P0 (k) is the standard power spectrum (e.g., from Starobinsky inflation),
and the factor 1/ωn2 arises naturally from the mode function normalization.

4.4    Check of the ϵ → 0 Limit
As ϵ → 0, all gn → 0, the environment decouples, SIF → 0, and we recover
the closed system result Pζ (k) = P0 (k). The corrections are of order ϵ2 ,
ensuring consistency with the ΛCDM limit at the required precision (e.g.,
< 10−6 level).




                                          6
5     The Gaussian Fork: Vanishing C3 for AL-
      GFT Track A
5.1    Why C3 = 0
Because the environment is Gaussian and the interaction Sint is strictly linear
in both ζ and O, the influence action SIF contains terms at most quadratic
in ζc and ζ∆ (see Eq. (10)). This implies that the equivalent stochastic
(Langevin) equation for ζ will have a Gaussian noise source ξ with:

                                  ⟨ξ⟩ = 0,                                (17)
                   ⟨ξ(η, k)ξ(η , k′ )⟩ ∝ δ(k + k′ )N (η, η ′ ; k),
                               ′
                                                                          (18)
                              ⟨ξξξ⟩c = 0.                                 (19)

Consequently, all connected correlation functions of ζ beyond the two-point
function vanish: C3 (k1 , k2 , k3 ) = 0.

5.2    Implications for Gate 1
The AL-GFT Track A derivation thus explicitly satisfies the Gate 1 require-
ment to compute C3 : it is zero by construction, given our choices of a Gaus-
sian environment and linear coupling. This is a clear, falsifiable prediction:
any detection of primordial non-Gaussianity (fNL ̸= 0) would rule out this
minimal Gaussian branch of AL-GFT and point toward the need for non-
linear couplings or a non-Gaussian initial state (Track B).


6     Mode Functions for the Environment Tower
      on Quasi-de Sitter
In this section we make explicit the mode functions for the environment fields
ϕn,k (η) on an approximately de Sitter background and show how they gener-
ate logarithmic phase dependence ∝ exp(±iωn log(k/k⋆ )) in the noise kernel.
This provides the bridge between the microscopic AL-GFT construction and
the Zeta-Comb modulation implemented numerically in algftgate1.py.




                                         7
6.1    Background and Canonical Normalization
We assume an inflationary background that is well approximated by quasi-de
Sitter expansion in conformal time η:
                                       1
                           a(η) ≃ −      ,   η < 0,                    (20)
                                      Hη
with H approximately constant over the range of scales of interest. For each
environment mode ϕn,k (η) we define the canonically normalized variable

                           vn,k (η) ≡ a(η) ϕn,k (η).                   (21)

The quadratic action (2) then leads to the standard Mukhanov–Sasaki–type
equation
                                          a′′ (η)
                                                 
               ′′          2    2     2
              vn,k (η) + k + a (η) mn −             vn,k (η) = 0,   (22)
                                           a(η)
where mn is an effective mass for the n-th environment mode, to be specified
below.
   For exact de Sitter, a′′ /a = 2/η 2 , so the mode equation becomes

                                     m2n
                                                
                   ′′           2              2
                  vn,k (η) + k + 2 2 − 2 vn,k (η) = 0.                 (23)
                                   H η        η
This has Hankel-function solutions.

6.2    Hankel Function Solutions and Index νn
Equation (23) can be written in the canonical Bessel form

                                  νn2 − 1/4
                                           
                   ′′         2
                  vn,k (η) + k −              vn,k (η) = 0,            (24)
                                      η2
with                                             r
                                 2
                      1       m                     9 m2n
               νn2 − = 2 − n2 ⇒ νn =                    −    .      (25)
                      4       H                     4 H2
The Bunch–Davies vacuum selects the positive-frequency solution at early
times (k|η| → ∞), giving
                           √
                             π i(νn +1/2)π/2 √
                vn,k (η) =    e               −η Hν(1)
                                                    n
                                                       (−kη),       (26)
                            2
                                       8
         (1)
where Hνn is a Hankel function of the first kind.
  The physical field is then
                                √
                   vn,k (η)    H π i(νn +1/2)π/2
        ϕn,k (η) =          =−      e            (−η)3/2 Hν(1)
                                                            n
                                                               (−kη).       (27)
                    a(η)        2

6.3    Asymptotics and Logarithmic Phase Structure
The Zeta-Comb modulation in the AL-GFT code is built from terms cos(ωn log(k/k⋆ ) + ϕn ),
where ωn are imaginary parts of Riemann zeta zeros and ϕn are their phases.
In the inflationary context, logarithmic dependence on k naturally arises from
the combination of Hankel-function phases and the time of horizon crossing.
    For modes evaluated near horizon crossing, we have −kη⋆ ∼ 1, so η⋆ ∼
−1/k. Substituting into (27):

                    ϕn,k (η⋆ ) ∝ H k −3/2 Hν(1)
                                             n
                                                (1) ei(νn +1/2)π/2 .        (28)

If we now choose the effective index νn to carry an imaginary part propor-
tional to the zeta zero,
                                       3   ωn
                                 νn = + i ,                             (29)
                                       2    α
for some dimensionless constant α of order unity, then the phase of ϕn,k (η⋆ )
contains a term
                                           h ω        i
                                               n
            exp [i Im(νn ) log(−η⋆ )] ∼ exp −    log k = k −ωn /α .     (30)
                                              α
Combining this with the explicit k −3/2 and any additional logarithmic run-
ning from quasi-de Sitter corrections leads to factors of the form exp (±i ωn log(k/k⋆ ))
after suitable rescalings and choice of α and k⋆ .
    In the minimal phenomenological realization used in algftgate1.py,
this structure is encoded directly into the couplings gn and the residual k-
dependence of the environment correlators. The present calculation shows
how such logarithmic phases can arise dynamically from a tower of modes
with complex νn .

6.4    Approximate Mode Functions and Effective Phase
For practical purposes in this Gate 1 Track A derivation, we do not need the
full exact Hankel function dependence. It is sufficient to adopt an effective

                                           9
parameterization in which each environment mode contributes a term
                                                    
                                               k
               ϕn,k (η) ∼ An (k) exp i ωn log     + iφn ,          (31)
                                               k⋆

where An (k) is a slowly varying amplitude (absorbing the Hankel magnitude
and any residual power-law running), and φn is a constant phase related to
arg ζ(1/2 + iωn ). This is precisely the structure assumed in the numerical
implementation:
                           X e−γωn2               
                                                    k
                                                            
             M (k) = 1 +       ϵ      cos ωn log        + ϕn ,        (32)
                            n
                                  ωn2               k⋆

with γ ∼ 1/σ 2 set by the resonance width σ.
   The role of the mode-function derivation is therefore to justify that:

  1. Logarithmic k-dependence of the phase is natural in a quasi-de Sitter
     background with a tower of modes characterized by complex indices νn
     tied to ωn .

  2. The slowly varying amplitude An (k) can be treated as approximately
     constant over the k-range of interest, consistent with the weak modu-
     lation assumption in AL-GFT.

A more detailed treatment (beyond minimal Track A) would fix α, compute
An (k) from first principles, and match directly to the microscopic GFT cou-
plings; here we focus on establishing the plausibility and consistency of the
effective phase structure used to derive the Zeta-Comb noise kernel.




                                     10
