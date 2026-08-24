              Multiplicity Knot Theory v3.0:
    Prime-Weighted Braid Invariants and a Cryptographic
                 Commitment Prototype
                                 Helix AI Innovations
                                          &
                                   Citizen Gardens
                             The Foundation of Multiplicity

                                        April 1, 2026


                                           Abstract
    Multiplicity Theory aims to construct braid invariants for knots and links whose structure is
driven by prime-number arithmetic rather than by arbitrary quantum-group parameter choices.
Building on a prior v2.1 note introducing a prime-weighted protection factor P (K) for “consti-
tutional lattices” [Innovations(2026)], we present a v3.0 reframing that:
   • defines a prime-colored braid category and a strand-dependent R-matrix Rp,q derived from
     standard Uq (sl2 ) data,
   • introduces a prime-weighted functional Z(K) via a modified trace against strand-local
     weights Op Op† ,
   • constructs a protection functional P (K; X) based on truncated prime averages c0 (X) and
     z(X) treated as conjectural limits, and
   • sketches a multiplicity-based commitment (MBC) scheme whose binding property is heuris-
     tically tied to the injectivity and stability of the invariant pipeline.
   We give precise conditional statements, explicitly record the necessary conjectures, and pro-
vide a small-scale Python prototype suitable for experimental validation.




                                               1
Contents
1 Executive Summary                                                                                     3

2 Prime-Colored Braid Category and Local Data                                                          4
  2.1 Prime-colored objects and morphisms . . . . . . . . . . . . . . . . . . . . . . . . . .          4
  2.2 Prime-indexed local unitaries Op . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       4
  2.3 Strand-dependent R-matrix Rp,q . . . . . . . . . . . . . . . . . . . . . . . . . . . . .         4

3 Yang–Baxter Structure and Restricted Markov Invariance                                                5
  3.1 Projective YBE conjecture . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       5
  3.2 Prime-weighted functional Z(K) . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          5
  3.3 Canonical prime assignment and restricted moves . . . . . . . . . . . . . . . . . . . .           5

4 Prime-Harmonic Couplings and the Constant c0                                                         6
  4.1 Truncated prime averages . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       6
  4.2 Finite-X self-consistency for c0 (X) . . . . . . . . . . . . . . . . . . . . . . . . . . . .     6

5 Prime-Distribution Exponent z                                                                        7
  5.1 Truncated prime-average for z(X) . . . . . . . . . . . . . . . . . . . . . . . . . . . .         7

6 Protection Functional and Conditional Main Result                                                     7
  6.1 Finite-X protection functional . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        7
  6.2 Conditional prime-weighted invariant . . . . . . . . . . . . . . . . . . . . . . . . . . .        7

7 Multiplicity-Based Commitment (MBC) Scheme                                                            8
  7.1 Syntax . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    8
  7.2 Setup . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     8
  7.3 Commit . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      8
  7.4 Open . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    9
  7.5 Binding game . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      9

8 Prototype Implementation and Experimental Plan                                                        9
  8.1 Prototype parameters . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        9
  8.2 Representative code snippet . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       9

9 Conclusion                                                                                           12




                                                   2
1      Executive Summary
The original v2.1 document claimed a parameter-free topological invariant P (K), built by conju-
gating a standard Uq (sl2 ) R-matrix by prime-indexed operators Op and combining the resulting
braid invariant Z(K) with number-theoretically derived constants c0 = ln 10 and z = 1/(2 cos 1)
[Innovations(2026)]. A subsequent self-critique identified several serious issues: an ill-defined mod-
ified Markov trace, incomplete or flawed derivations of the constants, and a lack of a canonical
prime assignment to strands.
    In this v3.0 program document we:

    (i) Restrict attention to a prime-colored braid category, with a strand-dependent R-matrix

                                     Rp,q := (Op ⊗ Oq )Rstd (Op† ⊗ Oq† )

       built from standard Uq (sl2 ) data at q = eiπ/3 and prime-indexed unitaries Op ∈ SU (2)
       [Innovations(2026), Sec. 2.1–2.3].

 (ii) Define a prime-weighted functional
                                                                   n
                                                                   O
                                                                         (Opj Op†j ),
                                               
                            Z(K) := Tr ρ(βK )WK ,          WK =
                                                                   j=1

       where βK is a canonical prime-colored braid representative of K and pj is the prime label of
       strand j.

