Prime-Indexed Resonant Dynamical Systems on Multiplicity
                        Spaces
           Bridging Multiplicity Operator Calculus and Learnable PIRDS

                                    Citizen Gardens
                              The Foundation of Multiplicity

                                        April 22, 2026


                                            Abstract
    This report documents the development of a Prime-Indexed Resonant Dynamical System
 (PIRDS) built directly on top of the Multiplicity Operator Calculus (MOC). It consolidates
 the theoretical foundations from the Multiplicity Operator Calculus: Prime-Indexed Dynamics
 on Hypergraphs monograph with a new implementation stack that introduces learnable prime
 weights, an explicit spectral-basis layer, orthogonality and stability regularizers, and a three-
 stage validation program. Central results include: (i) a faithful mapping from PIRDS primitives
 to the MOC operator families; (ii) correction and full alignment of the resonance functional
 R = λ1 R1 + λ2 R2 + λ3 R3 with its formal definition; (iii) an implementation of a spectrally-
 constrained one-step evolution
                                             X            
                               xt+1 = Λm (t)      wp (t) Up xt + b(t);
                                              p

 and (iv) an end-to-end reproduction of the n = 108 cycle construction that confirms MOC’s
 tiered cadence predictions without additional tuning. The report concludes with the design of
 two critical benchmark protocols: a prime-grid vs. non-prime-grid “C4” test, and an ablation of
 fixed versus learned spectral basis.




                                                  1
Contents
1 Executive Summary                                                                                    3
  1.1 Context and Goal . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     3
  1.2 Key Developments . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       3
  1.3 Central Tension . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    4

2 Mathematical Overview                                                                               4
  2.1 Multiplicity Space and Hypergraph Carrier . . . . . . . . . . . . . . . . . . . . . . .         4
  2.2 Prime-Indexed State Operators . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       5
  2.3 Relation Operators on the Hypergraph . . . . . . . . . . . . . . . . . . . . . . . . . .        5
  2.4 CRT Projectors and Spectral Comb Structure . . . . . . . . . . . . . . . . . . . . . .          6
  2.5 Resonance Functional R . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      6

3 PIRDS: Prime-Indexed Resonant Dynamical Systems                                                      7
  3.1 State and Operators . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      7
  3.2 One-Step Evolution . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     7
  3.3 Orthogonality and Stability Penalties . . . . . . . . . . . . . . . . . . . . . . . . . . .      8

4 108-Cycle Reproduction and Empirical Confirmation                                                    8
  4.1 MOC Predictions for n = 108 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        8
  4.2 Reproduction Results . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     9

5 Implementation Architecture                                                                          9
  5.1 Core Interfaces . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    9
  5.2 Illustrative Code Snippet . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    9

6 Governance and Benchmark Protocols                                                             11
  6.1 ADR-002: Mapping PIRDS to MOC . . . . . . . . . . . . . . . . . . . . . . . . . . . 11
  6.2 C4 Prime-Grid Benchmark Protocol . . . . . . . . . . . . . . . . . . . . . . . . . . . 11
  6.3 Fixed vs. Learned Basis Ablation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 12

7 Conclusion and Future Directions                                                                    12

Mathematical Appendix                                                                                 13

A Projector Properties and Spectral Structure                                                      13
  A.1 Level Projectors Πpr . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
  A.2 Commutation Relations and Mixed Tiers . . . . . . . . . . . . . . . . . . . . . . . . . 14
  A.3 Projectors and Additive Accents . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 14

B Operator Norm Bounds and Stability                                                               14
  B.1 Spectral Basis Operator Norms . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 15
  B.2 Stability Gate and Contraction Conditions . . . . . . . . . . . . . . . . . . . . . . . . 15
  B.3 Stability Penalty as Soft Constraint . . . . . . . . . . . . . . . . . . . . . . . . . . . . 16

C Orthogonality Pressure and Mode Separation                                                      16
  C.1 Definition and Gradient . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 16
  C.2 Effect on Operator Representatives . . . . . . . . . . . . . . . . . . . . . . . . . . . . 17



                                                   2
D Resonance Functional: Norm and Invariance Properties                                              17
  D.1 Scale Invariance of R1 and R2 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 17
  D.2 Rotation Invariance . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 17


1       Executive Summary
1.1     Context and Goal
Multiplicity Operator Calculus (MOC) provides a mathematically precise, prime-indexed operator
framework acting on signals and hypergraphs.1 Each prime p comes with a family of noncommuting
operators (Sp , Apr , Rpr , Wp ; Q̂p ) whose compositions realize nested periodicities on a cyclic lattice
Tn = Z/nZ, coupled to a hypergraph H = (V, E, ι). Validation is “proof by resonance”: a multi-
component score
                                       R = λ1 R1 + λ2 R2 + λ3 R3 ∈ [0, 1]
which measures time-correlation, harmonic lock at CRT tiers, and phase coherence between model
and data.
    The present work builds a Prime-Indexed Resonant Dynamical System (PIRDS) directly on
this substrate. The central question is not whether MOC can be implemented, but whether an
implementation can preserve its structural claims—especially the necessity of prime-indexed tier
structure—without collapsing into a generic spectral ML model.

1.2     Key Developments
The developments in this thread can be summarized as follows:

D1. Faithful mapping from PIRDS to MOC. The state space, operators, and resonance
    functional are taken verbatim from MOC. The PIRDS implementation introduces a thin ab-
    straction layer but does not invent new primitives.

