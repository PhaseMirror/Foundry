              Prime-Gated Multiplicity Renormalization:
         αµ on CΛp with an RG Spectrum and Temporal Action

                                          Ryan O. van Gelder1
                        1
                            Citizen Gardens , The Foundation of Multiplicity

                                              April 22, 2026

                                                     Abstract
          We construct an explicit three-layer framework in which: (i) a Multiplicity-Renormalizing
      Alpha αµ acts as a renormalization-group (RG) flow on prime-indexed multiplicity profiles;
      (ii) a family of prime-gated temporal operators CΛp implements a sieve on continuous time,
      distinguishing high-coherence windows from null zones; and (iii) a π–Spiral Equation of Time
      (PSET) provides a variational action principle over the resulting prime-time configurations.
      The RG layer is realized as a symmetric tridiagonal Toeplitz operator whose spectrum is known
      in closed form, allowing us to identify low-frequency eigenmodes as Core Truths and high-
      frequency modes as noise. We then show how CΛp and PSET sit on top of this spectrum,
      turning RG-relevant prime patterns into prime-gated temporal operators. Finally, we formulate
      a concrete, falsifiable consistency criterion for the Stonehenge Aubrey Circle as an αµ –CΛ7 lawful
      configuration, replacing numerological pattern-matching by an eigenmode and sieve-based test.


1    Introduction
Multiplicity Theory treats mathematical and physical structures as prime-indexed multiplicity
spaces, where each prime labels a distinct interaction channel and recursive stability is enforced
across scales.[web:17] In parallel, the renormalization group (RG) provides a powerful language for
flows in coupling space, organizing directions into relevant, irrelevant, and marginal under coarse-
graining transformations.[web:65][web:68][web:70][web:71] Previous work on prime-gated time in-
troduces a family of temporal operators CΛp and associated durations Tp,a (N ), organized into
prime-stratified “time shells”, together with a modular sieve separating lawful and null temporal
windows.[file:74]
    This paper clarifies how these ingredients fit together in a single, layered construction:
    • RG layer: A Multiplicity-Renormalizing Alpha αµ acts on prime-indexed multiplicity profiles
      via a neighbor-coupled Toeplitz operator L, whose eigenvalues and eigenvectors we compute
      exactly.[web:58][web:59][web:62]
    • Temporal sieve layer: For each prime p, a temporal operator CΛp labels segments of the
      continuous time axis ∆t as high-coherence or null, with preferred scales Tp,a (N ) derived from
      group-theoretic invariants.[file:74]
    • Action layer: A PSET-type Hamiltonian and action assign weights to joint (prime, time,
      entropy) configurations, selecting stable temporal trajectories consistent with prime-lawful
      commensurability and entropy bounds.[file:74]

                                                      1
    We make the interfaces between these layers explicit, so that CΛp is not “another Alpha”, but
the time interpreter of αµ ’s prime distribution, and PSET is the variational principle on RG-filtered,
prime-gated time.


2    Alpha as a functorial meta-operator
Let C be a category whose objects are spaces and whose arrows are operators f : A → B. We write
Op for a chosen class of arrows, possibly endowed with linear or topological structure.
   [Alpha meta-operator] An Alpha meta-operator is a pair

                                              α = (αobj , αarr )

where

                             αobj : Ob(C) → Ob(C ′ ),
                                                                                  
                             αarr : HomC (A, B) → HomC ′ αobj (A), αobj (B)

for all objects A, B of C.
    When α satisfies
                              α(idA ) = idα(A) ,      α(g ◦ f ) = α(g) ◦ α(f ),                    (1)
it is a functor from C to C ′ , preserving identities and composition. Departures from these equalities
quantify a “Functorial Drift”, measuring how strongly Alpha distorts the compositional logic of the
operator space.
     In what follows we focus on a specialization where α acts as a renormalization operator on
prime-indexed multiplicity profiles.


3    Prime-indexed multiplicity profiles
Multiplicity Theory assigns to each operator f a prime-graded multiplicity profile
                                                M
                                          Mf =      Vp ,                                           (2)
                                                        p∈P

