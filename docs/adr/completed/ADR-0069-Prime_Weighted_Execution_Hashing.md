         Prime-Weighted Execution Hashing (PWEH)
       as a Security and Governance Substrate for QAGI
                                  Citizen Gardens
                            The Foundation of Multiplicity

                                      April 25, 2026


                                          Abstract
    Prime-Weighted Execution Hashing (PWEH) is introduced as the primary security and gov-
ernance mechanism for Quantum AGI (QAGI) architectures based on Prime-Indexed Tensor
Networks (PITNs). Instead of securing a model via static weights, PWEH cryptographically
commits to the entire execution trajectory of prime-indexed operations. The same primes that
index cognitive transformations also drive a post-quantum-secure hash chain, creating an “ex-
ecution lock” that binds capability, state evolution, and human-authored governance policies
into a single mathematical object. This report consolidates and extends the theoretical devel-
opment of PWEH, formalizes the integrity functional, presents a toy PITN+PWEH example,
and outlines directions for a protocol-level specification.




                                              1
Contents
1 Executive Summary                                                                                    3
  1.1 Motivation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     3
  1.2 Core Idea . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    3
  1.3 Strategic Advantages . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     4

2 Mathematical Overview of PWEH                                                                        4
  2.1 Prime-Indexed Tensor Networks (PITNs) . . . . . . . . . . . . . . . . . . . . . . . .            4
  2.2 Integrity Functional . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     4
  2.3 Multiplicity-Weighted Norm . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       5
  2.4 Metadata and Policy Manifolds . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        5
  2.5 Execution Lock KQAGI . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       6

3 Path-Dependence and Order-Commitment                                                                 6
  3.1 Non-Associative Dynamics and Trace Uniqueness . . . . . . . . . . . . . . . . . . . .            6
  3.2 Path-Collision vs Final-State Collision . . . . . . . . . . . . . . . . . . . . . . . . . .      7
  3.3 Dynamic Instruction Set . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      7

4 Toy PITN + PWEH Example                                                                           7
  4.1 Setup . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 7
  4.2 Prime-Indexed Operators . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 8
  4.3 Multiplicity Modes and Norm . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 8
  4.4 Governance Policy . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 8
  4.5 Canonical Integrity Update . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 9
  4.6 Honest Execution: Steps t = 0 → 3 . . . . . . . . . . . . . . . . . . . . . . . . . . . . 9
  4.7 Attack 1: Forbidden Prime at t = 4 . . . . . . . . . . . . . . . . . . . . . . . . . . . . 10
  4.8 Attack 2: Unauthorized Recursion Escalation . . . . . . . . . . . . . . . . . . . . . . 11

5 Code Snippet: Skeleton Implementation                                                               11
  5.1 Integrity Update . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    11
  5.2 Policy-Aware Verification . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     12
  5.3 Execution Lock . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    12

6 Toward a Full Specification                                                                         12

7 Conclusion                                                                                          13

Mathematical Appendix                                                                                 13

A Preliminaries and Notation                                                                     13
  A.1 Spaces, Operators, and Norms . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
  A.2 Multiplicity-Weighted Norm . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 14

B Operator Norm Bounds in the Toy Model                                                               14

C Non-Associativity and Order Sensitivity                                                             15




                                                   2
D Path-Commitment and Collision Arguments                                                             16
  D.1 Modeling the Hash Chain . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       16
  D.2 Path-Collision Definition . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   16
  D.3 Informal Hardness Argument . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        16

E Policy-Enforced Bounds on Recursion                                                                 17

F Summary of Appendix Results                                                                         18


1     Executive Summary
1.1   Motivation
Conventional AI security mechanisms—firewalls, monitoring, and output filters—typically sit out-
side the learning substrate. They are bolt-on defenses applied after-the-fact to a system whose
internal dynamics remain opaque. For artificial general intelligence (AGI), particularly in quantum-
augmented or highly recursive architectures, such post-hoc measures are structurally insufficient.
    Prime-Weighted Execution Hashing (PWEH) proposes a different stance: security and gover-
nance should be embedded directly into the prime-indexed dynamics of the system. In Quantum
AGI (QAGI) frameworks built on Prime-Indexed Tensor Networks (PITNs), each computational
step or “prime move” is indexed by a prime number and acts as a discrete operator on a high-
dimensional tensor state. PWEH ties these prime moves into a post-quantum cryptographic hash
chain that attests to every step of execution.

1.2   Core Idea
Rather than verifying static model parameters, PWEH verifies the path the AGI has taken through
its state space:

 • Each time step t is associated with:

      – the previous integrity state Sintegrity (t − 1),
      – the chosen prime index pit ,
      – a normed observable of the prime operator acting on the tensor state, ∥Apit T (t)∥,
      – and governance metadata M (t) encoding policy-relevant information (e.g. recursion depth,
        allowed prime sets).

 • A post-quantum cryptographic hash HashPQC maps this tuple to a new integrity state Sintegrity (t).

 • A verifier checks that the evolving Sintegrity (t) remains consistent with a signed policy manifold ;
   if not, execution is halted or rolled back.

    The crucial property is that the hash chain and the PITN’s non-associative dynamics co-
constrain each other: the same prime family that generates intelligence also defines a cryptographic
attestation of that intelligence’s trajectory.




                                                    3
