---
id: ADR-0035
title: "ADR-0035: Hodge Spectral Surrogates for Topology-Constrained Optimization"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.HodgeSurrogates
rust_module: echonomics_engine::hodge_surrogates
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0035: Hodge Spectral Surrogates for Topology-Constrained Optimization

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for Hodge Spectral Surrogates for Topology-Constrained Optimization.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0035
Title: Hodge Spectral Surrogates for Topology-Constrained Optimization
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

Hodge Spectral Surrogates for Topology-Constrained Optimization

Satoshi Kanno1* and Yoshi-aki Shimada1 1* Quantum Information Technology Department, Quantum Technology Division, Product Research and Development Division, arXiv:2606.25194v1 [math.AT] 23 Jun 2026

SoftBank Corp., 1-7-1 Kaigan, Minato-ku, 105-7529, Tokyo, Japan .

*Corresponding author(s). E-mail(s): satoshi.kanno06@g.softbank.co.jp; Contributing authors: yoshiaki.shimada01@g.softbank.co.jp;

Abstract Topological information is widely used in data analysis, network design, and machine learning, and topological constraints naturally arise when optimizing or generating objects with prescribed homological structure. However, directly controlling Betti numbers and persistent homology is difficult because they are discrete and combinatorial. We propose a differentiable framework for topology- constrained optimization based on Hodge-spectral relaxations of homological constraints and low-pass spectral filters. From soft graphs and soft clique com- plexes, we construct Hodge-Laplacian-type spectral relaxations that unify graph clique complexes and Vietoris–Rips filtrations of point clouds. In the hard limit, the penalty-regularized ambient operator recovers the ordinary Hodge Laplacian on the active subcomplex, while in the soft regime it serves as a differentiable low- frequency spectral surrogate. Homological information is represented by zero and near-zero modes, and differentiable topological objectives are defined using heat filters, resolvent filters, and polynomial Laplacian moments. For point clouds, we show that the proposed Hodge spectral-filter losses yield more spatially dis- tributed gradients, smoother scale-normalized behavior under persistence-pairing changes, and geometry-aware update directions than persistent-homology-based losses. For graph clique complexes, Laplacian moments control normalized first-Betti-type quantities and can be combined with ordinary graph-feature objectives. We also discuss connections to trace-based normalized Betti-number estimation, polynomial spectral methods, and possible quantum trace estimation.

Keywords: Applied and computational topology, Topological data analysis, Hodge Laplacian, Spectral filters, Topology-constrained optimization

1

1 Introduction Understanding the shape of data is a fundamental problem in applied mathematics, data analysis, network science, and machine learning. In particular, the interaction between topology and artificial intelligence has become an important theme in applied and computational topology. Data such as point clouds, images, graphs, and time series often contain not only local metric information but also global structural information, including connected components, holes, loops, and higher-order relations. Homolog- ical invariants, such as Betti numbers and persistent homology (Edelsbrunner et al. (2002); Zomorodian and Carlsson (2004); Cohen-Steiner et al. (2005); Edelsbrunner et al. (2008); Otter et al. (2017)), provide mathematical tools for describing such global structures and have been widely used as topological descriptors and features in artificial-intelligence and machine-learning pipelines (see Adams et al. (2017); Hofer et al. (2017); Bubenik (2020); Chazal et al. (2014); Kališnik (2019)). Such topologi- cal features can improve representations or regularization when the underlying data distribution has nontrivial geometric or topological structure. Topology is also important not only as a descriptor but also as a quantity to be con- trolled in optimization through loss functions or regularizers (see Moor et al. (2020); Vandaele et al. (2021); Gabrielsson et al. (2020)). In many applications, one would like the output of a model or an optimization procedure to satisfy prescribed topological constraints. For example, in image segmentation, controlling the topology of predicted regions can reduce spurious connected components or undesired holes(see Clough et al. (2020); Hu et al. (2019)). In graph and network design, the Betti numbers of clique complexes describe higher-order connectivity, redundancy, and cyclic structure, which are related to robustness and alternative pathways in networks. Thus, differentiable control of persistent homology and Betti numbers is relevant to topology-constrained optimization in a broad applied-mathematical sense. In this prescriptive setting, topol- ogy is optimized rather than only observed: the aim is to deform, generate, or regularize an object so that its homological structure satisfies a desired condition. Persistent homology provides a natural mechanism for such topological control. Since a persistence diagram or barcode records the birth and death of homology classes across a filtration, one can define losses that penalize undesired bars, preserve selected bars, or match a target barcode. These barcode-based losses make it possible to incorporate persistent homology directly into optimization and learning procedures. However, directly controlling topological quantities is difficult because they are inher- ently discrete and combinatorial. Betti numbers of clique complexes depend on simplex inclusion and ranks of boundary operators. Even when graph edges are relaxed into continuous weights or probabilities, the resulting clique complex and its Betti numbers remain governed by combinatorial conditions. For persistent homology, differentiable losses based on barcode or persistence- diagram representations have been studied, and such losses are useful when the desired constraint is naturally expressed in terms of persistent features. However, when topol- ogy is used as an optimization signal, such losses have several limitations: gradients may tend to be localized on a small number of critical simplices (see Nigmetov and Morozov (2024); Nigmetov et al. (2024)), persistence-pairing changes may cause abrupt changes in gradient directions, and barcode representations may compress away

2

geometric and spectral information that could provide smoother and more spatially distributed update directions. We emphasize that our goal is not to replace persistent homology as a descriptor. Persistent homology remains the appropriate object when one wants stable barcode- level summaries of multiscale topology. Our focus is different: we study topology as a differentiable loss or constraint inside an optimization loop. In this setting, a smooth Hodge-spectral surrogate can be useful because it provides gradients through low- frequency spectral structure rather than only through selected birth–death simplices. In this work, we address these difficulties by representing homology through the zero modes of Hodge Laplacians. For a simplicial complex, the k -th Betti number is equal to the dimension of the kernel of the k -th Hodge Laplacian. Instead of directly counting zero eigenvalues, we introduce smooth low-pass spectral filters that emphasize zero and near-zero eigenmodes. These filters provide differentiable spectral surrogates for topological information and allow homological information to be used as a continuous optimization signal. More specifically, we construct Hodge-Laplacian-type spectral relaxations from soft graphs and soft clique complexes. This gives a unified formulation for two standard sources of finite simplicial complexes: graph data and Vietoris–Rips filtrations of point clouds. In the point-cloud setting, soft edge activations are defined from pairwise distances and scale parameters. In the graph setting, edge probabilities induce soft simplex weights and hence soft clique complexes. In both cases, topological losses are defined by applying low-pass spectral filters, such as heat filters, resolvent filters, and polynomial moment filters, to the corresponding Hodge-Laplacian-type spectral relaxations. In the hard limit, the proposed ambient operator recovers the ordinary Hodge Laplacian on the active subcomplex and hence retains the standard homological interpretation. In the soft regime, the same construction should be interpreted as a differentiable low-frequency spectral surrogate for homological structure. The Laplacian-based formulation also connects naturally with polynomial spectral methods and trace estimation. In particular, trace-type quantities such as

Tr(I − αLq )d

can be interpreted as low-frequency spectral masses and, in the hard ordinary-complex setting, as smooth surrogates for normalized Betti numbers, since zero modes con- tribute one to the trace while nonzero modes are suppressed by the polynomial filter. This structure is closely related to stochastic trace estimation and polynomial approximations of spectral projectors. It also has a structural connection to quan- tum trace-estimation approaches for normalized Betti numbers, which often formulate Betti numbers through the null space of combinatorial Laplacians. However, this paper does not implement a quantum algorithm and does not claim quantum advantage. We therefore treat the quantum connection as a possible computational direction rather than as a main contribution (see Lloyd et al. (2016); Akhalwaya et al. (2024); Gyurik et al. (2022); Yamauchi et al. (2025)). The contributions of this work are summarized as follows.

3

1. We construct an ambient Hodge-spectral relaxation for finite simplicial complexes. In the hard limit, the penalty-regularized ambient operator recovers the ordinary Hodge Laplacian on the active subcomplex and hence the corresponding Betti number. 2. We define differentiable topological losses using heat filters, resolvent filters, and polynomial Laplacian moments. These objectives include spectral-filter matching losses and trace-type Betti surrogates. 3. For Vietoris–Rips filtrations of point clouds, we numerically compare the pro- posed Hodge spectral-filter losses with persistent-homology-based losses and show that they provide more spatially distributed gradients, smoother scale-normalized behavior under persistence-pairing changes, and update directions that better reflect surrounding geometry. 4. For graph clique complexes, we use Laplacian moments to control normalized first- Betti-type quantities and show that the proposed topological loss can be combined with ordinary graph-feature objectives. 5. We discuss computational trade-offs and identify polynomial filtering, Cheby- shev approximation, and trace-estimation-based implementations as possible routes toward larger-scale applications. In summary, this work presents a Hodge-spectral framework for controlling homo- logical constraints in point clouds and graphs. By replacing discrete topological quantities with smooth low-pass spectral surrogates, the proposed method enables topology to be treated not only as a descriptor of data, but also as a controllable object in optimization, network design, machine learning, and future quantum-assisted topological computation.

2 Preliminaries and Problem Setting In this section, we summarize the topological quantities considered in this work and the difficulties that arise when using them as loss functions. We first introduce the Betti numbers of clique complexes constructed from graphs, and describe why it is difficult to directly use them as loss functions. We then introduce persistent homology for point-cloud data and loss functions based on barcode diagrams. Finally, we discuss three issues of barcode-based loss functions: gradient localization, discontinuity caused by changes in persistence pairings, and loss of geometric and spectral information.

2.1 Clique Complexes and Betti Numbers We first introduce the Betti numbers of clique complexes as topological quantities for graph data. Let G = (V, E ) be a graph, where V is the set of vertices and E is the set of edges. The clique complex X (G) of G is a simplicial complex obtained by regarding each clique in the graph as a simplex. That is, a subset of vertices

σ = {v0 , . . . , vk } ⊂ V

4

is a k -simplex if, for any distinct i, j ,

(vi , vj ) ∈ E

holds. Equivalently, σ must form a (k + 1)-clique. Therefore, the clique complex is defined as X (G) = {σ ⊂ V : σ is a clique in G}. Let Ck (X (G)) be the k -th chain group of X (G), and let

∂k : Ck (X (G)) → Ck−1 (X (G))

be the boundary operator. The k -th homology group is defined by

Hk (X (G)) = ker ∂k / im ∂k+1 .

The dimension of this homology group, βk (X (G)) = dim Hk (X (G)) is called the k - th Betti number. In particular, β0 represents the number of connected components, while β1 represents the number of independent one-dimensional cycles, namely loops that are not filled by triangles or higher-dimensional simplices. The Betti numbers of clique complexes capture higher-order connectivity and cyclic structures of graphs. Therefore, controlling the Betti numbers of clique complexes in graph generation or network design is meaningful for controlling redundancy and robustness of graph structures.

2.2 Difficulties in Using Betti Numbers as Loss Functions Suppose that we want to optimize a graph so that the Betti number of its clique complex approaches a target value. For example, for a target Betti number βktar , one may consider the loss function 2 Lβ (G) = βk (X (G)) − βktar . This formulation is natural from an intuitive viewpoint. However, it is difficult to optimize this loss function using standard gradient-based methods. The reason is that the map

G 7−→ X (G) 7−→ βk (X (G)) is combinatorial and discrete. A small change in the presence or absence of edges can discontinuously change the set of simplices contained in the clique complex. As a result, the ranks of boundary operators and the dimensions of homology groups can also change discontinuously.

2.3 Persistent Homology Next, we introduce persistent homologyEdelsbrunner et al. (2002); Zomorodian and Carlsson (2004); Cohen-Steiner et al. (2005); Edelsbrunner et al. (2008); Otter et al.

5

(2017) as a topological quantity for point-cloud data and related data types. Suppose that, from data X , we construct a sequence of simplicial complexes

K0 ⊂ K1 ⊂ · · · ⊂ Km

according to a scale parameter. Such a nested sequence of simplicial complexes is called a filtration. For example, for point-cloud data, one can construct a filtration using Vietoris–Rips complexes indexed by a distance scale r. At each scale r, the k -th homology group is

Hk (Kr ) = ker ∂k / im ∂k+1 .

Persistent homology tracks when homology classes are born and when they die along the filtration. For a homology class γ , let its birth time be bγ and its death time be dγ . Then the k -th persistence diagram is represented as

Dgmk (X ) = {(bγ , dγ )}γ ⊂ R2 .

The persistence of γ is defined by pers(γ ) = dγ − bγ . Persistence diagrams and barcode diagrams provide compact summaries of the multiscale topological structure of data. Homology classes with long persistence are often interpreted as reflecting essential structures of the data rather than noise. For this reason, persistent homology is widely used for shape analysis of point clouds, images, time-series data, and related objects.

2.4 Loss Functions Based on Barcode Diagrams One way to incorporate persistent homology into machine learning is to construct loss functions from barcode diagrams or persistence diagrams. In general, given a target persistence diagram Dtar , one may define a loss function for input data X as

LPD (X ) = ℓ Dgmk (X ), Dtar . 

For example, if the goal is to remove undesired homology classes, let U be the set of undesired classes. Then one can use a loss of the form X LPD (X ) =    (dγ − bγ )2 . γ∈U

This loss acts to shorten the lifetimes of undesired homology classes. On the other hand, if the goal is to preserve specific homology classes, let T be the set of classes to be preserved, and let τγ be the target persistence. Then one can consider the loss function X                     2 LPD (X ) =      ((dγ − bγ ) − τγ ) . γ∈T

6

Such barcode-based loss functions can be differentiated through birth and death values. The birth and death of each homology class γ are determined by certain critical simplices. That is, one can write