(iii) Introduce truncated prime-averaged constants
                                             −1                    2
                              P                          P
                            1   p≤X (p ln p)              p≤X 2 sin (ln p)/(p ln p)
                  c0 (X) =      P        −2
                                                , z(X) =    P              −1
                                                                                    ,
                           2π     p≤X p                       p≤X (p ln p)

       and define a finite-X protection functional

                                 P (K; X) := exp c0 (X)c(K) |Z(K)|z(X) .
                                                           


       The large-X limits c0 and z are treated as conjectural, supported by numerics rather than
       proved identities [Innovations(2026), Sec. 3–4].

(iv) Formulate a two-phase multiplicity-based commitment (MBC) scheme and a clear security
     model, in which binding is heuristic and tied to three assumption clusters (algebraic invariants,
     encoding/canonicalization, and hash/invariant collisions).

 (v) Provide a concrete 4-strand prototype using primes (2, 3, 5, 7) and Python/NumPy code to
     compute Z(K) and P (K; X) and to run small-scale collision and stability experiments.

   The result is not yet a full mathematical theory, but it is a coherent, testable research program
that turns the previous overclaims into explicit conjectures and experimentally accessible questions.




                                                     3
2     Prime-Colored Braid Category and Local Data
2.1   Prime-colored objects and morphisms
Fix an infinite ordered list of primes (p1 , p2 , p3 , . . . ). Objects of our category are finite ordered
tuples
                                         p = (pi1 , . . . , pin ),
which we interpret as colorings of n strands by primes. Morphisms are braids on n strands, with
the j-th strand colored by pij . Composition is braid concatenation; tensor product is given by
juxtaposing colored sequences and braids.

2.2   Prime-indexed local unitaries Op
For each prime p we define a unitary Op ∈ SU (2) by
                                                                  
                                         Op = exp i ln p (n̂p · σ) ,                                  (1)

where σ = (σx , σy , σz ) are the Pauli matrices and
                                                        
                                             sin(ln p)
                                     1                             p
                             n̂p =      cos(ln p) ,        Np =    1 + p−1 .                        (2)
                                                  
                                     Np
                                          p−1/2

The choice of n̂p is a modeling assumption (unit vector with nontrivial dependence on ln p and
p−1/2 ); no deeper number-theoretic significance is currently claimed beyond this structure. A
related construction appears in [Innovations(2026), Eq. (1)–(2)].

2.3   Strand-dependent R-matrix Rp,q
Let Rstd denote the standard Uq (sl2 ) R-matrix at q = eiπ/3 :
                                 1/2                     
                                  q     0      0      0
                                 0   q 1/2 −q −1/2   0 
                         Rstd = 
                                 0
                                                          ,             q = eiπ/3 ,                  (3)
                                        1      0      0 
                                    0   0      0    q 1/2

as in [Innovations(2026), Eq. (4)].
    For a crossing of two strands colored by primes p and q we define

                                     Rp,q := (Op ⊗ Oq ) Rstd (Op† ⊗ Oq† ).                            (4)

Given a prime-colored braid β on n strands with color sequence (pi1 , . . . , pin ), we obtain a repre-
sentation
                                     ρ(β) ∈ End (C2 )⊗n
                                                        

by assigning Rpij ,pij+1 (or its inverse) to each elementary crossing of strands j and j + 1. This
matches the strand-dependent construction sketched in [Innovations(2026), Sec. 2.2], but now with
explicit tensor indices and fixed prime colors.

                                                         4