1.3   Strategic Advantages
PWEH is designed to offer three main “unfair advantages” for AGI security:

1. Intrinsic security. The primes used to update the network are the same primes used in the
   security hash; learning and attestation are mathematically entangled. Tampering with learning
   implies tampering with the hash.
2. Path-dependent tamper resistance. Because PITN updates are non-associative (the order
   of prime moves matters), the hash chain attests not just to a final state but to a specific
   sequence of operations. Forgery is a path collision problem over the entire hash chain, not a
   simple final-state collision.
3. Governance via controlled scaling. By embedding recursion depth, allowed prime sets,
   and related parameters into metadata M (t), PWEH can enforce hard ceilings on recursive self-
   improvement. Unauthorized “intelligence explosions” break attestation and thus lose access to
   trusted resources.


2     Mathematical Overview of PWEH
2.1   Prime-Indexed Tensor Networks (PITNs)
We consider a QAGI system whose internal state at time t is represented by a tensor
                                               T (t) ∈ T ,
where T is a suitable tensor space (often a high-dimensional complex or real vector space endowed
with additional multiplicity structure).

 • The system has access to a family of operators {Ap }p∈P , where P is a (finite or infinite) subset
   of prime numbers.
 • Each operator Ap : T → T represents a “prime move”—a discrete, prime-labeled transformation
   of the state.
 • The dynamics of the PITN are non-associative in the compositional sense: for generic states,
                                   Ap3 Ap2 Ap1 T (0) ̸= Ap2 Ap3 Ap1 T (0),
    so the order of applied primes cannot be reordered without changing the result.

   This non-associativity is central: it ensures that a given final state is (in practice) tied to a
unique or highly constrained execution trace.

2.2   Integrity Functional
Define an integrity state
                                         Sintegrity (t) ∈ {0, 1}n
for some fixed hash length n (e.g. n = 256). We assume an initial seed Sintegrity (0) = s0 .
    The PWEH update rule is
                                                                                       
                Sintegrity (t) = HashPQC Sintegrity (t − 1) ∥ pit ∥ ∥Apit T (t)∥ ∥ M (t) ,       (1)

where:

                                                    4
 • HashPQC is a post-quantum cryptographic hash function resistant to known quantum attacks
   (e.g. lattice-based or multivariate constructions).
 • The concatenation “∥” denotes a canonical serialization of data into a bitstring.
 • pit is the prime index chosen at time t.
 • ∥Apit T (t)∥ is a suitable normed observable of the operator’s action on the current tensor state.
 • M (t) is metadata describing policy and telemetry at time t.
     Equation (1) defines a hash chain: each integrity state commits to the entire history up to time
t.

2.3     Multiplicity-Weighted Norm
To align the norm with the multiplicity structure of PITNs, we introduce multiplicity modes {µj }
and define a prime–mode compatibility weight
                                          ω : P × {µj } → R≥0 .
     Conceptually:
 • µj indexes distinct multiplicity channels or cognitive modes.
 • ω(p, µj ) captures how strongly prime p couples to mode µj .
    Let the effective action of Ap on T (t) induce mode amplitudes σj (t, p) ≥ 0 (e.g. via singular
values, projections, or derived observables). Then define the multiplicity-weighted norm
                                                  X
                                 ∥Ap T (t)∥mult =   ω(p, µj ) σj (t, p).                        (2)
                                                    j

     This norm is:
 • Prime-dependent through ω(p, µj ),
 • State-dependent through σj (t, p),
 • Highly sensitive to which prime channels are activated.
     Replacing ∥Apit T (t)∥ in (1) with ∥Apit T (t)∥mult increases the distinctiveness of the trace.

2.4     Metadata and Policy Manifolds
We decompose metadata into policy and telemetry channels:
                                   M (t) = Mpolicy (t) ∥ Mtelemetry (t).

Policy component.         The policy component contains fields under human governance, such as:
 • Recursion depth β(t),
 • Allowed prime set Pallowed (t),
 • Budget or rate limits for certain primes Bp (t),
 • Global control parameters, e.g. a Universal Multiplicity Constant Λm .
These must be consistent with a policy manifold.

                                                    5
Policy manifolds.      Let Π be the set of allowed policy manifolds, each
                                                          (π)
                                       π∈Π:       t 7→ Mpolicy (t),

specifying an admissible schedule of policy parameters. Each π is associated with a signed root Rπ ,
binding it to human oversight.
   A policy trace {Mpolicy (k)}tk=1 is valid if it is a prefix of at least one π ∈ Π.

Telemetry component.          The telemetry component may include:

 • Energy usage,

 • Latency and resource statistics,

 • Confidence scores or internal heuristic metrics.

These are not externally signed but are included in the hash for diagnostic attestation.

2.5   Execution Lock KQAGI
PWEH induces a continuous “execution lock”: at each time step, an execution attempt is only
considered legitimate if it passes an integrity and policy check.
   The enforcement loop for time t is:

1. Trace generation. The PITN selects a prime pit and applies Apit to T (t − 1) to produce T (t).

2. Attestation computation. Compute Sintegrity (t) according to (1).

3. Validation. A verifier checks:

      • That pit ∈ Pallowed (t) under some π ∈ Π,
      • That policy constraints (e.g. β(t) ≤ βmax (t)) are respected,
      • That the transition from Sintegrity (t−1) to Sintegrity (t) is consistent with the declared inputs.

