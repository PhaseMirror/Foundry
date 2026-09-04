---
id: ADR-0033
title: "ADR-0033: Fisher-Geometric Sharpness and the Implicit Bias of SGD Toward Flat Minima"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.FisherSharpness
rust_module: echonomics_engine::fisher_sharpness
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0033: Fisher-Geometric Sharpness and the Implicit Bias of SGD Toward Flat Minima

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for Fisher-Geometric Sharpness and the Implicit Bias of SGD Toward Flat Minima.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0033
Title: Fisher-Geometric Sharpness and the Implicit Bias of SGD Toward Flat Minima
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

F ISHER -G EOMETRIC S HARPNESS AND THE I MPLICIT B IAS OF SGD TOWARD F LAT M INIMA

Md Sakir Ahmed Department of Electronics and Communication Technology Gauhati University Guwahati, Assam, India arXiv:2606.20469v1 [cs.LG] 18 Jun 2026

ahmedsakir717@gmail.com

Kumaresh Sarmah                                              Hemen Dutta Department of Electronics and Communication Technology                   Department of Mathematics Gauhati University                                        Gauhati University Guwahati, Assam, India                                     Guwahati, Assam, India kumaresh@gauhati.ac.in                                      duttah@gauhati.ac.in

June 19, 2026

A BSTRACT A widely held intuition in deep learning is that stochastic gradient descent (SGD) implicitly favors flat minima and that flat minima generalize better, but the standard Euclidean measures of flatness like the trace or maximum eigenvalue of the loss Hessian are not invariant under reparametrizations that preserve the network function, which undermines the theoretical foundations of this narrative. In this study we resolve this issue by grounding flatness in the Riemannian geometry of the statistical manifold induced by the Fisher Information Matrix (FIM). We define Riemannian sharpness mathe- matically and prove that it is invariant under smooth, function-preserving reparametrizations, which directly addresses the critique of Dinh et al. in the paper “Sharp minima can generalize for deep nets”. We note that this invariance is a property of the true FIM; the diagonal empirical estimator used in practice (and in all experiments below) inherits invariance only approximately, and exact invariance under arbitrary reparametrizations would require structured estimators such as K-FAC. We formalize the gradient noise of mini-batch SGD as having a covariance structure proportional to the FIM, derive the stationary distribution of the resulting stochastic differential equation and then show that the probability mass is exponentially concentrated at Riemannian-flat minima. A PAC-Bayes generalization bound controlled explicitly by SR formally links this geometric bias to test performance. Our experiments on MNIST and CIFAR-10 confirm that SR reliably tracks generalization in ways that Euclidean sharpness does not, and that its scaling with η/B matches the theoretical predictions. Together these results provide a rigorous, reparametrization-invariant account of why flat minima generalize.

Keywords Stochastic Gradient Descent, Fisher Information Matrix, Riemannian Geometry, Loss Landscape, Generalization Bounds, Implicit Bias, Flat Minima, Information Geometry, PAC-Bayes, Neural Networks, TinyCNN

1    Introduction A central question in deep learning theory is that why stochastic gradient descent (SGD) finds solutions that generalize well despite operating in heavily over-parameterized regimes where infinitely many zero-loss solutions exist. A widely held intuition is that SGD implicitly prefers flat minima in which the regions of the loss landscape at which the curvature is low along with flat minima that corresponds to models with better generalization. This flatness bias has been empirically documented Keskar et al. [2017] and partially formalized through continuous-time SDE analyses Li

A PREPRINT - J UNE 19, 2026

et al. [2017] but the theoretical foundation of this intuition remains fragile. The central difficulty was identified by Dinh et al. [2017] that any Euclidean-based flatness measure such as the trace or maximum eigenvalue of the loss Hessian is not invariant under reparametrization. For a two-layer network the rescaling weights by α and α−1 preserves the function exactly while making the Euclidean sharpness arbitrarily large or small. Since the Euclidean sharpness is not an intrinsic property of the model, therefore, it cannot be meaningfully linked to generalization. This creates a fundamental gap, i.e., if the flatness measure is ill-defined then the entire flatness-generalization narrative is called into question. Partial steps toward invariant measures have been taken Jang et al. [2022], Kristiadi et al. [2023], but a unified account connecting invariant sharpness along with the SGD’s implicit bias and generalization bounds has remained lacking. In this study, we have tried to resolve this gap by replacing the Euclidean metric on parameter space with the Fisher Information Matrix (FIM), which endows the parameter space with a Riemannian structure that is intrinsic to the model’s predictive distribution. We then proceed to define Riemannian sharpness as SR (θ∗ ) = tr(G(θ∗ )−1 ∇2 L(θ∗ )), where G(θ∗ ) is the FIM at the minimum. This quantity measures curvature relative to the natural geometry of the statistical manifold and is invariant under smooth reparametrizations that preserve the network function which directly addresses the critique of Dinh et al. [2017]. Our main contribution in this study is a rigorous theoretical framework showing that mini-batch SGD has an implicit geometric bias toward minima with small Riemannian sharpness. We have formalized the gradient noise of mini-batch SGD as having a covariance structure proportional to the FIM after which we have attempted to derive the stationary distribution of the resulting SDE and have shown that probability mass is exponentially concentrated at Riemannian-flat minima. We further connect the Riemannian flatness to generalization via a PAC-Bayes bound which provides a formally grounded and reparametrization-invariant account of why flat minima generalize so well.

Contributions • We have defined Riemannian sharpness on the statistical manifold and showed its invariance under reparametrization (Lemma 1), attempting to resolve the fundamental critique of Dinh et al. [2017]. • We are explicit about the gap between the theoretical invariance of SR (which holds for the true FIM) and its empirical estimator (which is not exactly invariant; see Section 6.5). • We have derived the local stationary distribution of the mini-batch SGD SDE and then proved that it assigns exponentially greater mass to Riemannian-flat minima (Theorem 1, Corollary 1). • We have established a PAC-Bayes generalization bound that is explicitly controlled by Riemannian sharpness (Corollary 2) which formally links flatness to test performance. • We have provided empirical validation on MNIST and CIFAR-10, confirming that Riemannian sharpness tracks generalization across optimizers, batch sizes, and learning rates in ways that Euclidean sharpness does not.

Unlike prior work Jang et al. [2022], Kristiadi et al. [2023] which establishes reparametrization invariance in isolation, this work is the first to unify invariant sharpness with the SGD stationary distribution and a PAC-Bayes generalization bound in a single framework.

2     Related Work 2.1   Flat Minima and Generalization

The conjecture that the flat minima generalize better than sharp ones was first formalized by Hochreiter and Schmidhuber [1997] who used a minimum description length (MDL) argument to show that low-curvature regions of the loss surface correspond to simpler models with lower expected overfitting. This insight motivated algorithms to be explicitly designed to seek flat minima. More recently Keskar et al. [2017] provided influential empirical evidence that large-batch SGD tends to converge to sharp minima, while small-batch SGD consistently finds flatter ones which establishes a direct link between batch size, loss landscape geometry and generalization. Chaudhari et al. [2017] had built on this observation with Entropy-SGD which is an algorithm that constructs a local-entropy-based objective to bias gradient descent toward wide and flat valleys of the energy landscape with improved generalization bounds via uniform stability analysis. A key challenge to this narrative was raised by Dinh et al. [2017] who has demonstrated that Euclidean-based flatness measures like the Hessian trace or spectral norm are not invariant under reparametrization. In a two-layer network the rescaling weights by α and α−1 changes Euclidean sharpness arbitrarily while leaving predictions unchanged. Our

2

A PREPRINT - J UNE 19, 2026

work tries to address this critique by replacing the Euclidean metric with the Fisher Information Matrix which yields a reparametrization-invariant sharpness measure.

2.2   Reparametrization-Invariant Sharpness Measures

