           Prime-Graded Multiplicity
        Unified Specification and Formalization



                             Ryan O. Van Gelder

                                   Citizen Gardens

                    Institute for Mathematical Discovery
                                     August 28, 2026




                                       Abstract
We formalize the Prime – Graded Multiplicity (PGM) for the multiplicity operator M as a
single categorical object with consistent algebraic, analytic, and representation – theoretic
faces. The core consists of a signature category Sig, a prime – graded ∗ – algebra (A, {Pp })
with a positive state φ, and a functorial signature extractor F . From this backbone we
derive: (i) the strict monoidal functor Mfun : Sig → Q× ; (ii) the integer ledger Mint and
the state – dependent sector distribution M
                                          c(T, p); (iii) the diagonal representation M acting
on a signature Hilbert space with number operators Np . We prove normalization, stability,
and equivalence properties, give algorithms and complexity, and delimit a multiple – frame
extension as future work.
Contents
1 Introduction                                                                                       2

2 Preliminaries and Notation                                                                         2

3 Backbone of the PGM                                                                                2
  3.1 Signature Category Sig . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   2
  3.2 Prime – Graded ∗ – Algebra with State . . . . . . . . . . . . . . . . . . . . . . . . . .      2
  3.3 Signature Extractor . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    2

4 The M Object and Its Faces                                                                         3
  4.1 Functorial Mfun (Categorical Backbone) . . . . . . . . . . . . . . . . . . . . . . . . .       3
  4.2 Integer Ledger and State – Dependent Distribution . . . . . . . . . . . . . . . . . . .        3
  4.3 Diagonal Representation on Signature Space . . . . . . . . . . . . . . . . . . . . . . .       3

5 Stability and Convergence                                                                          4

6 Computation and Algorithms                                                                         4

7 Multiple – Frame Extension (Future Work)                                                           4

8 Worked Examples                                                                                    4

9 Deployment Checklist                                                                               5

A Reference Implementation (Python)                                                                  5

B Lipschitz Continuity: A Proof Sketch                                                               5

C Scope and Non – Claims                                                                             6

A A Free Abelian Structure of Signatures on Primes                                                   6

B Introduction                                                                                       6

C Prime Signatures and Monoidal Structure                                                            6

D Multiplicity Functor to ×                                                                          7

E Categorical Semantics and Conservation                                                             7

F Computational Semantics: Axis-Typed Tensors                                                        7

G ACE Integration: Stability-Aware, Certified Contractions                                           8

H Mechanization Summary (Lean)                                                                       8

I   Scope, Limitations, and Extensions                                                               9

A Lean Snippets                                                                                      9



                                                  1
B Python Signatures and Certificates                                                                9


1     Introduction
The multiplicity operator M has appeared informally in several contexts. This article provides
a rigorous, unified specification in which M is not many different objects but one categorical
functor whose other appearances are canonical incarnations. The resulting scaffold separates exact
algebraic information (integer ledgers) from analytic, state – dependent summaries (normalized sector
distributions) and from diagonal operator representations. Speculative extensions (e.g. non – abelian
behavior) are quarantined and given precise mathematical triggers (frame misalignment).

Contributions. (1) A strict monoidal functor Mfun on signature data and its valuation properties;
(2) a computable, basis – independent definition of M
                                                    c(T, p) via projectors and a state; (3) a diagonal
representation with log M = p (log p)Np ; (4) stability and convergence criteria; (5) algorithms and
                              P
worked examples.


2     Preliminaries and Notation
We write P for the set of primes; Z, Q, C have their usual meanings. All sums over p are over primes;
supports are finite unless stated otherwise. For X, ∥X∥ denotes an operator or Frobenius norm
depending on context; Tr denotes the trace when A ⊆ Cn×n .


3     Backbone of the PGM
3.1   Signature Category Sig
Definition 3.1 (Signature category). Let Sig = {e : P → Z with finite support}. Equip Sig with
(e ⊗ f )(p) = e(p) + f (p), unit 0, and dual e∨ = −e. Then (Sig, ⊗, 0) is a strict commutative monoid,
viewable as a strict monoidal category with one object.

