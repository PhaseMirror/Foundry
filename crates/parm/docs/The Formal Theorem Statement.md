The formal theorem statement and exchange‑lemma proof skeleton. That will crystallize the discovery into a stable mathematical result that can be referenced in any future paper or implementation. Once the proof is written, the corpus study becomes a straightforward empirical validation of the theorem’s predictions rather than an exploratory heuristic.

I will integrate your proof sketch into the PARM documentation and use it to justify the heuristic in the code. After the theorem is finalized, we can proceed directly to Phase 2 (corpus‑scale root study) using Open Scriptures Hebrew Lexicon.

Here is a clean theorem statement and an exchange‑lemma style proof skeleton that you can drop into the PARM documentation. I will write it at the level where you can later formalize it in a CAS or proof assistant if you wish.

***

## Setup and notation

Fix a finite multiset of positive primes $P = \{p_1,\dots,p_N\}$, where repetition is allowed. A **prime sequence** is an ordered tuple $(q_1,\dots,q_N)$ consisting of a permutation of the multiset elements of $P$.

Define the PARM sealed state by the recurrence (your numeric channel recurrence, but we suppress the “num” subscript):[^1]

- Seed: $V_1(q_1) = q_1^2$.
- Flow: for $2 \le k \le N-1$,

$$
V_k(q_1,\dots,q_k) = q_k\bigl(V_{k-1}(q_1,\dots,q_{k-1}) + q_k\bigr).
$$
- Seal:

$$
V_N(q_1,\dots,q_N) = q_N^2\bigl(V_{N-1}(q_1,\dots,q_{N-1}) + q_N\bigr). \tag{1}
$$

For a given multiset $P$, define

$$
V_{\max}(P) = \max\{V_N(q_1,\dots,q_N): (q_1,\dots,q_N) \text{ is a permutation of }P\},
$$

$$
V_{\min}(P) = \min\{V_N(q_1,\dots,q_N): (q_1,\dots,q_N) \text{ is a permutation of }P\}.
$$

We are interested in the **extremal ordering** problem: characterize the sequences that achieve these extrema.[^1]

***

## The extremal‑ordering theorem (informal statement)

Let $P$ be a multiset of positive primes with cardinality $N \ge 2$, and let

$$
a_1 \le a_2 \le \dots \le a_N
$$

be the non‑decreasing listing of elements of $P$ (each element repeated according to its multiplicity).[^1]

Define the sequences:

- **Maximizer candidate**:

$$
\mathbf{q}^{\max} = (a_{N-1},a_{N-2},\dots,a_1,a_N).
$$

That is, sort $P$ in descending order and move the largest element to the final position.
- **Minimizer candidate**:

$$
\mathbf{q}^{\min} = (a_2,a_3,\dots,a_N,a_1).
$$

That is, sort $P$ in ascending order and move the smallest element to the final position.

**Theorem (Extremal ordering for PARM sealed state).**
For every multiset $P$ of positive primes and $N \ge 2$:

1. The maximum sealed state value is attained at $\mathbf{q}^{\max}$:

$$
V_{\max}(P) = V_N(\mathbf{q}^{\max}).
$$
2. The minimum sealed state value is attained at $\mathbf{q}^{\min}$:

$$
V_{\min}(P) = V_N(\mathbf{q}^{\min}).
$$

In particular, there is a deterministic, $O(N\log N)$ procedure for computing $V_{\min}(P)$ and $V_{\max}(P)$, and hence the numeric PARM resonance $RQ_{\text{num}}$, without enumerating permutations.[^1]

**Comments:**

- When the multiset has repeated primes, any permutation consistent with the described pattern (largest class at the seal, second largest class at the seed, interior block sorted appropriately) is extremal; equal primes are interchangeable.
- For $N=1$, we define $V_{\min} = V_{\max} = p_1^2$; the theorem is then trivial and consistent with the pattern.

***

## High‑level proof strategy

The proof is naturally split into:

1. A **positional weight analysis**: show that the recurrence (1) makes the endpoints $q_1$ and $q_N$ contribute more strongly than interior positions, with the seal $q_N$ having the most leverage.
2. An **exchange lemma**: quantify how swapping two primes changes $V_N$, so that local “bubble” exchanges can be used to transform any sequence into the extremal form while monotonically increasing (for the max) or decreasing (for the min) the sealed state.
3. A **sorting argument**: show that iterated local exchanges converge to the claimed canonical patterns, and that no further exchange can improve or decrease the value.

I’ll sketch each of these separately.

***

## 1. Positional weight analysis (leading‑term intuition)

We can expand $V_N$ as a polynomial in the primes. What matters for ordering is not the exact closed form but the qualitative structure:

