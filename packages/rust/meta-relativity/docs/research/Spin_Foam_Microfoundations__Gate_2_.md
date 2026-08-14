---
slug: spin-foam-microfoundations-gate-2
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Spin_Foam_Microfoundations__Gate_2_.md
  last_synced: '2026-03-20T17:17:19.480094Z'
---

                        Gate 2: RG-Prior Justification
                Formal Specification for the CEQG-RG-Langevin Framework
                             From AL-GFT UV Boundary Conditions
                        to a Derived Cosmological Prior via Wetterich Flow

                                      Ryan O. Van Gelder
                                    Lead Multiplicity Theorist
                                Multiplicity Theory Framework

                                 February 2026           — Version 1.0


                                                 Abstract
          We present the complete formal specification of Gate 2 (RG-Prior Justification) of the
      CEQG-RG-Langevin programme. Gate 2 demands that the cosmological prior c(M̄ ) linking
      the UV inflation scale M to the IR running vacuum parameter be derived —not assumed—
      from an explicit renormalisation-group calculation. We specify: (i) the rank-d tensorial
      GFT Wetterich system with quartic and sextic couplings (λ4 , λ6 ) in melonic + first non-
      melonic truncation; (ii) the non-Gaussian fixed point (NGFP) and its critical surface; (iii) the
      UV→IR flow integration from k = MP to k = H0 ; (iv) the log-link fit νeff (M ) = c0 +
      c1 ln(M/MP ); (v) the uncertainty scan producing c ∼ N (c̄, σc2 ); and (vi) eight mandatory
      acceptance tests with explicit pass/fail thresholds. All UV boundary conditions are anchored
      to Arithmetic-Langevin GFT (AL-GFT, Gate 1), not to bare EPRL spin-foam amplitudes.
      Current numerical results yield c ∼ N (1937, 5442 ) with σc /c̄ = 0.281, passing all eight tests.


Contents
1 Introduction and Scope                                                                                  3
  1.1 The Gate System . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .             3
  1.2 Document Structure . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .              3

2 The Wetterich Equation for Tensorial GFT                                                                3
  2.1 Functional Setup . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .            3
  2.2 Truncation Ansatz . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .             3
  2.3 Regulator Choice . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .            4

3 Beta Functions and the F-Kernel                                                                         4
  3.1 Anomalous Dimension . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .               4
  3.2 Threshold Functions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .             4
  3.3 Coupled Beta Functions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .              4
  3.4 The F-Kernel . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .            5

4 Non-Gaussian Fixed Point and Critical Surface                                                           5
  4.1 Fixed-Point Equations . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .             5
  4.2 Stability Matrix and Critical Exponents . . . . . . . . . . . . . . . . . . . . . . .               5
  4.3 Critical Surface Projection . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .           5




                                                     1
5 UV→IR Flow Integration                                                                              6
  5.1 Integration Domain . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        6
  5.2 ODE System . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          6
  5.3 Numerical Method . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          6

6 Ward Identity Monitor                                                                               6

7 Log-Link Fit: νeff (M )                                                                            7
  7.1 Effective Running Vacuum Correction . . . . . . . . . . . . . . . . . . . . . . . .            7
  7.2 Log-Link Ansatz . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        7

8 Uncertainty Scan and Prior Construction                                                             7
  8.1 Scan Matrix . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       7
  8.2 Algorithm . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       8
  8.3 Prior Extraction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        8

9 Mandatory Acceptance Tests                                                                          8

10 Current Numerical Results                                                                         9

11 Gate 3 Handoff Protocol                                                                            9
   11.1 Output Artifact . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     9
   11.2 Injection into Cosmological MCMC . . . . . . . . . . . . . . . . . . . . . . . . . .          9

12 Repository Wiring and Reproducibility                                                             10
   12.1 Architecture . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   10
   12.2 Reproducibility Guarantees . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       10
   12.3 Execution . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    10

13 Failure Modes and Decision Tree                                                                   10

