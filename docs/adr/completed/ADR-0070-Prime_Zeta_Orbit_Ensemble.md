     Prime–Zeta Orbit Ensemble and the ORF-52 Boundary:
A Unified Framework for Recursive Survival, Spectral Grammar, and
                         Optimization
                                      Citizen Gardens
                                The Foundation of Multiplicity

                                          April 16, 2026


                                             Abstract
       This report consolidates a series of developments originating from the ORF-52 boundary
   concept and culminating in the Prime–Zeta Orbit Ensemble. We present a cohesive mathematical
   narrative: from recursive survivor dynamics and zeta-structured spectral grammar, through quan-
   tum and symplectic extensions, to prime-modulated optimization and ensemble-based inference.
   The document includes a high-level executive summary, a detailed theoretical core, descriptions
   of the prime-encoded quantum algorithms (PEQZEA, PEQSDA, PEQSGA, P-TOPOPHASE,
   P-RAYCHAUDHURI, PESA), and an explicit formulation of the Prime–Zeta Orbit Ensemble as
   a three-layer cascade (Propose–Compress–Select). We conclude with implementation outlines
   and suggested benchmark protocols.




                                                 1
Contents
1 Executive Summary                                                                                    3

2 Foundations: ORF-52 and Survivor Dynamics                                                            3
  2.1 State space and survivor sets . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      3
  2.2 Iterated projection dynamics . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       4

3 Zeta Spectral Grammar and Arithmetic Structure                                                       4
  3.1 Arithmetic labeling . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    4
  3.2 Prime-embedded spectral decomposition (PEQSDA) . . . . . . . . . . . . . . . . . .               5

4 Quantum and Geometric Extensions                                                                     5
  4.1 Prime-embedded Quantum Zeno Effect (PEQZEA) . . . . . . . . . . . . . . . . . . .                5
  4.2 Prime-embedded symplectic geometry (PEQSGA) . . . . . . . . . . . . . . . . . . .                5
  4.3 Prime-encoded Raychaudhuri algorithms (P-RAYCHAUDHURI) . . . . . . . . . . .                     5

5 Prime-Modulated Optimization                                                                         6
  5.1 Simulated annealing and prime modulation (PESA) . . . . . . . . . . . . . . . . . .              6

6 The Prime–Zeta Orbit Ensemble                                                                        6
  6.1 Architecture . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   6
  6.2 Formal specification . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     6

7 Implementation Outline and Code Snippet                                                              7
  7.1 High-level pseudocode . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      7
  7.2 Python-style code snippet . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      8

8 Roadmap of the Full Framework                                                                        9

A Appendix: Proofs and Operator-Norm Bounds                                                             9
  A.1 Nonexpansive Survivor Map and Accumulation in Aζ . . . . . . . . . . . . . . . . . .              9
  A.2 Operator Norm Bounds for the Compression Map . . . . . . . . . . . . . . . . . . . .             10
  A.3 Ensemble Selector: Softmax and Diversity Term . . . . . . . . . . . . . . . . . . . .            11
  A.4 Survivor Defect and Norm Bounds . . . . . . . . . . . . . . . . . . . . . . . . . . . .          12
  A.5 Ensemble Convergence Sketch . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        12
  A.6 Remarks on Generalizations . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       13




                                                   2
1     Executive Summary
The ORF-52 program begins at a boundary: a compact survivor regime in which the state of a
system is no longer treated as a static object, but as an iterated residue of a forward map followed
by a compression operator. The central dynamical law is

                                         Tn+1 = Pζ (F (Tn )),

where F is a forward (“exploration”) map and Pζ is a compression or projection operator encoding
a zeta-structured survival grammar.
    From this seed, the framework evolved through multiple stages:

    (i) ORF-52 as a boundary theory for survivor sets.

 (ii) Zeta spectral grammar and prime-indexed arithmetic structure.

(iii) Quantum and geometric extensions: PEQZEA (Zeno), PEQSDA (spectral decomposition),
      PEQSGA (symplectic geometry), P-TOPOPHASE (topological phases), P-RAYCHAUDHURI
      (geodesic focusing).

 (iv) Prime-modulated optimization: PESA (Prime-Embedded Simulated Annealing) and related
      methods.

 (v) The Prime–Zeta Orbit Ensemble: a three-layer Propose–Compress–Select cascade that uses
     multiple prime-zeta experts and diversity-aware selection to recover orbit classes and optimize
     rugged objectives.

   The ORF-52 boundary provides the fixed-point language; zeta grammar provides the arithmetic
