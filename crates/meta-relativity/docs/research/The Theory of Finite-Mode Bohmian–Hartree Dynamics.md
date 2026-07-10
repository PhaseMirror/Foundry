---
slug: the-theory-of-finite-mode-bohmian-hartree-dynamics
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: "04-domains/meta-relativity/The Theory of Finite-Mode Bohmian\u2013Hartree\
    \ Dynamics.md"
  last_synced: '2026-03-20T17:17:19.539754Z'
---

**The Theory of Finite-Mode Bohmian--Hartree Dynamics: A Technical Monograph**
==============================================================================

**1.0 Introduction: A Quantum-Classical Framework with Finite Memory**
----------------------------------------------------------------------

The finite-mode Bohmian-Hartree model represents a specialized yet
powerful framework for analyzing quantum systems that interact with a
limited set of classical degrees of freedom. It provides a
mathematically consistent description of a quantum wavefunction coupled
to a finite bank of harmonic oscillators, where the interaction is
mediated by nonlocal Hartree-type terms. This monograph systematically
deconstructs the model\'s mathematical structure, its physical
interpretation as a system with \"finite memory,\" and its theoretical
context within the broader landscape of quantum physics.

We will explore the complete dynamics of the system, which are derived
from a fundamental action principle. This derivation yields a coupled
Schrödinger-ODE system that governs the co-evolution of the quantum
wavefunction and the classical oscillator coordinates. A key feature of
this construction is the existence of a conserved total energy, which
serves as a crucial check on the physical consistency of the model.
Within this framework, we define Bohmian trajectories for the quantum
particle according to the standard guidance law, where the particle\'s
velocity is determined by the phase of the wavefunction. We will
establish that these trajectories are statistically consistent with the
predictions of quantum mechanics through the property of
\|Ψ\|²-equivariance, which ensures that an initial probability
distribution matching the quantum density is preserved over time.

Crucially, this model is not proposed as a fundamental modification of
quantum mechanics. Instead, its intended application is as an
*effective* quantum-classical closure. It is designed to approximate the
behavior of a quantum system interacting with a complex environment or a
feedback mechanism by representing those external influences with a
small, manageable set of classical modes. This monograph will detail the
theory\'s formulation, its analytical properties, and its place as a
well-posed and insightful tool for modeling specific physical regimes.

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**2.0 The Mathematical Formulation of the Dynamics**
----------------------------------------------------

A rigorous mathematical foundation is essential for any physical theory
to be predictive and internally consistent. This section establishes
that foundation for the finite-mode Bohmian-Hartree system. We will
begin by precisely defining the state space and its constituent
components. From there, we will introduce the fundamental action
principle from which the system\'s dynamics are derived. Applying the
principle of stationarity to this action yields the coupled equations of
motion that govern the system\'s evolution. Finally, we establish a
critical conservation law for the total energy, which confirms the
coherence of the resulting dynamical structure.

### **2.1 State Space and System Components**

The complete state of the system at any given time is specified by a
combination of quantum and classical variables, along with a set of
fixed physical parameters. These components are defined as follows:

-   **Quantum Component:** The state of the quantum particle is
    > described by a nonrelativistic wavefunction Ψ(x, t), a
    > complex-valued function on ℝᵈ × \[0, ∞) in d spatial dimensions (d
    > ∈ {1, 2, 3}). The wavefunction is normalized to unity, ∥Ψ(t)∥L² =
    > 1, and determines the quantum probability density ρ(x, t) = \|Ψ(x,
    > t)\|².

-   **Classical Components:** The classical part of the system consists
    > of a finite set of M harmonic oscillators. Their state is
    > described by:

    -   A set of real-valued coordinates qk(t), indexed by k ∈ I = {1,
        > \..., M}.

    -   A corresponding set of momenta πk(t) = q̇k(t).

-   **System Parameters:** The model is defined by a set of fixed
    > parameters:

    -   ωk \> 0: The natural frequencies of the classical oscillators.

    -   gk ∈ ℝ: A set of coupling constants that determine the strength
        > of the interaction between the quantum particle and each
        > classical mode.

    -   Kk(x): A set of even interaction kernels (Kk(x) = Kk(-x))
        > belonging to the space L¹(ℝᵈ). These kernels define the
        > spatial form of the nonlocal interaction.