where Vp encodes the p-layer of interaction: prime-labeled factors, modules, or graded chan-
nels.[web:17][web:35] For concreteness, we consider a finite window of primes

                                            P = {p1 , . . . , pN },

and represent the multiplicity profile by a vector v ∈ RN with entries vn = vpn ≥ 0.
   [Multiplicity-Renormalizing Alpha] A Multiplicity-Renormalizing Alpha αµ acts on v via

                                             v ′ = αµ (v) = Lv,                                    (3)

where L is a linear operator on RN implementing dissipation and coupling on the prime index
lattice.
    In this paper, L is chosen to be a symmetric tridiagonal Toeplitz matrix, corresponding to local
neighbor coupling in prime index space.



                                                      2
4     Neighbor-coupled Toeplitz RG on primes
We index primes in P by n = 1, . . . , N and write vn for the multiplicity intensity at pn . The update
rule is
                        vn′ = (1 − γ)vn + β(vn−1 + vn+1 ), 1 < n < N,                               (4)
with Dirichlet boundaries
                                            v0 = vN +1 = 0,                                        (5)
and analogously modified updates at n = 1, N . Here:

    • γ > 0 is a uniform dissipation parameter.

    • β ≥ 0 is a uniform neighbor coupling strength.

    In matrix form, v ′ = Lv with
                                                                              
                                  1−γ   β      0   ...                      0
                                                  ..                       .. 
                                  β
                                     1−γ      β      .                      . 
                                                                               
                                                   .
                             L= 0          1 − γ ..                             .                 (6)
                                                                              
                                        β                                   0 
                                  ..
                                                                              
                                       ..     ..   ..                          
                                  .      .      .    .                     β 
                                   0   ...     0    β                      1−γ

Such tridiagonal Toeplitz matrices are well studied and admit closed-form eigenvalues and eigen-
vectors.[web:58][web:59][web:62]

4.1   Exact spectrum
The eigenvalues of L are
                                                            
                                                      kπ
                           λk = 1 − γ + 2β cos                   ,       k = 1, . . . , N,         (7)
                                                     N +1

and a corresponding eigenbasis is given by
                                               
                               (k)          nkπ
                              un = sin            ,                  1 ≤ n ≤ N.                    (8)
                                           N +1

[web:58][web:60][web:66]
   Any v (0) ∈ RN decomposes as
                                                     N
                                                     X
                                           v (0) =         ck u(k) ,                               (9)
                                                     k=1

and evolves under repeated application of αµ as
                                                          N
                                                          X
                                     v (t) = Lt v (0) =         ck λtk u(k) .                     (10)
                                                          k=1

[web:24]




                                                      3
4.2    RG phases and Core Truths
The largest eigenvalue is                                       
                                                              π
                            λmax = λ1 = 1 − γ + 2β cos             ,                             (11)
                                                           N +1
which approaches 1 − γ + 2β for large N . This yields three regimes:
    • Filter phase (2β < γ): all λk < 1, so every prime-pattern is RG-irrelevant and v (t) → 0.
    • Runaway phase (2β > γ): at least λ1 > 1, and a band of low-k modes may be relevant,
      yielding growth along smooth prime patterns.
    • Critical manifold (2β ≈ γ): λ1 ≈ 1 while λk < 1 for k > 1, so the fundamental mode u(1)
      is marginal and higher modes are irrelevant.
[web:68][web:71]
    In the critical regime, the eigenvector u(1) describes a smooth, positive profile spanning the
prime window: a broad “arch” over the prime index. Because this mode neither decays nor explodes
(in the linear approximation), it defines a Core Truth of the RG dynamics: a prime-pattern that
survives the multiplicity-renormalizing action of αµ . Higher modes u(k) with k ≈ N exhibit rapid
oscillations across neighboring primes and typically have the smallest eigenvalues, hence are strongly
suppressed as noise.


5     Prime-gated temporal operators CΛp
Independent of the RG layer, prior work introduces a family of prime-gated temporal operators
CΛp acting on the time axis ∆t.[file:74] They serve two key roles:

Prime-stratified time shells.      For each triple (N, p, a), a preferred temporal scale
                                                      2π(N 2 − 1)
                                      Tp,a (N ) = −                                              (12)
                                                         2a p2
