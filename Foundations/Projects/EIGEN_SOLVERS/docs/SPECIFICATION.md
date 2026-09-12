# Prime-Encoded Eigen Solvers: Categorical Prime Flows Specification

## 1. Mathematical Backbone

### 1.1 Prime-Encoded Eigenvalue Decomposition (PEED)
For an $n \times n$ Hermitian matrix $A$:
$$P(A) = \sum_{p \in \mathbb{P}_A} \alpha_p\, p\, A_p$$
where $\mathbb{P}_A \subset \mathbb{P}$ is a finite set of distinct primes, $\alpha_p \in \mathbb{R}$, and $A_p$ are interaction operators.

Eigenvalues are represented as prime products:
$$\lambda_i = \prod_{j} p_j^{e_{ij}}, \quad e_{ij} \in \mathbb{Z}$$

### 1.2 Prime-Weighted Lanczos Recurrence
Given starting vector $v_1$ ($||v_1|| = 1$), the recurrence constructs the Krylov subspace $K_m(A, v_1) = \mathrm{span}\{v_1, A v_1, \dots, A^{m-1} v_1\}$:
$$w_1 = A v_1, \quad \alpha_1 = v_1^* w_1$$
$$w_{k+1} = A v_k - \alpha_k v_k - \beta_k v_{k-1}$$
$$\beta_k = ||w_k||\, p_k, \quad \alpha_k = v_k^* A v_k$$

The induced tridiagonal matrix $T_m$ is:
$$T_m = \begin{pmatrix}
\alpha_1 & \beta_1 p_1 & 0 & \dots & 0 \\
\beta_1 p_1 & \alpha_2 & \beta_2 p_2 & \dots & 0 \\
0 & \beta_2 p_2 & \alpha_3 & \dots & 0 \\
\vdots & \vdots & \vdots & \ddots & \beta_{m-1} p_{m-1} \\
0 & 0 & 0 & \beta_{m-1} p_{m-1} & \alpha_m
\end{pmatrix}$$

---

## 2. Category Theory of Prime-Labelled Krylov Modules ($\mathbf{PrimeMod}_A$)

- **Objects:** $M_m = (\mathcal{C}_m, \mathcal{L}, \tau_m)$ where $\mathcal{C}_m \subseteq \mathcal{H}$, $\mathcal{L} = \bigoplus_{p \in \mathbb{P}_A} \mathbb{R} e_p$, and $\tau_m : \mathcal{L} \otimes \mathcal{C}_m \to \mathcal{H}$ with $\tau(e_p \otimes v) = A_p v$.
- **Morphisms:** Pairs $(\phi_{\mathcal{C}}, \phi_{\mathcal{L}})$ such that $\tau_2 \circ (\phi_{\mathcal{L}} \otimes \phi_{\mathcal{C}}) = \tau_1$.
- **Prime-Weighted Lanczos Functor:** $\mathcal{F}_{\vec{p}} : M_m \mapsto M_{m+1}$.
- **Natural Transformation:** Canonical inclusion $\iota : \mathrm{Id}_{\mathbf{PrimeMod}_A} \Rightarrow \mathcal{F}_{\vec{p}}$.

### Spectral Invariants as Functors:
1. **Trace Functor:** $\mathrm{Tr}(M_m) = \sum_{k=1}^m \alpha_k$. Under $\iota$: $\mathrm{Tr}(\mathcal{F}_{\vec{p}}(M_m)) = \mathrm{Tr}(M_m) + \alpha_{m+1}$.
2. **Prime-Weighted Off-Diagonal Energy:** $E(M_m) = \sum_{k=1}^{m-1} (\beta_k p_k)^2$. Monotonicity: $E(\mathcal{F}_{\vec{p}}(M_m)) = E(M_m) + (\beta_m p_m)^2 \ge E(M_m)$.
3. **Scale-Free Coupling Ratios:** $r_k = \frac{\beta_k p_k}{\beta_{k-1} p_{k-1}}$ ($k = 2, \dots, m$). Invariant under uniform prime-similarities.
4. **Prime-Exponent Signature:** $s_m = \sum_{k=1}^{m-1} \log_{p_k} |\beta_k p_k|$.

---

## 3. Category Theory of Prime-Tensor Modules ($\mathbf{PrimeTen}_A$)

- **Objects:** $N = (\mathcal{E}, \mathcal{I}, \Theta)$ where $\mathcal{E}$ is an eigenspace, $\mathcal{I}$ is the prime Hilbert space with basis $\{|p\rangle\}$, and $\Theta(|p_i\rangle \otimes |e_i\rangle) = \lambda_i |e_i\rangle$.
- **Tensor State:** $\Psi(t) = \sum_i \lambda_i |p_i\rangle \otimes |e_i\rangle$.
- **Quantum Evolution Functor:** $\mathcal{Q}(N) = (\mathcal{E}, \mathcal{I}, \Theta_U)$ where $U = e^{iAt}$.
- **Phase Estimation Functor:** $\mathcal{P} : \mathbf{PrimeTen}_A \to \mathbf{QCirc}$ producing probabilities $P(p_i) = |\lambda_i|^2 / ||\Psi||^2$.
- **Observable Expectation Functor:** $\mathbb{E}_{\mathcal{O}}(N) = \langle \Psi(t) | \mathcal{O} | \Psi(t) \rangle$.

---

## 4. Verification & Bounds

1. **Spectral Norm Bound:** $||T_m||_2 \le ||A||_2$.
2. **Gershgorin Disk Bound:** $\max_{\theta \in \sigma(T_m)} |\theta| \le \max_k (|\alpha_k| + |\beta_{k-1} p_{k-1}| + |\beta_k p_k|)$.
3. **Residual Norm Formula:** $||r_j^{(m)}||_2 = |\beta_m p_m|\, |e_m^T y_j|$.
4. **A Priori Ritz Bound:** $\lambda_1 - \theta_1^{(m)} \le |\beta_m p_m|\, |e_m^T y_1|$.