3        Yang–Baxter Structure and Restricted Markov Invariance
3.1        Projective YBE conjecture
The standard matrix Rstd satisfies the Yang–Baxter equation (YBE). After conjugation by Op ⊗Oq ,
the resulting Rp,q is no longer guaranteed to satisfy YBE in a straightforward way, because different
strands carry different Op factors [Innovations(2026), Sec. 2.3]. We therefore formulate a projective
YBE condition.
    For any triple of primes (p, q, r) define

                                Lp,q,r := Rp,q Rp,r Rq,r ,        Rp,q,r := Rq,r Rp,r Rp,q .

Conjecture 2.1 (Projective prime-labeled YBE). For all primes p, q, r there exists a phase
λp,q,r ∈ U (1) such that
                                 Lp,q,r = λp,q,r Rp,q,r .
   Empirically, the v2.1 note reports YBE residuals below 10−15 for triples in a modest prime
range [Innovations(2026), Sec. 2.3, Remark 2.1], but no proof is given. In this v3.0 framework,
Conjecture 2.1 is taken as a central algebraic assumption.
   Under Conjecture 2.1, ρ defines a projective braid group representation in the prime-colored
category.

3.2        Prime-weighted functional Z(K)
Let βK be a fixed prime-colored braid representative of a knot or link K on n strands, with color
sequence (pi1 , . . . , pin ). We define the strand-weight operator
                                                         n
                                                         O
                                                                 Opij Op†i .
                                                                          
                                                WK :=                                                              (5)
                                                                         j
                                                         j=1

The prime-weighted functional is then
                                                                 
                                              Z(K) := Tr ρ(βK )WK .                                                (6)

This makes precise the “modified Markov trace” heuristic of [Innovations(2026), Eq. (6)], where a
product of Op Op† factors was written but not fully tensorialized.
   We do not claim that Z is a Markov trace in the sense of Ocneanu; instead we seek invariance
under a restricted set of moves compatible with a canonical prime assignment.

3.3        Canonical prime assignment and restricted moves
To ensure well-definedness we fix:

        • A deterministic procedure Canon that maps an initial diagram or braid for K to a braid word
          βK on n strands in a canonical form.1

        • A prime assignment rule: strand j of βK is labeled by prime pj for j = 1, . . . , n.
    1
        For the 4-strand prototype in Section 8, we take Canon to be the identity and work directly with the encoding.


                                                             5
     Allowed moves are:

     • Colored conjugations that do not permute strand endpoints (indices 1, . . . , n are fixed), so
       the prime labels remain aligned and cyclicity of trace preserves Z(K).

     • Terminal stabilization/destabilization that adds/removes a last strand with the next unused
       prime pn+1 , with normalization Tr(Opn+1 Op†n+1 ) = 2 to preserve Z(K) under paired moves,
       echoing the sketch of [Innovations(2026), Thm. 2.1].

Assumption A2 (Restricted Markov invariance). For any two diagrams of the same knot
or link K, the canonicalization and prime-assignment pipeline yields braids whose associated Z(K)
are equal up to numerical tolerance.


4     Prime-Harmonic Couplings and the Constant c0
4.1     Truncated prime averages
Let µp := 1/(p ln p) be the usual “prime-counting” weight [Innovations(2026), Sec. 1]. For a finite
cutoff X > 0 define the normalized truncated average
                                               P
                                                 p≤X f (p) µp
                                    ⟨f (p)⟩X := P             .
                                                    p≤X µp

In v2.1, a self-consistency condition for a prime-harmonic coupling Lp = c0 ln(p)/p and a frequency
factor ωp = 2π/ ln p was claimed to fix c0 = ln 10, but the derivation as written is mathematically
inconsistent when extended to all primes [Innovations(2026), Sec. 3.3]. We therefore work with a
finite-X definition.

4.2     Finite-X self-consistency for c0 (X)
For each cutoff X define c0 (X) by

                                                                 ln p         2π
                             Lp ωp X = 1,     Lp = c0 (X)             , ωp =      .               (7)
                                                                  p          ln p
This simplifies to
                                                            −2
                                                  P
                                                    p≤X p
                                    c0 (X) 2π P                  −1
                                                                      = 1,
                                                  p≤X (p ln p)
