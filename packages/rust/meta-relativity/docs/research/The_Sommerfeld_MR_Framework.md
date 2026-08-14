---
slug: the-sommerfeld-mr-framework
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/The_Sommerfeld_MR_Framework.md
  last_synced: '2026-03-20T17:17:19.363999Z'
---

                               From Primes to Predictions:
                  The Sommerfeld–MR Framework and the Gallows Protocol

                                         Ryan O. van Gelder∗

                                          December 13, 2025


                                                Abstract
            The Meta-Relativity (MR) program aims to derive physical laws from number-theoretic
        structure, in particular from primes and the Riemann zeta function. Without a clear route
        to falsifiable predictions, however, such frameworks risk remaining mathematical metaphors.
        In this work we introduce the Gallows Protocol, a step-by-step procedure that forces any
        MR-like construction to be expressed as an explicit operator, have its internal parameters
        fixed by MR principles, and be confronted with precision data.
            We apply the protocol to a concrete test case: a Sommerfeld–MR model of hydrogen
        fine structure. In its most natural implementation, the MR correction either overshoots
        experimental bounds by many orders of magnitude (Case A of the protocol) or reduces to
        a reparameterization of the standard spin–orbit operator (Case C). We then reframe the
        problem in terms of the multiplicity constant Λm , which provides a natural home for the
        small coupling required by hydrogen. In the current MR framework, however, Λm remains a
        system-dependent effective parameter, not a derived constant.
            To address this, we outline a program to obtain Λuniv m  from a universal prime-graded
        dynamics and to propagate this value into the hydrogen sector without further tuning. This
        would elevate MR from an ontological reinterpretation of known physics to a framework that
        makes genuine, falsifiable predictions.


Contents
1 Introduction                                                                                        2

2 A Universal Program: From Suniv to Λm to Hydrogen                                                   3
  2.1 A prime-graded universal operator Suniv . . . . . . . . . . . . . . . . . . . . . . .           3
  2.2 Global recursion and contraction condition . . . . . . . . . . . . . . . . . . . . .            4
  2.3 Selection principles for Λuniv
                                m    . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      4
  2.4 Sector restriction and inheritance by hydrogen . . . . . . . . . . . . . . . . . . .            5
  2.5 Implications for the hydrogen Gallows test . . . . . . . . . . . . . . . . . . . . . .          5
  2.6 MR as ontology vs MR as physics . . . . . . . . . . . . . . . . . . . . . . . . . . .           6

A Sommerfeld–MR Implementation Details                                                                6
  A.1 State space construction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        6
  A.2 Kernel specification . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      6
  A.3 Hilbert–Schmidt normalization . . . . . . . . . . . . . . . . . . . . . . . . . . . .           7
  A.4 Hydrogenic matrix elements . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          7
  A.5 Prime sum evaluation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          7
  A.6 Energy shift calculation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        8
  A.7 Numerical evaluation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        8
  A.8 Operator independence test (preliminary) . . . . . . . . . . . . . . . . . . . . . .            9
  ∗
      Citizen Gardens, email: ryan@citizengardens.org


                                                    1
B NRQED Operator Basis and Operator-Independence Test                                          9
  B.1 Spin-dependent NRQED operators for hydrogen . . . . . . . . . . . . . . . . . . . 9
  B.2 Structure of the Sommerfeld–MR operator . . . . . . . . . . . . . . . . . . . . . . 10
  B.3 Independence in the NRQED basis . . . . . . . . . . . . . . . . . . . . . . . . . . 10
  B.4 Implications for the Gallows classification . . . . . . . . . . . . . . . . . . . . . . 11


1     Introduction
The idea that number theory—and in particular the structure of the primes and the Riemann
zeta function—might underpin fundamental physics has a long history [. . . ]. The Meta-Relativity
(MR) program is a recent incarnation of this idea. In MR, physical laws are supposed to emerge
from lawfulness constraints, prime-graded Hilbert spaces, and multiplicity rules tied to zeta-like
sums.
    Despite its mathematical appeal, MR faces a familiar problem: without a systematic path from