bγ = f (σb ),       dγ = f (σd ),

where σb is the simplex that determines the birth, σd is the simplex that determines the death, and f is the function assigning filtration values to simplices. Then the gradient of the loss function can formally be written as

∂LPD              ∂LPD ∇X LPD =         ∇X f (σb ) +      ∇X f (σd ). ∂bγ               ∂dγ

Thus, in barcode-based loss functions, gradients can be computed through the critical simplices that determine birth and death values.

2.5 Issues of Barcode-Based Loss Functions This property makes it possible to use persistent homology as a loss function. However, this formulation has the following three important issues.

2.5.1 Gradient Localization The first issue is that gradients tend to be localized on a small number of critical simplices(see Nigmetov and Morozov (2024); Nigmetov et al. (2024)). As described above, in barcode-based loss functions, the birth and death of each homology class are determined by critical simplices σb and σd . Therefore, the gradient of the loss mainly flows through

∇X f (σb ),        ∇X f (σd ).

In other words, the actual updates tend to be concentrated on the vertices contained in these critical simplices and their neighborhoods. However, topological structures are inherently determined by the global configu- ration of the data. For example, when a point cloud forms a large loop, the birth or death of the loop may be represented by a small number of critical simplices, but geometrically the shape of the entire loop is important. Nevertheless, barcode-based losses concentrate gradients on a small number of simplices and may fail to provide smooth update directions for the entire data set. Such gradient localization can make optimization unstable and may prevent geometrically natural deformations.

2.5.2 Discontinuity of Gradients Caused by Pairing Changes The second issue is that gradients can change discontinuously when persistence pairings change due to small perturbations of filtration values.

7

In persistent homology, each homology class γ is associated with a birth–death pair of simplices (σb , σd ). However, when a small perturbation is added to the input data X , the ordering of filtration values of simplices may change. As a result, the persistence pairing may change as (σb , σd ) −→ (σb′ , σd′ ). In this case, even if the persistence diagram itself remains stable, the simplices through which gradients flow switch from

∇X f (σb ), ∇X f (σd )   −→    ∇X f (σb′ ), ∇X f (σd′ ).

Consequently, even if the value of the loss function does not change significantly, the gradient direction may change discontinuously. This issue is important from the viewpoint of optimization. Gradient-based meth- ods update parameters using local changes of the loss function. If the gradient direction changes discontinuously under small perturbations, stable optimization becomes difficult.

2.5.3 Loss of Geometric and Spectral Information The third issue is that barcode diagrams are representations specialized for birth–death information of homology classes, and they do not sufficiently preserve surrounding geometric and spectral information. A persistence diagram is obtained from input data X through the map

X 7−→ Dgmk (X ) = {(bγ , dγ )}γ .

This representation compactly summarizes the scales at which each homology class is born and dies. However, in this process, much information is compressed, including the geometric locations supporting the homology classes, the surrounding neighborhood structure, and spectral information such as eigenvectors and low-frequency modes of Laplacians. For example, two homology classes may have the same persistence, but they may be arranged differently in the data space, may have different degrees of geometric smooth- ness as cycles, or may contain different near-closed structures. Barcode diagrams do not sufficiently distinguish such differences. Therefore, while barcode-based loss functions are effective for controlling topolog- ical summary quantities, they may be insufficient for providing geometrically natural and smooth update directions for the entire data.

2.6 Problem Addressed in This Work The preceding subsections identify two related but distinct uses of topology in data analysis and optimization. The first is descriptive: one computes Betti numbers, per- sistent homology, or barcode diagrams of a fixed data set in order to describe its global

8

structure. The second is prescriptive: one seeks to optimize a point cloud, graph, or model output so that its topology satisfies a desired condition. This paper focuses on the second use. The difficulty is that the topological quantities considered above do not directly provide smooth optimization signals. For clique complexes of graphs, the map

G 7−→ X (G) 7−→ βk (X (G))

is combinatorial, because the set of simplices and the ranks of the boundary operators can change discontinuously when edges are added or removed. For Vietoris–Rips fil- trations, barcode-based losses make persistent homology differentiable through birth and death values, but the resulting gradients may be localized on critical simplices, may change abruptly when persistence pairings switch, and may discard geometric and spectral information that could be useful for optimization. Our goal is therefore not merely to compute topological summaries, but to con- struct differentiable objectives that retain a clear relationship with homology while providing smoother and more spatially distributed optimization signals. We use the Hodge-theoretic identity between homology and zero modes of the combinatorial Laplacian as the starting point. For a fixed finite simplicial complex K , the kernel of the q -th Hodge Laplacian Lq (K ) is naturally isomorphic to Hq (K ), and hence dim ker Lq (K ) = βq (K ). The main question is how to use this identity when the simplicial complex itself changes with continuous parameters. In the next section, we address this question by embedding changing complexes into a fixed ambient chain space, separating inactive simplex directions by a penalty term, and then replacing hard simplex indicators with soft simplex weights. This leads to a Hodge-Laplacian-type spectral relaxation that recovers the ordinary Hodge-theoretic interpretation in the hard limit and provides differentiable low-frequency spectral quantities in the soft regime.

3 Construction of Hodge-Laplacian-type spectral relaxation In this section, we introduce ambient Hodge-spectral relaxations as the basic objects for constructing differentiable topological losses for both point-cloud data and graph data. The construction is exact in the hard simplicial-complex limit and is used as a smooth spectral surrogate in the soft regime. The basic idea of this work is to represent both point-cloud data and graph data as soft graphs and then construct soft clique complexes from them. In graph generation, edge logits are used as optimization variables. In Vietoris–Rips filtrations, edge logits are defined from pairwise distances and a scale parameter. Therefore, both settings can be described by the common sequence

θ 7−→ ae (θ) 7−→ pe (θ) 7−→ wσ (θ) 7−→ L b q (θ).

9

Here, ae denotes an edge logit, pe denotes a soft edge activation, wσ denotes a sim- plex activation, and Lb q denotes a penalty-regularized Hodge-Laplacian-type spectral relaxation. The terminology is important: for hard simplex indicators, the construction recov- ers an ordinary Hodge Laplacian on the active subcomplex. For soft simplex weights, the same formula should be interpreted as a differentiable Hodge-spectral surrogate rather than as the Hodge Laplacian of an exact chain complex. For the ordinary Hodge Laplacian, zero modes correspond to homology classes, and the dimension of the kernel of the q -th Hodge Laplacian is equal to the q -th Betti number. However, when the simplicial complex changes according to input data or model parameters, the dimension and basis of the corresponding chain space may also change. Therefore, it is difficult to directly treat the ordinary Hodge Laplacian as a differentiable object on a fixed vector space. To address this issue, we introduce a fixed ambient chain space containing all candidate simplices. On this space, we construct a hard Hodge Laplacian using pro- jections and a penalty term so that the number of zero modes agrees with the Betti number of the active subcomplex. We then relax the projections using simplex activa- tions obtained from a soft graph, yielding a Hodge-Laplacian-type spectral relaxation that depends smoothly on the parameters and recovers the ordinary Hodge-theoretic interpretation in the hard limit.

3.1 Ambient Chain Spaces and Boundary Operators Let Kmax be a finite fixed ambient simplicial complex containing all candidate sim- plices that may appear during optimization. For example, given a candidate edge set Emax , one may define the maximum candidate graph

Gmax = (V, Emax )

and use its clique complex Kmax = X (Gmax ) as the ambient complex. For each dimension q , define the ambient q -chain space by

Cqamb = Cq (Kmax ).

This is a finite-dimensional real vector space generated by all oriented q -simplices in Kmax . After fixing orientations and equipping it with the standard inner product, Cqamb can be regarded as a finite-dimensional Hilbert space. Let Bq : Cqamb → Cq−1 amb be the ambient boundary operator of the fixed complex Kmax . For an oriented simplex σ = [v0 , . . . , vq ], q X ∂q σ =     (−1)i [v0 , . . . , vbi , . . . , vq ], i=0

and the matrix representation of this operator is Bq . Since the boundary of a boundary is zero, we have Bq Bq+1 = 0.

10