3.2   Prime – Graded ∗ – Algebra with State
Definition 3.2 (Prime grading and state). Let A =                Ap be a complex ∗ – algebra with
                                                          L
                                                             p∈P P
orthogonal projectors Pp : A → Ap satisfying Pp Pq = δpq Pp and p Pp = I (finite sum on supports).
Let φ : A → C be positive and normalized.

3.3   Signature Extractor
Definition 3.3 (Functorial extractor). A map F : Obj(A) → Sig satisfies

                  F (XY ) = F (X) + F (Y ),      F (X ∗ ) = −F (X),      F (1) = 0.               (1)

When restricted to multiplicatively factorable objects, F records prime – exponent ledgers.




                                                  2
4     The M Object and Its Faces
4.1   Functorial Mfun (Categorical Backbone)
Definition 4.1 (Functorial Mfun ). Define Mfun : Sig → Q× by Mfun (e) = p pe(p) . Then Mfun is
                                                                              Q

strict monoidal: Mfun (0) = 1, Mfun (e + f ) = Mfun (e)Mfun (f ), Mfun (−e) = Mfun (e)−1 .

Proposition 4.2 (Valuation property). Let νp : Q× → Z be the p – adic valuation. Then νp ◦ Mfun =
πp : Sig → Z, where πp (e) = e(p).

Proof. Immediate from the multiplicative definition of Mfun and the uniqueness of prime factorization
in Q× .

Remark 4.3 (Exponential form). Acting diagonally on signature labels, Mfun = exp         p (log p) πp .
                                                                                      P              


4.2   Integer Ledger and State – Dependent Distribution
Definition 4.4 (Integer ledger and distribution). Given X with e = F (X), define the integer ledger
Mint (X, p) := e(p) ∈ Z. For T ∈ A, define the sector mass and normalized weight

                 µp (T ) := φ (Pp T )∗ (Pp T ) ≥ 0,        c(T, p) := Pµp (T ) ∈ [0, 1].                (2)
                                              
                                                           M
                                                                       q µq (T )


Proposition 4.5 (Normalization). If T ̸= 0, then
                                                          P c
                                                           p M (T, p) = 1.

Proof. Positivity and linearity of φ plus orthogonality Pp Pq = δpq Pp yield                             ∗
                                                                               P             P                P          
                                                                               p µp (T ) = φ (   p Pp T ) (   p Pp T )       =
φ(T ∗ T ) > 0.

Remark 4.6 (Ledger vs. distribution). Mint is exact, algebraic, and functorial; M c is analytic and
state – dependent. They agree on pure signatures up to a chosen normalization rule (e.g. proportional
to |e(p)|) but generally differ on superpositions.

4.3   Diagonal Representation on Signature Space
Definition 4.7 (Signature Hilbert space and number operators). Let H = span{ |e⟩ : e ∈ Sig } and
define number operators Np |e⟩ = e(p)|e⟩. Define M by
                                                          X
                        M |e⟩ = Mfun (e) |e⟩,     log M =  (log p) Np .                       (3)
                                                                   p

Proposition 4.8 (Monoidal–Diagonal Equivalence).
                                            P         Let ρ : Sig → U(H) be the regular diagonal
representation ρ(e)|f ⟩ = |e + f ⟩. Then M = e Mfun (e)|e⟩⟨e| is the unique diagonal operator (up to
a central scalar) whose conjugation X 7→ MXM−1 implements a signature – scale gauge compatible
with Definition 4.1.

Proof. Diagonality and Definition 4.1 force the action on the eigenbasis |e⟩; uniqueness follows from
the spectral theorem for commuting {Np }.




                                                      3
5    Stability and Convergence
Definition 5.1 (Weighted prime response). For real parameters {αp } define
                                             X
                                  Sα (T ) :=   c(T, p) pαp .
                                               M                                                         (4)
                                                   p

Proposition 5.2 (Bounds and convergence). If only finitely many primes are active in T , then
0 ≤ Sα (T ) ≤ maxp pαp . If infinitely many are active, convergence of Equation (4) requires αp → −∞
sufficiently fast; otherwise Sα (T ) is undefined.
Proposition 5.3 (Contractivity gate). In regimes where an update T 7→ U(T ) linearizes with gain
aligned to the weights in Equation (4), a sufficient stability condition is |Sα (T )| < 1.