its constructions to concrete, falsifiable predictions, it risks remaining an elaborate metaphor. In
practice, MR-like models often introduce new operators whose overall scales are left undetermined,
or they are flexible enough to be adjusted post hoc to match known data. This undermines their
status as physical theories.
    The aim of this work is twofold. First, we introduce the MR Gallows Protocol, a brutally
simple procedure that any proposed MR effect must pass: write down an explicit operator on a
concrete state space, fix all internal parameters from MR principles (not data), compute at least
one observable, compare with the best available standard theory and experiment, and classify the
outcome. The classification has three cases: (A) overshoot and falsification, (B) compatibility
with a bound on the coupling, and (C) degeneracy with existing effective field theory (EFT)
operators, in which case MR adds no new physics, only an ontological reinterpretation.
    Second, we apply this protocol to a specific case: a Sommerfeld–MR model of hydrogen
fine structure. This provides a clean test bed because the relevant observables are measured
and computed with extremely high precision. In our implementation, the natural MR scale
overshoots the experimental residual window by roughly eight orders of magnitude, unless the
coupling is tuned to be very small. Moreover, at the operator level, the MR correction appears
proportional to the standard spin–orbit term. Within the Gallows classification, this places the
model in Case A at unit coupling, and in Case C at the operator level.
    We then reframe the coupling in terms of the multiplicity constant Λm , which in the
MR/multiplicity formalism is the scalar that keeps prime-weighted recursions contractive. This
makes Λm the natural “home” for the small coupling demanded by hydrogen, but in the absence
of a universal construction it remains a system-dependent Wilson coefficient. To address this,
we outline a universal program: define a prime-graded operator Suniv , derive a universal Λuniv m
from its spectrum and multiplicities, and then embed the hydrogenic MR operator as a block of
Suniv without re-tuning.
    The rest of the paper is organized as follows. In Sec. ?? we present the MR Gallows Protocol
and its A/B/C classification. In Sec. ?? we construct the Sommerfeld–MR operator for hydrogen
and apply the protocol, including the hydrogenic calculation and the operator-independence
discussion. In Sec. ?? we describe the Λm framing and the resulting hydrogen constraint. In
Sec. 2 we outline a universal program to derive Λm from prime-graded dynamics. We conclude
in Sec. ?? with a discussion of MR’s current status as an ontological framework, and what would
be required for it to become genuinely predictive.
    Box X — MR Gallows Protocol for Proposed Effects
    The Gallows Protocol provides a standardized test for any concrete MR effect or “gate”
    (Sommerfeld, ZM, Casimir, etc.). It mandates explicit operator specification, MR-internal



                                                 2
 Case         Condition           Interpretation
  A          ∆OMR (λMR ∼          Overshoot: this specific MR implementation is falsified at
              1) ≫ |δO|           that stratum unless a structural suppression is derived.
    B        ∆OMR (λMR ∼          Compatible: the effect is viable and yields a quantitative
              1) ≲ |δO|           bound on the MR coupling.
    C        ∆HMR linearly        Degenerate: MR adds no new operator, only an ontological
             dependent on         reinterpretation.
             existing EFT
               operators

                     Table 1: MR Gallows Protocol: outcome classification.


    parameter fixing, and direct confrontation with precision data.
    1. Explicit operator on a concrete state space. Work within a well-defined Hilbert
    space (e.g. hydrogenic |nℓjmj ; p⟩, cavity modes, lattice sites). Define the MR contribution
    as an operator ∆HMR : H → H with:
        • domain and basis explicitly specified,
        • matrix elements or kernel explicitly written,
        • no undefined symbols (“kernel”, “gate”, “zeta coupling”) remaining.