Jang et al. Jang et al. [2022] proposed an information-geometric sharpness measure based on the FIM that is invariant under reparametrizations and scale transformations for ReLU networks, and demonstrated its use as a training regularizer. Kristiadi et al. Kristiadi et al. [2023] provided a comprehensive Riemannian-geometric analysis of neural network parameter spaces under reparametrization, showing that invariance is an inherent property of any neural network provided the metric is made explicit and transformation rules are correctly applied. Both works establish the geometric foundations that motivate our framework. However neither derives the stationary distribution of mini-batch SGD under Fisher-structured noise nor connects Riemannian flatness to generalization via a PAC-Bayes bound.

2.3   Sharpness-Aware Minimization

Being motivated by the flatness-generalization connection, Foret et al. [2021] proposed Sharpness-Aware Minimization (SAM) which modifies the training objective to explicitly minimize the worst-case loss within an ϵ-ball around the current parameters while steering optimization toward flatter regions. SAM and its variants have demonstrated consistent empirical gains in generalization across diverse architectures and datasets. Our work provides a theoretical basis that complements SAM. Although SAM operates in Euclidean parameter space, our framework suggests that flatness-aware methods may be most naturally and robustly formulated with respect to the Riemannian geometry induced by the Fisher Information Matrix.

2.4   Information Geometry and the Fisher Information Matrix

The use of the Fisher Information Matrix as a Riemannian metric on the statistical manifold of a model’s predictive distribution originates from Amari [1998] who introduced the natural gradient as the steepest descent direction under this geometry. Amari showed that the natural gradient is Fisher efficient and can avoid the plateau phenomenon of standard backpropagation. Čencov’s theorem Čencov [1982] establishes that the FIM is the unique Riemannian metric on the statistical manifold that is invariant under sufficient statistics which provides a canonical justification for our choice of geometry. Martens and Grosse [2015] subsequently developed K-FAC which is a scalable Kronecker-factored approximation to the natural gradient that is closely related to the FIM structures we use in our empirical estimator.

2.5   SDE Analyses of SGD

A complementary line of work studies mini-batch SGD through the lens of stochastic differential equations (SDEs). Li et al. [2017] derived a continuous-time SDE approximation of SGD and analyzed its stationary distribution which provides one of the first rigorous accounts of how noise structure shapes the implicit bias of gradient-based optimization. Our analysis builds directly on this framework where we leverage the FIM as the covariance structure of the gradient noise (Assumption 3) to derive a stationary distribution that assigns exponentially greater mass to Riemannian-flat minima that in turn provides a geometry-aware refinement of the Euclidean SDE analyses that cannot distinguish between flat minima that are reparametrization-related.

2.6   PAC-Bayes Generalization Bounds

The PAC-Bayes framework McAllester [1999] which provides data-dependent generalization guarantees for randomized predictors has become a natural tool for connecting flatness to generalization. Dziugaite and Roy [2017] demonstrated that PAC-Bayes bounds remain non-vacuous for large deep networks on MNIST by directly optimizing the bound and established a formal connection between flat minima and compressibility of the network’s weights. Our Corollary 2 contributes to this line of work by establishing a PAC-Bayes bound that is explicitly controlled by Riemannian sharpness SR , rather than Euclidean flatness thereby making the bound reparametrization-invariant and links it more tightly to the intrinsic geometry of the model.

2.7   Implicit Bias of SGD

Beyond flatness, a broader literature studies the implicit bias of gradient-based optimizers. Wilson and Izmailov [2020] examined the relationship between Bayesian deep learning, flat minima and generalization, from a probabilistic perspective. Furthermore, more recent work has formalized implicit bias in specific settings, like, studies on linear networks Mulayoff and Michaeli [2020] and ReLU networks have shown that SGD with large step size is biased toward

3

A PREPRINT - J UNE 19, 2026

functions with bounded input-output sensitivity which connects flatness to Sobolev-type regularization of the learned function Nacson et al. [2022]. Our work can be considered complementary to this, where rather than characterizing the implicit bias in terms of the learned function, we characterize it in terms of the geometry of the parameter manifold and we have done so in a reparametrization-invariant manner.

3     Methodology

3.1   Problem Setup

We have considered a supervised learning setting where a neural network f (· ; θ) : X → RK with parameters θ ∈ Rd defines a conditional Pn       distribution p(y | x; θ) over K classes. The training objective is the empirical cross-entropy loss L(θ) = − n1 i=1 log p(yi | xi ; θ), minimized via mini-batch SGD with learning rate η and batch size B.

3.2   Riemannian Sharpness

The standard sharpness measures evaluate the curvature of the loss landscape using the Euclidean metric on Rd . The most common such measure is the Euclidean sharpness:

SE (θ∗ ) = tr(∇2 L(θ∗ )),                                                (1)

which is the sum of the eigenvalues of the loss Hessian. As shown by Dinh et al. [2017], SE is not invariant under reparametrizations that preserve the network function, thereby making it an unreliable measure of intrinsic geometry. Prior work have proposed information-geometric alternatives Jang et al. [2022] and studied the general Riemannian structure of parameter spaces Kristiadi et al. [2023] and we have built on this foundation by grounding the sharpness measure within a unified SDE and PAC-Bayes framework. We have instead equipped the parameter space with the Riemannian metric given by the Fisher Information Matrix G(θ), defined in (5). This metric is intrinsic to the model’s predictive distribution and from the Čencov’s theorem Čencov [1982] we know it is the unique invariant metric on the statistical manifold. The Riemannian sharpness, as stated in (6) measures curvature in the coordinate system that is natural to the model rather than to an arbitrary Euclidean embedding.

3.3   Empirical Estimation

While computing G(θ) exactly requires an expectation over the full data distribution which makes it intractable so we have used the standard diagonal empirical FIM approximation: N b                              2 1 X          ∂ log p(ỹj | xj ; θ) Ĝ(θ)ii ≈                                             ,                           (2) Nb j=1              ∂θi

where ỹj ∼ p(· | xj ; θ) is sampled from the model’s own predictive distribution (empirical Fisher) and Nb is the number of mini-batches used for estimation. We note that this diagonal approximation, while computationally necessary for networks of practical scale, does not inherit the full reparametrization invariance of the true G(θ); this gap is examined empirically in Section 6.5.The diagonal approximation is standard in natural gradient and K-FAC methods and is necessary for tractability at the scale of modern networks. The Hessian diagonal is estimated using Hutchinson’s stochastic trace estimator and for Rademacher random vectors v ∼ {±1}d , tr(H) = Ev [v ⊤ Hv],                                                  (3) approximated with np probe vectors per mini-batch, the Riemannian sharpness is then computed as: d X          Ĥii ŜR (θ∗ ) =                        ,                                       (4) ∗ i=1 Ĝ(θ )ii + λ

where λ > 0 is a Tikhonov damping constant that prevents numerical blow-up for near-zero FIM entries which follows standard practice in K-FAC.

4

A PREPRINT - J UNE 19, 2026

3.4   Experimental Protocol

We have evaluated our study based on two benchmark settings. For MNIST we trained a three-layer MLP with hidden dimension 256 and ReLU activations, and for CIFAR-10 we used a TinyCNN (a lightweight convolutional network suitable for controlled ablation studies). All models were trained with cross-entropy loss for 20 epochs (MNIST) and 30 epochs (CIFAR-10), and we performed the following ablations: Optimizer comparison. We compared mini-batch SGD and Adam across both architectures to assess whether the implicit bias toward Riemannian flatness is optimizer-specific. Batch size ablation. We varied B ∈ {32, 128, 512} at fixed η to test the theoretical prediction that SR ∝ η/B (Theorem 1). Learning rate ablation. We fixed B = 128 and varied η ∈ {0.001, 0.01, 0.05, 0.1} to test the scaling of SR with η. Seed robustness. All batch size ablation configurations are repeated over three random seeds; we report mean ± standard deviation. Riemannian and Euclidean sharpness are logged at epochs 5, 10, 15, and 20 (MNIST) or 5, 10, 15, 20, 25, and 30 (CIFAR-10) alongside test accuracy.