-   **Hartree Functionals:** The interaction between the quantum and
    > classical components is quantified by a set of Hartree
    > functionals, Hk\[ρ\]. These functionals measure the interaction
    > energy associated with each mode k and are defined by the double
    > integral:

-   H\_k\[\\rho\] := \\frac{1}{2} \\int\_{\\mathbb{R}\^d}
    > \\int\_{\\mathbb{R}\^d} \\rho(x) K\_k(x-y) \\rho(y) \\,dx \\,dy

-   This double-integral form is characteristic of mean-field theories,
    > where each part of the quantum probability \"fluid\" ρ(x)
    > interacts with every other part ρ(y) via the kernel Kk(x-y).

### **2.2 The Action Principle**

The entire dynamics of the coupled system can be derived from a single
action integral, S. The equations of motion arise from the principle of
stationary action, which requires that the variation of S with respect
to the dynamical variables (Ψ, Ψ\*, and q) is zero. The action is given
by:

S\[\\Psi, \\bar{\\Psi}, q\] = \\int dt \\left( \\text{Re} \\langle\\Psi,
i\\hbar \\partial\_t\\Psi\\rangle - \\langle\\bar{\\Psi},
\\hat{H}\_0\\Psi\\rangle - \\sum\_{k \\in I} g\_k
q\_k(t)H\_k\[\\rho(\\cdot, t)\] + \\sum\_{k \\in I} \\left(\\frac{1}{2}
\\dot{q}\_k(t)\^2 - \\frac{1}{2} \\omega\_k\^2 q\_k(t)\^2 \\right)
\\right)

where ⟨f, g⟩ = ∫ℝᵈ f̄g dx denotes the standard L² inner product and Ĥ₀ =
- (ℏ²/2m)Δ + Vext(x) is the quantum Hamiltonian for a single particle
with external potential Vext. The integrand can be deconstructed into
four key parts:

1.  The quantum kinetic term (Re⟨Ψ, iℏ∂tΨ⟩).

2.  The quantum potential energy (⟨Ψ, Ĥ₀Ψ⟩).

3.  The central interaction term (∑ gk qk(t)Hk\[ρ\]), which couples the
    > classical coordinates qk to the quantum density ρ.

4.  The classical Lagrangian, containing the kinetic and potential
    > energies of the M oscillators.

### **2.3 The Coupled Equations of Motion**

Applying the principle of stationarity to the action S yields two sets
of coupled differential equations that define the time evolution of the
system.

-   **The Schrödinger Equation (S)** The evolution of the wavefunction Ψ
    > is governed by a mode-modulated Hartree equation:

-   i\\hbar \\partial\_t\\Psi = \\hat{H}\_0\\Psi + \\left(\\sum\_{k \\in
    > I} g\_k q\_k(t) (K\_k \* \\rho)(x, t) \\right) \\Psi, \\quad
    > \\text{where } \\rho = \|\\Psi\|\^2

-   This is a nonlinear Schrödinger equation where the nonlocal Hartree
    > potential, (Kk \* ρ), is multiplied by the time-dependent
    > classical coordinates qk(t). Each qk(t) acts as a time-dependent
    > **coupling coefficient** for the k-th component of the nonlinear
    > potential, directly influencing the quantum evolution.

-   **The Oscillator Equations (O)** The evolution of the classical
    > coordinates qk and momenta πk is governed by a set of driven
    > harmonic oscillator equations:

-   \\dot{q}\_k = \\pi\_k

-   \\dot{\\pi}\_k = -\\omega\_k\^2 q\_k - g\_k H\_k\[\\rho(\\cdot, t)\]

-   In this formulation, the quantum state acts back on the classical
    > system. The Hartree functional Hk\[ρ\] acts as a state-dependent
    > **driving force** or **source term** in the oscillator\'s equation
    > of motion. The system thus constitutes a feedback loop where the
    > quantum and classical components mutually influence each other\'s
    > evolution.

### **2.4 The Conserved Total Energy**

A fundamental property of this dynamical system is the conservation of
total energy. The total energy E(t) is the sum of the quantum energy,
the classical energy, and the interaction energy:

E(t) = \\int\_{\\mathbb{R}\^d} \\left( \\frac{\\hbar\^2}{2m}
\|\\nabla\\Psi\|\^2 + V\_{\\text{ext}}\|\\Psi\|\^2 \\right) dx +
\\sum\_{k \\in I} \\left(\\frac{1}{2} \\pi\_k\^2 + \\frac{1}{2}
\\omega\_k\^2 q\_k\^2 \\right) + \\sum\_{k \\in I} g\_k q\_k
H\_k\[\\rho\]

**Proposition 1 (Energy Conservation):** For sufficiently regular
solutions of the coupled equations (S)--(O), the total energy is
conserved, i.e., dE(t)/dt = 0.

The existence of this conservation law is a powerful indicator of the
internal consistency of the model. It provides a physical constraint
that any valid solution must satisfy and serves as an essential
diagnostic tool in numerical simulations. This completes the formal
description of the system\'s state evolution. The next section addresses
the motion of the particle itself within this evolving quantum-classical
landscape.

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**3.0 The Bohmian Framework: Trajectories and Equivariance**
------------------------------------------------------------

Having defined the evolution of the wavefunction Ψ and the classical
modes, the next logical step is to define the motion of the quantum
particle itself. In the de Broglie-Bohm interpretation of quantum
mechanics, the wavefunction does not just provide statistical
predictions; it actively guides the motion of a point particle along a
deterministic trajectory. The cornerstone of this interpretation\'s
consistency is the property of *equivariance*, which guarantees that the
statistical predictions derived from these trajectories align perfectly
with those of standard quantum mechanics.

### **3.1 The Guidance Law and Bohmian Trajectories**

The motion of the particle is dictated by a velocity field vΨ(x, t) that
is generated directly from the wavefunction Ψ. This velocity field is
defined in terms of the probability current j = (ℏ/m) Im(Ψ\*∇Ψ) and the
probability density ρ = \|Ψ\|²:

v\^\\Psi(x, t) = \\frac{j(x, t)}{\\rho(x, t)} = \\frac{\\hbar}{m}
\\text{Im} \\left( \\frac{\\nabla\\Psi}{\\Psi} \\right)(x, t)

This definition is valid at all points x where Ψ(x, t) ≠ 0. The Bohmian
trajectory, denoted Xt, is the integral curve of this velocity field. It
is the solution to the first-order ordinary differential equation known
as the **guidance equation**:

**(B)** \\quad \\dot{X}\_t = v\^\\Psi(X\_t, t)

This equation postulates a deterministic evolution for the particle\'s
position. The particle\'s velocity at any point in space and time is not
an independent variable but is completely determined by the local phase
of the quantum wavefunction. The particle is thus \"piloted\" by the
wave.

### **3.2 The Continuity Equation and Statistical Equivariance**

The mathematical link between the evolution of the probability density ρ
and the velocity field vΨ is the continuity equation.

**Proposition 2 (Continuity Equation):** If Ψ is a sufficiently regular
solution of the Schrödinger equation (S), then the following equation
holds: ∂tρ + ∇ · (ρvΨ) = 0.

This equation shows that the probability density ρ evolves as a
conserved fluid with a flow velocity vΨ. This fluid-like behavior is the
foundation for the central consistency result of Bohmian mechanics:
\|Ψ\|²-equivariance.

**Theorem 1 (\|Ψ\|²-equivariance):** Assume that for a time interval t ∈
\[0, T\], the velocity field vΨ(·, t) generates a measurable flow on ℝᵈ
\\ Zt, where Zt = {x : Ψ(x, t) = 0} is the set of the wavefunction\'s
nodes. Assume also that trajectories avoid these nodes. If the initial
position of the particle, X₀, is a random variable with probability
density ρ(·, 0) = \|Ψ(·, 0)\|², then the position at any later time, Xt,
will have the probability density ρ(·, t) = \|Ψ(·, t)\|².

The implication of this theorem is profound. It guarantees that if we
assume an initial state of \"quantum equilibrium\" where the particle
distribution matches the quantum probability density, this equilibrium
is preserved by the dynamics. Consequently, for any observable related
to position, the statistical predictions of the Bohmian model are
identical to those of standard quantum mechanics. Equivariance ensures
that the hidden trajectories, while deterministic, reproduce the
statistical results of the Born rule. Having established the conceptual
consistency of these trajectories, we must now address whether the
underlying equations that generate them are mathematically well-behaved.

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**4.0 Analytical Foundations: Well-Posedness of the System**
------------------------------------------------------------