2       A Universal Program: From Suniv to Λm to Hydrogen
The central limitation of the hydrogenic Sommerfeld–MR construction is that its overall scale is
controlled by a free coupling λMR ≡ Λm which must be tuned to be extremely small in order
to satisfy the Gallows Protocol. In the present MR framework, Λm is defined only at the level
of a given sector or recursion. To turn Λm into a genuine prediction, we require a universal
construction in which a single prime-graded operator Suniv determines a global multiplicity
constant Λuniv
            m   that is then inherited by specific sectors, including hydrogen.

2.1      A prime-graded universal operator Suniv
We consider a universal Hilbert space
                                                     M
                                        Huniv =            Hσ ,                                    (1)
                                                     σ∈Σ

decomposed into strata or sectors Hσ (e.g. atomic, nuclear, cosmological, ZM sectors, etc.). The
universal dynamics is encoded in a prime-graded operator Suniv of the form
                                    X
                           Suniv =      ap Mp ,     ap = p−σ f (p),                           (2)
                                       p∈P

where:

    • P is the set of primes (possibly truncated in any finite-dimensional approximation),

    • Mp : Huniv → Huniv encodes the action of prime p (e.g. as a multiplicity map, transition
      operator or projector),

    • f (p) is a slowly varying weight (e.g. log p or a bounded function of p),

    • σ > 1 is an exponent ensuring convergence of the prime sum.


                                                 3
We assume that for some operator norm ∥ · ∥ on B(Huniv ), the series (2) converges absolutely:
                                   X
                                       ∥ap Mp ∥ < ∞,                                        (3)
                                        p∈P

which guarantees that Suniv is a bounded operator with finite norm ∥Suniv ∥ and finite spectral
radius ρ(Suniv ).
    In the multiplicity formulation, the Mp are built from multiplicity maps M (T, p) evaluated
on some universal configuration T ; for the purposes of this section we keep this structure implicit
and emphasize only that Suniv is prime-graded and bounded.

2.2   Global recursion and contraction condition
The universal evolution of a configuration Tt ∈ Huniv is encoded in a recursion of the form

                                    Tt+1 = Λuniv
                                            m Suniv Tt + F,                                      (4)

where F represents driving terms or inhomogeneities, and Λuniv
                                                             m   is the universal multiplicity
constant.
   For a fixed bounded operator Suniv and norm ∥ · ∥, the Banach fixed-point theorem implies
that the recursion (4) is contractive, and hence admits a unique fixed point and exponential
convergence, provided
                                       ∥Λuniv
                                         m Suniv ∥ < 1.                                    (5)
This defines an allowed interval for Λuniv
                                      m :

                                                                1
                                     0 < Λuniv
                                          m    <                        .                        (6)
                                                             ∥Suniv ∥

Tighter bounds can be obtained in terms of the spectral radius ρ(Suniv ), using the Gelfand
                             n ∥1/n . A natural “critical” value is
formula ρ(Suniv ) = limn→∞ ∥Suniv

                                                        1
                                        Λcrit =                ,                                 (7)
                                                     ρ(Suniv )

which saturates the boundary between contractive and non-contractive linear dynamics. In
practice one usually chooses a “safe” value
                                                 γ
                              Λuniv
                               m (γ) =                   ,          0 < γ < 1,                   (8)
                                              ∥Suniv ∥

which guarantees ∥Λuniv
                      m (γ)Suniv ∥ ≤ γ < 1.
    Thus, given Suniv , there is a whole interval of Λuniv
                                                      m    which make the recursion contractive. To
           univ
promote Λm from an arbitrary stability coefficient to a genuine prediction requires an additional
selection principle intrinsic to MR (e.g. a lawfulness or multiplicity extremality condition).

2.3   Selection principles for Λuniv
                                m

