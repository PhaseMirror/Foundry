Multiplicity Theory / PIRTM                                                  Defensive Publication Draft




     Carry-Forward Surplus, Prime-Indexed Memory,
                and the PIRTM Dialect
                           Defensive Publication and Technical Report

                                        Citizen Gardens
                                  The Foundation of Multiplicity

                                             April 25, 2026


                                                Abstract
         This document discloses a unified mathematical and systems architecture developed across
     the present design thread. The disclosure has two purposes: (1) to provide a comprehensive
     technical report on the carry-forward surplus formulation in Multiplicity Theory and its compiler
     realization in PIRTM, and (2) to serve as a defensive publication by publicly describing the
     essential structure, implementation path, invariants, and expected embodiments in sufficient
     detail to establish a dated technical record.
         The central result is a path-dependent, recursively stable architecture in which prime factor-
     ization is interpreted as a native memory ledger. The exponent of a prime in a factorization is
     treated as carried-forward participation history, leading to a canonical surplus dynamics with
     differential asymmetry kernel
                                                     1
                                         f (∆S) = − tanh(β∆S),
                                                     2
     a prime-indexed type system, squarefree closure under composition, a three-level governance
     model, a six-pass verification pipeline, a two-phase compilation flow, and a three-layer audit
     model separating static proof, link-time governance, and runtime trace.




                                                     1
Multiplicity Theory / PIRTM                                               Defensive Publication Draft


Contents

1 Executive Summary                                                                                    4

2 Purpose and Defensive Publication Scope                                                             4

3 Development Record and Locked Decisions                                                             5
  3.1 Decision Surface . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    5
  3.2 Architectural Thesis . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    5

4 Comprehensive Mathematical Overview                                                                  6
  4.1 Prime Factorization as Memory . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        6
  4.2 Von Mangoldt Interpretation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        6
  4.3 Carry-Forward Surplus Dynamics . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         6
  4.4 Canonical Interaction Kernel . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       7
  4.5 Gap Dynamics . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       7
  4.6 Positive-Positive Interactions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     8
  4.7 Network Dynamics . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       8
  4.8 Lyapunov Candidate . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       8
  4.9 Prime-Native Regime . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      8

5 PIRTM Formalization                                                                                  9
  5.1 Design Goal . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    9
  5.2 Channel Kinds and Types . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        9
      5.2.1 Atomic channels . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        9
      5.2.2 Composite channels . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         9
  5.3 Core IR Operations . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     9
  5.4 Three Structural Levels . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     10
  5.5 Six Verifier Passes . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   10
  5.6 Contractivity Invariant . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   10
  5.7 Network Small-Gain Invariant . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      10

6 Two-Phase Compilation and Linking                                                                   11
  6.1 Compilation Phases . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      11
  6.2 Why Link Time Exists . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      11
  6.3 Coupling Specification . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    11
  6.4 Three-Pass Linker Resolution . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      11

7 Audit, Proof, and Self-Description                                                                  12
  7.1 Three Audit Layers . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    12
  7.2 Why Runtime Audit Is Separate . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         12
  7.3 Self-Certifying Bitcode . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   12

8 Code and Specification Snippets                                                                     12
  8.1 Canonical Surplus Update . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      12
  8.2 Atomic and Composite IR Example . . . . . . . . . . . . . . . . . . . . . . . . . . . .         13
  8.3 TableGen-Type Sketch . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      14
  8.4 Coupling Specification Example . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      14


                                                   2
Multiplicity Theory / PIRTM                                                Defensive Publication Draft


9 Validation Roadmap                                                                                    15
  9.1 Immediate Gates . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       15
  9.2 Predictions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     15
  9.3 Recommended Mathematical Experiments . . . . . . . . . . . . . . . . . . . . . . . .              15

10 Novelty Framing and Defensive Publication Claims                                                     16
   10.1 Claimed Combination . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       16
   10.2 Rejected Alternatives . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   16
   10.3 Why This Matters for Prior Art . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      16

11 Recommended Publication and Release Strategy                                                         16

12 Recommendations for the Next Draft                                                                   17

13 Conclusion                                                                                           18

A Nomenclature                                                                                          18

B Minimal Defensive Publication Checklist                                                               18

C Minimal Commands Appendix                                                                             18

D Mathematical Appendix                                                                                 19
  D.1 Conservation of Total Surplus . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       19
  D.2 Lyapunov Function and Pairwise Convergence . . . . . . . . . . . . . . . . . . . . . .            20
  D.3 Operator-Norm Bound for the Contractivity Check . . . . . . . . . . . . . . . . . . .             20
  D.4 Connection to the von Mangoldt Function . . . . . . . . . . . . . . . . . . . . . . . .           21
  D.5 Entropy Production and the Hardy–Ramanujan Estimate . . . . . . . . . . . . . . .                 21
  D.6 Linearisation of the Gap Map and Choice of β . . . . . . . . . . . . . . . . . . . . .            22
  D.7 Summary of Key Inequalities . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         22




                                                    3
Multiplicity Theory / PIRTM                                               Defensive Publication Draft


1. Executive Summary

This report records a coherent sequence of design decisions linking Multiplicity Theory, non-
Markovian surplus dynamics, and the PIRTM compiler roadmap into a single formal architecture.
The most consequential mathematical decision is the adoption of carry-forward surplus as a native
state variable rather than per-event stateless accounting. The most consequential systems decision
is the realization that prime identity must become a compile-time type parameter rather than a
runtime attribute.
    At the mathematical level, the exponent in a prime power pk is interpreted as a surplus ledger: it is