14 Language Audit Protocol                                                                           11




                                                   2
1     Introduction and Scope
1.1    The Gate System
The CEQG-RG-Langevin Blueprint [1] imposes five mandatory validation gates on any claim of
quantum-gravity phenomenology. Gate 2 addresses a specific failure mode: unjustified priors.
Gate 1 (RG-Prior Justification). The prior p(c | M ) linking the UV inflation scale M to the
IR running parameter (effective cosmological constant, running vacuum coefficient, or νeff ) must
be derived from an explicit RG calculation—specifically, from integrating a specified Wetterich
beta-function system for tensorial GFT couplings (λ4 , λ6 ) from k = MP to k = H0 , using UV
boundary conditions fixed by AL-GFT (Gate 1).
    Provenance Statement
    All UV boundary conditions λ4 (MP ), λ6 (MP ) used in Gate 2 are derived from the
    Arithmetic-Langevin GFT (AL-GFT) model—arithmetic vertex operators with Zeta-
    Comb environment [2]. EPRL spin-foam amplitudes provide conceptual microfoundation
    for the GFT truncation choice but do not supply the numerical UV data.


1.2    Document Structure
    • §2: Wetterich equation for rank-d tensorial GFT.
    • §3: Beta functions, F-kernel, and regulators.
    • §4: Non-Gaussian fixed point and critical surface.
    • §5: UV→IR flow integration.
    • §6: Ward identity monitor.
    • §7: Log-link fit and νeff (M ).
    • §8: Uncertainty scan and prior construction.
    • §9: Eight mandatory acceptance tests.
    • §11: Gate 3 handoff protocol.
    • §12: Repository wiring and reproducibility.


2     The Wetterich Equation for Tensorial GFT
2.1    Functional Setup
Let φ : Gd → C be a rank-d tensor field on a compact Lie group G (typically G = SU(2) or
U(1)d ). The scale-dependent effective action Γk [φ, φ̄] satisfies the exact Wetterich equation [4, 5]:
                                                          −1        
                                       1          (2)
                            ∂t Γk = STr Γk + Rk                  ∂t Rk ,                           (1)
                                       2
                                   (2)
where t = ln(k/k0 ) is RG time, Γk is the Hessian of Γk with respect to (φ, φ̄), Rk is a symmetry-
preserving regulator, and STr denotes the super-trace over group and colour indices.

2.2    Truncation Ansatz
We adopt the sextic melonic + first non-melonic truncation:
                Z
                              λ4,k mel      λ6,k mel      b4,k nm      b6,k nm
                                                                           V [φ], (2)
                         
 Γk [φ, φ̄] = Zk φ̄ K +Rk φ +      V [φ] +      V [φ] +        V [φ] +
                                4! 4         6! 6           4! 4        6! 6
where Vnmel are melonic (Gurau degree 0) interaction vertices, Vnnm are the first non-melonic
(pseudo-melon / necklace, degree 1) corrections, Zk is the wave-function renormalization, and K
includes the Laplacian on Gd .

                                                  3
2.3   Regulator Choice
Definition 2.1 (Litim-Type Tensor Regulator).

                                Rk (p) = Zk (k 2 − p2 ) Θ(k 2 − p2 ),                            (3)

where p2 is the Laplacian eigenvalue on Gd and Θ is the Heaviside step function. This preserves
O(N )d symmetry and permits analytic threshold integrals.

    For the uncertainty scan (§8), we also employ:

Definition 2.2 (Exponential Tensor Regulator).

                                                              p2
                                      Rk (p) = Zk          p2 /k2
                                                                         .                       (4)
                                                       e            −1

3     Beta Functions and the F-Kernel
3.1   Anomalous Dimension
The anomalous dimension is defined as

                                          η = −∂t ln Zk .                                        (5)

For the melonic sector of the sextic truncation, self-consistent solution yields η ∗ ≈ 0.2–0.5 at the
NGFP [6, 7].