Suppose that a hard subcomplex K (θ) ⊂ Kmax is determined by a parameter θ. (q) For each q -simplex σ ∈ Kmax , define the activity indicator by ( 1, σ ∈ K (θ), χσ (θ) = 0, σ ∈ / K (θ).

The orthogonal projection onto the active q -simplex directions is defined by

Πq (θ) = diag (χσ (θ))σ∈K (q) . max

Then the q -chain space of K (θ) is embedded as

Cq (K (θ)) = Im Πq (θ) ⊂ Cqamb .

Since K (θ) is a simplicial complex, every face of an active simplex is also active. Hence, Bq Im Πq (θ) ⊂ Im Πq−1 (θ), or equivalently, Πq−1 (θ)Bq Πq (θ) = Bq Πq (θ). We define the hard restricted boundary operator on the ambient space by

Bqhard (θ) = Πq−1 (θ)Bq Πq (θ).

On the active subspace Cq (K (θ)) = Im Πq (θ), this agrees with the ordinary boundary map of the subcomplex K (θ).

3.2 Penalty-Regularized Hard Ambient Hodge Laplacian A naive Hodge operator on the fixed ambient space Cqamb would be

⊤                               ⊤ hard Bqhard (θ) Bqhard (θ) + Bq+1       hard (θ) Bq+1  (θ) .

However, since this operator acts on the entire ambient space, inactive simplex direc- tions may remain as spurious zero modes that do not correspond to homology classes of the active subcomplex. To remove them, we add an inactive-direction penalty. For µ > 0, define ⊤                               ⊤ Lhard q    (θ) = Bqhard (θ) Bqhard (θ) + Bq+1 hard      hard (θ) Bq+1  (θ) + µ (I − Πq (θ)) .

The last term assigns energy µ to inactive q -simplex directions and removes them from the low-eigenvalue region. With respect to the orthogonal decomposition

Cqamb = Im Πq (θ) ⊕ ker Πq (θ),

11

we have Lhard q    (θ) = Lq (K (θ)) ⊕ µIker Πq (θ) . Therefore, ker Lhard q    (θ) = ker Lq (K (θ)) ≃ Hq (K (θ)). Hence, dim ker Lhard q    (θ) = βq (K (θ)). Thus, the number of zero modes of the penalty-regularized hard ambient Hodge Laplacian agrees with the q -th Betti number of the active subcomplex.

Proposition 1 (Hard-limit consistency of the ambient Hodge Laplacian) Let K(θ) ⊂ Kmax be an active subcomplex and let Lhard q    (θ) be the penalty-regularized hard ambient Hodge Laplacian defined above. Then, with respect to the orthogonal decomposition Cqamb = Cq (K(θ)) ⊕ Cq (K(θ))⊥ , one has Lhard q    (θ) = Lq (K(θ)) ⊕ µICq (K(θ))⊥ . Consequently, ker Lhard q    (θ) ≃ Hq (K(θ)),     dim ker Lhard q    (θ) = βq (K(θ)).

Proof On the active subspace Cq (K(θ)) = Im Πq (θ), the projected boundary operators coin- cide with the ordinary boundary operators of the subcomplex K(θ), because K(θ) is closed under taking faces. On the inactive orthogonal complement, the projected boundary terms vanish and the penalty term acts as multiplication by µ. Thus the operator decomposes as Lq (K(θ)) ⊕ µICq (K(θ))⊥ . The statement follows from the finite-dimensional Hodge decomposition, which identifies ker Lq (K(θ)) with Hq (K(θ)).                                                        □

3.3 Soft Graphs and Hodge-Laplacian-type spectral relaxation We now relax the hard projection Πq (θ) using a soft graph and construct a differen- tiable spectral relaxation of the hard ambient operator. Let V = {1, . . . , n} be the vertex set, and let Emax ⊂ V2 be the set of candidate edges. For each candidate edge e ∈ Emax , define an edge logit ae (θ) ∈ R, and define the corresponding soft edge activation by 1 pe (θ) = σ (ae (θ)) =                      . 1 + exp(−ae (θ)/εe ) We call Gθ = (V, Emax , pθ ) a soft graph. The activation or soft weight of a simplex σ is defined as the product of the activations of its constituent edges: Y wσ (θ) =         pe (θ). e⊂σ

12

Vertices are assumed to always exist, so wv (θ) = 1. In particular, for an edge e, we = pe , and for a triangle t = {i, j, k},

wt = pij pik pjk .

In the hard limit pe → 1e∈E , we have

wσ (θ) → 1σ∈X(G) .

Thus, this construction is a continuous relaxation of the ordinary clique complex at the level of simplex indicators. For each dimension q , define

Wq (θ) = diag (wσ (θ))σ∈K (q) ,               Rq (θ) = Wq (θ)1/2 . max

Using these matrices, define the weighted boundary-type operator by

B eq (θ) = Rq−1 (θ)Bq Rq (θ).

In components,                              p              p Beq (θ)          =    wτ (θ)(Bq )τ,σ wσ (θ). τ,σ Thus, the boundary relation between a simplex and its face is smoothly weighted by their activations.

Remark 1 (Soft weighted boundaries) For hard simplex indicators, the projected boundary operators recover the ordinary boundary maps of the active subcomplex. For soft weights, however, the matrices B eq (θ) = Rq−1 (θ)Bq Rq (θ) do not generally satisfy B eq−1 (θ)B eq (θ) = 0. Thus, in the soft regime, these matrices should not be interpreted as boundary maps of an exact chain complex. They are instead boundary-inspired weighted operators used to define a smooth Hodge-Laplacian-type spectral relaxation. The exact homological interpretation is recovered in the hard limit.

We define the q -th penalty-regularized Hodge-Laplacian-type spectral relaxation by L         eq (θ)⊤ B b q (θ) = B       eq (θ) + B       eq+1 (θ)⊤ + µ (I − Wq (θ)) . eq+1 (θ)B The first term is the lower Laplacian-type term, the second term is the upper Laplacian-type term, and the third term is the inactive-direction penalty. If wσ (θ) ≈ 1, the penalty has almost no effect on the corresponding direction. If wσ (θ) ≈ 0, the direction receives approximately energy µ. In the hard limit wσ (θ) → χσ (θ), we have

Wq (θ) → Πq (θ),        Rq (θ) → Πq (θ),             b q (θ) → Lhard L               (θ). q

13

Therefore, L b q (θ) is a differentiable Hodge-spectral relaxation of the hard Hodge Lapla- cian that recovers the Betti-number interpretation in the hard limit. Away from the hard limit, its low-frequency spectrum should be interpreted as a spectral surrogate for homological structure rather than as an exact Betti-number representation.

(m) Proposition 2 (Convergence to the hard ambient operator) Let wσ ∈ [0, 1] be a sequence of simplex weights converging to hard activity indicators χσ ∈ {0, 1} for all simplices of Kmax . Let Lb q (w(m) ) be the corresponding penalty-regularized Hodge-Laplacian-type spectral relaxation. Then Lb q (w(m) ) −→ Lhard q    (K) in operator norm, where K = {σ ∈ Kmax : χσ = 1}.

Proof The ambient boundary matrices Bq are fixed finite matrices. The diagonal matrices Wq (w(m) ) converge entrywise to Πq , and the square-root matrices Rq (w(m) ) = Wq (w(m) )1/2 converge entrywise to Πq . Since all matrices are finite-dimensional, entrywise convergence implies convergence in operator norm. Therefore, Rq−1 (w(m) )Bq Rq (w(m) ) −→ Πq−1 Bq Πq , and the corresponding lower, upper, and penalty terms converge to those of Lhard q    (K).       □

3.4 Logit Parameterization for Graph Clique Complexes In graph generation or graph-structured optimization, the optimization variables are the edge logits θ = a = {ae }e∈Emax . Then pe (a) = σ (ae ) and                      Y wσ (a) =         pe (a). e⊂σ Thus, the Hodge-Laplacian-type spectral relaxation is obtained through

a 7−→ pe (a) 7−→ wσ (a) 7−→ L b q (a).

For controlling one-dimensional cyclic structure, which is measured by the first Betti number in the hard clique-complex limit, we use q = 1 and define

L         e1 (a)⊤ B b 1 (a) = B       e1 (a) + B     e2 (a)⊤ + µ(I − W1 (a)). e2 (a)B

This operator acts on the fixed ambient edge space C1amb . Hence, graph optimization or graph-structured topology control can be performed in a fixed-dimensional Hilbert space, even though the underlying hard clique complex changes combinatorially.

14

3.5 Soft-Graph Representation of Vietoris–Rips Filtrations We next represent Vietoris–Rips filtrations of point-cloud data within the same soft- graph and Hodge-spectral framework. Let

X = {x1 , . . . , xn } ⊂ Rd

be a point cloud. In the ordinary Vietoris–Rips complex at scale r > 0, an edge (i, j ) is present when ∥xi − xj ∥ ≤ r. To relax this condition smoothly, define the stabilized distance with a small numerical parameter δ > 0 q dij (X ) =    ∥xi − xj ∥2 + δ,

and define the Vietoris–Rips edge logit by

(r)          r − dij (X ) aij (X ) =                  . ε Here, ε > 0 controls the softness of the threshold. The corresponding soft edge activation is (r)  (r)              1 pij (X ) = σ aij (X ) =                       . r−dij (X) 1 + exp −      ε This value is close to one when dij (X ) < r, and close to zero when dij (X ) > r. In the hard-threshold limit ε → 0, (r) pij (X ) → 1dij (X)≤r . The activation of a simplex σ is defined by Y wσ(r) (X ) =         p(r) e (X ). e⊂σ

In the hard limit, wσ(r) (X ) → 1σ∈VRr (X) , because the Vietoris–Rips condition is equivalent to requiring all edges in σ to have length at most r, namely maxe⊂σ de (X ) ≤ r. Thus, the soft clique construction recovers the ordinary Vietoris–Rips complex at each fixed scale in the hard-threshold limit. Thus, the Vietoris–Rips filtration can be represented as the soft clique complex of a soft graph whose edge logits are

(r)          r − dij (X ) aij (X ) =                  . ε For each scale r, we obtain the sequence

X 7−→ a(r) (X ) 7−→ p(r) (X ) 7−→ w(r) (X ) 7−→ L b (r) q (X ).

15

More explicitly, define                                                   1/2 Wq(r) (X ) = diag wσ(r) (X )         (q) ,     Rq(r) (X ) = Wq(r) (X )     , σ∈Kmax

and eq(r) (X ) = R(r) (X )Bq Rq(r) (X ). B             q−1 Then            ⊤                                      ⊤                 b (r)            (r)          (r)           (r)         e (r) (X ) + µ I − Wq(r) (X ) . L q   (X ) =  Be q    (X )   B e q    ( X ) + B e q+1 ( X )  B q+1

This is the Vietoris–Rips instance of the Hodge-Laplacian-type spectral relaxation defined above. For controlling one-dimensional homology, we use q = 1.

3.6 Multi-Scale Vietoris–Rips Construction Persistent homology describes the birth and death of homology classes across scales. Therefore, instead of using a single scale, we consider a sequence

r1 < r2 < · · · < rM .

For each scale rm , define                     (r )                rm − dij (X ) pij m (X ) = σ                           . ε

This yields a Hodge-Laplacian-type spectral relaxation

b (r L    m) (X ) q

at each scale. The family n             oM Lb (r m) (X ) q m=1 can be regarded as a Hodge-spectral smooth relaxation of the Vietoris–Rips filtration. In the next section, we apply low-pass spectral filters to these operators and define dif- ferentiable topological objectives for controlling Betti-type and persistent-homological structures.

4 Topological Objectives via Low-Pass Hodge Spectral Filters In this section, we define differentiable topological objectives using the penalty- regularized Hodge-Laplacian-type spectral relaxation Lb q (θ) constructed in the previ- ous section.

16

The basic idea is to regard homology as the zero modes of the Hodge Laplacian and to extract zero and near-zero modes using smooth low-pass spectral filters. For an ordinary simplicial complex K , the q -th Betti number satisfies

βq (K ) = dim ker Lq (K ).

However, directly counting zero eigenvalues, namely the map Lq 7→ dim ker Lq , is discontinuous and is not suitable for gradient-based optimization. Therefore, we use a smooth function f : R≥0 → R that emphasizes the low-eigenvalue region and use

f (L b q (θ)) or     Tr f (L b q (θ))

as differentiable spectral surrogates for topological information. In the hard ordinary- complex case, these quantities approximate information about the kernel of the Hodge Laplacian. In the soft regime, they should be interpreted as low-frequency spectral quantities associated with the Hodge-Laplacian-type relaxation, rather than as exact Betti numbers. We first introduce low-pass spectral filters and define two types of losses: spectral- filter matching losses and trace-type spectral-mass Betti surrogate losses. We then formulate normalized first-Betti-type control for graph clique complexes and topology control for Vietoris–Rips filtrations of point clouds within the same framework. All losses introduced in this section are differentiable with respect to L b q (θ). Since L b q (θ) is constructed from soft-graph edge logits, gradients can be propagated analytically to the edge logits. In the Vietoris–Rips setting, the edge logits are functions of point coordinates through pairwise distances, and hence gradients can also be propagated to the point-cloud coordinates. In this section, we focus on the definitions and roles of the objectives; the detailed backward computation and gradient formulas are given in the Appendix.

4.1 Low-Pass Spectral Filters Let L(θ) = Lb q (θ) be the Hodge-Laplacian-type spectral relaxation, and let

L(θ) = U ΛU ⊤ ,      Λ = diag(λ1 , . . . , λN )

be its eigendecomposition. In the hard ordinary-complex case, homological modes correspond to zero eigenvalues. In addition, near-zero modes with small positive eigen- values may reflect geometrically meaningful structures such as almost-closed cycles, weakly filled holes, or unstable higher-order structures. Thus, it is useful to treat not only exact zero modes but also the low-eigenvalue region smoothly. We call a smooth function f : R≥0 → R a low-pass spectral filter if it emphasizes low eigenvalues and suppresses high eigenvalues. The corresponding matrix function

17

is defined by

f (L) = U f (Λ)U ⊤ ,       f (Λ) = diag(f (λ1 ), . . . , f (λN )).

In this work, we use the following representative filters. The heat filter is defined by                                      λ                                 L fheat (λ) = exp −     ,           Fheat (L) = exp −     , τ                                 τ

where τ > 0 is a temperature parameter. It preserves zero modes and exponentially suppresses high-eigenvalue modes. The resolvent filter is defined by α fres (λ) =       ,       Fres (L) = α(L + αI )−1 , λ+α

where α > 0. It also emphasizes low-eigenvalue modes, but its decay is rational rather than exponential. The polynomial moment filter is defined by

fmom (λ) = (1 − αλ)d ,          Fmom (L) = (I − αL)d ,

where α > 0 and d ∈ N. A zero mode contributes one, while high-eigenvalue modes are suppressed under suitable choices of α and d. More precisely, this polynomial behaves as a low-pass filter only when the positive spectrum is mapped inside the unit disk; this condition is made explicit below. Since this filter is expressed as a polynomial of the Laplacian, it does not require eigendecomposition and is compatible with matrix- vector products, stochastic trace estimation, and structural connections to possible quantum or quantum–classical hybrid computation. As a more stable polynomial approximation, one may also use a Chebyshev poly- nomial filter. After normalizing the Laplacian by an upper bound or estimate of its largest eigenvalue, for example

e = 2L − λmax I , L λmax

so that its spectrum is approximately contained in [−1, 1], define

D X fcheb (L) =         cℓ Tℓ (L e ), ℓ=0

where Tℓ is the ℓ-th Chebyshev polynomial, cℓ are coefficients approximating a desired low-pass function, and D is the polynomial degree. This filter can be computed recursively without eigendecomposition and is useful for approximating low-frequency spectral quantities in large-scale problems.

18

4.2 Spectral-Filter Matching Loss One way to use a low-pass filter is to compare low-energy subspaces themselves. Let θtar be a target parameter and define

Ltar = L b q (θtar ).

For a low-pass filter f , we define the spectral-filter matching loss by

1                        2 Lsf (θ) =        b q (θ)) − f (Ltar ) . f (L 2                        F

This loss compares not only the number of zero modes but also the orientation and distribution of the low-eigenvalue subspace. Therefore, compared with barcode-based losses, it can use richer geometric and spectral information. For the heat and resolvent filters, this gives !                       2 1       L b q (θ)                 Ltar Lheat (θ) =   exp −                 − exp − 2          τ                     τ F

and 1                                       2 Lres (θ) =    α(Lb q (θ) + αI )−1 − α(Ltar + αI )−1 . 2                                       F These losses act to move the current structure toward the low-energy subspace of the target structure. Although the heat and resolvent filters approximate the spec- tral projector onto the kernel in suitable parameter limits, they are not idempotent projectors for finite parameter values. For this reason, we refer to these objectives as spectral-filter matching losses rather than projector losses.

4.3 Trace-Type Spectral-Mass Betti Surrogate Loss Another way to use a low-pass filter is to construct a smooth low-frequency spectral- mass surrogate for Betti-type information from its trace. For a low-pass filter f , define

N X Sf (θ) = Tr f (L b q (θ)) =          f (λi (θ)). i=1

If f (0) = 1 and f (λ) ≈ 0 for high eigenvalues, then Sf (θ) approximates the number of zero and low-eigenvalue modes and can be regarded as a smooth surrogate for βq in the hard ordinary-complex setting, and as a low-frequency spectral mass in the soft setting.

Proposition 3 (Trace approximation of Betti numbers) Let K be a finite simplicial complex and let the eigenvalues of the ordinary Hodge Laplacian Lq (K) be 0 = λ1 = · · · = λβq < λβq +1 ≤ · · · ≤ λN .

19

Let f : R≥0 → R satisfy f (0) = 1, and define εf = max |f (λi )|. i>βq

Then |Tr f (Lq (K)) − βq (K)| ≤ (N − βq )εf .

Proof Since f (Lq (K)) has eigenvalues f (λi ), we have N X                           N X Tr f (Lq (K)) =         f (λi ) = βq (K) +             f (λi ). i=1                        i=βq +1

Taking absolute values gives the stated bound.                                         □

Given a target spectral-mass value τq , define

1               2 Ltrace (θ) =       (Sf (θ) − τq ) . 2 In particular, for the polynomial moment filter, set             d Sq,d (θ) = Tr I − αL b q (θ)

and define 1                 2 Lmom (θ) =         (Sq,d (θ) − τq ) . 2 For an ordinary hard complex, if

ρ = max |1 − αλi | < 1, λi >0

then Tr(I − αLq (K ))d − βq (K ) ≤ (N − βq )ρd . Thus, the parameters α and d should be chosen together with an appropriate spectral scaling of the Laplacian. This loss moves the low-frequency spectral mass toward the target value without explicitly counting Betti numbers.

4.4 Normalized Spectral-Moment Betti Surrogate When graph sizes or ambient chain-space dimensions differ, directly comparing trace values introduces scale dependence due to the number of simplices. Therefore, let

Nq = dim Cqamb

and define the normalized moment

1                d S q,d (θ) =      Tr I − αL b q (θ) . Nq

20

In the hard ordinary-complex setting, this normalization corresponds to comparing a Betti-type quantity per q -simplex. In the soft ambient setting, it should be interpreted as normalized low-frequency spectral mass. Given a target normalized value τ̄q , define

1                2 Lnorm (θ) =      S q,d (θ) − τ̄q . 2 This normalization yields topological losses that are more comparable across graphs or ambient complexes of different sizes.

4.5 Normalized First-Betti-Type Control in Graph Clique Complexes In graph generation or graph-structured topology control, the optimization variables are the edge logits a = {ae }e∈Emax . The edge activations pe (a) = σ (ae ) define a soft clique complex and hence a Hodge- Laplacian-type spectral relaxation Lb q (a). To control one-dimensional cyclic structures in the hard clique-complex limit, we take q = 1 and use

L         e1 (a)⊤ B b 1 (a) = B       e1 (a) + B     e2 (a)⊤ + µ(I − W1 (a)). e2 (a)B

Define the Laplacian moment and its normalized version by             d                       1                d S1,d (a) = Tr I − αL b 1 (a) ,         S 1,d (a) =      Tr I − αL b 1 (a) , N1

where N1 = dim C1amb . The quantity S 1,d (a) can be regarded as a normalized β1 -type surrogate in the hard-limit sense, and as a normalized low-frequency H1 -type spectral mass in the soft setting. Given a target normalized spectral-mass value τ̄1 , define the graph topological loss by

1                2 Ltopo graph (a) =     S 1,d (a) − τ̄1 . 2 In practical graph-generation tasks, one may combine this topological loss with ordinary graph objectives such as edge density, degree distribution, clustering coeffi- cient, or task-dependent losses. If such a base loss is denoted by Lbase (a), the total loss is Ltotal (a) = Lbase (a) + λtopo Ltopo graph (a), where λtopo > 0 controls the strength of topological regularization. This formulation allows one to optimize ordinary graph-structural objectives while controlling cyclic structures corresponding to β1 of the clique complex. The ambient normalization above is the abstract formulation used in this section. In the numerical graph experiments below, we use an ordinary-complex or weighted-current-complex implementation and normalize by an effective edge count; the relation between these choices is discussed in Section 6.

21

4.6 Topology Control for Vietoris–Rips Filtrations Let X = {x1 , . . . , xn } ⊂ Rd be a point cloud, and let r1 < r2 < · · · < rM be a sequence of scales. For each scale rm , define the edge logits by

rm − dij (X ) q (r ) aij m (X ) =                 ,         dij (X ) =       ∥xi − xj ∥2 + δ. ε These logits define a soft graph, a soft clique complex, and a Hodge-Laplacian-type spectral relaxation Lb (r m) (X ) q at each scale. Since persistent homology describes the birth and death of homology classes across scales, the corresponding Laplacian-based losses are defined as sums over scales.

4.6.1 Trace-Type Vietoris–Rips Loss Barcode-based losses often reduce undesired homology by penalizing persistence, for example                                 X LPD (X ) =    (dγ − bγ )2 . γ∈U In the Laplacian-based formulation, we instead use the low-frequency spectral mass at each scale,                                             Sq(rm ) (X ) = Tr f Lb (r q m) (X ) . To suppress q -dimensional homology, one can minimize

M X                            Lsup VR (X ) =           ωm Tr f Lb (r q m) ( X )  , m=1

where ωm ≥ 0 are scale weights. Conversely, to preserve or generate a prescribed topological structure, one can (r ) specify target low-frequency spectral masses τq m and define

M                                 2 1 X                       Ltrace VR (X ) =           ωm Tr f Lb (r q m) (X ) − τq(rm ) . 2 m=1

This loss can be interpreted as a smooth Laplacian-based approximation of the low- frequency Hq -type spectral mass present at each scale. In the hard limit and with sufficiently sharp filters, this quantity is related to the Betti profile across scales, but it is not itself a persistence-diagram loss.

22

4.6.2 Spectral-Filter Matching Vietoris–Rips Loss When a target point cloud Xtar is given, we can match low-energy subspaces at each scale. Define b (r Lm (X ) = L    m) (X ),   Ltar  b (rm ) (Xtar ). q              m = Lq Then M 1 X                            2 Lsf VR (X ) =          ωm f (Lm (X )) − f (Ltar m ) F . 2 m=1 For the heat and resolvent filters, this gives

M !                             ! 2 1     X               b (r L q m) (X )               b (r L q m) (Xtar ) Lheat VR (X ) =            ωm   exp −                    − exp − 2 m=1                    τ                           τ F

and M                           −1                          −1           2 1 X                                 Lres VR (X ) =         ωm α Lb (r q m) (X ) + αI     −α Lb (r q m) (Xtar ) + αI       . 2 m=1                                                          F

Unlike barcode-based losses, which compare birth–death pairs, this loss compares low- energy subspaces at each scale. Therefore, it is designed to reduce gradient localization on critical simplices and to provide update directions that retain more geometric and spectral information. Since the Vietoris–Rips edge logits are functions of the point- cloud coordinates, these losses are differentiable with respect to the point coordinates.

4.7 Practical Choice of Objectives The objectives above are intended for different uses. Spectral-filter matching losses are appropriate when a target point cloud, graph, or simplicial complex is available and one wants to align low-frequency Hodge spectral structure with that target. Trace- type spectral-mass losses are appropriate when the goal is to control the amount of q -dimensional topological structure without specifying a target low-eigenvalue sub- space. Normalized moment losses are useful when comparing complexes with different numbers of simplices or when controlling graph clique complexes. This table also clarifies the numerical experiments below. The Vietoris–Rips experiments examine whether spectral-filter losses provide useful gradients for point- cloud topology control, while the graph experiments examine whether normalized polynomial moments can control first-Betti-type quantities of clique complexes.

5 Numerical Experiments on Vietoris–Rips Topology Control In this section, we compare topology control based on persistent homology with the proposed Hodge spectral-filter losses on Vietoris–Rips filtrations. The purpose of these experiments is to examine whether the proposed Hodge-spectral losses can control

23

Table 1 Practical interpretation of the proposed Hodge-spectral objectives.

Goal                            Suggested objective              Interpretation Match a target point cloud      Spectral-filter matching loss    Aligns low-frequency Hodge spec- or target complex                                                tral structure with that of a target object. Control the amount of q-        Trace-type spectral-mass loss    Moves the low-frequency spectral dimensional topology                                             mass toward a prescribed value. Control a Betti-type profile    Scale-wise Vietoris–Rips spec-   Controls low-frequency Hq -type across scales                   tral loss                        structure over selected scales. Control cyclic structure in     Normalized         polynomial    Controls a normalized β1 -type graph clique complexes          moment loss                      spectral quantity. Scale to larger complexes       Polynomial, Chebyshev, or        Avoids full eigendecomposition trace-estimation-based filters   and uses matrix-vector or trace- estimation routines.

H1 -type structures without explicitly optimizing barcode diagrams, and whether they alleviate some of the characteristic difficulties of persistence-diagram losses, such as gradient localization and sensitivity to persistence-pairing changes. These experiments are intended to study the behavior of the optimization signals rather than to replace persistent homology as a topological descriptor.

5.1 Experimental Setup Let X = {x1 , . . . , xn } ⊂ R2 be a point cloud. For each scale r, we consider the Vietoris–Rips complex

VRr (X ).

In the persistent-homology baseline, the loss is defined directly from the H1 barcode. For example, to suppress or control one-dimensional homological features, we use losses based on the persistence values dγ − bγ of H1 bars. For the proposed Hodge-based losses, we construct a Hodge-Laplacian-type spectral relaxation b (r) (X ) L 1 for each scale r, and then apply a low-pass spectral filter. We mainly use the heat filter ! b (r) (X ) L Fτheat,(r) (X ) = exp    − 1 τ

24

Fig. 1 Multi-scale topology control from a random point cloud. The exact Betti-profile sum is used only as a diagnostic of the optimized point clouds.

and the resolvent filter                  −1 Fϵres,(r) (X ) = ϵ Lb (r) (X ) + ϵI     . 1

For multi-scale objectives, we sum these quantities over a finite set of scales

I = {r1 , . . . , rm }.

The Hodge spectral-filter losses are combined with mild geometric regularization terms to avoid degenerate point configurations such as excessive collapse or excessive spreading. These regularization terms are used only to keep the point-cloud geome- try numerically well behaved; the topological signal itself is provided by the Hodge spectral filters.

5.2 Multi-Scale Topology Control from Random Point Clouds We first test whether the Hodge spectral-filter losses can induce low-frequency H1 - type structures across multiple Vietoris–Rips scales. We initialize n = 36 points in the square [−1, 1]2 , and use the scale interval

I = {0.42, 0.46, 0.50, 0.54, 0.58, 0.62}.

We compare a persistent-homology baseline, the Hodge heat objective, and the Hodge resolvent objective. Figure 1 shows the initial point cloud and the optimized point clouds after 10 epochs. The Hodge objectives, especially the resolvent objective, produce point clouds with more pronounced loop-like structures than the PH baseline in this example. We evaluate the exact Betti number over the scale interval by X β1 (VRr (X )). r∈I

This quantity is used as an exact Betti-profile diagnostic of the optimized point cloud; it is not the differentiable objective optimized by the Hodge spectral-filter losses. The

25

Fig. 2 Gradient directions for PH and Hodge spectral-filter losses.

Fig. 3 Gradient localization metrics. Higher entropy and lower top-10% mass indicate a more spa- tially distributed gradient norm profile.

initial point cloud has value 1, the PH baseline reaches 2, the Hodge heat objective reaches 10, and the Hodge resolvent objective reaches 28. Thus, the Hodge spectral- filter losses increase low-frequency H1 -type spectral structure across the selected scale range without directly optimizing persistence diagrams. This result should be inter- preted as a scale-wise Hodge-spectral effect rather than as direct optimization of a persistence diagram.

5.3 Gradient Localization Next, we compare the localization of gradients for PH losses and Hodge spectral-filter losses. The PH loss is based on the squared sum of finite H1 persistence values, while the Hodge losses are based on heat and resolvent trace sums over the selected scales. Figure 2 visualizes the gradient directions for an input point cloud. The PH squared-sum gradient is concentrated on a small number of points, whereas the Hodge heat and Hodge resolvent gradients are distributed more globally around the point cloud for this input. To quantify this behavior, we compute the entropy of the gradient norm distribu- tion and the mass carried by the top 10% of points with largest gradient norms. The results are shown in Figure 3. The PH squared-sum loss has gradient entropy 1.3863 and top-10% mass 0.5000. The Hodge heat trace-sum loss has entropy 2.4623 and top- 10% mass 0.2049. The Hodge resolvent trace-sum loss has entropy 2.4740 and top-10% mass 0.2018.

26

Fig. 4 Point clouds used for the pairing-instability test.

Fig. 5 Loss and derivative under pairing stress. The comparison of derivative jumps is interpreted in a scale-normalized sense.

These results are consistent with the interpretation that PH losses tend to con- centrate gradients around critical simplices, while Hodge spectral-filter losses provide more spatially distributed update directions. The comparison concerns the spatial dis- tribution of gradient norms in these experiments, not a general dominance statement for all PH-based objectives.

5.4 Pairing Instability Stress Test We next examine sensitivity to persistence-pairing changes. We construct a point cloud with two similar loop-like structures and vary a parameter α, which changes the relative sizes of the two loops. Representative point clouds for α = −0.14, α = 0, and α = 0.14 are shown in Figure 4. For the PH baseline, we use a loss based on the largest H1 persistence value. Around α = 0, the two dominant H1 bars can exchange their order, causing a sharp change in which bar is selected by the loss. For the Hodge method, we use an interval Hodge spectral-filter loss over the scale interval [0.98, 1.12]. Figure 5 shows the normalized losses and their derivatives with respect to α. The PH loss has a sharp derivative jump near the pairing switch, whereas the interval Hodge spectral-filter loss changes more smoothly after normalization by the loss range. Quantitatively, the maximum raw derivative jump is 1.1773 for the PH loss and 15.8489 for the interval Hodge spectral-filter loss. Thus, the Hodge loss is not uniformly

27

Fig. 6 Recovered radial profiles and RMSE in the controlled radial-shape synthesis experiment .

smoother in raw scale. However, the absolute magnitudes and dynamic ranges of the two losses are different. After normalization by the loss range, the maximum derivative jump is 11.2194 for the PH loss and 1.6137 for the Hodge loss. Therefore, in this experiment, the Hodge interval loss exhibits a substantially smaller derivative jump relative to its own scale. This supports the interpretation that the Hodge-spectral objective provides a smoother optimization signal in a scale-normalized sense.

5.5 Shape Synthesis by Analytic Gradients We next test whether the analytic gradients of the losses can guide point-cloud shape synthesis. We parameterize a radial point cloud by

xi (ri ) = (ri cos θi , ri sin θi ),

where the angles θi are fixed and the radii ri are optimized. The target shape is a wavy ring. We compare PH gradient updates, Hodge heat filter gradient updates, and Hodge resolvent filter gradient updates. Figure 6 shows the recovered radial profiles and the mean RMSE with respect to the target radial profile. The PH gradient update gives final RMSE

0.1504 ± 0.0172,

whereas the Hodge heat projector gives

0.0324 ± 0.0092,

and the Hodge resolvent projector gives

0.0224 ± 0.0054.

Thus, the Hodge spectral-filter gradients recover the target shape more accurately in this controlled radial-shape experiment.

28

Fig. 7 Shape synthesis by analytic gradients.

Fig. 8 Complex size and one-step gradient runtime. The Hodge spectral-filter losses are evaluated using dense matrix operations in this implementation.

Figure 7 visualizes the initial circle, target wavy shape, and the results obtained by the three update rules. The Hodge heat and resolvent filter updates follow the target deformation more closely than the PH update. We also compute the cosine similarity between the first update direction and the desired target deformation direction. The PH gradient has mean cosine similarity −0.2156, the Hodge heat filter has 0.2143, and the Hodge resolvent filter has 0.8311. This indicates that the resolvent filter provides an initial update direction strongly aligned with the desired geometric deformation in this experiment. The first-gradient entropy is 1.2627 for PH, 2.5367 for Hodge heat, and 2.5274 for Hodge resolvent. Again, the Hodge spectral-filter gradients are less localized and more globally distributed according to this entropy metric.

5.6 Runtime Comparison Finally, we compare the cost of one loss-gradient evaluation. We vary the number of points as n = 12, 16, 20, 24, 28, 32, 36, 40, 48, 56, 64, 70, 80, 90, 100. For each n, we measure the runtime of one gradient step for PH, Hodge heat, and Hodge resolvent losses. The results are shown in Figure 8. At n = 100, the PH gradient evaluation takes

3.4515 s,

29

the Hodge heat gradient evaluation takes

60.4083 s,

and the Hodge resolvent gradient evaluation takes

43.5290 s.

Thus, at this scale, Hodge heat is about 17.5 times slower than PH, and Hodge resolvent is about 12.6 times slower. This increased cost is expected because the Hodge spectral-filter losses use richer spectral information. In the current implementation, dense matrix operations are used, and the number of ambient edges and triangles grows rapidly with n. There- fore, applying the Hodge spectral-filter losses to larger problems will require more scalable implementations, such as sparse linear algebra, Chebyshev polynomial approx- imation, and stochastic trace estimation. Possible quantum or quantum–classical trace-estimation approaches are a separate future direction and are not used in the present experiments.

6 Normalized First-Betti-Type Control on Graph Clique Complexes via Laplacian Moments In this section, we apply the Laplacian-moment topological loss introduced in Section 4 to normalized first-Betti-type control in graph clique complexes. In particular, we focus on the first homology of the clique complex of a graph and control a quantity corresponding to the normalized Betti number

β1 , |K1 |

where K1 denotes the set of 1-simplices, namely the set of edges, in the clique complex. In the soft optimization problem below, this hard normalized Betti number is used as an evaluation quantity, while the differentiable loss is applied to a calibrated soft spectral moment. In the theoretical formulation developed in the previous sections, we constructed a Hodge-Laplacian-type spectral relaxation on a fixed ambient chain space and introduced a penalty term to remove inactive directions. However, in the numerical experiments in this section, we do not use the full ambient penalty-regularized opera- tor. Instead, we use a weighted-current-complex implementation: the edge and triangle spaces are represented by the current soft graph weights, weighted boundary matri- ces are assembled from these weights, and the moment is computed without adding an inactive ambient block. For sampled hard graphs, this construction reduces to the ordinary Hodge Laplacian on the sampled clique complex. In this case, the chain space itself corresponds to the current weighted or sampled clique complex, and inactive simplex directions do not exist as a separate ambient block. Therefore, no penalty term is required to push inactive directions away from the low-energy region.

30

We first explain why the Laplacian moment based on the ordinary Hodge Laplacian can be theoretically justified as a surrogate for the normalized Betti number in the hard-complex setting. We then discuss the relation between the ordinary-complex computation, the ambient formulation, and polynomial trace estimation. Finally, we present the results of our numerical experiments.

6.1 Normalized Betti Surrogate Based on the Ordinary Hodge Laplacian for Hard Clique Complexes Let G = (V, E ) be a graph, and let its clique complex be K = X (G). Let Cq (K ) be the q -th chain space, and let Bq : Cq (K ) → Cq−1 (K ) be the boundary operator. The ordinary q -th Hodge Laplacian is defined by

Lq (K ) = Bq⊤ Bq + Bq+1 Bq+1 ⊤ .

By the Hodge decomposition,

ker Lq (K ) ≃ Hq (K ).

Therefore, dim ker Lq (K ) = dim Hq (K ) = βq (K ). In particular, for q = 1, dim ker L1 (K ) = β1 (K ). The important point is that Lq (K ) is defined not on an ambient space but on the actual chain space Cq (K ) of the clique complex K . Hence, the inactive simplex directions that appear in the ambient formulation do not exist in this space. Therefore, when using the ordinary Hodge Laplacian, zero modes directly correspond to homology classes, and the penalty term µ(I − Wq ) for removing inactive directions is unnecessary. This subsection serves as the hard-complex reference. In the soft optimization experiments below, the differentiable objective is evaluated using weighted boundary matrices. The final topological evaluation is then performed by sampling hard graphs from the optimized edge probabilities and computing the ordinary Betti number of the sampled clique complexes.

6.2 Laplacian Moments and Normalized Betti Numbers To treat normalized Betti numbers as differentiable objectives in the hard ordinary- complex setting, we use the polynomial moment filter

fd (λ) = (1 − αλ)d ,

where α > 0 and d ∈ N. For the ordinary Hodge Laplacian Lq (K ), define the Laplacian moment by

d Sq,d (K ) = Tr (I − αLq (K )) .

31

We then normalize this quantity by the number of q -simplices,

Nq = dim Cq (K ) = |Kq |,

and define d Tr (I − αLq (K )) S q,d (K ) =                     . Nq Let the eigenvalues of Lq (K ) be

0 = λ1 = · · · = λβq < λβq +1 ≤ · · · ≤ λNq .

Then Nq X Sq,d (K ) =           (1 − αλi )d . i=1 The contribution from each zero eigenvalue is equal to one. Therefore,

Nq X Sq,d (K ) = βq (K ) +                 (1 − αλi )d . i=βq +1

If α is chosen so that ρ = max |1 − αλi | < 1, λi >0 then |Sq,d (K ) − βq (K )| ≤ (Nq − βq )ρd . Therefore, for the normalized quantity,

βq (K )   Nq − βq d S q,d (K ) −           ≤        ρ ≤ ρd . Nq         Nq

Thus, when ρd is sufficiently small,

βq (K ) S q,d (K ) ≈              . Nq

In particular, for q = 1, d Tr (I − αL1 (K ))   β1 (K ) S 1,d (K ) =                     ≈         . |K1 |         |K1 |

In this sense, the Laplacian moment based on the ordinary Hodge Laplacian is a theoretically justified surrogate for the normalized Betti number when the spectrum is scaled so that the positive eigenvalues are suppressed by the polynomial filter.

32

6.3 Relation to the Ambient Formulation In the theoretical formulation of the previous sections, the Hodge-Laplacian-type spectral relaxation was defined on an ambient chain space containing all candidate sim- plices. In that setting, inactive simplex directions remain as ambient basis directions, and a penalty term is needed to exclude them from the low-energy region. In the hard limit, the penalty-regularized ambient Hodge Laplacian decomposes as

b q → Lq (K ) ⊕ µIinactive . L

Here, Lq (K ) is the ordinary Hodge Laplacian on the active complex, and µIinactive is the block acting on inactive directions. For the Laplacian moment, we obtain         d b q → Tr (I − αLq (K ))d + Nqinactive (1 − αµ)d . Tr I − αL

Therefore, if α and µ are chosen so that

|1 − αµ|d ≪ 1,

then the forward contribution from the inactive block is negligible. Moreover, the derivative of the moment filter is

fd′ (λ) = −αd(1 − αλ)d−1 .

Thus, the backward contribution from inactive directions is controlled by

αd|1 − αµ|d−1 .

Therefore, if |1 − αµ|d−1 ≪ 1, then inactive directions also have negligible influence on the gradient. In particular, when αµ ≃ 1, the inactive block contributes almost nothing to either the forward or backward com- putation of the Laplacian moment. In this sense, the numerical computation in this section using the ordinary Hodge Laplacian can be viewed as the limit of the ambient formulation in which inactive directions are completely removed, or as the regime in which their contribution is negligible.

Lemma 4 (Ambient-to-ordinary reduction for polynomial moments) Suppose that, in the hard limit, the ambient operator decomposes as b q = Lq (K) ⊕ µIinactive . L Let fd (λ) = (1 − αλ)d . Then b q ) = Tr fd (Lq (K)) + Nqinactive (1 − αµ)d . Tr fd (L

33

Moreover, fd′ (µ) = −αd(1 − αµ)d−1 . d               d−1 Thus, if |1 − αµ| and |1 − αµ|          are small, both the forward moment contribution and the local filter derivative associated with the inactive block are negligible. In this regime, the polynomial moment of the ambient operator reduces to the ordinary-complex moment up to a negligible inactive-block contribution.

6.4 Relation to Polynomial Trace Estimation The Laplacian moment Tr(I − αLq )d has the same general form as polynomial trace quantities used in normalized Betti- number estimation. Since zero modes contribute one and suitably filtered nonzero modes are suppressed, such traces can approximate normalized kernel dimensions when the spectrum is properly scaled. This connection is useful computationally because polynomial filters can be evaluated by matrix-vector products and can be combined with stochastic trace estimation. This viewpoint is closely related to recent trace-estimation approaches for esti- mating normalized Betti numbers of clique complexes Lloyd et al. (2016); Akhalwaya et al. (2024); Gyurik et al. (2022). In such approaches, Betti numbers are represented through the null space of a combinatorial Laplacian or a related reflected operator, and polynomial traces are used to approximate the normalized dimension of this null space. The polynomial moment used in this paper has the same mathematical form, but here it is used as a differentiable objective inside a graph optimization loop. The same polynomial-trace structure is also compatible with quantum trace- estimation viewpoints. However, this paper does not implement a quantum algorithm and does not claim quantum advantage. We therefore treat the quantum connection only as a structural observation and a possible future direction. The main contribu- tion of this section is the use of Laplacian moments as differentiable first-Betti-type objectives for graph clique complexes.

6.5 Numerical Results In the numerical experiments, each candidate edge e = (i, j ) is assigned an edge logit ae . The edge probability is defined by

1 pe = σ (ae ) =                 . 1 + exp(−ae )

For a triangle σ = (i, j, k ), the weight is defined by Y wσ =          pe . e⊂σ

This gives a weighted clique complex from a soft graph. We then compute the weighted- current-complex version of the first Hodge Laplacian.

34

Let √                          √ R1 = diag( pe )e∈Emax ,      R2 = diag( wσ )σ∈K (2) . max Since vertex weights are fixed to one, we use

B e1 = B1 R1 ,        B e2 = R1 B2 R2 .

The soft weighted first Hodge-Laplian-type operator used in the experiments is

Lsoft  e1⊤ B =B   e1 + B  e2⊤ . e2 B 1

Unlike the ambient operator in Section 3, this implementation does not include the inactive-direction penalty term. We define M = I − αLsoft1   and compute the Laplacian moment

S1,d = Tr(M d ).

For normalization, we use the effective edge count N1eff = P e pe , and define

S1,d S 1,d =             . N1eff + δ

Here N1eff is the soft analogue of the number of active edges |K1 |, and δ > 0 is a small numerical stabilizer. Given a fixed soft moment target s̄⋆1 , the soft spectral-moment Betti loss is 1              2 LBetti =     S 1,d − s̄⋆1 . 2 Here, s̄⋆1 is the target used in the differentiable soft optimization. It should be distin- guished from the hard normalized Betti target β̄1⋆ , which is used to evaluate sampled hard graphs after optimization.

Soft and hard targets. The soft moment target s̄⋆1 and the hard normalized Betti target β̄1⋆ are conceptu- ally different quantities. The loss above optimizes the differentiable soft moment S 1,d toward s̄⋆1 . After optimization, we sample hard graphs from the final edge probabilities and compute the ordinary normalized Betti number β1 /|K1 | of their clique complexes. This sampled hard value is then compared with the hard target β̄1⋆ . In the present proof-of-concept experiments, the soft target values are specified before optimization and kept fixed during each run. We do not claim an analytic or universal conversion rule from β̄1⋆ to s̄⋆1 . Instead, the experiments test whether optimizing the prescribed soft spectral moment induces sampled hard graphs whose normalized first Betti numbers move toward the desired hard target. The soft targets used in each experiment are reported explicitly in the tables. In the experiments, we used α = 0.15 as the basic setting, and mainly used d = 8. The edge logits were optimized using an Adam-type update, and both forward and backward computations were performed using the ordinary Hodge Laplacian.

35

Fig. 9 (left) Path-integral estimate compared with the exact trace-gradient. (right) Mean absolute error of the path-integral estimator.

6.5.1 Convergence of the Path-Integral Estimator We first compare the path-integral estimator with the exact value of the trace-gradient

Tr(M d−1 Cu )

for a fixed soft graph and a fixed direction u. In this experiment, the number of nodes is set to n = 8, and the moment order is set to d = 6. The number of Monte Carlo samples is varied over

NMC ∈ {100, 300, 1000, 3000, 10000},

and the estimator is evaluated multiple times for each sample size. Figure 9 compares the mean and standard deviation of the path-integral estimator with the exact trace-gradient. The dashed line represents the exact value, the blue curve represents the mean of the path-integral estimator, and the error bars represent the standard deviation. When the number of samples is small, the variance is large and the estimator deviates significantly from the exact value. As NMC increases, the estimator approaches the exact value, and in particular, at NMC = 10000, it reaches the neighborhood of the exact value. Figure 9 shows the mean absolute error with respect to the exact value. The mean absolute errors are 1.2014 for NMC = 100, 0.4782 for NMC = 300, 0.6399 for NMC = 1000, 0.2626 for NMC = 3000, and 0.1518 for NMC = 10000. At NMC = 1000, the error temporarily increases. This is due to the variance caused by a finite number of Monte Carlo trials. For larger sample sizes, the error decreases again, confirming the tendency of the path-integral estimator to approach the exact trace-gradient. These results show that the proposed path-integral backward estimator functions as a Monte Carlo estimator of the trace-gradient.

6.5.2 Convergence of Betti Loss Optimization Next, we verify whether the proposed Betti loss can actually be minimized. In this experiment, the number of nodes is set to n = 10, the hard normalized Betti target is

36

Table 2 Mean absolute error of the path-integral trace-gradient estimator.

NMC      Mean absolute error 100           1.2014 300           0.4782 1000           0.6399 3000           0.2626 10000          0.1518

Fig. 10 (left)Convergence of the Betti loss during optimization. (right) Convergence of the soft Betti moment toward the target.

set to β̄1⋆ = 0.10, and the soft moment target used in the differentiable loss is fixed to s̄⋆1 = 3.0717. The optimization is performed using the exact coordinate gradient and is terminated when the improvement of the loss reaches a plateau. Figure 10 shows the evolution of the Betti loss over optimization steps. The loss rapidly decreases in the early stage and then converges near zero with small oscilla- tions. This result shows that the proposed soft projector Betti loss provides an effective learning signal for the edge logits. Figure 10 shows the corresponding trajectory of the soft Betti moment. The dotted line represents the fixed soft moment target s̄⋆1 . The soft moment initially decreases below the target, then oscillates and returns toward the target, eventually stabilizing in its neighborhood. This behavior demonstrates that the Betti loss directly controls the soft moment toward the prescribed soft target. In this experiment, the optimization reaches a plateau after 45 steps. The final loss is 1.09 × 10−5 , the final soft spectral moment is 3.0763, and the fixed soft target is s̄⋆1 = 3.0717. Thus, the absolute error with respect to the soft target is reduced to 0.0047. These results confirm that minimizing the soft spectral-moment Betti loss drives the soft moment very close to the fixed soft target. Moreover, when hard graphs are sampled from the final soft graph, the mean ordinary hard normalized β1 of the sampled clique complexes is 0.1014, yielding an error of only 0.0014 with respect to the hard target 0.10. Therefore, in this example, the minimization of the soft Betti loss is reflected in the topology of the sampled hard graphs.

37

Table 3 Final result of Betti loss optimization for hard normalized Betti target 0.10. The loss is optimized against the fixed soft moment target s̄⋆ 1 = 3.0717. The hard target is used for evaluation after sampling hard graphs from the optimized edge probabilities.

Quantity                                Value Number of steps                           45 Final loss                           1.09 × 10−5 Final soft spectral moment              3.0763 Fixed soft target s̄⋆ 1                   3.0717 Soft target error                       0.0047 Sampled hard normalized β1 mean         0.1014 Sampled hard normalized β1 std          0.0904 Hard target β̄1⋆                        0.1000 Hard target error                       0.0014 Sampled edge density mean               0.2564

On the other hand, the hard β1 of a single thresholded graph is 0.0. This is because converting a soft graph into a hard graph by a single threshold is a discrete operation and is sensitive to the threshold value. Therefore, in these experiments, we evaluate the final hard topology by sampling multiple hard graphs from the edge probabilities and computing the mean normalized Betti number. This evaluation better reflects the probabilistic output of the soft generative model.

6.5.3 Topology-Controlled Graph Generation We next examine whether the generated graph topology follows different hard target normalized Betti values. In this experiment, the number of nodes is set to n = 15, and the hard target values are chosen as

β̄1⋆ ∈ {0.02, 0.05, 0.10, 0.20}.

For each hard target, we specify a fixed soft moment target s̄⋆1 used in the differen- tiable loss. These soft targets are reported in Table 4. For all targets, optimization is initialized from the same soft graph. Figure 11 shows the relationship between the target normalized Betti value and the sampled hard normalized β1 after optimization. The black dashed line indicates y = x, the orange dotted line indicates the mean β1 of the shared initial graph, and the green points with error bars indicate the mean and standard deviation of the sampled hard β1 after optimization. The mean sampled hard normalized β1 of the initial graph is 0.1604, with standard deviation 0.0769. Therefore, for targets 0.02 and 0.05, the optimization must decrease β1 , while for target 0.20, it must increase β1 . As shown in Figure 11, the optimized sampled hard β1 increases monotonically with the target and moves from the initial graph value toward each target. The final results are shown in Table 4.

38

Fig. 11 Initial and final sampled hard normalized Betti values for different targets. The dashed black line indicates y = x, the orange dotted line indicates the mean Betti value of the shared initial graph, and the green curve shows the optimized results with standard deviation error bars. The final hard Betti values follow the target values after optimization.

Table 4 Topology-controlled graph generation. “Soft mom.” denotes the optimized soft spectral moment S 1,d , and “Soft target” denotes the fixed soft moment target s̄⋆ 1 used in the differentiable loss. Hard β1 values are computed from sampled hard clique complexes and compared with the hard target β̄1⋆ .

Target β1     Steps     Soft mom.      Soft target    Soft err.   Hard β1 mean        Hard β1 std        Hard err.   Density 0.02         176        0.2562         0.2492        0.0070        0.0068             0.0135            0.0132     0.5671 0.05          43        0.8180         0.8878        0.0699        0.0447             0.0457            0.0053     0.4713 0.10          50        1.3477         1.3480        0.0002        0.1173             0.0744            0.0173     0.3978 0.20          59        2.4705         2.4937        0.0231        0.1999             0.0831            0.0001     0.2997

Figure 12 compares the soft target error and the hard target error for each target. The soft error is relatively large for target 0.05, but the hard error remains small overall. In particular, for target 0.20, the hard error is almost zero. This indicates that the proposed method can generate graphs close to the desired target not only in terms of the prescribed soft moment but also in terms of the hard topology after sampling. These results confirm that the final sampled hard normalized β1 generally increases as the target increases. In particular, for targets 0.05 and 0.20, the hard target errors are 0.0053 and 0.0001, respectively, indicating that graphs very close to the target topology are generated. For target 0.10, the mean hard β1 is 0.1173, with an error of 0.0173, but it still moves from the initial value 0.1604 toward the target. For tar- get 0.02, the final mean is 0.0068, which slightly underestimates the target, but the optimization successfully reduces β1 significantly from the initial value. The sampled edge density decreases as the target β1 increases, taking values 0.5671, 0.4713, 0.3978, and 0.2997. This is because, when the edge density is too high, loops

39

Fig. 12 Final soft and hard target errors for topology-controlled graph generation. The soft target error is computed from the optimized soft moment, while the hard target error is computed from sampled hard graphs. The hard topology follows the target values with small errors.

are more likely to be filled by triangles, reducing the first Betti number. Therefore, the proposed method does not merely increase or decrease edges. Rather, it controls β1 through the balance between loops and filling triangles in the clique complex. These results show that topology-controlled graph generation with different hard target normalized Betti values can be achieved using the soft spectral-moment Betti loss together with fixed soft moment targets.

6.5.4 Combination with Graph Feature Loss Finally, we examine whether the soft spectral-moment Betti loss can be combined with another graph feature loss. As an independent graph feature, we use the soft degree variance. The objective function is defined as the sum of the soft spectral-moment Betti loss and the degree variance loss. The target hard normalized β1 is fixed to 0.10, while the degree variance target is varied over 0.41, 0.45, and 0.49. For each condition, we run experiments with five random seeds. As a baseline, we use a variance-only optimization method, which optimizes only the degree variance. This baseline approaches the degree variance target but does not use the Betti loss. Therefore, it serves as a control experiment to check whether the Betti topology is preserved. Figure 13 shows the sampled hard normalized β1 for the variance-only baseline and the joint optimization. The dashed horizontal line indicates the Betti target 0.10. In the variance-only baseline, the hard β1 remains around 0.16 for all variance targets, deviating significantly from the Betti target. In contrast, the joint optimization keeps the hard β1 around 0.11, close to the target 0.10. Figure 13 shows the achieved soft degree variance. The dashed line indicates the degree variance target. Both the variance-only baseline and the joint optimization

40

Fig. 13 (left) Hard Betti preservation under joint optimization. (right) Achieved degree variance under joint optimization.

Table 5 Variance-only and joint optimization.

Var. target      Method         Var. mean      Var. std   Hard β1 mean      Hard β1 std     Hard β1 err. 0.41        Variance-only     0.4036         0.0079       0.1692           0.0121          0.0692 0.41            Joint         0.4112         0.0030       0.1100           0.0076          0.0108 0.45        Variance-only     0.4556         0.0158       0.1627           0.0106          0.0627 0.45            Joint         0.4504         0.0034       0.1125           0.0067          0.0125 0.49        Variance-only     0.4987         0.0172       0.1596           0.0089          0.0596 0.49            Joint         0.4892         0.0043       0.1088           0.0090          0.0102

follow the degree variance target well. In particular, the joint optimization does not significantly degrade the control of degree variance. The numerical results are shown in Table 5. The variance-only baseline achieves values close to the degree variance target, but the sampled hard β1 remains around 0.16, far from the target 0.10. The hard β1 error ranges from approximately 0.0596 to 0.0692. In contrast, the joint optimization achieves values close to the degree variance target while keeping the sampled hard β1 in the range from 0.1088 to 0.1125. The hard β1 error is approximately between 0.0102 and 0.0125, which is much smaller than that of the variance-only baseline. These results show that the Betti loss is not merely a special regularization term that conflicts with other graph feature objectives. Rather, it functions as a topology- aware objective that can be combined with ordinary graph statistics. In other words, the proposed method can control a standard graph feature such as degree variance while simultaneously keeping the first-order topology of the clique complex near the target value.

41

7 Summary and Discussion In this work, we proposed a framework for differentiably controlling homological constraints on finite simplicial complexes using the low-frequency spectrum of Hodge- Laplacian-type spectral relaxations. The central idea is not to treat Betti numbers or persistent homology directly as discrete quantities, but instead to extract zero and near-zero modes, which correspond to homological structures in the hard ordinary- complex limit, using smooth spectral filters. In the soft regime, these quantities should be interpreted as low-frequency Hodge-spectral surrogates rather than as exact homological invariants. The main contributions of this work can be summarized as follows. First, we intro- duced an ambient Hodge-spectral relaxation on a fixed chain space and showed that, in the hard limit, the penalty-regularized operator recovers the ordinary Hodge Laplacian on the active subcomplex and hence the corresponding Betti number. Second, using low-pass spectral filters such as heat filters, resolvent filters, and polynomial moment filters, we defined spectral-filter matching losses and trace-type spectral-mass losses. Third, we applied these objectives to Vietoris–Rips complexes of point clouds and compared their optimization signals with persistence-diagram-based losses. Fourth, we used polynomial Laplacian moments to control normalized first-Betti-type quantities of graph clique complexes and showed that this topological objective can be combined with ordinary graph-feature objectives. It is important to distinguish this contribution from the use of persistent homology as a descriptor. Persistent homology remains the appropriate object when the goal is to compute stable barcode-level summaries of multiscale topology. The proposed Hodge- spectral objectives are complementary: they are designed for optimization settings in which topology must provide a differentiable signal. In such settings, exact barcode information is not always the most convenient optimization object, and low-frequency spectral quantities can provide more distributed and geometry-aware gradients. In the experiments on Vietoris–Rips filtrations, we observed that Hodge spectral- filter losses have properties different from persistent-homology-based losses. Hodge spectral-filter losses do not act only on birth–death pairs, but instead provide gradients through low-energy subspaces at each scale. As a result, compared with PH losses, the gradients were less localized around a small number of critical simplices and were more broadly distributed over the point cloud in the gradient-localization experiments. In the pairing-instability stress test, PH losses showed sharp changes when the maximal persistence bar switched, whereas the Hodge interval loss exhibited relatively smoother behavior after normalization by the loss range. In the shape synthesis experiment, Hodge spectral-filter gradients provided update directions more aligned with the target geometry and achieved lower reconstruction error than PH gradients in the controlled radial-shape setting. In the graph clique-complex experiments, we used the Laplacian moment d Tr (I − αL1 )

to control a normalized first-Betti-type spectral quantity. When the ordinary Hodge Laplacian is used on a hard clique complex, the chain space consists only of active

42

simplices. Therefore, unlike the ambient formulation, no inactive-direction penalty is required. In the soft numerical implementation, the moment is computed using a weighted-current-complex operator, and the normalized soft spectral moment is evaluated against a fixed soft target. The resulting sampled hard graphs are then evaluated using the ordinary normalized Betti number

β1 . |K1 |

The numerical experiments showed that, for both a single target and multiple targets, optimizing edge logits with the soft spectral-moment Betti loss moves the sampled hard normalized Betti number toward the prescribed hard target value. We also confirmed that the soft spectral-moment Betti loss can be combined with ordinary graph-feature losses such as degree variance, enabling simultaneous control of graph statistics and topological quantities. These results suggest that the low-frequency spectrum of Hodge-Laplacian-type operators provides an effective continuous representation for topology-constrained optimization. In particular, unlike barcode representations, the proposed Hodge-based losses are sensitive not only to the existence of homology classes but also to the surrounding spectral and geometric structure. Therefore, they can induce more geo- metrically natural deformations and updates, rather than merely matching topological summary statistics in the settings studied here. This should not be interpreted as a gen- eral dominance statement over barcode-based objectives; rather, the two approaches emphasize different information and are useful for different purposes. At the same time, the proposed method has clear computational limitations. Hodge spectral-filter losses use richer spectral information than PH losses, but this also increases the computational cost. As the size of a point cloud or graph grows, the number of simplices can increase rapidly, and constructing the Hodge-Laplacian- type operator and evaluating spectral filters become expensive. In our experiments, dense matrix computations were used, and the runtime per gradient step for Hodge losses was larger than that for PH losses. Applying the method to larger datasets will require scalable implementations based on sparse linear algebra, low-rank approxima- tion, Chebyshev approximation, stochastic trace estimation, and related techniques. Thus, the present experiments should be viewed as proof-of-concept demonstrations of the optimization behavior rather than as optimized large-scale implementations. Another important point is that trace-type losses should be interpreted as low- frequency spectral masses rather than exact Betti numbers in the soft regime. This is both a limitation and an advantage. By including near-zero modes, the loss can respond not only to exact homology classes but also to weakly closed cycles, unsta- ble holes, and approximate topological structures. This yields smoother and more geometry-aware update directions. On the other hand, hyperparameters such as filter temperature, moment degree, scale set, spectral scaling, and regularization strength affect the resulting optimization behavior. For polynomial moment filters, in particu- lar, the choice of α and d must be coordinated with the spectrum of the Laplacian so that positive eigenvalues are actually suppressed. A more systematic theoretical and

43

empirical understanding of these parameters remains an important topic for future work. The polynomial trace form of the moment loss also suggests possible connec- tions with scalable trace-estimation methods. Classical stochastic trace estimation and polynomial filtering can reduce the need for full eigendecomposition, and they are nat- ural candidates for scaling Hodge-spectral objectives to larger complexes. Quantum trace-estimation methods for normalized Betti numbers have a related mathematical structure, because they also represent Betti information through traces of polynomial functions of Laplacian-related operators. However, this work does not implement a quantum algorithm and does not claim quantum advantage. A careful study of block encodings, state preparation costs, sampling error, and gradient estimation would be required before making algorithmic claims in that direction. On the application side, the proposed framework can be extended to many prob- lems where topological constraints are important. Hodge spectral-filter losses for point clouds and images may be useful for medical image segmentation, shape interpola- tion, and geometric generative modeling. Normalized spectral-moment Betti losses for graphs may be useful for communication networks, molecular graphs, material structures, and social networks, where higher-order loops and redundancy affect func- tionality. In particular, Betti numbers of clique complexes describe higher-order graph structures that cannot be fully captured by degree distributions or clustering coeffi- cients, and therefore may serve as useful objectives for controlling network robustness and higher-order connectivity. Developing such applications will require task-specific choices of filtrations, spectral filters, target quantities, and geometric or structural regularization terms. In summary, this work presented a framework for treating topology not merely as an external descriptor computed after the fact, but as an object that can be directly optimized as a loss function. By using the low-frequency spectrum of Hodge-Laplacian- type spectral relaxations, discrete homological information can be embedded into smooth optimization problems, yielding a common mathematical structure across Vietoris–Rips complexes of point clouds and clique complexes of graphs. Further devel- opment of scalable spectral approximations and trace-estimation methods may enable the control of larger and more complex topological structures.

Statements and Declarations Funding The authors declare that no funds, grants, or other support were received during the preparation of this manuscript.

Competing interests The authors have no relevant financial or non-financial interests to disclose.

44

Author contributions S.K. conceived the study, developed the theoretical framework, and carried out the numerical computations. Y.S. made significant contributions through extensive dis- cussions with S.K. and provided important guidance for refining the direction of the study. All authors reviewed and approved the final manuscript.

Data availability The datasets generated and analyzed during the current study are available from the corresponding author upon reasonable request.

Code availability The code used for the numerical experiments is available from the corresponding author upon reasonable request.

Ethics approval Not applicable.

Consent to participate Not applicable.

Consent for publication Not applicable.

Appendix A             Details of Backward Computation In this appendix, we derive the backward computation for the low-pass spectral losses defined in the main text. The basic flow is as follows. First, from a loss function

J = J (L b q ),

we compute the gradient with respect to the Hodge-Laplacian-type spectral relaxation:

∂J GL =       . ∂L bq

Then, using the structure of Lb q , we propagate the gradient to the weighted boundary operators, simplex weights, edge probabilities, and edge logits. In the Vietoris–Rips setting, since the edge logits are defined as functions of point-cloud coordinates, the gradients are further propagated to the point coordinates. Throughout this appendix, for a variable z , we denote the gradient of J with respect to z by ∂J gz =     . ∂z

45

For example,

∂J                  ∂J                     ∂J              ∂J gρσ =       ,      g wσ =       ,         g pe =       ,   gae =       . ∂ρσ                 ∂wσ                    ∂pe             ∂ae

Here, ρσ denotes the square root of the simplex weight wσ : √ ρσ =        wσ .

A.1     Notation and Overall Computational Path For a fixed degree q , we write the Hodge-Laplacian-type spectral relaxation as

L=L bq .

Let the loss function be J = J (L). The matrix gradient obtained from the spectral loss is denoted by

∂J GL =       . ∂L Since L is symmetric, in numerical implementations one may symmetrize this gradient as 1 GL + G⊤  GL ←            L . 2 The Hodge-Laplacian-type spectral relaxation is defined by

eq⊤ B L=B   eq + B eq+1 B ⊤ eq+1 + µ(I − Wq ).

For simplicity, we write A=B eq ,              C=B eq+1 . Then L = A⊤ A + CC ⊤ + µ(I − Wq ). Each weighted boundary operator is defined by

B ep = Rp−1 Bp Rp ,

where √ Rp = diag(ρσ )σ∈K (p) ,    ρσ = wσ . max In the soft clique complex, the simplex weights are given by Y wσ =          pe , e⊂σ

46

and each edge probability is defined by

1 pe = σ (ae ) =                  . 1 + exp(−ae )

Therefore, the backward computational path is

J −→ L −→ B    eq+1 , Wq −→ ρσ −→ wσ −→ pe −→ ae . eq , B

In the Vietoris–Rips setting, we further have

r − dij (X ) q (r) aij (X ) =                ,      dij (X ) =    ∥xi − xj ∥2 + δ. ε Thus, gradients are further propagated through

(r) aij −→ dij −→ xi .

A.2      From Spectral Losses to GL We first compute ∂J GL = ∂L for representative low-pass spectral losses used in the main text.

A.2.1     Heat Projector Matching Loss Let the heat projector be                          L F (L) = exp −     . τ Let the target projector be                         Ltar Ftar = exp −        . τ The loss function is 1                2 Jheat =       ∥F (L) − Ftar ∥F . 2 Define D = F (L) − Ftar . Then dJheat = ⟨D, dF ⟩F . Let the eigendecomposition of L be

L = U ΛU ⊤ ,          Λ = diag(λ1 , . . . , λN ).

Define                                              λ f (λ) = exp −     . τ

47

Then F (L) = U f (Λ)U ⊤ . By the Fréchet derivative of a matrix function,

U ⊤ (dF )U = K ⊙ U ⊤ (dL)U , 

where ⊙ denotes the Hadamard product, and the Loewner matrix K is given by   f (λi ) − f (λj ) , i ̸= j,  Kij =       λi − λ j f ′ (λ ),  i = j. i

For the heat filter,                                 ′         1      λi f (λi ) = − exp −      . τ      τ Therefore, dJheat = U ⊤ DU, K ⊙ U ⊤ (dL)U F . 

Using the inner-product property of the Hadamard product,

dJheat = K ⊙ U ⊤ DU , U ⊤ (dL)U F . 

Furthermore, using M, U ⊤ (dL)U F = U M U ⊤ , dL F , we obtain GL = U K ⊙ U ⊤ DU U ⊤ .         

Thus, for the heat projector matching loss,

∂Jheat = U K ⊙ U ⊤ (F (L) − Ftar ) U U ⊤ .                           GL = ∂L

A.2.2     Resolvent Projector Matching Loss Let the resolvent projector be

F (L) = α(L + αI )−1 .

Let the target projector be

Ftar = α(Ltar + αI )−1 .

The loss function is 1                2 Jres =      ∥F (L) − Ftar ∥F . 2 Define D = F (L) − Ftar .

48

Also define M = L + αI. Then F (L) = αM −1 . Using the differential formula for the inverse matrix,

dM −1 = −M −1 (dM )M −1 .

Since dM = dL, we have dF = −αM −1 (dL)M −1 . The differential of the loss is dJres = ⟨D, dF ⟩F . Therefore, dJres = −α Tr D⊤ M −1 (dL)M −1 .                 

By cyclicity of the trace,

dJres = −α Tr M −1 D⊤ M −1 dL .                

When L, M , and D are symmetric,

D⊤ = D.

Thus, GL = −αM −1 DM −1 . Equivalently,

∂Jres GL =         = −α(L + αI )−1 (F (L) − Ftar ) (L + αI )−1 . ∂L

A.2.3     Moment Trace Loss Let the moment surrogate be d Sq,d (L) = Tr (I − αL) .

Define M = I − αL. Then Sq,d (L) = Tr(M d ). We first compute dSq,d = d Tr(M d ).

49

By the product rule, d−1 X d(M d ) =            M ℓ (dM )M d−1−ℓ . ℓ=0 Therefore, d−1 X Tr M ℓ (dM )M d−1−ℓ .                  dSq,d = ℓ=0 By cyclicity of the trace,

Tr M ℓ (dM )M d−1−ℓ = Tr M d−1 dM .                             

Hence, dSq,d = d Tr M d−1 dM .         

Since M = I − αL, we have dM = −αdL. Therefore, dSq,d = −αd Tr M d−1 dL .         

Thus, ∂Sq,d               ⊤ = −αd M d−1 . ∂L If L is symmetric, then M is also symmetric, and hence

∂Sq,d = −αdM d−1 . ∂L For the loss function 1                 2 Jmom =        (Sq,d (L) − τq ) , 2 the chain rule gives

∂Jmom                    ∂Sq,d GL =           = (Sq,d (L) − τq )       . ∂L                       ∂L Therefore, GL = (Sq,d (L) − τq ) −αdM d−1 . 

When using the normalized moment surrogate

1 S q,d (L) =         Sq,d (L), Nq

the loss function is 1                2 Jnorm =       S q,d (L) − τ̄q . 2 In this case,  1 −αdM d−1 .  GL = S q,d (L) − τ̄q Nq

50

A.3      From the Hodge-Laplacian-type spectral relaxation to Weighted Boundaries We now assume that ∂J GL = ∂L has already been computed, and propagate it to the weighted boundary operators. Recall that L = A⊤ A + CC ⊤ + µ(I − Wq ), where A=B  eq ,   C=B  eq+1 . Taking the differential, we obtain

dL = d(A⊤ A) + d(CC ⊤ ) − µdWq .

The first two terms are

d(A⊤ A) = (dA)⊤ A + A⊤ (dA)

and d(CC ⊤ ) = (dC )C ⊤ + C (dC )⊤ . Thus, dL = (dA)⊤ A + A⊤ (dA) + (dC )C ⊤ + C (dC )⊤ − µdWq . The differential of the loss is

dJ = ⟨GL , dL⟩F .

First, consider the terms involving A:

dJA = GL , (dA)⊤ A + A⊤ (dA) F .

Using properties of the Frobenius inner product,

GL , (dA)⊤ A F = AG⊤ L , dA F

and GL , A⊤ (dA) F = ⟨AGL , dA⟩F . Since GL is symmetrized, G⊤ L = GL . Therefore, dJA = ⟨2AGL , dA⟩F . Hence, ∂J GA =      = 2AGL . ∂A

51

Next, consider the terms involving C :

dJC = GL , (dC )C ⊤ + C (dC )⊤ F .

Similarly, GL , (dC )C ⊤ F = ⟨GL C, dC⟩F and GL , C (dC )⊤ F = G⊤ L C, dC F . Since G⊤ L = GL , dJC = ⟨2GL C, dC⟩F . Thus, ∂J GC == 2GL C. ∂C We also compute the contribution from the penalty term

µ(I − Wq ).

The differential of this term is −µdWq . Therefore, dJpen = −µ⟨GL , dWq ⟩F . Since Wq is diagonal, Wq = diag(wσ )σ∈K (q) , max we have dWq = diag(dwσ )σ∈K (q) . max Thus,                                          X ⟨GL , dWq ⟩F =             (GL )σσ dwσ . (q) σ∈Kmax Hence, the direct gradient contribution from the penalty term to a q -simplex weight is pen                             (q) gw σ = −µ(GL )σσ ,          σ ∈ Kmax .

A.4     From Weighted Boundaries to Square-Root Weights We next propagate the gradient through the weighted boundary

B ep = Rp−1 Bp Rp

to the square-root weights ρσ . Recall that √ Rp = diag(ρσ )σ∈K (p) ,      ρσ = wσ . max Let ∂J GBep =          . ∂B ep

52

In components, (B ep )τ σ = ρτ (Bp )τ σ ρσ , where (p−1)            (p) τ ∈ Kmax    ,    σ ∈ Kmax  . First, consider the contribution to ρτ for a (p − 1)-simplex τ . We have

∂ (B ep )τ σ = (Bp )τ σ ρσ . ∂ρτ

Therefore, ∂J        X =              (GBep )τ σ (Bp )τ σ ρσ . ∂ρτ          (p) σ∈Kmax

In vector form, the contribution from B ep to ρp−1 is           gρ(p,lower) p−1 = GBep ⊙ Bp ρp .

Next, consider the contribution to ρσ for a p-simplex σ . We have

∂ (B ep )τ σ = ρτ (Bp )τ σ . ∂ρσ

Therefore, ∂J        X =               (GBep )τ σ (Bp )τ σ ρτ . ∂ρσ         (p−1) τ ∈Kmax

In vector form, the contribution from B ep to ρp is

          ⊤ gρ(p,upper) p =  GBp e ⊙ B p    ρp−1 .

A key point is that the same ρp appears in two weighted boundaries. It appears on the right side of Bep = Rp−1 Bp Rp and on the left side of B ep+1 = Rp Bp+1 Rp+1 . Therefore, the total gradient with respect to ρp is the sum of the two contributions. Thus, for a general degree p, the full gradient with respect to ρp is          ⊤                   gρp = GBep ⊙ Bp ρp−1 + GBep+1 ⊙ Bp+1 ρp+1 ,

where terms corresponding to non-existent boundary operators at the ends of the complex are omitted.

53

For the most important case q = 1, we have

L=L    e1⊤ B b1 = B   e1 + B  e2⊤ + µ(I − W1 ). e2 B

Then GBe1 = 2Be1 GL ,    GBe2 = 2GL Be2 . The gradient with respect to the square-root weights of edges, ρ1 , is          ⊤             gρ1 = GBe1 ⊙ B1 ρ0 + GBe2 ⊙ B2 ρ2 .

The gradient with respect to the square-root weights of triangles, ρ2 , is          ⊤ gρ2 = GBe2 ⊙ B2 ρ1 .

The vertex weights are usually fixed, and hence gradients with respect to ρ0 are not used for optimization.

A.5      From Square-Root Weights to Simplex Weights We now compute the derivative from √ ρσ =       wσ

to wσ . Since ρσ = wσ1/2 , we have ∂ρσ     1          1 = wσ−1/2 =       . ∂wσ     2         2ρσ Therefore, the gradient contribution from the weighted boundaries to the simplex weight is bdry       ∂ρσ    gρ gw    = gρσ      = σ. σ ∂wσ    2ρσ (q) If σ ∈ Kmax , then the penalty contribution pen gw σ = −µ(GL )σσ

must be added. Therefore, gρσ                         (q) gwσ =       − µ(GL )σσ ,       σ ∈ Kmax . 2ρσ

54

(p) For a p-simplex σ ∈ Kmax with p ̸= q , there is no direct penalty contribution, and hence gρ gwσ = σ . 2ρσ Numerically, when wσ is very small, ρσ also becomes very small and instability may occur. In such cases, one may use √ ρσ =        wσ + ϵnum .

Then bdry     gρσ gw    = √          . σ 2 wσ + ϵnum

A.6     From Simplex Weights to Edge Probabilities In the soft clique complex, simplex weights are defined by Y wσ =         pe . e⊂σ

If an edge e is contained in σ , then

∂wσ   Y =   p e′ . ∂pe   ′ e ⊂σ e′ ̸=e

Equivalently, ∂wσ   wσ =    . ∂pe   pe If e ̸⊂ σ, then ∂wσ = 0. ∂pe Therefore, the gradient with respect to the edge probability pe is the sum of the contributions from all simplices containing e:

∂J   X    ∂wσ gpe =      =   gw     . ∂pe σ⊃e σ ∂pe

Thus,                                       X            wσ gpe =          gwσ       . σ⊃e pe For numerical stability when pe is very small, one may use X              wσ gpe =          gwσ             . σ⊃e pe + ϵnum

55

A.7     From Edge Probabilities to Edge Logits The edge probability is defined from the edge logit ae by

1 pe = σ (ae ) =                 . 1 + exp(−ae )

The derivative of the logistic function is

∂pe = pe (1 − pe ). ∂ae

Therefore, ∂J gae =    = gpe pe (1 − pe ). ∂ae Substituting the result from the previous subsection gives X           wσ gae = pe (1 − pe )          gwσ      . σ⊃e pe

When pe > 0, this can be simplified as X gae = (1 − pe )            gwσ wσ . σ⊃e

However, for numerical stability, it is safer to use X              wσ gae = pe (1 − pe )         gwσ             . σ⊃e pe + ϵnum

Thus, gradients of arbitrary low-pass spectral losses can be propagated analytically to the edge logits ae .

A.8     Backward Computation for Graph Generation In graph generation, the optimization variables are the edge logits

a = {ae }e∈Emax .

Thus, the final output of the backward computation is

∇a J = (gae )e∈Emax .

The computation proceeds as follows. First, compute edge probabilities from edge logits:

pe = σ (ae ).

56

Next, compute simplex weights: Y wσ =            pe . e⊂σ

Then construct Wq ,        Rq ,           B eq ,       L bq . Next, compute ∂J GL = ∂L bq from the loss function. For example, for the normalized Laplacian moment loss

1            2 Jnorm =         S q,d − τ̄q , 2 where                                                d 1     S q,d =      Tr I − αL bq , Nq define M = I − αL bq . Then  1 −αdM d−1 .  GL = S q,d − τ̄q Nq Using this GL , compute GBeq = 2B eq GL and GBeq+1 = 2GL B eq+1 . Then compute gρp using the formula in the previous subsection. In particular, for q = 1,          ⊤             gρ1 = GBe1 ⊙ B1 ρ0 + GBe2 ⊙ B2 ρ2 .

Then compute gwσ . Next compute                                 X              wσ gpe =         gwσ         . σ⊃e pe Finally compute gae = gpe pe (1 − pe ). This gives ∂J = gae . ∂ae Therefore, the edge logits can be updated by gradient-based optimization.

57

A.9     From Vietoris–Rips Edge Logits to Distances In the Vietoris–Rips setting, edge logits are defined from point-cloud coordinates. At scale r, (r)      r − dij (X ) aij (X ) =              , ε where                                    q dij (X ) = ∥xi − xj ∥2 + δ. Assume that the gradient with respect to each edge logit has already been computed: ∂J ga(r) =   (r) . ij ∂aij We now propagate this gradient to the distance dij . Since (r)      r − dij aij =              , ε we have (r) ∂aij           1 =− . ∂dij          ε Therefore, (r) (r)   ∂J              ∂aij       1 gdij =      = ga(r)            = − ga(r) . ∂dij        ij ∂dij        ε ij

A.10      From Distances to Point-Cloud Coordinates We next differentiate the stabilized distance q dij (X ) = ∥xi − xj ∥2 + δ

with respect to the point-cloud coordinates. Since dij (X )2 = ∥xi − xj ∥2 + δ, we have xi − xj ∇xi dij = dij and xj − xi ∇xj dij =        . dij At a single scale r, the gradient with respect to a point xi is the sum of the contributions from all candidate edges incident to xi :

(r) xi − xj X ∇xi J (r) =                  gdij           . dij j:(i,j)∈Emax

58

Substituting (r)    1 gdij = − ga(r) , ε ij we obtain 1          X                  xi − xj ∇xi J (r) = −                              ga(r)           . ε                        ij     dij j:(i,j)∈Emax Furthermore, using

(r) (r) wσ           X (r)         (r) ga(r) = pij       1 − pij           gw σ  (r) , ij σ⊃(i,j)      pij

we obtain                                 (r) 1                                         (r) wσ  xi − xj           p(r)       (r) X                        X ∇xi J (r) = −                  ij   1 − pij            gw    (r) . ε                                           σ pij    dij j:(i,j)∈Emax                   σ⊃(i,j)

For numerical stability, one may replace

(r) wσ (r) pij

by (r) wσ (r) . pij + ϵnum

A.11       Multi-Scale Vietoris–Rips Backward Computation In a Vietoris–Rips filtration, we use multiple scales

r1 < r2 < · · · < rM .

Suppose that the loss function is

M X                           J (X ) =                ωm Jm Lb (r q m) (X ) . m=1

For each scale rm , first compute

(m)             ∂Jm GL           =              . b (r ∂L q m)

59

Then, following the procedure above, compute

∂Jm ga(rm ) =          (r ) . ij ∂aij m

The edge logit at scale rm is

(r )           rm − dij (X ) aij m (X ) =                    . ε

The distance dij (X ) does not depend on the scale, whereas the edge-logit gradient

ga(rm ) ij

does depend on the scale. The gradient of the total loss with respect to xi is the weighted sum of the contributions from all scales: M X ∇x i J =           ωm ∇xi Jm . m=1

Therefore, M 1 X                X                       xi − xj ∇x i J = −         ωm                         ga(rm )           . ε m=1                              ij        dij j:(i,j)∈Emax Writing ga(rm ) explicitly, we have ij

                                      M                                                       (rm ) 1 X                                                        w        xi − x j .            X p(r m)       (r )           (m) σ X ∇x i J = −       ωm                    ij     1 − pij m          gw    (rm ) ε m=1                                                    σ pij         dij j:(i,j)∈Emax                     σ⊃(i,j)

This shows that the multi-scale Vietoris–Rips loss is analytically differentiable with respect to the point-cloud coordinates X .

A.12      Summary of Backward Computation The backward computation derived in this appendix can be summarized as follows. First, compute ∂J GL = ∂Lbq from the spectral loss. Next, using L    eq⊤ B bq = B   eq + B eq+1 B ⊤ eq+1 + µ(I − Wq ), compute GBeq = 2B eq GL

60

and GBeq+1 = 2GL B eq+1 . For a general degree p, the gradient with respect to ρp is          ⊤                   gρp = GBep ⊙ Bp ρp−1 + GBep+1 ⊙ Bp+1 ρp+1 ,

where non-existent boundary terms are omitted. Then, since √ ρσ = wσ , compute bdry      gρσ gw    =        . σ 2ρσ (q) For σ ∈ Kmax , add the penalty contribution: gρσ gwσ =       − µ(GL )σσ . 2ρσ

Next, using the soft clique relation Y wσ =         pe , e⊂σ

compute                                       X           wσ gpe =          gwσ      . σ⊃e pe Finally, since pe = σ (ae ), compute gae = gpe pe (1 − pe ). In graph generation, this gae is the gradient with respect to the optimization variable. In the Vietoris–Rips setting, using

(r)          r − dij (X ) aij (X ) = ε and                                         q dij (X ) =      ∥xi − xj ∥2 + δ, we obtain the point-coordinate gradient

M 1 X               X                  xi − xj ∇x i J = −         ωm                   ga(rm )           . ε m=1                         ij       dij j:(i,j)∈Emax

61

Thus, all low-pass spectral losses introduced in the main text are analytically differentiable through the Hodge-Laplacian-type spectral relaxation, soft simplex weights, edge probabilities, edge logits, and, in the Vietoris–Rips setting, point-cloud coordinates.

References Adams, H., T. Emerson, M. Kirby, R. Neville, C. Peterson, P. Shipman, S. Chep- ushtanova, E. Hanson, F. Motta, and L. Ziegelmeier. 2017. Persistence images: A stable vector representation of persistent homology. Journal of Machine Learning Research 18 (8): 1–35 .

Akhalwaya, I.Y., A. Bhayat, A. Connolly, S. Herbert, L. Horesh, J. Sorci, and S. Ubaru. 2024. Comparing quantum and classical monte carlo algorithms for estimating betti numbers of clique complexes. arXiv preprint arXiv:2408.16934 .

Bubenik, P. 2020. The persistence landscape and some of its properties. In Topological Data Analysis: The Abel Symposium 2018, pp. 97–117. Springer.

Chazal, F., B.T. Fasy, F. Lecci, A. Rinaldo, and L. Wasserman 2014. Stochastic convergence of persistence landscapes and silhouettes. In Proceedings of the thirtieth annual symposium on Computational geometry, pp. 474–483.

Clough, J.R., N. Byrne, I. Oksuz, V.A. Zimmer, J.A. Schnabel, and A.P. King. 2020. A topological loss function for deep-learning based image segmentation using persistent homology. IEEE transactions on pattern analysis and machine intelligence 44 (12): 8766–8778 .

Cohen-Steiner, D., H. Edelsbrunner, and J. Harer 2005. Stability of persistence dia- grams. In Proceedings of the twenty-first annual symposium on Computational geometry, pp. 263–271.

Edelsbrunner, Letscher, and Zomorodian. 2002. Topological persistence and simplifi- cation. Discrete & computational geometry 28 (4): 511–533 .

Edelsbrunner, H., J. Harer, et al. 2008. Persistent homology-a survey. Contemporary mathematics 453 (26): 257–282 .

Gabrielsson, R.B., B.J. Nelson, A. Dwaraknath, and P. Skraba 2020. A topology layer for machine learning. In International Conference on Artificial Intelligence and Statistics, pp. 1553–1563. PMLR.

Gyurik, C., C. Cade, and V. Dunjko. 2022. Towards quantum advantage via topological data analysis. Quantum 6: 855 .

Hofer, C., R. Kwitt, M. Niethammer, and A. Uhl. 2017. Deep learning with topological signatures. Advances in neural information processing systems 30 .

62

Hu, X., F. Li, D. Samaras, and C. Chen. 2019. Topology-preserving deep image segmentation. Advances in neural information processing systems 32 .

Kališnik, S. 2019. Tropical coordinates on the space of persistence barcodes. Foundations of Computational Mathematics 19 (1): 101–129 .

Lloyd, S., S. Garnerone, and P. Zanardi. 2016. Quantum algorithms for topological and geometric analysis of data. Nature communications 7 (1): 10138 .

Moor, M., M. Horn, B. Rieck, and K. Borgwardt 2020. Topological autoencoders. In International conference on machine learning, pp. 7045–7054. PMLR.

Nigmetov, A., A. Krishnapriyan, N. Sanderson, and D. Morozov. 2024. Topological regularization via persistence-sensitive optimization. Computational Geometry 120: 102086 .

Nigmetov, A. and D. Morozov. 2024. Topological optimization with big steps. Discrete & computational geometry 72 (1): 310–344 .

Otter, N., M.A. Porter, U. Tillmann, P. Grindrod, and H.A. Harrington. 2017. A roadmap for the computation of persistent homology. EPJ data science 6 (1): 17 .

Vandaele, R., B. Kang, J. Lijffijt, T. De Bie, and Y. Saeys. 2021. Topologically regularized data embeddings. arXiv preprint arXiv:2110.09193 .

Yamauchi, H., S. Kanno, Y. Sato, H. Tezuka, Y.a. Shimada, E. Kaminishi, and N. Yamamoto. 2025. Quantum spectroscopy of topological dynamics via a supersymmetric hamiltonian. arXiv preprint arXiv:2511.23169 .

Zomorodian, A. and G. Carlsson 2004. Computing persistent homology. In Proceedings of the twentieth annual symposium on Computational geometry, pp. 347–356.

63

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