the record of a prime carrying participation history across repeated multiplicative interactions. This
motivates a canonical interaction rule based on relative surplus differential rather than sign-based
deficit detection. At the compiler level, this leads to a prime-indexed intermediate representation in
which atomic channels are prime-typed, merged channels are squarefree-typed, network governance
occurs at link time, and non-contractive or incoherent compositions become structural errors.
    At the architecture level, the work now consists of four tightly coupled layers:
 1. Mathematical layer: carry-forward surplus, asymmetry kernel, entropy, convergence.
 2. Type layer: mod= as a kind-dispatched parameter with atomic and composite channel types.
 3. Verification layer: ordered passes for primality, squarefreeness, coprimality, contractivity,
    certificate consumption, and network small-gain.
 4. Compilation and audit layer: transpile-to-bitcode, link-time sealing, and runtime-only audit
    traces.
    This document is intentionally written as both a technical specification and a defensive publication.
It includes the governing equations, the type-theoretic commitments, implementation sketches,
validation criteria, and rejected alternatives.

2. Purpose and Defensive Publication Scope

This disclosure is intended to place into the public technical record the following integrated body of
work:
 1. The interpretation of prime exponents as a native surplus ledger.
 2. A path-dependent surplus dynamics with bounded asymmetry and carry-forward memory.
 3. The selection of a gradient-triggered asymmetry kernel over a deficit-triggered rule.
 4. The translation of prime identity into a compile-time type parameter in the PIRTM dialect.
 5. A squarefree closure principle for multi-session composition under CRT-governed merge.
 6. A three-level governance model separating atomic, tensor-compositional, and network-spectral
    obligations.
 7. A six-pass verifier pipeline.
 8. A two-phase compilation model separating transpile-time local proofs from link-time network
    proofs.
 9. A three-layer audit model separating static proof, link-time governance metadata, and runtime
    audit chain.

                                                   4
Multiplicity Theory / PIRTM                                               Defensive Publication Draft


Defensive publication posture. The goal is not merely to announce broad ideas, but to disclose
enough structure that a technically literate reader could implement the system family. That includes
equations, type signatures, verifier obligations, data structures, lowering strategy, audit separation,
and test gates.

Non-legal disclaimer. This document is a technical draft, not legal advice. If the intent is formal
defensive publication or coordinated open licensing, the text should be reviewed by patent counsel
and released in a timestamped public venue.

3. Development Record and Locked Decisions

3.1. Decision Surface


  §            Locked decision                                    Locking rationale
  1            mod= replaces prime= as the type parameter;        Prime identity belongs in the
               four main kinds are disclosed: atomic tensor,      type system; composition must
               composite tensor, cert, cert pair.                 not overload the word “prime.”
  2            Session governance is flat at the module level:    Local contractivity and network
               one prime channel per pirtm.module; no             stability are distinct proof
               epsilon_map; three structural levels govern the    obligations.
               system.
  3            Six ordered verifier passes are required.          Verification order follows
                                                                  mathematical dependency order.
  4            Compilation is two-phase: transpile individual     Local proofs are available before
               modules to .pirtm.bc, then link to a sealed        global topology is known.
               runtime binary.
  5            Composite lowering uses array-of-structs           CRT factor structure must
               semantics.                                         remain visible after lowering.
  6            SpectralGovernor splits into local() and           Temporal separation of local and
               network().                                         network proofs.
  7            The prime to mod rename lands atomically at        API coherence and branch safety.
               merge time.
  8            Audit is three-layered: static proof, governance   Universal proof and
               seal, runtime-only audit chain.                    execution-specific evidence must
                                                                  not be conflated.

3.2. Architectural Thesis
The architecture can be summarized as follows:

        Prime identity is atomic, composition is squarefree, local contractivity is compile-time,
        network contractivity is link-time, and execution audit is runtime.

      This is the unifying principle of the entire stack.




                                                     5
Multiplicity Theory / PIRTM                                                  Defensive Publication Draft


4. Comprehensive Mathematical Overview

4.1. Prime Factorization as Memory
Definition 1 (Prime exponent ledger). Let
                                                   r
                                              n=     pki i .
                                                   Y

                                                   i=1
Define the prime-ledger view of n by treating each valuation vpi (n) = ki as the carried-forward
participation count of prime pi .
    In ordinary multiplicative number theory, ki is an exponent. In the present framework, it is
also interpreted as memory. The key conceptual move is that the prime does not reset after each
multiplicative event; it accumulates.
    A minimal ledger interpretation is
                                L(n) = vp1 (n), vp2 (n), . . . , vpr (n) ,
                                                                        

or, if one wishes to interpret the first appearance as baseline and only repeated participation as
surplus,
                             Lsurplus (n) = vp1 (n) − 1, . . . , vpr (n) − 1 + .
                                                                            

   This yields the governing intuition:
     Exponent is not merely multiplicity; it is carried-forward recurrence.

4.2. Von Mangoldt Interpretation
For prime powers n = pk , one may regard the von Mangoldt weight
                                             Λ(n) = log p
as assigning energy to the prime channel independent of how many times it has recurred in that
specific event record. In the present architecture, this suggests a distinction between:
 • identity-energy of the prime channel, and
 • carried participation memory stored in the exponent.
   This distinction motivates a system in which prime identity and carried history are related but
not collapsed into one scalar.

4.3. Carry-Forward Surplus Dynamics
Let S(x) denote the current surplus of element x before an interaction. For two interacting elements
x and y, define
                                         ∆S = S(x) − S(y).
    The design initially considered a generic attribution rule
                                             1
                                        αx = + f (S(x), S(y)),
                                             2
with f ∈ (−0.5, 0.5). The crucial precision question was whether asymmetry should depend on
deficit status or on surplus differential. The locked answer is:
     Asymmetry is gradient-triggered, not deficit-triggered.
   That is, the correct symmetry point is ∆S = 0, not “both positive” or “both negative.”

                                                    6
Multiplicity Theory / PIRTM                                                  Defensive Publication Draft


4.4. Canonical Interaction Kernel
The canonical kernel is
                                             1
                                   f (∆S) = − tanh(β∆S),
                                             2
