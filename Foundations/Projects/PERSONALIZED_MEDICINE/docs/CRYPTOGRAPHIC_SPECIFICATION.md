# ADR-0037 Cryptographic Specification: BN254 Pedersen Commitment

---

## 1. BN254 Group Parameters & Coordinates

- **Base Field Prime $p$:**
  $$p = 21888242871839275222246405745257275088696311157297823662689037894645226208583$$
- **Scalar Field Prime $q$ (Subgroup Order):**
  $$q = 21888242871839275222246405745257275088548364400416034343698204186575808495617$$
- **Curve Equation:**
  $$y^2 \equiv x^3 + 3 \pmod p$$
- **Canonical Generator $G \in \mathbb{G}_1$:**
  $$G = (1, 2)$$

---

## 2. Hash-to-Curve Generator $H_{\text{new}}$

$H_{\text{new}}$ is derived using the deterministic try-and-increment algorithm with domain separator `"pedersen-H-v1"`:
1. $x = \text{OS2IP}(\text{SHA256}(\text{domain\_tag} \parallel \text{counter})) \bmod p$.
2. Check if $x^3 + 3$ is a quadratic residue modulo $p$.
3. Compute $y = (x^3 + 3)^{(p+1)/4} \bmod p$.
4. Check subgroup membership: $[q](x, y) = \mathcal{O}$.

**Published Coordinates (Counter = 3):**
- $x = 17046893880706576227302933567865952443575315085384610791585125865694746778660$
- $y = 1755007254862881281539676568778060098749136803913131228006521259868497891010$

---

## 3. Commitment Minting & Security Analysis

For value scalar $v = \text{OS2IP}(\text{SHA256}(\text{preimage})) \bmod q$ and secret blinding scalar $r \leftarrow \mathbb{F}_q$:
$$C_{\text{new}} = r G + v H_{\text{new}}$$

### A. Perfect Hiding (Information-Theoretic)
Since $r$ is sampled uniformly at random from $\mathbb{F}_q$, $r G$ is uniformly distributed over $\mathbb{G}_1$. Consequently, $C_{\text{new}}$ is statistically independent of $v$. Even an adversary with unbounded computational power cannot distinguish commitments of different values without $r$.

### B. Computational Binding (Under ECDLP)
If an adversary finds two distinct valid openings $(v, r)$ and $(v', r')$ with $v \neq v'$ such that:
$$r G + v H_{\text{new}} = r' G + v' H_{\text{new}}$$
then the discrete logarithm $\log_G H_{\text{new}}$ can be computed efficiently:
$$\log_G H_{\text{new}} = \frac{r - r'}{v' - v} \pmod q$$
Thus, binding reduces directly to the hardness of the Elliptic Curve Discrete Logarithm Problem (ECDLP) on $\mathbb{G}_1$ for BN254.