For a physical theory to be predictive, its governing equations must be
well-posed. This mathematical property ensures that for a given set of
physically reasonable initial conditions, a unique solution exists, is
stable, and persists for some period of time. Well-posedness is a
prerequisite for the model to be computationally tractable and to make
unambiguous physical predictions. This section addresses the conditions
under which the finite-mode Bohmian-Hartree system meets this critical
requirement.

### **4.1 Mathematical Characterization**

The complete system, defined by equations (S) and (O), constitutes a
coupled partial differential equation-ordinary differential equation
(PDE-ODE) system. Its components can be characterized as follows:

-   The Schrödinger equation (S) is a **semilinear/nonlinear Schrödinger
    > equation** of the Hartree-type. Its nonlinearity arises from the
    > (Kk \* \|Ψ\|²)Ψ term, and it is distinguished by the presence of
    > time-dependent coefficients, qk(t), which modulate the strength of
    > this nonlinearity.

-   The oscillator equations (O) form a **smooth, finite-dimensional
    > ordinary differential equation system**. The driving force depends
    > on the solution of the PDE, but for any given wavefunction Ψ, the
    > equations for q and π are well-behaved.

### **4.2 Conditions for Local Existence and Uniqueness**

The existence of local-in-time solutions can be guaranteed under a set
of minimal, checkable hypotheses on the initial data and system
parameters.

**Assumption 1 (Baseline Regularity):**

-   The external potential is sufficiently smooth: Vext ∈ W²,∞(ℝᵈ).

-   The interaction kernels are integrable and even: Kk ∈ L¹(ℝᵈ).

-   The initial wavefunction is sufficiently regular: Ψ₀ ∈ H²(ℝᵈ) with
    > ∥Ψ₀∥L² = 1.

-   The initial classical state is well-defined: qk(0), πk(0) ∈ ℝ.

Under these standard conditions, the existence of a unique local
solution is guaranteed.

**Theorem 2 (Local Well-Posedness):** Under the baseline regularity
conditions of Assumption 1, there exists a time T \> 0 and a unique
solution to the coupled system (S)--(O) such that the wavefunction
exists in the space Ψ ∈ C(\[0, T\]; H²), and the classical trajectory
exists in (q, π) ∈ C¹(\[0, T\]; ℝ²M). Moreover, the L² norm of the
wavefunction is conserved for all t ∈ \[0, T\].

This theorem ensures that the model is well-defined and predictive, at
least for short times. The question of global well-posedness (whether
solutions exist for all t \> 0) is more complex and depends on more
specific properties of the system, such as the spatial dimension and the
functional class of the kernels. The broader mathematical literature on
Hartree-type equations provides numerous theorems establishing global
results under more restrictive conditions, while rigorous work has
established global existence for Bohmian trajectories in the linear case
for typical initial data \[6\].

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**5.0 Physical Interpretation and Theoretical Context**
-------------------------------------------------------

A model\'s utility is defined not only by its mathematical consistency
but also by its physical interpretation and its relationship to
established theories. A well-posed set of equations can represent
anything from a fundamental law of nature to a convenient approximation
for a specific physical regime. This section positions the finite-mode
Bohmian-Hartree system correctly as an effective model and evaluates its
scope and limitations in light of both theoretical principles and
experimental constraints.

### **5.1 An Effective Theory of Quantum-Classical Interaction**

The primary interpretation of this model is as an **effective theory**,
not a fundamental one. The finite bank of classical oscillators is not
intended to represent a true, fundamental classical sector of reality
coexisting with the quantum world. Instead, it serves as a simplified,
coarse-grained representation of a more complex quantum environment or a
classical feedback layer.

In this view, the oscillators provide a \"finite memory\" closure for an
open quantum system. The mechanism for this memory is direct: the
oscillator\'s equation of motion implies that its position qk(t) depends
on the integral of the force Hk\[ρ\] over past times, thereby encoding a
memory of the quantum state\'s history. This memory then feeds back into
the future evolution of Ψ. This makes the model suitable for describing
semiclassical feedback loops or systems where a few environmental modes
are dominant.