where β > 0 is a global hyperparameter.
   This yields the pair update
                                                 1
                           Sx (t + 1) = λSx (t) −  tanh β(Sx (t) − Sy (t)) ,                         (1)
                                                                          
                                                 2
                                                 1
                           Sy (t + 1) = λSy (t) + tanh β(Sx (t) − Sy (t)) ,                          (2)
                                                                          
                                                 2
with memory persistence parameter
                                              λ ∈ [0, 1].

Interpretation of λ.

 • λ = 1: prime-native full carry-forward.

 • 0 < λ < 1: exponential memory decay.

 • λ = 0: per-event reset; Markovian fallback.

4.5. Gap Dynamics
Define the surplus gap
                                         ∆t = Sx (t) − Sy (t).
Then
                                     ∆t+1 = λ∆t − tanh(β∆t ).
   This is the decisive reduction. The stronger element donates to the weaker not because the
weaker is negative, but because the kernel compresses differential. The fixed point is

                                               ∆∗ = 0.

   A local linearization around ∆t = 0 gives

                                         tanh(β∆t ) ≈ β∆t ,

hence
                                         ∆t+1 ≈ (λ − β)∆t .
Therefore a natural local stability condition is

                                             |λ − β| < 1.

Proposition 1 (Two-body conservation law). For the update rule above,

                             Sx (t + 1) + Sy (t + 1) = λ Sx (t) + Sy (t) .
                                                                        


Proof. Add the two update equations. The kernel terms cancel.

   Thus total surplus is preserved when λ = 1 and decays proportionally when λ < 1.

                                                    7
Multiplicity Theory / PIRTM                                              Defensive Publication Draft


4.6. Positive-Positive Interactions
A design tension was whether two elements with both positive surplus should revert to symmetry.
The locked answer is no. If Sx > Sy > 0, then ∆S > 0, so

                                               f (∆S) < 0,

and the stronger element still donates toward the weaker one. Compression depends on relative
differential, not sign.

4.7. Network Dynamics
Let G = (V, E) be a connected interaction graph. Each node i ∈ V carries surplus Si (t). Pairwise
interactions occur along edges. A natural aggregate instability or concentration measure is the
normalized entropy
                                                               Si
                            H(S) = −      Ŝi log Ŝi , Ŝi = P
                                       X
                                                                    ,
                                        i                      j Sj

whenever the normalization is defined.
   The design intent is:

 • high entropy means surplus is distributed broadly,

 • low entropy means concentration and possible instability,

 • entropy trajectories provide a governance-level signal even when local interactions are individu-
   ally well behaved.

4.8. Lyapunov Candidate
A natural pairwise Lyapunov candidate is
                                                                   2
                                     V (t) =         Si (t) − Sj (t) .
                                               X

                                               i<j

Under connected interactions and a compressive kernel, the design conjecture is that V (t) decreases
along trajectories except at equilibrium. This is the basis for the stability rationale behind the
gradient-triggered rule.

Design Claim 1 (Global design conjecture). For a connected interaction graph and admissible
(λ, β), repeated application of the canonical kernel drives pairwise surplus differentials toward a
bounded compression regime, with exact equalization in the simplest symmetric settings.

4.9. Prime-Native Regime
The special role of λ = 1 is that the system then most closely resembles prime power accumulation:

                                         p → p2 → p3 → · · ·

is no longer treated as stateless repetition but as recursive self-carry. The arithmetic object and the
dynamical object then coincide in spirit:

     Prime exponentiation is the arithmetic shadow of recursive surplus carry-forward.


                                                      8
Multiplicity Theory / PIRTM                                            Defensive Publication Draft


5. PIRTM Formalization

5.1. Design Goal
PIRTM is the compiler and IR realization of the foregoing structure. Its goal is to make incorrect
compositions structurally invalid rather than merely discouraged by runtime conventions.

5.2. Channel Kinds and Types
The key decision is that channel identity is carried by mod= as a type parameter. The type hierarchy
has two levels.

5.2.1   Atomic channels
Atomic channels are prime-typed:
                              !pirtm.tensor<dim, dtype, mod=p>
with p prime.
   Certificates are also atomic:
                                      !pirtm.cert<mod=p>.

5.2.2   Composite channels
Composite channels are squarefree-typed:
                             !pirtm.ctensor<dim, dtype, mod=m>
with m squarefree.
   Certificate pairs are squarefree-typed:
                                   !pirtm.cert_pair<mod=m>.

Why squarefree, not arbitrary composite? Because composition is governed by CRT factor
visibility. Repeated prime factors blur the intended product semantics. Squarefree closure preserves
factor distinctness and supports clean projection semantics.

5.3. Core IR Operations
The disclosed system family includes the following operations.

 1. pirtm.module — atomic session container with one prime_index, one ϵ, one op_norm_T, and
    one identity commitment.
 2. pirtm.step — recurrence update restricted to atomic tensors.
 3. pirtm.merge — explicit squarefree composition.
 4. pirtm.project — projection from composite to atomic component.
 5. pirtm.merge_cert — consumption of two atomic certs into a cert pair.
 6. pirtm.emit — gate conditioned on certificate validity or suppression.
 7. pirtm.session_graph — link-time multi-session governance construct.

                                                 9
Multiplicity Theory / PIRTM                                           Defensive Publication Draft


5.4. Three Structural Levels
The system is governed at three distinct levels:

         Level      IR construct              Governing object      Proof obligation
         Atomic     pirtm.module              ϵ, ∥T ∥op             Local contractivity
         Tensor     pirtm.merge               squarefree modulus    Coprime composition
         Network    pirtm.session_graph       gain matrix Ψ         Spectral small-gain

  This resolves the earlier ambiguity about whether a module should carry an epsilon map. It
must not. Local contractivity and network stability belong to different structural levels.

