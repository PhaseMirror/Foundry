---
id: ADR-0037
title: "ADR-0037: Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.GeometricTrees
rust_module: echonomics_engine::geometric_trees
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0037: Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0037
Title: Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space Yossi Bokor Bleile #  ISTA (Institute of Science and Technology Austria), Klosterneuburg, Austria and The University of Sydney, Sydney, Australia

Emanuele Cortinovis #  ISTA (Institute of Science and Technology Austria), Klosterneuburg, Austria

Herbert Edelsbrunner #  ISTA (Institute of Science and Technology Austria), Klosterneuburg, Austria

Shota Uka #  Technical University of Vienna, Vienna, Austria, and ISTA (Institute of Science and Technology arXiv:2606.20096v1 [cs.CG] 18 Jun 2026

Austria), Klosterneuburg, Austria

Abstract Tree-like structures appear in many areas of science, and their shapes can help understand the underlying processes they drive or that give rise to them. By thinking of these structures as geometric graphs in R3 , we gain access to tools from computational geometry and topology to study them. In this paper, we adopt the theory of quadratic forms to measure the directional spread of geometric graphs, and we introduce the hexplot model—equipped with a metric derived from the Fisher metric on the standard triangle—to visualize, measure, and collect statistics.

2012 ACM Subject Classification Theory of computation → Computational geometry

Keywords and phrases Geometric graphs, measures, quadratic forms, Fisher metric, path decompos- ition, applications to dendrites.

Digital Object Identifier 10.4230/LIPIcs...

Funding This research was partially funded by the Austrian Science Fund (FWF) 10.55776/ESP9584724. For open access purposes, the author has applied a CC BY public copyright license to any author accepted manuscript version arising from this submission.

1     Introduction

Exploring the morphology of tree-like structures is instrumental to understanding both their functional properties and the processes that generate them. Applications range from signal transmission in neurons to crystal growth and material porosity in physical systems. Quantifying and comparing such branching structures across different contexts remains a central challenge. Classical approaches rely on local geometric descriptors (such as branch length, curvature, bifurcation angles, tortuosity, branch diameter and taper, and Strahler order), summary profiles (such as the width function and Sholl analysis), or global scalar statistics (such as total path length and tree asymmetry indices); see e.g. [3, 4, 13, 17]. We focus on dendritic structures in 3-dimensional space that can be viewed as geometric graphs embedded in R3 , thereby gaining access to geometric and topological tools that describe both local and global aspects of shape and branching. This representation enables principled comparisons based on the geometry, connectivity, and hierarchical organisation of the dendrites, and provides a natural interface for integrating local geometric measures (such as edge lengths, angles, and curvature) with topological invariants (such as graph homology and persistence summaries) that capture structural complexity across scales.

XX:2   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

Figure 1: A-C) Reconstructions of three apical dendrites (courtesy of Peter Jonas and Jake Watson at ISTA) from SWC files. Each has the structure of a rooted geometric tree embedded in R3 . D) Each of the three dendrites corresponds to a 6-tuple of points in the hexplot, of which the points in the lower left quadrangle are labeled. The hexplot has 6-fold symmetry, with a quadrangular fundamental region indicated by dotted lines. E) Each dendrite is mapped to a continuous curve in the hexplot that reflects the evolution of the quadratic form as we consider the portion with progressively larger distance threshold from the soma. F) A comparison of two populations of dendrites in the hexplot. Points in the white and shaded rhombi represent dendrites with thin and elongated overall shape, respectively, and points in the central hexagon represent dendrites with overall round shape.

In this paper, we limit ourselves to quadratic forms whose level sets define ellipsoids; see e.g. [9] for background on quadratic forms in general and [7] for a delightful connection to number theory. In particular, such quadratic forms allow us to quantify the directional spread of a graph in R3 . A quadratic form is given by a symmetric matrix, and the symmetric positive semi-definite 3-by-3 matrices provide a natural representation of directional and spatial dispersion in R3 ; for instance Schwartzman et al. [15] use the scatter matrix of axial data, whose eigenspectrum encodes both the mean orientation and the concentration of diffusion directions at each point in a spatial lattice. More generally, Schwartzman [14] develops log-normal distributions and geometric averaging operations on the cone of symmetric positive definite matrices, furnishing rigorous tools for statistical inference—including confidence regions and hypothesis tests—on populations of such quadratic forms, while respecting their positive-definiteness constraint. To visualise the results, we introduce the hexplot model for the family of quadratic forms defined by positive semi-definite 3-by-3 matrices.1 We equip this model with a metric structure obtained by conflating the Fisher metric on the standard triangle and its centrally reflected image. Using this methodology, we construct unbiased descriptors of dendritic morphology that are invariant under rigid motion and scaling. In addition, we use quadratic forms to recover the hierarchical organisation that distinguishes main from side branches. Outline. Section 2 introduces the mathematics of quadratic forms and explains how we use them to measure the directional spread of a geometric graph in R3 . Section 3 explains

1 Using quadratic forms to measure directional spread can be generalised to higher dimensions, the hexplot model is however special to 3-dimensional space.

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                          XX:3

the hexplot model that visualizes the quadratic forms, including the metric defined on it, which quantifies the difference between two such forms. Section 4 uses the quadratic forms to decompose a tree into paths, and to visualize the directional spread as a function of the distance from its root. Finally, Section 5 concludes the paper by mentioning open questions and research directions.

2      Squared Distance in 3 Dimensions The average squared distance from a collection of planes in R3 is given by a quadratic form whose level sets are ellipsoids; see [8] for a general discussion of ellipses and ellipsoids. We begin by introducing the relevant mathematical formalism and follow up by demonstrating how to use quadratic forms to measure the directional spread and length of a geometric graph in R3 . The main motivating application is the study of neuronal morphologies.

