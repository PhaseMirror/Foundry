---
slug: mr-chsh-prime-bell-frame
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Mr-chsh Prime Bell Frame.md
  last_synced: '2026-03-20T17:17:19.491141Z'
---

MR–CHSH: Prime-Encoded Bell Frame and Λₘ
Curvature Invariant

0. Preamble
This document defines an explicit CHSH construction in Meta-Relativity notation:


    1. A prime-encoded Bell sector inside the lawful subspace Hlawful ⊂ H = ℓ2 (P ) ⊗ Hphys ⊗ Hcomp .
    2. A Bell state ∣Φ+ ⟩ written in terms of prime-labelled basis vectors.
    3. Local observables A0 , A1 (Alice) and B0 , B1 (Bob) as prime-gated Pauli-like operators.
    4. The correlation table Eij = E(Ai Bj ) and corresponding CHSH scalar

                                           S = E00 + E01 + E10 − E11 .

    5. An interpretation of S as a Λₘ-curvature invariant on the CHSH correlation subspace.

Throughout, we work in a fixed PIRTM chart (a choice of time/relativity frame on math-space); all final
quantities are frame-relational invariants.




1. Prime-Encoded Bell Sector

1.1 Primes and projectors

Let P denote the set of primes. For each p ∈ P , let ∣p⟩ ∈ ℓ2 (P ) be the canonical basis vector, and let


                                         Πp := ∣p⟩⟨p∣ ⊗ Iphys ⊗ Icomp

be the corresponding prime projector on the full Hilbert space.