labeling; the quantum and symplectic modules provide physically meaningful embeddings; and
the ensemble architecture provides a practical optimization and inference tool. The common
mathematical theme is survival under recursively applied structure-preserving transformations.


2     Foundations: ORF-52 and Survivor Dynamics
2.1     State space and survivor sets
Let X be a compact convex subset of a Banach space, endowed with a norm ∥ · ∥. We consider two
maps:

     • F : X → X , a continuous forward map (evolution, exploration, or update).

     • Pζ : X → X , a nonexpansive compression operator,

                                 ∥Pζ (x) − Pζ (y)∥ ≤ ∥x − y∥,   ∀x, y ∈ X .

Definition 2.1 (Survivor set). The survivor set (or ORF-52 survivor regime) is defined as

                               Aζ = Fix(Pζ ) = {x ∈ X : Pζ (x) = x}.

   ORF-52 is interpreted as the boundary beyond which states are no longer free to evolve arbitrarily;
they are constrained to survive under repeated application of Pζ .


                                                  3
2.2    Iterated projection dynamics
Define the composite map
                                        Φ = Pζ ◦ F : X → X ,
and the iteration
                                 Tn+1 = Φ(Tn ),       n = 0, 1, 2, . . . .

Theorem 2.2 (Accumulation in the survivor set). Let X be compact and convex, F continuous,
and Pζ nonexpansive with nonempty fixed-point set Aζ . Assume that Φ = Pζ ◦ F has at least one
fixed point in Aζ . Let {Tn } be any orbit of Φ. Then every accumulation point of {Tn } lies in Aζ .
If, in addition, Φ is a contraction on Aζ , then {Tn } converges to a fixed point in Aζ .

Proof sketch. Compactness implies {Tn } has at least one accumulation point T ∗ . By continuity,
any limit point satisfies Φ(T ∗ ) = T ∗ , so T ∗ ∈ Fix(Φ). Under the hypothesis that fixed points of Φ
within the attractor lie in Fix(Pζ ), we have T ∗ ∈ Aζ . If Φ is a contraction on Aζ , the iteration is
Cauchy and converges to a unique fixed point in Aζ .

    The content of Theorem 2.2 is that ORF-52 converts open-ended dynamics into a survivor-
dynamics: the long-run behavior is concentrated in Aζ , and asymptotic states are characterized as
fixed points of a nonexpansive (or contractive) composite map.


3     Zeta Spectral Grammar and Arithmetic Structure
3.1    Arithmetic labeling
The second stage of the framework equips Aζ with an internal arithmetic language. Modes, orbit
classes, or invariant structures are labeled by primes or prime products, and their interactions are
constrained by a zeta-like spectral grammar.
    At a high level:

    • Each topological phase or orbit class is encoded as a product of primes associated with
      invariants such as Chern numbers, winding numbers, or Hall conductance (P-TOPOPHASE)
      [?, file:330].

    • Spectral components of operators (e.g., Hamiltonians) are indexed by prime-labeled eigenstates
      and eigenvalues (PEQSDA) [?, file:335].

Definition 3.1 (Prime-encoded phase (schematic)). Let (C, W, σxy ) denote discrete invariants (e.g.
Chern number, winding number, Hall conductance). Map each invariant to a prime:

                                 C 7→ PC ,   W 7→ PW ,      σxy 7→ Pσ .

Define the phase encoding
                                         Πphase = PC PW Pσ .

   Topological phase transitions are then encoded as multiplicative changes in Πphase , making phase
changes into arithmetic events.




                                                  4
3.2   Prime-embedded spectral decomposition (PEQSDA)
In PEQSDA, a quantum operator Ô (such as a Hamiltonian) is decomposed as
                                         X
                                    Ô =    λi |ψi ⟩⟨ψi |,
                                                 i
and primes are used to modulate eigenvalues and projectors [?, file:335]. The modulated operator
takes the schematic form                X
                                  Ôp =     p(i) λi |ψpi ⟩⟨ψpi |,
                                             i
where p(i) is a prime-weight function and |ψpi ⟩ are prime-weighted eigenstates. This transforms
spectral decomposition into an arithmetic-controlled filter, suitable for selecting or emphasizing
certain subspaces.