Within the MR/multiplicity picture, one may envision several possible selection principles for
Λuniv
 m , for example:

   • Criticality: choose Λuniv
                          m    = Λcrit = 1/ρ(Suniv ) to sit at the boundary of stability, so that
     small changes in Suniv can be absorbed into Tt but not into Λuniv
                                                                     m .

   • Global lawfulness: choose Λuniv
                                 m   such that a global lawfulness functional L(T∞ ), defined on
     the fixed point T∞ of (4), is extremized or saturates a constraint.


                                                     4
    • Multiplicity averaging: define
                                                    X
                                             −1
                                       Λuniv
                                        m       =         M (T∞ , p) p−α ,                    (9)
                                                    p∈P

      for some exponent α and multiplicity function M , and use the universal fixed point T∞ to
      determine Λuniv
                  m .

In all of these cases, the central requirement is that Λuniv
                                                         m    be determined by the global prime-
graded dynamics alone, without reference to any specific sector such as hydrogen. Only under
such a selection principle can Λuniv
                                m    be claimed as a prediction of the MR framework rather than
a sector-by-sector fit parameter.

2.4    Sector restriction and inheritance by hydrogen
Given Suniv and a choice of Λuniv
                               m , we can define sector projectors Pσ : Huniv → Hσ and the
corresponding sector-restricted operators

                                          Sσ = Pσ Suniv Pσ .                                 (10)

In particular, let σ = atom denote the atomic/hydrogenic sector, with

                                    Hatom ≃ Hhyd ⊗ Hprime ,                                  (11)

and define
                                    SMR = Patom Suniv Patom .                                (12)
The key requirement of the universal program is that the same Λuniv
                                                               m    which stabilizes the global
recursion (4) also controls the atomic recursion,
                               (atom)                      (atom)
                             Tt+1       = Λuniv
                                           m SMR Tt                 + Fatom ,                (13)

and hence the atomic MR Hamiltonian,

                                        ∆HMR = Λuniv
                                                m OMR ,                                      (14)

with OMR fully specified by MR rules (kernel, normalization, angular structure, etc.). No further
“local” retuning of Λm is allowed at the atomic level.

2.5    Implications for the hydrogen Gallows test
With this structure in place, the hydrogen Gallows test becomes:

  (a) Construct OMR in the hydrogen sector from SMR and MR rules.

  (b) Use the globally determined Λuniv
                                   m    to fix the overall scale of ∆HMR .

  (c) Compute the hydrogenic corrections ∆OMR and compare them to the residual windows
      using the Gallows Protocol.

If ∆HMR is linearly independent of existing NRQED operators and Λuniv
                                                                 m    places ∆OMR within the
residual window (Case B), MR would make a genuine predictive connection between global prime-
graded dynamics and atomic physics. If instead ∆HMR ∝ OSO as in the present Sommerfeld–MR
implementation, the effect is Case C (degenerate), and Λuniv
                                                        m    only rescales an existing Wilson
coefficient, not a new operator.



                                                    5
2.6    MR as ontology vs MR as physics
The Sommerfeld–MR example, when passed through the Gallows Protocol, illustrates a distinction
that is conceptually crucial for the MR program but often blurred in informal discussions: the
difference between MR as ontology and MR as physics.
    By “MR as ontology” we mean the claim that familiar physical structures (e.g. spin–orbit
coupling, gauge interactions, curvature) can be factorized into prime-graded multiplicities, zeta-
like weights, and lawfulness constraints. In this mode, MR does not change any observable, but
offers a different story about why a given operator exists or why a particular combination of
operators is singled out. In the language of the Gallows Protocol, this corresponds to Case C:
∆HMR is a linear combination of existing EFT operators and merely repackages their coefficients
in multiplicity language. MR is then an ontological or mathematical framework, not a source of
new predictions.
    By “MR as physics” we mean the stronger claim that MR introduces new operator structures
or nontrivial relations between sectors that are not already present in standard effective field
theories. In Gallows language, this corresponds to either:

    • Case B: a genuinely new operator whose effects are small but compatible with residual
      windows and yield explicit bounds on its coupling, or

    • Case A: a proposed operator that overshoots the data and is thereby ruled out, providing
      a concrete falsification of a specific MR construction.