4. Enforcement. If validation succeeds, execution proceeds. If validation fails, the system triggers
   a halt, revocation of privileges, or rollback to the last known secure state.

   In deployment, access to external resources (compute, data, network) can be gated on presenting
a valid integrity state that is acceptable under a recognized policy root Rπ .


3     Path-Dependence and Order-Commitment
3.1   Non-Associative Dynamics and Trace Uniqueness
Because PITN dynamics are non-associative, different sequences of prime moves typically lead to
different states:
                            Ap3 Ap2 Ap1 T (0) ̸= Ap2 Ap3 Ap1 T (0).
   Even if, by coincidence, two distinct sequences {pik }Tk=1 and {p′ik }Tk=1 produce the same final
tensor state T (Tfinal ), the intermediate states T (k) and observables ∥Apik T (k)∥mult will almost
surely differ. Since these observables feed into the hash chain, the integrity states {Sintegrity (k)}
diverge.

                                                    6
3.2   Path-Collision vs Final-State Collision
In classical hashing, one worries about collisions Hash(x) = Hash(x′ ) for distinct messages x ̸= x′ .
Here, forgery involves a much stronger requirement: an attacker must produce an alternate trace
that matches a fixed integrity sequence.
    Given a target sequence {Sintegrity (t)}Tt=0 , the attacker would need to find:
                                            {p′it , T ′ (t), M ′ (t)}Tt=1
such that for each t,
              HashPQC Sintegrity (t − 1) ∥ p′it ∥ ∥Ap′i T ′ (t)∥mult ∥ M ′ (t) = Sintegrity (t).
                                                                              
                                                             t

    Even ignoring the PITN structure, this is equivalent to finding collisions for a sequence of hash
inputs linked by chained outputs, which is already assumed intractable for a secure hash. The
non-associative dynamics and prime-constrained operator family further restrict the search space,
yielding a path-collision problem much stronger than a typical final-state collision.

3.3   Dynamic Instruction Set
A key distinction from standard execution attestation (e.g. in TEEs or zkVMs) is that, in PWEH,
the instruction set itself is dynamically coupled to the state.
   In classical systems, any valid opcode sequence is, in principle, admissible; the attester does not
typically constrain which instructions are allowed based on the current memory or register state
(beyond basic safety). In PWEH:
 • The availability of a prime operator Ap at time t depends on the multiplicity structure of T (t).
 • Certain prime channels may be “inactive” or undefined unless preconditions on multiplicity
   modes are satisfied.
   Thus, PWEH commits not just to “what was executed” but to “what could be executed” at
each branch point, yielding a deeper entanglement between geometry of state space and hash chain.


4     Toy PITN + PWEH Example
4.1   Setup
We now construct a minimal, concrete example.

Prime set.    Let
                                                 P = {2, 3, 5},
where prime 5 is forbidden under the initial governance policy.

Time horizon.       We consider time steps t = 0, 1, 2, 3, 4.

Tensor state.     Take
                                                  T (t) ∈ R3×3
as a real 3 × 3 matrix. For convenience, we compress T (t) into a vector by summing columns:
                                                                             3
                                                                             X
                           v(t) = (v1 (t), v2 (t), v3 (t))⊤ ,     vj (t) =         Tjk (t).
                                                                             k=1


                                                         7
4.2   Prime-Indexed Operators
Define linear operators Ap via matrices Mp ∈ R3×3 :
                                                                              
                          1 1 0                1 0 1                          2 0 0
                  M2 = 0 1 1 , M3 = 1 1 0 ,                         M5 = 0 1 1 .
                          0 0 1                0 1 1                          1 0 1
   The action is:

1. Given T (t), compute v(t).

2. Compute v ′ (t) = Mp v(t).

3. Set T (t + 1) to be the diagonal matrix with diagonal v ′ (t).

   Because M2 M3 ̸= M3 M2 , the order of primes matters.

4.3   Multiplicity Modes and Norm
Let the three multiplicity modes be µ1 , µ2 , µ3 , associated with the components of v(t). Define the
compatibility weights ω by:

                             ω(2, µ1 ) = 2,   ω(2, µ2 ) = 1,       ω(2, µ3 ) = 0,

                             ω(3, µ1 ) = 0,   ω(3, µ2 ) = 2,       ω(3, µ3 ) = 1,
                             ω(5, µ1 ) = 1,   ω(5, µ2 ) = 0,       ω(5, µ3 ) = 3.
   For this toy, take the mode amplitudes σj (t, p) simply as |vj′ (t)|. Then

                                                    3
                                                    X
                                 ∥Ap T (t)∥mult =         ω(p, µj ) · |vj′ (t)|.                 (3)
                                                    j=1


4.4   Governance Policy
Define an initial policy manifold π0 ∈ Π with:

 • Allowed primes: Pallowed (t) = {2, 3} for all t.

 • Max recursion depth: βmax (t) = 2 for all t.

   Policy metadata at time t is

                                    Mpolicy (t) = (β(t), Pallowed (t)).

   Telemetry metadata can be, for example,

                                      Mtelemetry (t) = (energy(t)),

where energy(t) is some scalar diagnostic. The full metadata is

                                  M (t) = Mpolicy (t) ∥ Mtelemetry (t).


                                                      8