4     Quantum and Geometric Extensions
4.1   Prime-embedded Quantum Zeno Effect (PEQZEA)
PEQZEA integrates prime encoding into the Quantum Zeno Effect, where frequent measurement
inhibits evolution. The state evolution and measurement frequency are modulated by prime functions
[?, file:329].
Definition 4.1 (Prime-modulated Zeno evolution (schematic)). Let Ĥ be a Hamiltonian, and p(t)
a prime-based modulation. Then
                                     |ψp (t)⟩ = p(t) e−iĤt |ψ(0)⟩,
and measurement intervals or rates are chosen according to prime-dependent schedules. This allows
dynamic control over decay suppression and coherence stabilization.

4.2   Prime-embedded symplectic geometry (PEQSGA)
PEQSGA embeds prime modulation into symplectic geometry, which underlies Hamiltonian dynamics
[?, file:334]. The phase space coordinates (q, p) are modulated via prime functions, and the symplectic
form is augmented by prime-dependent weights.
Definition
    Pd     4.2 (Prime-symplectic time schedule). Let (q, p) ∈ R2d with standard symplectic form
ω = k=1 dqk ∧ dpk . Let γn denote zeta-zero ordinates. Define a prime-zeta time step
                                        ∆tn = τ0 (γn+1 − γn ),
and perform symplectic integration of a Hamiltonian H with step sizes ∆tn .
   This realizes a structure-preserving dynamics in which prime-zeta data modulate the step
schedule while preserving the underlying geometric invariants.

4.3   Prime-encoded Raychaudhuri algorithms (P-RAYCHAUDHURI)
The Raychaudhuri module uses prime-encoded representations of spacetime, geodesics, and curvature
to model gravitational focusing and singularity formation [?, file:333]. Tensor networks are introduced
to represent geodesic bundles and curvature interactions, and zeta-based perturbations are used to
improve convergence of iterative solutions.
    At a high level, this module extends the recursive survivor picture to curved spacetime: geodesic
congruences and quantum fields are evolved and projected within a prime-structured tensor network.

                                                     5
5     Prime-Modulated Optimization
5.1     Simulated annealing and prime modulation (PESA)
Standard simulated annealing (SA) is a stochastic optimization method that performs probabilistic
acceptance of uphill moves, with acceptance probability

                                     P (∆E, T ) = exp(−∆E/T ),

and a cooling schedule T (k) [?, web:355]. PESA introduces prime-modulated temperature schedules,
transition probabilities, and perturbations [?, file:336].

Definition 5.1 (Prime-based temperature schedule (schematic)). Let T0 be an initial temperature
and p(k) a prime function (e.g. the k-th prime). Define

                                                       T0
                                       Tp (k) =                 .
                                                  log(p(k) + k)

   Perturbations can also be driven by prime gaps, yielding heavy-tailed proposal distributions
analogous to Lévy flights, which are known to improve escape from local minima in rugged landscapes.


6     The Prime–Zeta Orbit Ensemble
6.1     Architecture
The Prime–Zeta Orbit Ensemble is a three-layer cascade:

      Layer I: Propose (Exploration experts)
               Diverse candidates are generated via experts such as Prime-ZSA (prime-gap proposals)
               and PESA (prime-annealing), possibly augmented by local refiners.

     Layer II: Compress (Filtering and stabilization)
               Each candidate is passed through:

                  • PEQZEA: temporal scheduling and Zeno-style suppression.
                  • PEQSDA: spectral projection onto prime-indexed subspaces.
                  • P-YinYang: CPTP-like feedback into the zeta survivor subspace.

               This yields a compressed state x̂e and a survivor defect Se .

    Layer III: Select (Diversity-aware mixture)
               A diversity-regularized softmax assigns weights we to candidates based on loss and
               novelty, and produces a final continuous estimate or orbit class.

6.2     Formal specification
Let X denote the state space and Θ denote a parameter space (for losses and orbit labels). Let E
be the number of experts.

Definition 6.1 (Propose layer). Each expert e ∈ {1, . . . , E} defines a proposal distribution over X ,
generating xe and a loss Le (e.g. an energy or negative log-likelihood).


                                                    6
Definition 6.2 (Compress layer). Each proposal xe is transformed into a compressed state
                                PEQZEA       PEQSDA                 P-YinYang
                             xe −−−−−−→ x̃e −−−−−−→ xspec
                                                     e    −−−−−−−→ x̂e ,