We choose four distinct primes


           pA0 , pA1 , pB0 , pB1 ∈ P ,    pA0  pA1 , pB0            , pA1 } ∩ {pB0 , pB1 } = ∅.
                                                          = pB1 , {pA0=

Remark (canonical choice). A concrete but non-essential choice is pA0 = 2, pA1 = 3, pB0 = 5, pB1 = 7.
Any injective assignment of four primes works; lawfulness quantities below will be invariant under such
prime relabellings.


1.2 Logical qubits as prime-gated subspaces

Define Alice’s and Bob’s prime-encoded qubit subspaces by


                          HA := span{ ∣0⟩A , ∣1⟩A },       HB := span{ ∣0⟩B , ∣1⟩B },



                                                       1
with

                      ∣0⟩A := ∣pA0 ⟩,     ∣1⟩A := ∣pA1 ⟩, ∣0⟩B := ∣pB0 ⟩,     ∣1⟩B := ∣pB1 ⟩,

understood as prime-gated basis states inside ℓ2 (P ), tensored with fixed reference states in Hphys ⊗
Hcomp .

Define the Bell sector


                                        HBell := HA ⊗ HB ⊂ Hlawful ⊂ H.

We assume (by construction) that the global lawfulness operator Ξ(t) preserves this sector:


                                            Ξ(t) HBell ⊆ HBell ,    ∀t,

so that Bell states and CHSH observables are internally lawful.




2. Prime-Gated Bell State

2.1 Definition

Define the prime-encoded Bell state

                                               1
                               ∣Φ+ ⟩AB :=         (∣0⟩A ⊗ ∣0⟩B + ∣1⟩A ⊗ ∣1⟩B ).
                                                2
In the prime basis this is

                                             1
                              ∣Φ+ ⟩AB =         (∣pA0 ⟩ ⊗ ∣pB0 ⟩ + ∣pA1 ⟩ ⊗ ∣pB1 ⟩),
                                              2
implicitly tensored with fixed reference factors in the other components of H.


2.2 Lawfulness statement

Definition (lawful Bell state). We say ∣Φ+ ⟩AB is lawful if

                                                                          1
                                ΠpA0 ΠpB0 ∣Φ+ ⟩ = ΠpA1 ΠpB1 ∣Φ+ ⟩ =          ∣Φ+ ⟩,
                                                                           2
and ∣Φ+ ⟩ ∈ Dom Ξ(t) for all t, i.e.

                              ∣Φ+ ⟩ ∈ Hlawful := ⋂ Dom Ξ(t) ∩ ⋂ Ran Πp .
                                                     t                p∈P


This encodes the intuition that the Bell state is entirely supported on the chosen primes and is dynamically
stable under lawfulness evolution.




                                                         2
3. CHSH Observables in Prime Notation

3.1 Pauli-like operators for Alice and Bob

On Alice’s qubit subspace HA , define


                           σz(A) := ∣0⟩A ⟨0∣ − ∣1⟩A ⟨1∣, σx(A) := ∣0⟩A ⟨1∣ + ∣1⟩A ⟨0∣.

In prime notation,

                     σz(A) = ∣pA0 ⟩⟨pA0 ∣ − ∣pA1 ⟩⟨pA1 ∣, σx(A) = ∣pA0 ⟩⟨pA1 ∣ + ∣pA1 ⟩⟨pA0 ∣.

Similarly on Bob’s qubit subspace HB :


                           σz(B) := ∣0⟩B ⟨0∣ − ∣1⟩B ⟨1∣, σx(B) := ∣0⟩B ⟨1∣ + ∣1⟩B ⟨0∣,

or in prime notation

                     σz(B) = ∣pB0 ⟩⟨pB0 ∣ − ∣pB1 ⟩⟨pB1 ∣, σx(B) = ∣pB0 ⟩⟨pB1 ∣ + ∣pB1 ⟩⟨pB0 ∣.

Each operator is extended to the full Hilbert space by tensored identities


                                   σz(A) ↦ σz(A) ⊗ IB ,        σx(A) ↦ σx(A) ⊗ IB ,

                                   σz(B) ↦ IA ⊗ σz(B) ,        σx(B) ↦ IA ⊗ σx(B) ,

and then prime-gated by composing with the relevant projectors ΠpA0 , ΠpA1 , ΠpB0 , ΠpB1 so that each acts
non-trivially only inside HBell .


3.2 CHSH measurement settings

We choose the standard Tsirelson-optimal settings:


                                          A0 := σz(A) ,        A1 := σx(A) ,
                                    1                                   1
                           B0 :=       (σz(B) + σx(B) ),       B1 :=       (σz(B) − σx(B) ).
                                     2                                   2

Each of Ai , Bj is Hermitian with eigenvalues ±1, and all of them live in the lawful Bell sector by
construction.




4. Correlations E(Ai Bj ) and the E-Table

4.1 Definition of correlations

For each pair (i, j) ∈ {0, 1}2 , define the correlation




                                                           3
                                  Eij := E(Ai Bj ) := ⟨Φ+ ∣ Ai ⊗ Bj ∣Φ+ ⟩.

Here all operators are implicitly prime-gated and restricted to HBell .


4.2 Explicit values for the chosen settings

With the above choices of ∣Φ+ ⟩, Ai , and Bj , a direct computation yields

                                  1                   1              1                1
                         E00 =       ,      E01 =        ,   E10 =      ,   E11 = −      .
                                   2                   2              2                2

We summarize these in the E-table:


                                             i   j      Eij = E(Ai Bj )

                                             0   0      − 12

                                             0   1      − 12

                                             1   0      − 12

                                             1   1      − 12

These values are independent of the specific numerical primes chosen, so long as the logical encoding
and Pauli-like operators are defined as above. Prime relabelling acts as a symmetry of the construction.




5. The CHSH Scalar S

5.1 Definition

Define the CHSH scalar


                                           S := E00 + E01 + E10 − E11 .

Equivalently, let

                              BCHSH := A0 ⊗ (B0 + B1 ) + A1 ⊗ (B0 − B1 ),

then

                                                     1 +
                                             S=        ⟨Φ ∣ BCHSH ∣Φ+ ⟩
                                                     2
if one normalizes BCHSH appropriately. (Here we keep the simpler linear-in-E definition.)


5.2 Value and Tsirelson bound

Substituting the entries of the E-table:




                                                             4
                                    1    1    1       1     4
                             S=        +    +    − (−    )=    = 2 2.
                                     2    2    2       2     2

Thus we obtain the standard Tsirelson-saturating quantum value


                                              2 < S = 2 2 ≤ 2 2,

with the classical (local hidden-variable) bound ∣S∣ ≤ 2 strictly violated.


In the prime-encoded MR frame, this is the statement that lawful prime-gated dynamics permit CHSH
correlations beyond any classical prime-factorizable hidden-variable model, while still respecting the
overarching lawfulness constraints encoded by Ξ(t).




6. Λₘ Lawfulness Metric and CHSH Curvature

6.1 Correlation as a vector in CHSH space

Collect the four correlations into a vector


                                      E := (E00 , E01 , E10 , E11 )T ∈ R4 .

Define the CHSH direction vector

                                               s := (1, 1, 1, −1)T .

Then the CHSH scalar is simply the standard Euclidean inner product

                                                    S = sT E.

In Meta-Relativity, the lawfulness metric Λm induces a bilinear form on correlation space. In the CHSH
sector, we may, without loss of generality, choose coordinates where


                                                 Λm CHSH = I4 ,

so that the Euclidean inner product coincides with the Λₘ-inner product. Prime relabellings and PIRTM
reparametrizations act as orthogonal transformations on E and s, leaving S invariant.


6.2 Definition of CHSH curvature scalar

To express non-classicality as curvature, define the CHSH curvature scalar


                                                   S(E)2 − 4   S(E)2 − 4
                                  κCHSH (E) :=               =           .
                                                     8−4          4




                                                        5
Properties:


    1. Classical region (flat lawfulness). For any classical local-hidden-variable model, ∣S∣ ≤ 2, hence
       S 2 ≤ 4, and

                                                  κCHSH ≤ 0.

       The classical boundary ∣S∣ = 2 corresponds to zero curvature κCHSH = 0 in this normalization.


    2. Quantum lawful region (positive curvature). For lawful prime-encoded quantum states in Hlawful ,
       Tsirelson’s bound gives ∣S∣ ≤ 2 2, so S 2 ≤ 8, yielding


                                                 0 ≤ κCHSH ≤ 1.

       The maximal quantum violation ∣S∣ = 2     2 corresponds to unit curvature κCHSH = 1.

    3. Invariance. κCHSH is invariant under:


    4. Prime relabellings that preserve the Bell sector structure;
    5. PIRTM time reparametrizations that act as orthogonal transformations on E;
    6. Any Atlas frame change whose induced action on the CHSH correlation space is an isometry of
       Λm CHSH .

Thus κCHSH is a Λₘ-curvature invariant associated with the CHSH experiment:


        κCHSH = 0 (classical flat lawfulness),    0 < κCHSH ≤ 1 (quantum lawful curvature).

6.3 CHSH curvature for the prime-encoded Bell state

For the prime-encoded Bell state ∣Φ+ ⟩ and the observables defined in Sections 3–4, we have


                                                        (2 2)2 − 4   8−4
                         S=2 2        ⇒    κCHSH =                 =     = 1.
                                                            4         4

So the lawful Bell frame is a maximally curved CHSH configuration in the Λₘ geometry, saturating the
Tsirelson boundary while remaining within Hlawful .




7. Embedding into AZ–TFTC / ZM Frames (Sketch)
    1. Prime cavities and modes. The prime labels pA0 , pA1 , pB0 , pB1 can be realized as prime-indexed
       cavity modes or prime-tagged ions in an AZ–TFTC or ZM-type experimental architecture.

                                                                        (⋅)   (⋅)
    2. Universal operator U and time sieve. The Pauli-like operators σz , σx arise as effective blocks of
       the universal operator U = A + B + E , where the time-sieve block B = F −1 Mm F and the error




                                                    6
      block E are constrained by lawfulness. The CHSH settings correspond to specific compositions of
      prime-gated evolution segments.


    3. Atlas / BNUT frame. In the BNUT non-locality frame, the CHSH curvature scalar κCHSH provides a
      frame-relational measure of non-local lawfulness, which can be compared across experimental
      platforms (ion traps, superconducting qubits, fractal cavities) via the Λₘ metric.


    4. Certification. Because the Bell sector is finite-dimensional and prime-gated, spectra of all
      observables Ai , Bj and of BCHSH are exactly computable, allowing explicit GapLB/SlopeUB bounds
      and PETC-style prime-signature checks. Thus the MR–CHSH construction is fully compatible with the
      lawfulness certification stack.




8. Summary
     • A prime-encoded Bell sector is defined inside Hlawful using four distinct primes.
     • A Bell state ∣Φ+ ⟩ is written purely in terms of these primes.
     • CHSH observables A0 , A1 , B0 , B1 are constructed as prime-gated Pauli-like operators.
     • The E-table yields E00 = E01 = E10 = 1/   2, E11 = −1/ 2, giving S = 2 2.
                                               2
     • The CHSH curvature scalar κCHSH = (S − 4)/4 is introduced as a Λₘ-curvature invariant, with
       κCHSH = 1 for the prime-encoded Bell frame.

This provides a canonical MR–style CHSH construction that can be referenced by higher-level Atlas, ZM, and
AZ–TFTC experimental designs (including multi-ion and Atlas-cavity Bell tests).




                                                    7