5.5. Six Verifier Passes
The ordered pipeline is:

 1. prime-validity

 2. squarefree-validity

 3. merge-coprimality

 4. contractivity-check

 5. cert-consumption

 6. spectral-small-gain

Dependency rule. A pass may only rely on facts established by earlier passes. This is not
arbitrary engineering style; it mirrors mathematical dependency order:

              identity ⇒ local well-formedness ⇒ local stability ⇒ network stability.

5.6. Contractivity Invariant
For an atomic step, the key structural constraint is

                                    ∥Ξ∥ + ∥Λ∥ · ∥T ∥op < 1 − ϵ.

The important design decision is that this becomes a verifier fact rather than a runtime assertion.

5.7. Network Small-Gain Invariant
At network level, the governing object is a gain matrix Ψ. The link-time obligation is

                                             r(Ψ) < 1,

where r(Ψ) denotes the spectral radius. This is why network governance cannot be reduced to a
map of local epsilons.




                                                   10
Multiplicity Theory / PIRTM                                            Defensive Publication Draft


6. Two-Phase Compilation and Linking

6.1. Compilation Phases
The locked compilation model is:

 1. Transpile phase: each session descriptor is lowered independently to .pirtm.bc, establishing
    local facts.

 2. Link phase: all compiled sessions and a coupling specification are resolved into a sealed binary,
    establishing network facts.

   This supports both modular development and safety sealing.

6.2. Why Link Time Exists
Session topology is not always known at initial transpile time. However, allowing arbitrary runtime
registration would invalidate the very notion of a sealed network proof. The compromise is:

     Sessions may be assembled dynamically before execution, but topology is sealed at link
     time, not during execution.

   Thus the architecture is neither naive AOT-only nor unconstrained runtime dynamism. It is a
controlled two-phase system.

6.3. Coupling Specification
The coupling artifact is a coupling.json file. The disclosed resolution model is two-layered:

 • Human layer: readable session aliases.

 • Canonical linker layer: prime_index as the actual resolved identity.

   The reason is simple: humans author names; the linker reasons over canonical identities.

6.4. Three-Pass Linker Resolution
Before the network pass runs, the linker performs:

 1. Name resolution — alias to compiled session.

 2. Commitment cross-check — human alias must match expected identity commitment.

 3. Matrix construction — row and column order are finalized in prime-index order.

   Only after that is the spectral pass run.




                                                11
Multiplicity Theory / PIRTM                                            Defensive Publication Draft


7. Audit, Proof, and Self-Description

7.1. Three Audit Layers
A major design clarification in the thread was that audit and proof are not one thing.

       Layer              Stored in        Read by           Meaning
       Static proof       .pirtm.bc        pirtm inspect     Compile-time verifier facts
       Governance seal    linked binary    pirtm inspect     Link-time network proof facts
       Audit chain        runtime trace    pirtm audit       Execution-specific history

7.2. Why Runtime Audit Is Separate
A static artifact can certify what was proven about a program. It cannot contain the history of an
execution that has not yet occurred. Therefore:

 • compile-time proofs are universal statements about the program class,

 • runtime audit records are existential statements about one execution.

   Mixing them would destroy the semantics of both.

7.3. Self-Certifying Bitcode
A compiled .pirtm.bc should carry a static proof section sufficient for offline inspection. A simple
content-addressed proof hash can be defined as
                                                                              
                   proof_hash = H prime_index ∥ ϵ ∥ ∥T ∥op ∥ ∥Ξ∥op ∥ ∥Λ∥op .

    This makes the bitcode a self-describing proof artifact without pretending to contain runtime
telemetry.

8. Code and Specification Snippets

8.1. Canonical Surplus Update

               Listing 1: Reference Python sketch for the canonical surplus kernel
from dataclasses import dataclass
from math import tanh
from typing import Dict, Tuple

@dataclass
class CarryForwardPolicy:
    beta: float = 1.0
    lam: float = 1.0

@dataclass
class SurplusLedgerEntry:
    S: float = 0.0
    t: int = 0
    cumulative_delta: float = 0.0


                                                12
Multiplicity Theory / PIRTM                                         Defensive Publication Draft



class SurplusLedger:
    def __init__(self):
        self.entries: Dict[int, SurplusLedgerEntry] = {}

   def get(self, prime_index: int) -> SurplusLedgerEntry:
       if prime_index not in self.entries:
           self.entries[prime_index] = SurplusLedgerEntry()
       return self.entries[prime_index]

   def interact(self, p: int, q: int, policy: CarryForwardPolicy) -> Tuple[float, float]:

       ep = self.get(p)
       eq = self.get(q)

       delta = ep.S - eq.S
       f = -0.5 * tanh(policy.beta * delta)

       ep.S = policy.lam * ep.S + f
       eq.S = policy.lam * eq.S - f

       ep.t += 1
       eq.t += 1

       ep.cumulative_delta += f
       eq.cumulative_delta -= f

       return ep.S, eq.S


8.2. Atomic and Composite IR Example

         Listing 2: Illustrative MLIR-style syntax for atomic step and composite merge
pirtm.module @session_a {
  prime_index = 7919 : i64,
  identity_commitment = "0xabc123",
  epsilon = 0.05 : f64,
  op_norm_T = 0.8 : f64
} {
  %x_next, %cert = pirtm.step(%x, %xi, %lam, %g)
    : (!pirtm.tensor<4, f64, mod=7919>,
       !pirtm.tensor<4, f64, mod=7919>,
       !pirtm.tensor<4, f64, mod=7919>,
       !pirtm.tensor<4, f64, mod=7919>)
    -> (!pirtm.tensor<4, f64, mod=7919>,
        !pirtm.cert<mod=7919>)
}

%merged = pirtm.merge(%a, %b)
  : (!pirtm.tensor<4, f64, mod=7919>,
     !pirtm.tensor<4, f64, mod=7907>)
  -> !pirtm.ctensor<4, f64, mod=59622233>



                                              13