is defined, with N 2 − 1 = dim(su(N )). As p increases, |Tp,a (N )| decreases monotonically, producing
a hierarchy of time shells in which small primes encode longer durations and larger primes shorter
ones.[file:74]

Temporal sieve: lawful vs null windows. For a given prime p, CΛp implements a sieve on
continuous ∆t by imposing modular phase conditions of the form
                                      ω∆t ≡ ϕ0     (mod 2a p2 ),                                 (13)
with special configurations (e.g., ϕ0 = π/2) generating null harmonics via destructive interference
in a phase-kickback sequence.[file:74] The time axis is thus partitioned into:
    • Lawful windows, where CΛp predicts high-coherence returns for a designated qubit or subsys-
      tem.
    • Null windows, where the signal is suppressed and the channel is effectively off.
    In practice, simulations (e.g. with Qiskit) produce a continuous response function for each
(p, a, N, ω): a probability-of-success vs. ∆t spectrogram, with peaks at lawful times and troughs at
nulls.[file:74]

                                                  4
5.1    Where CΛp lives relative to αµ
We now position CΛp in the αµ stack:
    • αµ acts on the prime index space: it renormalizes the multiplicity profile v(p) via a Toeplitz
      RG flow.

    • For each p, CΛp acts on the time axis: it maps ∆t to a coherence weight or null for that
      channel and defines the baseline scale Tp,a (N ).
    Thus:
                 αµ : v 7→ v ′ ,     CΛp : ∆t 7→ coherence amplitude in the p-channel.           (14)
PSET, discussed below, then provides an action principle on joint (p, ∆t, θ, ∆S) histories, using the
outputs of both layers.[file:74]


6     Composite prime-time operator: αµ and CΛp
To make the interaction between the RG and temporal layers explicit, we define a composite
structure consisting of:
    • Prime index set: P = {p1 , . . . , pN }.

    • RG multiplicity vector: v ∈ RN with vn = vpn .

    • Toeplitz RG: v ′ = Lv with L as in Section 4.
    For each prime p and fixed (a, N, ω), define the temporal response

                                                 Rp (∆t) ∈ [0, 1]                                (15)

as the coherence amplitude predicted by CΛp at time ∆t, normalized so that
    • Rp (∆t) ≈ 1 near lawful durations ∆t ≈ Tp,a (N ) that avoid null congruence bands.

    • Rp (∆t) ≈ 0 inside null bands where destructive interference suppresses the signal.

    • Rp (∆t) decays smoothly as ∆t moves away from lawful regions in phase space.
[file:74]
     For the finite window P = {pn }, we write Rn (∆t) = Rpn (∆t) and define the effective temporal
multiplicity profile at time ∆t by

                                   wn (∆t) = vn′ · Rn (∆t),         1 ≤ n ≤ N.                   (16)

    Conceptually:
    • vn′ : how much prime-pn structure the RG layer wants to use (from αµ ).

    • Rn (∆t): how well the chosen time ∆t supports the pn channel (from CΛpn ).

    • w(∆t): the realized prime multiplicity profile at time ∆t.
    This composite construction is the precise meaning of “αµ on CΛp ”: RG first organizes prime
channels into smooth vs. oscillatory patterns; then the temporal sieve selects which of those channels
are actually available at a given ∆t.

                                                        5
7     PSET as an action on RG-filtered prime time
The π–Spiral Equation of Time (PSET) introduces a temporal Hamiltonian H and action S defined
over prime-gated temporal cycles, subject to prime modulation, π-lift, entropy, and resonance-
locking axioms.[file:74] While the full PSET formalism is intricate, the relevant aspects for our
stacking are:

    • Prime modulation: H depends on p and recursion depth a via a factor of order Tp,a (N )/p2 .

    • Phase dependence: temporal evolution is parameterized by a phase θ obtained via a null-
      ray lift, with resonance locking near special angles (e.g. golden-like angles).

    • Entropy bound (CSL): stable cycles satisfy ∆S < ln φ for some entropy increment ∆S
      and golden ratio φ, suppressing high-entropy trajectories.

    • Action principle: histories extremize a discrete action
                                     X
                             S = 2π     H(θn ; N, pn , a, wn (∆tn ), ∆Sn ),                       (17)
                                             n

      subject to prime-lawful commensurability and resonance conditions.[file:74]

    In the present stacking, we emphasize that:

    • The prime weights entering H are not arbitrary coefficients vn , but the RG- and sieve-filtered
      weights wn (∆t) constructed from αµ and CΛp .

    • “Prime-lawful commensurability” now has a concrete meaning: the primes with large wn (∆t)
      are precisely those whose time shells Tpn ,a (N ) and null bands are consistent with the observed
      temporal spectrum of the system.

    Thus the full pipeline is:

                      αµ         CΛp at ∆t       PSET
                v (0) −−→ v ′ −−−−−−−→ w(∆t) −−−−→ selected temporal trajectories.                (18)