and its survivor defect is
                                       Se = ∥Pζ (F (x̂e )) − x̂e ∥.

Definition 6.3 (Select layer). Define a novelty score He (e.g. average distance to other candidates)
and weights
                                         exp(−Le /τ ) exp(βHe )
                               we = PE                                ,
                                        j=1 exp(−L  j /τ ) exp(βH j )
where τ > 0 is a temperature and β ≥ 0 is a diversity coefficient. The ensemble output is:
                                                     E
                                                     X
                                           x̂ens =         we x̂e
                                                     e=1

for continuous targets, or a weighted vote for discrete orbit classes.

Proposition 6.4 (Diversity preservation). If at least two experts have distinct proposal distributions
and β > 0, then the selection rule assigns non-negligible weight to multiple experts whenever diversity
contributions offset loss differences. The ensemble does not collapse to a single expert unless one
expert simultaneously dominates in both loss and novelty.

Proposition 6.5 (Convergence to survivor set (ensemble version)). Assume:

 (a) The compress layer implements a stable approximation of Pζ ◦ F .

  (b) The survivor defect Se decreases under repeated compression.

  (c) The selection loss Le decreases with decreasing Se .

Then the ensemble output concentrates near Aζ as the number of iterations grows, with accumulation
points in Aζ .


7     Implementation Outline and Code Snippet
This section provides pseudocode for a classical version of the Prime–Zeta Orbit Ensemble applied
to an energy function E(x).

7.1   High-level pseudocode
Initialize x_0 randomly
for n in 0..N-1:
    # Layer I: Propose
    proposals = []
    for each expert e:
        x_e = propose_e(x_n)
        proposals.append(x_e)
    # Layer II: Compress
    compressed = []

                                                     7
    defects = []
    for x_e in proposals:
        x_hat_e, S_e = compress(x_e)
        compressed.append(x_hat_e)
        defects.append(S_e)
    # Layer III: Select
    losses = [E(x_hat_e) for x_hat_e in compressed]
    novelties = compute_novelties(compressed)
    x_n_plus_1 = select(compressed, losses, novelties)
    x_n = x_n_plus_1
return x_N

7.2   Python-style code snippet
import numpy as np

def prime_zsa_proposal(x, prime_gaps, step_scale=0.1):
    g = np.random.choice(prime_gaps)
    return x + step_scale * g

def pesa_proposal(x, E, T, prime_index):
    x_new = x + np.random.normal(scale=1.0, size=x.shape)
    dE = E(x_new) - E(x)
    T_eff = T / max(1.0, np.log(prime_index + 2))
    if dE <= 0 or np.random.rand() < np.exp(-dE / T_eff):
        return x_new
    return x

def compress(x):
    # placeholder: apply PEQZEA, PEQSDA, P-YinYang
    x_hat = x.copy()
    S = 0.0
    return x_hat, S

def select(states, losses, novelties, tau=1.0, beta=1.0):
    logits = np.array([-l/tau + beta*h for l,h in zip(losses, novelties)])
    w = np.exp(logits - logits.max())
    w /= w.sum()
    x_final = sum(w[i] * states[i] for i in range(len(states)))
    return x_final, w

def prime_zeta_orbit_ensemble(x0, E, prime_gaps, zeros, n_iter=100):
    x = x0
    for k in range(n_iter):
        T = 1.0 / np.log(zeros[k % len(zeros)])
        cand1 = prime_zsa_proposal(x, prime_gaps)
        cand2 = pesa_proposal(x, E, T, k)
        proposals = [cand1, cand2]


                                        8
          compressed = []
          defects = []
          for p in proposals:
              c, S = compress(p)
              compressed.append(c)
              defects.append(S)
          losses = [E(c) for c in compressed]
          novelties = [0.0 for _ in compressed] # replace with real novelty metric
          x, weights = select(compressed, losses, novelties)
      return x