2.1      Mathematical Background Consider an ellipsoid with axes of lengths 0 < 2a ≤ 2b ≤ 2c in R3 . Assuming standard position, its axes align with the Cartesian coordinate axes in the same sequence, and the points of the ellipsoid have coordinates x1 , x2 , x3 that satisfy

x21 /a2 + x22 /b2 + x23 /c2 = 1.                                                         (1)

The ellipsoid is called an oblate spheroid if a < b = c, a prolate spheroid if a = b < c, and a sphere if a = b = c. With some tolerance for the exact lengths, we will call the corresponding kinds of ellipsoids thin, elongated, and round, in this sequence. We also allow for degenerate cases, in which the extreme elongated ellipsoid is an elliptic cylinder if a ≤ b < c = ∞, and the extreme thin ellipsoid is a pair of planes if a < b = c = ∞. We call the left-hand side of (1) a quadratic form and the points for which it evaluates to 1 the corresponding ellipsoid. Without insisting on the alignment of the axes but still centering the ellipsoid at the origin, we can write the quadratic form in matrix notation:                    A D F           x1 f (x) = xT · Q · x = [ x1 x2 x3 ] ·  D B E  ·  x2                                  (2) F E C           x3 = Ax21 + Bx22 + Cx23 + 2Dx1 x2 + 2Ex2 x3 + 2F x1 x3 .                              (3)

Without loss of generality, we may assume that the matrix is symmetric, and to specify an ellipsoid, it needs to be positive semi-definite; that is: f (x) ≥ 0 for all x ∈ R3 . We construct quadratic forms from planes that pass through the origin in R3 . Letting u ∈ S2 be the unit normal of such a plane, the squared distance of x ∈ R3 from this plane is 2                                  ⟨x, u⟩ = xT · u · uT · x = xT · u · uT · x,                                                (4)

in which the outer product, u · uT , is a positive semi-definite matrix as in (2). Viewing the matrix as a linear transformation, there are generically three solutions to Q · x = λx, with λ ∈ R and x ≠ 0, referred to as the eigenvalues and the corresponding unit eigenvectors of the matrix; see standard texts in linear algebra, e.g. [16]. Because Q is positive semi-definite, the eigenvalues are non-negative real numbers, denoted λ1 , λ2 , λ3 , with corresponding pairwise orthogonal eigenvectors, e1 , e2 , e3 ∈ S2 . The eigenvectors give the directions of the axes of √       √ the ellipsoid, and the eigenvalues specify their half-lengths, which are 1/ λ1 , 1/ λ2 , and

XX:4   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

√ 1/ λ3 . There is a connection between the eigenvalues and the trace of Q, which is the sum of diagonal entries, A, B, C, denoted tr Q = A + B + C. The trace defines a linear mapping; that is: tr (Q + R) = tr Q + tr R for any two 3-by-3 square matrices Q and R, and tr (c · Q) = c · tr Q for any scalar c. Importantly, the trace is equal to the sum of eigenvalues:

tr Q = λ1 + λ2 + λ3 ;                                                                            (5)

see e.g. [9]. If c ≥ 0 and Q and R are positive semi-definite, then so are Q + R and c · Q, and all their traces are non-negative. The polar of an ellipsoid, E, is the ellipsoid E ∗ that bounds the points y ∈ R3 satisfying ⟨y, x⟩ ≤ 1 for every x ∈ E. More specifically, if x0 is a point of E, then the plane of points y ∈ R3 with ⟨x0 , y⟩ = 1 touches E ∗ at a single point, y0 , and the plane of points x ∈ R3 that satisfy ⟨y0 , x⟩ = 1 touches E in the point x0 .2 Indeed, the

Figure 2: A pair of polar ellipsoids, together with the unit sphere with respect to which polarity is defined. The axes of the blue ellipsoid have half-lengths 1.8, 1.3, and 0.7, while the axes of the polar ellipsoid have half-lengths 1/1.8, 1/1.3, and 1/0.7, respectively.

relation is symmetric for non-degenerate ellipsoids; that is: E = (E ∗ )∗ . The polar ellipsoid inherits the symmetries of the ellipsoid, so it is not difficult to see that the half-lengths of the axes of E ∗ are the reciprocals of the half-lengths of the axes of E; see Figure 2 for an example. This implies that the polar of a sphere is a sphere, and the oblate and prolate spheroids are polar to each other. Throughout this paper, we will identify an ellipsoid with the quadratic form whose preimage of 1 is the ellipsoid.

2.2      The Eigenvalues Measure Directional Spread We use the squared distance from planes to construct a quadratic form that measures the directional spread of a collection of straight edges in R3 . Letting ai , bi ∈ R3 be the endpoints of the i-th edge in this collection, we set wi = ∥bi − ai ∥ and ui = (bi − ai )/wi .

2 This notion of polar body is heavily studied in the field of convex polytopes, but there seems to be a paucity in the literature on the special case of ellipsoids.

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                                  XX:5

The matrix of the quadratic form defined by these weights and vectors is X               Qsprd =     wi ui · uTi ,                                                                     (6) i

so fsprd : R3 → R defined by X                      fsprd (x) = xT · Qsprd · x =           wi xT ui · uTi x                                       (7) i

is the weighted sum of squared distances from the planes normal to the edges and passing through the origin of R3 . The weight of each plane being the length of the corresponding edge implies that subdividing an edge into shorter edges does not affect the function. The spread of directions is captured by the relations between the eigenvalues of Qsprd . Specifically, the ellipsoid is round, elongated, of thin if Qsprd has three roughly equal eigenvalues, one eigenvalue that is much smaller than the other two, or two eigenvalues that are much smaller than the third, respectively. Note that the polar of a round ellipsoid also tends to be round, while the polar of an elongated or thin ellipsoid tends to be thin and elongated, respectively. A quantitatively more concrete expression of this characterization of shape can be formulated using the tools to be introduced in Section 3.