In both cases, MR is behaving as a physical framework: it makes statements that can be tested
and, in principle, refuted.
     The Sommerfeld–MR construction in hydrogen currently sits on the ontological side of this
divide. At the operator level it appears proportional to the standard spin–orbit term and thus
falls into Case C; at the level of numerical size it belongs to Case A unless the coupling is tuned
to be extremely small. In this situation, it is misleading to advertise Sommerfeld–MR as “new
physics” in the usual sense. What it provides instead is an MR-flavored factorization of an
existing QED operator, together with a concrete demonstration of how the framework can fail
the Gallows test when pushed towards prediction.
     We view this distinction not as an indictment of MR but as a guide. The Gallows Protocol
allows one to keep the ontological ambitions of MR intact while demanding that any claim to
new physics pass a much stricter standard: an explicit operator, a fixed coupling (e.g. via a
universal Λm ), and survival against precision data without post hoc tuning.


A     Sommerfeld–MR Implementation Details
A.1    State space construction
We work in a truncated Hilbert space

                                       H = Hhyd ⊗ Hprime ,                                       (15)

where Hhyd is spanned by hydrogenic states |nℓjmj ⟩ with n ≤ 4, and Hprime is spanned by |p⟩
for primes p ∈ {2, 3, . . . , 53}. The total dimension is Nstates × Nprimes , where Nstates counts all
(n, ℓ, j, mj ) with n ≤ 4 and ℓ ≥ 1.

A.2    Kernel specification
The MR kernel is taken to be factorized:

                                         Kab,pq = Mab Lpq ,                                      (16)

                                                  6
where indices a, b run over hydrogenic states and p, q over primes.
   The hydrogenic part is chosen diagonal,
                       Mab = Ca δab ,       Cnℓj =           nℓj r−3 nℓj                 nℓj L · S nℓj ,        (17)
so that M encodes the usual spin–orbit structure.
    The prime part L is taken to be rank-1:
                                             log p                                      wp
                    Lpq = w̃p w̃q ,    wp =        ,                             w̃p = qP                   ,   (18)
                                              p2                                                        2
                                                                                                     q wq

                        2
          P
so that       p,q |Lpq | = 1.


A.3       Hilbert–Schmidt normalization
We define the MR correction to the coupling as
                                                  ∆α = αΦ K                                                     (19)
and impose a Hilbert–Schmidt normalization ∥∆α∥HS = 1:
                                         X
                        ∥∆α∥2HS = |αΦ |2    |Kab,pq |2                                                          (20)
                                                   a,b,p,q
                                                                         !                           !
                                                     X                           X
                                        = |αΦ |2             |Ca |2                    |w̃p w̃q |2              (21)
                                                       a                         p,q
                                                                         !
                                                     X
                                               2                     2
                                        = |αΦ |              |Ca |           ,                                  (22)
                                                       a
                          2
        P
since       p,q |w̃p w̃q | = 1 by construction. The condition ∥∆α∥HS = 1 then fixes
                                                                 1
                                           |αΦ | = pP                            .                              (23)
                                                                       2
                                                                a |Ca |


A.4       Hydrogenic matrix elements
For ℓ ≥ 1, the radial expectation values for a hydrogenic state are
                                                               Z3
                                    r−3 nℓ =                                .                                   (24)
                                                    a30 n3 ℓ ℓ + 21 (ℓ + 1)
                                                                   

The spin–orbit angular factor is
                                        1
                                           j(j + 1) − ℓ(ℓ + 1) − 34 .
                                                                   
                                L · S nℓj =                                                                     (25)
                                        2
We tabulate Cnℓj for n ≤ 4 and ℓ ≥ 1; these enter the normalization factor a |Ca |2 .
                                                                          P


A.5       Prime sum evaluation
We define the truncated prime sum
                                                               X log p
                                          S(P, σ) =                              ,                              (26)
                                                                         pσ
                                                               p≤P