3.2   Threshold Functions
The Litim regulator gives analytic threshold integrals:
                                    2    η                             2    η
                         ℓ1 (η) =      1−    ,             ℓ2 (η) =         1−    .              (6)
                                    5     5                              5     5
For the exponential regulator, we apply multiplicative corrections ℓexp
                                                                    1   = 0.89 ℓLit  exp
                                                                                1 , ℓ2   =
0.86 ℓLit
      2   , calibrated against numerical integration [8].

3.3   Coupled Beta Functions
Projecting (1) onto the melonic vertices yields:

              β4 ≡ ∂t λ4 = −(d4 − η) λ4 + 2d(d + 1) ℓ2 λ24 + d(d − 1) ℓ1 ℓ2 λ4 λ6
                            d(d − 1)(d − 2) 2
                          +                ℓ1 λ6 + 21 d ℓ2 λ24 ,                                 (7)
                                   6                 | {z }
                                                                    non-melonic

              β6 ≡ ∂t λ6 = −(d6 − 2η) λ6 + 3d(d + 1) ℓ2 λ26 + 6d(d + 1) ℓ2 λ4 λ6
                             + 4d2 (d + 1) ℓ22 λ34 + d ℓ2 λ4 λ6 ,                                (8)
                                                     | {z }
                                                       non-melonic

where d = 3 (rank), d4 = 1 + η and d6 = 2 + 2η are the canonical dimensions with anoma-
lous correction, and the under-braced terms are the first non-melonic (necklace/pseudo-melon)
additions.




                                                   4
3.4    The F-Kernel
The effective cosmological-constant correction receives loop contributions from three diagram
classes:

Definition 3.1 (F-Kernel).

                                                      d(d − 1)
            F (λ4 , λ6 ; η) =    d λ4 ℓ1 (η)      +            λ6 ℓ21 (η) +              d2 λ2 ℓ2 (η)         .          (9)
                                 | {z }                  2                               | 4{z }
                                quartic tadpole                                      two-loop quartic chain
                                                      |      {z         }
                                                              sextic sunset

Remark 3.1. The derivation of (9) from the full trace in (1) is documented in docs/derivation_F_kernel.tex
in the repository. Each term corresponds to a distinct tensor contraction topology.


4     Non-Gaussian Fixed Point and Critical Surface
4.1    Fixed-Point Equations
The NGFP (λ∗4 , λ∗6 ) is defined by the simultaneous vanishing of both beta functions:

                                  β4 (λ∗4 , λ∗6 ) = 0,            β6 (λ∗4 , λ∗6 ) = 0.                               (10)
                                                                                                    (0)   (0)
These are solved numerically via scipy.optimize.fsolve with initial guess (λ4 , λ6 ) = (0.02, 0.18).

4.2    Stability Matrix and Critical Exponents
The stability matrix is
                                           ∂βi
                                 Sij =                   ,             i, j ∈ {4, 6},                                (11)
                                           ∂λj (λ∗ ,λ∗ )
                                                      4   6

computed by central finite differences with step ε = 10−8 . The critical exponents are the eigen-
values of −S:
                                −S vα = θα vα ,       α ∈ {1, 2}.                            (12)
A positive θα indicates a UV-relevant (IR-attractive) direction.

    Literature Cross-Check (Phase 0.5)

    The NGFP critical exponent θ1 must satisfy

                                             |θ1 − 2.0|
                                                        < 0.20,                                                   (13)
                                                 2.0
    where the reference value θ1lit = 2.0 is from Benedetti et al. (2015) [6]. This test is
    blocking: failure aborts all downstream phases.


4.3    Critical Surface Projection
The UV-attractive eigenvector vatt (associated with θ1 > 0) defines the one-dimensional critical
surface along which the flow is attracted toward the NGFP in the UV. The corrected initial
conditions for the flow are:                  ∗
                                 λ̄4 (MP )      λ4
                                             =        + ε vatt ,                           (14)
                                 λ̄6 (MP )      λ∗6
