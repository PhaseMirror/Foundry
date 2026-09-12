---
slug: multiplicity-atomic-primes-via-multiplicity-profiles-derived-intersections-and-extremal-functionals
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Multiplicity-atomic Primes Via Multiplicity Profiles,
    Derived Intersections, And Extremal Functionals.md
  last_synced: '2026-03-20T17:17:19.633551Z'
---

Multiplicity-Atomic Primes (MAP)
This document formalizes a “prime by multiplicity profile” framework that (i) treats multiplicity as a
numerical invariant of local complexity, (ii) interfaces naturally with intersection multiplicity via derived
tensor products, and (iii) supports an optional extremal/“curvature–torsion” characterization that
distinguishes primes from near-prime regimes (prime powers, squarefree composites, highly composite).




0. Guiding idea
Instead of taking divisibility as primitive, encode an arithmetic object by its local multiplicity profile across
“prime points.”


      • For integers, this is the assignment p ↦ vp (n).
      • Geometrically, it is a 0-cycle (effective divisor) on Spec(Z) supported on height-1 points.
      • Categorically, it is the multiset of Jordan–Hölder multiplicities of simple torsion objects.

This lens generalizes cleanly to Dedekind domains and 1-dimensional regular schemes.




1. Ambient setting

1.1 Dedekind domain model

Let A be a Dedekind domain with fraction field K .


      • Height-1 primes p ∈ Spec(A) are the “prime points.”
      • Localizations Ap are DVRs.

For a nonzero ideal I ⊂ A, define the torsion module


$$ M_I := A/I. $$


Integer case: A = Z, I = (n), M(n) ≅ Z/nZ.


Polynomial case: A = Fq [t], I = (f ), M(f ) ≅ Fq [t]/(f ).


1.2 Sheaf model (1-dimensional regular scheme)

Let X be a 1-dimensional regular scheme.


      • Codimension-1 points x ∈ X (1) play the role of primes.
      • Local rings OX,x are DVRs.




                                                        1
For a torsion coherent sheaf F , localize to Fx .




2. Multiplicity profile as a local length invariant

2.1 Module/ideal multiplicity profile

For a torsion A-module M of finite length (e.g. M = A/I ), define the multiplicity profile