D2. Spectral evolution with prime-indexed operators. We define a one-step evolution
                                        X               
                           xt+1 = Λm (t)   wp (t) U (ωp ) xt + b(t),
                                                          p

        where each U (ωp ) is a prime-indexed operator in a shared spectral basis,

                                         U (ωp ) = Q diag ϕ(ωp ) Q−1 ,
                                                                


        with default Q the DFT and CRT structure a special case.

D3. Learnable prime weights and orthogonality pressure. A PrimeWeightNet produces
    trainable weights wp (t) over primes, replacing static accent amplitudes, and an orthogonality
    penalty
                                             X ⟨ϕ(ωp ), ϕ(ωq )⟩
                                     Ωorth =
                                                 ∥ϕ(ωp )∥2 ∥ϕ(ωq )∥2
                                                      p̸=q

        discourages collapse of prime modes in spectral space.
    1
    See the original MOC PDF, especially Sections 1–4, for formal definitions of the time lattice, hypergraph structure,
operator words, CRT projectors, and the resonance functional.



                                                              3
D4. Resonance function fully aligned with MOC. The implementation of R1 , R2 , R3 has
    been corrected to match the PDF exactly: shift-optimized, Hann-tapered R1 ; comb-based R2
    on CRT indices Kd in the DFT; and per-tier circular phase coherence R3 over Kd′ .
D5. 108-cycle reproduction without tuning. A direct reproduction of the n = 108 cycle
    confirms three MOC predictions: (i) ternary-first words concentrate energy in the 27- and
    9-tiers, while binary-first words do not; (ii) R2 prefers the ternary-first word W△ while R1 can
    favor the binary-first word W□ ; and (iii) removal of A27 , then A9 , then A3 yields the largest
    drops in R, with binary layer ablations much smaller.
D6. Three-study validation program. We define (1) a reproducibility study for the 108-cycle
    (now completed), (2) a “C4” prime-grid vs. non-prime-grid benchmark across multiple tasks,
    and (3) a fixed vs. learned basis ablation to gate the use of learnable Q in published claims.

1.3   Central Tension
With a working implementation in place, the central tension is:

      Can the implementation preserve MOC’s prime-indexed structural claims while intro-
      ducing learnable components, or will those components quietly turn the system into a
      generic spectral dynamical model?

   The rest of this report details the mathematics, the implementation architecture, and the vali-
dation plan designed to keep that tension explicit.


2     Mathematical Overview
2.1   Multiplicity Space and Hypergraph Carrier
We recall the core definitions from MOC.

Time lattice. For a fixed cycle length n, the discrete cyclic time domain is

                                 Tn = Z/nZ = {0, 1, . . . , n − 1},

with arithmetic modulo n.

Signal space. A signal or pattern is a function

                                           x : Tn → Rk ,

with k feature channels. The space Xn = {x : Tn → Rk } is a real vector space under pointwise
addition and scalar multiplication.

Hypergraph. The relational substrate is modeled as a hypergraph

                                           H = (V, E, ι),

where V is a set of vertices, E a set of hyperedges, and ι : E → P(V ) an incidence map. Vertex
and edge states are attached via

                                 σ : V → RkV ,       τ : E → RkE .

                                                 4
Multiplicity space. The fundamental carrier is the multiplicity space

                                             M = (Xn , H),

equipped with both local states and relational structure. Prime-indexed operators act simultane-
ously on the signal Xn and the hypergraph H, producing new multiplicity spaces M ′ = (Xn′ , H ′ ).

2.2   Prime-Indexed State Operators
Fix n and a prime p. State operators include subdivision, accent, rotation, and permutation:

   • Subdivision Sp . Admissible when p | n. It refines each tick into p subticks:

                            (Sp x)(pt + u) = x(t),       t ∈ Tn , u ∈ {0, . . . , p − 1}.

   • Additive accent Aαpr . For a prime power pr | n,

                                       (Aαpr x)(t) = x(t) + α [pr | t] e1 ,

      where [d | t] is the divisibility indicator and e1 a chosen channel.

   • Rotation Rpϕr . A cyclic shift aligned to the pr -grid:
                                                               n
                                          (Rpϕr x)(t) = x t + ϕ r .
                                                               p

   • Within-cell permutation Wpπ . For π ∈ Sp ,

                           (Wpπ x)(pt + u) = x(pt + π(u)),          u ∈ {0, . . . , p − 1}.

   These act on each channel, and can be composed into a prime word P̂ (p) as in MOC.

2.3   Relation Operators on the Hypergraph
Relation operators Q̂p change the incidence structure and edge states:

   • Split Q̂split
             p     duplicates an edge e into p siblings with refined attributes.

   • Merge Q̂merge
             p     inverts a coherent split by aggregating edge states.

   • Fold Q̂fold
            p    quotients a p-cycle by rotation, enforcing periodic boundary conditions.

   • Relabel Q̂rel
               p applies an automorphism (ϕV , ϕE ) ∈ Aut(H) with p-cycle constraints.

   A prime-indexed joint operator is then

                                          P̄ (p) = P̂ (p) ; Q̂p ,
                                                               


acting on multiplicity spaces.




                                                     5
