# ADR-035: Operator Lie Grammar and              and $\{Q_j\}$ must have nonzero
Baker-Campbell-Hausdorff (BCH) Integration       cross-commutator support ($[P_i, Q_j] \neq
                                                 0$). This ensures the overlay dependency
**Status:** PROPOSED                             propagates throughout the algebraic nesting.
**Date:** 2026-06-06                               - **Partial-Decoupling Mode (Control
**Owner:** Prototype Lead / Algebra Layer        Condition):** An optional mode where $[P_2,
**Metric:** Truncation order and cost path       Q_1] = 0$ functions strictly as an experimental
divergence under adaptive BCH composition        control condition to stress-test boundary
**Horizon:** 30 days                             behavior, not as a representative default.
**Supersedes:** none
**Superseded by:** none                          3. **Adaptive BCH Composition Rule:**
                                                   Composition order $N$ starts at 2 and is
## Context                                       adjusted adaptively up to a cap of 4. The order
In the PIRTM runtime, verifying session          increases only when the primary criterion is
contractivity requires mapping operator          met: the separation metric $\Delta BRA$
histories to reconstruction costs. Shared        becomes unstable (variation across orders $>
geometry alone is insufficient to guarantee      0.5$) or sign-ambiguous across truncation
system correctability; apparent stability can    levels. Matrix residual norms (Frobenius norm
exist without successful integration, making     difference between orders) serve as a
recomputation capacity the relevant failure      secondary trigger to detect numerical drift.
boundary.
                                                 4. **BRA Cost Functional:**
To measure this boundary, we require a             Reconstruction cost is defined as $C(W) =
mathematically sound operator word               \ell(W) + \alpha r(W) + \beta q(W)$, where:
composition rule. The                              - $\ell(W)$ is physical word length.
Baker-Campbell-Hausdorff (BCH) formula             - $r(W)$ is the nested commutator rank
allows us to express the product of generator    (worst-case nesting depth of Lie brackets).
exponentials as a single effective exponent,       - $q(W)$ is the $Q$-factor count.
enabling the extraction of the commutator          - Truncation depth $N$ and the resulting
nesting depth. However, static truncation        cost path must both remain fully observable in
orders introduce truncation errors that can      the results trace.
distort the separation metric, while simple
matrix embeddings risk masking accidental        ## Consequences
decoupling dependencies.                         ### Positive
                                                 - Prevents borrowed stability from simulating
## Decision                                      independent correctability.
We will codify the operator Lie grammar and      - Clear and audit-ready results tracing of
Baker-Campbell-Hausdorff (BCH) integration       computational costs.
as a **validated research protocol**,            - Noncommuting cross-brackets provide a
preserving room for future matrix families and   robust, mathematical boundary for verification
prime-indexed representations. The protocol      gates.
enforces the following constraints:
                                                 ### Negative (accepted)
1. **Generator Set:**                            - Evaluating deep words to order 4 increases
  The Lie algebra $\mathfrak{g}$ is spanned      computation latency due to nested commutator
by internal prime-indexed generators             calculations.
$\{P_i\}$ and external/overlay generators
$\{Q_j\}$. For the baseline prototype, we        ### Risks if deferred
embed $P_2, P_3$ (internal) and $Q_1$            - Overestimating system correctability by
(overlay) in $\mathfrak{gl}(3, \mathbb{R})$.     relying on shared geometry alone without
                                                 verifying geometric cohesion.
2. **Coupling Policy:**
  - **Full Cross-Coupling Mode (Default Stress   ## Enforcement
Baseline):** All pairings between $\{P_i\}$
- **Automated Tests:** `pytest` unit tests         Without a strict regression and generalization
verifying commutator antisymmetry, Jacobi          policy, replacing the default embedding matrix
identity, and adaptive truncation triggers.        family risks introducing representations that
- **Trace Auditing:** CLI runner must output       lose noncommutative sensitivity, collapse the
a tabular results trace to `output/results.csv`    separation invariant, or fail to isolate borrowed
logging `coupling_mode`, `test_type`,              stability from independent recomputation.
`final_order`, `matrix_residual_norm`,
`internal_cost`, `overlay_cost`, `delta_bra`,      ## Decision
and `separated`.                                   We will implement a mandatory **Regression
                                                   and Generalization Policy** for the operator
## Precision Question Answered                     Lie grammar. Any proposed replacement or
*Should the ADR codify the current prototype       upgrade of the generator matrix embedding
behavior as a stable formal rule, or explicitly    family must pass the following gate
label it as a validated research protocol with     requirements before acceptance:
room for future matrix families?*
                                                   1. **Algebraic Generalization Criteria:**
**Decision:** We explicitly label this as a          - **Structure Constant Parity:** The
**validated research protocol**. This preserves    proposed representation must faithfully
room to generalize the algebraic structures to     preserve the non-abelian structure constants
higher-dimensional Lie groups, custom              defined in the system invariants.
prime-indexed embeddings, or symbolic                - **Cross-Coupling Asymmetry:** All
solvers in future iterations without locking the   $P$-$Q$ pairings in the baseline stress model
runtime verifier exclusively to the gl(3) toy      must have non-vanishing cross-commutator
matrix representations.                            support ($[P_i, Q_j] \neq 0$).
                                                     - **Dimension Scalability:** The embedding
                                                   must scale to higher dimensions without
                                                   introducing accidental zeros or commutative
                                                   sub-spaces that bypass the cost functional.

# ADR-036: Operator Lie Grammar                    2. **Controller Regression Criteria:**
Regression and Generalization Policy                 - **Order Divergence Invariant:** The
                                                   adaptive BCH controller must exhibit distinct
**Status:** PROPOSED                               order-selection divergence between the
**Date:** 2026-06-06                               full-coupling stress baseline and the
**Owner:** Prototype Lead / Verification Gate      partial-decoupling control condition on
**Metric:** CI-enforced regression suite           adversarial test fixtures.
verifying matrix embedding generalization and        - **Control Halt Condition:** Under the
controller sensitivity                             control condition, the matrix residual norm
**Horizon:** 30 days                               must resolve to exactly `0.0000` at order 2,
**Supersedes:** none                               causing the controller to halt early.
**Superseded by:** none                              - **Falsification Integrity:** Any
                                                   representation that causes the baseline stress
## Context                                         mode and control condition to collapse into the
ADR-035 establishes the operator Lie grammar       same truncation order on adversarial inputs is
and Baker-Campbell-Hausdorff (BCH)                 rejected.
composition as a validated research protocol         - **Observability:** Both truncation depth
using a specific $\mathfrak{gl}(3,                 and cost path must remain fully inspectable
\mathbb{R})$ embedding. However, future            and logged.
development or optimization proposals may
introduce higher-dimensional representation        3. **CI Integration:**
spaces, custom prime-indexed algebras, or            - A dedicated regression verification script
alternative matrix families.                       (e.g. `tests/test_generalization.py`) must be
                                                   executed as a hard gate in the CI pipeline.
  - The regression gate will evaluate the          **Date:** 2026-06-06
candidate matrix family against the baseline,      **Owner:** Prototype Lead / Verification Gate
adversarial 1, and adversarial 2 histories,        **Metric:** CI-enforced regression suite
confirming $\Delta BRA > 0$ and order              verifying matrix embedding generalization and
divergence.                                        controller sensitivity
                                                   **Horizon:** 30 days