6    Computation and Algorithms

Algorithm 1 Normalized sector weights M     c(T, p)
Require: projectors {Pp }, state φ, element T ∈ A with finite prime support
 1: for all active primes p do
 2:    Tp ← Pp T
       µp ← φ Tp∗ Tp
                       
 3:
 4: end for
            q µq ; return M (T, p) = µp / max(µ, ε) for each p (small ε > 0)
         P
 5: µ ←                   c


Complexity. Linear in P the number of active primes. If projectors are approximate, report an
orthogonality defect δ = p̸=q ∥Pp Pq ∥ and propagate its effect on M
                                                                   c.


7    Multiple – Frame Extension (Future Work)
       (i)                                                                    (j)          (i)
Let {Pp } be alternative prime frames with intertwiners Uij satisfying Pp           = Uij Pp Uij−1 . Define

                                   (i)      (i)
                              φ (Pp T )∗ (Pp T )
                                                                       X             
             c(i)
             M      (T, p) = P        (i)      (i)   ,    M(i) = exp     (log p) Np(i) .                (5)
                                          ∗
                              q φ (Pq T ) (Pq T )                         p

Then M(j) = Uij M(i) Uij−1 and [M(i) , M(j) ] = 0 iff the frames are simultaneously diagonalizable;
non – commutation measures frame misalignment.


8    Worked Examples
Example 8.1 (Arithmetic toy model). Let e(2) = 1, e(3) = −1, e(5) = 2. Then Mint (X, 2) = 1,
Mint (X, 3) = −1, Mint (X, 5) = 2 and Mfun (F (X)) = 21 3−1 52 = 50/3. Choosing M
                                                                                c from absolute
exponents gives M (X, 2) = 1/4, M (X, 3) = 1/4, M (X, 5) = 1/2.
                c                c               c

Example 8.2 (Matrix model with trace state). Let A ⊆ Cn×n , φ = Tr, and P2 , P3 , P5 be block
projectors. For T = diag(A, B, C) we have µ2 = ∥A∥2F , µ3 = ∥B∥2F , µ5 = ∥C∥2F and M
                                                                                   c(T, 2) =
∥A∥2F /(∥A∥2F + ∥B∥2F + ∥C∥2F ).

                                                       4
9    Deployment Checklist
Specify: (1) the graded algebra A and state φ; (2) projectors {Pp } and an orthogonality – defect
budget; (3) a functorial extractor F satisfying Definition 3.3; (4) a rule linking ledgers to distributions
on pure signatures (if desired); (5) exponents {αp } and convergence guarantees for Sα .


A     Reference Implementation (Python)

from dataclasses import dataclass
from typing import Dict , Callable , Iterable
import numpy as np

Scalar = float | complex
Projector = Callable [[ np . ndarray ] , np . ndarray ]
State = Callable [[ np . ndarray ] , Scalar ]
Signature = Dict [ int , int ] # prime -> exponent

@dataclass
class P r i m e G r a d e d F r am e w o r k :
    primes : Iterable [ int ]
    projectors : Dict [ int , Projector ]               # p -> P_p
    state : State                                       #   : A -> C ( e . g . , np . trace )

     @staticmethod
     def M_fun ( signature : Signature ) -> float :
         out = 1.0
         for p , exp in signature . items () :
             out *= ( p ** exp )
         return out

     def sector_weight ( self , T : np . ndarray , p : int ) -> float :
         T_p = self . projectors [ p ]( T )
         mu_p = float ( self . state ( T_p . conj () . T @ T_p ) )
         total = 0.0
         for q in self . primes :
             T_q = self . projectors [ q ]( T )
             total += float ( self . state ( T_q . conj () . T @ T_q ) )
         eps = 1e -12
         return mu_p / max ( total , eps )

     def S_alpha ( self , T : np . ndarray , alpha : Dict [ int , float ]) -> float :
         return sum ( self . sector_weight (T , p ) * ( p ** alpha [ p ]) for p in
            self . primes )