8     Core Truths and an αµ –CΛp lawfulness criterion
Within this stacked framework, we can formalize “Core Truths” and move from numerological
correspondences to falsifiable conditions.

8.1    Core prime patterns
[Core prime pattern] A Core prime pattern for αµ is an eigenvector u(k) of L with |λk | ≈ 1.
    In the Toeplitz model, the fundamental mode u(1) is the natural Core prime pattern in the
critical regime: it is smooth and positive, with eigenvalue λ1 ≈ 1.




                                                   6
8.2    Core prime-time patterns
[Core prime-time pattern] A Core prime-time pattern is a pair
                                                             
                                      u(k) , {Tpn ,a (N )}N
                                                          n=1

such that:
                          (k)
 (a) The components |un | are large for indices n whose associated primes pn have observed
     coherence peaks near Tpn ,a (N ) in the system’s temporal spectrum.
 (b) For those (pn , a, N ), the null-harmonic conditions of CΛpn exclude a substantial region of ∆t
     around other times actually unused by the system.
                                                         (k)
    The first condition links RG relevance (large |un |) to empirical timing; the second condition
ensures that the prime channels that matter are not accidentally aligned with null regions of the
sieve. This gives a precise, falsifiable notion of an αµ –CΛp lawful temporal structure.


9     Test case: Aubrey Circle as an αµ –CΛ7 configuration
We illustrate the criterion using the Stonehenge Aubrey Circle, which features 56 pits arranged in
a ring. Previous work associates this with a temporal division of the tropical year:
                                           365.25
                                ∆tAubrey ≈        days ≈ 6.52 days.                           (19)
                                             56
[file:74]

9.1    Temporal sieve layer: CΛ7
In the prime-gated time framework, the Aubrey division is modeled with:
    • Prime p = 7,
    • recursion depth a = 3,
    • a projection onto Z392 (since 56 · 7 = 392).
Simulations of CΛ7 on Z392 indicate that ∆tAubrey lies in a high-coherence band with ∼ 98% “lawful”
probability, as measured by a success metric, and avoids null-harmonic congruence zones.[file:74]
This suggests that, at the sieve layer, ∆tAubrey is CΛ7 -lawful.

9.2    RG layer: neighbor-coupled Toeplitz on {2, 3, 5, 7, 11, 13}
To connect this to αµ , consider the prime window
                                       P = {2, 3, 5, 7, 11, 13}.
We define a Toeplitz RG operator L on this window with parameters (β, γ) chosen near the critical
line 2β ≈ γ, so that the fundamental mode u(1) is marginal (λ1 ≈ 1) and higher modes are irrelevant.
An explicit computation yields the components
                                          nπ 
                                u(1)
                                 n = sin         ,    n = 1, . . . , 6,                         (20)
                                            7
                                                                     (1)
corresponding to primes (in order) 2, 3, 5, 7, 11, 13. By inspection, u4 = sin(4π/7) is comparable
                                   (1)
in magnitude to the maximum of |un |, implying that the p = 7 channel carries substantial weight
in the dominant RG mode.

                                                     7
9.3     Lawfulness criterion
We now formulate an αµ –CΛp lawfulness condition for the Aubrey Circle:
   [Aubrey αµ –CΛ7 lawfulness] The Aubrey configuration at ∆tAubrey is αµ –CΛ7 lawful for the