## Consequences                                    **Supersedes:** none
### Positive                                       **Superseded by:** none
- Prevents structural regression where new
embeddings accidentally erase the                  ## Context
recomputation gap.                                 ADR-035 establishes the operator Lie grammar
- Enables safe, modular upgrades to                and Baker-Campbell-Hausdorff (BCH)
higher-dimensional algebraic representations.      composition as a validated research protocol
- Enforces mathematical discipline over the        using a specific $\mathfrak{gl}(3,
compilation verifier.                              \mathbb{R})$ embedding. However, future
                                                   development or optimization proposals may
### Negative (accepted)                            introduce higher-dimensional representation
- Introduces additional developer overhead for     spaces, custom prime-indexed algebras, or
validating custom generator sets.                  alternative matrix families.
- Increases CI runtimes due to matrix-norm
validation of candidate embeddings.                Without a strict regression and generalization
                                                   policy, replacing the default embedding matrix
### Risks if deferred                              family risks introducing representations that
- Silent collapse of the BRA separation            lose noncommutative sensitivity, collapse the
invariant if an optimized matrix family behaves    separation invariant, or fail to isolate borrowed
commutatively under specific histories.            stability from independent recomputation.

## Enforcement                                     ## Decision
- **Gate Validator:** CI must execute the          We will implement a mandatory **Regression
generalization test suite on any PR modifying      and Generalization Policy** for the operator
`src/bra/algebra.py` or the generator              Lie grammar. Any proposed replacement or
definitions.                                       upgrade of the generator matrix embedding
- **Upgrades:** Any matrix representation          family must pass the following gate
change must update `validation_gates.py` and       requirements before acceptance:
`system_invariants.yaml` concurrently.
                                                   1. **Algebraic Generalization Criteria:**
## Precision Question Answered                       - **Structure Constant Parity:** The
*What defines a valid generalization of the        proposed representation must faithfully
operator Lie grammar versus a regression?*         preserve the non-abelian structure constants
                                                   defined in the system invariants.
**Decision:** A valid generalization must            - **Cross-Coupling Asymmetry:** All
preserve the **truncation order divergence**       $P$-$Q$ pairings in the baseline stress model
under the adaptive BCH controller on               must have non-vanishing cross-commutator
adversarial inputs. If a candidate matrix family   support ($[P_i, Q_j] \neq 0$).
resolves the baseline and control histories to       - **Dimension Scalability:** The embedding
the same order, it is classified as a regression   must scale to higher dimensions without
and rejected, even if it achieves the required     introducing accidental zeros or commutative
$\Delta BRA > 0$ separation margin on paper.       sub-spaces that bypass the cost functional.

                                                   2. **Controller Regression Criteria:**
# ADR-036: Operator Lie Grammar                      - **Order Divergence Invariant:** The
Regression and Generalization Policy               adaptive BCH controller must exhibit distinct
                                                   order-selection divergence between the
**Status:** PROPOSED                               full-coupling stress baseline and the
partial-decoupling control condition on
adversarial test fixtures.                        ## Precision Question Answered
  - **Control Halt Condition:** Under the         *What defines a valid generalization of the
control condition, the matrix residual norm       operator Lie grammar versus a regression?*
must resolve to exactly `0.0000` at order 2,
causing the controller to halt early.             **Decision:** A valid generalization must
  - **Falsification Integrity:** Any              preserve the **truncation order divergence**
representation that causes the baseline stress    under the adaptive BCH controller on
mode and control condition to collapse into the   adversarial inputs. If a candidate matrix family
same truncation order on adversarial inputs is    resolves the baseline and control histories to
rejected.                                         the same order, it is classified as a regression
  - **Observability:** Both truncation depth      and rejected, even if it achieves the required
and cost path must remain fully inspectable       $\Delta BRA > 0$ separation margin on paper.
and logged.

3. **CI Integration:**
  - A dedicated regression verification script
(e.g. `tests/test_generalization.py`) must be     Below is a concrete **test harness scaffold**
executed as a hard gate in the CI pipeline.       for the BCH/BRA prototype, organized so you
  - The regression gate will evaluate the         can start with a minimal executable core and
candidate matrix family against the baseline,     then extend into the Lie grammar ADR. The
adversarial 1, and adversarial 2 histories,       governing tension is still the same: preserve a
confirming $\Delta BRA > 0$ and order             measurable recomputation gap between
divergence.                                       overlay and integration, not just a nicer
                                                  algebraic story.[^1]
## Consequences
### Positive                                      ## Central tension
- Prevents structural regression where new
embeddings accidentally erase the                 The harness should test whether
recomputation gap.                                $Q$-dependent histories require higher
- Enables safe, modular upgrades to               reconstruction cost than $P$-only histories
higher-dimensional algebraic representations.     with the same terminal state. The paper
- Enforces mathematical discipline over the       explicitly says apparent stability can exist
compilation verifier.                             without successful integration, and that
                                                  recomputation capacity is the relevant failure
### Negative (accepted)                           boundary.[^1]
- Introduces additional developer overhead for
validating custom generator sets.                 ## File scaffold
- Increases CI runtimes due to matrix-norm
validation of candidate embeddings.               Use this layout:

### Risks if deferred                             ```text
- Silent collapse of the BRA separation           bra-prototype/
invariant if an optimized matrix family behaves    pyproject.toml
commutatively under specific histories.            README.md
                                                   src/
## Enforcement                                      bra/
- **Gate Validator:** CI must execute the            __init__.py
generalization test suite on any PR modifying        algebra.py
`src/bra/algebra.py` or the generator                bch.py
definitions.                                         cost.py
- **Upgrades:** Any matrix representation            history.py
change must update `validation_gates.py` and         prototype.py
`system_invariants.yaml` concurrently.               metrics.py
 tests/
  test_algebra.py                                    ## Core test cases
  test_bch.py
  test_cost.py                                       Create two paired histories:
  test_paired_history.py
 data/                                               - **Internal history**: a pure $P$-word of
  paired_histories.json                              length 4–5.
 output/                                             - **Overlay history**: same terminal target,
  results.csv                                        but with one $Q_1$ insertion.
  results.png