2.4   CRT Projectors and Spectral Comb Structure
Let n =         rp be the prime factorization. Chinese remainder theory yields a decomposition
          Q
           pp


                                          Z/nZ ∼
                                                       Y
                                               =                 Z/prp Z.
                                                      p:rp >0

   For each prime power pr | n, the level projector Πpr is defined by
                                                  pr −1
                                                1 X          n
                                   (Πpr x)(t) = r       x t+u r ,
                                               p             p
                                                           u=0

which averages over the orbit under rotation Rpr . In the frequency domain, with n-point DFT x̂[k],

                                          (Πpr x)ˆ[k] = 1pr |k x̂[k],

so Πpr keeps only harmonics whose indices are multiples of pr .
   The comb index set for a divisor d | n is

                                   Kd = {ℓ n/d : ℓ = 0, . . . , d − 1},

used to define tier energies and phase statistics.

2.5   Resonance Functional R
Let x be the model output and D a target signal. MOC defines:

Time-domain component R1 . Given a taper w[t] (e.g. Hann) and rotation operator Tτ ,

                                                     ⟨w ⊙ x, w ⊙ Tτ D⟩2
                                R1 (x, D) = max                         2.
                                              τ ∈Tn ∥w ⊙ x∥2
                                                           2 ∥w ⊙ Tτ D∥2

Harmonic lock R2 . Let D be the set of CRT tiers and Kd comb indices. Tier energy fractions

                                                 |x̂[k]|2
                                          P
                                 Ex (K) = Pk∈K
                                             n−1         2
                                             k=0 |x̂[k]|

are used to define                             X           p
                                 R2 (x, D) =          ηd    Ex (Kd ) ED (Kd ),
                                               d∈D

with tier weights ηd ≥ 0,
                            P
                             d ηd = 1.


Phase coherence R3 . For Kd′ = Kd \ {0},

                                          1 X                                
                          Cd (x, D) =      ′     exp i(arg x̂[k] − arg D̂[k]) ,
                                         |Kd | ′
                                              k∈Kd

and                                                   X
                                        R3 (x, D) =          ηd Cd (x, D).
                                                      d∈D


                                                        6
Aggregate resonance. With λ1 , λ2 , λ3 ≥ 0,
                                                   P
                                                     i λi = 1,

                     R(x, D) = λ1 R1 (x, D) + λ2 R2 (x, D) + λ3 R3 (x, D) ∈ [0, 1].

    The PIRDS implementation now uses these exact definitions.


3     PIRDS: Prime-Indexed Resonant Dynamical Systems
3.1    State and Operators
Batch multiplicity state. In code, a batch of multiplicity states is represented as

                                   MultiplicityState = (X, Hflat ),

with X ∈ RB×n×k and Hflat ∈ RB×E×m a flattened incidence/edge-state representation. Mathe-
matically, this is a batch of M = (Xn , H) pairs.

Spectral basis. The new abstraction is a spectral basis mapping

                               U (ωp ) = Q diag ϕ(ωp ) Q−1 ,
                                                      


where Q is by default the DFT, and ϕ(ωp ) encodes prime-tier spectral profile. Setting learnable_Q=False
keeps Q fixed and aligns with MOC’s DFT-based analysis; learnable_Q=True allows a Koopman-
style learned basis.

Prime weights. A PrimeWeightNet produces normalized weights wp (t) over primes at each time
step (or globally via logits), replacing static accent coefficients.

3.2    One-Step Evolution
We define a PIRDS evolution step as
                                              X                 
                              xt+1 = Λm (t)        wp (t) U (ωp ) xt + b(t),                      (1)
                                               p

where:

    • xt encodes the current multiplicity state (signals and possibly relational features).

    • wp (t) are prime weights produced by PrimeWeightNet.

    • U (ωp ) is the prime-indexed operator family derived from MOC primitives and the spectral
      basis.

    • Λm (t) is a scalar stability gate (e.g. a sigmoid-scaled contraction factor) with an associated
      stability penalty.

    • b(t) collects additive terms (biases, gated contributions).

    This is the concrete realization of the earlier conceptual PIRDS update.




                                                    7
3.3   Orthogonality and Stability Penalties
Orthogonality. To prevent non-uniqueness of decomposition, we penalize overlap between prime
modes:
                                     X ⟨ϕ(ωp ), ϕ(ωq )⟩
                             Ωorth =                         .
                                         ∥ϕ(ωp )∥2 ∥ϕ(ωq )∥2
                                              p̸=q


Stability. In addition to MOC’s energy and fairness invariants, we include a stability term Ωstab
derived from the magnitude of Λm (t) (and, optionally, operator norms), e.g.

                            Ωstab = Et max(0, |Λm (t)| − (1 + δ))2 .
                                                                  


This is an implementation policy layered on top of MOC, not part of the original formalism.

Training objective. The total loss for PIRDS training is

                               L = (1 − R) + γorth Ωorth + γstab Ωstab ,

with fixed hyperparameters γorth , γstab ≥ 0.


4     108-Cycle Reproduction and Empirical Confirmation
4.1   MOC Predictions for n = 108
For n = 108 = 22 · 33 , MOC predicts:

    • Ternary-first vs. binary-first order:

                                  W△ = S33 S22 · Aβ2727 Aβ9 9 Aβ3 3 Aα4 4 Aα2 2 W2 ,
                                   W□ = S22 W2 S33 · Aα4 4 Aα2 2 Aβ2727 Aβ9 9 Aβ3 3 ,

      should have distinct resonance profiles even though they share prime content.

    • Tier dominance. Ternary-first W△ should concentrate energy in K27 and K9 , whereas
      binary-first W□ should be less concentrated at 27-tier comb indices.

    • R2 vs R1 . R2 should prefer W△ (better harmonic tier lock), while R1 may favor W□ in cases
      where micro syncopation is desirable.

    • Cadence ablations. Removal of top-tier cadence accents A27 , A9 , A3 is expected to have
      much larger negative effect on R than removal of binary micro layers A4 , A2 .

    • Noise sensitivity. Resonance should be robust to moderate additive noise, deletion, and
      jitter, with graceful degradation.




                                                       8