2.3        The Trace Measures Length Besides the directional spread, we can use the eigenvalues to measure length, namely by taking their sum. Specifically, we have

▶ Theorem 2.1. Let ai , bi be the endpoints and wi = ∥bi − ai ∥ the length of the i-th edge in a collection in R3 , and fsprd (x) = xT · Qsprd · x the quadratic form defined by weighting the P squared distances from the normal planes with wi . Then tr Qsprd = i ∥bi − ai ∥.

Proof. Recall that Qsprd includes one weighted outer product per edge, with trace equal to the length of the edge. It follows that the i-th edge contributes wi = ∥bi − ai ∥ to the trace of Qsprd . The claimed equations follows from the addiditivity of the trace.                ◀

3      The Hexplot Thus far, the used quadratic forms are rotation and translation invariant. To get a scale- independent representation of ellipsoids—which stresses the relation between the eigenvalues rather than their absolute sizes—we normalize, combine with the polar information, and draw them as sextuples of points in a regular hexagon.3 We show that this map is a homeomorphism to the hexagon, establish a metric on the hexagon, and generalize box plots to support the statistical analysis of collections of ellipsoids.

3.1        Normalization and Antonelli Map If we order the eigenvalues of an ellipsoid, we get a vector in the non-negative octant of R3 . Normalizing this vector to unit length gives a point in the intersection of this octant and the

3 Instead of ordering the eigenvalues, we have the symmetric group of degree (the six permutations of three elements) acting on the coordinates of every point. Hence, the hexagon is a six-fold covering of the fundamental domain (a quadrangle) so that each triple of normalized eigenvalues maps to a sextuple of points in the hexagon, namely one point in each copy of the quadrangle.

XX:6   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

unit sphere, denoted S2 . Assuming λ1 , λ2 , λ3 are the eigenvalues of E, then 1/λ1 , 1/λ2 , 1/λ3 are the eigenvalues of the polar, E ∗ , and the normalized vectors are (                                                           ) ◦               λ1                   λ2                 λ3 Λ (E) = p 2                  ,p 2               ,p 2                   ;                            (8) λ1 + λ22 + λ23      λ1 + λ22 + λ23      λ1 + λ22 + λ23 (                                                                                      ) ◦   ∗                λ2 λ3                       λ1 λ3                       λ1 λ2 Λ (E ) = p 2 2                           ,p 2 2                       ,p 2 2                        , (9) λ2 λ3 + λ21 λ23 + λ21 λ22    λ2 λ3 + λ21 λ23 + λ21 λ22   λ2 λ3 + λ21 λ23 + λ21 λ22

in which we use set notation to indicate that each vector (of unordered components) corres- ponds to six conventional vectors whose components are ordered. We note a side-effect of the normalization that will become important shortly. Call E non-degenerate if all three eigenvalues are strictly larger than 0. For such an ellipsoid, the polar is unique, so both Λ◦ (E) and Λ◦ (E ∗ ) are unique points in S2 . This is no longer the case for a degenerate ellipsoid, which has at least one vanishing eigenvalue. Indeed, if λ1 = 0 and λ2 , λ3 are strictly positive, then Λ◦ (E ∗ ) = {1, 0, 0} independent of the values of λ2 and λ3 . To cope with this ambiguity, we say two degenerate ellipsoids, E and E ∗ , are polar to each other if E is the limit of a converging sequence of non-degenerate ellipsoids, En , such that E ∗ is the limit of the sequence of non-degenerate polar ellipsoids, En∗ . Keep however in mind that different sequences converging to E may give rise to different polar ellipsoids. For visualization purposes, we further map the unit vectors to points in the standard triangle, denoted ∆, which is the intersection of the non-negative octant of R3 with the plane of points that satisfy x1 + x2 + x3 = 1. Instead of further shortening the vectors, we prefer to use Antonelli’s map [2], which sends each coordinate of a unit vector to its square; that is:

λ21                λ22                λ23                                                          Λ(E) =                         ,               ,                    ;                              (10) λ2 + λ22 + λ23 λ21 + λ22 + λ23 λ21 + λ22 + λ23  1 λ22 λ23                   λ21 λ23                     λ21 λ22  Λ(E ∗ ) =                              ,                           ,                              , (11) λ22 λ23 + λ21 λ23 + λ21 λ22 λ22 λ23 + λ21 λ23 + λ21 λ22 λ22 λ23 + λ21 λ23 + λ21 λ22

but note that the formula for Λ(E ∗ ) works only if at least two of the λi are non-zero. The main attraction of this map is it connects the geodesic distance on the sphere and the Fisher metric on the standard triangle. Writing Λ(E) = {x1 , x2 , x3 }, it is customary to call x1 , x2 , x3 the barycentric coordinates of Λ(E) ∈ ∆. Keeping in mind that there are six permutations of the three coordinates, we note that ∆ is also a 6-fold covering of a smaller domain, namely a triangle in the barycentric subdivision of ∆, denoted Sd ∆; see Figure 3. Indeed, the coordinates of any two points in the interior of a triangle in Sd ∆ have the same ordering. Assuming for example the labeling of the vertices in Figure 3, then every point x1 A + x2 B + x3 C in the interior of the south-west triangle, ∆SW , satisfies x1 > x2 > x3 . The reciprocals are ordered the opposite way, 1/x1 < 1/x2 < 1/x3 , which implies that the corresponding point lies in the diagonally opposite triangle, which for ∆SW is the north-east triangle, ∆NE . We combine the representation of an ellipsoid and its polar ellipsoid into one using the Minkowski sum of the standard triangle and its central reflection: G = ∆ + (−∆), which is a regular hexagon, as displayed in Figure 3. Specifically, the pair (E, E ∗ ) is sent to the point Γ(E, E ∗ ) = Λ(E) − Λ(E ∗ ), or rather to a sextuple of points, one for each permutation of the eigenvalues of E. Recall that E is the polar ellipsoid of E ∗ , so Γ(E ∗ , E) = −Γ(E, E ∗ ) is well defined. The barycentric subdivision of ∆ extends to a division of G into six quadrangles, each the Minkowski sum of a triangle in Sd ∆ with the central reflection of the opposite

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                                  XX:7