```                                                  The harness should try to reconstruct both
                                                     with the same budget and report whether the
                                                     overlay case exceeds it. That aligns with the
## Module roles                                      framework’s distinction between
                                                     reconstruction and integration, and with the
- `algebra.py`: generator definitions,               claim that some systems remain informed
commutators, structure constants, matrix or          while becoming less correctable.[^1]
symbolic representation.
- `bch.py`: truncated BCH composition and            ## Suggested code skeleton
helper routines for iterated composition.
- `cost.py`: $C(W)=\ell(W)+\alpha                    ### `src/bra/algebra.py`
r(W)+\beta q(W)$, plus budget checks.
- `history.py`: paired-history fixtures for          ```python
internal vs overlay cases.                           import numpy as np
- `prototype.py`: command-line runner that
computes reconstruction costs and writes             GENS = {
results.                                               ("P", 2): np.array([[0, 1, 0], [0, 0, 0], [0, 0,
- `metrics.py`: BRA, $\Delta BRA$, and               0]], dtype=float),
optional separation flags.                             ("P", 3): np.array([[0, 0, 0], [1, 0, 0], [0, 0,
                                                     0]], dtype=float),
                                                       ("Q", 1): np.array([[0, 0, 1], [0, 0, 0], [0, 1,
## Minimal data model                                0]], dtype=float),
                                                     }
Represent words as tagged tuples:
                                                     def commutator(a, b):
```python                                              return a @ b - b @ a
("P", 2)                                             ```
("P", 3)
("Q", 1)
```                                                  ### `src/bra/bch.py`

Represent a word as:                                 ```python
                                                     def bch2(X, Y):
```python                                              return X + Y + 0.5 * commutator(X, Y)
Word = list[tuple[str, int]]                         ```
```
                                                     For a deeper prototype, iterate the truncated
For the matrix backend, keep a small                 BCH composition over the word.
dictionary from generator tags to
`numpy.ndarray`. For the symbolic backend,           ### `src/bra/cost.py`
keep a basis vector or a small linear
combination object. The paper supports               ```python
treating this as a research prototype, not a final   def word_cost(word, alpha=1.0, beta=2.0,
validated mechanism.[^1]                             rank=0):
  l = len(word)
  q = sum(1 for g in word if g[^0] == "Q")        ### `tests/test_bch.py`
  return l + alpha * rank + beta * q
```                                               - truncated BCH returns expected shape/type.
                                                  - composition of commuting elements reduces
                                                  to sum at first order.
### `src/bra/history.py`                          - noncommuting pair produces a correction
                                                  term.
```python
INTERNAL = [("P", 2), ("P", 3), ("P", 2), ("P",
3)]                                               ### `tests/test_cost.py`
OVERLAY = [("P", 2), ("Q", 1), ("P", 3), ("P",
2)]                                               - $Q$-factor increases cost when $\beta > 1$.
```                                               - nested commutator rank raises cost when
                                                  $\alpha > 0$.

### `src/bra/prototype.py`
                                                  ### `tests/test_paired_history.py`
```python
from bra.history import INTERNAL,                 - internal and overlay histories produce
OVERLAY                                           different costs.
from bra.cost import word_cost                    - overlay cost exceeds internal cost under the
                                                  same budget.
def evaluate(word, rank=0, alpha=1.0,             - separation flag becomes true when $\Delta
beta=2.0):                                        BRA > 0$.
  return {
     "length": len(word),
     "q_count": sum(1 for g in word if g[^0] ==   ## `pyproject.toml`
"Q"),
     "rank": rank,                                Keep it simple:
     "cost": word_cost(word, alpha=alpha,
beta=beta, rank=rank),                            ```toml
  }                                               [project]
                                                  name = "bra-prototype"
def run():                                        version = "0.1.0"
  rows = []                                       requires-python = ">=3.11"
  for name, word in [("internal", INTERNAL),      dependencies = ["numpy", "pytest"]
("overlay", OVERLAY)]:                            ```
     rows.append({"history": name,
**evaluate(word, rank=1 if name == "overlay"
else 0)})                                         ## Execution flow
  return rows
```                                               1. Load generator matrices.
                                                  2. Compose a word using truncated BCH.
                                                  3. Extract effective rank proxy from
## Tests to write                                 commutator depth.
                                                  4. Compute $C(W)$.
### `tests/test_algebra.py`                       5. Compare paired histories.
                                                  6. Write `output/results.csv`.
- commutator is antisymmetric.                    7. Emit a small plot if you want a visual
- matrix generators are non-abelian.              separation trace.
- cross-commutator between $P$ and $Q$ is
nonzero in at least one pairing.                  ## Governance binding
The manuscript says future work should focus     The Lie bracket is defined by the matrix
on disciplined validation, operationalization,   commutator $[X, Y] = XY - YX$. The structure
and measurement before broader expansion.        constants govern the interactions:
So the harness should be the evidence layer      $$[P_i, P_k] = \sum_m c_{ik}^m P_m$$
first, and the ADR grammar extension             $$[P_i, Q_j] = \gamma_{ij} Q_j + \delta_{ij}
second.[^1]                                      P_i + \sum_m \epsilon_{ij}^m P_m +
                                                 \sum_n \eta_{ij}^n Q_n$$
## Precision question
                                                 Where $\gamma_{ij} \neq 0$ creates
Do you want the scaffold converted next into a   non-trivial mixing, ensuring that overlay
**ready-to-run Python package** or into a        modes cannot be simulated by pure internal
**single-file prototype** for faster initial     modes without generating high-order
execution?                                       cross-brackets.

<div align="center">⁂</div>                      ### 1.2 Matrix Representations
                                                 For the toy prototype, we embed the generators
[^1]: Accessibility-Geometry-v1.1.pdf            $P_2, P_3,$ and $Q_1$ into
                                                 $\mathfrak{gl}(3, \mathbb{R})$. To prevent
​                                                accidental decoupling dependencies, the
                                                 prototype supports two modes:
                                                 1. **Full Cross-Coupling Mode (Default
                                                 baseline):**
# Production-Grade Development Plan: BCH /         Enforces nonzero cross-commutators across
BRA Prototype                                    all generator pairings.
                                                   - $P_2 = \begin{pmatrix} 0 & 1 & 0 \\ 0 & 0
This document provides a production-grade        & 0 \\ 0 & 0 & 0 \end{pmatrix}$
development plan and complete architectural        - $P_3 = \begin{pmatrix} 0 & 0 & 0 \\ 1 & 0
blueprints for the Baker-Campbell-Hausdorff      & 0 \\ 0 & 0 & 0 \end{pmatrix}$
(BCH) / Bounded Reconstruction Asymmetry           - $Q_1 = \begin{pmatrix} 0 & 1 & 1 \\ 1 & 0 &
(BRA) prototype. This prototype verifies that    1 \\ 0 & 1 & 0 \end{pmatrix}$
external ($Q$-dependent) histories incur           Under this representation, $[P_2, Q_1] \neq
higher reconstruction costs than internal        0$ and $[P_3, Q_1] \neq 0$.
($P$-only) histories for the same terminal
target state.                                    2. **Optional Partial-Decoupling Mode
                                                 (Control Condition):**
---                                                Tests a mixed decoupling regime where one
                                                 cross-commutator vanishes.
## 1. Mathematical Foundation & Formalism          - $Q_1 = \begin{pmatrix} 0 & 0 & 1 \\ 0 & 0
                                                 & 0 \\ 0 & 1 & 0 \end{pmatrix}$
The prototype models the interaction of            Under this representation, $[P_2, Q_1] = 0$
operators in a non-commutative Lie algebra       but $[P_3, Q_1] \neq 0$.
$\mathfrak{g}$ generated by:
- **Internal Generators                            > [!NOTE]
($\mathfrak{g}_{\text{int}}$):** $\{P_i\}$         > This mode functions purely as a control
representing prime-indexed internal modes of     condition to stress-test the boundary behavior
the system.                                      of the invariant, not as a representative
- **External/Overlay Generators                  baseline default.
($\mathfrak{g}_{\text{ext}}$):** $\{Q_j\}$
representing external overlay modes with a
high-provenance footprint.
                                                 ### 1.3 Adaptive Iterative BCH Word
### 1.1 Commutator & Structure Constants         Composition
                                                 An operator word $W = \exp(G_1) \exp(G_2)
                                                 \cdots \exp(G_\ell)$ represents a sequence of
exponential map applications. We compute the       - $\beta > 1$ is the overlay provenance
effective single exponent $Z \in \mathfrak{g}$     penalty.
such that:
$$\prod_{i=1}^{\ell} \exp(G_i) = \exp(Z)$$         The separation metric is:
                                                   $$\Delta BRA = C(W_{\text{overlay}}) -
We solve this using the truncated                  C(W_{\text{internal}})$$
Baker-Campbell-Hausdorff (BCH) formula
recursively. For two terms:                        For identical terminal target states, $\Delta
$$\text{BCH}_3(X, Y) = X + Y +                     BRA > 0$ indicates successful separation of
\frac{1}{2}[X, Y] + \frac{1}{12}[X, [X, Y]] +      the overlay history.
\frac{1}{12}[Y, [Y, X]]$$
$$\text{BCH}_4(X, Y) = \text{BCH}_3(X, Y) -        ---
\frac{1}{24}[Y, [X, [X, Y]]]$$
                                                   ## 2. Software Architecture & Directory
#### Adaptive Controller                           Scaffold
Rather than utilizing a static truncation level,
an **Adaptive Error-Tolerance Controller** is      The prototype is structured as a clean, testable
implemented:                                       Python package under `bra-prototype/`.
1. Composes both internal and overlay words at
order 2.                                           ```text
2. Computes the resulting $\Delta                  bra-prototype/
BRA^{(2)}$.                                         pyproject.toml         # Modern packaging &
3. Compares the result against order 3 and         dependencies (PEP 621)
order 4 compositions.                               README.md                # Installation & usage
4. Upgrades the BCH order if:                      guide
  - **Primary (Stability of $\Delta BRA$):**        BCH_PROTOTYPE_PLAN.md                #
The sign of $\Delta BRA$ changes, or the           Development plan & math specification
margin fluctuates/unravels across orders.           src/
  - **Secondary (Matrix Residual Norm):**            bra/
Frobenius norm difference $\|Z^{(order)} -            __init__.py
Z^{(order-1)}\|_F$ exceeds                            algebra.py        # Generator
`residual_threshold`.                              representations and commutator math
  - **Tertiary (Truncation Depth Cap):**              bch.py           # Iterative BCH
Reaches maximum configured order (default:         composition engine
4).                                                   cost.py          # BRA cost functional &
                                                   tracking
                                                      history.py        # Paired-history fixture
### 1.4 BRA Cost Functional                        definitions
We define the reconstruction cost $C(W)$ of a         metrics.py         # BRA & ΔBRA
word $W$ as:                                       evaluation routines
$$C(W) = \ell(W) + \alpha r(W) + \beta                prototype.py        # CLI entrypoint and
q(W)$$                                             runner
                                                    tests/
Where:                                               test_algebra.py       # Unit tests for Lie
- $\ell(W)$ is the physical length of the word     algebra properties
(number of generator factors).                       test_bch.py         # Unit tests for BCH
- $r(W)$ is the nested commutator rank             expansion
(maximum nesting depth of brackets in the            test_cost.py        # Unit tests for cost
reduced Lie element $Z$).                          tracking
- $q(W)$ is the total count of $Q_j$ factors in      test_paired_history.py # System
the history.                                       integration & separation test
- $\alpha \geq 0$ is the commutator depth           data/
penalty.                                             paired_histories.json # Saved history
                                                   configurations
 output/
  results.csv       # Tabular results with         def commutator(a: LieElement, b: LieElement)
columns: coupling_mode, final_order,               -> LieElement:
matrix_residual_norm, internal_cost,                 matrix = a.matrix @ b.matrix - b.matrix @
overlay_cost, delta_bra, separated                 a.matrix
  results.png        # Separation plot               expression = f"[{a.expression},
visualization                                      {b.expression}]"
```                                                  depth = a.depth + b.depth + 1
                                                     q_count = a.q_count + b.q_count
                                                     return LieElement(matrix, expression,
---                                                depth, q_count)

## 3. Detailed Module Specifications               # Toy matrix representatives satisfying
                                                   cross-commutator asymmetry
### 3.1 `src/bra/algebra.py`                       P2 = LieElement([[0, 1, 0], [0, 0, 0], [0, 0, 0]],
Defines the `LieElement` class which               "P2", depth=0, q_count=0)
encapsulates a numeric matrix representation       P3 = LieElement([[0, 0, 0], [1, 0, 0], [0, 0, 0]],
while carrying metadata to track its algebraic     "P3", depth=0, q_count=0)
structure (symbolic expression, nesting depth,     Q1_FULL = LieElement([[0, 1, 1], [1, 0, 1], [0,
and Q-factor count).                               1, 0]], "Q1_full", depth=0, q_count=1)
                                                   Q1_PARTIAL = LieElement([[0, 0, 1], [0, 0, 0],
```python                                          [0, 1, 0]], "Q1_partial", depth=0, q_count=1)
import numpy as np
                                                   GENS = {
class LieElement:                                    ("P", 2): P2,
  def __init__(self, matrix, expression,             ("P", 3): P3,
depth=0, q_count=0):                                 ("Q", 1): Q1_FULL,
     self.matrix = np.array(matrix, dtype=float)   }
     self.expression = expression
     self.depth = depth                            def set_coupling_mode(mode: str = "full"):
     self.q_count = q_count                          global GENS
                                                     if mode == "full":
  def __add__(self, other):                             GENS[("Q", 1)] = Q1_FULL
    if not isinstance(other, LieElement):            elif mode == "partial":
       raise TypeError("Can only add                    GENS[("Q", 1)] = Q1_PARTIAL
LieElement to LieElement")                         ```
    return LieElement(
       self.matrix + other.matrix,
       f"({self.expression} +                      ### 3.2 `src/bra/bch.py`
{other.expression})",                              Implements the third-order BCH expansion
       max(self.depth, other.depth),               and recursive word composition.
       max(self.q_count, other.q_count)
    )                                              ```python
                                                   from bra.algebra import commutator,
  def __mul__(self, scalar):                       LieElement
    return LieElement(
      self.matrix * scalar,                        def bch3(X: LieElement, Y: LieElement) ->
      f"{scalar} * {self.expression}",             LieElement:
      self.depth,                                    """Computes BCH up to 3rd order: X + Y +
      self.q_count                                 1/2 [X,Y] + 1/12 [X,[X,Y]] + 1/12 [Y,[Y,X]]"""
    )                                                term1 = X + Y

  def __rmul__(self, scalar):                        xy = commutator(X, Y)
    return self.__mul__(scalar)                      term2 = 0.5 * xy
                                                     # Aggregate actual Q counts from history or
  x_xy = commutator(X, xy)                         LieElement
  y_yx = commutator(Y, commutator(Y, X))             q_W = sum(1 for g in word if g[0] == "Q")
  term3 = (1.0 / 12.0) * x_xy - (1.0 / 12.0) *       return l_W + alpha * r_W + beta * q_W
y_yx                                               ```

  return term1 + term2 + term3                     ### 3.4 `src/bra/metrics.py`
                                                   Computes the delta BRA and determines
def compose_word(word: list[tuple[str, int]],      whether separation is satisfied.
order: int = 3) -> LieElement:
  """Iteratively composes an operator word         ```python
using truncated BCH."""                            def compute_separation(
  from bra.algebra import GENS                        internal_cost: float,
  if not word:                                        overlay_cost: float,
     return LieElement(np.zeros((3, 3)), "0", 0,      internal_depth: int,
0)                                                    overlay_depth: int,
                                                      threshold: float = 0.0
  current = GENS[word[0]]                          ) -> dict:
  for tag in word[1:]:                                delta = overlay_cost - internal_cost
    next_elem = GENS[tag]                             return {
    if order == 1:                                      "delta_bra": delta,
       current = current + next_elem                    "separated": delta > threshold,
    elif order == 2:                                    "internal_depth": internal_depth,
       current = current + next_elem + 0.5 *            "overlay_depth": overlay_depth
commutator(current, next_elem)                        }
    elif order == 3:                               ```
       current = bch3(current, next_elem)
    elif order == 4:
       current = bch4(current, next_elem)          ---
  return current
                                                   ## 4. Testing & Verification Protocol
def
compose_paired_words_adaptive(internal_wo          A set of automated tests enforces mathematical
rd, overlay_word, alpha=1.0, beta=2.0,             lawfulness and prevents regression.
max_order=4):
  # (Refer to implementation in                    ### 4.1 Unit Test Specifications
src/bra/bch.py for the full adaptive logic)        1. **`test_algebra.py`:**
  pass                                               - Verify that the commutator is
```                                                anti-symmetric: $[X, Y] = -[Y, X]$.
                                                     - Verify that matrix representation is
                                                   non-abelian: $[P_2, P_3] \neq 0$.
### 3.3 `src/bra/cost.py`                            - Verify that Jacobi identity holds: $[X, [Y,
Computes the BRA cost functional and               Z]] + [Y, [Z, X]] + [Z, [X, Y]] = 0$.
enforces limits.                                   2. **`test_bch.py`:**
                                                     - Verify that composition of commuting