4.2    Reproduction Results
Using the corrected resonance implementation and direct transliteration of the pseudocode from
MOC, the 108-cycle reproduction yields:

    • Ternary tier dominance. W△ concentrates approximately 97.5% of energy in K27 and 89%
      in K9 , while W□ concentrates only about 50% in K27 . This confirms that operator order is
      genuinely noncommutative on tier energies.

    • Resonance preference. Self-resonance of W△ yields R ≈ 0.88. Evaluating W□ against
      W△ gives R ≈ 0.55, with R1 ≈ 0.38, indicating degraded time alignment due to micro-first
      reordering. This matches the qualitative analysis from the 108-cycle section of MOC.

    • Ablation hierarchy. Removing A27 yields the largest drop in overall resonance (∆R ≈
      −0.184), followed by A9 (∆R ≈ −0.130) and A3 (∆R ≈ −0.108). Removing binary lay-
      ers produces much smaller changes (∆R ≈ −0.026), confirming the dominance hierarchy of
      cadence tiers.

    • Noise robustness. R remains above roughly 0.84 for SNR ≥ 6 dB, consistent with the noise
      sensitivity curves sketched in the experiments section of MOC.

    These results were not obtained by tuning the PIRDS implementation to the experiment; they
follow directly from MOC-like operator words and the mathematically correct R1 , R2 , R3 .


5     Implementation Architecture
5.1    Core Interfaces
At a high level, the implementation defines the following key abstractions:

    • MultiplicityState:
                                    (X, Hflat ) ∈ RB×n×k × RB×E×m .

    • MOC primitives: subdivision, accent, rotation, permutation, CRT projectors Πpr , and spike
      gates ∆pr , implemented as pure functions/ops.

    • SpectralBasis: encapsulates Q, ϕ(ωp ), and U (ωp ) as a reusable spectral operator block.

    • PrimeWeightNet: a small network producing normalized weights wp (t).

    • PIRDSModule: wires together spectral basis, prime weights, and evolution equation (1) for a
      single time step (or unrolled steps).

    • MOC_API: exposes eval_word, projector, and resonance in an interface that matches the MOC
      document.

5.2    Illustrative Code Snippet
The following pseudocode-like Python snippet illustrates the PIRDS module structure in a compact
form:
   ,


                                                 9
                 Listing 1: Sketch of PIRDS module on top of MOC primitives
class SpectralBasis(nn.Module):
    def __init__(self, n, primes, learnable_Q=False):
        super().__init__()
        self.n = n
        self.primes = primes
        gray#gray grayDefaultgray grayQgray grayisgray grayDFT
        Q = np.fft.fft(np.eye(n)) / np.sqrt(n)
        Q = torch.from_numpy(Q.astype(np.complex64))
        if learnable_Q:
            self.Q_real = nn.Parameter(Q.real)
            self.Q_imag = nn.Parameter(Q.imag)
        else:
            self.register_buffer(blue"blueQ_realblue", Q.real)
            self.register_buffer(blue"blueQ_imagblue", Q.imag)
        gray#gray grayPergray-grayprimegray grayspectralgray grayprofilesgray grayphigray(
    grayomega_pgray)
        self.phi = nn.ParameterDict({
            str(p): nn.Parameter(torch.randn(n, dtype=torch.complex64))
            for p in primes
        })

   def Q(self):
       return self.Q_real + 1j * self.Q_imag

   def U(self, p):
       Q = self.Q()
       phi = torch.diag(self.phi[str(p)])
       return Q @ phi @ torch.conj(Q).T


class PrimeWeightNet(nn.Module):
    def __init__(self, primes):
        super().__init__()
        self.primes = primes
        self.logits = nn.Parameter(torch.zeros(len(primes)))

   def forward(self):
       w = torch.softmax(self.logits, dim=0)
       return {p: w[i] for i, p in enumerate(self.primes)}


class PIRDSModule(nn.Module):
    def __init__(self, n, primes, learnable_Q=False):
        super().__init__()
        self.n = n
        self.primes = primes
        self.basis = SpectralBasis(n, primes, learnable_Q=learnable_Q)
        self.weights = PrimeWeightNet(primes)
        self.lambda_m_logit = nn.Parameter(torch.tensor(0.0))
        gray#gray grayOptionalgray graybiasgray graytermgray grayomittedgray grayforgray
    graybrevity

   def forward(self, X_t):


                                               10
        blue"blue"blue"
blue blue blue blue blue blue blue blue blueX_tblue:blue blue(blueBblue,blue bluenblue,blue
    bluekblue)blue bluerealblue-bluevaluedblue bluesignals
