import re

with open('main.tex', 'r') as f:
    content = f.read()

abstract_text = r'''\begin{abstract}
We construct a dynamical realization of the scaling flow on the arithmetic surface $\operatorname{Spec}\mathbb{Z}\times_{\mathbb{F}_1}\operatorname{Spec}\mathbb{Z}$ (the F1-square) using a prime-indexed open quantum system. By tuning the Kraus operators of a completely positive, trace-preserving (CPTP) channel to the oscillatory behavior of the primes, we derive a transfer matrix whose spectral determinant formally matches that of the geometric scaling flow. We introduce a deformation parameter $g$ that controls the tension of this arithmetic membrane and prove via formal verification (Kani model-checker) that the channel remains strictly contractive if and only if $g \ge 0$. Furthermore, spectral determinant matching forces $g$ to equal the maximum real-part excess of the Riemann zeros. Consequently, if the global Hodge index theorem holds for the F1-square (the T5 regularized diagonal problem) and the trace formula is valid, then thermodynamic stability strictly forbids any zero from wandering off the critical line, conditionally proving the Riemann Hypothesis.
\end{abstract}'''

content = re.sub(r'\\begin\{abstract\}.*?\\end\{abstract\}', abstract_text, content, flags=re.DOTALL)

content = content.replace(
    r"This paper completes that program by building an \emph{explicit physical realisation} of the Hilbert–P\'olya operator.",
    r"This paper advances that program by building an \emph{explicit dynamical realisation} of the Hilbert–P\'olya operator."
)

content = content.replace(
    r"Hence the physical universe realises $g=0$.",
    r"This empirical anchor selects $g=0$ uniquely, placing the model at the exact threshold of stability."
)

content = content.replace(
    r"The Riemann Hypothesis thus emerges as an unavoidable consequence of the medium's thermodynamic stability.",
    r"The Riemann Hypothesis thus emerges as a conditional consequence of the medium's thermodynamic stability, provided the underlying geometry admits a valid intersection theory."
)

content = content.replace(
    r"We have presented a complete, physically grounded proof that the Riemann Hypothesis follows from the thermodynamic stability of the arithmetic membrane",
    r"We have presented a conditional, dynamically grounded proof that the Riemann Hypothesis follows from the thermodynamic stability of the arithmetic membrane"
)

content = content.replace(
    r"The observed positions of the first $32$ zeros, certified to micro‑Hertz precision, select the unique value $g=0$, the threshold of stability.  Contractivity at $g=0$ forces the real‑part offset $\Delta$ of every zero to vanish, placing all zeros on the critical line.",
    r"The observed positions of the first $32$ zeros, certified to micro‑Hertz precision, select the unique value $g=0$, the threshold of stability. If the geometric assumptions (the T5 diagonal and trace formula) hold, contractivity at $g=0$ forces the real‑part offset $\Delta$ of every zero to vanish, conditionally placing all zeros on the critical line."
)

content = content.replace(
    r"The only remaining open piece is the explicit construction of the regularised diagonal (the T5 problem).  While its formal properties are sufficient for our proof, a concrete geometric realisation would complete the F1‑square edifice",
    r"The proof remains strictly conditional on the explicit construction of the regularised diagonal (the T5 problem) and the full validity of the trace formula.  A concrete geometric realisation of these objects would complete the F1‑square edifice"
)

content = content.replace(
    r"It is the literal physical content of the Hilbert–Pólya conjecture: the Riemann zeros are the pure overtones of the arithmetic string, and the universe is tuned precisely to the point where that string can vibrate forever without sagging into dissonance.",
    r"It offers a concrete dynamical realization of the Hilbert–Pólya conjecture: the Riemann zeros act as the pure overtones of the arithmetic string, and the system is tuned precisely to the point where that string can vibrate without sagging into thermodynamic dissonance."
)

with open('main.tex', 'w') as f:
    f.write(content)

print("Updates applied.")