4     Theoretical Framework We have formalized the parameter space of a neural network as a statistical manifold and derive the implicit geometric bias of mini-batch SGD.

4.1   Setup: The Statistical Manifold

Let f (· ; θ) : X → RK be a neural network with parameters θ ∈ Rd , defining a family of conditional distributions p(y | x; θ). This family forms a Riemannian manifold (Rd , G(θ)) where the metric tensor is the Fisher Information Matrix (FIM):                                                                        ∂ log p(y | x; θ) ∂ log p(y | x; θ) G(θ)ij = Ex,y                                         .                        (5) ∂θi              ∂θj We define Riemannian sharpness at a minimum θ∗ as: SR (θ∗ ) = tr G(θ∗ )−1 ∇2 L(θ∗ ) ,  (6)

where ∇2 L(θ∗ ) is the Hessian of the training loss. We state that a minimum θ∗ is (λ, G)-flat if λmax (G(θ∗ )−1 ∇2 L(θ∗ )) ≤ λ.

4.2   Lemma 1: Reparametrization Invariance of the FIM Metric

Lemma 1 (Reparametrization Invariance). Let ϕ : Rd → Rd be a smooth reparametrization such that the network function is preserved: f (· ; θ) = f (· ; ϕ(θ)) for all θ. Then the Riemannian sharpness SR is invariant under ϕ. That is, SR (θ∗ ) = SR (ϕ(θ∗ )).                                               (7) 2 In contrast, the Euclidean sharpness SE = tr(∇ L) is not invariant and can be made arbitrarily large or small under ϕ.

Proof. Let θ̃ = ϕ(θ) and let J = ∂ϕ/∂θ ∈ Rd×d denote the Jacobian of the reparametrization. Since p(y | x; θ) = p(y | x; θ̃), the log-likelihood is preserved, and the FIM transforms as a (0, 2) tensor:

G̃(θ̃) = J −⊤ G(θ) J −1 .                                              (8) The Hessian of the loss transforms as: X ∂L ∂ 2 θ̃k ∇ g 2 L(θ̃) = J −⊤ ∇2 L(θ) J −1 +                       ,                            (9) k ∂ θ̃k ∂θ2 |         {z     } = 0 at a minimum

5

A PREPRINT - J UNE 19, 2026

where the second term vanishes at a critical point θ∗ since ∇L(θ∗ ) = 0. Substituting (8) and (9) into (6):            SR (θ̃∗ ) = tr G̃−1 ∇ 2L g

= tr (J −⊤ GJ −1 )−1 J −⊤ ∇2 L J −1 

= tr JG−1 J ⊤ J −⊤ ∇2 L J −1 

= tr JG−1 ∇2 L J −1 

= tr G−1 ∇2 L = SR (θ∗ ),  (10) where the last step uses the cyclic property of the trace. For the Euclidean case, we have considered the rescaling symmetry of a two-layer network, W1 7→ αW1 , W2 7→ α−1 W2 for α > 0 which preserves f exactly. Under this reparametrization J = diag(α1, α−1 1) and the Hessian scales as ∇ 2 L ∼ α2 , so S         2 E → α SE . Taking α → ∞ makes SE arbitrarily large, confirming the critique of Dinh et al. g [2017]. Remark 1. The invariance of G under sufficient statistics is guaranteed by Čencov’s theorem Čencov [1982] such that the FIM is the unique Riemannian metric on the statistical manifold that is invariant under sufficient statistics which makes it a canonical choice for measuring sharpness Jang et al. [2022], Kristiadi et al. [2023].

4.3   Theorem 1: SGD Favors Riemannian-Flat Minima

We make the following assumptions: Assumption 1 (Smoothness). L is L-smooth and the FIM G(θ) is positive definite with condition number bounded by κ < ∞ in a neighborhood U of every local minimum. Assumption 2 (Interpolation). The network is overparameterized and achieves zero training loss at every local minimum at L(θ∗ ) = 0. Remark 2 (Empirical status of Assumption 2). The zero training loss condition holds exactly in the overparameterized interpolating regime and is satisfied in our MNIST experiments. In the large-batch CIFAR-10 setting (B = 512), training loss does not reach zero and the theoretical guarantees of Theorem 1 are expected to degrade gracefully. The implicit bias toward Riemannian-flat minima weakens but does not vanish, as the stationary distribution π ∗ ∝ exp(− B     η L(θ)) still assigns greater mass to flatter minima even when L(θ∗ ) > 0. Assumption 3 (Fisher Noise Structure). The covariance of the mini-batch gradient noise at a minimum θ∗ satisfies: h         i      η Cov ∇L̃(θ∗ ) =          G(θ∗ ),                                      (11) B where η is the learning rate and B is the batch size. Remark 3 (Empirical status of Assumption 3). The equality α = η/B is derived under the continuous-time SDE limit, which requires η → 0 and B → ∞ in a coordinated fashion Li et al. [2017]. Neither condition holds in practice. Section 5 provides the first systematic empirical test of this assumption, decomposing it into a directional claim (that Cov[∇L̃] and G are proportional as matrices) and a scalar claim (that the constant is exactly η/B). The directional claim holds strongly across all configurations tested; the scalar claim fails in a structured way. Theorem 2 shows that the main theoretical conclusions of this paper are robust to this weakening. Assumption 4 (Barrier Separation). Distinct local minima are separated by loss barriers of height at least ∆ > 0. Theorem 1 (SGD Implicit Bias Toward Riemannian Flatness). Under Assumptions 1–4, in a neighborhood of each local minimum where G(θ) varies slowly relative to the loss curvature, the continuous-time SDE approximation of mini-batch SGD:                                                  r η dθ = −∇L(θ) dt +               G(θ)1/2 dWt ,                                (12) B ∗ admits a stationary distribution π with density:             B π ∗ (θ) ∝ exp − L(θ) .                                               (13) η Consequently, the probability mass assigned to a basin around minimum θ∗ is proportional to: 1/2 det G(θ∗ )  ∗     ∗ π (B(θ )) ∝ det ∇2 L(θ∗ ) d                                                            (14) ∗ −1/2 Y ∗ −1 2  =      λi G(θ ) ∇ L(θ )            , i=1

6

A PREPRINT - J UNE 19, 2026

where λi (·) denotes the i-th eigenvalue. Therefore, SGD asymptotically favors minima with smaller Riemannian sharpness SR (θ∗ ) = tr(G−1 ∇2 L).

Proof. Step 1: SDE Derivation. Mini-batch SGD iterates as θt+1 =p      θt − η∇L̃(θt ), where ∇L̃ = ∇L + ξt and ξt η                 η is the gradient noise. By Assumption 3, Cov[ξt ] = B     G(θ), so ξt ≈ B   G(θ)1/2 ζt with ζt ∼ N (0, I). Taking the continuous-time limit Li et al. [2017] yields the Itô SDE (12). Step 2: Fokker-Planck Equation. Let ρ(θ, t) denote the probability density of θt . In a neighbourhood U of a local minimum θ∗ , we approximate G(θ) ≈ G(θ∗ ) to be locally constant. Under this approximation, the Itô and Stratonovich forms of the Fokker–Planck equation coincide, and the diffusion term takes the form below; the cross-terms ∂i Gij ∂j ρ and ∂i ∂j Gij ρ that arise from a position-dependent G are absorbed into the higher-order remainder. The Fokker-Planck equation associated with (12) is: ∂ρ                        η = ∇ ·(ρ ∇L) +           ∇ ·(G(θ) ∇ρ) ,                                (15) ∂t                       2B where the first term is the drift and the second is the diffusion term under the locally-constant-G approximation. Step 3: Stationary Distribution. We seek a local approximation to the density near a minimum θ∗ . Under the locally- constant-G assumption from Step 2, the Itô SDE in (12) reduces to one with constant diffusion (η/B)G(θ∗ ), for which the stationary density of the local quadratic loss is the Gaussian shown below. We do not claim that exp(−(B/η)L) is the global stationary distribution of the SDE on all of Rd ; with position-dependent G, the global stationary distribution carries an additional Jacobian factor (see, e.g., Roberts & Stramer, 2002). We seek ρ∗ such that ∂ρ∗ /∂t = 0. Under Assumption 1, we work in a neighborhood U(θ∗ ) where G(θ) ≈ G(θ∗ ) is approximately constant; the derivation holds locally near each minimum. Substituting the ansatz ρ∗ (θ) ∝ exp(− B η L(θ)) into (15), the drift term gives:                                             ∗           ∗          B     2 ∇ · (ρ ∇L) = ρ ∆L − ∥∇L∥ .                                                (16) η The diffusion term gives:             η             ∗       η         B ∗ ∇ · (G∇ρ ) =          ∇ · − ρ G∇L 2B                    2B         η 1 = − ∇ · (ρ∗ G∇L).                                         (17) 2 Under Assumption 3, at a minimum where the noise structure is exactly G(θ), the drift and diffusion terms satisfy the detailed balance condition: η ρ∗ ∇L +         G(θ)∇ρ∗ = 0,                                         (18) 2B which is solved exactly by ρ∗ ∝ exp(− B  η L(θ)), confirming (13).

