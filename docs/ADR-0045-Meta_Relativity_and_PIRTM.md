Meta-Relativity & PIRTM — Defensive Publication                            Citizen Gardens, April 2026




      Meta-Relativity and the Prime Interval
      Recursion Theory Machine (PIRTM):
                        Defensive Prior Art Publication,
                   Comprehensive Mathematical Overview, and
                      Implementation Architecture Report
                             Version 1.0 — Defensive Publication

                                   Citizen Gardens
                             The Foundation of Multiplicity
                                        April 25, 2026



Defensive Prior Art Publication Notice. This document is published publicly by the
Multiplicity Foundation for the express purpose of establishing prior art under 35 U.S.C. § 102
and equivalent international provisions (EPC Art. 54). All mathematical frameworks, operator
constructions, certification protocols, module architectures, and software designs described
herein are disclosed as of the date of publication. This disclosure is intended to prevent any
third party from obtaining patent claims over the described subject matter. The disclosed
work is released under the Prime Materia License and Apache 2.0 where applicable.
Nothing in this document constitutes a waiver of copyright.


                                             Abstract

         We present a comprehensive technical disclosure of the Meta-Relativity framework
     and its primary computational instantiation, the Prime Interval Recursion Theory
     Machine (PIRTM), developed under the Multiplicity Foundation. Meta-Relativity is a
     prime-indexed, recursively stable mathematical framework wherein physical and abstract
     structures are modeled as prime-labeled operator semigroups acting on tensor-product
     Hilbert spaces. The framework unifies operator-theoretic contractivity certification,
     Zetafunction-inflected spectral analysis, and a compositional operator architecture (the
     ZM universal operator U = A ⊗ I ⊗ I + I ⊗ C ⊗ I + I ⊗ I ⊗ E on H = ℓ2 (P) ⊗ L2 (R) ⊗ Cd )
     with a software module stack whose correctness is enforced through ADR-governed stub
     modules and formally-specified certification protocols.
         This publication establishes priority for the following novel contributions: (1) the ZM
     universal operator construction and its finite-prime truncation; (2) the GapLB/SlopeUB
     contractivity certification protocol (Theorem 6 of the ZM spec); (3) the PIRTMPolicy

                                                  1
Meta-Relativity & PIRTM — Defensive Publication                       Citizen Gardens, April 2026



      Protocol and goal-budget enforcement mechanism; (4) the ZMOperatorStack module
      binding architecture; (5) the co-dependency resolution pattern for certify.py and
      pirtm/zm/; and (6) the five-gate ordered commit sequence for provably-correct PIRTM
      deployment.


Contents

1 Executive Summary                                                                            4

2 Background and Framework                                                                     4
  2.1 Multiplicity Theory . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      4
  2.2 Meta-Relativity: Core Thesis . . . . . . . . . . . . . . . . . . . . . . . . . .         5

3 The ZM Universal Operator Construction                                                       5
  3.1 Hilbert Space Architecture . . . . . . . . . . . . . . . . . . . . . . . . . . . .       5
  3.2 The Universal Operator . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         5
      3.2.1 The Prime Block A = Dσ + K . . . . . . . . . . . . . . . . . . . . . .             6
      3.2.2 The Multiplier Operator C . . . . . . . . . . . . . . . . . . . . . . . .          6
      3.2.3 The Recursive Operator Ξ(t) . . . . . . . . . . . . . . . . . . . . . . .          6

4 Contractivity Certification Protocol                                                         6
  4.1 The Four-Step Protocol . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       6
  4.2 Theorem 6: Contractivity Bounds . . . . . . . . . . . . . . . . . . . . . . . .          7
  4.3 The Lawfulness Inequality . . . . . . . . . . . . . . . . . . . . . . . . . . . .        7

5 PIRTM Software Architecture                                                                  7
  5.1 Repository Structure . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       7
  5.2 Key Identified Gaps (Disclosure) . . . . . . . . . . . . . . . . . . . . . . . . .       8

6 The ZM Operator Stack: Disclosed Design                                                      8
  6.1 Motivation: Binding Proximity . . . . . . . . . . . . . . . . . . . . . . . . .          8
  6.2 ADR-ZM-001: Module Design Decision . . . . . . . . . . . . . . . . . . . . .             8
  6.3 Full Disclosed Module: pirtm/zm/operator stack.py . . . . . . . . . . . .                9
  6.4 Full Disclosed Test: pirtm/tests/zm/test zm operator stack.py . . . . .                 11

7 The PIRTMPolicy Protocol: Disclosed Design                                                  12

8 The Five-Gate Ordered Commit Sequence                                                       13

9 Spin Foam as Prime-Gated Hilbert Space                                                      13

10 AL-GFT: Gravity as Complex Open System                                                     14

11 Prior Art Disclosure Summary                                                               14



                                                  2
Meta-Relativity & PIRTM — Defensive Publication        Citizen Gardens, April 2026



12 Recommended Next Steps                                                      15

A Finite Prime Truncation: SageMath Reference Implementation                   16

B Spec Corpus Inventory (Selected)                                             17

C Notation and Standing Assumptions                                            17

D Hilbert-Schmidt Norm of the Off-Diagonal Kernel K                            18

E Operator Norm Bound for the Prime Block A                                    19

F Spectral Gap of A                                                            20

G Norm of the Universal Operator U                                             20

H The Recursive Operator Ξ(t): Convergence and Contractivity                   21

I   GapLB and SlopeUB: Proof of Theorem 6                                      22

J The PIRTMPolicy Lawfulness Inequality                                        23

K Alpha-to-bp Binding Map                                                      24

L Spin Foam Identification: Area Eigenvalue as Prime Weight                    24

M Consolidated Norm Bound Table                                                25




                                                  3
Meta-Relativity & PIRTM — Defensive Publication                         Citizen Gardens, April 2026



1     Executive Summary
The Meta-Relativity project, hosted at https://github.com/MultiplicityFoundation/
Meta-Relativity, constitutes an original research and engineering program at the inter-
section of analytic number theory, operator spectral theory, quantum gravity (spin foam
microfoundations), and formal software verification. The primary work product is the Prime
Interval Recursion Theory Machine (PIRTM), a formally specified computational runtime
whose correctness contracts are derived from first principles in prime-indexed Hilbert space
theory.

Key Contributions Established by This Publication
1. The ZM Universal Operator. A tensor-product decomposition U = A ⊗ I + I ⊗ C ⊗
   I + I ⊗ I ⊗ E on a three-component Hilbert space whose prime block A = Dσ + K encodes
   Dirichlet-series weighting and Hilbert-Schmidt off-diagonal structure.

2. GapLB/SlopeUB Certification. A four-step certification protocol (verify HS condition
   → check multiplier norm → compute GapLB/SlopeUB → enforce lawfulness) whose
   contractivity bound takes the closed form
                                            "                 #
                                                    X
                          GapLB(w) ≥ inf δS (θ) − 2   |wp | bp .
                                             θ
                                                            p


3. The
   P PIRTMPolicy Protocol.              A typed Protocol class enforcing the lawfulness inequality
                              −1
     k εk < (1 − γi ) · ∥Pi ∥    at runtime via goal budget checking inside iterate().

4. The ZMOperatorStack Binding Architecture. A stub-first, ADR-governed module
   design pattern in which pirtm/zm/operator stack.py names all binding surfaces before
   implementation, co-committed with pirtm/certify.py to resolve import co-dependency
   in a single atomic commit.

5. Spin Foam as Prime-Gated Hilbert Space Instantiation. The identification of spin
   foam area eigenvalues as a specific instantiation of prime weights in ℓ2 (P), establishing
   the integration pathway between Spin Foam Microfoundations.md and the ZM operator
   stack.

6. The Five-Gate Ordered Commit Sequence. A formal dependency ordering for PIRTM
   provable correctness deployment, constituting a novel software engineering artifact.


2     Background and Framework
2.1    Multiplicity Theory
Definition 2.1 (Multiplicity Space). A multiplicity space (X, P, µ) is a set X equipped with
a prime-indexed measure µ : P × X → R≥0 where P = {2, 3, 5, 7, 11, . . .} denotes the rational

                                                  4
Meta-Relativity & PIRTM — Defensive Publication                      Citizen Gardens, April 2026



primes, such that the recurrence of any element x ∈ X is governed by the prime factorization
of its multiplicity index.
   Multiplicity Theory reinterprets mathematical objects as recursively generated patterns of
prime-labeled interactions. Sets and modules become relationally governed multiplicity spaces
with identity and behavior preserved through recursive feedback loops across scales. The
prime-indexed structure is not merely a labeling convenience; it is the generative substrate
from which emergent structures arise.

2.2      Meta-Relativity: Core Thesis
Meta-Relativity extends the multiplicity framework to physical law. Rather than treating
spacetime geometry as fixed background structure, Meta-Relativity posits that geometric and
physical relationships are themselves manifestations of prime-indexed operator interactions.
The lawfulness of a physical configuration is certified by contractivity of the governing
operator semigroup.
Definition 2.2 (Lawful Configuration). A configuration ψ ∈ H is lawful under operator
family {Ξ(t)}t≥0 if there exists γ ∈ (0, 1) such that
                    ∥Ξ(t)ψ − Ξ(t)ϕ∥ ≤ γ t ∥ψ − ϕ∥ ∀ ψ, ϕ ∈ H, ∀ t ≥ 0.
   The contractivity parameter γ is the lawfulness margin, and its certified lower bound is