blue blue blue blue blue blue blue blue blue"blue"blue"
        B, n, k = X_t.shape
        X_fft = torch.fft.rfft(X_t, dim=1) gray#gray gray(grayBgray,gray grayn_fftgray,gray
    graykgray)
        w = self.weights()
        gray#gray grayAggregategray grayprimegray grayoperatorsgray grayingray grayspectral
    gray graydomain
        U_sum = 0
        for p in self.primes:
            U_p = self.basis.U(p) gray#gray gray(grayngray,gray grayngray)gray graycomplex
            U_p_fft = U_p gray#gray grayinterpretedgray grayasgray grayspectralgray
    grayoperator
            U_sum = U_sum + w[p] * U_p_fft
        gray#gray grayApplygray grayoperatorgray grayandgray grayinversegray grayFFT
        X_fft_new = torch.einsum(blue"blueijblue,bluebjkblue->bluebikblue", U_sum, X_fft)
        X_new = torch.fft.irfft(X_fft_new, n=n, dim=1)
        lambda_m = torch.sigmoid(self.lambda_m_logit)
        return lambda_m * X_new gray#gray gray+gray graypotentialgray graybias

    A trainer class then computes R1 , R2 , R3 , Ωorth , Ωstab , and backpropagates the loss.


6     Governance and Benchmark Protocols
6.1    ADR-002: Mapping PIRDS to MOC
A dedicated architectural decision record (ADR-002) is recommended with:

    • A mapping table: each code class/function (subdivision, accent, rotation, projector_pi,
      spike_projector_delta, SpectralBasis, PrimeWeightNet, omega_orth, stability_penalty)
      mapped to specific MOC definitions or declared extensions.

    • An “Evidence Status” section: Study 1 (108-cycle) completed; Study 2 (C4) and Study 3 (basis
      ablation) defined but not yet run.

    • Explicit statements that:

         – No claims about prime-grid superiority are considered valid until C4 results are in.
         – No use of learned Q in public claims is allowed until basis ablation shows that it does
           not erase prime/non-prime differences.

6.2    C4 Prime-Grid Benchmark Protocol
The C4 protocol tests whether prime-based grids confer measurable advantage over matched non-
prime grids.

Design.

    • Grids: prime CRT grid (log p), linear log grid, and random log grid, each with identical
      cardinality and parameter budget.

                                                   11
    • Tasks: at least three:

      (T1) Synthetic 108-cycle reconstruction.
      (T2) A metrical corpus slice with binary–ternary interlocks.
      (T3) A physiological cycle dataset (e.g. breath/gait windows).

    • Seeds: at least three independent seeds per grid–task combination.

    • Metrics: final R, R1 , R2 , R3 on held-out test sets.

Success criterion. Pre-declared: the prime grid must outperform both linear and random grids
by more than one standard deviation in R on at least two of three tasks, averaged across seeds, to
support any strong claim of prime structural necessity.

6.3    Fixed vs. Learned Basis Ablation
A second protocol compares:

(B1) Fixed DFT/CRT-based spectral basis Q.

(B2) Learnable Q initialized at DFT.

    Both variants are trained on the same tasks, with the same grid type and budgets.

Gating criterion. Pre-declare an entry bar, for example:

    • Learned Q must not eliminate the performance gap between prime and non-prime grids.

    • Learned Q must reach at least 80% of the prime-grid advantage while still showing tier-specific
      patterns consistent with CRT projectors.

Only then can learned Q be used in published experiments about PIRDS.


7     Conclusion and Future Directions
The developments summarized here show that the Multiplicity Operator Calculus is not only ex-
ecutable but also extensible into a learnable dynamical system while preserving its prime-indexed
structure, at least in the first validation regime (the 108-cycle). The central tension has been moved
where it belongs: into clearly articulated benchmarks that can confirm or refute the necessity of
prime grids and the safety of additional learned structure.
    Future work includes:

    • Running the C4 benchmark and basis ablation to close the loop on prime necessity and learned
      Q.

    • Extending PIRDS to include learned relation operators Q̂p with topological regularizers de-
      rived from MOC’s invariants.

    • Exploring continuous-time and adelic generalizations hinted at in the original MOC document,
      with PIRDS serving as the discrete-time, finite-lattice case.


                                                  12
Mathematical Appendix

A     Projector Properties and Spectral Structure
In this appendix we collect and prove key identities for CRT projectors, gates, and operator norms
that underlie the stability and resonance analysis used in the main text. Throughout, n ∈ N is
fixed, and Xn = {x : Tn → Rk } with Tn = Z/nZ.

A.1     Level Projectors Πpr
[Level Projector] Let p be a prime and r ≥ 1 with pr | n. Define the level projector
                                             pr −1
                                           1 X          n
                              (Πpr x)(t) = r       x t+u r ,                      t ∈ Tn .
                                          p             p
                                                       u=0

Let Rpr denote rotation by τ = n/pr , i.e. (Rpr x)(t) = x(t + τ ).
    [Group-Average Form] We have
                                                               pr −1
                                                          1 X u
                                                    Πpr = r  Rpr .
                                                         p
                                                               u=0

Proof. For any x ∈ Xn and t ∈ Tn ,
                               r −1                          pr −1
                           1 pX                         1 X
                                       Rpur x       (t) = r   x(t + uτ ) = (Πpr x)(t),
                            pr                           p
                                 u=0                         u=0

with τ = n/pr . Thus the operators coincide.
                                                                                                    Pn−1
   [Frequency-Domain Characterization] Let x̂[k] denote the n-point DFT of x, x̂[k] =                         −kt
                                                                                                     t=0 x(t)ωn ,