- Only $q_1$ and $q_N$ are squared.
- $q_N$ is squared in the outermost multiplicative factor, and that square multiplies the entire accumulated prefix $V_{N-1} + q_N$.
- Interior positions $q_2,\dots,q_{N-1}$ appear only linearly, although in products with other primes via the nested recurrence.[^1]

A leading‑term inspection (e.g., via induction) shows that the dominant monomial in $V_N$ has the form

$$
\text{(leading term)} \propto q_N^2 \cdot q_{N-1} \cdot q_{N-2} \cdots q_2 \cdot q_1^2,
$$

plus terms of strictly smaller total degree in at least one of the primes. This already suggests:

- To maximize $V_N$, you want larger primes at the ends (especially at $q_N$), and high values toward the outer positions.
- To minimize $V_N$, you want smaller primes at the ends (especially at $q_N$), and low values toward the outer positions.

The exchange lemma formalizes this intuition by showing that appropriate swaps of neighboring primes strictly increase or decrease $V_N$ unless you are already in the extremal configuration.

***

## 2. Exchange lemma (skeleton)

We give the structure for the **maximizing** case; the minimizing case is the order‑dual (replace “larger” by “smaller” and reverse inequalities).

**Lemma (Endpoint exchange, informal).**
Let $(q_1,\dots,q_N)$ be a prime sequence and let $a > b$ be two primes occupying positions $i$ and $j$, respectively. Suppose we move $a$ closer to an endpoint (toward position $1$ or $N$) and move $b$ inward correspondingly, keeping all other primes fixed. Then:

- If the swap moves $a$ from an interior position toward the seal or seed, $V_N$ strictly increases.
- If the swap moves $a$ away from both endpoints (deeper into the interior), $V_N$ strictly decreases.

**Sketch of why this is plausible:**

1. Fix all primes except a pair $q_i, q_j$ with $i<j$, and consider $V_N$ as a function of these two arguments. Plugging the recurrence (1) into itself, any local swap $(q_i,q_j) \mapsto (q_j,q_i)$ affects a subexpression of the form

$$
F(\dots,q_i,q_j,\dots) = A q_i q_j + B q_i + C q_j + D,
$$

with positive constants $A,B,C,D$ that depend on the other primes and positions but not on $q_i,q_j$ themselves. Crucially, the coefficient $A$ encodes how often a particular pair is multiplied together on the path toward the seal.[^1]
2. The exchange difference

$$
\Delta V_N = V_N(\dots,q_i,q_j,\dots) - V_N(\dots,q_j,q_i,\dots)
$$

can be expressed as a linear combination of terms like

$$
(q_i - q_j) \cdot \text{(positive function of the remaining primes)}.
$$

Because $q_i \neq q_j$ and all primes are positive, the sign of $\Delta V_N$ is determined by the sign of $q_i - q_j$ multiplied by a positional “weight difference” that depends on how far each index is from the endpoints.
3. One shows that the seal and seed positions have strictly larger “weight” than interior positions in this exchange metric. Thus swapping a larger prime closer to an endpoint increases $V_N$, while swapping it away from an endpoint decreases $V_N$.

Formally, you can structure this as:

- Define a positional weight function $w(k)$ that measures how often a prime at index $k$ appears in products inside the recurrence.
- Show $w(1)$ and $w(N)$ are maximal, and $w(k)$ decreases as you move toward the center.
- For any adjacent indices $k,k+1$, compute $V_N(\dots,q_k,q_{k+1},\dots) - V_N(\dots,q_{k+1},q_k,\dots)$ and show it has the same sign as $(w(k) - w(k+1))(q_k - q_{k+1})$.
- Therefore, when $w(k) > w(k+1)$, placing a larger prime at index $k$ and a smaller one at $k+1$ increases $V_N$; conversely, placing a smaller prime at index $k$ and a larger one at $k+1$ decreases $V_N$.

That gives you a local exchange law: you can locally “bubble” larger primes toward endpoints to increase $V_N$, and bubble smaller primes toward endpoints to decrease $V_N$.

***

## 3. Sorting argument to reach the extremal patterns

With the exchange lemma in hand, the rest of the proof is an ordering argument.

### Maximizer

1. Start with any permutation $(q_1,\dots,q_N)$ of $P$.
2. Apply endpoint‑directed exchanges:
    - While there exists a larger prime at an interior index closer to the seal than some smaller prime at a more interior index, swap them using the exchange lemma to increase $V_N$.
    - Similarly, move larger primes toward the seed at index $1$.
3. By monotonic improvement and finiteness (only finitely many permutations), this process terminates in a permutation where no local swap moving a larger prime closer to an endpoint can increase $V_N$. At that point:
    - The seal $q_N$ must contain a maximal prime of $P$; otherwise, there exists a larger prime elsewhere whose swap with $q_N$ would increase $V_N$.
    - The seed $q_1$ must contain a second‑maximal prime of $P$; an analogous argument applies.
    - The interior block $(q_2,\dots,q_{N-1})$ must be sorted in descending order; otherwise, an exchange of two misordered neighbors would increase $V_N$.