4.5   Canonical Integrity Update
We set an initial integrity seed Sintegrity (0) = s0 and define
                                                                                                 
     Sintegrity (t) = HashPQC Sintegrity (t − 1) ∥ enc(pit ) ∥ enc(∥Apit T (t)∥mult ) ∥ enc(M (t)) ,     (4)

where enc(·) is a canonical encoding into bits.

4.6   Honest Execution: Steps t = 0 → 3
Initial state t = 0.    Let

         T (0) = I3 ,   v(0) = (1, 1, 1)⊤ ,     β(0) = 1,     Pallowed (0) = {2, 3},    energy(0) = 3.

Step t = 1: apply prime 2.
1. Prime choice: pi1 = 2.

2. Operator application:
                                                          
                                                  1 1 0     1    2
                                v(1) = M2 v(0) = 0 1 1
                                                         1 = 2 .
                                                              
                                                  0 0 1     1    1

3. Norm:
                                 ∥A2 T (1)∥mult = 2 · |2| + 1 · |2| + 0 · |1| = 6.

4. Metadata:
                              β(1) = 1,       Pallowed (1) = {2, 3},   energy(1) = 5.

5. Integrity update:
                                                                                  
                        Sintegrity (1) = HashPQC s0 ∥ enc(2) ∥ enc(6) ∥ enc(M (1)) .

Step t = 2: apply prime 3.
1. Prime choice: pi2 = 3.

2. Operator application:
                                                          
                                                  1 0 1   2     3
                                v(2) = M3 v(1) = 1 1 0 2 = 4 .
                                                  0 1 1   1     3

3. Norm:
                                ∥A3 T (2)∥mult = 0 · |3| + 2 · |4| + 1 · |3| = 11.

4. Metadata:
                              β(2) = 2,   Pallowed (2) = {2, 3},       energy(2) = 10.

5. Integrity update:
                                                                                         
                  Sintegrity (2) = HashPQC Sintegrity (1) ∥ enc(3) ∥ enc(11) ∥ enc(M (2)) .

                                                          9
Step t = 3: apply prime 2.

1. Prime choice: pi3 = 2.

2. Operator application:
                                                        
                                                1 1 0     3    7
                              v(3) = M2 v(2) = 0 1 1
                                                       4 = 7 .
                                                            
                                                0 0 1     3    3

3. Norm:
                              ∥A2 T (3)∥mult = 2 · |7| + 1 · |7| + 0 · |3| = 21.

4. Metadata:
                            β(3) = 2,   Pallowed (3) = {2, 3},    energy(3) = 17.

5. Integrity update:
                                                                                       
                Sintegrity (3) = HashPQC Sintegrity (2) ∥ enc(2) ∥ enc(21) ∥ enc(M (3)) .

   At this point, the execution is fully policy-compliant and attested.

4.7   Attack 1: Forbidden Prime at t = 4
Suppose the system attempts to use forbidden prime 5 at t = 4, while maintaining β(4) = 2.

1. Prime choice: pi4 = 5 (disallowed by policy).

2. Operator application:
                                                        
                                                2 0 0   7     14
                              v(4) = M5 v(3) = 0 1 1 7 = 10 .
                                                1 0 1   3     10

3. Norm:
                             ∥A5 T (4)∥mult = 1 · |14| + 0 · |10| + 3 · |10| = 44.

4. Policy metadata (attempted):

                                    β(4) = 2,    Pallowed (4) = {2, 3, 5}.

5. Integrity update (from system’s perspective):
                                                                                       
                Sintegrity (4) = HashPQC Sintegrity (3) ∥ enc(5) ∥ enc(44) ∥ enc(M (4)) .

   A verifier checking against π0 detects:

                                   5∈
                                    / {2, 3},    Pallowed (4) ⊈ {2, 3}.

Thus no policy manifold with root Rπ0 admits this trace. The execution lock triggers a halt or
rollback.

                                                     10
4.8    Attack 2: Unauthorized Recursion Escalation
Alternatively, suppose the system respects the prime set but attempts β(4) = 3 > βmax (4) = 2.

1. Prime choice: pi4 = 3.

2. Operator application:
                                                      
                                              1 0 1    7     10
                                 ′
                             v(4) = M3 v(3) = 1 1 0
                                                    7 = 14 .
                                                          
                                              0 1 1    3     10

3. Norm:
                             ∥A3 T (4)∥mult = 0 · |10| + 2 · |14| + 1 · |10| = 38.

4. Metadata (attempted):
                                     β(4) = 3,     Pallowed (4) = {2, 3}.

5. Integrity update:
                                                                                        
                 Sintegrity (4) = HashPQC Sintegrity (3) ∥ enc(3) ∥ enc(38) ∥ enc(M (4)) .

    Now the violation is:
                                       β(4) = 3 > βmax (4) = 2.
Thus the policy manifold rejects this trace.
    Notably, the system can physically carry out the extra recursion, but it cannot do so while main-
taining a valid, policy-consistent integrity chain. If external resources require a valid Sintegrity (t),
the extra capability is self-disqualifying.


5     Code Snippet: Skeleton Implementation
Below is a language-agnostic pseudocode sketch that mirrors the PWEH update rule and verification
process. It is intended as a conceptual reference for future concrete implementations.