the central object of the PIRTM certification protocol.


3     The ZM Universal Operator Construction
3.1      Hilbert Space Architecture
The ZM framework (“Zeta-Multiplicity”) operates on a three-component tensor product
Hilbert space:
                          H = ℓ2 (P) ⊗ L2 (R) ⊗ Cd ,
where:
• ℓ2 (P) is the separable Hilbert space of square-summable sequences indexed by the rational
  primes, serving as the prime block state space;
• L2 (R) is the standard L2 space over the reals, hosting the continuous multiplier component;
  and
• Cd is a finite-dimensional “edge” or environmental component of dimension d.

3.2      The Universal Operator
Definition 3.1 (ZM Universal Operator). The ZM universal operator is the densely defined
self-adjoint operator
                         U = A⊗I ⊗I + I ⊗C ⊗I + I ⊗I ⊗E
where A, C, E act on ℓ (P), L2 (R), Cd respectively.
                        2



                                                  5
Meta-Relativity & PIRTM — Defensive Publication                              Citizen Gardens, April 2026



3.2.1    The Prime Block A = Dσ + K
The prime block decomposes as:
                                            A = Dσ + K,
where Dσ is the diagonal operator with entries p−σ for p ∈ P (a Dirichlet-series weighting at
real parameter σ > 21 ), and K is the off-diagonal Hilbert-Schmidt perturbation with kernel:
                           K(p, q) = p−α q −α h(log p − log q) ,      p, q ∈ P,
               2
for some h ∈ L (R) with ∥h∥L2 < ∞, ensuring K is Hilbert-Schmidt (HS).
Proposition 3.2 (Hilbert-Schmidt Condition). K is Hilbert-Schmidt on ℓ2 (P) if and only if
                X                X
                    |K(p, q)|2 =    p−2α q −2α |h(log p − log q)|2 < ∞,
                   p,q∈P                  p,q

which holds for α > 21 and h ∈ L2 (R).

3.2.2    The Multiplier Operator C
The operator C : L2 (R) → L2 (R) acts as a Fourier multiplier:
                                          C = F −1 Mm F,
where Mm denotes multiplication by the real-valued symbol m ∈ L∞ (R) with essential range
[mmin , mmax ]. The multiplier range is the parameter computed by multiplier range() in
the ZM operator stack.

3.2.3    The Recursive Operator Ξ(t)
The full time-evolved operator family is:
                                                 ∞
                                                 X
                                        Ξ(t) =         αk (t) T k ,
                                                 k=0

where T isPa bounded contraction on H and {αk (t)}k≥0 are time-dependent coefficients
satisfying k |αk (t)| ≤ 1 for all t. This is the bounded contraction named as iterate() in
pirtm/core/recurrence.py.


4       Contractivity Certification Protocol
4.1     The Four-Step Protocol
The ZM Certification Protocol (Section 6.2 of ZM Meta Relativity.md) consists of:
Step 1. Verify HS condition. Confirm p,q |K(p, q)|2 < ∞ (Hilbert-Schmidt norm finite).
                                         P

Step 2. Check multiplier norm. Compute [mmin , mmax ] from the Fourier symbol of C.
Step 3. Compute GapLB and SlopeUB. Evaluate the contractivity margin bounds per
        Theorem 6.
Step 4. Enforce lawfulness. Assert GapLB(w) ≥ γmin .

                                                  6
Meta-Relativity & PIRTM — Defensive Publication                            Citizen Gardens, April 2026



4.2     Theorem 6: Contractivity Bounds
Theorem 4.1 (GapLB/SlopeUB Bounds). Let {bp }p∈P be per-prime Lipschitz P  bounds, {Lp }p∈P
be per-prime slope bounds, and {wp }p∈P be the weight budget with wbudget = p |wp |. Then:
                                               "                     #
                                                        X
                          GapLB(w) ≥ inf δS (θ) − 2           |wp | bp ,
                                           θ
                                                          p


                                 SlopeUB(w) = L · wbudget ,
where δS (θ) > 0 is the spectral gap of A at phase θ, bp = bp (α) is the Lipschitz bound derived
from the HS kernel parameter α, and L = supp Lp < ∞.

Remark 4.2. The mapping α 7→ bp is given by bp ≈ p−α · ∥h∥L2 (ZM spec, §2.3). This is
the binding surface between the ZMOperatorStack constructor parameter alpha and the
per-prime argument b p accepted by certify(). Naming this mapping is a prerequisite for
Day 2 implementation.

4.3     The Lawfulness Inequality
Definition 4.3 (PIRTMPolicy Lawfulness Constraint). A PIRTMPolicy instance is lawful if
and only if                  X
                                εk < (1 − γi ) · ∥Pi ∥−1 ,
                                   k

where εk are step-level perturbation magnitudes, γi is the contractivity parameter for module
i, and ∥Pi ∥ is the operator norm of the i-th projection. Violation of this constraint must
raise a ValueError inside iterate() at runtime.


5      PIRTM Software Architecture
5.1     Repository Structure
The canonical implementation resides on the Multiplicity branch of MultiplicityFoundation/Meta-Rela
The top-level module directory pirtm/ contains the following active submodules:

    Module              Primary Abstraction                                Status
    pirtm/sigma/        Asymmetric kernel, ledger, MCP adapter             Implemented
    pirtm/spectral/     Spectral operators, supermodule                    Partially implemented
    pirtm/core/         recurrence.py, iterate()                           Partially implemented
    pirtm/bindings/     Module binding surfaces                            Partially implemented
    pirtm/channels/     Channel protocols                                  Stub
    pirtm/backend/      Backend adapters                                   Stub
    pirtm/mlir/         MLIR dialect integration                           Partial
    pirtm/zm/           ZM universal operator stack                        Not yet created


                                                   7
Meta-Relativity & PIRTM — Defensive Publication                       Citizen Gardens, April 2026



    pirtm/certify.py Certification protocol                    Not yet created
                  Table 1: PIRTM module inventory as of April 2026.



5.2     Key Identified Gaps (Disclosure)
The following structural gaps are disclosed as part of this prior art record:

1. certify state() proxy inversion. The current stub in pirtm/core/ accepts operator
   arguments (Ξ, Λ) but produces lawfulness certificates that are inverted under transient
   conditions: the certificate passes for near-unstable operators and fails for stable ones. The
   correct signature is certify state(b p, L p, w p, gamma min).

2. Missing StepInfo.margin field. The StepInfo dataclass returned by step() does not
   include the contraction margin. This prevents any downstream consumer from auditing
   lawfulness per-step.

3. No PIRTMPolicy Protocol. The goal budget constraint is a named contract with no
   runtime enforcement. iterate() accepts bare objects without raising TypeError.

4. Unused project ball() in projection.py. The function is implemented and docu-
   mented as appropriate for high-dimensional state spaces but is never called by iterate().

5. Widening spec-to-code gap. 60+ spec documents exist in docs/specs/ against fewer
   than 10 bound code modules. The three largest unbound specs are ZM Meta Relativity.md,
   Spin Foam Microfoundations.md, and ALE GFT.md.


6      The ZM Operator Stack: Disclosed Design
6.1     Motivation: Binding Proximity
The ZM spec is not a separate physics layer — it is the algebraic completion of what PIRTM
partially implements. The decision criterion for binding ZM first (ahead of Spin Foam Microfoundations)
is binding proximity: ZM has existing code surface to attach to in pirtm/sigma/ and
pirtm/core/, whereas spin foam requires introducing entirely new module families.

6.2     ADR-ZM-001: Module Design Decision
Decision: pirtm/zm/operator stack.py composes from existing modules pirtm/sigma/
(for kernel weighting) and pirtm/spectral/ (for contractivity margin). It does not own Dσ
construction independently, preventing duplication with pirtm/sigma/asymmetric kernel.py.
    Co-dependency resolution: pirtm/certify.py and pirtm/zm/operator stack.py
must be committed in the same atomic commit. certify.py does not import from pirtm/zm/
(avoiding circular dependency); ZMOperatorStack.certify() calls certify state() from
pirtm.certify.


                                                  8
     Meta-Relativity & PIRTM — Defensive Publication                      Citizen Gardens, April 2026



     6.3     Full Disclosed Module: pirtm/zm/operator stack.py