4. Therefore, the permutation has the form

$$
(q_1,\dots,q_N) = (a_{N-1},a_{N-2},\dots,a_1,a_N),
$$

possibly with some equal primes permuted among themselves, which does not change $V_N$. This is exactly $\mathbf{q}^{\max}$ up to ties.

### Minimizer

The minimizer case is the order‑dual:

- To decrease $V_N$, you move **smaller** primes toward endpoints.
- A descending‑weight exchange lemma shows that swapping smaller primes toward the seed and seal reduces $V_N$, and swapping them away increases it.
- Repeating the bubble process in the opposite inequality direction leads to:
    - $q_N$ holding a minimal prime.
    - $q_1$ holding a second‑minimal prime.
    - The interior block sorted in ascending order.

So the minimizing sequence is

$$
(q_1,\dots,q_N) = (a_2,a_3,\dots,a_N,a_1),
$$

again up to permutations among equal primes. That is exactly $\mathbf{q}^{\min}$.

***

## Edge cases and multiplicities

- For $N=1$, Seed and Seal coincide; $V_1(p_1) = p_1^2$, so $V_{\min} = V_{\max}$, and every sequence is trivially extremal.
- For $N=2$, one can check the theorem directly:

$$
V(q_1,q_2) = q_2^2(q_1^2 + q_2),
$$

which is clearly maximized by placing the larger prime at $q_2$ (seal) and minimized by placing the smaller prime at $q_2$. That matches the descending‑largest‑last and ascending‑smallest‑last patterns immediately.
- For multisets with repeated primes, equal primes are indistinguishable; any permutation consistent with “largest class at the seal, second‑largest class at the seed, interior block ordered appropriately” is extremal. The exchange lemma degenerates to equality when swapping equal primes.

***

## How to present this in the PARM documentation

You can structure the documentation section as:

1. **Definition** of the sealed state function $V_N$ and the extremal ordering problem.
2. **Theorem** (as above) with the clear algorithmic corollary:
    - Max: sort descending, rotate left by one (largest to seal).
    - Min: sort ascending, rotate left by one (smallest to seal).
3. **Proof sketch**:
    - Endpoint weight intuition.
    - Exchange lemma: swapping larger primes toward endpoints increases $V_N$.
    - Sorting argument: iterated local exchanges lead to the canonical extremal patterns.
4. **Empirical verification**:
    - State your 8,000+ random multiset trials for $3 \le N \le 6$ with 100% matches.
    - Note that for small $N$, you keep an optional $O(N!)$ exact fallback for regression testing.

That gives you a stable, citable statement for future papers and code comments.

If you’d like, the next step is to draft a short “Extremal Ordering Theorem” note (2–3 pages LaTeX) with this content and a slightly more detailed exchange‑lemma computation you can later formalize.
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^2][^20][^21][^3][^4][^5][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: Position_Aware_Recursive_Multiplicity__PARM__for_Hebrew_Roots.pdf

[^2]: https://github.com/albertqjiang/draft_sketch_prove

[^3]: https://github.com/google-deepmind/formal-conjectures

[^4]: https://github.com/sourceduty/Theorem_Proof/blob/main/README.md

[^5]: https://github.com/PierreSenellart/theoremkb

[^6]: https://github.com/leanprover-community/mathlib4/issues/6091

[^7]: https://github.com/zhaoyu-li/DL4TP

[^8]: https://github.com/albertqjiang/draft_sketch_prove/blob/main/aligned_problems/new_complete_mini.jsonl

[^9]: https://github.com/zhangir-azerbayev/proofnet

[^10]: https://github.com/zhaoyu-li/DL4TP/blob/main/README.md

[^11]: https://github.com/zhangir-azerbayev/ProofNet

[^12]: https://cmartinez.web.wesleyan.edu/documents/FP.pdf

[^13]: https://www.csd.uwo.ca/~abrandt5/teaching/DiscreteStructures/Chapter1/proofs.html

[^14]: https://ar5iv.labs.arxiv.org/html/2210.12283

[^15]: https://writings.stephenwolfram.com/2025/01/who-can-understand-the-proof-a-window-on-formalized-mathematics/

[^16]: https://arxiv.org/abs/2210.12283

[^17]: https://wenda302.github.io/assets/pdf/draft_sketch_and_prove_guiding.pdf

[^18]: https://www.cs.ru.nl/~freek/100/

[^19]: https://sites.math.washington.edu/~lee/Courses/441-2007/writing-proofs.pdf

[^20]: https://robertylewis.com/files/mathhorizons.pdf

[^21]: https://pmc.ncbi.nlm.nih.gov/articles/PMC4599631/