and for the present calculation use P = 53 and σ = 2:
                                            X log p
                                S(53, 2) =            ≈ 0.476.                                                  (27)
                                                 p2
                                                     p≤53

Note that
       P this is distinct from the normalized weights w̃p , which are used in the kernel and
satisfy p w̃p2 = 1.

                                                           7
A.6       Energy shift calculation
To first order in perturbation theory, the MR correction to a given hydrogenic level is
                        (1)
                                            X
                    ∆Enℓj = λMR αΦ Cnℓj       Lpq ≈ λMR αΦ S(53, 2) Cnℓj ,                    (28)
                                               p,q

where we have used the rank-1 structure of Lpq and the fact that its effective trace picks out the
prime sum.
   For the 2P fine-structure levels (with Z = 1),
                                                  1 1
                                         C2P3/2 =        ,                                    (29)
                                                  48 a30
                                                    1 1
                                         C2P1/2 = −        ,                                  (30)
                                                    24 a30

so that
                                                           1 1
                                     C2P3/2 − C2P1/2 =            .                           (31)
                                                           16 a30
The MR contribution to the 2P splitting is therefore

                                               S(53, 2)     1
                             ∆EMR (2P ) = λMR pP                .                             (32)
                                                         2 16a3
                                                  a |Ca |     0


A.7       Numerical evaluation
Evaluating the hydrogenic sum over Ca2 for n ≤ 4 and ℓ ≥ 1 gives
                                                                        2
                                X
                                         2                −3       1
                                      |Ca | ≈ 2.42 × 10                       ,               (33)
                                 a
                                                                   a30

so that                               s
                                       X                       1
                                             |Ca |2 ≈ 0.049        .                          (34)
                                         a
                                                               a30

The dimensionless ratio
                                           S(53, 2)
                                      r ≡ pP           ≈ 9.7                                  (35)
                                                     2
                                              a |Ca |
then yields
                                                      1
                   ∆EMR (2P ) ≈ λMR × 9.7 ×                ≈ 0.61 λMR (Hartree).              (36)
                                                     16a30
   For hydrogen (Z = 1), 1 Hartree ≈ 27.2 eV, so

                                     ∆EMR (2P ) ≈ 16.6 λMR eV.                                (37)

The actual 2P3/2 − 2P1/2 splitting is ∆Esplit ∼ 4.5 × 10−5 eV, so for λMR ∼ 1 the MR correction
overshoots the splitting itself by a factor of order
                                        ∆EMR
                                                ∼ 105 –106 .                                  (38)
                                        ∆Esplit

Relative to the much smaller residual window between experiment and QED, the overshoot is
correspondingly larger.



                                                     8
A.8    Operator independence test (preliminary)
In NRQED, the leading spin-dependent operators include the spin–orbit term, the Darwin term,
and spin–spin/tensor terms. In the present implementation, Mab is constructed from r−3 L · S,
and the prime kernel Lpq is a scalar in the hydrogenic indices. At the operator level, this suggests
that
                                          ∆HMR ∝ L · S                                          (39)
up to an overall scalar and truncation effects, i.e. that the MR operator appears proportional to
the standard spin–orbit operator.
   A full operator-independence test would expand ∆HMR in a complete NRQED operator
basis and check for linear independence. Preliminary inspection indicates degeneracy (Case C in
the Gallows classification), but we leave the detailed decomposition to Appendix B.


B     NRQED Operator Basis and Operator-Independence Test
In this appendix we briefly review the nonrelativistic QED (NRQED) operator basis relevant
for hydrogenic fine structure, and use it to clarify the status of the Sommerfeld–MR operator
∆HMR at the operator level. The goal is to determine whether ∆HMR is linearly independent of
the standard NRQED operators, or whether it is degenerate with an existing structure (Case C
in the Gallows classification).