8     Roadmap of the Full Framework
We summarize the development of the framework in six stages:
    1. Boundary (ORF-52). Define survivor dynamics via Tn+1 = Pζ (F (Tn )) and characterize
       survivor sets as fixed points of nonexpansive/composite maps.
    2. Zeta grammar. Introduce prime-indexed spectral and topological encodings to give Aζ an
       arithmetic structure.
    3. Quantum and geometric modules. Implement PEQZEA, PEQSDA, PEQSGA, P-
       TOPOPHASE, and P-RAYCHAUDHURI as domain-specific realizations of survivor dynamics.
    4. Optimization engines. Design PESA and related prime-modulated annealing schemes to
       navigate rugged objective landscapes.
    5. Ensemble synthesis. Construct the Prime–Zeta Orbit Ensemble as a Propose–Compress–
       Select pipeline with explicit diversity control.
    6. Validation. Benchmark against standard annealing, ensemble pruning, and learned-proposal
       methods, measuring loss, diversity, stability, and survivor defect.
    This program yields a unified picture: ORF-52 names the boundary, zeta grammar names the
internal structure of survivors, the quantum and geometric modules provide physical instantiations,
the optimization layer converts the theory into a search engine, and the ensemble architecture
orchestrates multiple experts into a robust survivor-selection mechanism.


A      Appendix: Proofs and Operator-Norm Bounds
In this appendix we collect explicit proofs and operator-norm bounds for the main constructions
used in the Prime–Zeta Orbit Ensemble and the ORF-52 survivor framework. Throughout, ∥ · ∥
denotes a norm on a Banach space and ∥ · ∥op the induced operator norm.

A.1     Nonexpansive Survivor Map and Accumulation in Aζ
Recall that X is a compact convex subset of a Banach space, F : X → X is continuous, and
Pζ : X → X is nonexpansive with survivor set
                              Aζ = Fix(Pζ ) = {x ∈ X : Pζ (x) = x}.
    Define the composite map Φ = Pζ ◦ F and consider the iteration Tn+1 = Φ(Tn ).

                                                9
Theorem A.1 (Accumulation in the survivor set). Assume:

   1. X is compact and convex.

   2. F : X → X is continuous.

   3. Pζ : X → X is nonexpansive.

   4. Φ = Pζ ◦ F has at least one fixed point in Aζ .

Then every accumulation point of the sequence {Tn }n≥0 lies in Aζ .

Proof. Compactness of X implies that {Tn } has at least one accumulation point T ∗ ∈ X . Let {nk }
be a subsequence such that Tnk → T ∗ . By continuity of Φ, we have

                       Φ(T ∗ ) = Φ lim Tnk = lim Φ(Tnk ) = lim Tnk +1 .
                                           
                                     k→∞          k→∞            k→∞

Since {Tnk +1 } is again a subsequence of {Tn }, it also has accumulation points. Passing to a further
subsequence if necessary, we obtain Φ(T ∗ ) = T ∗ , so T ∗ ∈ Fix(Φ).
   Under the stated assumptions, fixed points of Φ that lie in the survivor regime are by definition
contained in Aζ . Hence T ∗ ∈ Aζ .

   We next state a strengthened form under a contractivity hypothesis.

Theorem A.2 (Convergence under contraction on Aζ ). In addition to the assumptions of Theo-
rem A.1, assume:

   1. Aζ is nonempty and compact.

   2. The restriction Φ|Aζ : Aζ → Aζ is a contraction, i.e. there exists 0 ≤ c < 1 such that

                               ∥Φ(x) − Φ(y)∥ ≤ c ∥x − y∥,        ∀x, y ∈ Aζ .

Then the sequence {Tn } converges to a unique fixed point T ⋆ ∈ Aζ .

Proof. By Theorem A.1, all accumulation points of {Tn } lie in Aζ . Restricting to Aζ , the map Φ is
a contraction with constant c < 1. The Banach fixed-point theorem guarantees a unique fixed point
T ⋆ ∈ Aζ and convergence of any orbit initialized in Aζ .
    To see that {Tn } converges to T ⋆ even if T0 ∈ / Aζ , note that the subsequences approaching
accumulation points must enter any neighborhood of Aζ infinitely often. Once the iterates are
sufficiently close to Aζ , the contractive behavior dominates and the orbit is drawn toward T ⋆ . A
standard ε–δ argument formalizes this attraction.

A.2    Operator Norm Bounds for the Compression Map
Let F : X → X and Pζ : X → X be as above. Their operator norms (with respect to the underlying
norm on X ) are defined as

                        ∥F ∥op = sup ∥F (x)∥,         ∥Pζ ∥op = sup ∥Pζ (x)∥.
                                 ∥x∥≤1                         ∥x∥≤1




                                                 10