Step 4: Probability Mass via Laplace Approximation. Near each minimum θ∗ , approximate the loss quadratically: L(θ) ≈ 12 (θ − θ∗ )⊤ H ∗ (θ − θ∗ ),                                        (19) ∗      2    ∗                                          ∗ where H = ∇ L(θ ). The probability mass in the basin B(θ ) is: Z                                           B π ∗ (B(θ∗ )) ∝          exp − (θ − θ∗ )⊤ H ∗ (θ − θ∗ ) dθ B(θ ∗ )          2η         d/2 2πη =               (det H ∗ )−1/2 B d/2 (det G∗ )1/2  2πη = B           (det G∗ )1/2 (det H ∗ )1/2 1/2 det G∗            −1/2 ∝                    = det(G∗−1 H ∗ )         ,                                  (20) det H ∗ which is exactly (14). The Gaussian integral yields (det H ∗ )−1/2 directly. The subsequent rewriting in terms of det(G∗−1 H ∗ ) is an algebraic identity, not a derivation: the basin mass itself depends only on H ∗ in this local approxi- mation. The Riemannian structure enters Corollary 1 only through the ratio of FIM determinants between two minima,

7

A PREPRINT - J UNE 19, 2026

(det G∗A / det G∗B )1/2 , which is non-negligible when the minima are related by a function-preserving reparametrization (Lemma 1) but negligible when they correspond to genuinely distinct solutions with similar FIMs. Here G∗ is inserted multiplicatively in the numerator and denominator purely to express the result in terms of the generalized Q eigenvalues λi (G∗−1 H ∗ ); the formula P (14) is an equivalent rewriting of (det H ∗ )−1/2 . Since det(G∗−1 H ∗ ) = i λi (G∗−1 H ∗ ) and SR = tr(G∗−1 H ∗ ) = i λi (G∗−1 H ∗ ), by the AM-GM inequality:       d Y                       SR λi (G∗−1 H ∗ ) ≤            ,                                     (21) i d so higher probability mass is assigned to minima with smaller SR .