### **5.2 Relationship to Established Physical Models**

The structure of the finite-mode Bohmian-Hartree system bears a strong
resemblance to several well-known physical models, which helps to place
it in a broader context.

-   **Caldeira--Leggett Model:** This model is a cornerstone of open
    > quantum systems theory, describing a quantum system coupled to a
    > bath of infinitely many harmonic oscillators \[7\]. In the limit
    > where the number of modes M becomes very large and their
    > frequencies ωk and couplings gk are chosen according to a suitable
    > spectral density, the finite-mode model\'s feedback mechanism can
    > reproduce the dissipative and stochastic forces characteristic of
    > quantum Brownian motion, thereby providing a bridge between a
    > simple feedback system and a full thermal bath.

-   **Mean-Field and Hartree Models:** The nonlocal term (K \* ρ)Ψ is
    > structurally identical to that found in self-consistent field
    > theories like the Hartree equation, which are used to approximate
    > the behavior of many-body quantum systems. The finite-mode model
    > extends this structure by allowing the strength of the
    > self-interaction to be dynamically modulated.

-   **Schrödinger--Newton Equation:** This well-known equation is a
    > specific special case of the model \[9\]. It arises by setting
    > d=3, having a single mode (M=1), and choosing the kernel to be the
    > gravitational potential, K(x) = -Gm²/\|x\|.

-   **Electron--Phonon Coupling:** The model is conceptually analogous
    > to theories of polaron physics, where an electron moving through a
    > crystal lattice interacts with collective vibrational modes
    > (phonons) \[8\]. In this analogy, the oscillators qk represent the
    > phonon modes, which modulate the effective interactions
    > experienced by the electron.

### **5.3 Scope and Empirical Constraints on Nonlinearity**

If one were to propose this model as a fundamental replacement for
linear quantum mechanics, it would face severe empirical and theoretical
challenges. Any such nonlinear modification is strongly constrained.

-   **Experimental Tests:** Following the theoretical framework for
    > general nonlinear quantum theories developed by Weinberg \[1, 2\],
    > precision experimental tests were conducted to search for evidence
    > of such effects. The experiments, notably by Bollinger et al.
    > using trapped ion spectroscopy, yielded null results and placed
    > extremely tight bounds on the potential magnitude of any
    > fundamental nonlinearity \[3\].

-   **Theoretical Prohibitions:** Beyond experimental limits,
    > fundamental nonlinear modifications to the Schrödinger equation
    > are known to have profound theoretical consequences. As shown by
    > Polchinski \[4\] and through arguments of the Gisin type \[5\],
    > generic nonlinear evolutions, when combined with the principles of
    > quantum entanglement, can lead to unphysical phenomena such as the
    > ability to send signals faster than the speed of light.

These powerful constraints firmly place the finite-mode Bohmian-Hartree
model in the domain of effective, regime-specific descriptions. Its
value lies not in challenging quantum mechanics, but in providing a
consistent and computable tool for modeling complex quantum-classical
feedback systems where a full quantum description is intractable.

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**6.0 A Computable Example and Advanced Topics**
------------------------------------------------

To solidify the theoretical concepts discussed, it is useful to consider
a simplified, concrete instance of the model that is amenable to direct
numerical simulation. This allows for the exploration of the system\'s
dynamics in practice. Furthermore, we can briefly touch upon more
advanced theoretical considerations that arise when applying the Bohmian
framework to non-trivial configuration spaces.

### **6.1 A Minimal 1D Toy Model**

A minimal, computable version of the model can be constructed in one
spatial dimension (d=1) with a single classical mode (M=1). By choosing
a simple exponential kernel, K(x) = e⁻\|ˣ\|/ℓ where ℓ \> 0 is a
characteristic length scale, the full system reduces to a manageable set
of equations:

-   **Schrödinger Equation:**

-   i\\hbar\\Psi\_t = -\\frac{\\hbar\^2}{2m} \\Psi\_{xx} +
    > V\_{\\text{ext}}\\Psi + g q(t) (K \* \|\\Psi\|\^2)\\Psi

-   **Oscillator Equation:**

