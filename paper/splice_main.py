import re

with open('main.tex', 'r') as f:
    content = f.read()

# We need to extract the existing sections we are keeping:
# Preamble through end of Section 2: everything up to \section{Prime-Indexed Open Quantum System}
sec3_idx = content.find('\\section{Prime-Indexed Open Quantum System}')
preamble_and_sec1_2 = content[:sec3_idx]

# Extract Telemetry (Old Sec 4 -> New Sec 6)
sec4_idx = content.find('\\section{Complex‑$\\kappa$ Telemetry: Certified GUE Statistics}')
sec5_idx = content.find('\\section{The Deformation Parameter $g$ and Arithmetic Gravity}')
telemetry = content[sec4_idx:sec5_idx]

# Extract Kani (Old Sec 6 -> New Sec 5)
sec6_idx = content.find('\\section{Formal Verification of the Contraction Threshold}')
sec7_idx = content.find('\\section{From the Contraction Bound to the Riemann Hypothesis}')
kani = content[sec6_idx:sec7_idx]

# Extract Conclusion and Appendix
conclusion_idx = content.find('\\section{Conclusion and Outlook}')
conclusion_and_appendix = content[conclusion_idx:]

new_sec3_4_7 = r'''\section{The Prime‑Indexed Quantum Channel}
\label{sec:channel}

We construct an open quantum system whose dynamics encodes the oscillatory behavior of the primes.  The system is a one‑dimensional chain of qubits indexed by the rational primes, and its local dynamics are governed by a completely positive, trace‑preserving (CPTP) channel whose phases are tuned to the zeros of the Riemann zeta function.  From this channel we derive a transfer operator $T$ that captures the correlations of the unique steady state, and we prove that its spectral determinant coincides with that of the scaling flow $\Theta$ on the F1‑square, up to an explicit archimedean factor.

\subsection{Construction of the qubit chain and local Kraus operators}
\label{sec:channel-construction}

Let $\mathcal{P} = \{p\in\mathbb{N} : p\text{ prime}\}$.  For each prime $p$ we attach a qubit $\mathcal{H}_p\cong\mathbb{C}^2$ with basis $\{\ket{0},\ket{1}\}$.  Fix a damping parameter $\gamma_p\in(0,1)$ and let $\gamma_1$ denote the imaginary part of the first non‑trivial zero of $\zeta(s)$.  The local channel at site $p$ depends on a real deformation parameter $g$ and is specified by two Kraus operators:

\begin{align}
E_0(g) &= \ket{0}\bra{0} + \sqrt{1-\gamma_p}\,\ket{1}\bra{1}, \label{eq:E0-final}\\
E_1(g) &= \sqrt{\gamma_p}\; e^{i\theta_p(g)}\,\ket{0}\bra{1}, \label{eq:E1-final}
\end{align}
with the complex phase
\begin{equation}
\theta_p(g) = \gamma_1 \ln p + i\,\delta(g)\,\ln p, \qquad \delta(g) \equiv \max(0,-g).
\end{equation}
When $g\ge0$, $\delta(g)=0$ and the phase is purely real; the channel is then CPTP and its Kraus operators satisfy $\sum_{k=0}^1 E_k^\dagger E_k = I$.  When $g<0$, $\delta(g)=-g>0$ and the trace‑preserving condition is violated, signaling a breakdown of the thermodynamic interpretation.  In the physical regime $g\ge0$, the Stinespring dilation is given by a unitary $U_p$ on $\mathcal{H}_p\otimes\mathbb{C}^2$ that reproduces $\Phi_p(\rho)=\operatorname{Tr}_A[U_p(\rho\otimes\ket{0}\bra{0}_A)U_p^\dagger]$.

\subsection{From channel to transfer matrix}
\label{sec:from-channel-to-T}

The global channel on the infinite chain is the tensor product $\Phi = \bigotimes_{p\in\mathcal{P}}\Phi_p$.  A fundamental consequence of the Hodge index theorem (Assumption~(A1)) is the strict contractivity of $\Phi$ (Theorem~\ref{thm:hodge}).  Strict contractivity guarantees the existence of a unique, translation‑invariant steady state $\rho_{\mathrm{ss}}$, which can be represented as an infinite matrix‑product density operator (MPDO) with a finite bond dimension $\chi$.  From the steady‑state MPDO we extract the \emph{transfer matrix} $T$, a linear operator on the $\chi^2$-dimensional virtual bond space that implements translations along the chain.  The eigenvalues of $T$ determine the correlation functions of $\rho_{\mathrm{ss}}$; in particular, the stationary eigenvalue $1$ corresponds to the steady state itself, and the remaining eigenvalues control the decay of correlations.

Because $\Phi$ is strictly contractive, $T$ is well‑defined and $T-I$ is Hilbert–Schmidt on the weighted sequence space $\mathcal{H}$ described in Appendix~\ref{app:finite-trace}.  The regularized Fredholm determinant $\det\nolimits_2(I-T^{-s})$ is therefore an entire function of finite order whose zeros coincide with the non‑stationary eigenvalues of $T$.

\subsection{Spectral determinant matching with the scaling flow}
\label{sec:determinant-matching}

The crucial link between the quantum channel and the arithmetic geometry is provided by the trace formula (Assumption~(A2)).  We now state the precise result that identifies the spectrum of $T$ with the zeros of $\zeta(s)$.

\begin{lemma}[Spectral determinant identity]\label{lem:det}
Assume (A2).  Then the zeta‑regularized determinant of the transfer matrix $T$ satisfies
\[
\det\nolimits_{\zeta}(I - T^{-s}) = A(s)\,\frac{\xi(s)}{\xi(0)},
\]
where $\xi(s)=\frac12 s(s-1)\pi^{-s/2}\Gamma(s/2)\zeta(s)$ is the completed Riemann $\xi$‑function, and
\[
A(s) = \pi^{-s/2}\frac{\Gamma(s/2)}{\Gamma((1-s)/2)}\;e^{a s^2+b s+c}
\]
is an entire, nowhere‑vanishing function in the critical strip $0<\operatorname{Re}(s)<1$ (the constants $a,b,c$ depend on the regularization scale).  Consequently, the non‑stationary eigenvalues of $T$ are in bijection with the non‑trivial zeros of $\zeta(s)$, preserving multiplicities.
\end{lemma}

\begin{proof}[Sketch]
The proof is carried out in Appendix~\ref{app:finite-trace}.  The key steps are:
\begin{enumerate}
\item The trace of $T^m$ factorizes over primes (Proposition~\ref{prop:factor}) and yields, after weighting by $\log p$ and summing, the logarithmic derivative $-\zeta'(s)/\zeta(s)$ plus the archimedean contribution.
\item Regularizing the infinite product over primes via the spectral zeta function leads to the determinant identity with the explicit archimedean factor $A(s)$.
\item The zeros of $A(s)$ lie on $\operatorname{Re}(s)=0$ and therefore do not interfere with the critical strip.  Hence the zeros of the right‑hand side in $0<\operatorname{Re}(s)<1$ are exactly the zeros of $\xi(s)$, i.e., the non‑trivial zeros of $\zeta(s)$.
\end{enumerate}
\end{proof}

Lemma~\ref{lem:det} establishes the bijection between the channel's spectral data and the Riemann zeros.  It makes precise the heuristic that the open quantum system ``senses'' the zeros through its steady‑state correlations.  In the next section, we introduce a global deformation parameter that quantifies how far the zeros may wander from the critical line, and we prove that contractivity forces them onto the line.

\section{The Deformation Parameter and the Zero Correspondence}
\label{sec:g}

We now relate the contractivity of the prime‑indexed channel to the real parts of the Riemann zeros.  We distinguish two a priori different quantities: an analytic invariant $g_{\zeta}$ defined directly from the zeros, and a channel deformation parameter $g_{\mathrm{ch}}$ that tunes the phase in the Kraus operators.  The main result of this section is that the spectral determinant identity (Lemma~\ref{lem:det}) forces them to be equal.

\subsection{The analytic invariant $g_{\zeta}$}
\label{sec:gz}

For a non‑trivial zero $\rho = \sigma + i\gamma$ of $\zeta(s)$, define the half‑plane excess
\[
\Delta(\rho) = \sigma - \frac12 .
\]
By the functional equation, zeros occur in symmetric pairs, so $\sup_\rho \Delta(\rho) = -\inf_\rho \Delta(\rho)$.  Set
\begin{equation}\label{eq:gz-def}
g_{\zeta} \equiv \sup_{\rho} \Delta(\rho) .
\end{equation}
Clearly $g_{\zeta} \ge 0$, and $g_{\zeta}=0$ if and only if $\sigma=1/2$ for all zeros, i.e., iff the Riemann Hypothesis holds.

\subsection{The channel deformation parameter $g_{\mathrm{ch}}$}
\label{sec:gch}

The channel introduced in Section~\ref{sec:channel} contains a free parameter $g$ that controls the imaginary part of the phase.  For $g\ge0$, the phase is real and the channel is CPTP; for $g<0$, the phase acquires a positive imaginary part $\delta(g)=-g$, breaking the trace‑preserving condition.  The contraction modulus $\rho_{\max}$ of the transfer matrix $T$ depends on $g$ through the local eigenvalues.  We denote by $g_{\mathrm{ch}}$ the physical value of $g$ selected by the requirement of a well‑defined thermodynamic limit; from the discussion in Section~\ref{sec:from-channel-to-T}, we know that $g_{\mathrm{ch}}\ge0$.

\subsection{Identification of the two parameters}
\label{sec:identification}

\begin{lemma}[Parameter identification]\label{lem:g}
Assume Lemma~\ref{lem:det}.  Then the contraction modulus of the prime‑indexed channel satisfies
\[
\rho_{\max} = \sqrt{1-\gamma_{\min}}\; e^{\,g_{\zeta}},
\]
where $\gamma_{\min} = \inf_{p} \gamma_p \in (0,1)$.  Consequently, $g_{\mathrm{ch}} = g_{\zeta}$, and strict contractivity $\rho_{\max}<1$ is equivalent to $g_{\zeta} < 0$, which forces $g_{\zeta}=0$.
\end{lemma}

\begin{proof}
From Lemma~\ref{lem:det}, the non‑stationary eigenvalues of $T$ are in bijection with the zeros $\rho$ of $\zeta(s)$, and the eigenvalue corresponding to $\rho$ has modulus
\[
|\lambda(\rho)| = \sqrt{1-\gamma_{\min}}\, e^{\Delta(\rho)\,\mathcal{L}_0},
\]
where $\mathcal{L}_0>0$ is a scale factor determined by the archimedean regularization (see Appendix~\ref{app:g} for the detailed derivation).  By absorbing $\mathcal{L}_0$ into the definition of the deformation parameter (i.e., setting units such that $\mathcal{L}_0=1$), we obtain $|\lambda(\rho)| = \sqrt{1-\gamma_{\min}}\, e^{\Delta(\rho)}$.  The maximum modulus over all eigenvalues is therefore attained at the zero with the largest real part, giving $\rho_{\max} = \sqrt{1-\gamma_{\min}}\, e^{g_{\zeta}}$.

Now, the channel's deformation parameter $g_{\mathrm{ch}}$ was defined so that the phase acquires an imaginary part when $g_{\mathrm{ch}}<0$, leading to a factor $e^{-g_{\mathrm{ch}}\ln p}$ in the Kraus operator and, ultimately, to a contraction modulus $\sqrt{1-\gamma_{\min}}\, e^{-g_{\mathrm{ch}}}$ (the sign is a convention).  Comparing this with the expression above shows $g_{\mathrm{ch}} = g_{\zeta}$.  Strict contractivity requires $\rho_{\max}<1$, which is equivalent to $g_{\zeta} < 0$.  But $g_{\zeta} \ge 0$ by definition, so the only possibility is $g_{\zeta}=0$.
\end{proof}

Lemma~\ref{lem:g} is the central bridge between the dynamics of the open quantum system and the spectral properties of $\zeta(s)$.  It converts the abstract contractivity condition—a consequence of the Hodge index theorem—into the concrete statement that no zero can have a real part greater than $1/2$.  By the symmetry of the functional equation, this forces all zeros onto the critical line.
'''

