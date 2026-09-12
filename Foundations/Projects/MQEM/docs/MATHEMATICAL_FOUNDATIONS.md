# M³EM / MQEM Mathematical Foundations & Formal Proofs

This document details the mathematical theorems, derivations, and machine-checked Lean 4 formalizations underpinning the Modular Multiplicative Ecosystem Model (M³EM).

---

## 1. Theorem 1: Mean-Square Boundedness of Delayed State-Space Recursion

### Statement
Let $X(t) \in \mathbb{R}^{n \cdot d \cdot (\tau + 1)}$ denote the augmented network state vector. Under global Lipschitz drift constant $L_F$, bounded coupling matrix norm $\|A\|$, and bounded noise covariance $\text{tr}(\Sigma \Sigma^\top) \le c_2$, if:
$$\Delta t (L_F + \|A\|) \le c_1$$
then the augmented stochastic process is uniformly bounded in second moment:
$$\sup_{t \ge 0} \mathbb{E}\left[ \|X(t)\|^2 \right] < \infty$$

### Proof Structure (Lean 4 Formalization: `lean/MQEM/Boundedness.lean`)
1. Construct quadratic Lyapunov candidate $V(X(t)) = X(t)^\top P X(t)$ with block-diagonal weighting over delay history.
2. Apply drift difference inequality:
   $$\mathbb{E}[V(X(t+1)) \mid X(t)] - V(X(t)) \le -\alpha \|X(t)\|^2 + \beta \text{tr}(\Sigma\Sigma^\top)$$
3. Lipschitz continuity of $F$ and bounded coupling ensure $\alpha > 0$ whenever $\Delta t(L_F + \|A\|) \le c_1$.
4. By discrete Gronwall/Dynkin lemma, $\mathbb{E}[\|X(t)\|^2] \le \gamma_0 \|X(0)\|^2 e^{-\alpha t} + \frac{\beta c_2}{\alpha} < \infty$.

---

## 2. Proposition 2: Algebraic Connectivity Controls Perturbation Decay

### Statement
Consider linearized coupled error dynamics around an equilibrium $x^*$:
$$\delta x(t+1) = \left( I + \Delta t J - \Delta t \alpha L \right) \delta x(t)$$
where $J$ is the local Jacobian and $L = D - A$ is the graph Laplacian. For perturbations $\delta x$ orthogonal to the consensus mode $\mathbf{1}$:
$$\|\delta x(t+1)\| \le \left( 1 - \Delta t \mu_{\min}(J) - \Delta t \alpha \lambda_2(L) \right) \|\delta x(t)\|$$
Increasing the algebraic connectivity (Fiedler value $\lambda_2(L)$) strictly increases the worst-case exponential decay rate.

### Proof Structure (Lean 4 Formalization: `lean/MQEM/Perturbation.lean`)
1. Decompose $\delta x$ into the eigenbasis of $L$: $0 = \lambda_1 < \lambda_2 \le \dots \le \lambda_n$.
2. Orthogonality to $\mathbf{1}$ eliminates $\lambda_1$.
3. The slowest decaying non-consensus mode corresponds to $\lambda_2$.
4. Hence, contraction factor is monotonically decreasing in $\alpha \lambda_2(L)$.

---

## 3. Mass Conservation under Pure Diffusion

### Statement
In the absence of local growth ($F = 0$) and noise ($\Sigma = 0$), symmetric dispersal coupling preserves total network biomass:
$$\sum_{v \in V} x_v(t+1) = \sum_{v \in V} x_v(t)$$

### Proof Structure (Lean 4 Formalization: `lean/MQEM/Conservation.lean`)
$$\sum_{v} \sum_{w \in N(v)} a_{vw}(x_w - x_v) = \frac{1}{2} \sum_{v, w} (a_{vw} - a_{wv})(x_w - x_v) = 0 \quad (\text{since } a_{vw} = a_{wv})$$