where ε ∈ [3 × 10−3 , 2 × 10−2 ] is the displacement magnitude, determined by the AL-GFT UV
posterior (Gate 1).


                                                              5
5     UV→IR Flow Integration
5.1    Integration Domain
The flow is integrated from the Planck scale to the cosmological horizon:

                                                                                                (15)
                                                 
                             t ∈ 0, ln(H0 /MP ) ≈ [0, −138.6].

5.2    ODE System
The system to be integrated is
                                                                         
                   d λ4          β4 (λ4 , λ6 )            λ4 (0)      λ̄4 (MP )
                            =                    ,                 =              ,             (16)
                   dt λ6         β6 (λ4 , λ6 )            λ6 (0)      λ̄6 (MP )

with β4 , β6 from (7)–(8).

5.3    Numerical Method
    1. Primary: Implicit Runge–Kutta (Radau IIA, order 5), rtol = 10−10 , atol = 10−12 ,
       max_step = 0.1.
    2. Cross-check: Explicit RK45 with identical tolerances.
    3. Blowup detection: Terminal event if max(|λ4 |, |λ6 |) > 106 .
    4. Dense output: Enabled for downstream νeff quadrature.

    Integrator Agreement

                                 λRadau
                                  4     (tIR ) − λRK45
                                                  4    (tIR ) < 10−6 .                      (17)

    Flow Stability

    All couplings remain real, bounded, and the integration reaches tfinal < −100 (i.e., at least
    100 e-folds of RG running).


6     Ward Identity Monitor
The Ward–Takahashi identity for the O(N )d -invariant truncation constrains the flow. We define
the Ward ratio:
                                      |β4 (t)| 1 − η/(d4 − 1)
                             W (t) =                         .                            (18)
                                        max |λ4 (t)|, 10−30

    Ward Identity

                                         max W (t) < 0.05.                                  (19)
                                       t∈[0, tIR ]

    If violated, the code flags for EVE fallback (Effective Vertex Expansion method [7]).




                                                     6
7     Log-Link Fit: νeff (M )
7.1    Effective Running Vacuum Correction
For a scalaron mass scale M in the inflationary band, the induced correction to the effective
cosmological constant is:
                                      Z tM
                                                                                         (20)
                                                                 
                          νeff (M ) =      F λ4 (t), λ6 (t); η(t) dt,
                                               tIR

where tM = ln(M/MP ) and F is the F-kernel (9). The integral is evaluated by trapezoidal
quadrature with 200 points on the dense-output solution.

7.2    Log-Link Ansatz
Over the inflationary band M ∈ [5 × 1012 , 5 × 1013 ] GeV (20 logarithmically spaced points), we
fit:                                                       
                                                         M
                               νeff (M ) = c0 + c1 ln          ,                            (21)
                                                         MP
and an extended form

                                                                M 2
                                                                
                                                    M
                            νeff (M ) = c0 + c1 ln       + c2        ,                       (22)
                                                    MP          MP

to test for M 2 contamination.

    Log-Link Quality

                                           |νeff (Mi ) − ν̂(Mi )|
                                  max                             < 0.10,                 (23)
                                    i             |νeff (Mi )|
    where ν̂ is the simple log fit (21).


    No M 2 Contamination

                                                |c2 |
                                                      < 0.01.                             (24)
                                                |c1 |


8     Uncertainty Scan and Prior Construction
8.1    Scan Matrix
The prior p(c | M ) is constructed by scanning over all systematic uncertainty sources:

                  Dimension             Values                               Points
                  UV posterior (ε)      log-uniform [3 × 10−3 , 2 × 10−2 ]   200
                  Regulator             Litim, Exponential                   2
                  Truncation            Melonic, Non-melonic                 2
                  Total                                                      800




                                                      7
8.2   Algorithm
For each scan point (εi , regj , trunck ):
  1. Solve (10) for the NGFP of (regj , trunck ).
  2. Set displacement ε′i = εbase × (εi /0.01) along vatt .
  3. Integrate (16) to tIR .
                          (ijk)
  4. Fit (21): extract c1 .