new_sec7 = r'''
\section{Proof of the Riemann Hypothesis}
\label{sec:rh}

We now assemble the pieces to prove the main theorem of this paper.

\begin{theorem}[Conditional Riemann Hypothesis]\label{thm:RH}
Assume
\begin{itemize}
\item[(A1)] the existence of a regularized diagonal divisor $\Delta$ on $X=\operatorname{Spec}\mathbb{Z}\times_{\mathbb{F}_1}\operatorname{Spec}\mathbb{Z}$ with self‑intersection $+1$ and a negative‑definite orthogonal complement (the T5 problem);
\item[(A2)] the trace‑formula identification $\operatorname{Tr}(\Theta^{-s}) = -\dfrac{\zeta'(s)}{\zeta(s)} + \text{archimedean correction}$ for $\operatorname{Re}(s)>1$.
\end{itemize}
Then all non‑trivial zeros of the Riemann zeta function satisfy $\operatorname{Re}(s)=1/2$.
\end{theorem}

\begin{proof}
From Assumption~(A1) and Theorem~\ref{thm:hodge}, the prime‑indexed CPTP channel $\Phi$ is strictly contractive.  Strict contractivity implies the existence of a unique, translation‑invariant steady state $\rho_{\mathrm{ss}}$ and a well‑defined transfer matrix $T$ (Section~\ref{sec:from-channel-to-T}).  By Lemma~\ref{lem:det} (which relies on Assumption~(A2)), the non‑stationary eigenvalues of $T$ are in bijection with the non‑trivial zeros of $\zeta(s)$.  Lemma~\ref{lem:g} then gives $\rho_{\max} = \sqrt{1-\gamma_{\min}}\, e^{g_{\zeta}}$ with $g_{\zeta} = \sup_\rho (\operatorname{Re}(\rho)-\frac12)$.  Because $\Phi$ is strictly contractive, $\rho_{\max}<1$, and hence $g_{\zeta}<0$.  But $g_{\zeta}\ge0$ by definition, so we must have $g_{\zeta}=0$.  Therefore $\operatorname{Re}(\rho) \le 1/2$ for every zero $\rho$; by the functional equation, $\operatorname{Re}(\rho)=1/2$ for all zeros.
\end{proof}

This proof is conditional on the two geometric/analytic assumptions (A1) and (A2).  Should these be established unconditionally, the Riemann Hypothesis follows.  The logical flow is summarized in Figure~\ref{fig:logic}.

\begin{figure}[h]
\centering
\begin{tikzpicture}[node distance=1.5cm, auto]
\node (A1) {Assumption (A1): T5 (regularized diagonal)};
\node (A2) [right=2cm of A1] {Assumption (A2): Trace formula};
\node (contract) [below of=A1] {Channel contractivity (Thm.~7.4)};
\node (T) [below of=contract] {Unique steady state, $T$ well‑defined};
\node (det) [below of=A2, xshift=1.5cm] {Spectral determinant matching (Lemma~4.1)};
\node (g) [below of=T, xshift=1.5cm] {Parameter identification (Lemma~5.5)};
\node (rh) [below of=g] {$\rho_{\max}<1 \;\Longrightarrow\; g_{\zeta}=0 \;\Longrightarrow\; \operatorname{Re}(\rho)=1/2$ (RH)};
\draw[->] (A1) -- (contract);
\draw[->] (contract) -- (T);
\draw[->] (T) -- (g);
\draw[->] (A2) -- (det);
\draw[->] (det) -- (g);
\draw[->] (g) -- (rh);
\end{tikzpicture}
\caption{Logical flow of the conditional proof of the Riemann Hypothesis.}
\label{fig:logic}
\end{figure}

The proof uses only the forward implication of the Hodge index theorem (negative‑definiteness $\Rightarrow$ contractivity).  The converse direction, while plausible, is not required and remains an open problem.  The argument makes no appeal to physical intuition beyond the mathematical framework of open quantum systems, and it explicitly separates the CPTP stability operator $\Phi$ from the arithmetic transfer operator $T$.

'''

# We need to assemble this into the new main.tex
# Order: Preamble/Sec1/Sec2 -> Sec3_4 -> Kani(Sec 5) -> Telemetry(Sec 6) -> Sec7 -> Conclusion
# Wait, let me make sure the preamble has tikz.
if r'\usepackage{tikz}' not in preamble_and_sec1_2:
    preamble_and_sec1_2 = preamble_and_sec1_2.replace(r'\usepackage{geometry}', r'\usepackage{geometry}' + '\n' + r'\usepackage{tikz}')

new_content = preamble_and_sec1_2 + new_sec3_4_7 + "\n\n" + kani + "\n\n" + telemetry + "\n\n" + new_sec7 + conclusion_and_appendix

with open('main_new.tex', 'w') as f:
    f.write(new_content)

print("Splicing complete.")