```python                                          elements reduces to exact sum.
from bra.algebra import LieElement                   - Verify that 3rd-order terms match analytic
                                                   values for toy generators.
def word_cost(word: list[tuple[str, int]],         3. **`test_cost.py`:**
reduced_element: LieElement, alpha: float =          - Verify that $Q$-factors scale cost with
1.0, beta: float = 2.0) -> float:                  $\beta$.
  l_W = len(word)                                    - Verify that commutator depth increases
  r_W = reduced_element.depth                      rank and cost.
                                                   4. **`test_paired_history.py`:**
 - Run comparison between `INTERNAL` and
`OVERLAY` histories.                                subgraph Governance Contracts
 - Assert $\Delta BRA > 0$ for $\alpha=1.0,           G[validation_gates.py]
\beta=2.0$.                                           H[governance_bootstrap.py]
                                                      I[innovation_budget.yaml]
### 4.2 Adaptive BCH Controller Acceptance          end
Criteria
The adaptive BCH controller must satisfy the        C -.-> G
following strict requirements:                      I -.-> G
1. **Separation-Driven Triggers:** The              H -.-> I
composition order $N$ must increase only          ```
when $\Delta BRA$ becomes unstable
(variation across orders exceeds                  ### 5.1 Coupling to `validation_gates.py`
`margin_threshold` = 0.5) or sign-ambiguous       The `validation_gates.py` validator must
across successive truncation levels.              import the cost computation module to
2. **Fallback Residual Bounds:** Matrix           perform checks:
residual norm tracking is retained as a           ```python
secondary trigger to detect numerical drift.      def verify_budget_token(action_details):
3. **No Hidden Costs:** Truncation depths           # Exempt safety-critical proofs
must be tracked and recorded explicitly inside      if action_details.get("action_class") ==
the results trace.                                "safety-proof":
                                                       return True
> [!WARNING]
> **Regression Note:** The adaptive controller      word = action_details.get("word")
must discriminate histories *both* by               reduced = compose_word(word)
truncation depth and by cost path, rather than      cost = word_cost(word, reduced)
depending solely on the terminal $\Delta
BRA$ separation. A collapse of truncation           if cost >
order divergence (such as baseline and control    action_details.get("budget_ceiling"):
selecting the same order on adversarial inputs)        raise PermissionError(f"Autonomous
indicates an overfitted or degenerate matrix      action cost {cost} exceeds budget ceiling.")
embedding.                                          return True
                                                  ```

                                                  ### 5.2 Dynamic Health Coupling