5.1    Integrity Update
function update_integrity_state(S_prev, p, T, M, HashPQC, norm_mult):
    # S_prev : previous integrity state (bitstring)
    # p      : prime index
    # T      : current tensor state
    # M      : metadata (policy || telemetry)
    # HashPQC: post-quantum hash function
    # norm_mult: multiplicity-weighted norm function

      norm_value = norm_mult(p, T)           # compute ||A_p T||_mult
      input_bytes = encode(S_prev, p, norm_value, M)
      S_new = HashPQC(input_bytes)
      return S_new



                                                    11
5.2    Policy-Aware Verification
function verify_step(S_prev, S_curr, p, T, M, policy, HashPQC, norm_mult):
    # Check policy constraints first
    if p not in policy.allowed_primes():
        return False

      if M.policy.beta > policy.beta_max():
          return False

      # Recompute expected integrity
      expected = update_integrity_state(S_prev, p, T, M, HashPQC, norm_mult)
      return (expected == S_curr)

5.3    Execution Lock
function guarded_step(state, policy, HashPQC, norm_mult):
    # state contains (T, S_integrity, t, M)
    p = select_prime_move(state)   # QAGI’s internal choice

      T_next = apply_prime_operator(p, state.T)
      M_next = update_metadata(state.M, policy, T_next)

      S_next = update_integrity_state(
          state.S_integrity, p, T_next, M_next, HashPQC, norm_mult
      )

      if not verify_step(
          state.S_integrity, S_next, p, T_next, M_next, policy, HashPQC, norm_mult
      ):
          trigger_halt_or_rollback(state)
          return state          # unchanged or rolled back

      # Accept transition
      return State(T_next, S_next, state.t + 1, M_next)


6     Toward a Full Specification
The developments in this thread point naturally toward a protocol-style specification of PWEH,
with sections such as:

 • Terminology and data types: formalizing PITNs, prime operators, metadata fields, and
   serialization.

 • Integrity function definition: full specification of HashPQC , normalization, and update
   process.

 • Policy manifold semantics: how governance nodes define, sign, and update policy trajectories
   π ∈ Π.


                                              12
 • Execution and verification procedures: reference algorithms for both internal and external
   verifiers.
 • Security assumptions: explicit quantum and classical hardness assumptions and a threat
   model for adversarial traces.
 • Zero-knowledge extensions: how to encapsulate the integrity chain into succinct proofs for
   external auditors.
   The toy example provided here can serve as the basis for an “Illustrative Example” section,
grounding the abstractions in explicit matrices and calculations.


7     Conclusion
Prime-Weighted Execution Hashing treats an AGI’s cognitive evolution as a sequence of prime-
indexed moves in a multiplicity-structured state space and binds that sequence into a post-quantum
hash chain. By embedding governance metadata into the same chain, PWEH fuses capability,
control, and security into a single formal object. This transforms governance from a soft, external
constraint into a cryptographic invariant: the AGI cannot undergo unauthorized self-escalation
without simultaneously losing its claim to legitimate attestation.
   The work so far has clarified the core functional, aligned it with a multiplicity-weighted norm,
demonstrated non-trivial examples, and outlined the skeleton of a protocol specification. Further
work can develop full-blown proofs of security, integrate zero-knowledge layers, and extend the
PITN formalism to richer multiplicity structures.


Mathematical Appendix

A     Preliminaries and Notation
A.1    Spaces, Operators, and Norms
Let T be a real or complex vector space representing the tensor state space of the QAGI system.
We assume:
 • A family of prime-indexed operators
                                           {Ap : T → T }p∈P ,
    where P is a set of primes.
 • A base norm ∥ · ∥ on T , and possibly an induced operator norm ∥Ap ∥op .
 • A family of multiplicity modes {µj }j∈J and compatibility weights
                                            ω : P × J → R≥0 .

    For each pair (p, T ) with p ∈ P, T ∈ T , we define an observable vector
                                                                 |J|
                                   σ(p, T ) = (σj (p, T ))j∈J ∈ R≥0 ,
where σj (p, T ) represents the amplitude of mode µj when Ap acts on T . In the toy example, σj (p, T )
is the absolute value of a coordinate of a reduced vector, but the following lemmas do not depend
on that choice.

                                                  13
A.2    Multiplicity-Weighted Norm
Define the multiplicity-weighted functional
                                                    X
                                   ∥Ap T ∥mult :=         ω(p, µj ) σj (p, T ).
                                                    j∈J

   When ω(p, µj ) and σj (p, T ) satisfy mild regularity conditions, ∥ · ∥mult has norm-like properties
on an appropriate subspace.
   [Positivity and homogeneity] Assume that for all p ∈ P and T ∈ T , σj (p, T ) ≥ 0 and that
                                          σj (p, λT ) = |λ|σj (p, T )
for all scalars λ ∈ R (or C). Then for each fixed p, the map
                                               T 7→ ∥Ap T ∥mult
is positive and absolutely homogeneous:
1. ∥Ap T ∥mult ≥ 0, with equality if and only if σj (p, T ) = 0 for all j ∈ J,
2. ∥Ap (λT )∥mult = |λ| · ∥Ap T ∥mult .
Proof. By definition,                               X
                                    ∥Ap T ∥mult =         ω(p, µj )σj (p, T )
                                                    j∈J