B.1    Spin-dependent NRQED operators for hydrogen
For a single electron in an external Coulomb field, the NRQED Hamiltonian can be organized as
an expansion in 1/me and the electromagnetic coupling. To the order relevant for fine structure,
the spin-dependent part of the effective Hamiltonian can be written as

                           Hspin = cSO OSO + cD OD + cSS OSS + . . . ,                         (40)

where the dots denote higher-order and/or many-body terms that are irrelevant for the hydrogenic
2P fine structure.
   A convenient basis of spin-dependent operators includes:
    • The spin–orbit operator,
                                                      Zα 1
                                         OSO =                L · S,                           (41)
                                                      4m2e r3
      which produces the familiar n, ℓ, j-dependent fine-structure splitting of P and higher-ℓ
      states.

    • The Darwin operator,
                                                      πZα (3)
                                          OD =             δ (r),                              (42)
                                                      2m2e
      which only affects S-states through the contact term.

    • Spin–spin or tensor operators (for many-body systems), which are absent for a single
      electron in a pure Coulomb field and do not contribute to the hydrogen 2P fine structure.
For the hydrogenic 2P3/2 − 2P1/2 splitting, the dominant spin-dependent contribution comes
from OSO ; OD does not contribute because P -wave wave functions vanish at the origin, and
there are no spin–spin terms in the one-electron problem.
   Thus, at the level of operator structure relevant to the 2P splitting, the NRQED spin-
dependent Hamiltonian is effectively one-dimensional:
                                          (2P )
                                       Hspin ≃ cSO OSO ,                                       (43)

                                                  9
with all other spin-dependent operators either vanishing on the 2P subspace or contributing
only at higher order.

B.2    Structure of the Sommerfeld–MR operator
In the Sommerfeld–MR construction described in the main text and in Appendix A, the MR
correction is implemented as a factorized kernel on the truncated state space Hhyd ⊗ Hprime :

                            Kab,pq = Mab Lpq ,        Mab = Ca δab ,                         (44)

with Ca proportional to the standard spin–orbit matrix element,

                            Cnℓj ∝     nℓj r−3 nℓj    nℓj L · S nℓj .                        (45)

The prime kernel Lpq is a rank-1 projector built from normalized weights w̃p and is a scalar in
the hydrogenic indices.
   After Hilbert–Schmidt normalization, the MR contribution to the Hamiltonian can be written
schematically as
                                  ∆HMR = λMR αΦ Ĉ ⊗ L̂,                                   (46)
where Ĉ is a diagonal operator on Hhyd with entries proportional to the spin–orbit expectation
values, and L̂ acts only on the prime sector. If we restrict attention to the physical hydrogenic
Hilbert space by tracing over or projecting out the prime degrees of freedom, the effect of L̂
reduces to an overall scalar factor,

                                     Trprime (L̂ ρprime ) → κ,                               (47)

for an appropriate prime-sector state ρprime . The effective operator acting on the hydrogenic
sector is therefore
                               (eff)
                           ∆HMR = λeff Ĉ,         λeff ≡ λMR αΦ κ,                       (48)
with Ĉ diagonal in the hydrogenic basis and proportional, by construction, to the spin–orbit
matrix element.
   At the level of operators on Hhyd , this means

                                      (eff)   1
                                 ∆HMR ∝          L · S ≡ OSO ,                               (49)
                                              r3
up to an overall scalar factor and the truncation to n ≤ 4 used in the explicit calculation.
No additional angular or radial structures are introduced by the prime sector; all of the MR
structure is carried by the overall scalar λeff and the internal prime weights in Lpq .

B.3    Independence in the NRQED basis
Given the NRQED spin-dependent basis {OSO , OD , . . . } and the form (49), the independence
question is straightforward for the hydrogenic 2P splitting:

   • OD and higher-contact operators do not contribute to the 2P fine structure because P -wave
     hydrogenic wave functions vanish at the origin.

   • Spin–spin/tensor operators are absent in the one-electron Coulomb problem and are
     therefore irrelevant for hydrogen.

   • The only spin-dependent operator that contributes at leading order to the 2P3/2 − 2P1/2
     splitting is OSO .


                                                10
    Any diagonal operator in the hydrogenic basis whose entries are proportional to the spin–orbit