Figure 3: The standard triangle, its central reflection, and the hexagon, each six-divided by the same three lines. An ellipsoid, E, maps to one point in each triangle of Sd ∆, −E ∗ maps to one point in each triangle of −Sd ∆, and (E, E ∗ ) maps to one point in each quadrangle in the six-division of the hexagon.

triangle in Sd ∆. The pair (E, E ∗ ) thus maps to one point in the hexagon, which after unfolding is six points, one in each quadrangle, or three points if each is shared by two quadrangles, or one point if it is shared by all six quadrangles. In the latter case, the point is Γ(E, E ∗ ) = {0, 0, 0}, which implies Λ(E) = Λ(E ∗ ) = { 13 , 13 , 13 }. Indeed, every pair maps to a unique point in each hexagon, but this requires a proof.

3.2     Bijectivity and Continuity To prove properties of the map Γ to the hexagon, we need to be precise about the class of ellipsoids that are mapped to the same point in G.

▶ Definition 3.1. Two pairs of possibly degenerate ellipsoids, (E, E ∗ ) and (D, D∗ ), have the same type if E and D have the same set of three normalized eigenvalues, and so do E ∗ and D∗ ; that is: Λ(E) = Λ(D) and Λ(E ∗ ) = Λ(D∗ ).

We visualize the space of types as a 2-dimensional submanifold with boundary in the shape of a hexagon in R6 , denoted E. Each point in E has six coordinates: the three barycentric coordinates of Λ(E) and the three barycentric coordinates of Λ(E ∗ ). The first three coordinates project E to ∆, and for almost all points of E, this projection is injective. The only exception to injectivity are three sides of the hexagon, which project to the three

XX:8   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

vertices of ∆. Symmetrically, the second three coordinates project E to ∆, but now to the points of the polar ellipsoids, and injectivity is violated by the other three sides of the hexagon. Indeed, these violations of injectivity are the main reason for defining Γ : E → G as a combination of two projections; that is: Γ(E, E ∗ ) = Λ(E) − Λ(E ∗ ). Importantly, this map is bijective, as we now prove.

▶ Lemma 3.2 (Bijectivity). The map Γ : E → G is bijective.

Proof. We begin by proving the injectivity of Γ while writing x = {x1 , x2 , x3 } and y = {y1 , y2 , y3 } for two points in ∆, and z = {z1 , z2 , z3 } for a point in G. Specifically, we show that for each z ∈ G, there is at most one x ∈ ∆ such that z = x − y, in which y = y(x) depends on x. For the six vertices of G, these are the six pairs of vertices of ∆. We can therefore exclude them from the remainder of the argument and assume that at least two of the coordinates of x are non-zero. Hence, x1 x2 x3 s=                                                                                          (12) x2 x3 + x 1 x3 + x 1 x2

is well defined, and assuming x = Λ(E), we have yi = s/xi for the coordinates of y = Λ(E ∗ ). Multiplying with xi we get a quadratic equation, x2i − zi xi − s = 0. It has either one or two solutions, and in the latter case, one solution is positive and the other negative. Since xi ≥ 0 we can discard the negative solution, so      q          xi = 12 zi + zi2 + 4s .                                                                  (13)

Fixing z in G, we thus get unique points x and y = y(x) in ∆ for each s. We now prove that there is at most one feasible choice for s. To this end consider the function that maps s to the sum of right-hand sides in (13) and its derivative:

3 q X Fz (s) = 21         zi2 + 4s;                                                             (14) i=1 3 ∂Fz       X       1 (s) =     p         ,                                                                  (15) ∂s       i=1 2 zi + 4s

in which we use z1 + z2 + z3 = 0 to get (14). Since x1 + x2 + x3 = 1, we need s such that Fz (s) = 1. Assuming s > 0, the derivative is well defined and positive, so Fz is strictly increasing. Hence, if there is a solution it must be unique, which implies injectivity. To see that Γ is also surjective, we show that there is a solution for each z ∈ G. Observe P        P               P that i |zi | = i |xi − yi | ≤ i (xi + yi ) = 2, so the sum of the three absolute coordinates of z is at most 2. For s = 0, 1, we therefore have

Fz (0) = 12 [|z1 | + |z2 | + |z3 |] ≤ 1;                                                    (16) Fz (1) ≥ 12 [2 + 2 + 2] = 3,                                                                (17)

and the intermediate value theorem implies the existence of an s such that Fz (s) = 1.           ◀

Before exploiting the bijectivity to get stronger properties of Γ, we present a technical lemma about the angle between the difference vectors defined by two ellipsoids, E, D, and their polars, E ∗ , D∗ . To formulate the claim, we let x = Λ(E), y = Λ(E ∗ ) and u = Λ(D),

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                        XX:9