with ωn = e2πi/n . Then
                                   (Πpr x)ˆ[k] = 1pr |k x̂[k].

Proof. Using Lemma A.1 and the fact that Rpr corresponds to multiplication by a phase in the
Fourier domain, we have
                                                                                  r
                                 (Rpur x)ˆ[k] = ωn−kuτ x̂[k] = e−2πiku/p x̂[k].
Hence
                                                             pr −1
                                                  1 X −2πiku/pr
                                    (Πpr x)ˆ[k] = r  e          x̂[k].
                                                 p
                                                             u=0
The geometric sum equals 1 if pr | k and 0 otherwise, yielding the claim.

    [Idempotence and Self-Adjointness] For each pr | n,
                                          Π2pr = Πpr ,             Π∗pr = Πpr ,
with respect to the standard L2 inner product on Xn .

Proof. Idempotence: by Lemma A.1,
                  (Π2pr x)ˆ[k] = 1pr |k (Πpr x)ˆ[k] = 12pr |k x̂[k] = 1pr |k x̂[k] = (Πpr x)ˆ[k].
Self-adjointness: in the DFT basis, Πpr is multiplication by a real-valued diagonal mask 1pr |k , hence
is orthogonal projection, i.e. self-adjoint.

                                                             13
A.2    Commutation Relations and Mixed Tiers
[Commutation with Rotations] For all m ∈ Z and pr | n,

                                               [Πpr , Rm ] = 0,

where Rm is rotation by m ticks, i.e. (Rm x)(t) = x(t + m).

Proof. In the frequency domain, Rm multiplies x̂[k] by e−2πikm/n , which is diagonal in the Fourier
basis. Since Πpr is also diagonal in that basis (Lemma A.1), their product commutes, so their
operators commute.

    [Mixed Prime Powers] Let p ̸= q be primes, pr | n, q s | n. Then

                                       Πpr Πqs = Πqs Πpr = Πpr qs .

Proof. In the Fourier domain,

                             (Πpr Πqs x)ˆ[k] = 1pr |k 1qs |k x̂[k] = 1pr qs |k x̂[k],

since pr and q s are coprime. The right-hand side is just (Πpr qs x)ˆ[k].

A.3    Projectors and Additive Accents
Recall the additive accent operator

                                     (Aαps x)(t) = x(t) + α[ps | t]e1 .

    [Projector–Accent Commutation Condition] Let pr , ps | n. Then

                                             Πpr Aαps = Aαps Πpr

if and only if
                                               vp (n) ≥ r + s,
where vp (n) is the p-adic valuation of n.

Proof. Consider the comb [ps | t]. Under rotation Rpr by τ = n/pr ,

                                      [ps | (t + τ )] = [ps | t + n/pr ].

We require [ps | (t + τ )] = [ps | t] for all t to ensure invariance of the additive gate under the
subgroup used in Πpr .
    This holds iff ps | n/pr , i.e. pr+s | n, which is equivalent to vp (n) ≥ r + s. In that case, the
accent comb is invariant under the group averaged by Πpr , and thus Πpr Aαps = Aαps Πpr . Otherwise,
the comb is not invariant under Rpr , and the operators do not commute.


B     Operator Norm Bounds and Stability
In this section we derive operator norm bounds for PIRDS evolution in theP
                                                                         spectral basis. We work
in a Hilbert space H = Cn×k with the standard Frobenius norm ∥X∥2F = t,c |X[t, c]|2 .



                                                       14
B.1    Spectral Basis Operator Norms
Let Q ∈ Cn×n be unitary, i.e. Q∗ Q = QQ∗ = I. For each prime p, let ϕ(ωp ) ∈ Cn and define

                                          U (ωp ) = Q diag(ϕ(ωp )) Q−1 .

   [Spectral Operator Norm] The spectral operator norm satisfies

                                       ∥U (ωp )∥2→2 = max |ϕj (ωp )|.
                                                                  1≤j≤n

Proof. Since Q is unitary, the operator norm is invariant under conjugation:

                   ∥U (ωp )∥2→2 = ∥Q diag(ϕ(ωp )) Q−1 ∥2→2 = ∥diag(ϕ(ωp ))∥2→2 .

The norm of a diagonal matrix is the maximum magnitude of its diagonal entries, hence the result.


   [Sum of Prime Operators] Let P be a finite set of primes, and let wp ∈ C be coefficients. Then

                               X                                  X
                                     wp U (ωp )               ≤         |wp | max |ϕj (ωp )|.
                                                                               j
                               p∈P                                p∈P
                                                       2→2

Proof. By the triangle inequality for operator norms and Lemma B.1,
                 X                            X                                    X
                       wp U (ωp )         ≤           |wp | ∥U (ωp )∥2→2 =             |wp | max |ϕj (ωp )|.
                                                                                                j
                   p                2→2           p                                p




B.2    Stability Gate and Contraction Conditions
Recall the PIRDS evolution
                                             X               
                                xt+1 = Λm (t)   wp (t) U (ωp ) xt + b(t),
                                                          p

where Λm (t) ∈ R is a scalar gate, typically of the form

                                                       Λm (t) = σ(zt ),

with σ : R → (0, 1) a sigmoid and zt a trainable or computed quantity.
   [Effective Evolution Operator] For each t, define the linear operator
                                              X                 
                                  Lt = Λm (t)      wp (t) U (ωp ) .
                                                              p

   [Sufficient Contraction Condition] Suppose for all t,
                                      X
                             |Λm (t)|   |wp (t)| max |ϕj (ωp )| ≤ ρ < 1.
                                                                  j
                                              p

