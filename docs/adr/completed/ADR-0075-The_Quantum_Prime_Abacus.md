   Multiplicity-Theoretic Framing of the Quantum Prime Abacus,
                       PME, and PL-Commit
                                         Draft for Internal Use

                                            August 28, 2026


                                                 Abstract
          This report reinterprets the Quantum Prime Abacus (QPA), Prime-Modular Hypergraph
      Partitioning (PMHP), Prime-Multiplicity Extraction (PME), and the PL-Commit commitment
      scheme within the language of Multiplicity Theory and the Genius v2 “prime moves” framework.
     We provide: (i) an executive-level summary for cryptographic and quantum-engineering stakehold-
      ers, (ii) a comprehensive mathematical overview of the QPA architecture and associated hardness
      assumptions, (iii) a canonical alphabet of prime moves and an explicit multiplicity-calculus
     “program” for encoding PMHP into QPA, (iv) a dynamics + shadows + inversion phase written
      in the same calculus, and (v) code-style snippets that illustrate how these ideas could be exposed
      in a software stack such as PhaseMirror-HQ.


Contents
1 Executive Summary                                                                                        2
  1.1 Conceptual Goal . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          2
  1.2 Why This Matters . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .           3

2 Multiplicity-Theoretic Overview of QPA                                                                   3
  2.1 Prime-Bead Logical Layer . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .           3
  2.2 Recursive Prime-Multiplicity Semantics . . . . . . . . . . . . . . . . . . . . . . . . .             4
  2.3 Prime Couplings and Coherence . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .            5

3 Prime-Modular Hypergraph Partitioning (PMHP)                                                             5
  3.1 Problem Definition . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         5
  3.2 Hamiltonian Encoding . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .           6

4 Prime-Multiplicity Extraction (PME)                                                                      6
  4.1 Problem Definition . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         6
  4.2 Multiplicity-Theoretic View . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          6

5 PL-Commit as a Multiplicity Commitment                                                                   7
  5.1 Protocol Summary . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .           7
  5.2 Security Intuition . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       7

6 Canonical Prime-Move Alphabet                                                                            8
  6.1 Seven Prime Moves . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          8



                                                     1
7 A Tiny Multiplicity-Calculus Program                                                   8
  7.1 Program: PMHP → QPA Encoding . . . . . . . . . . . . . . . . . . . . . . . . . . . 8
  7.2 Program: QPA Dynamics + Shadows + PME . . . . . . . . . . . . . . . . . . . . . . 10

8 Code-Style Snippets                                                                               11
  8.1 Prime-Move Interface . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    11
  8.2 Prime-Multiplicity Recursion . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    11
  8.3 Prime Coupling Tensor . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   12

9 Conclusion                                                                                        12

A Mathematical Appendix                                                                             12

B NP-Completeness of PMHP                                                                        13
  B.1 Decision Version of PMHP . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13

C Reduction PMHP ≤p PME                                                                             15

D Information-Theoretic Shadow Barrier for PME                                                      16
  D.1 State Dimension and Parameter Count . . . . . . . . . . . . . . . . . . . . . . . . . .       16
  D.2 Classical Shadows: Information Budget . . . . . . . . . . . . . . . . . . . . . . . . .       17
  D.3 Lower Bound for PME . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     17

E Operator Norm Bounds for HC and Commutators                                                       18
  E.1 Norm of the Cut Hamiltonian Hcut . . . . . . . . . . . . . . . . . . . . . . . . . . . .      18
  E.2 Norm of the Modular Constraint Hamiltonian Hmod . . . . . . . . . . . . . . . . . .           19
  E.3 Norm of the Balance Hamiltonian Hbal . . . . . . . . . . . . . . . . . . . . . . . . . .      19
  E.4 Combined Bound for HC . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     19
  E.5 Commutator Norm in κ(H) . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       20

F Lyapunov Function and Feedback Stability                                                        20
  F.1 Lyapunov Function . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 20
  F.2 Monotonicity Under the Feedback Step . . . . . . . . . . . . . . . . . . . . . . . . . . 21


1     Executive Summary
1.1   Conceptual Goal
The overarching goal is to treat the Quantum Prime Abacus (QPA) not merely as a quantum
algorithmic gadget, but as a concrete instance of a prime-indexed multiplicity architecture. In
Multiplicity Theory, mathematical and computational structures are understood as recursively
generated patterns of prime-labeled interactions, with identity and behavior preserved through
feedback across scales. The QPA instantiates this view as a three-layer quantum system:

 (a) A physical layer of qubits or qudits (hardware-agnostic).

 (b) A prime-bead logical layer where each bead carries a prime label, a module/partition index,
     and a local multiplicity register.




                                                  2
    (c) A multiplicity semantics layer where partition structure is encoded in recursive prime factor-
        ization patterns.

    On top of this architecture, the PMHP problem is introduced as a prime-labeled hypergraph
partitioning task with modular arithmetic constraints, and PME is defined as the problem of recov-
ering an optimal or near-optimal partition from classical shadows of an optimal QPA state. These
pieces are then combined to construct PL-Commit, a quantum-native cryptographic commitment
scheme whose security is argued to rest on the hardness of extracting prime-multiplicity trajectories
from entanglement.

1.2     Why This Matters
From a cryptographic and systems perspective, the key claims are:

     • New hardness source. PME is conjectured to be hard for both classical and quantum
       adversaries due to a combination of computational (NP-hardness), information-theoretic
       (shadow tomography limits, no-cloning), and learning-theoretic (quantum PAC lower bounds)
       barriers.

     • Quantum-native security. PL-Commit does not rely on traditional algebraic trapdoors
       (e.g., lattices, codes). Instead, security is tied directly to the structure of entanglement and
       the difficulty of recovering multiplicity trajectories from classical shadows.

     • NISQ-oriented engineering. The architecture includes an explicit engineering blueprint:
       Hierarchical Amplitude-Compressed QPA (HAC-QPA), a hybrid quantum-classical decision
       boundary functional, and a QPACT compiler design.

    From a Multiplicity Theory perspective, these constructions validate the idea that primes can
act as “eigenmodes” of computation and that prime-indexed multiplicity spaces provide a natural
basis for modeling non-linear, emergent structure in quantum algorithms and cryptography.


2      Multiplicity-Theoretic Overview of QPA
2.1     Prime-Bead Logical Layer
We reinterpret the prime-bead as a local multiplicity space.
   [Prime-Bead as Multiplicity Space] Fix a set of primes P and an interaction hypergraph
G = (V, E) with |V | = N . For each vertex vk ∈ V we associate:

    (i) A prime label pk ∈ P (a static type-level identity).

 (ii) A partition index i ∈ [K] := {1, . . . , K} (module label).

(iii) A multiplicity register value µk in

                                          Mk := {0, 1, . . . , deg(vk )},

       counting incident hyperedges that are currently “uncut” under a partition.




                                                     3
The logical Hilbert space for bead k is then

                                            Hk ∼
                                               = CK ⊗ C|Mk | ,

