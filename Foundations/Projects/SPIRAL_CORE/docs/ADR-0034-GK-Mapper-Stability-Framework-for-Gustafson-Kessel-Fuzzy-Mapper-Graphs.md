---
id: ADR-0034
title: "ADR-0034: GK-Mapper: A Stability Framework for Gustafson-Kessel Fuzzy Mapper Graphs"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.GkMapper
rust_module: echonomics_engine::gk_mapper
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0034: GK-Mapper: A Stability Framework for Gustafson-Kessel Fuzzy Mapper Graphs

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for GK-Mapper: A Stability Framework for Gustafson-Kessel Fuzzy Mapper Graphs.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0034
Title: GK-Mapper: A Stability Framework for Gustafson-Kessel Fuzzy Mapper Graphs
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

GK-Mapper: A Stability Framework for Gustafson-Kessel Fuzzy Mapper Graphs Annesha Sena , Shivam Singha , S. P. Tiwaria,∗ a Department of Mathematics & Computing, Indian Institute of Technology (ISM), arXiv:2606.21671v1 [math.AT] 19 Jun 2026

Dhanbad-826004, India

Abstract Topological Data Analysis is the field that uses algebraic topology for data analysis, with the Mapper Algorithm that studies the structure of data af- ter reducing the dimension of the dataset. There are several variants of Mapper, like Conventional Mapper, F-Mapper, and Shape Fuzzy-C Means Mapper. In this article, we extend the idea of the Shape Fuzzy-C Means Mapper graphs by introducing the Gustafson-Kessel Fuzzy Mapper Graphs algorithm, which replaces the spherical covers by ellipsoidal cover, which is useful for high dimensional datasets because real world datasets are not al- ways symmetrical or spherical. We then develop the stability framework for the graphs produced by Gustafson Kessel Mapper graph and Shape Fuzzy C-Mean Mapper graph. We prove that the memberships depend smoothly on the fuzzifier, establish a precise condition for the existence of edges, and show that the graph is locally stable under small perturbations. We describe the critical event structure of graph changes in terms of threshold crossings of the membership functions and show that the graph is constant between consecutive critical events. When the threshold-crossing set is finite, this yields an eventual freezing threshold. Finally, we show empirically that the Gustafson Kessel Mapper is more stable than the Shape Fuzzy C Means for high-dimensional complex datasets. Keywords: Gustafson Kessel Mapper, Gustafson Kessel FCM, Fuzzy Clustering, Mapper Algorithm, Topological Data Analysis, Stability Analysis, Fuzzifier Parameter, Simplicial Complex,

∗ Corresponding author. Email addresses: 23dr0026@iitism.ac.in (Annesha Sen), 24dr0172@iitism.ac.in (Shivam Singh), sptiwari@iitism.ac.in (S. P. Tiwari)

1. Introduction The Mapper algorithm [24] has become one of the tools in Topological Data Analysis for analysing the shape of complex, high-dimensional data. It transforms datasets into a graph, which is a 2D/3D representation of the datasets. It provides the summaries of connectivity, loops, and hidden geometric relationships that sometimes ML methods miss [9, 6]. It has been applied in various fields like bioinformatics, neuroscience, social networks, and many more. Some applications can be found in [16, 19, 20, 21, 22, 28]. Since it has so many applications, selecting its appropriate parameters is still a challenging task. Particularly, the choice of filter function, cover resolution, and overlap parameters highly influences the resulting graph. Several works have addressed this issue by studying stability conditions and robustness properties of Mapper graphs [1, 6, 7, 12]. The conventional Mapper [24] uses hard partitioning and rigid inter- val covers, but for real-world datasets, boundaries cannot always be rigid, and so Fuzzy variants of Mapper have been proposed. The F-Mapper al- gorithm [4] uses Fuzzy C-Mean (FCM) to generate overlapping covers. It creates soft cover rather than hard ones, which becomes more useful for real- world datasets. But it also contains the same number of parameters; the filter function, the fcm cover that requires the number of clusters and mem- bership factor and the dbscan algorithm. To limit these parameters, The Shape Fuzzy C-Mean (SFCM) algorithm [5] combines FCM directly with the Mapper nerve construction. Thus, in this method, we only need the number of clusters and the threshold condition. Although it solves a lot of our purpose, it again has two major limitations: The first one is that it uses FCM to generate cover, which assumes spheri- cal cluster geometry. In many real world datasets, biological structures, and medical image clusters are non-spherical, and the Euclidean cover misrepre- sents the true cluster boundaries. Second, the stability of the SFCM graph with respect to the fuzzifier parameter m has not been studied. It is typi- cally considered as m = 2 without theoretical justification [2], and without knowing whether small changes in m can affect the graph structure. We address both limitations. We propose the Gustafson-Kessel Fuzzy Mapper Graphs (GK Mapper) algorithm, which replaces the Euclidean FCM cover of SFCM with a cover generated by the Gustafson-Kessel FCM (GK-

2

FCM) algorithm [15, 2], which considers an ellipsoidal structure for the clus- ter. We then develop a stability framework for GK Mapper and empirically show that GK-Mapper often performs well across several aspects for which theoretical foundations are developed in this paper. The contributions of the paper are as follows:

1. We propose the GK-Mapper algorithm, which modifies the cover con- struction of the SFCM algorithm with the Gustafson-Kessel-based cover.

2. We characterise the edgeless-zone boundary by the critical threshold tcrit (m) = maxi maxj̸=k min{uij (m), uik (m)}, above which the graph becomes edgeless.

3. We then prove a local structural stability theorem with a computable stability radius r∗ . This radius indicates how far one can vary a chosen value of m, obtaining the same Mapper graph.

4. We show that the GK-Mapper graph can change only at threshold- crossing events and is constant between consecutive critical events. We further provide a crossing-count bound for the number of critical events and recover the estimate |T | ≤ nc under a single-crossing condition.

5. We empirically show that GK-Mapper performs well in all these cases as compared to SFCM.

The rest of this paper is organised as follows. Section 2 introduces the necessary background and definitions. Section 3 proposes the GK-Mapper algorithm. Section 4 establishes membership regularity for both FCM and GK-FCM. Section 5 presents the main stability framework. Section 6 pro- vides empirical validation on synthetic and real-world datasets. Section 7 discusses the implications and limitations of the framework. Section 8 con- cludes the paper.

2. Background Fuzzy set theory [29] extends classical set membership by allowing each element to belong to a set with a degree in the interval [0, 1] rather than in a strictly binary manner. It is useful for real-world data, where cluster bound- aries are often vague, overlapping, or uncertain. In clustering, such partial

3

memberships provide a natural way to model ambiguity at the interfaces between groups. The Fuzzy C-Mean (FCM) algorithm [3] is one of the most widely used fuzzy clustering methods. It assigns memberships to all clusters and de- termines cluster centres by minimising a weighted objective function. This soft partitioning makes FCM more flexible than hard partitioning clustering methods, especially when the data contains overlap or gradual transitions between groups. In the standard formulation, however, FCM relies on the Euclidean distance, which implicitly favours approximately spherical clusters. This section provides a brief overview of the definitions and notations related to the GK-FCM, Mapper, and SFCM algorithms [2, 15, 24, 5].