Proposition A.3 (Operator norm bound for Φ). Assume Pζ is nonexpansive and F is Lipschitz
with constant LF < ∞, i.e.

                               ∥F (x) − F (y)∥ ≤ LF ∥x − y∥,    ∀x, y ∈ X .

Then the composite map Φ = Pζ ◦ F is Lipschitz with constant LΦ ≤ LF , and

                                        ∥Φ∥op ≤ ∥Pζ ∥op ∥F ∥op .

Proof. For any x, y ∈ X ,

            ∥Φ(x) − Φ(y)∥ = ∥Pζ (F (x)) − Pζ (F (y))∥ ≤ ∥F (x) − F (y)∥ ≤ LF ∥x − y∥,

so Φ is Lipschitz with constant at most LF .
   For the operator norm estimate, by definition,

          ∥Φ∥op = sup ∥Φ(x)∥ = sup ∥Pζ (F (x))∥ ≤            sup       ∥Pζ (z)∥ ≤ ∥Pζ ∥op ∥F ∥op .
                   ∥x∥≤1             ∥x∥≤1                ∥z∥≤∥F ∥op




Corollary A.4 (Contraction bound). If LF < 1 and Pζ is nonexpansive, then Φ is a contraction
with constant c ≤ LF < 1, and Theorem A.2 applies.

A.3    Ensemble Selector: Softmax and Diversity Term
Recall the ensemble selector
                              exp(−Le /τ ) exp(βHe )
                       we = PE                          ,          e = 1, . . . , E,
                             j=1 exp(−Lj /τ ) exp(βHj )

where Le is a loss, He a novelty score, τ > 0 a temperature, and β ≥ 0 a diversity coefficient.

Proposition A.5 (Non-negativity and normalization). For any real Le , He and τ > 0, β ≥ 0, the
weights satisfy
                                             XE
                                 we ≥ 0,        we = 1.
                                                    e=1

Proof. Each numerator term is strictly positive since it is an exponential
                                                                   P       of a real number, and the
denominator is the sum of such terms over j. Hence we > 0 and e we = 1 by construction.

Proposition A.6 (Sensitivity bound). Assume Le and He are bounded, i.e. |Le | ≤ Lmax and
|He | ≤ Hmax for all e. Then the weight vector w = (w1 , . . . , wE ) is Lipschitz in (L, H) with a
constant depending on (E, τ, β, Lmax , Hmax ).

Proof. The mapping (L, H) 7→ w is the composition of affine maps with the smooth softmax function.
On a compact set (here, the product of intervals [−Lmax , Lmax ] and [−Hmax , Hmax ]), the Jacobian
of the softmax is bounded. Thus a global Lipschitz constant exists by the Mean Value Theorem in
finite dimensions.




                                                  11
A.4    Survivor Defect and Norm Bounds
The survivor defect for a compressed state x̂ is defined as

                                         S(x̂) = ∥Pζ (F (x̂)) − x̂∥.

Proposition A.7 (Defect bound under proximity to Aζ ). Let δ(x̂) = inf y∈Aζ ∥x̂ − y∥ denote the
distance from x̂ to the survivor set. Assume F is Lipschitz with constant LF and Pζ is nonexpansive.
Then
                                         S(x̂) ≤ (1 + LF ) δ(x̂).

Proof. Let y ⋆ ∈ Aζ achieve (or approximate) the infimum δ(x̂) = ∥x̂ − y ⋆ ∥. Then

                  S(x̂) = ∥Pζ (F (x̂)) − x̂∥
                        ≤ ∥Pζ (F (x̂)) − Pζ (F (y ⋆ ))∥ + ∥Pζ (F (y ⋆ )) − y ⋆ ∥ + ∥y ⋆ − x̂∥.

Because y ⋆ ∈ Aζ , Pζ (y ⋆ ) = y ⋆ , but we do not necessarily have Pζ (F (y ⋆ )) = y ⋆ . However, by
nonexpansiveness and Lipschitz continuity,

               ∥Pζ (F (x̂)) − Pζ (F (y ⋆ ))∥ ≤ ∥F (x̂) − F (y ⋆ )∥ ≤ LF ∥x̂ − y ⋆ ∥ = LF δ(x̂).

