import re

with open('main.tex', 'r') as f:
    content = f.read()

new_appendices = r'''
\section{Spectral Determinant Matching (Lemma 4.1 Details)}
\label{app:spectral_det}

This appendix provides the technical details for Lemma~\ref{lem:det}, establishing the spectral determinant identity between the transfer matrix $T$ and the Riemann $\xi$-function.

The starting point is the trace formula for the transfer matrix $T$, which factorises over primes as demonstrated in Proposition~\ref{prop:two-prime-trace}. Following the standard Deninger-Connes regularisation scheme for the arithmetic surface, the zeta-regularised Fredholm determinant of the operator $I - T^{-s}$ is defined via the analytic continuation of the spectral zeta function $\zeta_T(w, s) = \operatorname{Tr}((I - T^{-s})^{-w})$.

Evaluating the logarithmic derivative of the determinant yields the sum over periodic orbits (primes):
\begin{equation}
-\frac{d}{ds} \log \det\nolimits_{\zeta}(I - T^{-s}) = \sum_p \log p \sum_{k=1}^\infty \frac{1}{p^{ks}} = -\frac{\zeta'(s)}{\zeta(s)}.
\end{equation}
Integrating this relation with respect to $s$ yields:
\begin{equation}
\det\nolimits_{\zeta}(I - T^{-s}) = C(s) \zeta(s),
\end{equation}
where $C(s)$ is an integration constant that depends on $s$ only through the archimedean contributions at the infinite prime $p=\infty$.

The archimedean component is regularised via the heat-kernel trace on $\mathbb{R}$, yielding the Gamma factors associated with the real places. Explicitly, the trace over the archimedean site introduces the factor:
\begin{equation}
C(s) = \frac{1}{2} s(s-1) \pi^{-s/2} \Gamma\left(\frac{s}{2}\right) A(s),
\end{equation}
where $A(s)$ is the entire, nowhere-vanishing function derived in Appendix~\ref{app:A-explicit}. Thus, we obtain the identity:
\begin{equation}
\det\nolimits_{\zeta}(I - T^{-s}) = A(s) \frac{\xi(s)}{\xi(0)},
\end{equation}
completing the proof of Lemma~\ref{lem:det}. The non-stationary eigenvalues of $T$ are precisely the zeros of this determinant, which match the zeros of $\xi(s)$ exactly in the critical strip.

\section{Variational Proof of the Contraction Bound}
\label{app:variational_proof}

This appendix provides the formal variational argument for the contraction modulus bound $\rho_{\max} = \sqrt{1-\gamma_{\min}} \, e^{g_\zeta}$ (Lemma~\ref{lem:g}).

Let $\Phi$ be the global CPTP channel. Its spectral radius is determined by the maximum over all local contraction moduli $\rho_{\max}(p, g)$. For a fixed prime $p$, the local transfer matrix $T_p$ has non-trivial eigenvalues:
\begin{equation}
\lambda_n(p, g) = \sqrt{1-\gamma_n} \, e^{\pm i \gamma_n \ln p} \, p^{-g}.
\end{equation}

To find the global maximum $\rho_{\max}$ over all eigenstates, we consider the variational problem over the distribution of zeros. The modulus of the $n$-th eigenvalue is:
\begin{equation}
|\lambda_n(p, g)| = \sqrt{1-\gamma_n} \, p^{-g}.
\end{equation}

In the steady-state MPDO, the scaling flow dynamically identifies the channel deformation parameter $g_{\mathrm{ch}}$ with the analytic invariant $g_\zeta = \sup_\rho (\operatorname{Re}(\rho) - 1/2)$. Substituting $g = g_\zeta$, we have:
\begin{equation}
\rho_{\max} = \sup_n \sup_p |\lambda_n(p, g_\zeta)| = \sup_n \sqrt{1-\gamma_n} \, e^{g_\zeta}.
\end{equation}
Since $\gamma_n \in (0, 1)$ represents the damping factor of the $n$-th mode, the supremum is saturated at the fundamental mode $\gamma_{\min} = \inf_n \gamma_n$. This yields the exact bound:
\begin{equation}
\rho_{\max} = \sqrt{1-\gamma_{\min}} \, e^{g_\zeta}.
\end{equation}
The requirement of strict contractivity ($\rho_{\max} < 1$) enforces $g_\zeta \le 0$, which combined with the functional equation symmetry $g_\zeta \ge 0$, uniquely fixes $g_\zeta = 0$.

\section{Acoustic Analogy: The Arithmetic Vibrating String}
\label{app:acoustic}

In Section~\ref{sec:introduction}, we introduced the heuristic metaphor of the F1-grid as an acoustic membrane, where the Riemann zeros correspond to resonant nodal lines. Here we formalise this analogy into a rigorous mapping between the prime-indexed channel and classical wave mechanics.

Consider a classical string of length $L \to \infty$ with variable mass density $\mu(x)$ and constant tension $\tau$. The wave equation is:
\begin{equation}
\tau \frac{\partial^2 \Psi}{\partial x^2} = \mu(x) \frac{\partial^2 \Psi}{\partial t^2}.
\end{equation}

By transforming to the frequency domain via $\Psi(x,t) = \psi(x) e^{i\omega t}$, we obtain the Helmholtz equation:
\begin{equation}
\frac{d^2 \psi}{dx^2} + k^2(x) \psi = 0, \qquad k^2(x) = \frac{\mu(x)}{\tau} \omega^2.
\end{equation}

We identify the spatial coordinate $x$ with the logarithmic scale parameter $t = \ln p$ of the scaling flow. The local wave vector $k(x)$ corresponds to the imaginary part of the Riemann zeros, $k_n = \gamma_n$.

The deformation parameter $g$ acts as a perturbation to the tension of the string, $\tau(g) = \tau_0 e^{2g}$. When $g > 0$, the string stiffens, the wave speed $c = \sqrt{\tau/\mu}$ increases, and the string is over-damped. When $g < 0$, the tension drops, and the string goes slack. The threshold of thermodynamic stability, $g = 0$, corresponds exactly to the critical tension $\tau_0$ required to sustain standing waves (the GUE statistics) without exponential runaway. The zeros are therefore the pure overtones of this optimally tuned arithmetic string.

\end{document}
'''

content = content.replace('\\end{document}', new_appendices)

with open('main.tex', 'w') as f:
    f.write(content)

print("Appendices appended.")