so
                                                                      −1
                                                   P
                                               1       p≤X (p ln p)
                                     c0 (X) =          P        −2
                                                                           .                      (8)
                                              2π         p≤X p

Conjecture 3.1 (Prime-harmonic coupling limit). The limit c0 = limX→∞ c0 (X) exists and
equals ln 10.
   In v2.1, a numerical fit c0 ≈ ln 10 with small residuals is reported [Innovations(2026), Sec. 3.3];
here we recast that observation as a conjectural limiting value.


                                                      6
5     Prime-Distribution Exponent z
5.1    Truncated prime-average for z(X)
Using the same weights µp , define
                                                                   2
                                                      P
                                            2             p≤X 2 sin (ln p)/(p ln p)
                           z(X) := 2 sin (ln p) X =         P              −1
                                                                                    .              (9)
                                                              p≤X (p ln p)

The v2.1 note numerically observes z ≈ 0.9248 for p ≤ 106 , matching 1/(2 cos 1) ≈ 0.9254 to within
about 0.06% [Innovations(2026), Sec. 4].
Conjecture 4.1 (Prime-zeta exponent). The limit z := limX→∞ z(X) exists and equals
1/(2 cos 1).
    Again, this is explicitly conjectural: the exact evaluation of the associated prime-zeta-like inte-
gral remains open [Innovations(2026), Remark 4.1].


6     Protection Functional and Conditional Main Result
6.1    Finite-X protection functional
Given a knot or link K with canonical prime-colored braid βK and corresponding Z(K), define the
finite-X protection functional

                             P (K; X) := exp c0 (X)c(K) |Z(K)|z(X) ,
                                                        
                                                                                           (10)

where c(K) is the crossing number of a chosen canonical diagram of K. This mirrors the structure
of [Innovations(2026), Eq. (7)], but with c0 and z now explicitly cutoff-dependent and conjectural
in the limit.

6.2    Conditional prime-weighted invariant
We can now state a main conditional theorem, in the style of Theorem 1.1 from our earlier draft.
Theorem 6.1 (Conditional prime-weighted protection invariant). Fix:

    • the ordered prime list (p1 , p2 , . . . ),

    • the data (Op ) and (Rp,q ) as in (1)–(4),

    • a deterministic canonicalization procedure Canon and prime assignment rule as in Section 3.2,

    • a finite set of cutoffs {X1 , . . . , Xt }.

    Assume:

(C1) (Projective YBE) Conjecture 2.1 holds for all primes p, q, r.

(C2) (Restricted invariance) Z(K) is invariant (up to numerical tolerance) under the moves
     used by Canon on equivalent diagrams of K (Assumption A2).


                                                      7
(C3) (Convergence) The limits c0 = limX→∞ c0 (X), z = limX→∞ z(X) exist and are finite
     (Conjectures 3.1–4.1).
    Then:
(1) For each finite Xi , the quantity P (K; Xi ) in (10) is a well-defined numerical invariant of K
    under isotopy, relative to the fixed prime list and canonicalization.
(2) The limit P (K) = limX→∞ P (K; X) exists and defines a conjectural prime-weighted protection
    invariant of K.


7     Multiplicity-Based Commitment (MBC) Scheme
We now describe a non-interacting commitment scheme MBC = (Setup, Commit, Open) built on top
of P (K; X). The goal is not to claim production-ready security but to align cryptographic binding
with the injectivity and stability of the v3.0 invariant pipeline.

7.1    Syntax
    • Setup(1λ ) → pp: generates public parameters pp.
    • Commit(pp, m) → (C, aux): on input message m, outputs a commitment C and opening data
      aux.
    • Open(pp, C, m, aux) → {0, 1}: verifies a purported opening and returns 1 for accept, 0 other-
      wise.

7.2    Setup
Setup(1λ ):
    1. Fix a global prime list (pj )j , and the operators Op , Rp,q , and cutoffs {Xi } as in previous
       sections.
    2. Fix an encoding Enc : {0, 1}ℓ → {initial diagrams/braids} and canonicalization Canon.
    3. Fix a collision-resistant hash function H.
    Set                                                                              
                          pp := (pj )j , (Op )p , (Rp,q )p,q , {Xi }i , H, Enc, Canon .