v = Λ(D∗ ) be the corresponding points in ∆, and assume their coordinates are sorted such that x1 ≥ x2 ≥ x3 so y1 ≤ y2 ≤ y3 and u1 ≥ u2 ≥ u3 so v1 ≤ v2 ≤ v3 . Setting 1     1    1     1        1    1     1    1 =    +     +      and    =    +     +                                           (18) s    x1    x2   x3        t   u1    u2   u3 we see that the first relation agrees with (12), and the coordinates of y and v are yi = s/xi and vi = t/ui , for i = 1, 2, 3, respectively. ▶ Lemma 3.3 (Strong Cauchy–Schwarz Inequality). Let E, D be ellipsoids, E ∗ , D∗ their polars, and x = Λ(E), y = Λ(E ∗ ), u = Λ(D), v = Λ(D∗ ) the corresponding points in ∆. Then ⟨u − x, v − y⟩ ≤ 12 ∥u − x∥∥v − y∥, which for u ̸= x and v = ̸ y is equivalent to having an angle of at least 60◦ between the two vectors. Proof. The scalar product is the sum of three terms, each the product of two factors, which we call a matching pair: 3                       X                t    s ⟨u − x, v − y⟩ =     (ui − xi )      −      .                                           (19) i=1 ui   xi P3 The respective first factors add to zero, i=1 (ui − xi ) = 0, so two have the same sign and the third factor has a different sign. It is also possible that one or more of the three factors vanish, but we may think of this as a limiting case and assign signs arbitrarily. Accordingly, we call the factor with the unique sign long and the two factors with the same sign short. Similarly, the respective second factors add to zero, so we again have one long and two short factors. We claim that there are only two possible configurations of the six factors: 1. none of the three matching pairs has two factors with the same sign; or 2. exactly one of the three matching pairs has factors with the same sign, and these two factors are both short. We prove this property and show that each possible configuration satisfies the claimed inequality. To begin consider a matching pair whose factors have the same sign. If t ≤ s, then both factors are necessarily non-positive, and if s ≤ t, then they are necessarily non-negative. It follows that there cannot be two matching pairs of which one pair has two non-negative factors and the other has two non-positive factors. Suppose first that the two long factors have different signs, which implies that also the first short and the second short factors have different signs. If we match the long factors with each other—and therefore the short factors with each other—we get three matching pairs, none of which has factors with the same sign. This is configuration 1, the scalar product is non-positive, so the angle is at least 90◦ and therefore also at least 60◦ . On the other hand, if we match each long factor with a short factor, we get a contradiction because one matching pair has two non-negative factors while the other has two non-positive factors, which is impossible as argued above. Suppose second that the two long factors have the same sign, which implies that all short factors have the same sign. If we match long with long and short with short, we get three matching pairs all with factors of the same sign, which is again impossible because this would mean one matching pair with two non-negative and another with two non-positive factors. The only remaining case is that we match each long factor with a short factor, which leaves one matching pair of two short factors. This is configuration 2. Letting j be the corresponding index, we have " 3               #              2      " 3            2 # 2  1 X               2          t    s       1 X t          s (uj − xj ) ≤        (ui − xi )     and      −       ≤              −                 (20) 2 i=1                       uj   xj       2 i=1 ui       xi

XX:10   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

because both factors are short, which implies that in absolute value each is less than or equal to the corresponding absolute long factor. Hence, we have v                    v           u       3              u 3               t   s      u 1  X 2 u1 X t         s       1 (uj − xj )      −     ≤  t       (ui − xi ) · t           −       = ∥u − x∥∥v − y∥. (21) uj   xj       2 i=1                2 i=1 ui     xi      2

But this is the only positive term in (19), so ⟨u − x, v − y⟩ ≤ 12 ∥u − x∥∥v − y∥, as claimed.    ◀

We now go beyond bijectivity and prove that Γ and Γ−1 are both continuous. To this end, we use the Euclidean metric in R3 to measure distances in ∆ and G, and the Euclidean metric in R6 to measure distances in E. For points x, y, u, v ∈ ∆, we therefore write q 2          2 dE ((u, v), (x, y)) = ∥u − x∥ + ∥v − y∥ .                                          (22)

Letting z = x − y and w = u − v be the corresponding points in G, we note that ∥w − z∥ ≤ ∥u − x∥ + ∥v − y∥ by the triangle inequality, and dE ((u, v), (x, y)) ≤ ∥u − x∥ + ∥v − y∥ because the square root function is concave.

▶ Theorem 3.4 (Bi-Lipschitz Homeomorphism). The map Γ : E → G is a bi-Lipschitz homeo- morphism, in which Γ and Γ−1 are both Lipschitz continuous with constant 2.

Proof. By Lemma 3.2, Γ is bijective, so Γ−1 exists. To see the Lipschitz continuity of Γ, consider ellipsoids E, D, and write x = Λ(E), y = Λ(E ∗ ), u = Λ(D), v = Λ(D∗ ) as well as z = x − y, w = u − v. We have ∥w − z∥ ≤ ∥u − x∥ + ∥v − y∥, and since the larger of the latter two distances is at least half of ∥w − z∥ and at most dE ((u, v), (x, y)), we get

∥w − z∥ ≤ 2dE ((u, v), (x, y)),                                                               (23)

as needed. To see the Lipschitz continuity of Γ−1 , we consider the triangle with vertices 0, u − x, v − y, and note that the edge opposite the vertex 0 has length ∥w − z∥. By Lemma 3.3, the angle at 0 is at least 60◦ , which implies

∥u − x∥ + ∥v − y∥ ≤ 2∥w − z∥.                                                                 (24)

The left-hand side of (24) is at least dE ((u, v), (x, y)), which implies that Γ−1 is Lipschitz continuous with constant 2.                                                                  ◀

▶ Remark. The continuity of Γ−1 can also be proven by appealing to a version of the Inverse Function Theorem, and thus without using Lemma 3.3. In particular, [12, Lemma A.19] asserts that a continuous and bijective map from a compact space to a Hausdorff space is a homeomorphism. Indeed, the space of types is closed since it includes the limits of pairs (xn , yn ) = (Λ(En ), Λ(En∗ )), and it is bounded because every pair satisfies ∥xn ∥ ≤ 1 and ∥yn ∥ ≤ 1. This proof from general principles does however not imply that Γ−1 is Lipschitz continuous.