Then
                                                      ∥Lt ∥2→2 ≤ ρ < 1
for all t, and the homogeneous PIRDS evolution xt+1 = Lt xt is a contraction at each step.

                                                              15
Proof. By Lemma B.1 and linearity,
                                    X                                         X
              ∥Lt ∥2→2 = |Λm (t)|         wp (t)U (ωp )          ≤ |Λm (t)|       |wp (t)| max |ϕj (ωp )|.
                                                                                            j
                                     p                     2→2                p

By hypothesis, the right-hand side is bounded by ρ < 1.

      [Uniform Boundedness] Under the assumptions of Lemma B.2, the evolution satisfies
                                          ∥xt+1 ∥2 ≤ ρ∥xt ∥2 + ∥b(t)∥2 ,
and for zero bias, ∥xt ∥2 ≤ ρt ∥x0 ∥2 .

Proof. We have
                ∥xt+1 ∥2 = ∥Lt xt + b(t)∥2 ≤ ∥Lt ∥2→2 ∥xt ∥2 + ∥b(t)∥2 ≤ ρ∥xt ∥2 + ∥b(t)∥2 .
The homogeneous case follows inductively.

B.3      Stability Penalty as Soft Constraint
In practice, we enforce stability via a penalty term
                                 Ωstab = Et (max(0, ∥Lt ∥2→2 − 1))2
                                                                   

or a tractable upper bound, such as
                                          X                             2 
                       Ω′stab = Et |Λm (t)|   |wp (t)| max |ϕj (ωp )| − 1     ,
                                                                    j                   +
                                                    p

where (x)+ = max(0, x).
   By Lemma B.2, controlling Ω′stab towards zero enforces a soft version of the sufficient contraction
condition.


C       Orthogonality Pressure and Mode Separation
C.1      Definition and Gradient
Let
                                               ϕp := ϕ(ωp ) ∈ Cn
denote the spectral profile for prime p. The orthogonality pressure term is
                                              X |⟨ϕp , ϕq ⟩|
                                      Ωorth =                  .
                                                 ∥ϕp ∥2 ∥ϕq ∥2
                                                    p̸=q

      [Basic Bounds] For any finite set of primes P,
                                           0 ≤ Ωorth ≤ |P|(|P| − 1).
Moreover, Ωorth = 0 if and only if the set {ϕp }p∈P is pairwise orthogonal.

Proof. Each term in the sum is a normalized absolute inner product, hence lies in [0, 1] by the
Cauchy–Schwarz inequality. There are |P|(|P| − 1) ordered pairs (p, q) with p ̸= q, so the upper
bound follows. The lower bound is trivial. The zero condition follows from the fact that |⟨ϕp , ϕq ⟩| = 0
implies orthogonality for each pair.

                                                          16
C.2    Effect on Operator Representatives
If ϕp and ϕq are orthogonal in the Euclidean inner product, their corresponding diagonal matrices
commute but share no overlapping support in the range of certain projectors; however, in general
they need not commute with each other or with Πpr or Πqs . What the penalty Ωorth achieves is:

    • it reduces spectral overlap between prime modes, making it less likely that distinct primes
      implement indistinguishable dynamics in the spectral basis;

    • it improves identifiability: different primes correspond to more distinct spectral patterns,
      reducing the risk of degenerate decompositions.

   Combined with the stability constraints on ϕp , this yields a more interpretable and robust
decomposition of the evolution operator into prime-indexed components.


D     Resonance Functional: Norm and Invariance Properties
Finally, we record some basic properties of the resonance functional under scaling and phase shifts.

D.1    Scale Invariance of R1 and R2
[Homogeneous Scaling] Let x, D ∈ Xn and c ∈ R \ {0}. Then:

  (i) R1 (cx, D) = R1 (x, D) and R1 (x, cD) = R1 (x, D).

 (ii) R2 (cx, D) = R2 (x, D) and R2 (x, cD) = R2 (x, D).

Proof. For R1 , both numerator and denominator scale quadratically in c, which cancels in the
normalized squared correlation. For R2 , the tier energy fractions Ex (Kd ) are ratios of sums of
squared magnitudes; scaling x or D by c scales numerator and denominator by the same factor,
leaving the fraction unchanged. Thus R2 is scale-invariant in both arguments.

D.2    Rotation Invariance
[Rotation Invariance] Let Tτ be rotation by τ ticks. Then

                      R2 (Tτ x, Tτ D) = R2 (x, D),        R3 (Tτ x, Tτ D) = R3 (x, D).

Proof. In the Fourier domain, rotation multiplies all coefficients x̂[k] and D̂[k] by the same phase
e−2πikτ /n . Tier energies depend on squared magnitudes, which are invariant under phase; thus R2
is invariant. Phase differences in R3 involve arg x̂[k] − arg D̂[k], which is unaffected by adding the
same phase to both, so R3 is also invariant.

   These invariance and norm properties justify the use of R as a structural measure of fit in the
PIRDS training objective.

Summary. The results in this appendix provide the detailed spectral and operator-norm under-
pinnings for the PIRDS implementation. Projector identities formalize tier separation, operator
norm bounds give explicit contraction conditions for evolution operators, the orthogonality penalty
enhances identifiability, and the resonance functional’s invariances ensure that the training objective
reflects structural similarity rather than trivial rescalings or phase shifts.


                                                     17