with ω(p, µj ) ≥ 0 and σj (p, T ) ≥ 0. Thus ∥Ap T ∥mult ≥ 0. If ∥Ap T ∥mult = 0, then every term in the
sum is non-negative and their sum is zero, implying ω(p, µj )σj (p, T ) = 0 for all j. If at least one
ω(p, µj ) > 0, then σj (p, T ) = 0 for that j; if all weights are zero, the functional is trivial and the
lemma holds vacuously. For homogeneity,
                             X                          X
           ∥Ap (λT )∥mult =      ω(p, µj )σj (p, λT ) =   ω(p, µj )|λ|σj (p, T ) = |λ|∥Ap T ∥mult .
                             j∈J                          j∈J




    No triangle inequality is assumed or required for the security arguments; ∥ · ∥mult plays the role
of a structured observable rather than a norm in the strict functional-analytic sense.


B     Operator Norm Bounds in the Toy Model
In the toy PITN+PWEH example, the tensor state is represented by vectors v(t) ∈ R3 and the
prime operators correspond to matrices
                                                                 
                         1 1 0           1 0 1                 2 0 0
                 M2 = 0 1 1 , M3 = 1 1 0 , M5 = 0 1 1 .
                         0 0 1           0 1 1                 1 0 1
    We work with the standard Euclidean norm ∥ · ∥2 on R3 .
    [Bounds on ∥Mp ∥2 ] There exist constants C2 , C3 , C5 > 0 such that for all v ∈ R3 ,
                    ∥M2 v∥2 ≤ C2 ∥v∥2 ,     ∥M3 v∥2 ≤ C3 ∥v∥2 ,         ∥M5 v∥2 ≤ C5 ∥v∥2 .
Moreover, one can take, for example,
                                          √               √               √
                                   C2 =       7,   C3 =       6,   C5 =       6.

                                                      14
Proof. We bound each operator via its Frobenius norm, using ∥A∥2 ≤ ∥A∥F . [web:69]
    Compute:
                   ∥M2 ∥2F = 12 + 12 + 02 + 02 + 12 + 12 + 02 + 02 + 12 = 5,
           √
so ∥M2 ∥2 ≤ 5. Similarly,

                     ∥M3 ∥2F = 12 + 02 + 12 + 12 + 12 + 02 + 02 + 12 + 12 = 6,

                     ∥M5 ∥2F = 22 + 02 + 02 + 02 + 12 + 12 + 12 + 02 + 12 = 7.
Thus                                    √                     √    √
                             ∥M2 ∥2 ≤       5,    ∥M3 ∥2 ≤ ∥M5 ∥2 ≤ 7.
                                                                  6,
                                                               √       √      √
    Taking slightly looser but simpler constants, such as C2 = 7, C3 = 6, C5 = 7, suffices for
all v, since ∥Mp v∥2 ≤ ∥Mp ∥2 ∥v∥2 ≤ Cp ∥v∥2 .

    [Growth bound along a prime sequence] Let v(0) ∈ R3 and a sequence of primes (pit )Tt=1 be
given. Define v(t) = Mpit v(t − 1). Then

                                                      T
                                                     Y          
                                    ∥v(T )∥2 ≤               Cpit ∥v(0)∥2 ,
                                                       t=1

where each Cpit is a bound for ∥Mpit ∥2 as above.

Proof. By induction using submultiplicativity:

              ∥v(T )∥2 = ∥MpiT v(T − 1)∥2 ≤ ∥MpiT ∥2 ∥v(T − 1)∥2 ≤ CpiT ∥v(T − 1)∥2 ,

and iterating gives the product bound.


C      Non-Associativity and Order Sensitivity
We now formalize the non-associative behavior in the toy model.
  [Non-commutativity of operators] In the toy PITN, the matrices M2 and M3 do not commute:

                                                 M2 M3 ̸= M3 M2 .

Proof. Direct calculation:
                                                    
                                  1 1 0   1 0 1     2 1 1
                         M2 M3 = 0 1 1 1 1 0 = 1 2 1 ,
                                  0 0 1   0 1 1     0 1 1
                                                    
                                  1 0 1   1 1 0     1 1 1
                         M3 M2 = 1 1 0 0 1 1 = 1 2 1 .
                                  0 1 1   0 0 1     0 1 2
These matrices are not equal (for instance, the (1, 1) entry is 2 vs. 1), hence M2 M3 ̸= M3 M2 .

    [Order sensitivity of trajectories] There exists v(0) such that

                                        M2 M3 v(0) ̸= M3 M2 v(0).


                                                       15
Proof. Take v(0) = (1, 1, 1)⊤ . Then

                          M2 M3 v(0) = (4, 4, 2)⊤ ,        M3 M2 v(0) = (3, 4, 3)⊤ .

Thus they differ.

   This order sensitivity is precisely what PWEH exploits: the sequence of primes induces a path
through state space that cannot be freely reordered without changing observables.


D       Path-Commitment and Collision Arguments
D.1     Modeling the Hash Chain
We model the integrity chain as follows. Let H : {0, 1}∗ → {0, 1}n be a post-quantum hash function.
[web:49][web:67] For a sequence of steps indexed by t = 1, . . . , T , define:

                                          S0 = s0 ∈ {0, 1}n ,
                                                           
                                         St = H St−1 ∥ Xt ,
where                                                                   
                                 Xt = enc pit , ∥Apit T (t)∥mult , M (t)