3.3    Hexagonal Box Plots Letting a0 , a1 , . . . , an be an ordered sequence of real numbers, its box plot is a graphical representation of five of these numbers: minimum, first quartile, median, third quartile, and maximum. Assuming n = 4k, these are a0 , ak , a2k , a3k , and a4k . The traditional way of drawing it is an axes aligned rectangle that stretches vertically from the first to the third

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                                 XX:11

Figure 4: Left: the conventional box plot of an empirical distribution. Right: the hexagonal box plot, which combines three conventional box plots in one.

quartile, has a horizontal bar at the median, and whiskers down to the minimum and up to the maximum; see the left panel of Figure 4. For each ellipsoid, we get three eigenvalues and therefore three related box plots, which we combine by intersecting the boxes drawn on top of each other, centered at the shared midpoint of the three median lines, and rotated by 120◦ relative to each other; see the right panel of Figure 4. We call this the hexagonal box plot. ▶ Remark. It is possible that the three strips defining a hexagonal box plot intersect in a convex polygon with fewer than six sides. However, in this case an extreme quarter of the population is the same for all three eigenvalues, so we may as well assume that the missing side has contracted to a corner of the plot. In other words, the corresponding line cannot be far from this corner, which justifies we still call it a hexagonal box plot.

3.4    The Metric We use the Antonelli map once again, this time to define a metric on the hexagonal model of ellipsoid types by pulling back the geodesic distance on the unit sphere.

▶ Definition 3.5. The hexplot Fisher metric is the map dhex : G × G → R defined by

dhex (z, w) = dgeo (Λ◦ (E), Λ◦ (D)) + dgeo (Λ◦ (E ∗ ), Λ◦ (D∗ )),                               (25)

in which z = Γ(E, E ∗ ), w = Γ(D, D∗ ), and dgeo denotes the geodesic distance between points on the unit sphere.

To see that dhex is indeed a metric, we note that dhex (z, w) = 0 iff z = w, dhex (z, w) = dhex (w, z) for all z, w ∈ G, and dhex (z, w) ≤ dhex (z, p) + dhex (p, w) for a third point p ∈ G, simply because the triangle inequality holds for the geodesic distance on the sphere. ▶ Remark. The pull-back of the geodesic distance on an orthant of the sphere to the standard simplex of the same dimension is traditionally known as the Fisher information metric or the Fisher–Rao metric between discrete probability distributions; see e.g. [1]. It can alternatively be derived from the Shannon entropy by considering the Kullback–Leibler divergence [11],

XX:12   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

Figure 5: Left: an approximation of the Fisher–Voronoi tessellation of the origin and the midpoints of the six sides of the hexagon, together with five level sets each of the hexplot Fisher distance from these seven points. The shading of the rhombi indicates that there are two kinds: the white rhombi of thin or pancake-like polar ellipsoids and shaded rhombi of elongated or cigar-like polar ellipsoids. Right: an example population of dendritic structures, plotted using the Quadrix software [5]. The points range from elongated (inside the shaded rhombi) to round (in the central region of the hexagon). The sparse population in the white rhombi implies that thin polar ellipsoids are rare in this population.

which measures the information loss if an encoding optimized for a different distribution is used. This divergence behaves like a distance but is not symmetric and also violates the triangle inequality. Taking the divergence to the infinitesimal limit and measuring a path by integrating the infinitesimal steps along it, we obtain the Fisher information metric from the shortest paths between their endpoints.

The geometry of the hexplot Fisher metric is not immediately obvious, so we visualize it by drawing the Voronoi tessellation of the center—the point {0, 0, 0}—and the midpoints of the six sides of the hexplot; which are really only two points: { 21 , 12 , −1} for the white rhombi, and {− 12 , − 12 , 1} for the shaded rhombi; see the left panel of Figure 5. The overall shape of a dendrite is shared by the polar ellipsoid of the pair, and if the representing point lies in the regions of {0, 0, 0}, { 12 , 12 , −1}, and {− 12 , − 12 , 1}, then we may call this shape round, thin (or pancake-like), and elongated (or cigar-like), respectively. After unfolding, we have seven regions: the hexagon in the middle and six rhombi surrounding it. These regions look like convex polygons, but at closer inspection it seems that the arcs that separate the hexagon from the six rhombi are not entirely straight. The left panel of Figure 5 also show the level lines of the hexplot Fisher distance inside each region. Here the level lines of the center are remarkably close to circles, and only for larger radii the subtle adaption to a more hexagonal shape becomes visible.

4      Paths and Quadratic Forms

The quadratic forms can also be used to segment a dendritic structure into higher-level components than the edges, which includes the distinction between main trunk and side branches studied in this section. Assuming information about the local thickness at every vertex, we could construct the main trunk by repeatedly moving to the child with the maximum radius, and compute the side branches recursively. We consider another criterion that uses quadratic forms to make the choices.

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                                   XX:13

4.1     Path Decompositions A path is a linear sequence of edges in the tree, and it is maximal if it starts and ends at a leaf each. By a path decomposition we mean a collection such that each edge belongs to exactly one path. We do not allow two paths to pass through the same fork—even if the degree of that fork is four or larger—so we call a path decomposition minimal if every fork of degree k + 1 is interior to exactly one path and endpoint of k − 1 paths. We call a minimal decomposition hierarchical if there is exactly one maximal path and every other path starts at a fork and ends at a leaf. In such a decomposition, the maximal path is at the top of the hierarchy, all paths that start at interior vertices of the maximal path are its children, and the remaining paths are descendants further down the hierarchy. To construct a hierarchical path decomposition, we assume a distinguished leaf, r, called the root, and we direct each edge of the tree away from r. If the tree is the representation of a neuronal dendrite, r would be an artificially added node whose only child is the soma. We thus have a tree in the computer science sense: other than the root, each node has a unique parent, and the remaining adjacent nodes are its children. We construct the hierarchy top down and proceed greedily such that, given the starting point, Criterion: each selected path is to be as straight as possible. To quantify this criterion, let f (x) = xT · Q · x be the quadratic form that measures the directional spread of a path, and write (E, E ∗ ) for the corresponding pair of ellipsoids. This path is completely straight if Λ(E) = {0, 0, 1}. Setting Λ(E ∗ ) = { 12 , 12 , 0}, the corresponding point in the hexagon is Γ0 = {− 12 , − 12 , 1}. In the general case, we use the hexplot Fisher distance of Γ(E, E ∗ ) from Γ0 to quantify how much the path deviates from being straight. We need notation to describe the algorithm that computes the paths maximizing this criterion. For a node b of the tree, we write k(b) + 1 for its degree, b0 for the parent, and b1 , b2 , . . . , bk(b) for the children. For a given points a and b, we write fa,b (x) = xT · Qa,b · x for the quadratic form of the edge connecting the points, as defined in (6). While traversing the tree, the algorithm computes the optimizing path starting at any edge in the tree, and stores the last point and the quadratic form of this path at this edge. The algorithm is recursive, and we initially call it for the edge from the root, r, to its only child, r1 :