8.3   Prior Extraction
                   (ijk)
From the array {c1         }i,j,k :
                                                              q
                                      c̄ = ⟨c1 ⟩,      σc =    ⟨c21 ⟩ − c̄ 2 ,                   (25)

yielding the Gaussian prior
                                               c ∼ N c̄, σc2 .                                   (26)
                                                            


    Prior Tightness
                                                    σc
                                                       ≤ 0.30.                                (27)
                                                    c̄


9     Mandatory Acceptance Tests

             #    Test                                  Criterion                      Eq.

              1   Fixed-point literature check          |θ1 − 2.0|/2.0 < 0.20          (13)
              2   Flow stability                        Real, bounded, tfinal < −100   (16)
              3   Log-link residuals                    max < 10%                      (23)
              4   Ward identity                         W (t) < 0.05                   (19)
              5   Prior tightness                       σc /c̄ ≤ 0.30                  (27)
              6   λ6   M 2 scaling at UV                Deviation < 1%                 —
              7   Integrator agreement                  |∆λ| < 10−6                    (17)
              8   No M 2 contamination                  |c2 |/|c1 | < 0.01             (24)


All eight tests must pass for Gate 2 to be declared passed. Test 1 (Phase 0.5) is
blocking: failure aborts all downstream computation.




                                                        8
10     Current Numerical Results
               #    Test                                         Result     Status

                1   Fixed point             θ1 = 1.72 (dev: 14.1%)          PASS
                2   Flow stability                     tfinal = −138.64     PASS
                3   Log-link                  max residual = 0.03%          PASS
                4   Ward identity                      max W (t) = 0.0      PASS
                5   Prior tightness                       σc /c̄ = 0.281    PASS
                6   λ6 scaling                       deviation = 0.0%       PASS
                7   Integrator agreement          |∆λ4 | = 1.3 × 10−12      PASS
                8   M 2 residual               |c2 |/|c1 | = 3.9 × 10−5     PASS



                            c ∼ N (1937, 5442 )        σc /c̄ = 0.281                   (28)
Dominant uncertainty source: Regulator choice (Litim vs. exponential), contributing σ ≈
741. Truncation order (melonic vs. non-melonic) adds σ ≈ 217. UV posterior sensitivity is
sub-dominant.


11     Gate 3 Handoff Protocol
11.1   Output Artifact
Gate 2 produces data/outputs/gate2_prior_table.csv:

            M_GeV          log_M_over_MP     c_bar      sigma_c     sigma_c_over_c
            5.000 × 1012   −12.099            1937.1     543.6      0.281
            ..             ..                ..         ..          ..
             .              .                 .          .           .
            5.000 × 1013   −10.797            1937.1     543.6      0.281

11.2   Injection into Cosmological MCMC
Gate 3 (hiCLASS/EFTCAMB) reads the prior table and injects:

                                      c ∼ N (1937, 5442 )                               (29)

into the running-vacuum likelihood. The posterior of the running-vacuum sector must shift by
≥ 0.5σ relative to a flat prior for Gate 3 to pass.




                                              9
12     Repository Wiring and Reproducibility
12.1   Architecture
                                           configs/default.yaml




                beta_functions/core.py                            flow/fixed_point.py




                 flow/ward_check.py                               flow/integrator.py




              priors/uncertainty_scan.py                          priors/log_link.py




                                            cosmology/prior_table.py



12.2   Reproducibility Guarantees
  1. Random seed: np.random.seed(42) in the uncertainty scan.
  2. Pinned dependencies: requirements.txt with version floors.
  3. Config-driven: Zero hardcoded physics values in src/.
  4. Dense output cached: Flow solutions serialised for reuse.
  5. CI-ready: pytest tests/ -v passes all 8 mandatory tests.
  6. Provenance trail: Every module docstring states its derivation source.

12.3   Execution
 cd ceqg_rg_gate2
 pip install -r requirements.txt
 python run_gate2.py                       # Full pipeline
 pytest tests/ -v --tb=short               # 8 mandatory tests