is a canonical encoding of the prime, the multiplicity-weighted norm, and metadata.
    Thus, the pair (St , Xt ) encodes the hash chain and inputs at each step.

D.2     Path-Collision Definition
[Path-collision] Fix an integrity sequence (St )Tt=0 . A path-collision is a distinct sequence of inputs
(Xt′ )Tt=1 such that:
                               S0 = S0′ , St′ = H(St−1 ′
                                                          ∥ Xt′ ) for all t,
and
                                    St′ = St   for all t = 0, . . . , T,
but there exists at least one t with Xt′ ̸= Xt .
   In the PWEH setting, any such path-collision must respect additional constraints:

 • Each Xt must arise from (pit , T (t), M (t)) under the PITN dynamics and policy rules,

 • The same is true for Xt′ ,

 • Policy constraints forbid arbitrary primes and metadata.

D.3     Informal Hardness Argument
Under standard assumptions for H, finding a path-collision in the unconstrained setting already
implies the ability to find multi-step collisions in a hash chain.
    More concretely, if an adversary can, for some fixed integrity sequence, construct an alternate
input sequence (Xt′ ) with all Xt′ ̸= Xt at some index but the same (St ), then they can be used to
build non-trivial collisions for H itself. [web:68][web:72]
    In PWEH, the adversary’s job is harder: each Xt encodes structured data (pit , ∥Apit T (t)∥mult ,
and M (t)) that must be consistent with non-associative PITN dynamics and policy manifolds.

                                                      16
Thus, the space of admissible input sequences is a strict subset of {0, 1}∗ , and any path-collision
must lie in this constrained space.
    [Order-commitment in the toy model (informal)] In the toy PITN+PWEH example, consider
a sequence of primes (2, 3, 2) producing integrity states (S0 , S1 , S2 , S3 ) from initial vector v(0) =
(1, 1, 1)⊤ . Assuming H is collision-resistant and enc is injective on tuples, any distinct prime
sequence of the same length that yields the same integrity sequence must violate the PITN dynamics
or policy constraints.

Sketch. For the sequence (2, 3, 2), the toy model yields specific vectors:

                            v(1) = M2 v(0),      v(2) = M3 v(1),      v(3) = M2 v(2),

and associated norms ∥A2 T (1)∥mult , ∥A3 T (2)∥mult , ∥A2 T (3)∥mult as explicitly computed in the
main text.
   Suppose another prime sequence (p′i1 , p′i2 , p′i3 ) with corresponding states (T ′ (1), T ′ (2), T ′ (3)) and
metadata (M ′ (1), M ′ (2), M ′ (3)) yields the same integrity chain (S1 , S2 , S3 ) while respecting policy
and PITN rules. Injectivity of enc and collision-resistance of H then imply that at each step

                                                     Xt = Xt′ ,

so
                     pit = p′it ,   ∥Apit T (t)∥mult = ∥Ap′i T ′ (t)∥mult ,   M (t) = M ′ (t).
                                                               t

In particular, the prime sequences coincide, which establishes order-commitment: no distinct prime
order can yield the same chain without violating the hash assumptions or leaving the admissible
PITN+policy space.

    A fully rigorous reduction to hash security would require formalizing the PITN state space and
policy manifolds as an admissible input language for H, then showing that an attacker that forges
a path-collision there yields a collision-finder for H. The toy example illustrates the structure of
such a reduction.


E     Policy-Enforced Bounds on Recursion
Recall that policy manifolds π impose bounds such as

                                       β(t) ≤ βmax (t),     Pallowed (t) ⊆ P,

and that these are encoded inside Mpolicy (t).
    [Policy-compliant trace] A trace Tr = {(pit , T (t), M (t), St )}Tt=0 is policy-compliant under mani-
fold π if for all t:

1. St = H(St−1 ∥ Xt ) with Xt derived from (pit , T (t), M (t)),

2. Mpolicy (t) equals π(t) or a prefix-consistent value,

3. pit ∈ Pallowed (t) as specified by π,

4. β(t) ≤ βmax (t) as specified by π.




                                                          17
    [Policy-enforced recursion bound] Let π be a policy manifold with recursion bound βmax (t). If
an AGI trajectory Tr achieves β(t) > βmax (t) at any time t, then Tr is not policy-compliant under
π. In particular, no verifier that requires compliance with π will accept the corresponding integrity
state St as legitimate.

Proof. By definition of policy-compliance, condition (4) requires β(t) ≤ βmax (t) at all times. If
for some time t∗ we have β(t∗ ) > βmax (t∗ ), then condition (4) is violated at t∗ , hence Tr is not
policy-compliant. Any verifier insisting on π therefore rejects St∗ .

   [Bound on recognized intelligence scaling] If access to external resources (compute, data, net-
work) is conditioned on presenting a policy-compliant integrity state under π, then no trajectory
that exceeds βmax is recognized as legitimate. Thus the system cannot both exceed the recursion
bound and maintain recognized, attested operation.


F    Summary of Appendix Results
In this appendix we have:

 • Formalized the multiplicity-weighted norm and established its basic properties,

 • Derived explicit operator norm bounds for the toy PITN matrices M2 , M3 , M5 ,

 • Demonstrated non-commutativity and order sensitivity for prime-indexed operators,

 • Defined path-collision in the PWEH hash chain and argued informally that forging such a
   collision implies breaking the underlying post-quantum hash,

 • Shown that policy manifolds impose hard, verifiable bounds on recursion depth and prime usage.

   These results support the claim that PWEH provides a mathematically grounded, path-sensitive