Definition 1 (Gustafson-Kessel FCM [15, 2]). The Gustafson-Kessel FCM (GK-FCM) algorithm addresses the spherical-cluster limitation of the stan- dard FCM by replacing the Euclidean metric with a cluster-adaptive Mahalanobis- type distance [11]. Each cluster is allowed to adapt its shape according to the local covariance structure of the data, making GK-FCM particularly suitable for datasets with ellipsoidal or directionally stretched clusters. This adap- tive geometry provides the foundation for the cover used in GK-Mapper. Further detail on clustering variants and their applications can be found in [2, 17, 26, 27].

Definition 2 (Mapper Algorithm [24]). Let X be a dataset, let f : X → Rd be a continuous filter function, and let U = {Ua } be an open cover of f (X). For each Ua ∈ U, apply a clustering algorithm to the preimage f −1 (Ua ), producing clusters {Ca,1 , Ca,2 , . . .}. The Mapper complex is the simplicial complex where each cluster Ca,i is a node and two nodes are connected by an edge whenever Ca,i ∩Cb,j ̸= ∅. More generally, a k-simplex is added whenever k+1 clusters have a common nonempty intersection.

Definition 3 (F-Mapper Algorithm [4]). Let X be a finite dataset in a metric space, and let f : X → R be a continuous filter. F-Mapper partitions f (X) into N fuzzy clusters by FCM, producing membership degrees uij ∈ [0, 1] satisfying N P j=1 uij = 1. For a threshold t ∈ [0, 1], define fuzzy cover intervals Uj = {f (xi ) : uij ≥ t} and pullback sets f −1 (Uj ). Each pullback set is clustered into connected components, and the F-Mapper complex is the nerve of these components.

4

Definition 4 (SFCM Algorithm [5]). Let X = {x1 , . . . , xn } ⊂ Rp , c ≥ 2, m > 1, and t ∈ (T0 , T1 ], where T0 = mini,j uijPandPT1 = mini maxj uij . SFCM minimises the FCM objective Jm (U, V ) = ni=1 cj=1 (uij )m ∥xi −vj ∥2 , producing clusters Cj (t) = {xi : uij (m) ≥ t}. The SFCM graph is Gt (m) = (V, E(m)) where V = {1, . . . , c} and E(m) = {(j, k) : j ̸= k, Cj ∩ Ck ̸= ∅}. The complete algorithm is given in Algorithm 2.

3. GK-Fuzzy Mapper Algorithm The SFCM algorithm uses the Euclidean-distance assumption from FCM, which naturally favours spherical cluster shapes. However, many real-world datasets contain clusters that are elongated, ellipsoidal, or otherwise non- spherical. To address this limitation, we introduce the Gustafson Kessel Mapper(GK-Mapper) algorithm. This method removes the spherical con- straint by replacing the Euclidean cover used in SFCM with a geometry- adaptive cover derived from the Gustafson-Kessel FCM algorithm [15]. Com- pared with SFCM, GK-Mapper uses the same number of parameters. The only change is that Euclidean distance is replaced by a cluster-adaptive dis- tance [2, Theorem 22.1]. The detailed computational procedure is presented in Algorithm 3. The algorithm follows the standard fuzzy clustering framework, where cluster centres and memberships are iteratively updated using the Gustafson-Kessel adaptive distance. After convergence, the fuzzy memberships are thresh- olded to construct the adaptive cover, and the Mapper graph is obtained by connecting clusters with nonempty intersections.

4. Membership Regularity Before developing the stability framework, we establish that the GK- FCM membership function depends smoothly on the fuzzifier parameter m along the optimisation path. This regularity is the foundation on which all subsequent results rest. The following proposition is stated for the moving- centre setting, where the centres vj (m) and (in the GK-Mapper case) the adaptive matrices Aj (m) depend on m. The arguments depend only on the composition structure of the membership formula, and not on the specific distance used. Before stating the main regularity result, we fix the standing assumptions that govern Sections 4 and 5.

5

Assumption 1 (H1-Continuity). For each i ∈ {1, . . . , n} and j ∈ {1, . . . , c}, the membership function m 7→ uij (m) is continuous at m0 .

Assumption 2 (H2-C 1 Optimisation Path). The optimisation path m 7→ V (m) = {v1 (m), . . . , vc (m)} is C 1 on an open interval I ∋ m0 . In the GK- Mapper case, the adaptive matrices m 7→ Aj (m) are additionally C 1 on I for every j ∈ {1, . . . , c}. Furthermore, the non-degeneracy condition

dil (m0 ) > 0     ∀ i ∈ {1, . . . , n}, l ∈ {1, . . . , c}   (1)

holds, that is, no data point coincides with any cluster centre at m0 .