7.3    Commit
Commit(pp, m):
    1. Compute Dm := Enc(m) and (βm , nm ) := Canon(Dm ).
    2. Assign primes p1 , . . . , pnm to strands, construct Z(Km ) and P (Km ; Xi ) for each cutoff.
    3. Serialize βm as σm and set Tm := H(σm ∥ m).
    Output                                              
                              Cm := Tm , {P (Km ; Xi )}i ,         auxm := σm .

                                                       8
7.4    Open
Open(pp, C, m, aux) recomputes the canonical braid from m, verifies Tm and the invariant vector
{P (Km ; Xi )} against the published C, and returns 1 if all checks pass within tolerance, 0 otherwise.

7.5    Binding game
We formalize the binding game BindGameMBC (A, λ) where an adversary A gets pp, outputs (C, m, aux, m′ , aux′ ),
and wins if m ̸= m′ and both openings verify. The binding advantage is

                         Advbind
                                                                    
                             MBC (A, λ) = Pr BindGameMBC (A, λ) = 1 .

    Under assumptions about hash collision-resistance, injectivity of the encoding/canonicalization
map m 7→ σm , and the absence of “cheap” invariant collisions P (Km ; Xi ) = P (Km′ ; Xi ) for m ̸=
m′ , any double opening would either break the hash function or witness a nontrivial collision
in the invariant pipeline (or a failure of the invariant’s stability), making the binding advantage
heuristically negligible.
    A more detailed security model and assumption set (Assumptions A–C) can be stated following
the structure in the chat-derived draft.


8     Prototype Implementation and Experimental Plan
We now describe a concrete 4-strand prototype with primes (2, 3, 5, 7) and a 12-bit message encod-
ing, and present a Python-style pseudocode snippet that instantiates the v3.0 constructions. This
mirrors the structure and constants of the v2.1 note but in a controlled, small-parameter setting
[Innovations(2026), Table 2].

8.1    Prototype parameters
    • Strand count: n = 4 with primes (2, 3, 5, 7).

    • Base Rstd and Op as in (3)–(1).

    • Cutoffs: e.g. X ∈ {103 , 104 } for c0 (X) and z(X).

    • Encoding Enc: 12-bit messages split into four 3-bit blocks; each block m(j) selects a small
      braid gadget on 4 strands and an exponent. The full braid is the concatenation of four such
      gadgets.

8.2    Representative code snippet
The following excerpt shows the core of the prototype: construction of Op , Rp,q , the braid repre-
sentation ρ(β) on 4 strands, and the computation of Z(K) and P (K; X).

                        Listing 1: Core v3.0 prototype code (4-strand case)
import numpy as np
import cmath
from math import log , sqrt , sin , cos
import sympy as sp


                                                  9
DTYPE = np . complex128

def kron (* matrices ) :
    result = matrices [0]
    for M in matrices [1:]:
         result = np . kron ( result , M )
    return result

# Pauli   matrices
sigma_x   = np . array ([[0 , 1] , [1 , 0]] , dtype = DTYPE )
sigma_y   = np . array ([[0 , -1 j ] , [1 j , 0]] , dtype = DTYPE )
sigma_z   = np . array ([[1 , 0] , [0 , -1]] , dtype = DTYPE )

def n_hat_p ( p ) :
    ln_p = log ( p )
    v = np . array ([ sin ( ln_p ) , cos ( ln_p ) , p ** -0.5] , dtype = float )
    Np = sqrt (1.0 + 1.0/ p )
    return v / Np

def O_p ( p ) :
    ln_p = log ( p )
    nx , ny , nz = n_hat_p ( p )
    n_dot_sigma = nx * sigma_x + ny * sigma_y + nz * sigma_z
    theta = ln_p
    I2 = np . eye (2 , dtype = DTYPE )
    return np . cos ( theta ) * I2 + 1 j * np . sin ( theta ) * n_dot_sigma