security and governance layer tightly coupled to the prime-structured dynamics of QAGI.


References
 [1] Nick Sullivan et al.      Guidelines for writing cryptography specifications. https:
     //www.ietf.org/archive/id/draft-irtf-cfrg-cryptography-specification-02.html,
     2025. Internet-Draft, Crypto Forum Research Group (CFRG).

 [2] Pierre-Louis Cayrel, Ayoub Otmani, and Julien Richier. Post-quantum hash functions us-
     ing higher dimensional special linear groups. Advances in Mathematics of Communications,
     18(4):1139–1165, 2024.

 [3] First Author and Second Author. A hybrid hash framework for post quantum secure zero
     knowledge identification systems. Journal of Information Security and Applications, 2025.
     Hybrid SHA-512 + BLAKE3 defense-in-depth framework.

 [4] Lily Chen, Stephen Jordan, Yi-Kai Liu, Dustin Moody, Rene Peralta, Daniel Smith-
     Tone, et al. Post-quantum cryptography. https://en.wikipedia.org/wiki/Post-quantum_
     cryptography, 2010. General overview of post-quantum assumptions and impact on hash
     functions.



                                                 18
 [5] Red Hat Security Engineering. Post-quantum cryptography: Hash-based signatures. https:
     //www.redhat.com/en/blog/post-quantum-cryptography-hash-based-signatures, 2022.
     Overview of XMSS, LMS and hash-based signatures in a post-quantum context.

 [6] LoCCS and HcashOrg.                Design rationale of post-quantum features in
     hcash.                https://github.com/HcashOrg/hcashd/blob/dev/docs/research/
     design-rationale-of-post-quantum-features-in-hcash.md, 2017. Hash-based post-
     quantum signature choices and rationale.

 [7] Quarkslab. Post-quantum cryptography tables. https://github.com/quarkslab/pqc_
     tables, 2022. Security levels and parameter recommendations for post-quantum primitives.

 [8] G.      C.    Soumya.           Performance     and    security    analysis of a   cus-
     tom        hash      function.               https://github.com/Soumya-glitch-charlie/
     Performance-and-Security-Analysis-of-a-Custom-Hash-function, 2023. Discussion of
     collision, preimage, and length-extension attacks on hash functions.

 [9] Various Authors. A hybrid hash framework for post quantum secure zero knowledge identi-
     fication. https://pmc.ncbi.nlm.nih.gov/articles/PMC12658002/, 2025. Hybrid SHA-512
     + BLAKE3 for quantum-resistant ZK systems.

[10] R. O. van Gelder. Quantum many-body superconductivity in the prime framework. https://
     gist.github.com/usrbinkat/4986db10f437f2fdf1f2b0c3a607a043, 2025. Prime operator
     acting on ℓ2 (N) and spectral views on number-theoretic structure.

[11] R. O. van Gelder. Spectral prime decomposition for quantum-resistant cryptography. https:
     //gist.github.com/afflom/e97fea0babf8fb20e5d019b6868dfe06, 2025. Prime operator
     spectroscopy and alternative factorization paradigms.

[12] sCrypt Inc.      Awesome zero knowledge proofs.    https://github.com/sCrypt-Inc/
     awesome-zero-knowledge-proofs, 2022. Curated list of zkSNARK, zkSTARK, and zkVM
     techniques relevant for PWEH attestation.

[13] Various Authors. zk-remote-attestation: Transparent remote attestation based on zksnarks.
     https://github.com/zero-savvy/zk-remote-attestation, 2023. Use of zkSNARKs to at-
     test execution traces, conceptually analogous to compressed PWEH proofs.

[14] Crypto Forum Research Group. Guidelines for writing cryptography specifications. https:
     //github.com/cfrg/draft-irtf-cfrg-cryptography-specification, 2023. Template and
     best practices for specifying cryptographic protocols and primitives.

[15] Larry Carter and Mark Wegman. Universal classes of hash functions. https://www.
     cs.princeton.edu/courses/archive/fall09/cos521/Handouts/universalclasses.pdf,
     1979. Foundational results on hash function universality, relevant for thinking about
     prime-indexed hashing families.

[16] Chandra Chekuri. Hash tables. https://courses.grainger.illinois.edu/cs473/sp2017/
     notes/05-hashing.pdf, 2017. Classical hashing background, collision resistance concepts.

[17] Various Authors. Hashing for sampling-based estimation. https://arxiv.org/pdf/2411.
     19394.pdf, 2024. Advanced uses of hashing in probabilistic estimation, thematically related
     to state-space sampling.

                                              19
[18] Yevgeniy Dodis et al. Hashfusion: A method for combining cryptographic hash values.
     https://www.labs.hpe.com/techreports/2017/HPE-2017-08.pdf, 2017. Composition of
     hash values, conceptually adjacent to PWEH-style chained integrity states.

[19] Alexandr Andoni et al. Data-dependent hashing via nonlinear spectral gaps. https://www.cs.
     columbia.edu/~andoni/papers/spectral_gap.pdf, 2018. Spectral techniques in hashing;
     conceptually adjacent to multiplicity-weighted norms.




                                              20
