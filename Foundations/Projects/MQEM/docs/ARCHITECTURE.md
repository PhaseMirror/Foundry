# M³EM / MQEM Architecture Specification
### Modular Multiplicative Ecosystem Model (M³EM)

---

## 1. System Philosophy & Layer Separation

The **Modular Multiplicative Ecosystem Model (M³EM)** enforces strict architectural separation between three primary concerns:

```mermaid
graph TD
    subgraph Layer 1: Core Ecological Dynamics
        G[Habitat Graph G = (V, E)]
        Tau[Ring Buffer Delay tau]
        LV[Ecological Drift F(x, u)]
        Disp[Dispersal Coupling Matrix A]
        Noise[Stochastic Forcing Sigma xi]
        Core[x_v(t+1) = x_v + dt(F + Dispersal) + Noise]
        G --> Core
        Tau --> Core
        LV --> Core
        Disp --> Core
        Noise --> Core
    end

    subgraph Layer 2: Observation & Likelihood
        Core --> LatentX[Latent Ecological State x_v(t)]
        LatentX --> ObsOp[Observation Operator h(x)]
        ObsOp --> Bern[Bernoulli Presence/Absence]
        ObsOp --> NegBin[Negative Binomial Counts]
        ObsOp --> Gauss[Continuous Gaussian Index]
    end

    subgraph Layer 3: Complexity & Spectral Metrics
        G --> Lap[Laplacian L = D - A]
        Lap --> Fiedler[Algebraic Connectivity lambda_2(L)]
        Lap --> Mod[Modularity & Clustering C(t)]
    end

    subgraph Layer 4: External Management Optimization
        Core -.-> J[Objective Functional J(x, u)]
        J --> SA[Classical Simulated Annealing]
        J --> QAOA[QUBO / QAOA Quantum Combinatorial Solver]
        SA --> u[Intervention u_v(t)]
        QAOA --> u
        u -.-> Core
    end
```

---

## 2. Core Architectural Components

### 2.1 State-Space Dynamics Engine (`rust/src/dynamics.rs`)
- Manages an augmented state ring buffer $X_v(t) = [x_v(t)^\top, x_v(t-1)^\top, \dots, x_v(t-\tau)^\top]^\top$.
- Computes internal growth drift $F(x, u)$ (Lotka-Volterra logistic dynamics) and spatial dispersal flux:
  $$\sum_{w \in N(v)} a_{vw}(x_w(t-\tau) - x_v(t))$$
- Guarantees positivity preservation ($x_v(t) \ge 0$).

### 2.2 Observation Operators (`rust/src/observation.rs`)
- Connects latent continuous biomass/occupancy states to real field data:
  - **Occupancy:** Bernoulli presence/absence with detection probability $p_{\text{det}}$.
  - **Count Data:** Poisson / Negative Binomial counts with overdispersion.
  - **Continuous Telemetry:** Gaussian measurement error $y = h(x) + \varepsilon$.

### 2.3 Spectral Connectivity Analyzer (`rust/src/laplacian.rs`)
- Evaluates the unnormalized graph Laplacian $L = D - A$.
- Computes the Fiedler eigenvalue $\lambda_2(L)$ via shifted inverse power iteration and consensus mode deflation.

### 2.4 Sequential Monte Carlo Inference (`rust/src/inference.rs`)
- Executes Particle Filtering over longitudinal time-series data to compute unbiased marginal log-likelihoods:
  $$\ln p(y_{1:T} \mid \Theta) = \sum_{t=1}^T \ln\left(\frac{1}{P}\sum_{i=1}^P w_t^{(i)}\right)$$

### 2.5 Combinatorial Optimization Solvers (`rust/src/optimization.rs`)
- Solves reserve network design and corridor allocation problems.
- Formulates QUBO Hamiltonian matrices $Q$ for external classical/quantum solvers (QAOA), ensuring optimization remains an external tool rather than an internal biological mechanism.