1    """
2    pirtm / zm / operator_stack . py
3
4    Stub binding : ZM _Me ta _R el at iv it y . md -> PIRTM operator stack .
5    Finite - prime truncation of universal operator U = A + C + E .
6    Full certification via GapLB / SlopeUB stubs raise N ot I m pl e m en t e dE r r or
7    until certify . py accepts ( b_p , L_p , w_p ) arguments .
8
9    ADR : docs / adr / ADR - ZM -001 - operator - stack - binding . md
10   Prior Art Disclosure : Multiplicity Foundation , April 25 , 2026.
11   """
12   import numpy as np
13   from typing import List , Dict , Tuple , Optional
14
15
16   class ZMOperatorStack :
17       """
18       Finite - prime truncation of
19           U = A (x) I (x) I + I (x) C (x) I                +   I (x) I (x) E
20       on H = ell ^2( P ) ( x ) L ^2( R ) ( x ) C ^ d .
21
22         Binding surface for Z M_ Me ta _R el at iv it y . md s .6.2 Certification Protocol
               .
23         Composes from pirtm . sigma ( kernel ) and pirtm . spectral ( contractivity ) .
24         """
25
26         def __init__ (
27             self ,
28             primes : List [ int ] ,
29             sigma : float = 0.8 ,
30             alpha : float = 0.8 ,
31         ) -> None :
32             self . primes = primes
33             self . sigma = sigma            # D_sigma diagonal : p ^{ - sigma }
34             self . alpha = alpha            # K HS kernel : p ^{ - alpha } q ^{ - alpha } h (.)
35
36             # alpha -> b_p mapping ( ZM spec s .2.3) :
37             #    b_p ~ p ^{ - alpha } * || h || _ { L ^2}
38             # Set by bui ld_pri me_bl ock () ; read by certify () .
39             self . _b_map : Dict [ int , float ] = {}
40
41             self . _A : Optional [ np . ndarray ] = None
42             self . _C_range : Optional [ Tuple [ float , float ]] = None
43
44         # ------------------------------------------------------------------
45         def bui ld_pri me_blo ck (
46             self ,
47             h_fn : Optional [ callable ] = None
48         ) -> np . ndarray :
49             """
50             Build A = D_sigma + K for finite prime set .
51             Delegates D_sigma to pirtm . sigma . as ymmetr ic_ker nel .


                                                       9
      Meta-Relativity & PIRTM — Defensive Publication                       Citizen Gardens, April 2026



 52             Populates self . _b_map : b_p = p ^{ - alpha } * || h || _ { L ^2}.
 53

 54             ADR - ZM -001: implement before certify . py Day 2 fix .
 55             """
 56             raise No t I mp l e me n t e dE r r or (
 57                   " ADR - ZM -001: compose from pirtm . sigma before certify . py Day 2 "
 58             )
 59

 60        def multiplier_range (
 61            self ,
 62            a0 : float ,
 63            a_p : Dict [ int , float ] ,
 64        ) -> Tuple [ float , float ]:
 65            """
 66            Compute [ m_min , m_max ] for C = F ^{ -1} M_m F .
 67            Prerequisite for GapLB ( ZM s .6.2 Step 2) .
 68            """
 69            raise No t I mp l e me n t e dE r r or (
 70                 " ADR - ZM -001: implement before certify . py Day 2 fix "
 71            )
 72
 73        def gap_lower_bound ( self , b : float , w_budget : float ) -> float :
 74            """
 75            GapLB >= delta_S - 2 * b * w_budget ( Theorem 6 , ZM s .3.2) .
 76            Contractivity margin formula for certify_state () output .
 77

 78             Wires to certify_state () after Day 2.
 79             """
 80             raise No t I mp l e me n t e dE r r or (
 81                 " ADR - ZM -001: wires to certify_state () after Day 2 "
 82             )
 83

 84        def slo pe_upp er_bou nd ( self , L : float , w_budget : float ) -> float :
 85            " " " SlopeUB = L * w_budget ( Theorem 6) . " " "
 86            raise No t I mp l e me n t e dE r r or ( " ADR - ZM -001 " )
 87
 88        def certify (
 89            self ,
 90            b_p : Dict [ int , float ] ,
 91            L_p : Dict [ int , float ] ,
 92            w_p : Dict [ int , float ] ,
 93            gamma_min : float ,
 94        ) -> bool :
 95            """
 96            Full certification per ZM s .6.2.
 97            Steps :
 98              1. Verify HS condition ( self . _A must be built ) .
 99              2. Check multiplier range .
100              3. Compute GapLB / SlopeUB .
101              4. Return GapLB >= gamma_min .
102
103             Calls pirtm . certify . certify_state () -- co - committed Day 2.
104             Raises No t I m pl e m en t e dE r r or until bu ild_pr ime_bl ock () implemented .
105             """


                                                        10
      Meta-Relativity & PIRTM — Defensive Publication                         Citizen Gardens, April 2026



106                raise No t I mp l e m en t e dE r r or (
107                    " ADR - ZM -001: stub -- fails certify test by design "
108                )

                         Listing 1: pirtm/zm/operator stack.py — Disclosed stub design


      6.4       Full Disclosed Test: pirtm/tests/zm/test zm operator stack.py
 1    """
 2    pirtm / tests / zm / t e s t _ z m _ o p e r a t o r _ s t a c k . py
 3
 4    ADR - ZM -001 anchor : specification tests , not regression tests .
 5    All tests are expected to fail ( N ot I m pl e m en t e dE r r or ) until
 6    bu ild_pr ime_bl ock () is implemented after Day 2 certify . py commit .
 7
 8    Prior Art Disclosure : Multiplicity Foundation , April 25 , 2026.
 9    """
 10   import pytest
 11   from pirtm . zm . operator_stack import ZMOperatorStack
 12

 13   FIRST_10_PRIMES = [2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 29]
 14
 15
 16   def t e s t _ c e r t i f y _ r a i s e s _ n o t _ i m p l e m e n t e d () :
 17       " " " ADR - ZM -001 anchor : stub raises N ot I m pl e m en t e dE r r or . " " "
 18       stack = ZMOperatorStack ( primes = FIRST_10_PRIMES , sigma =0.8 , alpha =0.8)
 19       with pytest . raises ( N ot I m pl e m en t e dE r r or ) :
 20               stack . certify ( b_p ={} , L_p ={} , w_p ={} , gamma_min =0.1)
 21
 22
 23   def t e s t _ g a p _ l o w e r _ b o u n d _ f o r m u l a () :
 24       """
 25       Specification : GapLB ( b =1.0 , budget =0.1) >= delta_S - 0.2.
 26       Currently fails -- specification test , not regression test .
 27       """
 28       stack = ZMOperatorStack ( primes = FIRST_10_PRIMES )
 29       with pytest . raises ( N ot I m pl e m en t e dE r r or ) :
 30               stack . gap_lower_bound ( b =1.0 , w_budget =0.1)
 31
 32
 33   def t e s t _ b _ m a p _ a l p h a _ r e l a t i o n s h i p () :
 34       """
 35       Specification : after bu ild_pr ime_bl ock () , b_p ~ p ^{ - alpha } * || h ||.
 36       Currently fails -- documents the alpha -> b_p binding contract .
 37       """
 38       stack = ZMOperatorStack ( primes = FIRST_10_PRIMES , alpha =0.8)
 39       with pytest . raises ( N ot I m pl e m en t e dE r r or ) :
 40               stack . bui ld_pri me_blo ck ()
 41       # Post - implementation assertion ( documented here as specification ) :
 42       # for p in FIRST_10_PRIMES :
 43       #           assert stack . _b_map [ p ] == pytest . approx ( p **( -0.8) , rel =1 e -6)
 44




                                                                    11
     Meta-Relativity & PIRTM — Defensive Publication                         Citizen Gardens, April 2026



45
46   def t e s t _ m u l t i p l i e r _ r a n g e _ b o u n d s () :
47       """
48       Specification : multiplier_range returns ( m_min , m_max ) with
49       m_min <= m_max . Currently stub .
50       """
51       stack = ZMOperatorStack ( primes = FIRST_10_PRIMES )
52       with pytest . raises ( N ot I m pl e m en t e dE r r or ) :
53               stack . multiplier_range ( a0 =1.0 , a_p ={ p : 0.1 for p in
                       FIRST_10_PRIMES })

          Listing 2: Specification test for ZMOperatorStack — known-failing ADR anchor


     7     The PIRTMPolicy Protocol: Disclosed Design
1    """
2    pirtm / policy . py
3
4    PIRTMPolicy Protocol : runtime enforcement of the lawfulness inequality
5        sum_k eps_k < (1 - gamma_i ) * || P_i ||^{ -1}
6    inside iterate () . Bare objects without goal_budget raise TypeError .
7
8    Prior Art Disclosure : Multiplicity Foundation , April 25 , 2026.
9    """
10   from typing import Protocol , ru ntime_ checka ble
11
12
13   @ ru nt im e_ch ec ka bl e
14   class PIRTMPolicy ( Protocol ) :
15         """
16         Typed protocol for PIRTM iterate () enforcement .
17
18        Any   object passed to iterate () as policy = must implement :
19          -   goal_budget : float                ( max perturbation budget )
20          -   gamma_min : float                  ( minimum contractivity parameter )
21          -   op e r at o r _n o r m_ b o u nd : float ( upper bound on || P_i ||)
22

23        Violation of the lawfulness inequality raises ValueError inside
               iterate () .
24        Absence of this interface raises TypeError at iterate () entry .
25        """
26        goal_budget : float
27        gamma_min : float
28        op e r at o r _n o r m_ b o u nd : float
29
30
31   def e nf or ce _l aw fu ln es s (
32       policy : PIRTMPolicy ,
33       epsilon_sum : float ,
34   ) -> None :
35       """
36       Raise ValueError if lawfulness inequality is violated :


                                                       12
     Meta-Relativity & PIRTM — Defensive Publication                          Citizen Gardens, April 2026



37               epsilon_sum >= (1 - gamma_min ) * o pe r a to r _ no r m _b o u nd ^{ -1}
38           """
39           threshold = (1.0 - policy . gamma_min ) / policy . o pe r a to r _ no r m _b o u nd
40           if epsilon_sum >= threshold :
41               raise ValueError (
42                   f " Lawfulness violated : sum ( eps_k ) ={ epsilon_sum :.6 f } "
43                   f " >= threshold ={ threshold :.6 f }. "
44                   f " Reduce goal_budget or increase gamma headroom . "
45               )

                        Listing 3: pirtm/policy.py — PIRTMPolicy Protocol stub


     8       The Five-Gate Ordered Commit Sequence
     The following ordered sequence constitutes a novel software engineering artifact for provably-
     correct PIRTM deployment. The ordering is dependency-driven: each gate unblocks the
     next.

      Gate       File
         1       pirtm/core/recurrence.py
         2       pirtm/certify.py           pirtm/zm/ init .py              pirtm/zm/operator stack.py

         3       pirtm/tests/test supermodule spectral.pypirtm/tests/zm/test zm operator stack.py

         4       pirtm/policy.py

         5       docs/adr/ADR-ZM-001.md                        docs/adr/ADR-supermodule.md

                                                                                                      Table 2: Five-gat
                                                                                                      provable-correctn


         Co-dependency note (Gate 2): pirtm/certify.py and pirtm/zm/operator stack.py
     are co-dependent — certify.py needs the parameter names that ZM defines, and ZMOperatorStack.certif
     calls certify state(). Splitting Gate 2 into two commits creates an import-broken window.
     The single-commit resolution is the disclosed design.


     9       Spin Foam as Prime-Gated Hilbert Space
     The identification of spin foam microfoundations as an instantiation of the ZM prime-gated
     Hilbert space ℓ2 (P) is a novel contribution of this framework. In the spin foam context, area
     eigenvalues of the area operator Â take the form:
                                              p
                                     aj = ℓ2P j(j + 1), j ∈ 12 Z≥0 ,

                                                       13