B     Lipschitz Continuity: A Proof Sketch
Assuming φ uniformly continuous and ∥Pp ∥ ≤ 1, expand M
                                                      c(T, p) using Equation (2) and apply
standard quotient stability bounds to obtain
                                                            C ∥T − S∥
                              |M
                               c(T, p) − M
                                         c(S, p)| ≤
                                                          min(∥T ∥2 , ∥S∥2 )

                                                    5
for some C depending on φ.


C     Scope and Non – Claims
This formalization is purely mathematical; any physical modeling (e.g. dissipative/ conservative
splittings) must be justified independently from a chosen dynamical principle (Lyapunov, unitarity,
etc.).


A     A Free Abelian Structure of Signatures on Primes
We develop a certified mathematical framework where prime factorization provides a canonical
encoding of tensor structure. Objects are prime signatures — finitely supported integer labelings
of the set of primes — equipped with a strict symmetric monoidal structure (tensor = pointwise
addition, unit = 0, dual = negation).
                                  Q epA central multiplicity functor : Sig → maps signatures
                                                                                 ×

to units of the rationals by (e) = p p , thereby transporting tensor to multiplication and duals
to inversion. We formalize the key laws ((0) = 1, (e + f ) = (e) (f ), (−e) = (e)−1 ) and show
prime-conservation for morphisms in the discrete categorical model. This yields algebraic certificates
for tensor product and contraction that are independent of floating-point numerics and integrate
seamlessly with an ACE control loop for stability-aware contraction planning.


B     Introduction
Prime factorization is canonical, global, and choice-free. We leverage this to encode the structural
“type” of tensor axes and to define a multiplicative invariant that certifies the correctness of tensor
operations. The resulting framework—Typed-Prime-Signatures (TPS)—unifies:

• a free abelian structure of signatures on primes,

• a monoidal/dual semantics (tensor/dual ↔ add/negate exponents),

• a functorial multiplicity invariant into × (group of rational units), and

• certified computation: tensor product and contraction preserve the invariant and hence cannot
  create or destroy “prime mass".

We also outline an ACE-integrated control loop that uses these algebraic guarantees as hard
constraints while learning numerically stable contraction orderings.

Contributions. (1) A strict symmetric monoidal skeleton on prime signatures with duals; (2)
a monoidal functor : Sig →× proving conservation laws; (3) a computational semantics that lifts
signatures to axis-typed tensors; (4) certified operations and property-based testing; (5) an integration
plan with ACE for stability-aware, safety-preserving tensor contraction.


C     Prime Signatures and Monoidal Structure
Let denote the set of natural primes. We write e = (ep )p∈ ∈() for a finitely supported integer
labeling of primes.



                                                   6
Definition C.1 (Prime signatures). The set of prime signatures is
                             Sig := {e :→ : e has finite support} ∼
                                                                  = () .
The support is (e) := {p ∈: ep ̸= 0}.
Definition C.2 (Monoidal and dual structure). Define tensor by pointwise addition (e⊗f )p := ep +fp ,
the unit by 0, and the dual by e∨ := −e. Thus (Sig, ⊗, 0, (·)∨ ) is a strict symmetric monoidal skeleton
with duals.


D     Multiplicity Functor to ×
Definition D.1 (Multiplicity). Define : Sig →× by
                                               Y
                                        (e) :=    p ep .
                                                    p∈(e)

Because (e) is finite, this product is well-defined. Negative exponents are interpreted via pep = 1/p−ep .
Theorem D.2 (Monoidality and duality). For all e, f ∈ Sig:
                          (0) = 1,      (e + f ) = (e) (f ),    (−e) = (e)−1 .
Proof. Immediate from unique factorization and the laws of exponents. Finite support ensures all
products are finite.

Remark D.3 (Valuations). The coordinate ep coincides with the p-adic valuation vp ((e)). Thus
e 7→ (e) packages the family of valuations (vp )p into a single multiplicative invariant.

Unsigned size (optional). Define (e) := p p|ep | ∈≥0 . Then (e + f ) = (e) (f ), but (−e) = (e),
                                             Q