$$ \nu_M(\mathfrak p) := \operatorname{length}{A)\in \mathbb N. $$}}(M_{\mathfrak p


For MI = A/I , write νI (p) := νA/I (p).


Facts (Dedekind domain):


      • νI (p) = 0 for all but finitely many p.
      • If I = ∏p pap (unique factorization of ideals), then $$ \nu_I(\mathfrak p)=a_{\mathfrak p}. $$

Integer specialization: I = (n) ⊂ Z gives ν(n) (p) = vp (n).


2.2 Multiplicity cycle / multiplicity field

Define the multiplicity cycle (effective divisor / measure)


$$ \mu(M) := \sum_{\mathfrak p\in\mathrm{Spec}(A)^{(1)}} \nu_M(\mathfrak p)\,[\mathfrak p]. $$


In the sheaf model:


$$ \mu(\mathcal F) := \sum_{x\in X^{(1)}} \operatorname{length}{\mathcal O(\mathcal F_x)\,[x]. $$}


Interpretation: μ is the canonical “multiplicity field” assigning mass ν to each prime point.




3. Multiplicity-Atomic Primes (MAP)

3.1 Definition (MAP object)

A torsion module M (finite length) over a Dedekind domain A, or a torsion coherent sheaf F on a 1-
dimensional regular scheme X , is Multiplicity-Atomic Prime (MAP) if its multiplicity cycle is a single unit
spike:


      • Single support: μ(M ) = [p] for some height-1 prime p (equivalently νM (q) = 0 for q  p).=
      • Unit thickness: νM (p) = 1.

Equivalently, in the Dedekind domain case:




                                                       2
$$ M\cong A/\mathfrak p. $$


Integer case: MAP objects are exactly Z/pZ, i.e. primes.


3.2 Near-MAP strata (spectrum)

The multiplicity cycle yields a natural stratification:


      • Prime powers: μ = k[p] (single support, thickness k ).
                                            r
      • Squarefree composites: μ = ∑i=1 [pi ] with r ≥ 2.
      • Highly composite: many p with larger ν .

This gives a spectrum of “prime-likeness” measured by dispersion of μ and by thickness.




4. Derived intersections as multiplicity overlap

4.1 Derived tensor product as intersection

For torsion A-modules M , N define their derived intersection complex


$$ M\otimes^{\mathbf L}_A N $$

                     A
with homology Tori (M , N ).


Localizing at p reduces to the DVR Ap , so the overlap is controlled prime-by-prime.


4.2 Tor-min rule (local DVR calculation)

Let R be a DVR with uniformizer π . For a, b ≥ 1, set Ma = R/(π a ), Nb = R/(π b ). Then:


$$ M_a\otimes_R N_b\cong R/(\pi^{\min(a,b)}),\qquad \mathrm{Tor}_1^R(M_a,N_b)\cong R/(\pi^{\min(a,b)}),
\qquad \mathrm{Tor}_i^R(M_a,N_b)=0\ (i>1). $$


Consequences:


      • Local overlap thickness is min(a, b).
      • Both Tor0 and Tor1 carry the same local length.

4.3 Derived minimal-overlap characterization of MAP

Let M be MAP supported at p.


      • If N has disjoint support (νN (p) = 0), then (M ⊗L
                                                         A N )p ≃ 0, and in fact the entire derived tensor
        product vanishes after localization at every prime.
      • If N is supported at p, then local overlap is exactly min(1, νN (p)) = 1 in Tor0 and Tor1 .




                                                          3
This implements the slogan: MAP objects have minimal nontrivial derived intersection, occurring only
at the same prime point, and only with unit thickness.


         Note: In 1-dimensional settings, Serre’s alternating Euler characteristic ∑(−1)i ℓ(Tori ) often
         cancels because Tor0 and Tor1 have equal length. Here we use Tor-length profiles (or
         ℓ(Tor0 ) alone) as the multiplicity signal.



5. Extremal functionals (“curvature / torsion”) on multiplicity
profiles
This section builds optional, computable functionals on μ that distinguish:


      • localization across supports (how many spikes),
      • thickness (prime powers vs unit thickness),
      • overall dispersion (highly composite).

5.1 Normalized distribution on primes

For an integer n ≥ 2, define:


$$ \Omega(n)=\sum_p v_p(n),\qquad \omega(n)=#{p:\ v_p(n)>0},\qquad \pi_n(p)=\frac{v_p(n)}{\Omega(n)}. $
$


Analogously over Dedekind domains, normalize ν by total mass.


5.2 Dispersion (entropy)

Define the entropy


$$ H(n)= -\sum_{p:\ v_p(n)>0} \pi_n(p)\log \pi_n(p). $$


Properties:


      • H(n) = 0 iff μn has single support (i.e. n is a prime power).
      • For squarefree composites with r distinct primes, H(n) = log r .

5.3 Thickness penalty (torsion-thickness)

Define


$$ T(n) := \Omega(n)-\omega(n)=\sum_p \max{v_p(n)-1,0}. $$




                                                          4
Properties:


        • T (n) = 0 iff n is squarefree.
        • Prime powers pk satisfy T (pk ) = k − 1.

5.4 MAP score

For λ > 0 define


$$ J(n):=H(n)+\lambda\,T(n). $$


Then:


        • J(n) = 0 iff n is prime.
        • Prime powers: H = 0, T > 0.
        • Squarefree composites: T = 0, H > 0.
        • Highly composite: typically both H and T large.

This gives a canonical, non-tautological “prime-likeness” scalar that separates the two main failure modes
(multi-support vs thickness).


5.5 Optional filtration curvature (order-based)

Define the cutoff filtration


$$ F_n(x):=\sum_{p\le x} v_p(n) $$


(step function in x). One can define a discrete curvature energy via second differences in x (choice-
dependent, but computable).


Caution: order-based curvature depends on the chosen filtration (e.g., by p ≤ x, by log p, by Chebyshev
weights). Robustness should be tested by comparing several natural filtrations.




6. Theorems and core propositions (statements)

Theorem 6.1 (Classification of MAP modules over Dedekind domains)

Let A be a Dedekind domain and M a finite-length torsion A-module. Then M is MAP iff M ≅ A/p for
some height-1 prime p.


Proposition 6.2 (Local derived overlap)

Let M = A/I , N = A/J . For each height-1 prime p, localizing at p gives:




                                                       5
$$ \ell_{A_{\mathfrak p}}\big(\mathrm{Tor}0^A(M,N)\big) = \ell_{A_{\mathfrak p}}\big(\mathrm{Tor}1^A(M,N)
\big) = \min{\nu_I(\mathfrak p),\nu_J(\mathfrak p)}. $$


and Tori = 0 for i > 1 after localization at a height-1 prime.


Corollary 6.3 (Minimal nontrivial overlap for MAP)

If M is MAP supported at p, then for any N :


     • If νN (p) = 0, then (M ⊗L
                               A N ) p ≃ 0.
     • If νN (p) > 0, then the local derived overlap thickness equals 1.




7. Predictions / expected structural outcomes
    1. Spectral stratification: The pair (H(n), T (n)) partitions integers into regimes:


    2. primes (0, 0),


    3. prime powers (0, > 0),
    4. squarefree composites (> 0, 0),

    5. mixed composites (> 0, > 0).


    6. Derived overlap detects gcd-loci locally: The pointwise overlap min(vp (m), vp (n)) is exactly the
       local derived thickness; the full Tor-length profile can be read as “hidden multiplicity.”


    7. Generalization robustness: Over Fq [t], the same (H, T ) and MAP definitions pick out irreducibles
       as MAP, prime powers as thickness-only deviations, etc.




8. Fast validation pathway

8.1 Integer sandbox

     • Compute vp (n), Ω(n), ω(n), H(n), T (n), J(n) for 2 ≤ n ≤ N .
     • Verify J(n) = 0 iff n is prime.
     • Visualize clusters in (H, T ) space.

8.2 Structural (derived) validation

     • Prove the DVR Tor-min rule.
     • Deduce Proposition 6.2 by localization.




                                                        6
8.3 Generalization test

    • Repeat computations for A = Fq [t] up to degree d and compare distributions of (H, T ).




9. Notes and cautions
    • In dimension 1, the alternating Serre intersection multiplicity ∑(−1)i ℓ(Tori ) can cancel; here the
      multiplicity signal is carried by Tor-length profiles (or ℓ(Tor0 ) alone).
    • Over general rings, “simple module” corresponds to maximal ideals; to keep “prime points” aligned
      with height-1 primes, work in the divisor/Dedekind/regular-codim-1 setting.
    • Order-based curvature requires choosing a filtration; test robustness under several natural
      filtrations.


10. References

Core commutative algebra and length

    • M. F. Atiyah and I. G. Macdonald, Introduction to Commutative Algebra, Addison–Wesley, 1969.
    • D. Eisenbud, Commutative Algebra with a View Toward Algebraic Geometry (Graduate Texts in
      Mathematics 150), Springer, 1995.
    • H. Matsumura, Commutative Ring Theory (Cambridge Studies in Advanced Mathematics 8),
      Cambridge University Press (English ed.), 1986.
    • The Stacks Project (online reference):
    • “Length” (Tag 00IU): definitions and basic properties of module length.
    • “Factorization / Dedekind domain” (Tag 034O / 034W): ideal factorization in Dedekind domains.

Algebraic number theory viewpoint (divisors, valuations)

    • J. Neukirch, Algebraic Number Theory (Grundlehren der mathematischen Wissenschaften 322),
      Springer, 1999.

Intersection multiplicity and Tor-formulas

    • J.-P. Serre, Algèbre locale, multiplicités (Lecture Notes in Mathematics 11), Springer, 1965; English
      translation Local Algebra, Springer.
    • W. Fulton, Intersection Theory (Ergebnisse der Mathematik und ihrer Grenzgebiete), Springer, 1984
      (2nd ed. 1998).
    • P. C. Roberts, “Intersection multiplicities and Hilbert polynomials,” Michigan Mathematical Journal 48
      (2000).

Homological algebra (derived tensor, Tor/Ext)

    • C. A. Weibel, An Introduction to Homological Algebra (Cambridge Studies in Advanced Mathematics
      38), Cambridge University Press, 1994.




                                                     7
Derived algebraic geometry (derived intersections as the correct intersection object)

     • J. Lurie, Derived Algebraic Geometry (DAG notes, preprints).
     • B. Toën, “Derived algebraic geometry,” EMS Surveys (expository article / notes).

Recent and expository pointers (2024+)

     • Y. Cid-Ruiz, C. Polini, and B. Ulrich, “Multidegrees, families, and integral dependence,” arXiv:
       2405.07000 (2024).
     • Y. Cid-Ruiz, “Polar Multiplicities and Integral Dependence,” International Mathematics Research Notices,
       Volume 2024, Issue 17 (2024).
     • O. Finegan, Cohomologies of Derived Intersections (PhD thesis, 2024).
     • T. Feng and M. Harris, Derived Structures in the Langlands Correspondence, arXiv:2409.03035 (2024).

Citizen Gardens © 2025 CC-NC-ND 4.0




                                                      8