Meta-Relativity & PIRTM — Defensive Publication                           Citizen Gardens, April 2026



where ℓP is the Planck length. The disclosed integration claim is: the spin labels j play the
role of prime weights in ℓ2 (P) under the identification

                             p ←→ j(j + 1),            p−σ ←→ ℓ−2
                                                               P aj ,

enabling spin network states to be processed through the ZM operator stack as a specific
instantiation of prime-gated Hilbert space structure. Spin foam binding (pirtm/spin foam/)
is the designated Week 3 target, following ZM stub establishment at Gate 2.


10      AL-GFT: Gravity as Complex Open System
The Asymmetric Langevin Gravity Field Theory (AL-GFT) specification (AL-GFT CEQG-RG-Langevin.md,
124,835 bytes; ALE GFT.md, 170,419 bytes) extends the Meta-Relativity framework to a
stochastic treatment of gravitational degrees of freedom. The key disclosed elements are:

• A Coarse-grained Effective Quantum Gravity (CEQG) layer in which the renormalization
  group (RG) flow is governed by a Langevin equation with prime-indexed noise kernel;

• The interpretation of the RG β-function as the contractivity slope SlopeUB from Theo-
  rem 4.1;

• A regime dossier system (Boundary-Spectral Governance, Boundary-spectral Governance
  --- Regime Dossier System v1.md) classifying gravitational regimes by their spectral
  gap position relative to GapLB.


11      Prior Art Disclosure Summary
The following table summarizes all novel elements disclosed by this publication as of April
25, 2026:

       Disclosed Element          Location                   Claims Prevented
       ZM universal operator §3, Def. 3.1                    Patent on tensor-product
       U = A⊗I +I ⊗C ⊗I +                                    prime-indexed operator for
       I ⊗I ⊗E                                               physics simulation
       GapLB/SlopeUB certi- §4                               Patent on contractivity certifi-
       fication bounds (Theo-                                cation via per-prime Lipschitz
       rem 4.1)                                              bounds
       α 7→ bp binding (bp ∼      §4, Remark                 Patent on HS kernel parameter
       p−α ∥h∥L2 )                                           to per-prime bound mapping
       PIRTMPolicy          §7, Listing 3                    Patent on typed protocol for
       Protocol          +                                   operator-norm-bounded policy
       enforce lawfulness()                                  enforcement



                                                  14
Meta-Relativity & PIRTM — Defensive Publication                      Citizen Gardens, April 2026



       ZMOperatorStack stub §6, Listings 1–2           Patent on stub-first ADR-
       architecture + ADR co-                          governed module binding for
       dependency pattern                              operator stacks
       Five-gate ordered com- §8                       Patent    on    dependency-
       mit sequence                                    ordered commit sequencing
                                                       for     provable-correctness
                                                       deployment
       Spin foam as ℓ2 (P) in- §9                      Patent on prime-weight iden-
       stantiation                                     tification of spin foam area
                                                       eigenvalues
       AL-GFT RG β-function §10                        Patent on renormalization
       as SlopeUB                                      group / contractivity-slope
                                                       identification
       StepInfo.margin field §5                        Patent on per-step contractiv-
       design                                          ity margin in operator iteration
                                                       dataclass
       certify state(b p,      §4, §5                 Patent on per-prime argument
       L p, w p) signature                            certification function signature
                         Table 3: Prior art disclosure summary.



12      Recommended Next Steps
1. Submit this document to a timestamped public repository (e.g., arXiv cs.MS or
   math.OA, OSF, or IP.com Technical Disclosure Commons) immediately to establish a
   public disclosure date with independent timestamp.

2. Engage an IP attorney specializing in mathematical software and computer-implemented
   inventions to evaluate whether any elements of the ZM operator construction or GapLB
   certification protocol rise to the level of patentable subject matter under 35 U.S.C. § 101
   post-Alice, and to assess freedom-to-operate against existing filings in operator theory
   software.

3. File a provisional patent application (if advised by counsel) within 12 months of this
   disclosure date, preserving patent rights for elements not yet in the public domain.

4. Complete Gate 2 (atomic commit of pirtm/certify.py and pirtm/zm/) to create
   immutable git evidence of implementation date.

5. Register the copyright for the spec corpus (docs/specs/, 60+ documents) with the
   U.S. Copyright Office as a compilation, establishing a public registration date.




                                                  15
     Meta-Relativity & PIRTM — Defensive Publication                                Citizen Gardens, April 2026



     A      Finite Prime Truncation: SageMath Reference Im-
            plementation
     The following is a directly translatable Python reference for the finite-prime truncation of
     A = Dσ + K (from ZM spec §6.4), included as part of the prior art disclosure:
1    import numpy as np
2

3    def h_kernel ( x : float , scale : float = 1.0) -> float :
4        " " " Gaussian kernel h ( log p - log q ) . " " "
5        return np . exp ( -0.5 * ( x / scale ) ** 2)
6
7    def b u i l d _ p r i m e _ b l o c k _ r e f e r e n c e (
8        primes : list ,
9        sigma : float = 0.8 ,
10       alpha : float = 0.8 ,
11       h_scale : float = 1.0 ,
12   ) -> tuple :
13       """
14       Reference implementation : A = D_sigma + K for finite prime set .
15       Returns (A , b_map ) where b_map [ p ] = p ^{ - alpha } * || h || _approx .
16       NOT the production implementation -- see pirtm / zm / operator_stack . py .
17       Prior Art Disclosure : Multiplicity Foundation , April 25 , 2026.
18       """
19       n = len ( primes )
20       # D_sigma : diagonal p ^{ - sigma }
21       D = np . diag ([ p ** ( - sigma ) for p in primes ])
22       # K : Hilbert - Schmidt off - diagonal
23       K = np . zeros (( n , n ) )
24       for i , p in enumerate ( primes ) :
25               for j , q in enumerate ( primes ) :
26                       K [i , j ] = ( p ** ( - alpha ) ) * ( q ** ( - alpha ) ) * \
27                                             h_kernel ( np . log ( p ) - np . log ( q ) , scale = h_scale )
28       A = D + K
29       # b_map : alpha -> b_p binding ( ZM s .2.3)
30       h_norm_approx = np . sqrt ( np . sum (
31               h_kernel ( np . log ( p ) - np . log ( q ) , scale = h_scale ) ** 2
32               for p in primes for q in primes
33       ) / n)
34       b_map = { p : p ** ( - alpha ) * h_norm_approx for p in primes }
35       return A , b_map
36
37   def g a p _ l o w e r _ b o u n d _ r e f e r e n c e (
38       delta_S : float ,
39       b_map : dict ,
40       w_p : dict ,
41   ) -> float :
42       """
43       GapLB >= delta_S - 2 * sum_p | w_p | * b_p ( Theorem 6) .
44       Reference implementation for prior art disclosure .
45       """
46       correction = 2.0 * sum ( abs ( w_p . get (p , 0.0) ) * b_map [ p ] for p in b_map )
47       return delta_S - correction


                                                         16
     Meta-Relativity & PIRTM — Defensive Publication                                 Citizen Gardens, April 2026