References
 [1] Claude Berge. Hypergraphs: Combinatorics of Finite Sets, volume 45 of North-Holland Math-
     ematical Library. North-Holland, Amsterdam, 1989.

 [2] Alain Bretto. Hypergraph Theory: An Introduction. Mathematical Engineering. Springer,
     Cham, 2013.

 [3] Dengyong Zhou, Jiayuan Huang, and Bernhard Schölkopf. Learning with hypergraphs: Clus-
     tering, classification, and embedding. Advances in Neural Information Processing Systems, 19,
     2006.

 [4] Joshua Cooper and Aaron Dutle. Spectra of uniform hypergraphs. Linear Algebra and its
     Applications, 436(9):3268–3293, 2012.

 [5] David I. Shuman, Sunil K. Narang, Pascal Frossard, Antonio Ortega, and Pierre Vandergheynst.
     The emerging field of signal processing on graphs: Extending high-dimensional data analysis
     to networks and other irregular domains. IEEE Signal Processing Magazine, 30(3):83–98, 2013.

 [6] Antonio Ortega, Pascal Frossard, Jelena Kovačević, José M. F. Moura, and Pierre Van-
     dergheynst. Graph signal processing: Overview, challenges, and applications. Proceedings
     of the IEEE, 106(5):808–828, 2018.

 [7] Godfried T. Toussaint. The Geometry of Musical Rhythm: What Makes a “Good” Rhythm
     Good? CRC Press, Boca Raton, 2013.

 [8] Justin London. Hearing in Time: Psychological Aspects of Musical Meter. Oxford University
     Press, New York, 2 edition, 2012.

 [9] David Temperley. The Cognition of Basic Musical Structures. MIT Press, Cambridge, MA,
     2001.

[10] E. Bjorklund. The theory of rep-rate pattern generation in the sns timing system. Technical
     report, Spallation Neutron Source, Oak Ridge National Laboratory, 2003. SNS Technical Note;
     widely cited in the “Euclidean rhythms” literature.

[11] Fred Lerdahl and Ray Jackendoff. A Generative Theory of Tonal Music. MIT Press, Cambridge,
     MA, 1983.

[12] Eric D. Scheirer. Tempo and beat analysis of acoustic musical signals. Journal of the Acoustical
     Society of America, 103(1):588–601, 1998.

[13] Simon Dixon. Automatic extraction of tempo and beat from musical recordings. Journal of
     New Music Research, 30(1):39–58, 2001.

[14] Anssi P. Klapuri, Antti Eronen, and Jarmo Astola. Analysis of the meter of acoustic musical
     signals. IEEE Transactions on Audio, Speech, and Language Processing, 14(1):342–355, 2006.

[15] Franz Baader and Tobias Nipkow. Term Rewriting and All That. Cambridge University Press,
     Cambridge, 1999.

[16] Przemyslaw Prusinkiewicz and Aristid Lindenmayer.         The Algorithmic Beauty of Plants.
     Springer, New York, 1990.


                                                 18
[17] Elias M. Stein and Rami Shakarchi. Complex Analysis, volume 2 of Princeton Lectures in
     Analysis. Princeton University Press, Princeton, 2003.

[18] Nicholas M. Katz and Peter Sarnak. Random Matrices, Frobenius Eigenvalues, and Monodromy,
     volume 45 of AMS Colloquium Publications. American Mathematical Society, Providence, RI,
     1999.

[19] Tom M. Apostol. Modular Functions and Dirichlet Series in Number Theory, volume 41 of
     Graduate Texts in Mathematics. Springer, New York, 2 edition, 1990.

[20] Jean-Pierre Serre. A Course in Arithmetic, volume 7 of Graduate Texts in Mathematics.
     Springer, New York, 1973.

[21] E. C. Titchmarsh. The Theory of the Riemann Zeta-Function. Oxford University Press, Oxford,
     2 edition, 1986. Revised by D. R. Heath-Brown.

[22] Stéphane Mallat. A Wavelet Tour of Signal Processing. Academic Press, Burlington, MA, 3
     edition, 2008.

[23] Alan V. Oppenheim and Ronald W. Schafer. Discrete-Time Signal Processing. Prentice Hall,
     Upper Saddle River, NJ, 3 edition, 2009.

[24] James W. Cooley and John W. Tukey. An Algorithm for the Machine Calculation of Complex
     Fourier Series, volume 19. AMS, 1965.

[25] Robert G. Gallager. Stochastic Processes: Theory for Applications. Cambridge University
     Press, Cambridge, 2013.

[26] Anatole Katok and Boris Hasselblatt. Introduction to the Modern Theory of Dynamical Systems,
     volume 54 of Encyclopedia of Mathematics and its Applications. Cambridge University Press,
     Cambridge, 1995.

[27] Arkady Pikovsky, Michael Rosenblum, and Jürgen Kurths. Synchronization: A Universal
     Concept in Nonlinear Sciences. Cambridge University Press, Cambridge, 2001.

[28] Marina Meilă and Jianbo Shi. A random walks view of spectral segmentation. AI and Statistics
     (AISTATS), 2001.

[29] Mikhail Belkin and Partha Niyogi. Laplacian eigenmaps for dimensionality reduction and data
     representation. In Advances in Neural Information Processing Systems, volume 15, 2003.




                                               19