-   \\ddot{q} + \\omega\^2q = -g H\[\\rho\]

The corresponding **Bohmian trajectory equation** in 1D is given by:

\\dot{X}\_t = \\frac{\\hbar}{m}
\\text{Im}\\left(\\frac{\\Psi\_x}{\\Psi}\\right)(X\_t, t)

This \"toy model\" encapsulates all the essential features of the full
theory---quantum-classical feedback, nonlinearity, and Bohmian
guidance---in a form that is ideal for numerical investigation. A common
computational approach would be to use a split-step Fast Fourier
Transform (FFT) method to evolve the wavefunction Ψ, coupled with a
standard ODE integrator (like Runge-Kutta) to evolve the classical
coordinate q.

### **6.2 Topological Considerations in Configuration Space**

When the configuration space of the quantum particle is not simply
connected (for example, ℝ² with a region removed), the Bohmian velocity
field can exhibit interesting topological properties. For a closed loop
γ that does not pass through a node of the wavefunction, one can define
the **circulation** of the velocity field:

\\Gamma(t) = \\oint\_\\gamma v(\\cdot, t) \\cdot d\\ell

This quantity has two crucial properties:

1.  **Quantization:** The circulation is quantized in integer multiples
    > of 2πℏ/m.

2.  **Invariance:** This quantized value remains constant over time,
    > dΓ/dt = 0, as long as a node of the wavefunction does not cross
    > the loop γ.

The quantization of circulation is a direct consequence of the
mathematical structure of the velocity field and the single-valuedness
of the wavefunction. Writing the wavefunction in polar form, Ψ =
\|Ψ\|e\^(iS/ħ), gives the velocity field as v = ∇S/m. The requirement
that Ψ be single-valued means that the change in its phase S around any
closed loop must be an integer multiple of 2πħ. This directly implies
the quantization of ∮ v · dℓ.

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**7.0 Conclusion**
------------------

This monograph has detailed the complete mathematical and physical
structure of the finite-mode Bohmian-Hartree dynamics. We have shown
that the model is derived from a coherent action principle, leading to a
coupled system of equations for a quantum wavefunction and a finite set
of classical oscillators. This system respects a fundamental
conservation law for total energy, reinforcing its internal consistency.

Furthermore, we established that a Bohmian interpretation can be
consistently applied to this framework. The particle trajectories,
governed by the phase of the wavefunction, reproduce the statistical
predictions of the quantum density through the crucial property of
\|Ψ\|²-equivariance. The underlying equations of motion are
mathematically well-posed under standard regularity conditions, ensuring
the model is both predictive and suitable for numerical analysis.

Ultimately, the finite-mode Bohmian-Hartree system should be understood
not as a proposal for new fundamental physics, but as a well-posed,
computationally accessible, and physically insightful **effective
theory**. It provides a robust framework for modeling quantum systems
subject to feedback from a simplified, coarse-grained environment,
making it a valuable tool for studying complex quantum-classical
interactions with finite memory.

\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

**8.0 References**
------------------

\[1\] S. Weinberg, Testing quantum mechanics, Ann. Phys. 194 (1989).

\[2\] S. Weinberg, Precision tests of quantum mechanics, Phys. Rev.
Lett. 62, 485 (1989).

\[3\] J. J. Bollinger et al., Test of the linearity of quantum mechanics
by rf spectroscopy of trapped ions, Phys. Rev. Lett. 63, 1031 (1989).

\[4\] J. Polchinski, Weinberg's nonlinear quantum mechanics and the
Einstein--Podolsky--Rosen paradox, Phys. Rev. Lett. 66, 397 (1991).

\[5\] A. Bassi and K. Hejazi, No-faster-than-light-signaling implies
linear evolutions, arXiv:1411.1768.

\[6\] K. Berndl et al., Global existence and uniqueness of Bohmian
trajectories, arXiv:quant-ph/9509009.

\[7\] Caldeira--Leggett model, Scholarpedia.

\[8\] F. Giustino, Electron-phonon interactions from first principles,
Rev. Mod. Phys. 89, 015003 (2017).

\[9\] See e.g. discussion in Schrödinger--Newton equation as a possible
generator of quantum state reduction, arXiv:0803.4488.