Proposition 1 (Membership Regularity Along the Optimisation Path). Let m 7→ V (m) = {v1 (m), . . . , vc (m)} be a C 1 path of cluster centres on an interval I ⊂ (1, ∞). In the GK-Mapper case, also assume that m 7→ Aj (m) is C 1 for every j ∈ {1, . . . , c}. Define ( ∥xi − vj (m)∥,                          SFCM, dij (m) = p (xi − vj (m))⊤ Aj (m)(xi − vj (m)), GK,

and assume dij (m) > 0 for all i, j and all m ∈ I. Set

dij (m)                       2 rijk (m) =           ,          b(m) =        , dik (m)                      m−1

and                                     c X Dij (m) =             rijk (m)b(m) . k=1

Then 1 uij (m) = Dij (m) satisfies:

(i) uij (m) ∈ (0, 1) for all m ∈ I;

(ii) uij (m) is of class C 1 on I; Pc (iii)    j=1 uij (m) = 1 for all i and m;

6

(iv) uij (m) is differentiable with

u′ij (m) = T1 (m) + T2 (m),

where                           c 2uij (m)2 X T1 (m) =              rijk (m)b(m) ln rijk (m), (m − 1)2 k=1 and T2 (m) contains the contribution coming from the motion of the centres and, in the GK-Mapper case, the adaptive matrices. More explicitly, for SFCM, c 2uij (m)2 X wijl SFCM T2    (m) =                   2 (xi − vl )⊤ v̇l , m − 1 l=1 dil (m)

whereas for GK-Mapper, c GK      2uij (m)2 X wijl T2 (m) = m − 1 l=1 dil (m)2                                              ⊤       1          ⊤ × (xi − vl ) Al v̇l − (xi − vl ) Ȧl (xi − vl ) , 2 with                            ( Dij (m) − 1, l = j, wijl = −rijl (m)b(m) , l = ̸ j.

Proof. Since dij (m) > 0 and the distance functions are C 1 in m under the stated assumptions, each ratio rijk (m) is strictly positive and C 1 . For m > 1, b(m) > 0, so each summand rijk (m)b(m) is positive and Dij (m) > 0. Since the term k = j equals 1 and c ≥ 2, we have Dij (m) > 1. Therefore uij (m) ∈ (0, 1). Next, each summand can be written as

rijk (m)b(m) = exp b(m) ln rijk (m) . 

Since both b(m) and ln rijk (m) are C 1 on I, it follows that Dij is C 1 . Hence −1 uij = Dij         C 1 on I. is alsoP The identity cj=1 uij (m) = 1 is the standard normalisation property of fuzzy memberships [2, Def. 5.1].

7

−1 Finally, differentiating uij = Dij gives ′ u′ij (m) = −uij (m)2 Dij (m).

Using b′ (m) = −2/(m − 1)2 and the chain rule, " d                                      2 rijk (m)b(m) = rijk (m)b(m) −  ln rijk (m) dm                                  (m − 1)2 # ṙijk (m) + b(m)             . rijk (m)

Therefore, c ′               2     X Dij (m) = −                rijk (m)b(m) ln rijk (m) (m − 1)2 k=1 c X                    ṙijk (m) + b(m)         rijk (m)b(m)             . k=1 rijk (m)

Substituting this expression into u′ij = −u2ij Dij′ gives the decomposition ′ uij (m) = T1 (m) + T2 (m). The stated forms of T2SFCM and T2GK follow by differentiating the corresponding distance functions and collecting the terms associated with each moving centre and adaptive matrix.

Corollary 1 (Non-monotonicity Along the Optimisation Path). Under the hypotheses of Proposition 1, each membership function uij (m) is C 1 on I. However, along the optimisation path, uij (m) is not necessarily monotone. Indeed, the derivative has the form

u′ij (m) = T1 (m) + T2 (m),

where T1 is determined by the fuzzifier-dependent exponent and distance ra- tios, while T2 contains the effect of centre motion and, in GK-Mapper, adaptive- matrix motion. Since T2 may have either sign, the sign of u′ij (m) is not de- termined by the distance ratios alone. Consequently, monotonicity of uij (m) cannot be assumed without additional restrictions on the optimisation path.

Proof. The result follows directly from the derivative decomposition in Propo- sition 1. The term T2 depends on v̇l and, in the GK-Mapper case, on Ȧl .

8

These quantities may vary in direction and magnitude along the optimisa- tion path. Hence T2 may be positive, negative, or zero, and no general sign condition for u′ij (m) follows from the membership formula alone. Therefore uij (m) need not be monotone on I. Remark 1. Proposition 1 and Corollary 1 apply to both SFCM and GK- Mapper. The only difference is the form of the distance function: SFCM uses Euclidean distances, while GK-Mapper uses cluster-adaptive Gustafson- Kessel distances. Hence, the subsequent stability results apply to both con- structions, with the GK-Mapper case including the additional contribution from the evolution of the adaptive matrices.

5. Main Results In this section, we present the main theoretical results that describe how the GK-Mapper graphs change as the fuzzifier m varies. These results iden- tify the parameter setting in which the graph carries structural information, establishes a local stability zone around any reference value of m, quantify graph variation under small perturbations, and describe the critical event structure of the graph along the moving centre optimisation path. We begin by characterising the Edgeless Zone (Section 5.1), where the graph has no edges. We then establish a Stability Zone (Section 5.2) in which the graph remains unchanged under small changes in m. We next analyse the Instability Zone (Section 5.3) and derive an upper bound on edge changes. Finally, we describe the Critical Event Structure (Section 5.4) and analyse when the graph eventually freezes beyond a finite threshold m∗∗ .

5.1. The Edgeless Zone A parameter pair (m, t) lies in the Edgeless Zone if Gt (m) has zero edges, then the graph carries no structural information. Theorem 1 establishes the necessary and sufficient condition for avoiding the Edgeless Zone. A visual illustration is provided in Fig. 1a. Theorem 1 (Edgeless Zone). Let Gt (m) be the GK-Mapper graph. Then Gt (m) has at least one edge if and only if  t ≤ max max min uij (m), uik (m) .         (2) i   j̸=k

Equivalently, Gt (m) has no edges iff t > maxi maxj̸=k min{uij (m), uik (m)}.

9

(a) Visual illustration of Theorem 1 for the                  (b) Visual illustration of Theorem 2 for the anisotropic ellipsoidal dataset at m0 = 2.0. The              anisotropic ellipsoidal dataset at m0 = 2.0 and critical threshold tcrit (m) separates the non-trivial        t = 0.2. The stability radius r∗ defines a local graph regime from the Edgeless Zone.                          interval where no membership value crosses t, so Gt (m) = Gt (m0 ). The flat edge-count paths con- firm the predicted local graph constancy.

Figure 1: Empirical illustrations of Theorems 1 and 2. Subfigure 1a shows the Edgeless Zone transition, while Subfigure 1b shows local graph stability around m0 = 2.0.

Proof. (⇒) Suppose Gt (m) contains an edge; then Cj ∩Ck ̸= ∅ for some j ̸= k. Let xi be a point in this intersection. Then uij (m) ≥ t and uik (m) ≥ t, so min{uij (m), uik (m)} ≥ t, giving (2). (⇐) If (2) holds, there exist i, j, k with j ̸= k such that uij (m) ≥ t and uik (m) ≥ t. Therefore xi ∈ Cj ∩ Ck and an edge (j, k) exists. We define tcrit = maxi maxj̸=k min{uij (m), uik (m)} as the critical thresh- old above which the graph enters the Edgeless Zone.

5.2. The Stability Zone After identifying the region where the graph becomes edgeless , we focus on the area where the graph structure is preserved under small perturba- tions of the fuzzifier m. Intuitively, if the membership values do not cross the threshold t, the induced cover and hence the graph topology remain un- changed. The following theorem gives a radius r∗ for which the graph remains unchanged for a chosen m. Its behaviour described is illustrated in Fig. 1b. Throughout Theorem 2, we assume

dil (m0 ) > 0,           ∀ i ∈ {1, . . . , n}, l ∈ {1, . . . , c},                     (3)

that is, no data point coincides with any cluster centre at m0 . This ensures that every distance denominator appearing in the proof is strictly positive. This is the standard non-degeneracy condition in FCM [2].

10

Moreover, for each i ∈ {1, . . . , n} and j ∈ {1, . . . , c}, let dij (m) denote the distance from xi to the cluster centre vj (m) under the relevant metric: ( ∥xi − vj (m)∥,                              SFCM, dij (m) = p                                                              (4) (xi − vj (m))⊤ Aj (m) (xi − vj (m)), GK-Mapper.

Define                                                     c dij (m)                          X rijk (m) =         ,         Dij (m) =             rijk (m)b(m) , dik (m)                          k=1 2                                 1 b(m) =         ,          uij (m) =                . m−1                             Dij (m) Note that rijj (m) ≡ 1, and therefore X Dij (m) = 1 +          rijk (m)b(m) . k̸=j

Theorem 2 (Local Stability Zone). Let m0 > 1 and t ∈ (0, 1) satisfy

uij (m0 ) ̸= t       for all i ∈ {1, . . . , n}, j ∈ {1, . . . , c}.

Assume the non-degeneracy condition (3) and suppose that the hypotheses of Proposition 1 hold on a neighbourhood of m0 . Then there exists r∗ > 0 such that Gt (m) = Gt (m0 )   whenever |m − m0 | < r∗ .            (5) Hence, the SFCM and GK-Mapper graphs are locally constant with respect to the fuzzifier parameter near every non-threshold value m0 . Proof. By Proposition 1, each membership function uij (m) is continuous, indeed C 1 , in a neighbourhood of m0 . Since uij (m0 ) ̸= t, define the positive threshold margin dgap ij := |uij (m0 ) − t| > 0.

By continuity of uij at m0 , there exists rij > 0 such that

|uij (m) − uij (m0 )| < dgap ij           whenever |m − m0 | < rij .

Since there are only finitely many pairs (i, j), define

r∗ :=       min        rij . 1≤i≤n, 1≤j≤c

11

Then r∗ > 0. Hence, for every m satisfying |m − m0 | < r∗ , we have

|uij (m) − uij (m0 )| < |uij (m0 ) − t|     for all i, j.

Therefore uij (m) and uij (m0 ) lie on the same side of the threshold t. Conse- quently, 1[uij (m) ≥ t] = 1[uij (m0 ) ≥ t]    for all i, j. Thus the thresholded cluster sets Cj (t, m) = {xi : uij (m) ≥ t} remain un- changed for all j. Since the edge set of Gt (m) is determined by the nonempty intersections Ca (t, m) ∩ Cb (t, m) ̸= ∅, the edge set also remains unchanged. Therefore Gt (m) = Gt (m0 ) whenever |m − m0 | < r∗ . Remark 2. The proof above establishes the existence of a local stability ra- dius. A conservative computable estimate can be obtained from the deriva- tive formula in Proposition 1. Let J = [m0 − tol, m0 + tol] be a compact neighbourhood contained in the interval of regularity, and set Mij (tol) := sups∈J |u′ij (s)|. By Proposition 1, u′ij is continuous, so Mij (tol) < ∞. The mean value theorem gives |uij (m) − uij (m0 )| ≤ Mij (tol)|m − m0 |. Hence, one may take                                                  ∗               |uij (m0 ) − t| r = min tol,                       , i,j          Mij (tol) with the convention that if Mij (tol) = 0, the corresponding term is taken as tol. Remark 3. Theorem 2 establishes that both GK-Mapper and SFCM graphs are locally stable near any non-threshold fuzzifier value m0 , with computable stability radii r∗,GK and r∗,SFCM . Whether GK-Mapper or SFCM achieves a larger stability radius depends on the underlying cluster geometry through the distance ratios, the rates of evolution of the shape matrices and many other factors. For complex datasets, the empirical evidence in Section 6 suggests that GK-Mapper can produce larger stability regions than SFCM.

5.3. The Instability Zone Having established local stability, we now quantify how many edges can change when the fuzzifier is perturbed from m to m+h. For each membership entry, define the threshold indicator

indij (m) = 1[uij (m) ≥ t] .                    (6)

12

For a pair of clusters (a, b), define the witness count n X Iab (m) =         india (m) indib (m).               (7) i=1

Thus, Iab (m) counts the number of data points simultaneously belonging to the thresholded clusters a and b. Hence, the edge (a, b) exists in Gt (m) if and only if Iab (m) > 0. This behaviour is illustrated in Fig. 2a. Lemma 1. An edge (a, b) changes between Gt (m) and Gt (m + h) if and only if Iab (m) Iab (m + h) = 0 and Iab (m) + Iab (m + h) > 0. Consequently, Gt (m) ̸= Gt (m + h) if and only if the above condition holds for at least one pair (a, b). Proof. The edge (a, b) exists exactly when Iab (m) > 0. Therefore, the edge changes between m and m + h precisely when one of the two witness counts Iab (m) and Iab (m + h) is positive and the other is zero, which is equivalent to the stated conditions. The graph changes if and only if at least one edge changes. Theorem 3 (Edge-Change Bound). Define the threshold-crossing set                                    Sh = (i, j) : uij (m) − t uij (m + h) − t < 0 . For each i, let Ki = |{j : (i, j) ∈ Sh }|. Then the number of edge changes satisfies n                     X    Ki |Echg | ≤            + Ki (c − Ki ) ≤ (c − 1)|Sh |.      (8) i=1 2 Proof. An edge (a, b) can change only if, for some data point xi , at least one of the indicators india or indib changes between m and m + h. Such a change can occur only when (i, a) ∈ Sh or (i, b) ∈ Sh . Fix a data point xi and suppose that Ki of its membership entries cross the threshold. The affected cluster pairs are of two types. First, both indices Ki may belong to the crossing set, giving at most 2 pairs. Second, exactly one index may belong to the crossing set, giving at most Ki (c − Ki ) pairs. Hence the number of edge pairs affected by xi is at most K2i +Ki (c−Ki ). Summing over all data points gives the firstPinequality. Since K2i + Ki (c − Ki ) ≤ 

Ki (c − 1), summing yields (c − 1) i Ki = (c − 1)|Sh |.

13

(a) Visual illustration of Theorem 3 for the                (b) Visual illustration of Theorem 4 for the t- anisotropic ellipsoidal dataset. Edge changes in the        superlevel cluster co-occurrence graph. Graph t-superlevel cluster co-occurrence graph are con-           changes occur only at critical fuzzifier values satis- trolled by membership threshold crossings between           fying uij (m) = t. The edge-count paths are piece- m = 2.0 and m = 2.2. The SFCM and GK-Mapper                 wise constant, with the frozen regime appearing af- graphs remain unchanged, confirming that the the-           ter m∗∗ . orem gives a conservative upper bound on graph instability.

Figure 2: Empirical illustrations of Theorems 3 and 4. Subfigure 2a shows the conserva- tive instability bound through membership threshold crossings, while Subfigure 2b shows critical-event structure and eventual graph freezing.

5.4. Critical Events and Eventual Freezing Having shown that edge changes are controlled by membership threshold crossings, we now describe the critical-event structure of the graph as the fuzzifier m varies. Since the memberships are evaluated along the optimisa- tion path, they need not be monotone in m. Therefore, a membership value may cross the threshold t more than once. We formulate the result in terms of the actual threshold-crossing events. Let I ⊂ (1, ∞) be the interval of fuzzifier values under consideration. Define the critical-event set T = {m ∈ I : ∃ (i, j) such that uij (m) = t} . For each pair (i, j), define the threshold-crossing count Nij (t) = # {m ∈ I : uij (m) = t} . Thus, Nij (t) records the number of times the membership of xi in cluster j reaches the threshold t on I.

14

Theorem 4 (Critical Events and Eventual Freezing). Assume that each membership function uij (m) is continuous on I. Then the following state- ments hold.

(i) Gt (m) can change only at values m ∈ T . Equivalently, Gt (m) is con- stant on every connected component of I \ T .

(ii) If Nij (t) < ∞ for every pair (i, j), then n X X c |T | ≤             Nij (t). i=1 j=1

(iii) If Nij (t) ≤ 1 for all (i, j), then |T | ≤ nc.

(iv) If T is finite and bounded above in I, and if m∗∗ := sup T , then Gt (m) is constant on I ∩ (m∗∗ , ∞).

Proof. For each i, j, define the threshold indicator indij (m) = 1[uij (m) ≥ t], so that xi ∈ Cj (t, m) ⇐⇒ indij (m) = 1. An edge (a, b) exists in Gt (m) if and only if there exists some xi such that india (m) indib (m) = 1. (i) Suppose m1 and m2 lie in the same connected component of I \ T . Then uij (m) ̸= throughout the interval between m1 and m2 . Since uij is continuous, it cannot move from one side of t to the other without attaining the value t. Hence indij (m1 ) = indij (m2 ) for all i, j, so the edge set of Gt (m) is unchanged. Consequently, graph changes can occur only at values in T . (ii) For each fixed pair (i, j), P  the equation uij (m) = t has exactly Nij (t) n Pc solutions on I. Hence |T | ≤              i=1  j=1 ij (t), with inequality because N several memberships may cross t at theP        same value of m. (iii) If Nij (t) ≤ 1 for all (i, j), then i,j Nij (t) ≤ nc, giving |T | ≤ nc. (iv) Since T is finite, no critical event occurs in I ∩ (m∗∗ , ∞). By part (i), the graph is constant on every connected component of I \ T . Therefore Gt (m) is constant on I ∩ (m∗∗ , ∞). Remark 4. Theorem 4 does not assume that the memberships are monotone in m. It only requires continuity. The bound in part (ii) uses the actual num- ber of threshold-crossing events, while part (iii) gives the simpler estimate |T | ≤ nc only when each membership reaches the threshold at most once on I. Thus, the eventual freezing point m∗∗ is conditional on the critical-event set being finite and bounded above.

15

(a) Co-occurrence graphs (c = 8, t = 0.3); both        (b) Cluster assignments. Both methods give com- yield |V | = |E| = 8, b0 = b1 = 1.                     parable decompositions on this isotropic geometry.

Figure 3: Unit circle dataset: SFCM (left) and GK-Mapper (right).

6. Empirical Validation We evaluate GK-Mapper against SFCM on five datasets-Circle, Anisotropic Ellipsoidal, Stanford Bunny, UCI Handwritten Digits, and Wisconsin Breast Cancer to test the stability framework of Section 5. The reported quanti- ties are the critical threshold tcrit (Theorem 1; largest t admitting at least one edge), the empirical stability radius r∗ (Theorem 2; local robustness in m), the edge instability |Echg | under perturbation h, the Theorem 3 detailed/simple bounds, and standard clustering metrics (Silhouette, ARI, matching score). All reference fuzzifiers m0 are selected automatically from the search grid. Aggregate results appear in Table 1.

6.1. Circle Dataset A synthetic benchmark of 150 points on the unit circle in R2 with Gaus- sian noise (s = 0.05) and eight angular sectors as ground-truth labels. Both methods use c = 8, t = 0.30, with m0 = 4.457 (SFCM) and m0 = 2.286 (GK- Mapper). GK-Mapper raises tcrit from 0.4016 to 0.4652 and increases r∗ from 0.0229 to 0.0833. Under h = 0.10, both methods yield |Echg | = 0, indicating that the graph structure is unchanged under the selected perturbation. Clustering metrics show a mixed but favourable trend for GK-Mapper. SFCM has a slightly higher Silhouette score (0.495 vs. 0.480), whereas GK- Mapper gives a substantially higher ARI (0.814 vs. 0.513) and matching score (0.913 vs. 0.713). Both methods recover the expected circular topology, with |V | = 8, |E| = 8, and b0 = b1 = 1; see Fig. 3. Thus, on this dataset, GK- Mapper preserves the same topological structure as SFCM while improving the empirical stability radius and external label agreement.

16

(a) Co-occurrence graphs (c = 3, t = 0.20); both            (b) Cluster assignments.     GK-Mapper adapts give |V | = |E| = 3, b0 = b1 = 1, but with different        to elongated geometries via the Gustafson-Kessel overlap strengths.                                          metric.

Figure 4: Anisotropic ellipsoidal dataset.

6.2. Anisotropic Ellipsoidal Dataset Three Gaussian clusters (180 points each) in R2 with aspect ratios 5:1, 8:1, 4:1, deliberately violating spherical-cluster assumptions [23]. Both methods use c = 3, t = 0.20, and m0 = 1.200. GK-Mapper improves tcrit from 0.3723 to 0.4390 and increases r∗ from 0.0132 to 0.0333. Under the selected perturbation h = 0.10, both methods give |Echg | = 0, so no edge change is observed. Both methods produce the same graph-level topological summary: |V | = 3, |E| = 3, b0 = 1, and b1 = 1 (Fig. 4). The clustering metrics are also very close. SFCM has a slightly higher Silhouette score (0.684 vs. 0.677), while both methods obtain the same ARI (0.962) and matching score (0.987). Hence, on this elongated dataset, GK-Mapper mainly improves the nontrivial threshold range and the empirical stability radius while preserving essentially the same clustering quality as SFCM.

6.3. Stanford Bunny Dataset A 3D point cloud of 5000 points sampled from the Stanford Bunny mesh [25] (Open3D), centered, rotated, and ℓ2 normalized. Both methods use c = 8, t = 0.25, with m0 = 5.000 (SFCM) and m0 = 3.943 (GK-Mapper). GK- Mapper raises tcrit from 0.3762 to 0.4511 and slightly improves r∗ from 0.0072 to 0.0096. Under h = 0.10, SFCM shows one edge change, whereas GK- Mapper shows no edge change. The GK-Mapper graph is topologically richer than the SFCM graph. SFCM gives |V | = 8, |E| = 10, b0 = 1, and b1 = 3, whereas GK-Mapper gives |V | = 8, |E| = 13, b0 = 1, and b1 = 6; see Fig. 5. The Silhouette

17

(a) Co-occurrence graphs (c = 8, t = 0.25). SFCM:        (b) Cluster assignments on the 3D point cloud. |E| = 10, b1 = 3; GK-Mapper: |E| = 13, b1 = 6.

Figure 5: Stanford Bunny dataset.

score is higher for SFCM (0.346 vs. 0.307), while ARI and matching score are not available because the point cloud has no class labels. These results suggest that GK-Mapper retains a more connected and cycle-rich graph on the Bunny point cloud while also reducing the observed edge variation under the selected perturbation.

6.4. UCI Handwritten Digits Dataset 1797 grayscale 8 × 8 digit images [30, 31], reduced to 20 dimensions via PCA (≈ 95% variance) and standardized. Both methods use c = 10, t = 0.12, with m0 = 1.40 (SFCM) and m0 = 2.400 (GK-Mapper). GK-Mapper markedly raises tcrit from 0.1000 to 0.4386. Since t = 0.12 lies above the SFCM critical threshold, the SFCM graph becomes edgeless, with |E| = 0, b0 = 10, and b1 = 0. In contrast, GK-Mapper retains a nontrivial graph with |E| = 23, b0 = 2, and b1 = 15. The empirical stability radius is slightly larger for SFCM (0.0004 vs. 0.0003), and SFCM shows no edge changes under h = 0.10, while GK-Mapper gives |Echg | = 11. This comparison must be interpreted carefully because the SFCM graph is already edgeless at the selected threshold; therefore, the ab- sence of edge changes does not represent preservation of a meaningful overlap structure. In terms of clustering metrics, GK-Mapper performs better: the Silhouette score improves from −0.054 to 0.036, the ARI improves from 0.143 to 0.257, and the matching score improves from 0.234 to 0.439. Thus, for UCI Digits, GK-Mapper produces a nontrivial graph and better label agreement, although with a slightly smaller empirical stability radius and more observed edge changes.

18

(a) Co-occurrence graphs (c = 10, t = 0.12).        (b) Cluster assignments (2D PCA projection). SFCM is edgeless; GK-Mapper gives |E| = 23, b1 = 15.

Figure 6: UCI Digits dataset.

6.5. Wisconsin Breast Cancer Dataset 569 samples with 30 features describing cell nuclei from digitised fine- needle aspirates [32, 30, 31]; binary malignant/benign labels. To probe the high-resolution regime (1/c ≈ 0.01), we use c = 100, t = 0.015, h = 0.10, with m0 = 1.65 (SFCM) and m0 = 2.40 (GK-Mapper). GK-Mapper substantially increases tcrit from 0.0291 to 0.2478 and improves the empirical stability radius from 0.0011 to 0.1596. It also sharply reduces the number of edge changes from 879 to 11. The graph structures are very different. SFCM produces a dense graph with |E| = 1734, b0 = 2, and b1 = 1636, whereas GK-Mapper produces a much sparser graph with |E| = 21, b0 = 94, and b1 = 15; see Fig. 7. This indicates that the adaptive Gustafson Kessel metric strongly reduces excessive overlap in this high-dimensional biomedical dataset. In terms of clustering metrics, GK-Mapper improves the Silhouette score from −0.203 to 0.019 and the matching score from 0.455 to 0.504, while SFCM obtains a higher ARI (0.256 vs. 0.143). Thus, GK-Mapper gives a more stable and much sparser graph, although SFCM aligns better with the binary labels under ARI.

7. Discussion The empirical validation across five datasets shows that GK-Mapper con- sistently increases the critical threshold tcrit compared with SFCM. The in- crease is observed on the Unit Circle dataset (0.4016 to 0.4652), the Anisotropic Ellipsoidal dataset (0.3723 to 0.4390), the Stanford Bunny dataset (0.3762

19

(a) Co-occurrence graphs (c = 100, t = 0.015).        (b) Cluster assignments (2D PCA projection). SFCM: |E| = 1734, b1 = 1636; GK-Mapper: |E| = 21, b1 = 15.

Figure 7: Wisconsin Breast Cancer dataset.

to 0.4511), the UCI Digits dataset (0.1000 to 0.4386), and the Breast Cancer dataset (0.0291 to 0.2478). This indicates that GK Mapper allows the graph to remain nontrivial over a wider range of threshold values. In Theorem 1, a threshold satisfying t > tcrit makes the graph edgless and discrete. Thus, finding tcrit is an essential first step before interpreting the resulting Mapper graph. GK-Mapper also produces a larger empirical stability radius in four of the five datasets. The improvement is most visible for the Unit Circle dataset (0.0833 vs. 0.0229), the Anisotropic Ellipsoidal dataset (0.0333 vs. 0.0132), the Stanford Bunny dataset (0.0096 vs. 0.0072), and the Breast Cancer dataset (0.1596 vs. 0.0011). The only exception is the UCI Digits dataset, where SFCM has a slightly larger radius (0.0004 vs. 0.0003). This supports the local stability result of Theorem 2: when the membership values remain separated from the threshold t, small changes in the fuzzifier m do not alter the thresholded cover, and hence the graph remains unchanged. The empir- ical results therefore suggest that GK-Mapper often provides a wider local stability region, especially when the data is heterogeneous. The edge-change results shows that GK-Mapper reduces the number of edge changes on the Breast Cancer dataset, where |Echg | drops from 879 for SFCM to 11 for GK-Mapper. It also improves stability on the Stan- ford Bunny dataset, where the edge change decreases from 1 to 0. On the Anisotropic Ellipsoidal and Unit Circle datasets, both methods show no edge changes under the selected perturbation. However, on the UCI Digits dataset, GK-Mapper has 11 edge changes whereas SFCM has none. This case should be interpreted carefully, because the SFCM graph is already edgeless at the

20

Table 1: Summary of SFCM and GK-Mapper performance across datasets. r∗ : empirical stability radius; |Echg |: edge change for h=0.10.

Dataset          Method       tcrit   r∗     m0   |Echg | edges b0   b1    Sil.   ARI Match. SFCM      0.0291 0.0011 1.65      879   1734 2 1636 −0.203 0.256         0.455 Breast Cancer GK-Mapper 0.2478 0.1596 2.40       11    21 94 15    0.019 0.143         0.504 SFCM      0.1000 0.0004 1.40       0      0    10    0   −0.054 0.143    0.234 UCI Digits GK-Mapper 0.4386 0.0003 2.40      11     23    2    15    0.036 0.257    0.439 Anisotropic      SFCM      0.3723 0.0132 1.20       0      3    1    1    0.684   0.962   0.987 Ellipsoidal      GK-Mapper 0.4390 0.0333 1.20       0      3    1    1    0.677   0.962   0.987 SFCM      0.3762 0.0072 5.000      1     10    1    3    0.346   NaN     NaN Stanford Bunny GK-Mapper 0.4511 0.0096 3.943      0     13    1    6    0.307   NaN     NaN SFCM      0.4016 0.0229 4.457      0      8    1    1    0.495   0.513   0.713 Unit Circle GK-Mapper 0.4652 0.0833 2.286      0      8    1    1    0.480   0.814   0.913

chosen threshold, while GK-Mapper retains a nontrivial graph with 23 edges. Therefore, the absence of edge changes for SFCM in this case reflects an already-empty graph rather than a more informative stable structure. This agrees with Theorem 3, which states that edge changes are controlled by threshold crossings of membership values. The clustering metrics show that graph stability and label agreement are related but distinct objectives. GK-Mapper improves the ARI and matching score on the Unit Circle and UCI Digits datasets. For example, on UCI Dig- its, the ARI increases from 0.143 to 0.257, and the matching score increases from 0.234 to 0.439. On the Unit Circle dataset, the ARI increases from 0.513 to 0.814, and the matching score increases from 0.713 to 0.913. On the Anisotropic Ellipsoidal dataset, both methods obtain the same ARI and matching score, while SFCM has a slightly higher silhouette value. On the Breast Cancer dataset, GK-Mapper improves the silhouette and matching score, but SFCM obtains a higher ARI. Therefore, a more stable or more structured Mapper graph does not automatically imply stronger agreement with external class labels. Several limitations remain. The theoretical results assume local regular- ity of the optimisation path but do not prove global uniqueness or global smoothness of FCM or GK-FCM solutions. The stability guarantee is local in the fuzzifier parameter, and the theory does not establish a universal or- dering between the stability radius of GK-Mapper and that of SFCM. The

21

empirical behaviour also depends on the chosen threshold, number of clusters, initialisation, fuzzifier grid, perturbation size, and scatter-matrix regularisa- tion. Therefore, GK-Mapper should not be viewed as uniformly superior to SFCM; rather, it provides a geometry-adaptive alternative that can be more stable and more informative when the data contain anisotropic or heteroge- neous structures. In summary, the proposed framework separates three issues in fuzzy Map- per construction: whether the graph is nontrivial, whether it remains locally stable under perturbations of the fuzzifier, and whether the resulting graph agrees with external labels. The experiments indicate that GK-Mapper usu- ally increases the nontrivial threshold range and often improves local stabil- ity, particularly on geometrically complex datasets. At the same time, the comparison with SFCM remains data-dependent, so the choice between the two methods should be guided by the geometry of the dataset and the goal of the analysis.

8. Conclusion We introduced the Gustafson Kessel Mapper (GK-Mapper) algorithm, that generalises SFCM [5] by replacing its Euclidean cover with an Ellipsoidal cover from the Gustafson-Kessel FCM algorithm [15, 2]. We then developed a stability framework that (i) identifies the edgeless zone boundary tcrit (m) = maxi maxj̸=k min{uij (m), uik (m)}, (ii) establishes local graph stability near fuzzifier values, and (iii) bounds edge changes by membership threshold crossings. We also showed that under a single crossing condition, the critical event set satisfies |T | ≤ nc, and when T is finite the graph freezes beyond m∗∗ = sup T . To validate these theorems, we did experiments on the Circle, Anisotropic Ellipsoidal, Stanford Bunny, UCI Digits, and Wisconsin Breast Cancer datasets. In all these cases, GK-Mapper has yielded more stable regions, while clus- tering quality remains dataset-dependent. This confirms that GK-Mapper is more effective in terms of graph stability. Future work includes (i) characterising single-crossing behaviour along the full GK-FCM path, (ii) extending the construction to fuzzy c-varieties [2, Sec- tion 23], (iii) integrating persistent homology to track the filtration induced by varying m [10, 13, 14], and (iv) deriving Lipschitz-type bounds linking membership-space perturbations to topological distances [18, 8].

22

Author contributions Annesha Sen and Shivam Singh contributed to the conceptualization of the problem and wrote the main manuscript text. S.P. Tiwari supervised the work and helped in the preparation of manuscript.

Declarations Competing interests: The authors confirm that they have no compet- ing interests.

References [1] S. Ben-David, U. von Luxburg, and D. Pál, “A sober look at clustering stability,” in Proc. 19th Annu. Conf. Learning Theory (COLT), 2006, pp. 5-19.

[2] J. C. Bezdek, Pattern Recognition with Fuzzy Objective Function Algo- rithms. New York, NY, USA: Plenum Press, 1981.

[3] J. C. Bezdek, R. Ehrlich, and W. Full, “FCM: The fuzzy C-Mean clus- tering algorithm,” Comput. Geosci., vol. 10, no. 2-3, pp. 191-203, 1984.

[4] Q.-T. Bui, B. Vo, H.-A. N. Do, N. Q. V. Hung, and V. Snasel, “F- Mapper: A fuzzy mapper clustering algorithm,” Knowl.-Based Syst., vol. 189, p. 105097, 2020.

[5] Q.-T. Bui, B. Vo, V. Snasel, W. Pedrycz, T.-P. Hong, N.-T. Nguyen, and M.-Y. Chen, “SFCM: A fuzzy clustering algorithm of extracting the shape information of data,” IEEE Trans. Fuzzy Syst., vol. 29, no. 1, pp. 75-89, Jan. 2021.

[6] M. Carrière and S. Oudot, “Structure and stability of the 1-dimensional Mapper,” Found. Comput. Math., vol. 18, no. 6, pp. 1333-1396, 2018.

[7] M. Carrière, B. Michel, and S. Oudot, “Statistical analysis and parame- ter selection for Mapper,” J. Mach. Learn. Res., vol. 19, no. 1, pp. 1-39, 2018.

[8] F. Chazal, V. de Silva, M. Glisse, and S. Oudot, The Structure and Stability of Persistence Modules. Cham, Switzerland: Springer, 2016.

23

[9] F. Chazal and B. Michel, “An introduction to topological data analy- sis: Fundamental and practical aspects for data scientists,” Front. Artif. Intell., vol. 4, p. 667963, 2021.

[10] D. Cohen-Steiner, H. Edelsbrunner, and J. Harer, “Stability of persis- tence diagrams,” Discrete Comput. Geom., vol. 37, no. 1, pp. 103-120, 2007.

[11] R. De Maesschalck, D. Jouan-Rimbaud, and D. L. Massart, “The Ma- halanobis distance,” Chemom. Intell. Lab. Syst., vol. 50, no. 1, pp. 1-18, 2000.

[12] T. K. Dey, F. Mémoli, and Y. Wang, “Multiscale Mapper: Topologi- cal summarisation via codomain covers,” in Proc. ACM-SIAM Symp. Discrete Algorithms (SODA), 2016, pp. 997-1013.

[13] H. Edelsbrunner, D. Letscher, and A. Zomorodian, “Topological persis- tence and simplification,” in Proc. IEEE Symp. Found. Comput. Sci., 2000, pp. 454-463.

[14] R. Ghrist, “Barcodes: The persistent topology of data,” Bull. Amer. Math. Soc., vol. 45, no. 1, pp. 61-75, 2008.

[15] D. E. Gustafson and W. C. Kessel, “Fuzzy clustering with a fuzzy covari- ance matrix,” in Proc. IEEE Conf. Decision Control, 1979, pp. 761-766.

[16] D. Haşegan et al., “Deconstructing the Mapper algorithm to extract richer topological and temporal features from functional neuroimaging data,” Netw. Neurosci., vol. 8, no. 4, pp. 1355-1382, 2024.

[17] R. Krishnapuram and J. M. Keller, “A possibilistic approach to cluster- ing,” IEEE Trans. Fuzzy Syst., vol. 1, no. 2, pp. 98-110, May 1993.

[18] M. Lesnick, “The theory of the interleaving distance on multidimensional persistence modules,” Found. Comput. Math., vol. 15, no. 3, pp. 613-650, 2015.

[19] L. Li et al., “Identification of type 2 diabetes subgroups through topo- logical analysis of patient similarity,” Sci. Transl. Med., vol. 7, no. 311, p. 311ra174, 2015.

24

[20] V. N. Madukpe et al., “A comprehensive review of the Mapper algorithm and its applications across various fields (2007–2025),” Int. J. Data Sci. Anal., vol. 21, 2025.

[21] M. Nicolau, A. J. Levine, and G. Carlsson, Topology-based data analysis identifies a subgroup of breast cancers with a unique mutational profile and excellent survival,” Proc. Natl. Acad. Sci. USA, vol. 108, no. 17, pp. 7265-7270, 2011.

[22] O. Rafique and A. H. Mir, “A topological approach for cancer subtyping from gene expression data,” J. Biomed. Inf., vol. 102, p. 103357, 2020.

[23] M. Riani, A. Cerioli, D. Perrotta et al., “Simulating mixtures of mul- tivariate data with fixed cluster overlap in FSDA library,” Adv. Data Anal. Classif., vol. 9, pp. 461–481, 2015.

[24] G. Singh, F. Mémoli, and G. Carlsson, “Topological methods for the analysis of high-dimensional data sets and 3D object recognition,” in Eurographics Symp. Point-Based Graphics, 2007, pp. 91-100.

[25] H. J. van Veen, N. Saul, D. Eargle, and S. Mangham, “Kepler Mapper: A flexible Python implementation of the Mapper algorithm,” J. Open Source Softw., vol. 4, no. 42, p. 1315, 2019.

[26] E. P. Xing, A. Y. Ng, M. I. Jordan, and S. Russell, “Distance metric learning with application to clustering with side-information,” in Adv. Neural Inf. Process. Syst. (NeurIPS), vol. 15, 2002.

[27] D. Q. Zhang and S. C. Chen, “A novel kernelized fuzzy C-Mean algo- rithm with application in medical image segmentation,” Artif. Intell. Med., vol. 32, no. 1, pp. 37-50, 2004.

[28] Y. Zhou et al., “Mapper Interactive: A scalable, extendable, and inter- active toolbox for the visual exploration of high-dimensional data,” in Proc. IEEE Pacific Vis. Symp. (PacificVis), 2021, pp. 101-110.

[29] H. J. Zimmermann, Fuzzy Set Theory-and Its Applications, 4th ed. Dor- drecht, Netherlands: Springer, 2001.

[30] D. Dua and C. Graff, “UCI Machine Learning Repository,” University of California, Irvine, School of Information and Computer Sciences, 2019.

25

[31] F. Pedregosa et al., “Scikit-learn: Machine Learning in Python,” J. Mach. Learn. Res., vol. 12, pp. 2825-2830, 2011.

[32] W. H. Wolberg, W. N. Street, and O. L. Mangasarian, “Breast cancer Wisconsin (diagnostic) data set,” UCI Machine Learning Repository, 1995.

26

Algorithm 1 Gustafson-Kessel Fuzzy C-Mean (GK-FCM) Require: Dataset X = {x1 , . . . , xn } ⊂ Rp , number of clusters c, fuzzifier m > 1, volume parameters qj > 0, tolerance tol Ensure: Membership matrix   Pc        U = [uij ], cluster centres V = {v1 , . . . , vc } (0) 1: Initialise U      with j=1 uij = 1 for all i; set t ← 0 2: repeat 3:     for j = 1 to c do Pn      (t) m (t)       i=1 (uij ) xi 4:         vj = Pn             (t) m i=1 (uij ) 5:     end for 6:     for j = 1 to  P c do (t) (t)                          (t)          (t) 7:         Sfj = ni=1 (uij )m (xi − vj )(xi − vj )⊤ (t)             (t)          (t) 8:        Aj = qj · det(Sfj )1/p · (Sfj )−1 9:     end for 10:     for i = 1 q to n; j = 1 to c do (t)              (t)    (t)         (t) 11:        dij = (xi − vj )⊤ Aj (xi − vj ) 12:    end for 13:    for i = 1 ton; j = 1 to c do        −1 (t) 2/(m−1) ! (t+1)              dij =  ck=1 (t) P 14:        uij                               dik 15:    end for 16:    t←t+1 17: until ∥U (t) − U (t−1) ∥ < tol 18: return U, V

27

Algorithm 2 Shape Fuzzy C-Mean (SFCM) Require: X = {x1 , . . . , xn } ⊂ Rp , number of clusters c, fuzzifier m > 1, overlap threshold t, tolerance tol ∈ (0, 1), maximum iterations kmax Ensure: SFCM graph Gt = (V, Et ) (0)             (0)             Pc    (0) 1: Initialise U (0) = [uij ] such that uij ∈ [0, 1] and  j=1 uij = 1 for all i 2: Set k ← 0 3: repeat 4:     for j = 1 to c do n (k) m X uij     xi 5:        vj ← i=1n (k) m X uij i=1 6:    end for 7:    for i = 1 to n;  " jc =1 to c do  2/(m−1) −1 # (k+1) X     ∥x  i − v j ∥ 8:        uij      ← ℓ=1 ∥xi − vℓ ∥ 9:    end for 10:    k ←k+1 (k)     (k−1) 11: until maxi,j uij − uij            < tol or k = kmax 12: Compute T0 ← mini,j uij            and T1 ← mini maxj uij 13: Clamp t ← max(T0 , min(t, T1 )) 14: for j = 1 to c do 15:    Cj (t) ← {xi ∈ X : uij ≥ t} 16: end for 17: V ← {1, . . . , c},    Et ← ∅ 18: for j = 1 to c − 1; k = j+1 to c do 19:    if Cj (t) ∩ Ck (t) ̸= ∅ then 20:        Et ← Et ∪ {(j, k)} 21:    end if 22: end for 23: return Gt = (V, Et )

28

Algorithm 3 Gustafson Kessel Mapper (GK-Mapper) Require: X = {x1 , . . . , xn } ⊂ Rp , number of clusters c, fuzzifier m > 1, threshold t, tolerance tol Ensure: GK-Mapper graph Gt (m) = (V, E) Pc       (0) 1: Initialise U (0) with     j=1 uij = 1 for all i 2: repeat 3:     for j = 1Pto c do n (uij )m xi 4:         vj = Pi=1 n         m Pni=1 (uij )m 5:         Sfj = i=1 (uij ) (xi − vj )(xi − vj )⊤ 6:         Aj = qj det(Sfj )1/p Sf−1 j 7:     end for 8:     for i = 1 to pn; j = 1 to c do 9:         dGK ij  =     (xi − vj )⊤ Aj (xi − vj ) 10:     end for 11:     for i = 1to n; j = 1 to c do  !2/(m−1) −1 Pc       dGK ij 12:         uij =  k=1 GK                  dik 13:    end for 14: until ∥U (t+1) − U (t) ∥F < tol 15: for j = 1 to c do 16:    Cj (t) ← {xi ∈ X : uij ≥ t} 17: end for 18: V ← {1, . . . , c}, E ← ∅ 19: for j = 1 to c − 1; k = j+1 to c do 20:    if Cj (t) ∩ Ck (t) ̸= ∅ then E ← E ∪ {(j, k)} 21:    end if 22: end for 23: return Gt (m) = (V, E)

29

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