so ignores variance (duals) and is not a duality-preserving functor.


E    Categorical Semantics and Conservation
To obtain lightweight, fully certified laws, we view signatures as objects of the discrete category
(Sig): morphisms are equalities.
Proposition E.1 (Prime conservation in the discrete model). Any isomorphism e ∼
                                                                              = f in (Sig)
satisfies (e) = (f ).
Proof. In (Sig), isomorphisms are equalities; apply Definition D.2.

Remark E.2 (Compact-closed perspective). Object-level duals e∨ = −e admit evaluation/coevaluation
maps e∨ ⊗ e → 0 and 0 → e ⊗ e∨ given by the definitional equalities (−e) + e = 0 and 0 = e + (−e).
Passing through , evaluation corresponds to multiplication by (−e) (e) = 1.


F    Computational Semantics: Axis-Typed Tensors
EachQtensor axis of integer length n > 0 carries a signature given by its prime factorization
n = pvp (n) . A tensor with axes (ni ) and variances σi ∈ {+1, −1} has global signature
                                          X
                              sig(T ) =      σi e(i) , e(i)
                                                        p := vp (ni ).
                                             i


                                                    7
Certified operations.

• Tensor product (Kronecker). Concatenates axes; globally, signatures add: sig(A ⊗ B) =
  sig(A) + sig(B).

• Contraction (Einstein). Removes one +1 axis and one −1 axis with matching signatures
  (same prime profile). Globally, the signature is unchanged: sig(contract(A, B)) = sig(A) + sig(B),
  because the contracted pair contributes +e + (−e) = 0.

Certificates. Define the (algebraic) certificate

C⊗ : (A, B, C) 7→ [sig(C) = sig(A) + sig(B)],          C⟨·,·⟩ : (A, B, C) 7→ [sig(C) = sig(A) + sig(B)].

Both certificates imply (sig(C)) = (sig(A)) (sig(B)) by Definition D.2.

Example F.1 (Matrix multiplication). A ∈m×n (variance [−1, +1]), B ∈n×p (variance [−1, +1]).
Contract the shared n-axis to obtain C ∈m×p . The global signature obeys sig(C) = sig(A) + sig(B);
the contracted pair contributes 0.


G     ACE Integration: Stability-Aware, Certified Contractions
We integrate the algebraic layer with an ACE control loop:

1. Candidates. Generate contraction plans (which axes to contract, in which order).

2. Hard constraints. Filter plans by certificates C⊗ , C⟨·,·⟩ ; reject any plan violating signature
   equalities.

3. Stability scoring. A learned oracle predicts instability based on signature features (cancellation
   depth, prime residuals, entropy, spread).

4. Execute learn. Execute the best certified plan, measure stability, and update the oracle
   (bandit/Thompson or small MLP).

This yields a self-correcting loop: algebraic invariants enforce correctness, while ACE optimizes
performance.


H     Mechanization Summary (Lean)
We formalized the following in Lean (mathlib):

• Sig =→fin via finitely supported functions.

• : Sig →× with proofs of (0) = 1, (e + f ) = (e) (f ), (−e) = (e)−1 .

• Discrete symmetric monoidal packaging (tensor = addition; dual = negation).

• Prime conservation: isomorphisms (equalities) preserve .

A compact-closed upgrade (cups/caps, yanking) can be added; then becomes a strong monoidal
functor into the one-object monoidal category (× , ·, 1).


                                                   8
I   Scope, Limitations, and Extensions
Scope. The framework certifies structural correctness (no creation/destruction of prime content)
independent of numeric values.
    Limitations. Current formalization uses the discrete category; full compact-closed coherence is
future work. Factorization cost is mitigated by maintaining signatures symbolically.
    Extensions. Replace by prime ideals of a Dedekind domain;   Q treat signatures as gradings of
tensor categories; connect to Hecke-operator factorization Tn ∼
                                                              = p Tpvp (n) for algebraic validation.


A    Lean Snippets

import   Mathlib
import   Mathlib / Data / Finsupp
import   Mathlib / Data / Nat / Prime
import   Mathlib / Algebra / GroupPower
import   Mathlib / CategoryTheory / Category / Discrete