def R_std () :
    q = cmath . exp (1 j * cmath . pi / 3.0)
    q_half = q **0.5
    q_minus_half = q ** -0.5
    R = np . zeros ((4 ,4) , dtype = DTYPE )
    R [0 ,0] = q_half
    R [1 ,1] = q_half
    R [1 ,2] = - q_minus_half
    R [2 ,1] = 1.0
    R [3 ,3] = q_half
    return R

R_STD = R_std ()
PRIMES_4 = (2 , 3 , 5 , 7)

def R_pq (p , q ) :
    Op = O_p ( p ) ; Oq = O_p ( q )
    U = kron ( Op , Oq )
    U_dag = U . conj () . T
    return U @ R_STD @ U_dag

# Precompute generators
I2 = np . eye (2 , dtype = DTYPE )


                                               10
GEN = {}
for j in [1 ,2 ,3]:
    p_left = PRIMES_4 [j -1]
    p_right = PRIMES_4 [ j ]
    R = R_pq ( p_left , p_right )
    R_inv = np . linalg . inv ( R )
    if j == 1:
         op_plus = kron (R , I2 , I2 )
         op_minus = kron ( R_inv , I2 , I2 )
    elif j == 2:
         op_plus = kron ( I2 , R , I2 )
         op_minus = kron ( I2 , R_inv , I2 )
    else :
         op_plus = kron ( I2 , I2 , R )
         op_minus = kron ( I2 , I2 , R_inv )
    GEN [( j , +1) ] = op_plus
    GEN [( j , -1) ] = op_minus

class Braid :
    def __init__ ( self , word ) :
        self . word = list ( word )
    def serialize ( self ) :
        return " ; " . join ( f " { j }:{ s } " for (j , s ) in self . word )

def rho ( braid ) :
    M = np . eye (16 , dtype = DTYPE )
    for (j , s ) in braid . word :
          M = GEN [( j , s ) ] @ M
    return M

def W_K () :
    factors = []
    for p in PRIMES_4 :
         Op = O_p ( p )
         factors . append ( Op @ Op . conj () . T )
    return kron (* factors )

W_GLOBAL = W_K ()

def Z_of_braid ( braid ) :
    return np . trace ( rho ( braid ) @ W_GLOBAL )

def c0_of_X ( X ) :
    primes = list ( sp . primerange (2 , X +1) )
    S1 = sum (1.0/( p **2) for p in primes )
    S2 = sum (1.0/( p * log ( p ) ) for p in primes )
    return (1.0/(2.0* cmath . pi ) ) * ( S2 / S1 )

def z_of_X ( X ) :
    primes = list ( sp . primerange (2 , X +1) )
    num = sum (2.0*( sin ( log ( p ) ) **2) /( p * log ( p ) ) for p in primes )


                                                11
     den = sum (1.0/( p * log ( p ) ) for p in primes )
     return num / den

def P_of_braid_X ( braid , X ) :
    Z = Z_of_braid ( braid )
    cK = len ( braid . word ) # proxy for crossing number
    c0 = c0_of_X ( X )
    zX = z_of_X ( X )
    return np . exp ( c0 * cK ) * ( abs ( Z ) ** zX )

    Using this prototype, one can implement a commitment function by hashing the serialized
braid and the message, and binding it to the vector of P (K; X) values for chosen cutoffs. A small-
scale experimental plan (e.g. enumerating 212 messages, checking for collisions in (β, P ) pairs, and
measuring inversion difficulty) directly probes the assumptions underlying binding and the stability
of the invariants.


9    Conclusion
The v3.0 reframing of Multiplicity Theory:

    • isolates a mathematically meaningful core (prime-colored braid representations and prime-
      weighted functionals),

    • demotes previously overclaimed constants to conjectural limits based on truncated prime
      statistics,

    • introduces a structured, falsifiable cryptographic use case (MBC) whose security hinges on
      the same algebraic and numerical properties,

    • and provides a concrete numerical environment in which the central conjectures can be probed.

    Future work includes: a rigorous analysis of the prime-labeled YBE, analytic control of the