expectation values ⟨r−3 ⟩nℓ ⟨L · S⟩nℓj is therefore linearly dependent on OSO when restricted to
                                                                   (eff)
the 2P subspace. In particular, the effective MR operator ∆HMR constructed above can be
written as
                                            (eff)
                                        ∆HMR = λ′eff OSO ,                                    (50)
for some effective coupling λ′eff that encodes the prime-sector weights, the HS normalization,
and the overall MR coupling.
    In the language of the Gallows Protocol, this places the Sommerfeld–MR implementation in
Case C at the operator level: the MR correction does not introduce a new operator structure in
the NRQED basis, but rather rescales an existing operator, namely the spin–orbit term.

B.4    Implications for the Gallows classification
Combining the operator-level analysis of this appendix with the numerical results of Appendix A,
we obtain a sharp classification:

   • At λMR ∼ 1 (or, equivalently, Λm ∼ 1 in the Λm framing), the Sommerfeld–MR contribution
     to the 2P3/2 − 2P1/2 splitting overshoots the experimental residual window by many orders
     of magnitude (Case A: overshoot / falsified).

   • As an operator on the hydrogenic Hilbert space, the MR correction is proportional to the
     standard spin–orbit operator and therefore introduces no new independent structure in
     the NRQED basis (Case C: degenerate / interpretational).

    This confirms the qualitative conclusion of the main text: in its present form, the Sommerfeld–
MR implementation for hydrogen fine structure is either ruled out as a sizable physical effect or,
if tuned to be small, reduces to an ontological reparameterization of the spin–orbit interaction
rather than a new piece of physics.


References
 [1] H. A. Bethe and E. E. Salpeter, Quantum Mechanics of One- and Two-Electron Atoms
     (Springer, Berlin, 1957).

 [2] W. E. Caswell and G. P. Lepage, “Effective Lagrangians for Bound State Problems in QED,
     QCD, and Other Field Theories,” Phys. Lett. B 167, 437–442 (1986).

 [3] P. Labelle, “Effective Field Theories for QED Bound States,” Phys. Rev. D 58, 093013
     (1998).

 [4] M. I. Eides, H. Grotch, and V. A. Shelyuto, “Theory of Light Hydrogenlike Atoms,” Phys.
     Rep. 342, 63–261 (2001).

 [5] S. G. Karshenboim, “Precision Physics of Simple Atoms: QED Tests, Nuclear Structure
     and Fundamental Constants,” Phys. Rep. 422, 1–63 (2005).

 [6] S. G. Karshenboim, “Simple Atoms, Quantum Electrodynamics, and Fundamental Con-
     stants,” in The Hydrogen Atom: Precision Physics of Simple Atomic Systems, Lect. Notes
     Phys. 627, 141–164 (Springer, Berlin, 2003).

 [7] S. Weinberg, The Quantum Theory of Fields, Vol. I: Foundations (Cambridge University
     Press, Cambridge, 1995).

 [8] W. E. Caswell and G. P. Lepage, Phys. Lett. B 167, 437 (1986).


                                                11
 [9] S. G. Karshenboim, “Recent Progress in the Precision Physics of Simple Atoms,” in The
     Hydrogen Atom: Precision Physics of Simple Atomic Systems, Lect. Notes Phys. 627, 1–30
     (Springer, Berlin, 2003).

[10] B. Riemann, “Über die Anzahl der Primzahlen unter einer gegebenen Grösse,” Monatsber.
     Königl. Preuss. Akad. Wiss. Berlin (1859).

[11] H. M. Edwards, Riemann’s Zeta Function (Academic Press, New York, 1974).




                                            12