4.4   Corollary 1: Asymptotic Preference for Riemannian-Flat Minima ∗      ∗ Corollary 1 (Asymptotic Flatness Preference). Under the conditions of Theorem 1, given two local minima θA       and θB with equal loss values, the ratio of their probability masses under the SGD stationary distribution satisfies: d/2 π ∗ (B(θA ∗              ∗  ))      SR (θB ) ∗ )) =         ∗)       · O(1),                                   (22) π ∗ (B(θB          SR (θA ∗                                   ∗ as d → ∞ under isotropic eigenvalue assumptions. In particular, θA         is exponentially preferred over θB  whenever ∗          ∗ SR (θA ) < SR (θB ), with the preference strengthening as η/B decreases. Remark 4. The isotropic eigenvalue assumption (λi (G−1 H ∗ ) ≈ SR /d for all i) is a simplifying condition used to obtain a closed-form mass ratio. In practice the eigenvalues of G−1 H ∗ are non-uniform and its exact ratio depends on the full spectrum. The qualitative conclusion is that minima with smaller SR are exponentially preferred which follows directly from Theorem 1 without this assumption.

4.5   Corollary 2: Generalization Bound via PAC-Bayes

Corollary 2 (Riemannian Flatness Implies Generalization). Let θ∗ be a (λ, G)-flat minimum of the training loss, and let θ0 be the (fixed, data-independent) initialization. Define the posterior Q = N (θ∗ , σ 2 I) and the prior P = N (θ0 , σ02 I). Then for any δ > 0, with probability at least 1 − δ over the draw of n training samples, s  d2 /σ02  ∗              ∗         1                                  1 Ltest (θ ) − Ltrain (θ ) ≤                                  +   log     ,                    (23) 2n SR (θ∗ ) λmin (G(θ∗ ))           δ where SR (θ∗ ) = tr G(θ∗ )−1 ∇2 Ltrain (θ∗ ) is the Riemannian sharpness and λmin (G(θ∗ )) is the smallest eigenvalue  of the Fisher information matrix at θ∗ . The bound is increasing in SR : flatter minima generalize better.

Proof. Step 1: PAC-Bayes setup. We apply the PAC-Bayes theorem McAllester [1999], Dziugaite and Roy [2017]: for any prior P fixed before observing the data and any posterior Q (which may depend on the data), with probability at least 1 − δ over the draw of the training set, r KL(Q ∥ P ) + log(1/δ) Eθ∼Q [Ltest (θ)] ≤ Eθ∼Q [Ltrain (θ)] +                               .                    (24) 2n Set the prior P = N (θ0 , σ02 I) centered at the data-independent initialization θ0 , and the posterior Q = N (θ∗ , σ 2 I) centered at the trained minimum. The KL divergence is d σ2              σ2      ∥θ∗ − θ0 ∥2                      KL(Q ∥ P ) =          − 1 −  log       +              .                           (25) 2 σ02             σ02         2σ02 2 Since x − 1 − log x ≤ x for all x > 0, the first term satisfies d2 (σ 2 /σ02 − 1 − log(σ 2 /σ02 )) ≤ dσ 2σ 2 . Absorbing the 0 displacement term ∥θ∗ − θ0 ∥2 /(2σ02 ) into a constant C0 (it is independent of σ 2 ), we obtain d σ2 KL(Q ∥ P ) ≤           + C0 .                                             (26) 2σ02 Step 2: Bounding the expected training loss under Q. Since θ∗ is a (λ, G)-flat minimum, ∇Ltrain (θ∗ ) = 0 and ∇2 Ltrain (θ∗ ) ⪯ λ G(θ∗ ). By a second-order Taylor expansion, for any perturbation ϵ ∼ N (0, σ 2 I), EQ [Ltrain (θ∗ + ϵ)] ≤ Ltrain (θ∗ ) + 12 Eϵ ϵ⊤ ∇2 Ltrain (θ∗ ) ϵ                     

λ σ2 ≤ Ltrain (θ∗ ) +        tr(G(θ∗ )),                                  (27) 2

8

A PREPRINT - J UNE 19, 2026

where the second inequality uses E[ϵϵ⊤ ] = σ 2 I and ∇2 L ⪯ λG. Additionally, by the same flatness bound, λ σ2 Ltest (θ∗ ) ≤ EQ [Ltest (θ)] +    tr(G(θ∗ )),                              (28) 2 2                 2 because any smooth loss satisfies |L(θ∗ ) − EQ [L]| ≤ σ2 λmax (H ∗ ) ≤ λσ2 tr(G) under the flatness assumption (here we use tr(G) ≥ λmax (G) and the PSD bound). Step 3: Combining and optimizing σ 2 . Substituting (27), (28), and (26) into (24) and rearranging gives, with probability at least 1 − δ, v u d σ2                 1 u u 2 + C0 + log 2σ                δ Ltest (θ∗ ) − Ltrain (θ∗ ) ≤ λ σ 2 tr(G(θ∗ )) + t       0 .                (29) 2n We minimize the right-hand side over σ 2 ∈ (0, σ02 ]. Setting the derivative with respect to σ 2 to zero and solving (see Dziugaite and Roy [2017], Section 4) yields the optimal                                 2               2          1            d σ⋆ = min σ0 ,                         ·        .                              (30) n λ2 tr(G(θ∗ ))2 8σ02 Substituting (30) back into (29) and using the definition SR (θ∗ ) = tr(G(θ∗ )−1 ∇2 L(θ∗ )) ≤ dλ to bound λ ≥ SR (θ∗ )/d, and the inequality tr(G(θ∗ )) ≥ d λmin (G(θ∗ )) (since tr(A) ≥ d λmin (A) for any PSD A), we obtain the chain of inequalities SR (θ∗ ) λ tr(G(θ∗ )) ≥               · d λmin (G(θ∗ )) = SR (θ∗ ) λmin (G(θ∗ )),                    (31) d d/(8σ 2 ) which means σ⋆2 ≤ n S 2 λ20 . Substituting and collecting constant and logarithmic factors into a single d2 /σ02 prefactor R min (see Neyshabur et al. [2017], Theorem 1, for the detailed bookkeeping) yields s  d2 /σ02  ∗              ∗          1                                  1 Ltest (θ ) − Ltrain (θ ) ≤                                      + log     ,                 (32) 2n SR (θ∗ ) λmin (G(θ∗ ))           δ which is (23). The bound is strictly increasing in SR (θ∗ ) and strictly decreasing in λmin (G(θ∗ )), confirming that flatter minima (smaller Riemannian sharpness) generalize better. Remark 5. Equation (23) makes the flatness-generalization link precise and the generalization gap is upper bounded by a function decreasing in SR (θ∗ ) and in λmin (G(θ∗ )). A Riemannian-flat minimum (small SR ) therefore provably generalizes better, independent of Euclidean sharpness, directly addressing the critique of Dinh et al. [2017]. The constant C = d2 /σ02 is dimension-dependent and tightening this via a data-dependent prior or a structured posterior remains an avenue for future work.

5     Empirical Validation of Assumption 3

Assumption 3 bundles two distinct claims. The first is a directional claim that the Cov[∇L̃(θ)] and G(θ) are positively proportional as matrices, i.e. they share the same structure in parameter space. The second is a scalar claim which states that the proportionality constant is exactly η/B. These two claims can fail independently. For our study we have decomposed and tested each separately.

5.1   Metrics

Since computing full d × d covariance and FIM matrices is intractable at the scale of modern networks, all three matrices, ie., Σ, G, and ∇2 L are approximated by their diagonals, in accordance with the diagonal approximation used for SE and SR throughout this paper.

Diagonal FIM. We use the empirical Fisher diagonal. For each mini-batch (xj , ỹj ) with ỹj ∼ p( · | xj ; θ) sampled from the model’s own predictive distribution: Nb                        2 1 X      ∂ log p(ỹj | xj ; θ) Ĝ(θ)ii ≈                                   ,                                (33) Nb j=1          ∂θi averaged over Nb = 30 mini-batches with Tikhonov damping λ = 10−6 .

9

A PREPRINT - J UNE 19, 2026

Figure 1: Sharpness comparison on MNIST (three-layer MLP). From left to right: Riemannian sharpness SR , Euclidean sharpness SE , and test accuracy over training.

Figure 2: Sharpness comparison on CIFAR-10 (TinyCNN). From left to right: Riemannian sharpness SR , Euclidean sharpness SE , and test accuracy over training.

Diagonal gradient covariance. The diagonal of Σ(θ) = Cov[∇L̃(θ)] is estimated from K = 200 mini-batches via the standard variance decomposition:              2 K            K 1 X 2       1  X Σ̂(θ)ii =      g −          gj,i  ,                              (34) K j=1 j,i   K j=1

where gj,i = ∂ L̃j (θ)/∂θi . Negative entries from numerical noise are clamped to zero. We use K = 200 batches because the covariance estimator requires a stable second moment, which converges more slowly than the first.

Alignment metrics.     Given diagonal vectors Σ̂, Ĝ ∈ Rd , we compute two metrics. For the directional claim: ⟨Σ̂, Ĝ⟩ cosine =                 ,                                       (35) ∥Σ̂∥ ∥Ĝ∥ which takes values in [−1, 1]; a value near +1 means Σ̂ and Ĝ point in the same direction in parameter space. For the scalar claim: η Σ̂ − B  Ĝ γ =                 ,                                             (36) η B Ĝ

which equals zero if and only if Σ̂ = (η/B)Ĝ exactly, and is large when the magnitudes are mismatched.

Experimental scope. We evaluated these metrics across two benchmarks (MNIST and CIFAR-10) with two architec- tures (a three-layer MLP and TinyCNN), two optimizers (SGD and Adam), three batch sizes (B ∈ {32, 128, 512}) and

10

A PREPRINT - J UNE 19, 2026

four learning rates (η ∈ {0.001, 0.01, 0.05, 0.1}). Metrics are computed at a mid-training checkpoint (epoch 10 for MNIST, epoch 15 for CIFAR-10), where the learning rate schedule has not yet driven η → 0.

5.2     Results

5.2.1    Directional Claim: Cosine Alignment Table 1 reports cosine alignment at the mid-training checkpoint across all configurations.

Table 1: Cosine alignment between diag(Σ̂) and diag(Ĝ) at the mid-training checkpoint. MNIST and CIFAR-10 values are mean ± std over three seeds across all batch sizes. Dataset       Optimizer    Mean       Std       Min    Max MNIST         SGD          1.000     0.000     1.000   1.000 MNIST         Adam         1.000     0.000     1.000   1.000 CIFAR-10      SGD          0.997     0.005     0.984   1.000 CIFAR-10      Adam         0.992     0.003     0.989   0.997

The directional claim holds strongly across all configurations. On MNIST and CIFAR-10 with SGD, cosine alignment is effectively 1.000 at every batch size and learning rate tested, indicating that the gradient noise covariance and the FIM are nearly perfectly aligned as diagonal vectors in parameter space. Adam on CIFAR-10 shows marginally lower alignment (0.993), which is consistent with Adam’s adaptive preconditioning modifying the effective gradient distribution, yet the directional claim remains well supported.

5.2.2    Scalar Claim: Power-Law Scaling of γ Table 2 reports γ as a function of batch size at fixed η = 0.01 under SGD.

Table 2: Relative Frobenius error γ and cosine alignment at the mid-training checkpoint for SGD with η = 0.01. MNIST values are mean over three seeds (epoch 20); CIFAR-10 values are mean over three seeds (epoch 30). Dataset       B             η/B                   γ     cosine MNIST         32     3.13 × 10−4      0.007 ± 0.009      1.000 MNIST         128    7.81 × 10−5      0.002 ± 0.000      1.000 MNIST         512    1.95 × 10−5      0.002 ± 0.000      1.000 CIFAR-10      32     3.13 × 10−4      0.121 ± 0.045      0.997 CIFAR-10      128    7.81 × 10−5      0.016 ± 0.000      1.000 CIFAR-10      512    1.95 × 10−5      0.007 ± 0.000      1.000

On MNIST, γ is negligible across all batch sizes (below 0.01), indicating that the gradient noise covariance is extremely well matched to (η/B) G(θ) in magnitude — the scalar claim holds closely in this setting. On CIFAR-10, γ is small overall and decreases as B increases, with the only noteworthy deviation occurring at B = 32 (γ = 0.071). This is consistent with the small-batch, high-noise regime being furthest from the continuous-time SDE limit that underlies the η/B prefactor. Across all configurations, the frob values are at most 0.184 (an isolated late-epoch outlier in CIFAR-10 at B = 32), confirming that the dominant failure mode is a modest scalar mismatch rather than a structural one.

5.2.3    Learning Rate Ablation Table 3 reports γ and cosine for the MNIST learning rate ablation at fixed B = 128 over three seeds.

Table 3: Learning rate ablation on MNIST (MLP, B = 128, epoch 20, seed 0). η           η/B          γ    cosine    Test acc. 0.001    7.81 × 10−6     0.007    1.000      0.968 0.010    7.81 × 10−5     0.001    1.000      0.981 0.050    3.91 × 10−4     0.000    1.000      0.985 0.100    7.81 × 10−4     0.006    1.000      0.977

Cosine alignment is 1.000 across all learning rates, and γ is uniformly small and decreases as η increases. Both claims of Assumption 3 are therefore well supported on MNIST across the full range of learning rates tested.

11

A PREPRINT - J UNE 19, 2026

5.3   Refined Assumption and Theoretical Robustness

The results above motivate replacing Assumption 3 with the following weaker but empirically supported condition. Assumption 5 (Refined Fisher Noise Structure). The covariance of the mini-batch gradient noise at a parameter θ satisfies                                   h       i Cov ∇L̃(θ)     = α(θ) G(θ),                                           (37)

where α(θ) > 0 is a scalar that may depend on the parameter location and training regime but not on η or B in the large-batch limit.

We now show that the two main theoretical conclusions of this paper are robust to this weakening. Theorem 2 (Stationary Distribution Under Refined Noise). Under Assumptions 1, 2, and 4 of this paper and under Assumption 5, the continuous-time SDE approximation of mini-batch SGD, p dθ = −∇L(θ) dt +       α(θ) G(θ)1/2 dWt ,                               (38) admits a stationary distribution π ∗ with density         L(θ) π ∗ (θ) ∝ exp −        .                                             (39) α(θ) When α is approximately constant in a neighbourhood of a minimum θ∗ , the probability mass assigned to the basin B(θ∗ ) is 1/2 det G(θ∗ )  ∗    ∗ π (B(θ )) ∝                        ,                                  (40) det ∇2 L(θ∗ ) which depends only on G(θ∗ ) and ∇2 L(θ∗ ), not on α. Consequently, SGD asymptotically favours minima with smaller Riemannian sharpness SR (θ∗ ) = tr(G−1 ∇2 L) regardless of the value of α.

Proof. Step 1: Stationary distribution. The Fokker–Planck equation for the density ρ(θ, t) is ∂ρ               1 = ∇ · (ρ ∇L) + ∇ ·(αG(θ) ∇ρ) .                                            (41) ∂t               2 Substituting the ansatz ρ∗ ∝ exp(−L/α) into the detailed balance condition and using ∇ρ∗ = −(1/α)ρ∗ ∇L confirms the stationary density at critical points where ∇L(θ∗ ) = 0 (Assumption 2 ensures training loss is zero at all minima). Step 2: Basin mass. Near θ∗ , approximate L(θ) ≈ 12 (θ − θ∗ )⊤ H ∗ (θ − θ∗ ) with H ∗ = ∇2 L(θ∗ ) and L(θ∗ ) = 0. The Gaussian integral over the basin yields 1/2 det G∗  π ∗ (B(θ∗ )) ∝ (2πα)d/2 (det H ∗ )−1/2 ∝                    ,                        (42) det H ∗

where (2πα)d/2 cancels in any ratio of two basins since α is constant across minima, giving (40). Step 3: Implicit bias. By the AM–GM inequality, i λi (G∗−1 H ∗ ) ≤ (SR /d)d , so higher mass is assigned to minima Q with smaller SR which is the same as in the original framework.

Remark 6. The key observation in Step 2 is that α appears only in the prefactor (2πα)d/2 , which is identical for every basin and cancels in any pairwise comparison. The basin mass ratio depends solely on the Riemannian geometry encoded by G and H at each minimum. This is why the implicit bias toward Riemannian-flat minima is robust to the scalar mismatch documented in Section 5.2: the mismatch is real but theoretically inconsequential for the flatness bias. ∗      ∗ Corollary 3 (Asymptotic Flatness Preference). Under the conditions of Theorem 2, given two local minima θA and θB with equal loss values, the ratio of their stationary masses satisfies d/2 π ∗ (B(θA∗              ∗  ))     SR (θB   ) ∗ )) =         ∗)        · O(1),                            (43) π ∗ (B(θB         SR (θA ∗                                          ∗ under isotropic eigenvalue assumptions as d → ∞. In particular, θA is exponentially preferred whenever SR (θA )< ∗ SR (θB ), with the preference independent of α.

12

A PREPRINT - J UNE 19, 2026

Proof. From (40), the mass ratio equals (det(G−1 ∗         −1 ∗ 1/2 B HB )/ det(GA HA ))     . Under the isotropic assumption −1 ∗                               −1 ∗      d λi (G H ) ≈ SR /d, this gives det(G H ) ≈ (SR /d) , yielding the stated ratio. The factor α does not appear because it cancelled in Step 2 of Theorem 2. Corollary 4 (PAC-Bayes Bound Under Refined Noise). Let Q = N (θ∗ , σ 2 I) be a Gaussian posterior centred at a (λ, G)-flat minimum θ∗ , and let P = N (θ0 , σ02 I) be a data-free prior. For any δ > 0, with probability at least 1 − δ over the draw of n training samples, s  d2 /σ02  ∗             ∗          1                               1 Ltest (θ ) − Ltrain (θ ) ≤                                 + log     .                     (44) 2n SR (θ∗ ) λmin (G(θ∗ ))        δ This bound holds under either Assumption 3 or the refined Assumption 5; the scalar α does not appear. p Proof. The PAC-Bayes theorem McAllester [1999] gives Ltest − Ltrain ≤ (KL(Q ∥ P ) + log(1/δ))/(2n). The KL divergence is bounded by dσ 2 /(2σ02 ) when σ 2 ≤ σ02 . Setting σ 2 = (λ λmin (G(θ∗ )))−1 via the (λ, G)-flatness condition and using SR (θ∗ ) ≤ dλ yields (44). The derivation involves only G(θ∗ ) and ∇2 L(θ∗ ) through SR and λmin (G); the noise covariance and α do not appear.

6     Results and Discussion 6.1   SGD Batch Size and the η/B Scaling Law

Theorem 1 predicts that SR at convergence should scale inversely with η/B, i.e., SR ∝ B/η. Table 4 confirms this prediction across three batch sizes at fixed learning rate η = 0.01. On MNIST, increasing B from 32 to 512 raises SR from approximately 388 to 71,656, a factor of roughly 185×, while test accuracy declines from 0.985 to 0.977. The scaling is broadly consistent with the theoretical prediction, though not perfectly linear, likely due to the diagonal FIM approximation and finite training epochs. Results are stable across random seeds, with standard deviations below 20% of the mean. On CIFAR-10, the batch size picture is more nuanced. SR increases from 128,412 at B = 32 to 802,797 at B = 512, consistent with the theoretical trend. However, test accuracy at B = 128 (0.803) is higher than at B = 32 (0.773), despite B = 128 having higher SR . We attribute this to the small-batch, high-noise regime on TinyCNN/CIFAR-10 being genuinely difficult to optimize at B = 32: the gradient noise is large enough to impede convergence as well as flatten the minimum, and the model has not fully converged within 30 epochs. The B = 512 regime, by contrast, achieves lower accuracy (0.766) with much higher SR , consistent with being trapped in sharp minima with insufficient noise to escape. The B=128 configuration occupies a favorable middle ground. Euclidean sharpness SE tracks SR proportionally throughout, as expected when the FIM is approximately isotropic.

Table 4: Batch size ablation (SGD, η = 0.01, final epoch, mean ± std over 3 seeds). SR grows with B on both datasets as predicted by Theorem 1. Dataset     B               SR                    SE             Test Acc 32         388.0 ± 252.0           0.8 ± 0.5      0.985 ± 0.000 MNIST        128      12,284.6 ± 3,294.2       24.6 ± 6.6      0.981 ± 0.000 512     71,656.1 ± 10,580.9      143.7 ± 21.2     0.977 ± 0.000 32     128,412.1 ± 10,952.0      299.0 ± 25.4     0.773 ± 0.006 CIFAR-10      128     386,247.4 ± 3,891.3      825.7 ± 14.2     0.803 ± 0.005 512     802,796.5 ± 2,504.6      1658.8 ± 2.8     0.766 ± 0.004

6.2   Learning Rate Scaling

Fixing B = 128 and varying η reveals a clear relationship between η and SR (Table 5). On MNIST, larger learning rates produce smaller SR and better generalization, consistent with Theorem 1: at η = 0.001, SR ≈ 73,102 with test accuracy 0.968, while at η = 0.05, SR drops to 168 and accuracy rises to 0.985. The one exception is η = 0.1, which gives a higher SR (3,668) than η = 0.05 and slightly worse accuracy (0.977), suggesting that at very large learning rates SGD enters a regime where the SDE approximation breaks down and the noise is no longer simply regularizing. On CIFAR-10 the pattern reverses at large η: accuracy peaks at η = 0.01 (0.807) and falls sharply at η = 0.1 (0.609), while SR continues to decrease. This divergence — lower SR but worse accuracy — occurs because η = 0.1 is too large

13

A PREPRINT - J UNE 19, 2026

Figure 3: Riemannian sharpness SR as a function of batch size and learning rate for MNIST (top) and CIFAR-10 (bottom), confirming the inverse η/B scaling (SR ∝ B/η) predicted by Theorem 1.

for stable optimization on this task with TinyCNN; the model fails to converge properly rather than finding a genuinely flat and well-generalizing minimum. This reinforces an important caveat: SR is a reliable predictor of generalization when the optimizer has converged, but very large learning rates can produce low SR at unstable or suboptimal solutions.

Table 5: Learning rate ablation (SGD, B = 128, final epoch, seed 0). On MNIST, larger η consistently lowers SR and improves generalization. On CIFAR-10, η = 0.1 achieves low SR but poor accuracy due to training instability. Dataset     η            η/B              SR        Test Acc 0.001    7.81 × 10−6       73,102.1      0.968 0.010    7.81 × 10−5       7,629.1       0.981 MNIST 0.050    3.91 × 10−4        167.9        0.985 0.100    7.81 × 10−4       3,668.1       0.977 0.001    7.81 × 10−6     1,176,416.0     0.717 0.010    7.81 × 10−5      386,314.4      0.807 CIFAR-10 0.050    3.91 × 10−4      148,639.5      0.748 0.100    7.81 × 10−4       95,286.9      0.609

6.3   Training Dynamics

Beyond final-epoch values, the training trajectories in Table 6 reveal how SR evolves during optimization. On MNIST, SGD small-batch (B = 32) shows monotonically decreasing sharpness: from 15,232 at epoch 5 (seed 0) down to 190 at epoch 20. This is consistent with the SDE stationary distribution interpretation — the optimizer progressively escapes sharp basins and settles into flatter regions as training continues. Large-batch SGD (B = 512) follows a different trajectory. Sharpness decreases more slowly and stabilizes at a high plateau (63,909–87,570 depending on seed), while test accuracy improves more gradually. The reduced noise temperature η/B is insufficient to drive the optimizer into genuinely flat basins.

14

A PREPRINT - J UNE 19, 2026

Figure 4: Riemannian sharpness SR as a function of learning rate at fixed batch size B = 128.

Adam on MNIST also converges to low sharpness by epoch 20 (2,575–6,095 across seeds) and achieves high accuracy (0.980 averaged over seeds), slightly above SGD small-batch. The steep early descent in sharpness suggests Adam’s adaptive preconditioning accelerates the implicit bias toward flat minima. On CIFAR-10 (Table 7), SGD with B = 128 shows sharpness increasing slightly over training (308,825 at epoch 5 to 386,314 at epoch 30, seed 0) while accuracy improves steadily (0.699 → 0.807). Adam on CIFAR-10 exhibits more variable dynamics, with sharpness stabilizing around 232,765 by epoch 30 (seed 0; 226,738 averaged over seeds) and accuracy reaching 0.794 on average — a profile consistent with a different geometry of descent than FIM-based SGD.

Table 6: Training dynamics on MNIST. SR and SE reported at epochs 5, 10, 15, 20 for small-batch SGD, large-batch SGD, and Adam (all seed 0). Optimizer           Epoch    Test Acc       SR        SE 5         0.979      15,232.3     30.8 10        0.984      4,306.6       8.6 SGD (B = 32) 15        0.985       620.2        1.2 20        0.985       190.0        0.4 5         0.955      87,570.1    176.3 10        0.969      82,920.9    166.5 SGD (B = 512) 15        0.975      80,536.7    161.5 20        0.977      63,909.2    128.1 5         0.980      15,246.6     30.9 10        0.981      7,882.7      16.0 Adam (B = 128) 15        0.980      14,536.3     29.5 20        0.981      3,015.1       6.0

6.4   SGD vs. Adam

Table 8 compares SGD and Adam across MNIST and CIFAR-10. On MNIST, Adam achieves low SR (3,895 on average over seeds) and high accuracy (0.980), comparable to SGD small-batch. This is consistent with Adam’s adaptive

15

A PREPRINT - J UNE 19, 2026

Table 7: Training dynamics for TinyCNN on CIFAR-10 (SGD B = 128 and Adam B = 128, seed 0). Sharpness values are FIM-based (SR ) and Euclidean (SE ). Optimizer            Epoch     Test Acc       SR           SE 5          0.699      308,824.8      679.6 10         0.758      351,542.6      752.7 15         0.766      362,620.0      781.3 SGD (B = 128) 20         0.788      374,911.9      801.4 25         0.796      358,997.5      760.0 30         0.807      386,314.4      821.9 5          0.711      237,225.5      965.2 10         0.753      244,045.6     1135.9 15         0.763      234,513.6     1157.2 Adam (B = 128) 20         0.774      237,633.5     1241.8 25         0.778      237,011.7     1078.3 30         0.789      232,765.0     1072.1

Table 8: Summary of final metrics across all configurations (epoch 20 for MNIST, epoch 30 for CIFAR-10; mean over 3 seeds where available). SR is FIM-based Riemannian sharpness; SE is Euclidean sharpness. Configuration                               Test Acc        SR          SE SGD small-batch (MNIST, B = 32)              0.985         388.0        0.8 SGD large-batch (MNIST, B = 512)             0.977       71,656.1      143.7 Adam (MNIST, B = 128)                        0.980        3,895.4       7.8 TinyCNN SGD (CIFAR-10, B = 128)              0.803      386,247.4      825.7 TinyCNN Adam (CIFAR-10, B = 128)             0.794      226,737.6     1,157.7

preconditioning implicitly optimizing for flatness in the FIM-weighted geometry, even though the SDE framework of Theorem 1 was derived for SGD with Fisher-structured noise. On CIFAR-10, Adam achieves slightly lower SR (226,738) than SGD (386,247) but also slightly lower accuracy (0.794 vs. 0.803). The two metrics are not straightforwardly comparable across optimizers, because Adam’s preconditioning changes the effective metric under which sharpness is being measured. To investigate, we compute the Adam-adjusted Riemannian sharpness, Adam = tr G−1  SR             Adam H ,     GAdam = diag(vt ),                              (45) where vt is Adam’s second-moment diagonal. This captures the flatness of the minimum with respect to Adam’s own preconditioning geometry rather than the FIM. Remark 7. This supports a broader interpretation: the implicit bias of any preconditioned optimizer is toward minima flat with respect to the optimizer’s own metric tensor, of which the SGD/FIM result is a special case.

6.5   Reparametrization Invariance

Lemma 1 guarantees that SR is invariant under smooth reparametrizations when the true FIM is used. However in practice the empirical diagonal FIM estimator is not fully reparametrization-invariant. Under a layer-wise weight rescaling that preserves the network’s input–output function exactly, SE increases dramatically while SR remains substantially more stable — yet still deviates from exact invariance. This gap has a clear mechanical explanation: rescaling the weights changes gradient magnitudes, which in turn changes the independently re-estimated empirical FIM at the rescaled parameters. The empirical Fisher therefore does not transform as a (0, 2) tensor under reparametrization, and the cancellation exploited in the proof of Lemma 1 fails. This is not a failure of the theory — the invariance guarantee of Lemma 1 applies to the true FIM, which is a property of the predictive distribution alone and is therefore parameterization-independent. The limitations of the empirical Fisher as a proxy for the true FIM are well-documented Kunstner et al. [2019], and exact invariance under arbitrary reparametrizations would require a structured estimator such as K-FAC Martens and Grosse [2015] that captures the full covariance rather than only the diagonal. The natural-gradient literature Pascanu and Bengio [2014] similarly distinguishes between theoretical properties of the true FIM and the behavior of tractable approximations. We regard the development of reparametrization-robust empirical FIM estimators as an important avenue for future work, and we caution the reader that the invariance claim in our abstract and contributions is a property of SR defined with the true FIM; the empirical ŜR used in all experiments inherits this invariance only approximately.

16

A PREPRINT - J UNE 19, 2026

Figure 5: Comparison of Fisher Information Matrix-based Riemannian sharpness SR and Euclidean Hessian sharpness

7   Conclusion We have presented a geometric framework for understanding the implicit bias of mini-batch SGD through the lens of information geometry. By replacing the Euclidean metric on parameter space with the Fisher Information Matrix, we have defined a reparametrization-invariant sharpness measure — Riemannian sharpness SR — which addresses the fundamental objection to the flatness-generalization narrative raised by Dinh et al. [2017]. Our main results establish that (i) SR is invariant under smooth function-preserving reparametrizations (Lemma 1); (ii) the stationary distribution of mini-batch SGD assigns exponentially greater probability mass to Riemannian-flat minima (Theorem 1, Corollary 1); and (iii) SR controls generalization through a PAC-Bayes bound (Corollary 2). Empirically, SR is a reliable predictor of generalization across batch sizes, learning rates, and optimizers on both MNIST and CIFAR-10. The scaling of SR with η/B confirms Theorem 1 on MNIST, where the scalar claim of Assumption 3 holds closely. On CIFAR-10 the directional alignment between the gradient noise covariance and the FIM is very high (cosine > 0.984), but the η/B scaling is less clean, particularly at large learning rates where training instability confounds the geometric interpretation. The behavior of Adam suggests a natural extension of our framework to preconditioned optimizers, where the relevant flatness measure is defined with respect to the optimizer’s own preconditioning matrix rather than the FIM. Limitations. Assumption 3 (Fisher noise structure) is an approximation that holds well directionally but whose scalar magnitude varies with architecture and dataset. The diagonal FIM approximation discards off-diagonal correlations, and the continuous-time SDE limit requires sufficiently small η. The empirical ŜR is not fully reparametrization-invariant in practice, though it remains substantially more stable than SE under rescaling, as discussed in Section 6.5. On CIFAR-10, the relationship between SR and generalization is not monotone across all learning rates, indicating that the metric is most informative when the optimizer has converged to a genuine minimum. Future work should extend validation to larger architectures and structured (Kronecker-factored) FIM estimates. Broader Impact. Our results provide a theoretically grounded justification for small-batch training as a geometric regularization strategy and suggest that flatness-aware objectives such as SAM Foret et al. [2021] may be most naturally formulated in the Riemannian geometry of parameter space.

8   Acknowledgment The authors declare no external funding for this work. During the preparation of this manuscript, the authors used AI-assisted tools (Claude, DeepSeek) for coding and debugging assistance, and Grammarly for grammar and language suggestions. All theoretical development, experimental design, analysis, and conclusions are the sole responsibility of the authors.

References S. Amari. Natural gradient works efficiently in learning. Neural Computation, 10(2):251–276, 1998.

N. N. Čencov. Statistical Decision Rules and Optimal Inference. American Mathematical Society, Providence, RI, 1982.

17

A PREPRINT - J UNE 19, 2026

P. Chaudhari, A. Choromanska, S. Soatto, Y. LeCun, C. Baldassi, C. Borgs, J. Chayes, L. Sagun, and R. Zecchina. Entropy-SGD: Biasing gradient descent into wide valleys. In Proceedings of the International Conference on Learning Representations (ICLR), 2017. L. Dinh, R. Pascanu, S. Bengio, and Y. Bengio. Sharp minima can generalize for deep nets. In Proceedings of the International Conference on Machine Learning (ICML), 2017. G. K. Dziugaite and D. M. Roy. Computing nonvacuous generalization bounds for deep (stochastic) neural networks with many parameters. In Proceedings of the Conference on Uncertainty in Artificial Intelligence (UAI), 2017. P. Foret, A. Kleiner, H. Mobahi, and B. Neyshabur. Sharpness-aware minimization for efficiently improving generaliza- tion. In Proceedings of the International Conference on Learning Representations (ICLR), 2021. S. Hochreiter and J. Schmidhuber. Flat minima. Neural Computation, 9(1):1–42, 1997. C. Jang, S. Lee, F. C. Park, and Y.-K. Noh. A reparametrization-invariant sharpness measure based on information geometry. In Advances in Neural Information Processing Systems (NeurIPS), 2022. N. S. Keskar, D. Mudigere, J. Nocedal, M. Smelyanskiy, and P. T. P. Tang. On large-batch training for deep learning: Generalization gap and sharp minima. In Proceedings of the International Conference on Learning Representations (ICLR), 2017. A. Kristiadi, F. Dangel, and P. Hennig. The geometry of neural nets’ parameter spaces under reparametrization. In Advances in Neural Information Processing Systems (NeurIPS), 2023. Frederik Kunstner, Lukas Balles, and Philipp Hennig. Limitations of the empirical Fisher approximation for natural gradient descent. In Advances in Neural Information Processing Systems, volume 32, pages 4156–4167. Curran Associates, Inc., 2019. Q. Li, C. Tai, and W. E. Stochastic modified equations and adaptive stochastic gradient algorithms. In Proceedings of the International Conference on Machine Learning (ICML), 2017. J. Martens and R. Grosse. Optimizing neural networks with Kronecker-factored approximate curvature. In Proceedings of the International Conference on Machine Learning (ICML), 2015. D. A. McAllester. PAC-Bayesian model averaging. In Proceedings of the Conference on Computational Learning Theory (COLT), 1999. R. Mulayoff and T. Michaeli. Unique properties of flat minima in deep networks. In Proceedings of the International Conference on Machine Learning (ICML), 2020. M. S. Nacson, K. Ravikumar, N. Srebro, and D. Soudry. Implicit bias of SGD for diagonal linear networks: A provable benefit of stochasticity. In Advances in Neural Information Processing Systems (NeurIPS), 2022. B. Neyshabur, S. Bhojanapalli, D. McAllester, and N. Srebro. Exploring generalization in deep learning. In Advances in Neural Information Processing Systems (NeurIPS), pages 5949–5958, 2017. Razvan Pascanu and Yoshua Bengio. Revisiting natural gradient for deep networks. In International Conference on Learning Representations, 2014. A. G. Wilson and P. Izmailov. Bayesian deep learning and a probabilistic perspective of generalization. In Advances in Neural Information Processing Systems (NeurIPS), 2020.

18

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