prime-averaged constants c0 and z, a full proof of restricted Markov invariance for Z(K), and explo-
ration of stronger cryptographic constructions leveraging the same multiplicity-theoretic structure.


References
[Apostol(1976)] Tom M. Apostol. Introduction to Analytic Number Theory. Springer, 1976.

[Birman(1974)] Joan S. Birman. Braids, Links, and Mapping Class Groups. Princeton University
    Press, 1974.

[Chari and Pressley(1994)] Vyjayanthi Chari and Andrew Pressley. A Guide to Quantum Groups.
    Cambridge University Press, 1994.

[Erdős and Kac(1940)] P. Erdős and M. Kac. The gaussian law of errors in the theory of additive
     number theoretic functions. American Journal of Mathematics, 62(1):738–742, 1940.



                                                 12
[Fiat and Shamir(1987)] Amos Fiat and Adi Shamir. How to prove yourself: Practical solutions to
     identification and signature problems. Advances in Cryptology – CRYPTO ’86, 263:186–194,
     1987.

[Goldreich(2001)] Oded Goldreich. Foundations of Cryptography, Vol. 1: Basic Tools. Cambridge
    University Press, 2001.

[Innovations(2026)] Helix AI Innovations. Multiplicity theory: A prime-weighted braid invariant
     for constitutional lattices. Version 2.1, April 2026. Internal report, 2026.

[Jones(1987)] Vaughan F. R. Jones. Von Neumann Algebras and the Jones Polynomial, volume 47
    of London Mathematical Society Lecture Note Series. Cambridge University Press, 1987.

[Kassel(1995)] Christian Kassel. Quantum Groups, volume 155 of Graduate Texts in Mathematics.
    Springer, 1995.

[Kassel and Turaev(2008)] Christian Kassel and Vladimir Turaev. Braid Groups, volume 247 of
    Graduate Texts in Mathematics. Springer, 2008.

[Katz and Lindell(2014)] Jonathan Katz and Yehuda Lindell. Introduction to Modern Cryptogra-
    phy. Chapman and Hall/CRC, 2 edition, 2014.

[Montgomery and Vaughan(2007)] Hugh L. Montgomery and Robert C. Vaughan. Multiplicative
    Number Theory I: Classical Theory. Cambridge University Press, 2007.

[Narkiewicz(2000)] Wladyslaw Narkiewicz. The Development of Prime Number Theory: From
    Euclid to Hardy and Littlewood. Springer, 2000.

[NumPy Developers(2026)] NumPy Developers. Numpy: The fundamental package for scientific
    computing with python. https://numpy.org/, 2026. Accessed 2026-04-01.

[Ocneanu(1988)] Adrian Ocneanu. Quantized groups, string algebras and galois theory for algebras.
    Operator Algebras and Applications, London Math. Soc. Lecture Note Ser., 136:119–172, 1988.

[Pedersen(1992)] Torben P. Pedersen. Non-interactive and information-theoretic secure verifiable
    secret sharing. In Advances in Cryptology – CRYPTO ’91, volume 576 of LNCS, pages 129–140.
    Springer, 1992.

[Reshetikhin and Turaev(1991)] Nicolai Reshetikhin and Vladimir G. Turaev. Invariants of 3-
    manifolds via link polynomials and quantum groups. In Inventiones Mathematicae, volume
    103, pages 547–597. 1991.

[SymPy Development Team(2026)] SymPy Development Team. Sympy: Symbolic mathematics in
    python. https://www.sympy.org/, 2026. Accessed 2026-04-01.

[Tao and Vu(2006)] Terence Tao and Van Vu. Additive Combinatorics, volume 105 of Cambridge
    Studies in Advanced Mathematics. Cambridge University Press, 2006.

[Turaev(1994)] Vladimir G. Turaev. Quantum Invariants of Knots and 3-Manifolds. de Gruyter,
    1994.


                                               13