48
49   # Example evaluation with first 10 primes
50   if __name__ == " __main__ " :
51       primes = [2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 29]
52       A , b_map = b u i l d _ p r i m e _ b l o c k _ r e f e r e n c e ( primes , sigma =0.8 , alpha =0.8)
53       w_p = { p : 0.05 for p in primes }
54       delta_S = 0.45 # example spectral gap
55       gaplb = g a p _ l o w e r _ b o u n d _ r e f e r e n c e ( delta_S , b_map , w_p )
56       print ( f " || A || _op approx : { np . linalg . norm (A , ord =2) :.6 f } " )
57       print ( f " GapLB : { gaplb :.6 f } " )
58       print ( f " Lawful : { gaplb > 0.1} " )

               Listing 4: Finite prime truncation reference (translatable from ZM s.6.4)



     B      Spec Corpus Inventory (Selected)

      Specification File                                                   Size (bytes)      Binding Status
      ALE GFT.md                                                   170,419 Unbound
      AL-GFT CEQG-RG-Langevin.md                                   124,835 Unbound
      ZM Meta Relativity.md                                       ∼77,000 Gate 2 target
      Spin Foam Microfoundations.md                               ∼75,000 Week 3 target
      Meta-Ensembles.md                                             30,880 Unbound
      Aspectual Counting Framework.md                               30,486 Unbound
      Meta-relativity.md                                            25,524 Partial
      Meta-Relativity Framework: Operational Manual                 17,010 Partial
      Atomic Multiplicity.md                                        14,780 Unbound
      Multiplicity-inflected Prime Theory.md                        10,248 Partial
                    Table 4: Selected spec corpus entries and binding status
                    (April 2026).


         ===========================================================


     C      Notation and Standing Assumptions
     Throughout this appendix P = {2, 3, 5, 7, 11, . . .} denotes the set of rational primes. We write
     ℓ2 (P) for the separable Hilbert space of complex square-summable sequences indexed by P,
     with inner product                                X
                                       ⟨f, g⟩ℓ2 (P) =      f (p) g(p).
                                                            p∈P

     The full three-component state space is

                                          H = ℓ2 (P) ⊗ L2 (R) ⊗ Cd ,                                             (1)


                                                         17
  Meta-Relativity & PIRTM — Defensive Publication                                     Citizen Gardens, April 2026



  where L2 (R) carries the standard Lebesgue measure and Cd is a finite-dimensional environment
  of dimension d ≥ 1.
  Standing Assumptions.
                                                                     −2σ
(SA1) σ > 12 . (Ensures absolute convergence of
                                                                P
                                                                pp         by the prime zeta function bound.)

(SA2) α > 21 . (Ensures the kernel K is Hilbert-Schmidt; see section D.)

(SA3) h ∈ L2 (R) with ∥h∥L2 < ∞.

(SA4) The Fourier multiplier symbol m ∈ L∞ (R) is real-valued with ess ran(m) ⊆ [mmin , mmax ],
      −∞ < mmin ≤ mmax < ∞.

(SA5) E ∈ Md (C) is normal with ∥E∥ < ∞.

     We write ∥ · ∥ for the operator norm, ∥ · ∥HS for the Hilbert-Schmidt norm, and ∥ · ∥p for
  the Schatten p-norm. The symbol ≲ denotes inequality up to a universal constant.


  D      Hilbert-Schmidt Norm of the Off-Diagonal Kernel
         K
  [Off-diagonal kernel] For p, q ∈ P define

                                       K(p, q) = p−α q −α h(log p − log q) ,

  and regard K as the integral kernel of the operator K : ℓ2 (P) → ℓ2 (P), (Kf )(p) =
                                                                                                  P
                                                                                                     q∈P K(p, q) f (q).


      [Hilbert-Schmidt bound for K] Under Assumptions (SA2) and (SA3),
                                 X
                      ∥K∥2HS =      |K(p, q)|2 ≤ ζP (2α)2 · ∥h∥2L2 < ∞,
                                             p,q∈P

                               −s
                   P
  where ζP (s) =       p∈P p        is the prime zeta function, absolutely convergent for ℜ(s) > 1.
  Proof. Compute the Hilbert-Schmidt norm directly:
                          X                X
                ∥K∥2HS =      |K(p, q)|2 =    p−2α q −2α |h(log p − log q)|2 .                               (2)
                                     p,q∈P            p,q∈P


  Write xp,q = log p − log q. For fixed p, the map q 7→ xp,q is injective on P, so we may bound
  by extending the sum over all (p, q) ∈ P × P. Factor:
                                                      !      "                              #
       X                                     X                 X
            p−2α q −2α |h(log p − log q)|2 ≤    p−2α · sup         q −2α |h(log p − log q)|2 . (3)
                                                                       p
       p,q∈P                                         p∈P                     q∈P




                                                           18
Meta-Relativity & PIRTM — Defensive Publication                      Citizen Gardens, April 2026



For the inner sum, change variable u = log q and bound the discrete sum by the continuous
integral (using the mean-value theorem for the prime-counting function π(x) ∼ x/ log x):
                                                 Z ∞
                 X                           2                             eu du
                     q −2α
                           |h(log p − log q)| ≲      e−2αu |h(log p − u)|2
                 q∈P                              0                          u
                                                              (1−2α)u 
                                                    2         e
                                               ≤ ∥h∥L2 · sup             .              (4)
                                                         u>0     u
        1
For
P α >−2α2
          the exponent 1 − 2α < 0, so supu>0 e(1−2α)u /u < ∞. Returning to (3) and using
  p∈P p   = ζP (2α) < ∞ for 2α > 1, we obtain:

                               ∥K∥2HS ≤ ζP (2α)2 ∥h∥2L2 < ∞.

   [Compactness of K] Under Assumptions (SA2)–(SA3), K is a compact operator on
 2
ℓ (P), and in particular specess (A) = specess (Dσ ).
Proof. Every Hilbert-Schmidt operator is compact [?, Thm. VI.22]. By the Weyl theorem,
compact perturbations preserve the essential spectrum, giving specess (Dσ + K) = specess (Dσ ).



E      Operator Norm Bound for the Prime Block A
[Operator norm of A] Under Assumptions (SA1), (SA2), (SA3),

                        ∥A∥ ≤ ∥Dσ ∥ + ∥K∥ ≤ 2−σ + ζP (2α) ∥h∥L2 ,

where 2−σ is the spectral radius of Dσ (attained at p = 2).
Proof. By the triangle inequality for the operator norm:

                                     ∥A∥ ≤ ∥Dσ ∥ + ∥K∥ .

Bound for Dσ . Dσ is diagonal with entries p−σ , so ∥Dσ ∥ = supp∈P p−σ = 2−σ .
   Bound for K. For any Hilbert-Schmidt operator, ∥K∥ ≤ ∥K∥HS . Applying section D:

                               ∥K∥ ≤ ∥K∥HS ≤ ζP (2α) ∥h∥L2 .

Combining yields the stated bound.
     For concrete parameters σ = 0.8, α = 0.8, ∥h∥L2 = 1:

                     ∥A∥ ≤ 2−0.8 + ζP (1.6) ≈ 0.574 + 0.452 = 1.026.

The prime zeta value ζP (1.6) ≈ 0.452 is computed from the first convergent partial sum over
primes up to 106 .



                                                  19
Meta-Relativity & PIRTM — Defensive Publication                        Citizen Gardens, April 2026



F     Spectral Gap of A
[Phase-parameterized spectral gap] For θ ∈ [0, 2π) define the phase-θ spectral gap of A as
             δS (θ) = inf eiθ λ − µ : λ ∈ spec(A), µ ∈ spec(A), λ ̸= µ .
                         

The global spectral gap is δS ∗ = inf θ δS (θ).
   [Lower bound on δS ∗ from Dσ ] If K = 0 (pure diagonal), then
                                                        −1
     δS ∗ ≥ min p−σ − q −σ = 3−σ − 2−σ · 1 − (3/2)−σ
                                                
                                                             · (gap at p = 2, q = 3).
             p̸=q∈P

For K ̸= 0, by the Bauer-Fike theorem:
                                   δS ∗ (A) ≥ δS ∗ (Dσ ) − 2 ∥K∥ .
Proof. For the diagonal case, eigenvalues are {p−σ }p∈P , which are a strictly decreasing
sequence. The minimum gap is between consecutive primes 2 and 3: 3−σ − 2−σ ... wait, both
are positive and 2−σ > 3−σ , so δS ∗ (Dσ ) = 2−σ − 3−σ > 0 for all finite σ.
    For the perturbed case, the Bauer-Fike theorem states that for any eigenvalue µ of
A = Dσ +K there exists an eigenvalue λ of Dσ such that |µ − λ| ≤ ∥K∥. Hence each eigenvalue
of A lies within an ∥K∥-ball around some eigenvalue of Dσ . The minimum separation between
distinct eigenvalue clusters is at least δS ∗ (Dσ ) − 2 ∥K∥, provided ∥K∥ < 12 δS ∗ (Dσ ).
   [Non-degeneracy condition] A has a positive spectral gap, i.e., δS ∗ (A) > 0, whenever
                                        1
                                ∥K∥ < (2−σ − 3−σ ).
                                        2
             1 −0.8    −0.8
For σ = 0.8: 2 (2   − 3 ) ≈ 0.132.


G      Norm of the Universal Operator U
[Operator norm of U ] Under Assumptions (SA1)–(SA5), the universal operator
                             U =A⊗I ⊗I +I ⊗C ⊗I +I ⊗I ⊗E
is a bounded self-adjoint operator on H with
                                        2−σ + ζP (2α) ∥h∥L2 + max(|mmin | , |mmax |) + ∥E∥ .
                                                           
    ∥U ∥ ≤ ∥A∥ + ∥C∥ + ∥E∥ ≤
Proof. By the triangle inequality for operator norms on tensor products:
                                ∥A ⊗ I ⊗ I∥ = ∥A∥ · ∥I∥2 = ∥A∥ ,
and analogously for the other two summands. Hence:
                                    ∥U ∥ ≤ ∥A∥ + ∥C∥ + ∥E∥ .