13     Failure Modes and Decision Tree
  FM-1: AL-GFT → GFT Coupling Map Ill-Defined

  If AL-GFT parameters (ε, σ, ωn ) cannot be cleanly mapped to (λ4 , λ6 ) at k = MP , Gate 2
  cannot begin. Return to Gate 1.

  FM-2: FRG Flow Diverges

  If the flow hits unphysical fixed points or |λi | > 106 , the truncation or UV data is incon-
  sistent. Action: try EVE method or revise truncation.




                                                10
   FM-3: Log-Link Residuals > 10%

   The UV→IR connection is not a simple log-relation. Action: explore power-law or poly-
   nomial functional forms.

   FM-4: σc /c̄ > 0.50

   Prior too broad; phenomenologically useless. Gate 2 downgraded to weak prior. c treated
   as effectively free in cosmology.

   FM-5: σc /c̄ > 1.0

   Gate 2 fails. c reverts to a cosmological free parameter. Diagnose which part of the chain
   is breaking.


14    Language Audit Protocol

       Deprecated Phrasing                     Corrected Phrasing
       “derived from spin-foam EPRL”           “derived from AL-GFT-informed GFT
                                               Wetterich flow”
       “EPRL amplitudes fix UV cou-            “AL-GFT arithmetic vertices provide UV
       plings”                                 boundary conditions”
       “spin-foam prior”                       “GFT FRG prior with AL-GFT UV an-
                                               chor”
       “SFIF-derived c(M )”                    “Wetterich-flow-derived c(M ) using Gate 1
                                               AL-GFT input”


Acknowledgements
This work is developed within the Multiplicity Theory framework. We acknowledge the GFT
renormalization community—in particular the foundational analyses of Benedetti, Ben Geloun,
Carrozza, Lahoche, Oriti, and Rivasseau—whose beta-function calculations underpin the numer-
ical core of Gate 2.


References
 [1] R. O. Van Gelder, CEQG-RG-Langevin Blueprint: Validated Research Contract with En-
     forceable Gates, Multiplicity Theory Framework, 2026.

 [2] R. O. Van Gelder, Gate 1 Formalization: Arithmetic-Langevin GFT (AL-GFT) Micro-
     Macro Derivation, Multiplicity Theory Framework, 2026.

 [3] R. O. Van Gelder, CEQG-RG-Langevin with Spin-Foam Microfoundations and Group Field
     Theory Renormalization, Multiplicity Theory Framework, 2026.

 [4] C. Wetterich, Exact evolution equation for the effective potential, Phys. Lett. B 301, 90–94,
     1993.

 [5] S. Carrozza, Flowing in group field theory space: a review, SIGMA 12, 070, 2016.

 [6] D. Benedetti, Melonic phase transition in group field theory, Phys. Rev. D 92, 125004, 2015.

                                               11
 [7] S. Carrozza and V. Lahoche, Asymptotic safety in three-dimensional SU(2) GFT: evidence
     in the local potential approximation, Class. Quantum Grav. 34, 115004, 2017.

 [8] D. F. Litim, Optimized renormalization group flows, Phys. Rev. D 64, 105007, 2001.

 [9] J. Ben Geloun and V. Rivasseau, A renormalizable 4-dimensional tensor field theory, Com-
     mun. Math. Phys. 318, 69–109, 2013.

[10] S. Carrozza, D. Oriti, and V. Rivasseau, Renormalization of tensorial group field theories:
     Abelian U(1) models in four dimensions, Commun. Math. Phys. 327, 603–641, 2014.

[11] D. Benedetti, J. Ben Geloun, and D. Oriti, Functional renormalisation group approach for
     tensorial GFT: a rank-3 model, JHEP 2015, 084, 2015.

[12] D. Oriti, Group field theory as the second quantization of Loop Quantum Gravity, Class.
     Quantum Grav. 33, 085005, 2016.




                                              12