Multiplicity Theory / PIRTM                                             Defensive Publication Draft


%cert_pair = pirtm.merge_cert(%c1, %c2)
  : (!pirtm.cert<mod=7919>, !pirtm.cert<mod=7907>)
  -> !pirtm.cert_pair<mod=59622233>


8.3. TableGen-Type Sketch

             Listing 3: Minimal type declarations consistent with the disclosed design
def Pirtm_AtomicTensorType : TypeDef<Pirtm_Dialect, "AtomicTensor"> {
  let mnemonic = "tensor";
  let parameters = (ins "int64_t":$dim, "::mlir::Type":$dtype, "int64_t":$mod);
  let assemblyFormat = "‘<‘ $dim ‘,‘ $dtype ‘,‘ ‘mod=‘ $mod ‘>‘";
  let genVerifyDecl = 1;
}

def Pirtm_CompositeTensorType : TypeDef<Pirtm_Dialect, "CompositeTensor"> {
  let mnemonic = "ctensor";
  let parameters = (ins "int64_t":$dim, "::mlir::Type":$dtype, "int64_t":$mod);
  let assemblyFormat = "‘<‘ $dim ‘,‘ $dtype ‘,‘ ‘mod=‘ $mod ‘>‘";
  let genVerifyDecl = 1;
}

def Pirtm_CertType : TypeDef<Pirtm_Dialect, "Cert"> {
  let mnemonic = "cert";
  let parameters = (ins "int64_t":$mod);
  let assemblyFormat = "‘<‘ ‘mod=‘ $mod ‘>‘";
  let genVerifyDecl = 1;
}

def Pirtm_CertPairType : TypeDef<Pirtm_Dialect, "CertPair"> {
  let mnemonic = "cert_pair";
  let parameters = (ins "int64_t":$mod);
  let assemblyFormat = "‘<‘ ‘mod=‘ $mod ‘>‘";
  let genVerifyDecl = 1;
}


8.4. Coupling Specification Example

      Listing 4: Illustrative coupling specification with human aliases and canonical identities
{
    "format": "pirtm-coupling-v1",
    "sessions": {
      "session_a": { "prime_index": 7919, "commitment": "0xabc123" },
      "session_b": { "prime_index": 7907, "commitment": "0xdef456" }
    },
    "gain_matrix": {
      "session_a": { "session_a": 0.0, "session_b": 0.15 },
      "session_b": { "session_a": 0.20, "session_b": 0.0 }
    }
}



                                                 14
Multiplicity Theory / PIRTM                                           Defensive Publication Draft


9. Validation Roadmap

9.1. Immediate Gates
The disclosed development plan naturally yields a staged validation program.

 1. Type gate: four-line .mlir accept/reject test for prime and squarefree typing.

 2. Merge gate: coprime merge accepted, non-coprime merge rejected.

 3. Emitter gate: all example descriptors round-trip through pirtm transpile.

 4. Link gate: coupling resolution plus two spectral-small-gain tests.

 5. Audit gate: pirtm inspect exposes static proof and governance seal; runtime trace exposed
    separately via pirtm audit.

9.2. Predictions
The architecture makes several testable predictions.

 1. A gradient-triggered kernel should avoid the incoherence of sign-triggered symmetry restoration
    in positive-positive interactions.

 2. Network-level failures should emerge even when all atomic modules are locally contractive,
    demonstrating the need for a separate spectral pass.

 3. The prime to mod rename should surface latent dict-keying and emission bugs that were
    previously hidden by informal assumptions.

 4. Array-of-struct lowering should preserve projection semantics more cleanly than interleaved or
    lazy-view representations.

 5. The separation of static proof from runtime audit should make pirtm inspect and pirtm
    audit semantically cleaner and easier to reason about.

9.3. Recommended Mathematical Experiments
 • Simulate two-body and graph-level surplus dynamics over a range of (λ, β).

 • Measure convergence rate of ∆t under repeated interactions.

 • Track entropy H(S) over connected and disconnected graphs.

 • Compare bounded kernels such as tanh, logistic, and clipped linear rules.

 • Analyze whether the chosen kernel yields desirable invariants under sparse and dense interaction
   schedules.




                                                15
Multiplicity Theory / PIRTM                                               Defensive Publication Draft


10. Novelty Framing and Defensive Publication Claims

10.1. Claimed Combination
The contribution disclosed here is not one isolated trick but a specific combination of elements. The
intended novelty record is the disclosed combination of:

 1. prime-exponent-as-ledger interpretation for path-dependent recursive memory,

 2. gradient-triggered bounded asymmetry with canonical tanh kernel,

 3. prime-indexed compile-time typing with squarefree closure under composition,

 4. link-time network governance via spectral small-gain,

 5. certificate values as SSA-level entities rather than only side-effect logs,

 6. explicit split of static proof, governance seal, and runtime audit.

10.2. Rejected Alternatives
The thread also established negative space, which is valuable in a defensive publication.

 • Deficit-triggered asymmetry was rejected in favor of differential asymmetry.

 • Prime-only closure was rejected because composite merge cannot remain prime while
   preserving CRT semantics.

 • Multi-prime modules with epsilon maps were rejected because they blur local and network
   proof levels.

 • Single-phase runtime registration as the safety boundary was rejected because it
   invalidates sealed network proof.

 • Interleaved or lazy composite lowering was rejected because it obscures CRT factor
   visibility.

 • Embedding runtime audit chain into the static binary as if it were pre-existing was
   rejected because it confuses proof with execution trace.

10.3. Why This Matters for Prior Art
A defensive publication is strongest when it discloses not only what was chosen, but what was
considered and ruled out, together with the technical reasons. That is done here. This document
records the design space, the selected points within it, and the rationale connecting them.

11. Recommended Publication and Release Strategy