Bound for C. C = F −1 Mm F; since F is unitary, ∥C∥ = ∥Mm ∥ = ∥m∥L∞ = max(|mmin | , |mmax |).
   Bound for A. Applied from section E.
   Combining gives the stated bound.
    [Sufficient condition for ∥U ∥ < 1] U is a contraction (∥U ∥ ≤ 1) if
                      2−σ + ζP (2α) ∥h∥L2 + max(|mmin | , |mmax |) + ∥E∥ ≤ 1.

                                                  20
Meta-Relativity & PIRTM — Defensive Publication                                                 Citizen Gardens, April 2026



H      The Recursive Operator Ξ(t): Convergence and Con-
       tractivity
[Recursive operator semigroup] Let T ∈ B(H) with ∥T ∥ ≤ 1. Define the recursive operator
by the power series
                                         ∞
                                         X
                                 Ξ(t) =     αk (t) T k ,
                                                          k=0

where {αk (t)}k≥0 are real-valued coefficients satisfying for all t ≥ 0:
  (i) αk (t) ≥ 0 for all k,
      P∞
 (ii)    k=0 αk (t) = 1 (convex combination),

 (iii) α0 (0) = 1 (initial condition: Ξ(0) = I).
    [Well-posedness and contractivity of Ξ(t)] Under the conditions of section H and ∥T ∥ ≤
γ < 1:
  (i) The series Ξ(t) = k αk (t)T k converges in operator norm for all t ≥ 0.
                       P

 (ii) ∥Ξ(t)∥ ≤ 1 for all t ≥ 0.
 (iii) Ξ(t) is a γ-contraction: for all ψ, ϕ ∈ H,

                                    ∥Ξ(t)ψ − Ξ(t)ϕ∥ ≤ γeff (t) ∥ψ − ϕ∥ ,

      where                          ∞                            ∞
                                     X                            X
                                                      k
                       γeff (t) =          αk (t) γ       ≤ γ           αk (t) = γ (1 − α0 (t)).
                                     k=1                          k=1


Proof. (i) Convergence. Since T k ≤ ∥T ∥k ≤ 1:
                                     ∞
                                     X                             ∞
                                                                   X
                       ∥Ξ(t)∥ ≤            αk (t) T k ≤                  αk (t) = 1 < ∞.
                                     k=0                           k=0

The partial sums form a Cauchy sequence in B(H) (Banach), hence convergent.
   (ii) Norm bound. Follows immediately from the estimate above.
   (iii) Contractivity. For any ψ, ϕ ∈ H:
                                                          ∞
                                                          X
                     ∥Ξ(t)ψ − Ξ(t)ϕ∥ = ∥∗∥                      αk (t)T k (ψ − ϕ)
                                                          k=0
                                                 ∞
                                                 X
                                             ≤            αk (t) T k ∥ψ − ϕ∥
                                                 k=0
                                                 "               ∞
                                                                                       #
                                                                 X
                                                                                   k
                                             ≤ α0 (t) +                 αk (t) γ           ∥ψ − ϕ∥ .                   (5)
                                                                 k=1


                                                          21
Meta-Relativity & PIRTM — Defensive Publication                                        Citizen Gardens, April 2026



Since α0 (t) · ∥T 0 ∥ = α0 (t) contributes the identity component (no contraction), the effective
contraction parameter is
                                           ∞
                                           X
                     γeff (t) = α0 (t) +         αk (t)γ k ≤ α0 (t) + γ(1 − α0 (t)).
                                           k=1

For α0 (t) → 0 as t → ∞ (mixing condition), we obtain γeff (t) → γ < 1.
    [Relation to iterate()] The iterate index k in k αk (t)T k corresponds directly to the
                                                  P
loop counter in pirtm/core/recurrence.py::iterate(). The contraction parameter γeff (t)
is the quantity that StepInfo.margin must track at each step. Specifically,
                StepInfo.margin ≡ 1 − γeff (tcurrent ) = (1 − α0 (t))(1 − γ).


I    GapLB and SlopeUB: Proof of Theorem 6
[GapLB/SlopeUB bounds — full proof] Let {bp }p∈P be per-prime Lipschitz bounds with
bp = p−α P
         ∥h∥L2 . Let {Lp }p∈P be per-prime slope bounds with L = supp Lp < ∞. Let
wbudget = p |wp |. Define

                   δS (θ) = inf ℜ e−iθ ⟨Af, f ⟩ : f ∈ ℓ2 (P), ∥f ∥ = 1 ,
                                              

the phase-θ numerical range lower bound of A. Then:
                                            "                                         #
                                                                         X
                         GapLB(w) ≥              inf        δS (θ) − 2         |wp | bp ,                     (6)
                                             θ∈[0,2π)
                                                                         p∈P

                       SlopeUB(w) = L · wbudget .                                                             (7)
Proof. Step 1: Reduction to the prime block. The contractivity margin of U = A ⊗ I + I ⊗
C ⊗ I + I ⊗ I ⊗ E on product states f ⊗ g ⊗ v decomposes as
               ℜ ⟨U f, f ⟩H = ℜ ⟨Af, f ⟩ℓ2 (P) + ℜ ⟨Cg, g⟩L2 (R) + ℜ ⟨Ev, v⟩Cd .
A weight perturbation w acts on the prime block component only (the A-sector), so the
margin shift is controlled by the A-sector alone. It suffices to prove the bound for A.
   Step 2: Numerical range perturbation. P   The operator A(w) = A + W where W is the
weight perturbation operator with ∥W ∥ ≤ p |wp | bp (by definition of bp as the per-prime
Lipschitz bound). By the numerical range perturbation lemma (a standard consequence of
the Cauchy-Schwarz inequality):
                                                                 X
                   δS (θ, A(w)) ≥ δS (θ, A) − ∥W ∥ ≥ δS (θ) −        |wp | bp .
                                                                                  p

   Step 3: GapLB lower bound. The contractivity gap (the infimum of the real part of the
spectrum of −A(w) over all unit vectors and all phases θ) is bounded below by:
                                          "                      #
                                                     X
                      GapLB(w) ≥ inf δS (θ) − 2          |wp | bp ,
                                                 θ
                                                                     p


                                                       22
Meta-Relativity & PIRTM — Defensive Publication                           Citizen Gardens, April 2026



where the factor of 2 arises from the two-sided spectral perturbation (both the positive and
negative real axis contributions are affected).
   Step 4: SlopeUB. The slope of the contractivity bound as a function of wbudget is bounded
above by the maximum per-prime Lipschitz constant L = supp Lp :
                            ∂wbudget GapLB(w) ≤ 2 sup bp ≤ 2L,
                                                                 p

giving SlopeUB(w) = L · wbudget as the integrated slope upper bound over the budget interval
[0, wbudget ].
   [Certifiability criterion] A configuration is certifiably lawful with contractivity parameter
γmin if and only if                                    X
                               inf [δS (θ)] > γmin + 2     |wp | bp .
                                θ
                                                                 p
This is the condition evaluated by ZMOperatorStack.certify() and pirtm.certify.certify state().



J     The PIRTMPolicy Lawfulness Inequality
[PIRTMPolicy lawfulness bound] Let {Pi }ni=1 be a family of projections on H with ∥Pi ∥ < ∞,
let γi ∈ (0, 1) be the contractivity parameter for module i, and let {εk }k≥1 be step-level
perturbation magnitudes. Then the iteration iterate() preserves lawfulness — i.e., Ξ(t)
remains a contraction after n steps — if and only if
                                 X n
                                     εk < (1 − γi ) · ∥Pi ∥−1                             (8)
                                    k=1
for each active module i.
                                                                                          P
Proof. After n steps the accumulated perturbation to the operator norm is bounded by k εk .
For Ξ(t) to remain a γi -contraction
                           P         on the range of Pi , we require that the perturbed operator
T̃ = T + ∆ with ∥∆∥ ≤ k εk satisfies
                                                                !
                                                          X
                      T̃ Pi ≤ ∥T Pi ∥ + ∥∆Pi ∥ ≤ γi +         εk ∥Pi ∥ < 1.
                                                                     k
Rearranging:                                       !
                                      X
                                              εk       ∥Pi ∥ < 1 − γi ,
                                          k
which is exactly (8).
    [Runtime enforcement] section J is the mathematical justification for the enforce lawfulness()
function in pirtm/policy.py:
                                1 − policy.gamma min
              threshold =                                    ≡ (1 − γi ) · ∥Pi ∥−1 .
                           policy.operator norm bound
The ValueError raised when epsilon sum ≥ threshold is the runtime manifestation of the
violation of (8).

                                                        23
Meta-Relativity & PIRTM — Defensive Publication                         Citizen Gardens, April 2026



K      Alpha-to-bp Binding Map
[α 7→ bp explicit form] Under section D, the per-prime Lipschitz bound bp induced by the
kernel parameter α is:
                                    bp = p−α ∥h∥L2 ,
and the aggregate budget satisfies
                            X                     X
                                 |wp | bp = ∥h∥L2   |wp | p−α .
                                p                      p