01 function Pre-order(a, b): initialize ℓ = b and Qℓ = Qa,b ; 02      for i = 1 to k(b) do (ℓi , Qi ) = Pre-order(b, bi ); Q = Qa,b + Qi ; 03         if dhex (Γ0 , Γ(E, E ∗ )) < dℓ then ℓ = ℓi ; Qℓ = Q; dℓ = dhex (Γ0 , Γ(E, E ∗ )) endif 04      endfor; store (ℓ, Qℓ ) at the edge from a to b and return (ℓ, Qℓ ).

The algorithm gathers enough information so that the entire path decomposition can be extracted in a single additional traversal of the tree: walk the path that starts at the root backward while labelling all its nodes, and recurse along the way to explore side paths at every fork. Importantly, for each such side path, its last node has already been computed and stored at its first edge. In summary, the decomposition that constructs paths greedily according to the straightness criterion runs in time linear in the number of nodes in the tree. Other reasonable criteria for decomposing into paths are to maximize length, maximize centrality, or possibly combine different criteria into a weighted compromize.

4.2     Evolving Quadratic Forms To probe the shape of a dendrite near the beginning, near the end, and in between, we evaluate the quadratic form at every distance from its root. Write D for the tree in R3 , r0 for

XX:14   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

its root, and dint : D → R for the map that sends each point y ∈ D to its intrinsic distance from r0 .

Figure 6: Evolution of the directional spread of the dentrites in Figure 1 (on the left) and some of the paths in a decomposition of one of these dendrites (on the right), for clarity we have stopped at depth 2.

Hence, Dt = d−1int [0, t] are the points connected to r0 by paths of length at most t, and we let ft (x) = xT · Qt · x be the quadratic form that measures the directional spread of Dt . By Theorem 2.1, the trace of Qt is the total length of this subtree. The corresponding ellipsoid is Et = ft−1 (1). The polar ellipsoid, Et∗ , is unique if Qt has at least two non-zero eigenvalues, and we set Λ(Et∗ ) = { 21 , 12 , 0} if Λ(Et ) = {0, 0, 1}. Accordingly, we introduce

gD : R+ → G defined by gD (t) = Γ(Et , Et∗ )                                                          (26)

for every t ≥ 0. It maps the tree to a curve that visualizes how the directional spread evolves as we move away from the root; see the left panel of Figure 6.4 It also makes sense to map individual paths in a decomposition of the tree to G; see the right panel of Figure 6. Let for example γ ⊆ D be the main path in the decomposition computed as described in Section 4.1; that is: the path that begins at r0 and ends at another leaf of the tree. The ellipsoid that corresponds to the first edge in γ is thin, with Λ(E) = {0, 0, 1} and Λ(E ∗ ) = { 12 , 21 , 0}. The corresponding point in G is Γ0 = {− 21 , − 12 , 1}, which unfolds into three points, each shared by two quadrangles in the six-division of G. The image of gγ : R+ → G, is therefore a curve that starts at Γ0 in G.

4.3      Curves without Cusps When we draw a curve within a single quadrangle of the six-division, its tangent vector gets reflected whenever the curve hits a side shared with a neighboring quadrangle. The drawing is still continuous but has cusps needed to prevent entering other quadrangles. This motivates us to draw the full hexagon and to prove that the image of gγ is differentiable if γ is a generically smooth path in R3 .

4 Since each pair of ellipsoids, (Et , Et∗ ), maps to six points, we get six curves in G. Any one of them will not necessarily be contained within the fundamental domain of G. This is indeed the main reasons we use the hexagon—and not merely one of the quadrangles—since the former avoids sudden changes of direction when the curve is about to leave a quadrangle.

Bokor Bleile, Cortinovis, Edelsbrunner, Uka                                                             XX:15

We begin by adapting the quadratic form to the smooth case. Let γ : [0, L] → R3 be an arc-length parametrization of a regular smooth path, i.e. the unit tangent, T (s), is defined for every s ∈ [0, L]. We then introduce the quadratic form of such a path: ▶ Definition 4.1. Let γ : [0, L] → R3 be the arc-length parametrization of a regular smooth path. Then Z L  Qsprd (γ) =      T (s) · T (s)T ds                                                  (27) s=0

and the corresponding quadratic form defined by fγ (x) = xT · Qsprd (γ) · x measures the directional spread of the path. To see that this is a sensible definition, consider a partition 0 = s0 < s1 < . . . < sn = L of [0, L], write φn : [0, L] → R3 for the polygonal path with vertices γ(si ) for 0 ≤ i ≤ n, and say a sequence of such polygonal paths rectifies γ if the length of the longest edge goes to zero and the length of the paths converges to the length of γ. Importantly, the limit of the matrices whose corresponding quadratic forms measure the directional spread of the polygonal paths is the matrix defined in (27):