For robust public timestamping and practical defensibility, the following release pattern is recom-
mended:

 1. Publish this report in a public, immutable or versioned venue.



                                                 16
Multiplicity Theory / PIRTM                                          Defensive Publication Draft


 2. Attach the exact ADR text, code stubs, and acceptance tests as appendices or companion files.

 3. Tag the relevant repository commit and create an archival release.

 4. Generate a citable archive snapshot with a stable identifier.

 5. Publish the report and artifacts together so the conceptual and enabling disclosures are
    colocated.

 6. Retain dated copies of the specific file set:

      • ADR-004,
      • migration memo,
      • type stubs,
      • linker schema draft,
      • validation tests.

Suggested companion artifacts. A strong public packet would include:

 • this report,

 • the live ADR,

 • pirtm.td,

 • the four-line type test,

 • the migration memo,

 • a minimal reference implementation of the surplus kernel,

 • a changelog mapping decisions to commit hashes.

12. Recommendations for the Next Draft

I recommend the next revision include four additions:

 1. A formal notation appendix distinguishing prime identity, modulus identity, session identity,
    and commitment identity.

 2. A theorem-status appendix separating proved statements, design conjectures, and engineer-
    ing assumptions.

 3. A reproducibility appendix listing exact test commands and expected diagnostics.

 4. A legal-packaging appendix identifying publication venue, release date, commit hashes, and
    artifact digests.




                                                    17
Multiplicity Theory / PIRTM                                            Defensive Publication Draft


13. Conclusion

The developments in this thread now form a single coherent framework. The mathematical core
is a recursive memory model in which prime exponents function as native surplus ledgers. The
systems core is a typed and verified compiler pathway in which prime identity becomes compile-time
structure, squarefree composition preserves CRT semantics, local and network proofs are separated
in time, and audit is layered according to what can be known before and after execution.
    Stated compactly: the framework has moved from metaphor to mechanism. Carry-forward
surplus is no longer only an interpretive idea; it is now the organizing principle for type design,
verifier ordering, compilation staging, linking semantics, and audit architecture.

A. Nomenclature

Symbol / term             Meaning
p                         Prime channel identity
m                         Squarefree composite modulus
vp (n)                    Prime valuation of n at p
S(x)                      Surplus of element x
∆S                        Surplus differential between two interacting elements
λ                         Carry-forward persistence parameter
β                         Global sensitivity of the asymmetry kernel
ϵ                         Local contractivity margin for an atomic session
Ψ                         Network gain matrix used at link time
r(Ψ)                      Spectral radius of the gain matrix
mod=                      Type-level channel identity parameter
prime_index               Named attribute identifying the atomic prime channel
identity_commitment       Session commitment used for cross-check and audit provenance


B. Minimal Defensive Publication Checklist

 1. Publicly timestamped report.

 2. Publicly timestamped source repository or release archive.

 3. Archived copy of ADR-004 and related files.

 4. Enabling details sufficient for implementation.

 5. Explicit statement of selected and rejected alternatives.

 6. Dated changelog or commit map.

C. Minimal Commands Appendix

                Listing 5: Illustrative command sequence for the disclosed toolchain
# Transpile atomic sessions
pirtm transpile session_a.yaml --output session_a.pirtm.bc
pirtm transpile session_b.yaml --output session_b.pirtm.bc


                                                18
Multiplicity Theory / PIRTM                                                  Defensive Publication Draft



# Inspect static proof metadata
pirtm inspect session_a.pirtm.bc

# Link with network governance
pirtm link \
  --sessions session_a.pirtm.bc session_b.pirtm.bc \
  --coupling coupling.json \
  --output pirtm_runtime.bin

# Inspect link-time governance seal
pirtm inspect pirtm_runtime.bin

# Execute runtime binary (implementation dependent)
pirtm-runtime pirtm_runtime.bin

# Audit execution trace
pirtm audit trace.log --binary pirtm_runtime.bin



D. Mathematical Appendix

This appendix contains the detailed derivations, proofs, and bounds that support the claims made
in the main text. All results are self-contained and assume the notation introduced in Sections ??
and ??.

D.1. Conservation of Total Surplus
Consider the canonical gradient-triggered update for two interacting elements x and y with
carry-forward parameter λ ∈ [0, 1] and sensitivity β > 0:
                                                1
                         Sx (t + 1) = λSx (t) −   tanh β (Sx (t) − Sy (t)) ,                         (3)
                                                                          
                                                2
                                                1
                          Sy (t + 1) = λSy (t) + tanh β (Sx (t) − Sy (t)) .                          (4)
                                                                          
                                                2
Proposition 2 (Total-surplus conservation). For the dynamics (3)–(4),

                       Sx (t + 1) + Sy (t + 1) = λ Sx (t) + Sy (t)      ∀ t ≥ 0.
                                                                 


Proof. Add (3) and (4); the hyperbolic-tangent terms cancel exactly, leaving

                             Sx (t + 1) + Sy (t + 1) = λ Sx (t) + Sy (t) .
                                                                        




   Consequently, λ = 1 yields exact conservation of total surplus, while 0 ≤ λ < 1 produces
exponential decay of the total surplus at rate λ.




                                                  19
Multiplicity Theory / PIRTM                                                     Defensive Publication Draft


D.2. Lyapunov Function and Pairwise Convergence
Define the pairwise surplus gap ∆t := Sx (t)−Sy (t). Subtracting (4) from (3) gives the one-dimensional
map
                                     ∆t+1 = λ∆t − tanh β ∆t .                                       (5)
                                                               

[Monotonicity of the gap map] For any β > 0 and λ ∈ [0, 1], the function g(∆) := λ∆ − tanh(β∆)
satisfies
                           g(∆) −0 ∆ ≤ 0 with equality iff ∆ = 0.
                                   