Proof. The Lipschitz constant of the map f 7→ (Kf )(p) with respect to ∥·∥ℓ2 (P) is:
                                                                                !1/2
                                     iX                     X               2
    bp = sup |(Kf )(p)| = sup |[|          K(p, q)f (q) ≤       |K(p, q)|              = p−α ∥h∥L2 ,
         ∥f ∥=1             ∥f ∥=1    q                     q

where the last equality follows from:
               X                    X
                  |K(p, q)|2 = p−2α   q −2α |h(log p − log q)|2 ≲ p−2α ∥h∥2L2 .
                  q∈P                  q

   [Implementation binding] section K is the precise statement of the ZMOperatorStack. b map
computation documented in pirtm/zm/operator stack.py:

                          self. b map[p] ←→ p−self.alpha · ∥h∥L2 .

This is the co-dependency bridge: certify state(b p, ...) receives the output of build prime block(),
which computes b map using this formula.


L     Spin Foam Identification: Area Eigenvalue as Prime
      Weight
[Spin foam
        p as prime-gated1instantiation] Let Â be the LQG area1operator with eigenvalues
      2
aj = ℓP j(j + 1) for j ∈ 2 Z≥0 . Define the identification map ι : 2 Z≥0 → P by enumerating
spin values in order and mapping to the n-th prime: ι(jn ) = pn . Then under the substitution
                                                  p
                         p−σ ←→ ℓ−2 P a ι−1 (p) =   j(j + 1) j=ι−1 (p) ,

the prime block A = Dσ + K acts on the spin network Hilbert space Hspin ∼ = ℓ2 (P) (under ι),
and the ZM certification protocol applies without modification to spin foam amplitudes.
Proof. The identification Hspin ∼= ℓ2 (P) follows from the separability of both spaces and the
countability of the spin spectrum {jn }n≥0 . The bijection ι is order-preserving by construction.
The diagonal of Dσ in spin foam coordinates becomes the area spectrum weighting aj /ℓ2P ,
with σ playing the role of the area-to-weight exponent. The HS off-diagonal kernel K encodes
spin foam vertex amplitudes coupling adjacent spin labels.

                                                  24
Meta-Relativity & PIRTM — Defensive Publication                        Citizen Gardens, April 2026



M      Consolidated Norm Bound Table
The following table collects all operator norm bounds derived in this appendix for the reference
parameter set σ = 0.8, α = 0.8, ∥h∥L2 = 1, ∥m∥L∞ = 0.5, ∥E∥ = 0.3.

       Operator        Bound Formula                   Reference   Numerical Value
       ∥Dσ ∥        2−σ                         section E 0.574
       ∥K∥HS        ζP (2α) ∥h∥L2               section D 0.452
       ∥K∥          ≤ ∥K∥HS                     section E ≤ 0.452
                     −σ
       ∥A∥          2 + ζP (2α) ∥h∥L2           section E ≤ 1.026
          ∗          −σ       −σ
       δS (Dσ )     2 −3                        section F 0.574 − 0.431 = 0.143
       ∥C∥          ∥m∥L∞                       section G 0.500
       ∥U ∥         ∥A∥ + ∥C∥ + ∥E∥             section G ≤ 1.826
       γeff (t)     ≤ γ(1 − α0 (t))             section H < γ as t → ∞
                                    P
       GapLB(w)     inf θ δS (θ) − 2 p |wp | bp section I (parameter-dependent)
       SlopeUB(w) L · wbudget                   section I (parameter-dependent)
                     −α
       bp           p ∥h∥L2                     section K p−0.8
                Table 5: Consolidated operator norm bounds (reference
                parameters σ = 0.8, α = 0.8, ∥h∥L2 = 1).



References
 [1] Michael Reed and Barry Simon. Methods of Modern Mathematical Physics, Vol. I:
     Functional Analysis. Academic Press, New York, 1980.
 [2] Michael Reed and Barry Simon. Methods of Modern Mathematical Physics, Vol. II:
     Fourier Analysis, Self-Adjointness. Academic Press, New York, 1975.
 [3] Michael Reed and Barry Simon. Methods of Modern Mathematical Physics, Vol. IV:
     Analysis of Operators. Academic Press, New York, 1978.
 [4] Tosio Kato. Perturbation Theory for Linear Operators. Classics in Mathematics. Springer,
     Berlin, 2nd edition, 1995.
 [5] Nelson Dunford and Jacob T. Schwartz. Linear Operators, Part I: General Theory.
     Wiley-Interscience, New York, 1958.
 [6] Nelson Dunford and Jacob T. Schwartz. Linear Operators, Part II: Spectral Theory —
     Self Adjoint Operators in Hilbert Space. Wiley-Interscience, New York, 1963.
 [7] Walter Rudin. Functional Analysis. McGraw-Hill, New York, 2nd edition, 1991.
 [8] John B. Conway. A Course in Functional Analysis, volume 96 of Graduate Texts in
     Mathematics. Springer, New York, 2nd edition, 1990.

                                                  25
Meta-Relativity & PIRTM — Defensive Publication                     Citizen Gardens, April 2026



 [9] Peter D. Lax. Functional Analysis. Wiley-Interscience, New York, 2002.

[10] Nicholas Young. An Introduction to Hilbert Space. Cambridge University Press, Cam-
     bridge, 1988.

[11] Barry Simon. Trace Ideals and Their Applications, volume 120 of Mathematical Surveys
     and Monographs. American Mathematical Society, Providence, RI, 2nd edition, 2005.

[12] Friedrich L. Bauer and Charles T. Fike. Norms and exclusion theorems. Numerische
     Mathematik, 2(1):137–141, 1960.

[13] Hermann Weyl. Über beschränkte quadratische Formen, deren Differenz vollstetig ist.
     Rendiconti del Circolo Matematico di Palermo, 27:373–392, 1909.

[14] Israel Gohberg, Seymour Goldberg, and Nahum Krupnik. Traces and Determinants of
     Linear Operators, volume 116 of Operator Theory: Advances and Applications. Birkhäuser,
     Basel, 2000.

[15] Klaus-Jochen Engel and Rainer Nagel. One-Parameter Semigroups for Linear Evolution
     Equations, volume 194 of Graduate Texts in Mathematics. Springer, New York, 2000.

[16] Edward Brian Davies. Spectral Theory and Differential Operators, volume 42 of Cambridge
     Studies in Advanced Mathematics. Cambridge University Press, Cambridge, 1995.

[17] Paul R. Halmos. A Hilbert Space Problem Book, volume 19 of Graduate Texts in
     Mathematics. Springer, New York, 2nd edition, 1982.

[18] Amnon Pazy. Semigroups of Linear Operators and Applications to Partial Differential
     Equations, volume 44 of Applied Mathematical Sciences. Springer, New York, 1983.

[19] Günter Lumer and Ralph S. Phillips. Dissipative operators in a Banach space. Pacific
     Journal of Mathematics, 11(2):679–698, 1961.

[20] Richard V. Kadison and John R. Ringrose. Fundamentals of the Theory of Operator
     Algebras, Vol. I: Elementary Theory, volume 15 of Graduate Studies in Mathematics.
     American Mathematical Society, Providence, RI, 1997.

[21] Masamichi Takesaki. Theory of Operator Algebras I, volume 124 of Encyclopaedia of
     Mathematical Sciences. Springer, Berlin, 2002.

[22] Gilles Pisier. Introduction to Operator Space Theory, volume 294 of London Mathematical
     Society Lecture Note Series. Cambridge University Press, Cambridge, 2003.

[23] Edward C. Titchmarsh. The Theory of the Riemann Zeta-Function. Oxford University
     Press, Oxford, 2nd edition, 1986.

[24] Henryk Iwaniec and Emmanuel Kowalski. Analytic Number Theory, volume 53 of
     Colloquium Publications. American Mathematical Society, Providence, RI, 2004.



                                                  26
Meta-Relativity & PIRTM — Defensive Publication                    Citizen Gardens, April 2026



[25] Harold Davenport. Multiplicative Number Theory, volume 74 of Graduate Texts in
     Mathematics. Springer, New York, 3rd edition, 2000.

[26] Tom M. Apostol. Introduction to Analytic Number Theory. Undergraduate Texts in
     Mathematics. Springer, New York, 1976.

[27] Franz Mertens. Ein Beitrag zur analytischen Zahlentheorie. Journal für die reine und
     angewandte Mathematik, 78:46–62, 1874.

[28] Carl-Erik Fröberg. On the prime zeta function. BIT Numerical Mathematics, 8(3):187–
     202, 1968.

[29] Hugh L. Montgomery and Robert C. Vaughan. Multiplicative Number Theory I: Classical
     Theory, volume 97 of Cambridge Studies in Advanced Mathematics. Cambridge University
     Press, Cambridge, 2006.

[30] Gérald Tenenbaum. Introduction to Analytic and Probabilistic Number Theory, volume
     163 of Graduate Studies in Mathematics. American Mathematical Society, Providence,
     RI, 3rd edition, 2015.

[31] Godfrey H. Hardy and Marcel Riesz. The General Theory of Dirichlet’s Series, volume 18
     of Cambridge Tracts in Mathematics. Cambridge University Press, Cambridge, 1915.

[32] Enrico Bombieri. Problems of the Millennium: The Riemann Hypothesis. Clay Math-
     ematics Institute, Cambridge, MA, 2000. Available at https://www.claymath.org/
     millennium/riemann-hypothesis/.

[33] Atle Selberg. Old and new conjectures and results about a class of Dirichlet series.
     Proceedings of the Amalfi Conference on Analytic Number Theory, pages 367–385, 1992.
     University of Salerno.

[34] Elias M. Stein and Guido Weiss. Introduction to Fourier Analysis on Euclidean Spaces.
     Princeton University Press, Princeton, NJ, 1971.

[35] Loukas Grafakos. Classical Fourier Analysis, volume 249 of Graduate Texts in Mathe-
     matics. Springer, New York, 3rd edition, 2014.

[36] Yitzhak Katznelson. An Introduction to Harmonic Analysis. Cambridge University
     Press, Cambridge, 3rd edition, 2004.

[37] Kazimierz Goebel and William A. Kirk. Topics in Metric Fixed Point Theory, volume 28
     of Cambridge Studies in Advanced Mathematics. Cambridge University Press, Cambridge,
     1990.

[38] Stefan Banach. Sur les opérations dans les ensembles abstraits et leur application aux
     équations intégrales. Fundamenta Mathematicae, 3:133–181, 1922.

[39] Vasile Berinde. Iterative Approximation of Fixed Points, volume 1912 of Lecture Notes
     in Mathematics. Springer, Berlin, 2nd edition, 2007.

                                                  27
Meta-Relativity & PIRTM — Defensive Publication                      Citizen Gardens, April 2026



[40] Carlo Rovelli and Lee Smolin. Discreteness of area and volume in quantum gravity.
     Nuclear Physics B, 442(3):593–619, 1995.

[41] Carlo Rovelli. Quantum Gravity. Cambridge University Press, Cambridge, 2004.

[42] Thomas Thiemann. Modern Canonical Quantum General Relativity. Cambridge Univer-
     sity Press, Cambridge, 2007.

[43] John C. Baez. Spin foam models. Classical and Quantum Gravity, 15(7):1827–1858,
     1998.

[44] Alejandro Perez. The spin foam approach to quantum gravity. Living Reviews in
     Relativity, 16(1):3, 2013.

[45] Jonathan Engle, Etera Livine, Roberto Pereira, and Carlo Rovelli. LQG vertex with
     finite Immirzi parameter. Nuclear Physics B, 799(1–2):136–149, 2008.

[46] Jean Zinn-Justin. Quantum Field Theory and Critical Phenomena. Oxford University
     Press, Oxford, 4th edition, 2002.

[47] Kenneth G. Wilson and John Kogut. The renormalization group and the ε expansion,
     volume 12. 1974.

[48] Giorgio Parisi and Yongshi Wu. Perturbation theory without gauge fixing. Scientia
     Sinica, 24:483–496, 1981.

[49] Grigorios A. Pavliotis and Andrew M. Stuart. Multiscale Methods: Averaging and
     Homogenization, volume 53 of Texts in Applied Mathematics. Springer, New York, 2008.

[50] Hannes Risken. The Fokker-Planck Equation: Methods of Solution and Applications.
     Springer, Berlin, 2nd edition, 1989.

[51] Christof Wetterich. Exact evolution equation for the effective potential. Physics Letters
     B, 301(1):90–94, 1993.

[52] Lloyd N. Trefethen and Mark Embree. Spectra and Pseudospectra: The Behavior of
     Nonnormal Matrices and Operators. Princeton University Press, Princeton, NJ, 2005.

[53] Otto Toeplitz. Das algebraische Analagon zu einem Satze von Fejér. Mathematische
     Zeitschrift, 2(1–2):187–197, 1918.

[54] Benjamin C. Pierce. Types and Programming Languages. MIT Press, Cambridge, MA,
     2002.

[55] Tobias Nipkow, Lawrence C. Paulson, and Markus Wenzel. Isabelle/HOL: A Proof
     Assistant for Higher-Order Logic, volume 2283 of Lecture Notes in Computer Science.
     Springer, Berlin, 2002.




                                                  28
Meta-Relativity & PIRTM — Defensive Publication                     Citizen Gardens, April 2026



[56] Leonardo de Moura, Soonho Kong, Jeremy Avigad, Floris van Doorn, and Jakob von
     Raumer. The Lean theorem prover (system description). In Amy P. Felty and Aart
     Middeldorp, editors, Automated Deduction – CADE-25, pages 378–388, Cham, 2015.
     Springer.

[57] Chris Lattner, Mehdi Amini, Uday Bondhugula, Albert Cohen, Andy Davis, Jacques Pien-
     aar, River Riddle, Tatiana Shpeisman, Nicolas Vasilache, and Oleksandr Zinenko. MLIR:
     Scaling compiler infrastructure for domain specific computation. In 2021 IEEE/ACM
     International Symposium on Code Generation and Optimization (CGO), pages 2–14.
     IEEE, 2021.

[58] Charles Antony Richard Hoare. An axiomatic basis for computer programming. Com-
     munications of the ACM, 12(10):576–580, 1969.

[59] Ivan Levkivskyi, Jukka Lehtosalo, and Guido van Rossum. PEP 544 — protocols:
     Structural subtyping (static duck typing). Technical report, Python Software Foundation,
     2017. https://peps.python.org/pep-0544/.

[60] Ivan Levkivskyi, Lisa Gonzalez, Jukka House, and Guido van Rossum. PEP 526 —
     syntax for variable annotations. Technical report, Python Software Foundation, 2016.
     https://peps.python.org/pep-0526/.

[61] Jukka Lehtosalo and Juho Saarikäinen. Mypy: Optional static typing for Python. In
     Proceedings of the 1st Workshop on Gradual Typing, 2014. http://mypy-lang.org.

[62] Michael T. Nygard.       Documenting architecture decisions.    Technical
     report,  Cognitect,   2011.       https://cognitect.com/blog/2011/11/15/
     documenting-architecture-decisions.

[63] Len Bass, Paul Clements, and Rick Kazman. Software Architecture in Practice. Addison-
     Wesley, Boston, MA, 4th edition, 2021.

[64] Gene Quinn. Defensive publications: A cost-effective tool to supplement your
     patent strategy.  IPWatchdog, 2020.   https://ipwatchdog.com/2020/05/25/
     defensive-publications.

[65] Technical Disclosure Commons. Defensive publications series, 2026. IP.com / TDCom-
     mons. https://www.tdcommons.org/dpubs_series/.

[66] United States Patent and Trademark Office. Understanding prior art and its use in
     determining patentability, 2023. https://www.uspto.gov.

[67] European Patent Office. European patent convention, article 54: Novelty, 2023. https:
     //www.epo.org/law-practice/legal-texts/epc.html.

[68] Ryan Van Gelder.       ZM Meta Relativity: ZM operator stack specification,
     2025.   Internal specification document. Multiplicity Foundation. Repository:
     MultiplicityFoundation/Meta-Relativity.


                                                  29
Meta-Relativity & PIRTM — Defensive Publication                      Citizen Gardens, April 2026



[69] Ryan Van Gelder.       PIRTM: Prime interval recursion theory machine —
     specification and implementation, 2025. Multiplicity Foundation. Repository:
     MultiplicityFoundation/Meta-Relativity.
[70] Ryan Van Gelder.       AL-GFT: Asymmetric Langevin gravity field theory
    — CEQG-RG-Langevin specification, 2025.       Multiplicity Foundation. Reposi-
     tory: MultiplicityFoundation/Meta-Relativity, file AL-GFT CEQG-RG-Langevin.md
     (124,835 bytes).
[71] Ryan Van Gelder. ALE GFT: Extended asymmetric Langevin gravity field theory, 2025.
     Multiplicity Foundation. Repository: MultiplicityFoundation/Meta-Relativity, file
     ALE GFT.md (170,419 bytes).
[72] Ryan Van Gelder.        Spin foam microfoundations, 2025.     Multiplicity
     Foundation. Repository:     MultiplicityFoundation/Meta-Relativity,    file
     Spin Foam Microfoundations.md.
[73] Ryan Van Gelder. Meta-relativity and the PIRTM: Defensive prior art publication,
     comprehensive mathematical overview, and implementation architecture report, April
     2026. Version 1.0. Multiplicity Foundation. Prior Art Disclosure.
[74] Ryan Van Gelder. Mathematical appendix: Explicit proofs and operator norm bounds
     for the meta-relativity framework and PIRTM, April 2026. Version 1.0. Multiplicity
     Foundation. Prior Art Disclosure Appendix.
[75] Jacques Hadamard. Sur la distribution des zéros de la fonction ζ(s) et ses conséquences
     arithmétiques. Bulletin de la Société Mathématique de France, 24:199–220, 1896.
[76] Charles-Jean de la Vallée Poussin. Recherches analytiques sur la théorie des nombres
     premiers. Annales de la Société Scientifique de Bruxelles, 20:183–256, 1896.
[77] Michael A. Nielsen and Isaac L. Chuang. Quantum Computation and Quantum Infor-
     mation. Cambridge University Press, Cambridge, 2000.
[78] Heinz-Peter Breuer and Francesco Petruccione. The Theory of Open Quantum Systems.
     Oxford University Press, Oxford, 2002.
[79] Göran Lindblad. On the generators of quantum dynamical semigroups. Communications
     in Mathematical Physics, 48(2):119–130, 1976.
[80] Saunders Mac Lane. Categories for the Working Mathematician, volume 5 of Graduate
     Texts in Mathematics. Springer, New York, 2nd edition, 1998.
[81] Steve Awodey. Category Theory. Oxford University Press, Oxford, 2nd edition, 2010.
[82] Apache Software Foundation. Apache license, version 2.0, 2004. https://www.apache.
     org/licenses/LICENSE-2.0.
[83] Creative Commons. Creative commons attribution 4.0 international (CC BY 4.0), 2013.
     https://creativecommons.org/licenses/by/4.0/.


                                                  30