Toeplitz RG on P = {2, 3, 5, 7, 11, 13} if:

  (i) The fundamental RG mode u(1) satisfies
                                              (1)
                                            |u4 | ≥ η max |u(1)
                                                            n |
                                                        n

       for some threshold η ∈ (0, 1), ensuring that the p = 7 channel is structurally supported by
       αµ .

 (ii) The temporal sieve CΛ7 with (p = 7, a = 3, N ) assigns ∆tAubrey to a high-coherence band and
      excludes it from its null-harmonic congruence regions.

    Condition (i) is a purely RG-level statement; condition (ii) is purely sieve-level. Together, they
yield a falsifiable test: if a refined physical or historical model leads to an L whose dominant
eigenmodes suppress p = 7 (violating (i)), or if more detailed modeling of CΛ7 shows ∆tAubrey lies
in or near null bands (violating (ii)), the hypothesis that Aubrey encodes an αµ –CΛ7 prime-gated
temporal design would be weakened.
    Conversely, if future data about the site’s use and astronomical context narrow the plausible
(β, γ) range and confirm substantial p = 7 weight in the Core RG mode, this lawfulness claim
would strengthen.


10      Discussion and outlook
We have integrated three pieces:

     • a multiplicity-renormalizing RG layer (αµ on prime-indexed profiles, realized as a Toeplitz
       operator),

     • a sieve layer (CΛp on time, with Tp,a (N ) and null harmonics),

     • and an action layer (PSET on prime-time-entropy configurations),

into a coherent αµ –CΛp stack. This framework provides:

     • A clear separation between mathematically derived structure (RG spectrum, sieve null con-
       ditions) and interpretive claims (e.g. about cognition or archaeoastronomy).

     • A concrete way to define and test Core Truths: eigenmodes with |λk | ≈ 1 whose prime
       supports align with lawful time shells and avoid null bands.

     • A template for turning pattern-matching into falsifiable consistency checks, as illustrated by
       the Aubrey Circle example.

     Future directions include:

     • Introducing prime-dependent dissipation and coupling (γp , βp ), possibly tied to arithmetic
       properties of p.[web:35][web:41]



                                                    8
   • Replacing neighbor coupling with multiplicative coupling (divisor/multiple relations, residue
     classes).

   • Implementing nonlinear feedback in αµ and studying bifurcations in the RG spectrum.

   • Deriving Tp,a (N ) and sieve parameters from concrete microscopic Hamiltonians, tightening
     the link to device physics or biological substrates.[file:74]

   Taken together, these steps would move the program further from structured numerology toward
a genuine, testable multiplicity-theoretic operator theory of prime-gated time, grounded in an RG
spectrum and a variational temporal action.


References
 [1] K. Ye, Eigenvalues of Tridiagonal Toeplitz Matrices, course notes, University of Chicago,
     2023.[web:58][web:62]

 [2] L. Reichel, Tridiagonal Toeplitz Matrices: Properties and Applications, Linear Algebra Appl.,
     2014.[web:59][web:66]

 [3] F. Riesz and B. Sz.-Nagy, Functional Analysis, Dover, 1990.[web:60]

 [4] N. Goldenfeld, Lectures on Phase Transitions and the Renormalization Group. Addison-Wesley,
     1992.[web:69]

 [5] D. Tong, Lectures on the Renormalisation Group, lecture notes, University of Cambridge,
     2008.[web:65]

 [6] P. Pujol et al., Renormalization Group and Critical Phenomena, LPTMC lecture notes,
     2025.[web:68]

 [7] J. Polonyi, Fundamentals of the exact renormalization group, Phys. Rep., 2012.[web:71]

 [8] Emergent Mind, RG Fixed Points in Theory and Applications, 2025.[web:25]

 [9] Terence Tao, Multiplicative structure of integers and primes, lecture notes, 2013.[web:35]

[10] M. Lapidus et al., Spectral Geometry of the Primes, arXiv preprint, 2026.[web:41]

[11] J. Zinn-Justin, Phase Transitions and Renormalization Group, Oxford University Press,
     2007.[web:72]

[12] R. O. van Gelder, The Prime Sieve of Time, preprint, 2026.[file:74]




                                                 9