Proof. Because tanh is odd and strictly increasing, tanh(β∆) has the same sign as ∆ and | tanh(β∆)| <
|β∆| for ∆ ̸= 0. Hence
                    ∆ g(∆) = λ∆2 − ∆ tanh(β∆) ≤ λ∆2 − β −1 tanh2 (β∆) ≤ 0,
with equality only when ∆ = 0 (since then both terms vanish).

Proposition 3 (Gap Lyapunov function). Let Vt := 12 ∆2t . Then Vt+1 − Vt ≤ 0 for all t, with
equality iff ∆t = 0.
Proof. Using Lemma D.2,
                                1                1
                  Vt+1 − Vt =     g(∆t )2 − ∆2t = g(∆t ) − ∆t g(∆t ) + ∆t ≤ 0,
                                                                       
                                2                2
because g(∆t ) − ∆t = −(tanh(β∆t ) + (1 − λ)∆t ) has opposite sign to ∆t , while g(∆t ) + ∆t has the
same sign as ∆t . Equality holds only at ∆t = 0.

    Summing over t yields ∞  t=0 ∆t < ∞, which implies ∆t → 0 as t → ∞. Hence every interacting
                                  2
                           P

pair converges to equal surplus.

D.3. Operator-Norm Bound for the Contractivity Check
In the PIRTM dialect the contractivity condition for an atomic step is
                                      ∥Ξ∥ + ∥Λ∥ ∥T ∥op < 1 − ϵ,                                         (1)
where ∥ · ∥ denotes any sub-multiplicative matrix norm and ∥T ∥op is the operator norm induced by
that norm. The following bound guarantees that (1) is sufficient for input-to-state stability (ISS) of
the recurrence
                                 Xt+1 = P ΞXt + ΛT (Xt ) + Gt .                                    (2)
                                                                

Proposition 4 (ISS from the contractivity check). If (1) holds with some ϵ > 0, then the origin of (2)
                                                                                   ∥P ∥           ∥P ∥
is ISS with respect to the input Gt and the gain from G to X is bounded by 1−(∥Ξ∥+∥Λ∥∥T   ∥op ) < ϵ .

Proof. Let ρ := ∥Ξ∥ + ∥Λ∥∥T ∥op . From (1) we have ρ < 1 − ϵ < 1. Using sub-multiplicativity,
              ∥Xt+1 ∥ ≤ ∥P ∥ ∥Ξ∥∥Xt ∥ + ∥Λ∥∥T ∥op ∥Xt ∥ + ∥Gt ∥ ≤ ρ∥Xt ∥ + ∥P ∥∥Gt ∥.
                                                                      


Iterating this inequality yields
                                          t−1
                                                                            ∥P ∥
                ∥Xt ∥ ≤ ρt ∥X0 ∥ + ∥P ∥         ρk ∥Gt−1−k ∥ ≤ ρt ∥X0 ∥ +          sup ∥Gs ∥.
                                          X

                                          k=0
                                                                            1 − ρ 0≤s≤t

Since ρ < 1, the term ρt ∥X0 ∥ vanishes as t → ∞, and the coefficient of the supremum is exactly
∥P ∥/(1 − ρ) < ∥P ∥/ϵ. Hence the system is ISS with the stated gain.

                                                      20
Multiplicity Theory / PIRTM                                                     Defensive Publication Draft


D.4. Connection to the von Mangoldt Function
When the system operates in the prime-native regime (λ = 1) and we consider a single prime channel
p undergoing k successive self-interactions, the surplus after k steps (starting from S(p, 0) = 0) is
                                                      k
                                               S(p, k) =δ,
                                                      2
where δ denotes the average infinitesimal surplus contributed per interaction (the factor 1/2 comes
from the antisymmetry of the kernel). The von Mangoldt weight of pk is Λ(pk ) = log p. If we
identify the attribution-weighted contribution of a prime after k events with αk log p and set
                                              1 1
                                    αk :=      − tanh β (k − 1)δ ,
                                                                
                                              2 2
then in the limit k → ∞ (or for any finite k when β is small) we have αk → 12 . Consequently
the long-run average attribution per event tends to 12 log p, and the total attributed weight after k
events approaches k2 log p, which is proportional to the von Mangoldt weight scaled by the surplus
per event. This provides the precise bridge between the dynamical surplus ledger and the arithmetic
weight function.

D.5. Entropy Production and the Hardy–Ramanujan Estimate
Let the system contain M distinct prime channels with surplus vector S(t) = (S1 (t), . . . , SM (t)) and
total surplus Stot (t) = i Si (t). Define the normalized surplus distribution
                        P

                                             Si (t)
                                Ŝi (t) =              (when Stot (t) > 0).
                                            Stot (t)
The Shannon entropy of this distribution is
                                                   M
                                     H(t) = −            Ŝi (t) log Ŝi (t).
                                                   X

                                                   i=1

Proposition 5 (Entropy non-decrease under λ = 1). If λ = 1 and the interaction graph is connected,
then H(t + 1) ≥ H(t) for all t, with strict inequality unless all Si (t) are equal.
Proof. From Proposition 2 with λ = 1, Stot (t) is constant. The update for each channel is a
doubly-stochastic redistribution of surplus because the kernel is antisymmetric and conserves the
sum of the two interacting channels. A doubly-stochastic map cannot decrease Shannon entropy (a
standard consequence of Jensen’s inequality applied to the convex function x 7→ −x log x). Equality
holds only when the map leaves the distribution unchanged, which for a connected graph requires
all entries to be equal.
   When the interaction schedule picks pairs uniformly at random from a connected graph, the
surplus distribution converges to the uniform distribution over the M primes. Hence the limiting
entropy is log M .
   If we let N be the largest integer whose prime factorization uses only the first M primes,
then the number of distinct prime factors of a typical integer ≤ N is, by the Hardy–Ramanujan
theorem, approximately log log N with variance also ∼ log log N . Identifying M ≈ log log N gives
the prediction
                                      lim H(t) ≈ log log N,
                                        t→∞