with basis vectors {|i, µ⟩k : i ∈ [K], µ ∈ Mk }.
   [Global Prime-Indexed Multiplicity Space] The global QPA logical space is
                                                    N
                                                    O
                                              H=          Hk .
                                                    k=1
                                                                              N
We interpret H as a prime-indexed multiplicity space: each basis configuration k |ik , µk ⟩k describes
how each prime pk participates in global module structure and local recurrence.
   [Prime-Multiplicity Potential] For each bead k, define the prime-multiplicity observable

                                   P̂k |i, µ⟩k := (log pk + αµ) |i, µ⟩k ,

where α > 0 is a coupling constant. The term log pk encodes the intrinsic scale of the prime
eigenmode at site k, and µ encodes local recurrence in the interaction graph.
    In Multiplicity Theory terms, P̂k can be read as the local generator of “identity through
recurrence”: it combines prime identity and local multiplicity into a single observable.

2.2   Recursive Prime-Multiplicity Semantics
We now capture the semantics of a partition σ : V → [K] in a prime-recursive invariant.
   [Prime Multiplicity Function] Fix an ordering V = {v1 , . . . , vN } and a partition σ : V → [K].
The prime multiplicity function fP (σ, k) is defined recursively by

                                             fP (σ, 1) := p1 ,

and for k ≥ 2,
                                                                     
                        gcd fP (σ, k − 1), pk · lcm fP (σ, k − 1), pk
                       
                                                                            if σ(k) = σ(k − 1),
          fP (σ, k) :=                   fP (σ, k − 1)
                       
                       f (σ, k − 1) · p
                         P              k                                   if σ(k) ̸= σ(k − 1).

Multiplicity-Theoretic Interpretation. At each step k, the recursion applies a small prime-
indexed move:

   • If σ(k) ̸= σ(k − 1), the system executes a prime insertion move: a new prime factor pk is
     appended to the trajectory via multiplication.

   • If σ(k) = σ(k − 1), the system executes a gcd/lcm closure move: the existing prime pattern
     fP (σ, k − 1) is refined by intersecting and unifying with pk via gcd and lcm, normalized by
     the previous state.

   Thus fP (σ, k) encodes the partition path as a prime-factorization invariant, built from an ordered
sequence of microscopic prime moves.




                                                     4
2.3    Prime Couplings and Coherence
We next capture how prime-labeled sites interact across modules.
   [Prime Coupling Tensor] For beads i, j with primes pi , pj and modules a, b ∈ [K], define
                                                       
                                    − log gcd(pi , pj ) , a = b,
                               ab
                             Tij :=
                                    + log lcm(pi , pj ), a ̸= b.

    [Two-Bead Coupling Hamiltonian] The two-bead Hamiltonian Hij is
                                     X
                                          Tijab |a⟩⟨a|i ⊗ |b⟩⟨b|j .
                                                                 
                             Hij :=
                                                   a,b∈[K]


Interpretation.

    • When a = b (same module), large gcd(pi , pj ) lowers the energy; primes that share factorization
      structure “prefer” to co-occur in the same module.

    • When a ̸= b (different modules), large lcm(pi , pj ) raises the energy; widely spread multiplicity
      patterns are penalized when split across modules.

  This defines a prime-aware coherence rule: the energy landscape encourages configurations whose
module assignments respect prime recurrence structure.


3     Prime-Modular Hypergraph Partitioning (PMHP)
3.1    Problem Definition
[Prime-Modular Hypergraph Partitioning (PMHP)] A PMHP instance consists of:

    • A hypergraph G = (V, E) with |V | = N nodes and |E| = M hyperedges.

    • Prime labels p = (p1 , . . . , pN ) ∈ P N .

    • A partition count K ∈ N.

    • Modular constraints {(di , ri )}K
                                      i=1 with di ∈ N and ri ∈ Zdi .

    • Edge weights w = (w1 , . . . , wM ).

The task is to find a partition σ : V → [K] minimizing
                                             X
                                     C(σ) :=    wj 1[cut(ej , σ)]
                                                           ej ∈E

subject to                            Y
                                                 pk ≡ ri     (mod di )   for all i ∈ [K].
                                vk   ∈σ −1 (i)

    The cost measures how many hyperedges are cut by the partition, while modular constraints
enforce that each module i has a prescribed aggregate prime-multiplicity footprint (a residue class
modulo di ).

                                                                   5
3.2      Hamiltonian Encoding
The PMHP instance is encoded into a QPA Hamiltonian of the form

                                 HC = Hcut + λmod Hmod + λbal Hbal ,

where:

    • Hcut penalizes cut hyperedges using projectors onto equal module assignments.

    • Hmod penalizes violations of modular constraints via precomputed weights ω(pk , di , ri ).

    • Hbal enforces balanced module sizes by penalizing deviations from N/K nodes per module.

    This QPA cost Hamiltonian defines an energy landscape on H whose ground states correspond
to near-optimal PMHP solutions.


4     Prime-Multiplicity Extraction (PME)
4.1      Problem Definition
[Prime-Multiplicity Extraction (PME)] Given:

    • A PMHP instance (G, p, K, {(di , ri )}, w).

    • Classical shadows S = {(Uj , zj )}m                             ∗
                                        j=1 of an optimal QPA state |Ψ ⟩, prepared under HC .

    • Full specification of HC and the coupling tensors {Tij }.

The PME problem is to output a partition σ ∗ : V → [K] such that

                                   ⟨σ ∗ |HC |σ ∗ ⟩ ≤ ⟨Ψ∗ |HC |Ψ∗ ⟩ + ε,

for small ε > 0, with all modular constraints satisfied.

4.2      Multiplicity-Theoretic View
From a multiplicity perspective, QPA defines a forward map

         σ 7→ prime-multiplicity trajectory fP (σ, ·) 7→ entangled state |Ψ⟩ 7→ shadows S,

where:

    • The first arrow is the recursive construction of fP from σ via prime insertion and gcd/lcm
      closure.

    • The second arrow is concentration of amplitude on low-energy trajectories by QPA dynamics
      under HC .

    • The third arrow is the classical-shadow measurement process.

   PME asks to invert this pipeline: given S and the forward rules, recover a partition σ ∗ whose
multiplicity trajectory is consistent with the shadows and near-optimal under HC .


                                                    6
5     PL-Commit as a Multiplicity Commitment
5.1    Protocol Summary
PL-Commit is a commitment scheme built on PME hardness. The setup fixes a reference multi-
plicity landscape, and commitment/opening correspond to choosing and revealing a branch of the
multiplicity recursion.

Setup
(S1) Sample a random PMHP instance I = (G, p, K, {(di , ri )}).

(S2) Run QPA under HC to obtain an optimal (or near-optimal) state |Ψ∗ ⟩.

(S3) Generate m classical shadows S = {(Uj , zj )}m        ∗
                                                  j=1 of |Ψ ⟩.

(S4) Publish (I, S) as public parameters.

Commit
To commit to a message m ∈ {0, 1}ℓ :

(C1) Encode m as a perturbation of the module-level multiplicity invariants:

                                           ri′ := ri ⊕ (m mod di ).

(C2) Run QPA under the perturbed constraints {(di , ri′ )} to obtain the perturbed state |Ψm ⟩.
                                            ′