limn→∞ Qsprd (φn ) = Qsprd (γ).                                                            (28)

Assuming the curvature of γ is non-zero at s, we can define the unit normal, N (s), and the unit binormal, B(s); see e.g. [6]. These two vectors, together with the unit tangent vector, T (s), form an ortho-normal system classically referred to as the Frenet–Serre frame of γ and s, and a singular point is where this frame is not defined. We call γ tame if the set of singular points is finite. For each 0 ≤ t ≤ L, write γt for the portion of the path from γ(0) to γ(t), set Qt = Qsprd (γt ), write (Et , Et∗ ) for the corresponding pair of ellipsoids, and define gγ (t) = Γ(Et , Et∗ ). Our goal is to prove that under the tameness assumption the image of gγ drawn in the hexplot has no cusps. ▶ Lemma 4.2. Let γ : [0, L] → R3 be the arc-length parametrization of a tame path in R3 . Then the image of gγ : (0, L) → G is the trajectory of six continuously differentiable curves. Proof. By the fundamental theorem of calculus, Qt : [0, L] → R3×3 is a smooth family of symmetric bilinear forms. Moreover, its eigenvalues assemble in three continuously differentiable maps δi (t) : [0, L] → R, for i = 1, 2, 3; see [10, Chapter II, § 6.8]. If t > 0 then Qt ̸= 0, and hence δi (t) > 0 for at least one i, so we can then normalize to obtain a curve in ∆. Furthermore, by the tameness assumption at least two of the eigenvalues are non-zero. It follows that none of the associated ellipsoids maps to a vertex of ∆, so the polar ellipsoid is uniquely defined for every s ∈ (0, L). By composing with Γ : ∆ → G, we obtain a continuously differentiable map, and taking into account the permutations of δ1 , δ2 , δ3 yields the image of the map gγ : (0, L) → G and shows the claim.                                     ◀

5      Discussion Motivated by the study of phenotypes of neuronal dendrites, we show how to use quadratic forms to measure the morphology of rooted trees in 3-dimensional space, and how to visualize the results in what we call the hexplot of ellipsoid types. Indeed, we consider the introduction of the hexplot together with its Fisher metric as the main contribution of this paper. The reported work suggests directions for further inquiry and raises yet open questions. We list them in the order of increasing generality.

XX:16   Quadratic Forms for Measuring Geometric Trees in 3-dimensional Space

Can we use quadratic forms to probe additional features of the dendritic phenotype, such as the chirality of paths, and the correlation between neighboring neurons? The hexplot reflects the relative size of eigenvalues and deliberately ignores absolute size and the direction of the eigenvectors. Are there elegant ways to add this information without substantially increasing the complexity of the visualization? How does the framework introduced in this paper extend to more general settings, such as quadratic forms defined by matrices that are not necessarily positive semi-definite, and to dimensions beyond three? A broad quest that relates to the second of the above items is the mathematical description of complex traits of neuronal dendrites, such as the uptake of information or other resources that may guide the way they explore the ambient space. Can quadratic forms and the related tools developed in this paper contribute to this effort of rationalizing scientific data?

References 1    S. Amari and H. Nagaoka. Methods of Information Geometry. Amer. Math. Soc., Providence, Rhoode Island, 2000. 2    P.L. Antonelli et al. The geometry of random drift i-vi. Adv. Appl. Probab. 9-12 (1977-80). 3    G.A. Ascoli, D.E. Donohue and N.M. Halavi. NeuroMorpho.Org: a central resource for neuronal morphologies. J. Neurosci. 27 (2007), 9247–9251. 4    R. Benavides-Piccione et al. Differential structure of hippocampal CA1 pyramidal neurons in the human and mouse. Cerebral Cortex 30 (2020), 730–752. 5    Y. Bokor Bleile and E. Cortinovis. Quadrix. Inst. Sci. Techn. Austria, Klosterneuburg, Austria, 2026. DOI: 10.15479/AT-ISTA-21971. 6    J.W. Bruce and P.J. Giblin. Curves and Singularities: a Geometrical Introduction to Singularity Theory. Second edition, Cambridge Univ. Press, Cambridge, England, 1992. 7    J.H. Conway. The Sensual (quadratic) Form. The Carus Mathematical Monographs 26, MAA Press, Amer. Math. Soc., Providence, Rhode Island, 1997. 8    D. Hilbert and S. Cohn-Vossen. Geometry and the Imagination. Translated by P. Nemenyi, AMS Chelsea Publ., Providence, Rhode Island, 1952. 9    R.A. Horn and C.R. Johnson. Matrix Analysis. Second edition, Cambridge Univ. Press, Cam- bridge, England, 2013. 10    T. Kato. Perturbation Theory for Linear Operators. Second edition, Springer-Verlag, New York, New York, 1976. 11    S. Kullback and R.A. Leibler. On information and sufficiency. Ann. Math. Stat. 22 (1951). 79–86. 12    J.M. Lee. Introduction to Smooth Manifolds. Graduate Texts in Mathematics 218, Springer, New York, New York, 2003. 13    H. Mohan et al. Dendritic and axonal architecture of individual pyramidal neurons across layers of adult human neocortex. Cerebral Cortex 25 (2015), 4839–4853. 14    A. Schwartzman. Lognormal distributions and geometric averages of symmetric positive definite matrices. Int. Stat. Rev. 84 (2016), 456–486. 15    A. Schwartzman, R.F. Dougherty and J.E. Taylor. False discovery rate analysis of brain diffusion direction maps. Ann. Appl. Stat. 2 (2008), 153–175. 16    Introduction to Linear Algebra. Wellesley-Cambridge, Wellesley, Massachusetts, 1993. 17    J.F. Watson et al. Human hippocampal CA3 uses specific functional connectivity rules for efficient associative memory. Cell 188 (2024), 501–514.

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