---                                               The parameter $\beta$ is dynamically scaled
                                                  based on the recursive stability monitor
## 5. Phase Mirror Integration & Governance       $l_\phi$ defined in **ADR-034**:
                                                  - If $l_\phi < 0.7$, the budget ceiling is
The BCH/BRA prototype acts as the empirical       dynamically scaled by a multiplier of $0.2$,
validation layer before integration into the      restricting exploratory trajectories during
compilation runtime.                              unstable regimes.

```mermaid                                        ---
graph TD
  A[Operator History Word W] --> B[Iterative      ## 6. Implementation Phases (Timeline &
BCH Engine]                                       Roadmap)
  B --> C[Compute C_W = l + alpha * r + beta
* q]                                              | Phase | Milestone | Deliverables | Gate
  C --> D{Verify Budget Gate}                     Condition |
  D -- Exceeds Budget --> E[Raise Budget          | :--- | :--- | :--- | :--- |
Violation Error]                                  | **Phase 1** | Algebraic Core | Setup directory
  D -- Within Budget --> F[Authorize State        layout, implement `algebra.py` and
Evolution]
`LieElement` with matrix reps. | `pytest            - **Full Cross-Coupling Mode (Stress
tests/test_algebra.py` passes. |                    Baseline):** All generator pairings between
| **Phase 2** | BCH Engine | Implement              $P$ and $Q$ have nonzero support ($[P_2,
iterative `bch3` and word composition; define       Q_1] \neq 0$ and $[P_3, Q_1] \neq 0$).
`cost.py`. | `pytest tests/test_bch.py` passes. |   - **Partial-Decoupling Mode (Control
| **Phase 3** | Paired-History | Create             Condition):** A decoupled representation
`history.py`, compare internal vs overlay           where $[P_2, Q_1] = 0$.
paths. | $\Delta BRA > 0$ separation verified.
|                                                   ### 1.2 Adaptive Controller Criteria
| **Phase 4** | Integration | Bridge to             - **Primary:** $\Delta BRA$ sign and margin
`validation_gates.py` and implement budget          stability across orders (tolerance threshold =
token limits. | Gate validation rejects high-cost   0.5).
word. |                                             - **Secondary:** Frobenius norm matrix
| **Phase 5** | Governance | Connect to             residual limit (threshold = 0.05).
`governance_bootstrap.py` and seed                  - **Tertiary:** Truncation depth cap ($N \le
`innovation_budget.yaml`. | Full CI run with        4$).
budget token enforcement. |
                                                    ---

                                                    ## 2. Empirical Results Table

# Empirical Findings: Adaptive BCH                  The table below summarizes the output
Truncation and BRA Cost Separation                  recorded during the test runs:

This report documents the empirical findings        | Coupling Mode | Test Type | Final BCH Order
from the Bounded Reconstruction Asymmetry           | Matrix Residual Norm | Internal Cost |
(BRA) and Baker-Campbell-Hausdorff (BCH)            Overlay Cost | $\Delta BRA$ | Separated? |
prototype. It analyzes how different generator      | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
matrix coupling modes (full cross-coupling vs.      | **full** | baseline | 4 | 0.9079 | 25.0 | 27.0 |
partial decoupling control) and operator            2.0 | True |
orderings affect the adaptive truncation            | **partial** | baseline | 4 | 0.9079 | 25.0 |
decisions and the resulting reconstruction          27.0 | 2.0 | True |
costs.                                              | **full** | adversarial_1 | 4 | 0.2505 | 25.0 |
                                                    27.0 | 2.0 | True |
---                                                 | **partial** | adversarial_1 | **2** |
                                                    **0.0000** | **7.0** | **9.0** | 2.0 | True |
## 1. Experimental Methodology & Parameters         | **full** | adversarial_2 | 4 | 0.9876 | 25.0 |
                                                    29.0 | 4.0 | True |
The experiments evaluate paired histories           | **partial** | adversarial_2 | **2** |
(Internal $P$-only vs. External                     **0.0000** | **7.0** | **11.0** | 4.0 | True |
$Q$-dependent) across three test
configurations:                                     ---
1. **Baseline History:**
  - Internal: `[P2, P3, P2, P3]`                    ## 3. Analysis & Divergence Mechanisms
  - Overlay: `[P2, Q1, P3, P2]`
2. **Adversarial 1 (Single Insertion):**            ### 3.1 Baseline History Behavior
  - Internal: `[P2, P2, P2, P2]`                    In the baseline test, both the full
  - Overlay: `[P2, Q1, P2, P2]`                     cross-coupling mode and partial-decoupling
3. **Adversarial 2 (Alternating Pattern):**         mode selected **order 4** composition with a
  - Internal: `[P2, P2, P2, P2]`                    depth of $21$. This occurs because the baseline
  - Overlay: `[Q1, P2, Q1, P2]`                     histories contain both $P_2$ and $P_3$
                                                    generators. Because $[P_2, P_3] \neq 0$, the
### 1.1 Coupling Modes                              internal composition generates non-trivial
                                                    commutators regardless of the $Q$-coupling
mode. The adaptive controller detects the           - In the **control partial-coupling mode**, the
resulting residual norms (e.g. $1.4411$ to          commutator penalty vanishes, proving that the
$2.0234$) and correctly upgrades the                controller is genuinely sensitive to the
composition to order 4 to ensure numerical          underlying Lie algebra structure constants and
accuracy.                                           matrix embeddings, not just a static tag
                                                    penalty.
### 3.2 Adversarial Divergence (The Control
Verification)                                       ---
The adversarial histories isolate the interaction
between $P_2$ and $Q_1$ by excluding the            ## 5. Conclusion & Next Steps
$P_3$ generator. This exposes a clear               The prototype succeeds in providing a credible,
divergence between the baseline and control         falsifiable surface for recomputation cost. The
modes:                                              divergence in the chosen truncation order
                                                    serves as empirical proof that the embedding
1. **Full Coupling Mode (Baseline Stress):**        geometry affects correctability.
  Since $P_2$ and $Q_1$ do not commute
($[P_2, Q_1] \neq 0$), composing the overlay        The next step is to codify this behavior into the
word generates non-vanishing cross-brackets.        broader PIRTM compilation pipeline by
The adaptive controller detects a non-zero          integrating the adaptive BCH compositor into
residual norm ($0.2505$ to $0.9876$) and            `validation_gates.py` as a primary gate
upgrades the composition order to **order 4**,      validator for autonomous compute spends.
resulting in a high commutator depth ($21$)
and elevated cost ($27.0$ to $29.0$).
2. **Partial Coupling Mode (Control                 # Operator Lie Grammar Operational Handoff
Condition):**                                       Note
  Since $P_2$ and $Q_1$ commute ($[P_2,
Q_1] = 0$), the composed overlay elements           This handoff note outlines the operational
commute completely. The matrix residual             parameters, verification checkpoints, and
norm drops to exactly **`0.0000`**. The             trigger conditions for the Operator Lie
adaptive controller detects this stable,            Grammar and Bounded Reconstruction
vanishing error and halts at **order 2**,           Asymmetry (BRA) verification system. It
keeping the commutator depth low ($3$) and          documents the safety boundaries as the project
costs minimal ($9.0$ to $11.0$).                    transitions from research validation to routine
                                                    operation.
---
                                                    ---
## 4. Exposing & Resolving the Hidden
Assumption                                          ## 1. What the Daemon Enforces

The primary risk of the initial prototype was       The
that the cost separation delta ($\Delta BRA$)       [SelfModificationDaemon](file:///home/multi
was cosmetic—driven entirely by the                 plicity/governance/self_modification/daemon.
hardcoded $Q$-penalty coefficient ($\beta =         py) dynamically intercepts all self-modification
2.0$) rather than the non-commutative               proposals and enforces the operator grammar
geometry.                                           invariants via the
                                                    [check_algebra_generalization_gate](file:///h
By introducing the adversarial control              ome/multiplicity/governance/self_modificatio
condition side-by-side with the baseline stress     n/validation_gates.py#L190-L277) in its Phase
mode, this assumption is resolved:                  3 validation flow.
- In the **baseline full-coupling mode**, the
cost is driven by both the $Q$-penalty and the      ### 1.1 Trigger Condition
commutator depth penalty ($\alpha \cdot             The generalization gate is triggered
r(W)$) due to non-commutative bracket               automatically if the proposal:
expansion.
1. Targets `SOURCE_CODE` modifications           - **Signatures & Quorum:** Signed by
affecting files in the algebra path              `pm-safety-01` and `pm-arch-01`, satisfying
(`src/bra/algebra.py` or `src/bra/bch.py`).      the 2/3 quorum requirement with mandatory
2. Proposes changes to generator matrix          Safety Lead presence.
parameters (`GENS`, `P2`, `P3`, `Q1`,
`Q1_FULL`, `Q1_PARTIAL`) or injects the          ---
test hook `trigger_degenerate_check` in its
proposed delta.                                  ## 3. When to Re-Open the Regression Gate

### 1.2 Verification Invariants                  The regression gate is designed to protect the
When triggered, the gate verifies that the       falsification surface. Future operators must
proposed changes satisfy the following           re-open and execute the generalization test
mathematical bounds within the current           suite
protocol:                                        [test_generalization.py](file:///home/multipli
- **Cost Separation ($\Delta BRA > 0$):** In     city/bra-prototype/tests/test_generalization.p
both full-coupling and partial-decoupling        y) under the following conditions:
modes, external overlay histories must incur
strictly higher reconstruction costs than        1. **Embedding upgrades:** Proposing to
internal histories.                              replace the $\mathfrak{gl}(3, \mathbb{R})$
- **Order Divergence Invariant:** On             or $\mathfrak{gl}(4, \mathbb{R})$ matrix
adversarial fixtures, the adaptive BCH           families with higher-dimensional spaces or
controller must select a higher truncation       custom prime-indexed representations.
order under full coupling (typically order 4)    2. **Controller tuning:** Adjusting the
than under the partial decoupling control        adaptive BCH controller parameters, such as
condition.                                       the matrix residual norm threshold (`0.05`) or
- **Control Halt Condition:** Under partial      the cost functional weights ($\alpha, \beta$).
decoupling ($[P_2, Q_1] = 0$), the matrix        3. **Algebraic amendments:** Altering the
residual norm must resolve to exactly            structure constants, commutator rules, or
`0.0000` at order 2, causing the controller to   introducing new generator mappings that
halt early to preserve efficiency.               could cause accidental commutative
                                                 sub-spaces.
---                                              4. **Gate modifications:** Any proposal that
                                                 changes the validation rules within
## 2. What the Ledger Ratifies                   `validation_gates.py` must run the entire
                                                 regression suite to ensure previous models are
The global immutable ledger                      not retroactively broken.
[ledger.json](file:///home/multiplicity/govern
ance/ledger.json#L1250-L1273) ratifies the
current system state, anchoring the specific
SHA-256 hashes of the governance documents
as transaction `"11"`:                           # Proof-to-Runtime Correspondence Note:
                                                 BRA/BCH Operator Grammar System
- **ADR-035 (Research Protocol):**
`7a75055c964c230dfb7f2889a589870178e733          This note documents the correspondence
5e8a7745866c7756741ebdeac3`                      between the machine-checked mathematical
 *Ratifies the Lie brackets, the baseline 3D     invariants proven in Lean 4 and the runtime
embedding, the cost functional formulation,      enforcement mechanisms running in
and the adaptive triggers.*                      Continuous Integration (CI) and the
- **ADR-036 (Generalization Policy):**           self-modification daemon.
`9109cb6cee3377a67fb6a3b98b4fb36c5d168f9
f049bc69f224b317b7e0f762b`                       > [!IMPORTANT]
 *Ratifies the structure constant parity,        > **Governance Boundary & Scope
cross-coupling asymmetry, and early-halt         Restriction**
invariants.*
> The formal invariants verified in Lean 4 are    multiplicity/bra-prototype/tests/test_generali
certified strictly *within the current research   zation.py#L57-L60)) |
protocol boundary* as defined in                  `check_algebra_generalization_gate`
[adr-035-operator-lie-grammar-bch.md](file:/      ([validation_gates.py:L303-309](file:///home
//home/multiplicity/bra-prototype/docs/adr/       /multiplicity/governance/self_modification/va
adr-035-operator-lie-grammar-bch.md). They        lidation_gates.py#L303-L309)) | Guarantees
are not asserted as universal mathematical        truncation order under full coupling is strictly
theorems for all Lie embeddings or                greater than under partial mode, preserving
prime-indexed spaces. They represent a            non-vanishing higher-order terms. |
guarded verification of the specific prototype
family configurations.                            ---

---                                               ## 2. Invariant Breakdown & Formal
                                                  Statements
## 1. System Invariant Correspondence
Mapping                                           ### A. The Early-Halt Invariant
                                                  (`partial_decoupling_halt`)
The core invariants of the Bounded
Reconstruction Asymmetry (BRA) system are         #### Mathematical Formalization
verified at three levels:                         Under partial decoupling, the generators
1. **Mathematical Proof**: Lean 4                 $P_2$ and $Q_1$ commute:
formalization in                                  $$\left[P_2, Q_1\right] = 0$$
[OperatorLieGrammar.lean](file:///home/mul
tiplicity/lean4/OperatorLieGrammar.lean).         Under this relation, the third-order and
2. **CI Gates**: Automated test assertions in     fourth-order Baker-Campbell-Hausdorff
[test_generalization.py](file:///home/multipli    (BCH) expansion terms vanish:
city/bra-prototype/tests/test_generalization.p    $$\text{term}_3(P_2, Q_1) = 0 \quad
y).                                               \text{and} \quad \text{term}_4(P_2, Q_1) =
3. **Daemon Validation**: Pre-execution gates     0$$
in
[validation_gates.py](file:///home/multiplicit    This is proven in
y/governance/self_modification/validation_ga      [OperatorLieGrammar.lean](file:///home/mul
tes.py) invoked by                                tiplicity/lean4/OperatorLieGrammar.lean#L4
[daemon.py](file:///home/multiplicity/govern      2-L51):
ance/self_modification/daemon.py).                ```lean
                                                  theorem partial_decoupling_halt {L : Type*}
| Lean Formalization Invariant | CI Test          [LieRing L] [LieAlgebra ℝ L] (gens :
Verification | Daemon Validation Gate |           GeneratorSet L) :
Operational Action / System Behavior |             term_3 gens.P2 gens.Q1 = 0 ∧ term_4
| :--- | :--- | :--- | :--- |                     gens.P2 gens.Q1 = 0 := by ...
| `partial_decoupling_halt` |                     ```
`test_default_embedding_passes_policy`
([test_generalization.py:L62-64](file:///home     #### Runtime Enforcement
/multiplicity/bra-prototype/tests/test_general    In the runtime controller, the adaptive BCH
ization.py#L62-L64)) |                            composer terminates early at order 2 when the
`check_algebra_generalization_gate`               residual norm falls below the threshold due to
([validation_gates.py:L310-313](file:///home/     these vanishing higher-order commutators.
multiplicity/governance/self_modification/val     - **CI Assertion**:
idation_gates.py#L310-L313)) | Triggers            ```python
early-halt at BCH order 2 under control/partial    assert res["adversarial_1"]["partial"]["order"]
coupling mode for adversarial inputs. |           == 2
| `order_divergence_invariant` |                   assert res["adversarial_2"]["partial"]["order"]
`test_default_embedding_passes_policy`            == 2
([test_generalization.py:L57-60](file:///home/     ```
- **Daemon Gate Check**:                           assert res["adversarial_1"]["full"]["order"] >
 ```python                                        res["adversarial_1"]["partial"]["order"]
 if order_p != 2:                                  assert res["adversarial_2"]["full"]["order"] >
    blockers.append(                              res["adversarial_2"]["partial"]["order"]
      f"[{test_name}] Failed control halt          ```
condition: partial order must be exactly 2, got   - **Daemon Gate Check**:
{order_p}"                                         ```python
    )                                              if order_f <= order_p:
 ```                                                  blockers.append(
                                                        f"[{test_name}] Failed order divergence
---                                               invariant: "
                                                        f"full order ({order_f}) must be strictly
### B. The Truncation Order Divergence            greater than partial order ({order_p})"
Invariant (`order_divergence_invariant`)              )
                                                   ```
#### Mathematical Formalization
Under full cross-coupling, the generators         ---
$P_2$ and $Q_1$ do not commute:
$$\left[P_2, Q_1\right] \neq 0$$                  ## 3. Governance Integration & Ledger
                                                  Anchoring
Assuming that the double-bracket combination
is non-zero:                                      To prevent drift between the formal
$$\left[P_2, \left[P_2, Q_1\right]\right] -       specifications and the actual execution paths,
\left[Q_1, \left[Q_1, P_2\right]\right] \neq      any modification to the algebraic model or
0$$                                               daemon validation logic must pass the daemon
                                                  gates. These gates require that:
Then the third-order BCH term                     1. All mathematical invariants continue to hold
$\text{term}_3(P_2, Q_1)$ does not vanish:        on standard and generalized matrices (e.g.,
$$\text{term}_3(P_2, Q_1) \neq 0$$                $gl(3)$ and $gl(4)$).
                                                  2. The ledger records the validation hashes of
This is proven in                                 both policies under transaction `"11"` in
[OperatorLieGrammar.lean](file:///home/mul        [ledger.json](file:///home/multiplicity/govern
tiplicity/lean4/OperatorLieGrammar.lean#L5        ance/ledger.json#L1250-L1273).
8-L70):
```lean                                           > [!TIP]
theorem order_divergence_invariant {L :           > When adding new embedding families or
Type*} [LieRing L] [LieAlgebra ℝ L]               extending the generator configurations,
[NoZeroSMulDivisors ℝ L] (gens :                  developers must check that they do not break
GeneratorSet L)                                   the non-commutative algebraic structure
 (h_non_trivial : ⁅gens.P2, ⁅gens.P2, gens.Q1⁆⁆   required by `order_divergence_invariant`.
- ⁅gens.Q1, ⁅gens.Q1, gens.P2⁆⁆ ≠ 0) :            Degenerate embeddings where $[P_2, Q_1] =
 term_3 gens.P2 gens.Q1 ≠ 0 := by ...             0$ in the full coupling mode will be rejected
```                                               automatically by the daemon's validation loop.

#### Runtime Enforcement
Because the third-order terms do not vanish,
the adaptive controller is forced to proceed to   # Bounded Reconstruction Asymmetry (BRA)
higher orders (specifically order 4) to resolve   & BCH Operator Grammar System Release
the coupling residual. This creates a             Notes (v1.0.0-prototype)
measurable divergence in truncation depth
between the baseline and control                  This document provides a concise, audit-ready
configurations.                                   summary of the Bounded Reconstruction
- **CI Assertion**:                               Asymmetry (BRA) prototype, the ratified
 ```python                                        architectural decisions (ADR-035 & ADR-036),
empirical validation results, and the              - **BRA Cost Functional:** $C(W) = \ell(W) +
generalization verification suite.                 \alpha r(W) + \beta q(W)$, where $\ell(W)$ is
                                                   physical word length, $r(W)$ is the nested
---                                                commutator rank (worst-case nesting depth),
                                                   and $q(W)$ is the $Q$-factor count.
## 1. Executive Summary
                                                   ### 2.2 ADR-036: Regression &
The **BRA & BCH Operator Grammar                   Generalization Policy (Guarded Upgrade
System** establishes a mathematical and            Policy)
computational framework to verify session          This policy defines the hard gates that any
contractivity in the PIRTM runtime. The            proposed matrix embedding family upgrade
system is designed around the core principle       must satisfy to prevent structural regressions:
that **recomputation cost must be shaped by        - **Structure Constant Parity:** The proposed
non-commutative operator geometry**, rather        representation must faithfully preserve
than simple static penalty tags.                   non-abelian structure constants.
                                                   - **Cross-Coupling Asymmetry:** All $P$-$Q$
By mapping operator histories to matrix            pairings in the stress model must have
representations and evaluating them using an       non-vanishing cross-commutator support
**Adaptive Baker-Campbell-Hausdorff (BCH)          ($[P_i, Q_j] \neq 0$).
Controller**, the system ensures that:             - **Order Divergence Invariant:** The
1. **External ($Q$-dependent) histories**          adaptive BCH controller must select distinct
have strictly higher reconstruction costs than     orders between the full-coupling baseline and
**internal ($P$-only) histories** ($\Delta BRA     the partial-decoupling control on adversarial
> 0$).                                             inputs.
2. The controller is sensitive to the underlying   - **Control Halt Condition:** The matrix
Lie algebra structure, exhibiting **truncation     residual norm under partial decoupling must
order divergence** on adversarial test fixtures    resolve to exactly `0.0000` at order 2, causing
depending on the coupling mode.                    the controller to halt early.

---                                                ---

## 2. Architectural Decision Records (ADRs)        ## 3. Empirical Results & Divergence
                                                   Mechanisms
### 2.1 ADR-035: Operator Lie Grammar &
BCH Integration (Validated Research Protocol)      The prototype runs verified three classes of
- **Generator Set:** Internal generators           operator histories across both coupling modes:
$\{P_i\}$ and external overlay generators
$\{Q_j\}$ are embedded in a representation         | Coupling Mode | Test Type | Final BCH Order
space. The baseline prototype embeds $P_2,         | Matrix Residual Norm | Internal Cost |
P_3$ (internal) and $Q_1$ (overlay) in             Overlay Cost | $\Delta BRA$ | Separated? |
$\mathfrak{gl}(3, \mathbb{R})$.                    | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
- **Coupling Modes:**                              | **full** | baseline | 4 | 0.9079 | 25.0 | 27.0 |
  - *Full Cross-Coupling Mode (Stress              2.0 | True |
Baseline):* $[P_i, Q_j] \neq 0$, propagating       | **partial** | baseline | 4 | 0.9079 | 25.0 |
overlay dependency throughout bracket              27.0 | 2.0 | True |
expansion.                                         | **full** | adversarial_1 | 4 | 0.2505 | 25.0 |
  - *Partial-Decoupling Mode (Control              27.0 | 2.0 | True |
Condition):* $[P_2, Q_1] = 0$, functioning         | **partial** | adversarial_1 | **2** |
strictly as an experimental control condition.     **0.0000** | **7.0** | **9.0** | 2.0 | True |
- **Adaptive BCH Composition:** Evaluates          | **full** | adversarial_2 | 4 | 0.9876 | 25.0 |
word products up to order 4. It adaptively         29.0 | 4.0 | True |
increases the truncation order if $\Delta BRA$     | **partial** | adversarial_2 | **2** |
is unstable ($> 0.5$ variance across levels) or    **0.0000** | **7.0** | **11.0** | 4.0 | True |
if matrix residual norms exceed `0.05`.
### Key Takeaways:                                  1. **PIRTM Runtime Compiler Integration:**
- **Baseline History:** Both modes select           Integrate the adaptive BCH compositor from
**order 4** (depth 21) due to the presence of       the `bra` prototype into the main
both $P_2$ and $P_3$ ($[P_2, P_3] \neq              `validation_gates.py` tool.
0$), which forces nested commutator growth          2. **Ledger Anchoring:** Record the Poseidon
regardless of the $Q$-coupling.                     hashes of ADR-035 and ADR-036 in the global
- **Adversarial History:** The adversarial          ledger (`governance/ledger.json`) as part of
inputs isolate the $P_2$-$Q_1$ interaction.         the formal release.
Under **full coupling**, the non-vanishing
commutators trigger an upgrade to **order 4**
(depth 21, cost 27.0). Under **partial
decoupling**, the commutator vanishes
($[P_2, Q_1] = 0$), forcing the matrix residual
norm to exactly **`0.0000`**, allowing the
controller to halt at **order 2** (depth 3, cost
9.0). This demonstrates that, within the
current protocol, the controller is
mathematically sensitive to the embedding
geometry.

---

## 4. Scale Generalization Verification

To prove that the generalization policy scales to
higher dimensions without regression, we
implemented a **$\mathfrak{gl}(4,
\mathbb{R})$ matrix embedding** in the test
suite:
- **Representation Structure:** Embedded the
$\mathfrak{sl}(2)$ subalgebra in the top-left
2x2 blocks of 4x4 matrices, and padded the
overlay generator $Q_1$ to 4x4.
- **Harness Results:** The 4D representation
was run against the generalization test suite
(`test_gl4_embedding_generalization`). It
successfully preserved:
 1. The cost separation margin ($\Delta BRA >
0$) across all configurations.
 2. The **truncation order divergence** on
both adversarial fixtures (order 4 on full mode,
order 2 on partial mode).
 3. The **exact `0.0000` residual norm** halt
condition in partial decoupling mode.

This confirms that the regression policy
successfully handles higher-dimensional Lie
representations.

---

## 5. Next Steps