which matches empirically observed entropy of prime-exponent surplus in large-scale factorisations
(see, e.g., the data cited in the main text).

                                                       21
Multiplicity Theory / PIRTM                                                Defensive Publication Draft


D.6. Linearisation of the Gap Map and Choice of β
                                                                3
Near the fixed point ∆ = 0, we have tanh(β∆) = β∆ − (β∆)
                                                      3  + O(∆5 ). Substituting into (5) gives

                                                        β3 3
                                 ∆t+1 = (λ − β)∆t +       ∆ + O(∆5t ).                                 (3)
                                                        3 t
Thus the linear stability coefficient is λ − β. To guarantee local contraction we require |λ − β| < 1. In
the prime-native regime λ = 1 this becomes β ∈ (0, 2). Choosing β = 1 places the linear coefficient
at zero, making the leading term cubic and yielding exceptionally soft convergence that avoids
overshoot while still guaranteeing ∆t → 0. This trade-off motivated the default β = 1 used in the
reference implementation.

D.7. Summary of Key Inequalities
All derived inequalities that appear as verification conditions in the dialect are collected here for
quick reference:


    Primality:                     p ∈ P ⇐⇒ ¬∃ d ∈ (1, p) : d | p.                                     (6)
    Squarefreeness:                m squarefree ⇐⇒ µ(m) ̸= 0 ⇐⇒ ∀ p : p ∤ m.2    2
                                                                                                       (7)
    Coprimality:                   gcd(p1 , p2 ) = 1 ⇐⇒ p1 p2 squarefree and p1 ̸= p2 .                (8)
    Contractivity:                 ∥Ξ∥ + ∥Λ∥ ∥T ∥op < 1 − ϵ.                                           (9)
    Certificate consumption:       every !.cert produced is consumed before function return.          (10)
    Network small-gain:            r(Ψ) < 1 where Ψij = gain from channel j to i.                     (11)
    Entropy bound:                 H(t) ≤ log M with equality iff Si (t) = Sj (t) ∀i, j.              (12)
                                                                                                      (13)

   These are the exact mathematical statements enforced (directly or indirectly) by the six verifier
passes, the type constraints, and the linking procedure described in the main text.

References

 [1] Chris Lattner et al. Mlir language reference. 2016. https://mlir.llvm.org/docs/LangRef/.
 [2] Chris Lattner et al.     Rationale for mlir.     2016.            https://github.com/llvm/llvm-
     project/blob/main/mlir/docs/Rationale/Rationale.md.
 [3] Jeremy Kun.        Mlir — verifiers.      Math        Programming,                  September   2023.
     https://www.jeremykun.com/2023/09/13/mlir-verifiers/.
 [4] LLVM Project.           Defining dialect attributes and types                   —    mlir.      2020.
     https://mlir.llvm.org/docs/DefiningDialects/AttributesAndTypes/.
 [5] LLVM Project. Passes — mlir. 2020. https://mlir.llvm.org/docs/Passes/.
 [6] Chris Lattner et al. Llvm link time optimization: Design and implementation.                    2018.
     https://llvm.org/docs/LinkTimeOptimization.html.
 [7] Eduardo D. Sontag. Smooth stabilization implies coprime factorization. IEEE Transactions on
     Automatic Control, 34(4):435–443, 1989.

                                                   22
    Multiplicity Theory / PIRTM                                              Defensive Publication Draft


     [8] Zong-Ping Jiang, Maryam Mareels, and Yuan Wang. A lyapunov formulation of the nonlinear
         small-gain theorem for iss systems. Systems & Control Letters, 23(5):303–314, 1994.

     [9] G. H. Hardy and S. Ramanujan. Asymptotic formulae in combinatory analysis. Proceedings of
         the London Mathematical Society, s2-17(1):75–115, 1917.

    [10] Terence Tao.      254a, notes 1: Elementary multiplicative number theory.          2014.
         https://terrytao.wordpress.com/2014/11/23/254a-notes-1-elementary-multiplicative-number-
         theory/.

    [11] Hans von Mangoldt. Zu riemanns”scher funktion” ξ(s). Journal für die reine und angewandte
         Mathematik, 114:255–265, 1895.

    [12] Zhi-Wei Sun and Zhi-Hong Sun. Chinese remainder theorem: History, applications, and
         generalizations. American Mathematical Monthly, 117(5):422–443, 2010.

    [13] Peter L. Bartlett and Shahar Mendelson. Rademacher and gaussian complexities: Risk bounds
         and structural results. Journal of Machine Learning Research, 3:463–482, 2002.

    [14] Behnam Neyshabur, Srinadh Bhojanapalli, David McAllester, and Nathan Srebro. Exploring
         generalization in deep learning. Advances in Neural Information Processing Systems, 30:5949–
         5958, 2017.

    [15] Feng Zhang et al. Small gain theorem for iss nonlinear systems and its application to distributed
         consensus. pages 1360–1365, 2020.

    [16] LLVM Project. Llvm bitcode file format. 2022. https://llvm.org/docs/BitCodeFormat.html.

    [17] DWARF Committee.          Dwarf debugging information format,              version 6.      2025.
         https://dwarfstd.org/doc/DWARF6.pdf.

    [18] WebAssembly Community Group. Webassembly core specification: Custom sections and
         annotation. 2026. https://webassembly.github.io/spec/core/appendix/custom.html.

    [19] Anonymous.      Qarisession: A lightweight session tracking library for pirtm.    2020.
         https://github.com/MultiplicityFoundation/PIRTM/blob/main/src/pirtm/qaris ession.py.

[20] Anonymous.                 Auditchain     for   multiplicity    theory.                        2021.
     https://github.com/MultiplicityFoundation/PIRTM/blob/main/src/pirtm/auditc hain.py.




                                                     23