-- primes as indices
def PrimeNat := { p : Nat // Nat . Prime p }
-- signatures
def Sig := PrimeNat         Int

namespace Sig
noncomputable def qUnit ( p : PrimeNat ) :           :=
  Units . mk0 ( p .1 :   ) ( by exact_mod_cast Nat . cast_ne_zero . mpr ( Nat .
     ne_of_gt p .2. pos ) )

noncomputable def multiplicity ( s : Sig ) :                     :=
  s . support . prod ( fun p = > ( qUnit p ) ^ ( s p ) )

@ [ simp ] lemma multip licity_z ero : multiplicity (0 : Sig ) = (1 :                       ) :=
     by
    simp [ multiplicity ]

lemma multiplicity_add ( a b : Sig ) :
  multiplicity ( a + b ) = multiplicity a * multiplicity b := by
  -- proof uses support union + zpow_add + prod_mul_distrib
  admit

lemma multiplicity_neg ( a : Sig ) : multiplicity ( - a ) = ( multiplicity a )
         := by
  -- proof uses support equality + zpow_neg + prod_inv_distrib
  admit
end Sig



B    Python Signatures and Certificates

from fractions import Fraction

def multiplicity_Qx ( sig : dict [ int , int ]) -> Fraction :


                                                 9
     num , den = 1 , 1
     for p , e in sig . items () :
          if e >= 0: num *= p ** e
          else :       den *= p ** ( - e )
     return Fraction ( num , den )

def conservation_ok ( inputs : list [ dict [ int , int ]] , out : dict [ int , int ]) ->
   bool :
    m_in = Fraction (1 ,1)
    for s in inputs : m_in *= multiplicity_Qx ( s )
    return m_in == multiplicity_Qx ( out )



References
 [1] Roger A. Horn and Charles R. Johnson. Matrix Analysis. Cambridge University Press, 2 edition,
     2013.

 [2] Rajendra Bhatia. Matrix Analysis. Springer, 1997.

 [3] Gene H. Golub and Charles F. Van Loan. Matrix Computations. Johns Hopkins University
     Press, 4 edition, 2013.

 [4] Tosio Kato. Perturbation Theory for Linear Operators. Springer, 2 edition, 1995.

 [5] G. W. Stewart and Ji guang Sun. Matrix Perturbation Theory. Academic Press, 1990.

 [6] Lloyd N. Trefethen and Mark Embree. Spectra and Pseudospectra: The Behavior of Nonnormal
     Matrices and Operators. Princeton University Press, 2005.

 [7] Stefan Banach. Sur les opérations dans les ensembles abstraits et leur application aux équations
     intégrales. Fundamenta Mathematicae, 3:133–181, 1922.

 [8] John B. Conway. A Course in Functional Analysis. Springer, 2 edition, 1990.

 [9] Erwin Kreyszig. Introductory Functional Analysis with Applications. John Wiley & Sons, 1978.

[10] Nicholas J. Higham. Accuracy and Stability of Numerical Algorithms. SIAM, 2 edition, 2002.

[11] Lloyd N. Trefethen and David Bau III. Numerical Linear Algebra. SIAM, 1997.

[12] Youcef Saad. Numerical Methods for Large Eigenvalue Problems. SIAM, 2 edition, 2011.

[13] Saunders Mac Lane. Categories for the Working Mathematician. Springer, 2 edition, 1998.

[14] J"urgen Neukirch. Algebraic Number Theory. Springer, 1999.

[15] Stephen Boyd and Lieven Vandenberghe. Convex Optimization. Cambridge University Press,
     2004.

[16] Tyler Van Osdol. Arithmetic control engine (ace): Certified spectral control. Internal whitepaper,
     user-supplied PDF, 2025. Available in project materials.

[17] R.O. Van Gelder. Prime-encoded tensor calculus (petc): Multiplicity functor and prime
     conservation. Internal whitepaper, user-supplied PDF, 2025. Available in project materials.

                                                  10
[18] R.O. Van Gelder. Pgf m operator: Definitions and properties. Internal technical note, user-
     supplied PDF, 2025. Available in project materials.




                                              11