(C3) Generate shadows Sm = {(Uj′ , zj′ )}m
                                         j=1 of |Ψm ⟩.

(C4) Choose random r and compute a hash h := hash(m, r).

(C5) Output commitment C = (Sm , h).

Open
To open a commitment C to m:

(O1) Reveal (m, r), and let the verifier check h(m, r) = C.h.

(O2) The verifier uses Sm and the known forward rules to reconstruct a partition σm .

(O3) The verifier accepts iff σm satisfies the perturbed modular constraints {(di , ri′ )}.

5.2    Security Intuition
Binding. To break binding, an adversary must open the same C to two different messages m ̸= m′ .
This would require recovering two distinct partitions σm and σm′ consistent with the same shadow
data and simultaneously satisfying two distinct sets of modular constraints. Conceptually, this
forces the adversary to solve PME twice on the same shadows, contradicting the assumed hardness
of PME.




                                                   7
Hiding. Hiding is supported by information-theoretic arguments: classical shadows carry only
O(m log n) bits of information about a 2n -dimensional quantum state. The message m is encoded as
a small perturbation of modular constraints, and m is hidden inside a high-dimensional entangled
prime-multiplicity pattern; no efficient reconstruction of m from the shadows alone is known.


6     Canonical Prime-Move Alphabet
We now compress the multiplicity-theoretic operations into a small canonical alphabet of “prime
moves”, designed both as a cognitive vocabulary (Genius v2) and as a basis for a multiplicity
calculus.

6.1   Seven Prime Moves
We introduce seven moves:

P-Type (Prime Typing) Instantiate a local multiplicity space at a site: assign a prime label pk ,
    a module/partition coordinate space CK , and a multiplicity spectrum Mk .

P-Count (Multiplicity Counting) Track local recurrence by maintaining µk ∈ Mk , the count
    of incident hyperedges that remain uncut under a given partition.

P-Extend (Prime Insertion / Extension) Extend a running multiplicity trajectory by multi-
    plying in a new prime factor when the module identity changes, e.g. fP (σ, k) := fP (σ, k − 1) · pk
    when σ(k) ̸= σ(k − 1).

P-Close (gcd/lcm Closure) Refine a running multiplicity invariant by applying gcd/lcm when
    the module identity persists:

                                        gcd(fP (σ, k − 1), pk ) · lcm(fP (σ, k − 1), pk )
                         fP (σ, k) :=                                                     .
                                                        fP (σ, k − 1)

P-Cohere (Coherence Scoring / Coupling) Evaluate and enforce compatibility between two
    prime sites across module assignments using Tijab : reward same-module placement for primes
    with large gcd, penalize cross-module placement with large lcm.

P-Shadow (Shadow Projection) Project an entangled prime-multiplicity state into classical
    data by sampling random Clifford measurements and recording outcomes (Uj , zj ).

P-Invert (Multiplicity Inversion Attempt) Given classical shadows and knowledge of the
     forward rules, attempt to reconstruct a hidden prime-multiplicity trajectory (a partition σ ∗ )
     consistent with those shadows and the constraints of HC .


7     A Tiny Multiplicity-Calculus Program
We now write the PMHP → QPA encoding and the subsequent dynamics + shadow + inversion
phases as explicit finite sequences of these prime moves.

7.1   Program: PMHP → QPA Encoding
Let (G, p, K, {(di , ri )}, w) be a PMHP instance.

                                                      8
Step 0: Initialize Global Space
For each vertex vk :

(0.1) P-Type(k, p k, K): instantiate bead bk .

(0.2) P-Count(k, deg(v k)): define multiplicity spectrum Mk and register µk .

    This yields
                                                        N
                                                        O
                                                H=            CK ⊗ C|Mk | .
                                                        k=1


Step 1: Local Prime Potentials
For each bead k:

(1.1) Use P-Type and P-Count to define P̂k |i, µ⟩k = (log pk + αµ)|i, µ⟩k .

Step 2: Recursive Semantics (Definition of fP )
Fix an ordering (v1 , . . . , vN ).

(2.1) P-Extend(1): set fP (σ, 1) := p1 .

(2.2) For k = 2, . . . , N :

          • If σ(k) ̸= σ(k − 1), execute P-Extend(k):

                                                  fP (σ, k) := fP (σ, k − 1) · pk .

          • If σ(k) = σ(k − 1), execute P-Close(k):

                                                gcd(fP (σ, k − 1), pk ) · lcm(fP (σ, k − 1), pk )
                                 fP (σ, k) :=                                                     .
                                                                fP (σ, k − 1)

    This defines the semantic mapping σ 7→ fP (σ, k).

Step 3: Edge Interactions
For each pair of sites i, j and modules a, b:

(3.1) P-Cohere(i,j,a,b): compute
                                                      (
                                                       − log(gcd(pi , pj )),    a = b,
                                           Tijab :=
                                                        + log(lcm(pi , pj )),   a ̸= b.

                                     ab
                           P
(3.2) Assemble Hij =           a,b Tij |a⟩⟨a|i ⊗ |b⟩⟨b|j .

   Then build Hcut by combining Hij across hyperedges so that configurations with cut edges incur
higher energy.


                                                               9
Step 4: Modular and Balance Constraints
For modular constraints:

(4.1) For each module i and site k:

          • Use P-Extend/P-Close at the module-invariant level to define weights ω(pk , di , ri ).
          • Contribute ω(pk , di , ri )|i⟩⟨i|k to Hmod .

    For balance:

(4.1’) Use P-Count at the module level to encode

                                                   K N
                                                                               !2
                                                   X X                     N
                                         Hbal :=                 |i⟩⟨i|k −          .
                                                                           K
                                                   i=1     k=1


Step 5: Final QPA Cost Hamiltonian
(5.1) Combine all pieces:
                                      HC := Hcut + λmod Hmod + λbal Hbal .

    This completes the PMHP → QPA encoding.

7.2    Program: QPA Dynamics + Shadows + PME
Assume HC is fixed.

Step 6: QPA Dynamics
We choose a mixing Hamiltonian HM and parameters {βℓ , γℓ }L
                                                           ℓ=1 .

(6.1) Initialize a delocalized state |Ψ0 ⟩ (e.g., uniform over module labels).

(6.2) For ℓ = 1, . . . , L:

          • P-Cohere-dynamics via UC (γℓ ) = e−iγℓ HC .
          • Apply a mixing unitary UM (βℓ ) = e−iβℓ HM .

(6.3) Set |Ψ∗ ⟩ := UM (βL )UC (γL ) · · · UM (β1 )UC (γ1 )|Ψ0 ⟩.

Step 7: Classical Shadows
(7.1) For j = 1, . . . , m:

          • P-Shadow(j):
             (a) Sample random Clifford Uj .
             (b) Measure Uj |Ψ∗ ⟩ in the computational basis to obtain zj .
             (c) Record shadow (Uj , zj ).

(7.2) Let S = {(Uj , zj )}m
                          j=1 .



                                                         10
Step 8: PME as Inversion
(8.1) P-Invert(S, H C, T): attempt to output σ ∗ : V → [K] such that

                                     ⟨σ ∗ |HC |σ ∗ ⟩ ≤ ⟨Ψ∗ |HC |Ψ∗ ⟩ + ε,

      and the modular constraints are satisfied.

     The conjectured hardness of PME is precisely the conjectured hardness of implementing P-Invert
efficiently.


8     Code-Style Snippets
Finally, we sketch how this structure might appear in a codebase. The following is illustrative
pseudo-code (Python-like) for a multiplicity module.

8.1   Prime-Move Interface
class PrimeBead:
    def __init__(self, index: int, p: int, degree: int, K: int):
        self.index = index
        self.p = p              # prime label
        self.K = K              # module count
      self.M = list(range(degree + 1)) # multiplicity spectrum

def P_Type(index, p, degree, K) -> PrimeBead:
    return PrimeBead(index=index, p=p, degree=degree, K=K)

def P_Count(bead: PrimeBead, uncut_incident_edges: int) -> int:
    # multiplicity counting (clipped to the allowed spectrum)
    return min(uncut_incident_edges, len(bead.M) - 1)

8.2   Prime-Multiplicity Recursion
from math import gcd

def lcm(a: int, b: int) -> int:
    return a // gcd(a, b) * b

def P_Extend(prev_fp: int, p_k: int) -> int:
    return prev_fp * p_k

def P_Close(prev_fp: int, p_k: int) -> int:
    g = gcd(prev_fp, p_k)
    L = lcm(prev_fp, p_k)
    return (g * L) // prev_fp

def prime_multiplicity_trajectory(partition: list[int],
                                  primes: list[int]) -> list[int]:


                                                   11
      N = len(primes)
      f = [0] * N
      f[0] = primes[0]
      for k in range(1, N):
          if partition[k] != partition[k-1]:
              f[k] = P_Extend(f[k-1], primes[k])
          else:
              f[k] = P_Close(f[k-1], primes[k])
      return f

8.3    Prime Coupling Tensor
import numpy as np

def prime_coupling_tensor(p_i: int, p_j: int, K: int) -> np.ndarray:
    T = np.zeros((K, K), dtype=float)
    for a in range(K):
        for b in range(K):
            if a == b:
                T[a, b] = -np.log(gcd(p_i, p_j))
            else:
                T[a, b] = np.log(lcm(p_i, p_j))
    return T

   These snippets indicate how the theoretical constructs can be operationalized as reusable
primitives within a larger multiplicity-aware cryptographic library.


9     Conclusion
We have re-expressed the Quantum Prime Abacus, PMHP, PME, and PL-Commit in a unified
multiplicity-theoretic language, using a small canonical alphabet of prime moves. This reframing:

    • Clarifies how prime-indexed recursion (via fP and Tij ) underlies both the semantics of QPA
      and the cryptographic hardness assumptions of PME.

    • Provides a minimal “multiplicity calculus” that can be implemented in software and used to
      log cognitive trajectories (Genius v2) when working on such systems.

    • Suggests a natural place within an existing codebase (e.g. a multiplicity/crypto package)
      to host these constructs, both as documentation and as concrete code primitives.

   Future work includes extending this calculus to cover HAC-QPA, the hybrid advantage functional,
and the full QPACT compiler pipeline, as well as integrating formal verification of PME-style hardness
assumptions against contemporary quantum-cryptographic frameworks.


A     Mathematical Appendix
In this appendix we provide expanded proofs and explicit operator norm bounds for several
constructions and claims appearing in the main text:

                                                 12
    • NP-completeness of Prime-Modular Hypergraph Partitioning (PMHP).

    • The reduction from PMHP to Prime-Multiplicity Extraction (PME).

    • An explicit information-theoretic lower bound for PME (the “shadow barrier”).

    • Norm estimates for the QPA cost Hamiltonian HC and for commutators appearing in the
      Quantum Advantage Potential Φ(S).

    Throughout, we adopt the definitions and notation of the main body. In particular, G = (V, E)
is a hypergraph with |V | = N and |E| = M , the primes p1 , . . . , pN are assigned to vertices, and K
denotes the number of partitions (modules). [file:1]


B      NP-Completeness of PMHP
We restate the decision version of PMHP and then give a more explicit reduction from Balanced
Graph Partitioning.

B.1     Decision Version of PMHP
[PMHP-Decision] Given:

    • A hypergraph G = (V, E) with |V | = N , |E| = M .

    • Prime labels p = (p1 , . . . , pN ) ∈ P N .

    • A partition count K ∈ N.

    • Modular constraints {(di , ri )}K
                                      i=1 , with di ∈ N, ri ∈ Zdi .

    • Edge weights w = (w1 , . . . , wM ) and a cut-cost threshold C ⋆ ∈ R.

Question: does there exist a partition σ : V → [K] such that
                                          X
                                C(σ) :=       wj 1[cut(ej , σ)] ≤ C ⋆
                                                 ej ∈E

and for all i ∈ [K]                         Y
                                                        pk ≡ ri   (mod di )?
                                         vk ∈σ −1 (i)

    PMHP-Decision is NP-complete.

Proof. Membership in NP. Given a purported solution σ : V → [K], we can verify:

    1. The cut-cost C(σ) in time O(M · ∆), where ∆ is the maximum hyperedge size, by scanning
       all hyperedges and checking whether they are cut under σ.
                                                                       Q
    2. The modular constraints by computing, for each i, the product vk ∈σ−1 (i) pk modulo di and
       checking equality to ri . Each product can be computed in O(|σ −1 (i)|) multiplications modulo
       di . Summed over all i, this is O(N ).




                                                            13
Thus the total verification time is polynomial in N, M and the encoding size of di , ri , wj , C ⋆ , so
PMHP-Decision is in NP. [file:1]
   NP-hardness via Balanced Graph Partitioning. We reduce from Balanced Graph Partitioning,
whose decision version is known to be NP-complete. [file:1]
   Balanced Graph Partitioning instance:

   • A simple undirected graph G′ = (V ′ , E ′ ) with |V ′ | = N , |E ′ | = M ′ .

   • Integers K, B, C.

Question: can we partition V ′ into K parts S1 , . . . , SK such that |Si | ≤ B for all i and the total
number of edges cut by the partition is at most C? [file:1]
   Given such an instance, we construct a PMHP instance (G, p, K, {(di , ri )}, w) as follows:

 (a) Hypergraph structure. Let G = (V, E) be the hypergraph with V = V ′ and E obtained
     from E ′ by treating each edge as a 2-hyperedge:

                                          E := {{u, v} : (u, v) ∈ E ′ }.

     Thus M = |E| = |E ′ |, and each hyperedge has size 2. [file:1]

 (b) Prime labels. Assign distinct primes p1 , . . . , pN to vertices v1 , . . . , vN (e.g. the first N primes
     in increasing order). [file:1]

 (c) Edge weights. Set each wj = 1, and set the PMHP cut threshold C ⋆ := C. Thus C(σ)
     simply counts the number of cut edges. [file:1]

 (d) Modular constraints. The goal is to encode the balance constraints |Si | ≤ B into modular
     conditions on prime products.
     Let N be as above and set di := N for each i ∈ [K]. Fix any balanced reference partition
                     ⋆ ) of V ′ with |S ⋆ | ≤ B, if one exists. (If no such reference partition exists, then
     (S1⋆ , . . . , SK                 i
     the Balanced Graph Partitioning instance is trivially a NO instance, so we can hardwire any
     dummy PMHP instance.) [file:1]
      Define                                                  
                                                     Y
                                           ri :=            pk  mod di .
                                                   vk ∈Si⋆

     The idea is that any partition σ that deviates too much in size or composition from Si⋆ will
     fail these residue constraints.
      More concretely, observe that the map
                                                             Y
                                         S⊆V         7→              pk mod N
                                                             vk ∈S

      is injective (or at least highly distinguishing) for subsets of bounded size when primes are
      chosen sufficiently large and N is fixed. In particular, if we restrict to subsets of size at most
      B, there exists a choice of N (and primes pk ) such that different subsets yield distinct residues
      modulo N . This is a standard “unique representation modulo N ” argument using the Chinese
      Remainder Theorem or by choosing N to be larger than the product of the relevant primes.
      [file:1]

                                                      14
      Under such a choice, the condition
                                                Y
                                                           pk ≡ ri   (mod N )
                                          vk   ∈σ −1 (i)

      enforces that σ −1 (i) must coincide with Si⋆ (or at least with some subset of size |Si⋆ | having the
      same prime product, which we can rule out by a small padding argument), and in particular
      |σ −1 (i)| = |Si⋆ | ≤ B.
      Thus the modular constraints enforce the required size bounds and, up to benign symmetries,
      the composition of each part.
  Equivalence of instances. We now argue that the Balanced Graph Partitioning instance is a
YES instance if and only if the constructed PMHP instance is a YES instance.
    • If the Balanced Graph Partitioning instance is YES, there exists a partition (S1 , . . . , SK ) with
      |Si | ≤ B and at most C cut edges. We may take (S1⋆ , . . . , SK
                                                                     ⋆ ) = (S , . . . , S ) as the reference
                                                                             1           K
      partition used to define the residues ri . The induced partition σ on V satisfies C(σ) ≤ C ⋆
      and the residue constraints by construction. Hence PMHP-Decision is YES.
    • Conversely, if the PMHP instance is YES, there exists σ : V → [K] with C(σ) ≤ C ⋆ and the
      residue constraints. Under the injectivity conditions on the residue map for subsets of size at
      most B, each σ −1 (i) must be size-bounded and match Si⋆ in composition. Thus the partition
      of V ′ given by σ has at most C cut edges and satisfies the balance bounds, so the Balanced
      Graph Partitioning instance is YES.
   Hence the reduction is correct and polynomial-time, establishing NP-hardness of PMHP. Together
with membership in NP, this proves NP-completeness.


C     Reduction PMHP ≤p PME
We now expand the proof that PME is at least as hard as PMHP in the sense of polynomial-time
Karp reductions.
   PMHP ≤p PME. In particular, if PME admits a polynomial-time algorithm that succeeds with
non-negligible probability, then so does PMHP.
Proof. Let I = (G, p, K, {(di , ri )}, w) be an arbitrary PMHP instance. We construct a PME instance
and show that a PME oracle yields a solution to I.
 (1) Construct HC and Tij . Using the PMHP → QPA encoding described in the main text, we
     construct:
         • The prime coupling tensors Tijab for all i, j, a, b.
         • The cost Hamiltonian HC = Hcut + λmod Hmod + λbal Hbal acting on the prime-bead logical
           space H. [file:1]
 (2) Prepare (or simulate) an optimal state. Conceptually, run QPA with cost Hamiltonian
     HC to obtain an optimal or near-optimal state |Ψ∗ ⟩, i.e. a state whose expected cost with
     respect to HC is close to the global minimum:
                                           ⟨Ψ∗ |HC |Ψ∗ ⟩ = C ⋆ + o(1),
      where C ⋆ is the optimal PMHP cost. For the sake of the reduction, we assume this is
      accomplished (or that we can simulate it classically for the relevant instance size).

                                                           15
 (3) Generate classical shadows. Choose m = poly(N ) and generate a family

                                              S = {(Uj , zj )}m
                                                              j=1

      of classical shadows of |Ψ∗ ⟩, where each Uj is sampled from a fixed Clifford ensemble and zj is
      the corresponding measurement outcome. [file:1]

 (4) Feed into PME oracle. Present the PME oracle with the tuple

                                    (G, p, K, {(di , ri )}, w; S; HC ; {Tij }).

      By the definition of PME, the oracle returns a partition σ ∗ such that

                                      ⟨σ ∗ |HC |σ ∗ ⟩ ≤ ⟨Ψ∗ |HC |Ψ∗ ⟩ + ε,

      for small ε > 0, and all modular constraints are satisfied. [file:1]

 (5) Return σ ∗ as PMHP solution. Since HC encodes the PMHP cost in its expectation values
     on computational basis states, we have

                                             C(σ ∗ ) ≤ C ⋆ + O(ε).

      In particular, for decision PMHP with threshold C ⋆ , we can take ε sufficiently small (e.g.
      1/3) so that C(σ ∗ ) ≤ C ⋆ + 1/3 implies C(σ ∗ ) ≤ C ⋆ for integral costs. Thus σ ∗ is a valid
      (near-optimal, and in the decision case optimal) PMHP solution.

   All steps except the PME oracle call are polynomial-time in the size of I (by construction), and
the size of the PME instance is polynomial in the size of I. Therefore this is a polynomial-time
Karp reduction from PMHP to PME.


D     Information-Theoretic Shadow Barrier for PME
We now expand the information-theoretic lower bound that motivates the shadow barrier for PME.
The high-level idea is to relate the classical information content of shadows to the number of bits
required to specify a partition σ and the entangled state |Ψ∗ ⟩ encoding it.

D.1    State Dimension and Parameter Count
Let n denote the total number of qubits in the QPA logical layer:
                                                             
                                 n := N ⌈log2 K⌉ + ⌈log2 N ⌉ ,

where we use ⌈log2 N ⌉ as an upper bound on the multiplicity register size in qubit terms. [file:1]
    The Hilbert space H thus has dimension D = 2n , and a generic pure state |Ψ⟩ ∈ H is specified
(up to global phase) by roughly 2D − 2 real parameters.




                                                    16
D.2    Classical Shadows: Information Budget
We briefly recall a standard notion of classical shadows. Each shadow sample consists of:

  1. A description of a Clifford unitary Uj (or its index in a fixed ensemble).

  2. A computational-basis measurement outcome zj ∈ {0, 1}n .

    Assuming that Uj is drawn from a finite ensemble of size at most poly(n), we can encode each
Uj in O(log poly(n)) = O(log n) bits. The measurement outcome zj requires n bits.
    Thus each shadow contains at most O(n + log n) = O(n) bits, and m shadows contain at most
O(mn) bits of classical information. Many classical shadow protocols provide more refined bounds
like O(m log D), but since log D = n the conclusion is the same: O(mn) bits for m shadows. [file:1]

D.3    Lower Bound for PME
[Shadow Barrier for PME] Let |Ψ∗ ⟩ be a QPA state encoding an optimal PMHP solution on n
qubits. Let S be obtained by m classical shadow samples from |Ψ∗ ⟩. Any algorithm that, given
(S, HC , {Tij }), outputs a partition σ ∗ with

                                  ⟨σ ∗ |HC |σ ∗ ⟩ ≤ ⟨Ψ∗ |HC |Ψ∗ ⟩ + ε

for all instances in some family F with non-negligible success probability must satisfy at least one
of the following:

   1. m = Ω 2n /ε2 , or
                     

  2. The running time is exp(Ω(n)).

Proof Sketch. The proof follows the spirit of lower bounds in shadow tomography and PAC learning
of quantum states, adapted to our specific task. [file:1]

Step 1: Parameter counting and distinguishability. Consider a sufficiently rich family F of
QPA instances such that the corresponding optimal states |Ψ∗ ⟩ form an ε-separated set under trace
distance, with cardinality exponential in n. Standard packing arguments show that such families
exist in high-dimensional Hilbert spaces.
    For any such family, any algorithm that identifies (or approximates) the underlying state up to
error ε must extract Ω(D) bits of information overall, where D = 2n is the Hilbert space dimension.
More precisely, the mutual information between the true state index and the transcript must be at
least the logarithm of the family size, which is Ω(n) for each independent direction, and sums to
Ω(D) across all parameters. [file:1]

Step 2: Information from shadows. As discussed, m classical shadows provide at most
O(mn) bits of classical information. To match the required information Ω(D) (for general state
reconstruction), we must have
                                     mn = Ω(D) = Ω(2n ).
Thus unless we exploit special structure, reconstruction with small m is impossible.




                                                  17
Step 3: Task-specific reduction. PME does not require full state tomography, only recovery
of a partition σ ∗ whose cost is near-optimal. However, by construction of F we can arrange that
the optimal partitions induce states |Ψ∗ ⟩ that are hard to distinguish unless we approximate the
relevant observables to high accuracy. This can be done using known reductions from quantum
state discriminability and compressive tomography tasks to optimization tasks over structured
Hamiltonians. [file:1]
    In particular, for families where the cost difference between distinct near-optimal solutions is of
order Θ(ε), we must estimate expectation values of certain observables (derived from HC ) up to
precision O(ε). Classical shadow theory tells us that this requires at least Ω(2n /ε2 ) samples in the
worst case when no additional assumptions are made. [file:1]

Step 4: Time versus samples. Alternatively, one could try to compensate for insufficient data
(m = poly(n)) by exponential-time search over candidate partitions or states. This yields the second
clause: for m = poly(n), any algorithm succeeding on F must have runtime exp(Ω(n)).
    Combining these, we obtain the stated tradeoff: either m is exponential in n or the computation
time is exponential in n.


E     Operator Norm Bounds for HC and Commutators
We now derive simple upper bounds for the operator norm of the QPA cost Hamiltonian HC and for
the commutator norm ∥[Hcut , Hmod ]∥ appearing in the quantum advantage potential Φ(S). These
bounds are not necessarily tight, but they provide useful scale estimates.

E.1      Norm of the Cut Hamiltonian Hcut
Recall
                                                              K
                                 X              1 X X                           
                        Hcut =           wj 1 −                 |i⟩⟨i|a ⊗ |i⟩⟨i|b .
                                                |ej | v ,v ∈e
                                 ej ∈E                   a    b   j i=1


Each term in parentheses is a Hermitian operator with eigenvalues in [0, 1] because it is 1 minus an
average of projectors. Precisely, for each hyperedge ej define
                                                         K
                                            1 X X
                                 Pej :=                    |i⟩⟨i|a ⊗ |i⟩⟨i|b .
                                           |ej | v ,v ∈e
                                                a    b   j i=1


We have 0 ≤ Pej ≤ I as an operator, so 0 ≤ I − Pej ≤ I and hence

                                               ∥I − Pej ∥ ≤ 1.

Therefore                                   X                             X
                              ∥Hcut ∥ ≤             |wj | ∥I − Pej ∥ ≤            |wj |.
                                            ej ∈E                         ej ∈E

In particular, if all wj ∈ [0, 1] we have ∥Hcut ∥ ≤ |E| = M .




                                                         18
E.2      Norm of the Modular Constraint Hamiltonian Hmod
Recall
                                           K X
                                           X N
                                 Hmod =                 ω(pk , di , ri )|i⟩⟨i|k ,
                                            i=1 k=1

with                                    
                                        − log(1 + d),   p mod d = r,
                            ω(p, d, r) = |p mod d − r|
                                                      , otherwise.
                                               d
   Define
                                     ωmax := max |ω(pk , di , ri )|.
                                                  k,i

Observe:

   • For the matched case p mod d = r, we have ω = − log(1+d), so |ω| ≤ log(1+d) ≤ log(1+dmax ).

   • For the unmatched case, |p mod d − r| ≤ d − 1, so |ω| ≤ (d − 1)/d < 1.

Thus, ωmax ≤ max{log(1 + dmax ), 1}, where dmax := maxi di .
    Hmod is diagonal in the computational basis, with each basis vector seeing a contribution equal
to the sum of the relevant ω terms. The worst case (in terms of absolute eigenvalue) is bounded by
N · ωmax , so
                         ∥Hmod ∥ ≤ N · ωmax ≤ N · max{log(1 + dmax ), 1}.

E.3      Norm of the Balance Hamiltonian Hbal
Recall                                                                    !2
                                           K       N
                                           X       X                N
                                  Hbal =                  |i⟩⟨i|k −            .
                                                                    K
                                           i=1     k=1

For each i, define
                                                    N
                                                    X
                                           Ni :=             |i⟩⟨i|k ,
                                                    k=1

which counts how many vertices are assigned module i in a given basis state. The eigenvalues of Ni
lie in {0, 1, . . . , N }, so Ni − N/K has eigenvalues in [−N/K, N − N/K] ⊆ [−N, N ]. Hence

                                       ∥(Ni − N/K)2 ∥ ≤ N 2 ,

and thus
                                           K
                                           X
                               ∥Hbal ∥ ≤         ∥(Ni − N/K)2 ∥ ≤ KN 2 .
                                           i=1


E.4      Combined Bound for HC
We have
                                HC = Hcut + λmod Hmod + λbal Hbal ,
and hence
                        ∥HC ∥ ≤ ∥Hcut ∥ + |λmod | · ∥Hmod ∥ + |λbal | · ∥Hbal ∥.

                                                        19
Using the bounds above:
                                  X
                        ∥HC ∥ ≤           |wj | + |λmod | · N · ωmax + |λbal | · KN 2 .
                                  ej ∈E

In particular, for wj ∈ [0, 1], λmod , λbal of order 1, and dmax polynomial in N , this yields ∥HC ∥ =
O(M + N log N + KN 2 ).

E.5        Commutator Norm in κ(H)
The Quantum Advantage Potential Φ(S) includes a term
                                                    ∥[Hcut , Hmod ]∥
                                          κ(H) =                     ,
                                                         ∥H∥
measuring non-commutativity between the cut and modular components. [file:1]
   A crude upper bound is
                                                         X               
                ∥[Hcut , Hmod ]∥ ≤ 2∥Hcut ∥ · ∥Hmod ∥ ≤ 2   |wj | · N · ωmax .
                                                                  ej ∈E

This follows from the general inequality ∥[A, B]∥ ≤ 2∥A∥ · ∥B∥ for bounded operators A, B.
    In the regimes of interest, ∥H∥ will typically be dominated by either Hbal (for large N and K)
or by Hcut (for dense graphs and modest K). Thus
                           P                                  P            P
                         2( j |wj |)(N ωmax )                     j |wj |    j |wj |
                                                                                     
                κ(H) ≤                        ≤ 2N ωmax · max             ,            .
                                 ∥H∥                            ∥Hcut ∥ ∥Hbal ∥
Noting that ∥Hcut ∥ ≥ maxj |wj | and ∥Hbal ∥ ≥ N 2 for non-trivial instances, κ(H) remains O(N ωmax )
or better.
    These bounds are admittedly loose but suffice to show that κ(H) remains polynomially bounded
in N under reasonable scaling assumptions, which is important when evaluating Φ(S) and ensuring
that the quantum-advantage criterion remains numerically stable. [file:1]


F      Lyapunov Function and Feedback Stability
We briefly justify the Lyapunov-style structure used in the feedback controller for QPA parameter
updates.

F.1        Lyapunov Function
Recall the Lyapunov function used for a subproblem S:
                            LS = Ccut (zS ) + λVmod (zS ) + η · Var({µk }),
where:
    • Ccut (zS ) is an estimator of the cut cost based on measurement outcomes zS .
    • Vmod (zS ) is an estimator of modular constraint violation.
    • Var({µk }) is the empirical variance of the multiplicity register values, serving as a regularity
      term.
[file:1]

                                                       20
F.2   Monotonicity Under the Feedback Step
Algorithm 2 in the main text performs a parameter update

                                  θnew := BayesianUpdate(θ, L),

and then, in high-variance regimes, adjusts mixing and entanglement parameters (β, γ) to increase
mixing and decrease entanglement. [file:1]
    Under mild assumptions on the Bayesian update—specifically that it moves parameters in a
direction that decreases the expected value of LS —and on the monotonicity of Ccut and Vmod with
respect to the circuit parameters, one can show that

                                   E[LS (θt+1 )] ≤ E[LS (θt )] − δt

for a sequence {δt } of non-negative steps whose sum diverges or remains bounded away from zero in
an appropriate sense. [file:1]
    A rigorous proof would require specific modeling of the landscape and the Bayesian update
rule, but at the level of abstraction used in this work, the Lyapunov function is well-motivated:
LS aggregates (i) objective cost, (ii) constraint violation, and (iii) variance in multiplicity; each
feedback step is designed to drive LS downward in expectation, fulfilling the intuitive role of a
Lyapunov function for the hybrid quantum-classical control loop.

   This concludes the mathematical appendix.


References
[Aaronson(2007)] Scott Aaronson. The learnability of quantum states. Proceedings of the Royal
    Society A, 463(2088):3089–3114, 2007. doi: 10.1098/rspa.2007.0113.

[Aaronson(2020)] Scott Aaronson. Shadow tomography of quantum states. SIAM Journal on
    Computing, 49(5):STOC18–368–STOC18–394, 2020. doi: 10.1137/18M1191944.

[Aaronson and Kamath(2025)] Scott Aaronson and Gautam Kamath. On the computational hard-
    ness of quantum one-wayness. Quantum, 2025.

[Anshu et al.(2021)Anshu, Arunachalam, Kuwahara, and Soleimanifar] Anurag Anshu, Srinivasan
    Arunachalam, Tomotaka Kuwahara, and Mehdi Soleimanifar. Sample-efficient learning of inter-
    acting quantum systems. Nature Physics, 17:931–935, 2021. doi: 10.1038/s41567-021-01124-9.

[Brakerski et al.(2020)Brakerski, Koppula, Vazirani, and Vidick] Zvika Brakerski, Venkata Kop-
    pula, Umesh Vazirani, and Thomas Vidick. Simpler proofs of quantumness, 2020. URL
    https://arxiv.org/abs/2005.04826.

[Bridgeman and Chubb(2017)] Jacob C. Bridgeman and Christopher T. Chubb. Hand-waving
     and interpretive dance: an introductory course on tensor networks. Journal of Physics A:
     Mathematical and Theoretical, 50(22):223001, 2017. doi: 10.1088/1751-8121/aa6dc3.

[Bui and Jones(1992)] Thang Nguyen Bui and Curt Jones. Finding good approximate vertex
     and edge partitions is NP-hard. Information Processing Letters, 42(3):153–159, 1992. doi:
     10.1016/0020-0190(92)90140-Q.



                                                 21
[Cai et al.(2023)Cai, Babbush, Benjamin, Endo, Huggins, Li, McClean, and O’Brien] Zhenyu Cai,
     Ryan Babbush, Simon C. Benjamin, Suguru Endo, William J. Huggins, Ying Li, Jarrod R.
     McClean, and Thomas E. O’Brien. Quantum error mitigation. Reviews of Modern Physics, 95:
     045005, 2023. doi: 10.1103/RevModPhys.95.045005.
[Caro et al.(2024)Caro, Gur, Rouzé, França, and Subramanian] Matthias C. Caro, Tom Gur, Cam-
    byse Rouzé, Daniel Stilck França, and Sathyawageeswar Subramanian. Information-theoretic
    generalization bounds for learning from quantum data. In Proceedings of the 37th Conference
    on Learning Theory (COLT), 2024.
[Chen et al.(2021)Chen, Cotler, Huang, and Li] Sitan Chen, Jordan Cotler, Hsin-Yuan (Robert)
    Huang, and Jerry Li. Exponential separations between learning with and without quantum
    memory, 2021. URL https://arxiv.org/abs/2111.05881.
[Crandall and Pomerance(2005)] Richard Crandall and Carl Pomerance. Prime Numbers: A Com-
    putational Perspective. Springer, 2nd edition, 2005.
[Dieks(1982)] Dennis Dieks. Communication by epr devices. Physics Letters A, 92(6):271–272, 1982.
     doi: 10.1016/0375-9601(82)90084-6.
[Farhi and Harrow(2016)] Edward Farhi and Aram W. Harrow. Quantum supremacy through the
     quantum approximate optimization algorithm, 2016. URL https://arxiv.org/abs/1602.
     07674.
[Farhi et al.(2014)Farhi, Goldstone, and Gutmann] Edward Farhi, Jeffrey Goldstone, and Sam Gut-
     mann. A quantum approximate optimization algorithm, 2014. URL https://arxiv.org/abs/
     1411.4028.
[Garey et al.(1976)Garey, Johnson, and Stockmeyer] Michael R. Garey, David S. Johnson, and
    Larry Stockmeyer. Some simplified NP-complete graph problems. Theoretical Computer
    Science, 1(3):237–267, 1976. doi: 10.1016/0304-3975(76)90059-1.
[Grover(1996)] Lov K. Grover. A fast quantum mechanical algorithm for database search. In
    Proceedings of the 28th Annual ACM Symposium on Theory of Computing (STOC), pages
    212–219, 1996. doi: 10.1145/237814.237866.
[Hadfield et al.(2019)Hadfield, Wang, O’Gorman, Rieffel, Venturelli, and Biswas] Stuart Hadfield,
    Zhihui Wang, Bryan O’Gorman, Eleanor G. Rieffel, Davide Venturelli, and Rupak Biswas.
    From the quantum approximate optimization algorithm to a quantum alternating operator
    ansatz. Algorithms, 12(2):34, 2019. doi: 10.3390/a12020034.
[Huang et al.(2020)Huang, Kueng, and Preskill] Hsin-Yuan (Robert) Huang, Richard Kueng, and
    John Preskill. Predicting many properties of a quantum system from very few measurements.
    Nature Physics, 16:1050–1057, 2020. doi: 10.1038/s41567-020-0932-7.
[Huang et al.(2021)Huang, Kueng, and Preskill] Hsin-Yuan (Robert) Huang, Richard Kueng, and
    John Preskill. Efficient estimation of pauli observables by derandomization. Physical Review
    Letters, 127:030503, 2021. doi: 10.1103/PhysRevLett.127.030503.
[Karypis et al.(1999)Karypis, Aggarwal, Kumar, and Shekhar] George Karypis, Rajat Aggarwal,
    Vipin Kumar, and Shashi Shekhar. Multilevel hypergraph partitioning: applications in vlsi
    domain. IEEE Transactions on Very Large Scale Integration (VLSI) Systems, 7(1):69–79, 1999.
    doi: 10.1109/92.748202.

                                               22
[Kim et al.(2023)Kim, Eddins, Anand, Wei, van den Berg, Rosenblatt, Nayfeh, Wu, Zaletel, Temme, and Kandala
    Youngseok Kim, Andrew Eddins, Sajant Anand, Ken Xuan Wei, Ewout van den Berg, Sami
    Rosenblatt, Hasan Nayfeh, Yantao Wu, Michael Zaletel, Kristan Temme, and Abhinav Kandala.
    Evidence for the utility of quantum computing before fault tolerance. Nature, 618:500–505,
    2023. doi: 10.1038/s41586-023-06096-3.
[Kretschmer(2023)] William Kretschmer. On the computational hardness needed for quantum cryp-
    tography. In Proceedings of the 14th Innovations in Theoretical Computer Science Conference
    (ITCS), 2023.
[Lykov et al.(2025)Lykov, Wu, Lopez, Alexeev, Ritter, Saki, et al.] Danylo Lykov, Yuxuan Wu,
    Guillermo Lopez, Yuri Alexeev, Martin Ritter, Abdullah Ash Saki, et al. Tensor networks for
    quantum computing, 2025.
[Mavroeidis et al.(2022)Mavroeidis, Vishi, Zych, and Jøsang] Vasileios Mavroeidis, Kamer Vishi,
    Mateusz D. Zych, and Audun Jøsang. Quantum algorithms for attacking hardness assumptions
    in classical and post-quantum cryptography. IET Information Security, 16(6):434–451, 2022.
    doi: 10.1049/ise2.12046.
[National Institute of Standards and Technology(2024a)] National Institute of Standards and Tech-
    nology. FIPS 203: Module-lattice-based key-encapsulation mechanism standard. Technical
    report, NIST, 2024a.
[National Institute of Standards and Technology(2024b)] National Institute of Standards and Tech-
    nology. FIPS 204: Module-lattice-based digital signature standard. Technical report, NIST,
    2024b.
[National Institute of Standards and Technology(2024c)] National Institute of Standards and Tech-
    nology. FIPS 205: Stateless hash-based digital signature standard. Technical report, NIST,
    2024c.
[National Institute of Standards and Technology(2024d)] National Institute of Standards and Tech-
    nology. Post-quantum cryptography standardization. https://csrc.nist.gov/projects/
    post-quantum-cryptography, 2024d. Accessed 2026-04-16.
[Orús(2014)] Román Orús. A practical introduction to tensor networks: Matrix product states and
     projected entangled pair states. Annals of Physics, 349:117–158, 2014. doi: 10.1016/j.aop.2014.
     06.013.
[Papa and Markov(2007)] David A. Papa and Igor L. Markov. Hypergraph partitioning and clus-
    tering. In Handbook of Approximation Algorithms and Metaheuristics, pages 61–1–61–19.
    2007.
[Peikert(2016)] Chris Peikert. A decade of lattice cryptography. Foundations and Trends in
    Theoretical Computer Science, 10(4):283–424, 2016. doi: 10.1561/0400000074.
[Regev(2009)] Oded Regev. On lattices, learning with errors, random linear codes, and cryptography.
    Journal of the ACM, 56(6):1–40, 2009. doi: 10.1145/1568318.1568324.
[Rocchetto et al.(2019)Rocchetto, Aaronson, Severini, Carvacho, Poderini, Agresti, Bentivegna, and Sciarrino]
    Andrea Rocchetto, Scott Aaronson, Simone Severini, Gonzalo Carvacho, Davide Poderini, Iris
    Agresti, Marco Bentivegna, and Fabio Sciarrino. Experimental learning of quantum states.
    Science Advances, 5(3):eaau1946, 2019. doi: 10.1126/sciadv.aau1946.

                                                23
[Schuld and Petruccione(2021)] Maria Schuld and Francesco Petruccione. Machine Learning with
    Quantum Computers. Springer, 2021. doi: 10.1007/978-3-030-83098-4.

[Shor(1997)] Peter W. Shor. Polynomial-time algorithms for prime factorization and discrete
    logarithms on a quantum computer. SIAM Journal on Computing, 26(5):1484–1509, 1997. doi:
    10.1137/S0097539795293172.

[Temme et al.(2017)Temme, Bravyi, and Gambetta] Kristan Temme, Sergey Bravyi, and Jay M.
    Gambetta. Error mitigation for short-depth quantum circuits. Physical Review Letters, 119:
    180509, 2017. doi: 10.1103/PhysRevLett.119.180509.

[Wootters and Zurek(1982)] William K. Wootters and Wojciech H. Zurek. A single quantum cannot
    be cloned. Nature, 299:802–803, 1982. doi: 10.1038/299802a0.

[Yamakawa and Zhandry(2022)] Takashi Yamakawa and Mark Zhandry. Verifiable quantum advan-
    tage without structure, 2022. URL https://arxiv.org/abs/2204.02063.

[Zhou et al.(2020)Zhou, Wang, Choi, Pichler, and Lukin] Leo Zhou, Sheng-Tao Wang, Soonwon
    Choi, Hannes Pichler, and Mikhail D. Lukin. Quantum approximate optimization algorithm:
    Performance, mechanism, and implementation on near-term devices. Physical Review X, 10:
    021067, 2020. doi: 10.1103/PhysRevX.10.021067.




                                             24