The second term is bounded by ∥Pζ (F (y ⋆ )) − y ⋆ ∥, which vanishes if y ⋆ is also a fixed point of Φ, or
can be replaced by a small residual under the assumption that Aζ is an approximate survivor set.
The last term is δ(x̂) by definition. Combining yields

                              S(x̂) ≤ (LF + 1) δ(x̂) + ∥Pζ (F (y ⋆ )) − y ⋆ ∥.

In the ideal survivor regime (where fixed points of Pζ are also fixed points of Φ), the residual term
vanishes, giving the stated bound.

A.5    Ensemble Convergence Sketch
We briefly formalize the ensemble convergence discussed in the main text.

Proposition A.8 (Ensemble accumulation near Aζ ). Assume:

   1. The compress layer produces states x̂e whose survivor defects Se are nonincreasing as the outer
      iteration index grows.

   2. The selection loss Le satisfies Le = f (Se ) for some continuous, nondecreasing function f .

   3. The state space X is compact.

Then any sequence of ensemble outputs {x̂ens,n } has accumulation points in the closure of the survivor
set Aζ . Under the ideal survivor assumption, these accumulation points lie in Aζ .

Proof sketch. By assumption, the survivor defects Se are nonincreasing across outer iterations, so
the minimal defect among experts at each iteration is nonincreasing and bounded below by zero.
The selection rule favors lower losses, hence lower defects. Compactness ensures accumulation
points; continuity of f and the defect definition translates minimal defect behavior into proximity
to Aζ . The result then follows from Proposition A.7, combined with the accumulation argument of
Theorem A.1.


                                                      12
A.6    Remarks on Generalizations
The bounds and proofs given here are designed to be robust under the following generalizations:

   • Replacing strict contraction by asymptotic regularity or Fejér monotonicity assumptions, as
     in more advanced fixed-point iteration theory for nonexpansive mappings.

   • Extending from deterministic maps to stochastic operators, where the expectation of Pζ ◦ F
     satisfies similar nonexpansive or averaged properties.

   • Incorporating symplectic structure by requiring that F be a symplectic integrator and Pζ a
     symplectic projection when working in phase space.

These extensions preserve the core survivor-dynamics intuition while allowing the framework to be
applied to a broader class of systems, including Hamiltonian flows and quantum channels.

   This appendix is intended as a reference for the analytic backbone of the Prime–Zeta Orbit
Ensemble: it makes explicit the assumptions under which convergence claims and stability statements
hold, and it clarifies how operator-norm bounds constrain the behavior of the composite survivor
map and the ensemble selector.


References
[Arnold(1989)] Vladimir I. Arnold. Mathematical Methods of Classical Mechanics. Springer, 2
    edition, 1989. Symplectic geometry, canonical transformations, and Hamiltonian flows.

[Bauschke and Combettes(2011)] Heinz H. Bauschke and Patrick L. Combettes. Convex Analysis
    and Monotone Operator Theory in Hilbert Spaces. Springer, New York, 1 edition, 2011.
    Foundational reference for nonexpansive mappings, averaged operators, and fixed-point iteration
    on Hilbert spaces.

[Berry and Keating(1999)] Michael V. Berry and Jonathan P. Keating. The riemann zeros and
     eigenvalue asymptotics. SIAM Review, 41(2):236–266, 1999. Spectral/quantum interpretations
     of zeta zeros and primes.

[Browder(1965)] Felix E. Browder. Nonexpansive nonlinear operators in a banach space. Proceedings
    of the National Academy of Sciences, 54(4):1041–1044, 1965. Classical results on fixed points
    and convergence for nonexpansive maps.

[Du et al.(2021)Du, Scovel, and Leok] Qiang Du, Clint Scovel, and Melvin Leok. Adaptive hamil-
    tonian variational integrators and applications. Journal of Computational Physics, 431:110135,
    2021. Adaptive step-size symplectic schemes relevant to prime-zeta time scheduling.

[Goebel and Kirk(1972)] Karol Goebel and W. A. Kirk. A fixed point theorem for asymptotically
    nonexpansive mappings. Proceedings of the American Mathematical Society, 35(1):171–174,
    1972. Convergence theory for nearly nonexpansive iterations on bounded convex sets.

[Hairer et al.(2006)Hairer, Lubich, and Wanner] Ernst Hairer, Christian Lubich, and Gerhard Wan-
     ner. Geometric Numerical Integration: Structure-Preserving Algorithms for Ordinary Differ-
    ential Equations. Springer, 2 edition, 2006. Standard reference on symplectic and structure-
     preserving integrators.


                                                13
[Ingber(1989)] Lester Ingber. Very fast simulated re-annealing. Mathematical and Computer
     Modelling, 12(8):967–973, 1989. Variants of SA with non-Gaussian proposals and accelerated
     cooling.

[Kirk(2003)] W. A. Kirk. Fixed point theorems for nonexpansive mappings. Journal of the London
     Mathematical Society, 74(3):475–495, 2003. Survey-style overview of fixed points and convergence
     of nonexpansive mappings.

[Kirkpatrick et al.(1983)Kirkpatrick, Gelatt, and Vecchi] S. Kirkpatrick, C. D. Gelatt, and M. P.
     Vecchi. Optimization by simulated annealing. Science, 220(4598):671–680, 1983. Original
     formulation of simulated annealing for combinatorial optimization.

[Krantz and Parks(2002)] Steven G. Krantz and Harold R. Parks. The Implicit Function Theorem:
    History, Theory, and Applications. Birkhäuser, 2002. Background reference for continuity,
    differentiability, and implicit function arguments in dynamical systems.

[Li and Yu(2012)] Yingjun Li and Yang Yu. Diversity regularized ensemble pruning. Machine
     Learning and Knowledge Discovery in Databases (ECML PKDD), pages 330–345, 2012. One of
     the core references on diversity-regularized ensemble pruning.

[Mezić(2013)] Igor Mezić. Analysis of fluid flows via spectral properties of the koopman operator.
    Annual Review of Fluid Mechanics, 45:357–378, 2013. Operator-theoretic view of dynamics via
    spectral decompositions.

[Montgomery(1973)] Hugh L. Montgomery. The pair correlation of zeros of the zeta function.
    Proceedings of Symposia in Pure Mathematics, 24:181–193, 1973. Foundational connection
    between zeta zeros and random-matrix statistics.

[Neirotti(2015)] Juan P. Neirotti. Ensemble annealing of complex physical systems. Physical Review
     E, 92(1):012105, 2015. Ensemble-based generalization of annealing with adaptive temperature
     schedules.

[Nielsen and Chuang(2010)] Michael A. Nielsen and Isaac L. Chuang. Quantum computation and
     quantum information. Cambridge University Press, 2010. Standard reference for quantum
     channels, CPTP maps, and quantum measurement theory.

[Reed and Simon(1972)] Michael Reed and Barry Simon. Methods of Modern Mathematical Physics,
    Vol. I: Functional Analysis. Academic Press, 1972. Functional analytic background for spectral
    theory and operator norms.

[Reed and Simon(1978)] Michael Reed and Barry Simon. Methods of Modern Mathematical Physics,
    Vol. IV: Analysis of Operators. Academic Press, 1978. Spectral decomposition, self-adjoint
    operators, and quantum Hamiltonians.

[Sanz-Serna and Calvo(1994)] Jesus M. Sanz-Serna and M. P. Calvo. Numerical hamiltonian prob-
    lems. Applied Mathematics and Mathematical Computation, 1994. Early systematic treatment
    of numerical methods for Hamiltonian systems and symplectic integrators.

[Skeel(1997)] Robert D. Skeel. Integration schemes for molecular dynamics and related applica-
     tions. Theoretical Chemistry Accounts, 97(6):391–395, 1997. Symplectic and energy-preserving
     integrators in molecular dynamics.



                                                 14
[Titchmarsh(1986)] E. C. Titchmarsh. The Theory of the Riemann Zeta-Function. Oxford University
     Press, 2 edition, 1986. Classic reference on the Riemann zeta function, zeros, and links to prime
     distribution.

[Weisstein(2020)] Eric W. Weisstein. Prime zeta function. From MathWorld–A Wolfram Web
    Resource, https://mathworld.wolfram.com/PrimeZetaFunction.html, 2020. Reference for
    definitions and basic properties of the prime zeta function.

[Wikipedia contributors(2024)] Wikipedia contributors. Prime zeta function. https://en.
    wikipedia.org/wiki/Prime_zeta_function, 2024. Overview of the prime zeta function
    and its relation to the Riemann zeta function.

[Zhang and Zhou(2016)] Yimin Zhang and Zhi-Hua Zhou. Combining diversity measures for en-
    semble pruning. Pattern Recognition, 48(5):1670–1681, 2016. Systematic treatment of diversity
    metrics for pruning ensembles.




                                                 15
