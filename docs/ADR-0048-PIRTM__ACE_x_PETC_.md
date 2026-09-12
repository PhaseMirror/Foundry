                PIRTM — Core Technical Disclosure
                 Defensive Publication / Prior Art

              Ryan Van Gelder (PETC) & Tyler Van Osdol (ACE)

                                    Citizen Gardens

                                    August 28, 2026


                                        Abstract
    We present a complete, engineering-ready formulation of the Prime-Indexed Recursive
Tensor Model (PIRTM) integrated with the Arithmetic Control Engine (ACE) for safety
certificates and the Prime-Encoded Tensor Calculus (PETC) for lawful prime-weighted
structure. The core dynamics are affine-linear with a prime-decomposed gain operator.
We prove necessary and sufficient convergence conditions (spectral radius < 1), provide
sufficient ACE–PETC budget tests, give robustness and time-varying extensions, and supply
drop-in Python implementations including exact weighted-ℓ1 projection, monitoring utilities,
fixed-point estimators with certified tails, and adaptive margin control. Throughout we
adhere to the notational convention that the gain acts by operator application K T (not
tensor product), reserving ⊗ for true space tensor products.




                                             1
Contents
1 Introduction                                                                                    3

2 Notation and Setting                                                                             3

3 Core Recurrence: Scalar and Operator Forms                                                      3
  3.1 Scalar/Mode-wise Form . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       3
  3.2 Operator Form . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     3

4 Convergence Theory                                                                              4
  4.1 ACE–PETC Sufficient Test . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .        4
  4.2 Infinite-prime extension . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    4

5 Robustness and Time-Varying Systems                                                              4

6 ACE×PETC Integration                                                                             4

7 Algorithms and Reference Implementations                                                        5
  7.1 Exact weighted-ℓ1 projection (ACE) . . . . . . . . . . . . . . . . . . . . . . . . .        5
  7.2 Unified ACE–PETC update (scalar and operator cases) . . . . . . . . . . . . . .             6
  7.3 Monitoring and safety status . . . . . . . . . . . . . . . . . . . . . . . . . . . . .      7
  7.4 Fixed-point estimator with certified tail . . . . . . . . . . . . . . . . . . . . . . .     7
  7.5 Adaptive budget to maintain a target gap . . . . . . . . . . . . . . . . . . . . . .        8
  7.6 Infinite-prime convergence check (corrected) . . . . . . . . . . . . . . . . . . . . .      8
  7.7 Usage example (scalar case) . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     8
  7.8 Design Guidelines and Checklists . . . . . . . . . . . . . . . . . . . . . . . . . . .      9
  7.9 Conclusions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   9

8 Lightweight Scalar Friendly                                                                      9
  8.1 Notation and Setup . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     9
  8.2 Convergence and Safety . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       9
  8.3 PETC Typing: Prime Structure as Metadata . . . . . . . . . . . . . . . . . . . .            10
  8.4 Algorithm (ACE×PETC-compliant) . . . . . . . . . . . . . . . . . . . . . . . . .            10
  8.5 Practical Guidance . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    10
  8.6 Experimental Protocol (Preregistered) . . . . . . . . . . . . . . . . . . . . . . . .       11
  8.7 Related Work . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .    11
  8.8 Limitations . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   11
  8.9 Future Work . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     11

9 The Prime-Recursive Foundations of Mathematical Existence                                       11
  9.1 The Meta-Recursive Function (ACE×PETC Form) . . . . . . . . . . . . . . . . .               11
  9.2 PETC: Prime-Signature Ledger for Unambiguous Retrospection . . . . . . . . . .              12
  9.3 Interpretation as a Universal Constructor . . . . . . . . . . . . . . . . . . . . . .       12
  9.4 Examples of Emergent Structures . . . . . . . . . . . . . . . . . . . . . . . . . . .       13
  9.5 Refinements: Compression, Hierarchies, Causality, and Performance . . . . . . .             13
  9.6 ACE: Exact Weighted-ℓ1 Projection . . . . . . . . . . . . . . . . . . . . . . . . .         13
  9.7 Kernel-Level Multiplicity Scheduler . . . . . . . . . . . . . . . . . . . . . . . . . .     14
  9.8 Algorithms and Code (Runnable Sketches) . . . . . . . . . . . . . . . . . . . . . .         14
  9.9 Operational Checklist . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .     16

A Handy Design Bound for |k|                                                                      16



                                                 2
B Prime-Recursive Mechanical Stabilization: PETC × ACE Formalization                          16
  B.1 Prime-Signature Ledger (PETC) for Unambiguous Retrospection . . . . . . . . .           16
  B.2 Prime-Indexed Affine Recursion (ACE-Certified) . . . . . . . . . . . . . . . . . .      17
  B.3 Algorithms and Code Snippets . . . . . . . . . . . . . . . . . . . . . . . . . . . .    17
  B.4 Design Pattern and Examples . . . . . . . . . . . . . . . . . . . . . . . . . . . . .   19
  B.5 Takeaways (Operational Rules) . . . . . . . . . . . . . . . . . . . . . . . . . . . .   19


1     Introduction
PIRTM models the evolution of a tensor-valued state Tt under a prime-weighted linear operator
with an affine forcing term. To guarantee safe and predictable behavior, we combine:

• PETC: a structural layer that encodes prime indices, exponents and operator bounds bp ,
  producing a lawful ledger for {(p, α, bp )} and raw weights;

• ACE: a certification layer that enforces a contraction budget via exact weighted-ℓ1 projection
  and yields online certificates (contraction gap, rate upper bounds).

This report consolidates the mathematical foundation (convergence, robustness) and the production-
grade implementation (projection, monitoring and solvers).


2     Notation and Setting
Let (H, ∥·∥) be a Banach space suitable for the tensor Tt ∈ H. For a list of primes PN =
{p1 , . . . , pN } and bounded linear maps Bp : H → H with operator bounds ∥Bp ∥ ≤ bp , define
prime weights
                                   wp := Λp pα ,  α ∈ R, Λp ∈ R.
The gain operator is the (finite) sum
                    X                                              X
             K :=       wp Bp ,      acting by application (K X) =   wp Bp (X).
                   p∈PN                                                    p

We reserve ⊗ for explicit tensor products of spaces; we do not write K ⊗ T for the state update.


3     Core Recurrence: Scalar and Operator Forms
3.1   Scalar/Mode-wise Form
For each mode (m, n), the state obeys
                                                                         X
                 Tt+1 (m, n) = km Tt (m, n) + F (m, n),          km :=          Λm pα .       (1)
                                                                         p∈PN

This is a specialization of the operator model when each Bp acts as the identity on the (m, n)-
mode.

3.2   Operator Form
For the full tensor state Tt ∈ H we have
                                                   X
                     Tt+1 = F + K Tt ,     K=             wp B p ,   wp = Λp pα .             (2)
                                                   p∈PN




                                               3
4      Convergence Theory
Theorem 1 (Fixed point and convergence). Consider (2). The following are equivalent:
    (i) The spectral radius satisfies ρ(K) < 1.
    (ii) The operator (I − K) is invertible with Neumann series (I − K)−1 =               j converging
                                                                              P
                                                                                  j≥0 K
         in operator norm.
 (iii) For every T0 ∈ H, the sequence Tt+1 = F + K Tt converges to the unique fixed point
       T∞ = (I − K)−1 F with linear rate bounded by ∥K∥t .
Proof. (i) ⇒ (ii): If ρ(K) < 1, then there exists a submultiplicative operator norm with ∥K∥ < 1,
which yields the Neumann series. (ii) ⇒ (iii): Summation of K j F and the Banach fixed-point
theorem give uniqueness and linear convergence. (iii) ⇒ (i): If iterates converge for all T0 then
1 is not in the spectrum of K and ρ(K) < 1.
                                                                                  P
Corollary 2 (Scalar specialization). If each Bp = Id, then K = k Id with k = p wp . Conver-
gence holds iff |k| < 1, and the fixed point and rate are
                                   F
                           T∞ =       ,      |Tt − T∞ | ≤ |k|t |T0 − T∞ |.
                                  1−k

4.1     ACE–PETC Sufficient Test
A practical sufficient condition enforced by ACE with PETC bounds is
                                X
                                     bp |wp | < 1 − ε, (ε > 0),                                    (3)
                                p∈PN
                       P
which implies ∥K∥ ≤       p bp |wp | < 1 and hence ρ(K) < 1.


4.2     Infinite-prime extension
If PN ↑ P and p∈P bp |Λp | pα < 1 (e.g., α < −1 with bounded Λp and bp ), then the series for
              P
K converges absolutely in operator norm and all results above hold.


5      Robustness and Time-Varying Systems
Proposition 3 (Sensitivity of the fixed point). Let ∥K∥ ≤ 1−δ with δ ∈ (0, 1). For perturbations
∆K and ∆F with ∥∆K∥ < δ, the fixed point shifts by
               ∆T∞ = (I − K)−1 ∆F + (I − K)−1 ∆K (I − K)−1 F + O(∥∆K∥2 ),
so that ∥∆T∞ ∥ ≤ δ −1 ∥∆F ∥ + δ −2 ∥∆K∥ ∥F ∥ + . . ..
Theorem 4 (Uniform contraction for time-varying gains). Suppose Tt+1 = Ft + Kt Tt with
supt ∥Kt ∥ ≤ 1 − δ and bounded Ft . Then
                                                           1
                                ∥Tt ∥ ≤ (1 − δ)t ∥T0 ∥ +     sup ∥Fj ∥ ,
                                                           δ j≤t

so the system is BIBO-stable and tracks slowly varying fixed points with error O(δ −1 ).


6      ACE×PETC Integration
PETC (lawfulness). PETC supplies the prime-signature ledger {(p, α, bp )} and raw weights
wp = Λp pα . It also specifies admissible decay profiles in Λp when α ≥ −1 so that (3) still holds.

                                                  4
     ACE (safety). ACE enforces the weighted-ℓ1 budget (3) via a 1-Lipschitz projection (soft-
     thresholding by a common multiplier), preserving contraction margins. Online metrics: the
                             d = P bp |wp |, the gap gapLB = 1 − d
     contraction upper bound ∥K∥                                  ∥K∥, and a rate upper bound
                                    p
     SlopeUB = ∥K∥.
                 d


     7     Algorithms and Reference Implementations
     7.1    Exact weighted-ℓ1 projection (ACE)

     Algorithm 1 Weighted-ℓ1 projection by bisection
            P raw weights w, PETC bounds b, budget τ ∈ (0, 1)
     Require:
      1: if   i bi |wi | ≤ τ then
      2:    return w
      3: end if
      4: Set λ ∈ [0, maxi |wi |/ max(bi , ϵ)]
      5: while budget error > tol and iters < max do
      6:    wiproj ← sign(wi ) max(0, |wi | − λbi )
            budget ← i bi |wiproj |
                          P
      7:
      8:    Adjust λ by bisection to meet budget = τ
      9: end while
     10: return w proj


                         Listing 1: Exact weighted-ℓ1 projection (ACE budget)
     Python.
1    from typing import List
2    import numpy as np
3
4  def project_weighted_l1(w: List[float], b: List[float], tau: float,
5                          tol: float = 1e-9, max_iters: int = 80) -> List[float]:
 6     """
 7     Projects weights to exactly meet ACE budget via bisection.
 8     Returns projected w satisfying sum(b_i * |w_i|) tau.
 9     """
10     current_budget = sum(b_i * abs(w_i) for w_i, b_i in zip(w, b))
11     if current_budget <= tau:
12         return w.copy()
13

14         lo, hi = 0.0, max(abs(w_i) / max(b_i, 1e-15) for w_i, b_i in zip(w, b))
15         w_proj = w.copy()
16         for _ in range(max_iters):
17             lam = 0.5 * (lo + hi)
18             w_proj = [
19                 np.sign(w_i) * max(0.0, abs(w_i) - lam * b_i)
20                 for w_i, b_i in zip(w, b)
21             ]
22             budget = sum(b_i * abs(wi) for wi, b_i in zip(w_proj, b))
23             if abs(budget - tau) < tol:
24                 break
25             if budget > tau:
26                 lo = lam
27             else:
28                 hi = lam
29         return w_proj



                                                  5
     7.2    Unified ACE–PETC update (scalar and operator cases)

                       Listing 2: One PIRTM step with ACE×PETC certification
1    from typing import List, Callable, Dict, Tuple
2    import numpy as np
3

4    Tensor = np.ndarray
5    LinearOp = Callable[[Tensor], Tensor]
6
7
8  def ace_petc_step(T: Tensor, F: Tensor, primes: List[int], alpha: float,
9                    Lambda: List[float], B_ops: List[LinearOp] = None,
10                   b_p: List[float] = None, tau: float = 0.9
11                   ) -> Tuple[Tensor, Dict, Dict]:
12     """
13     One step of PIRTM recurrence with ACEPETC certification.
14     Returns: T_next, margins, debug
15     """
16     w_raw = [Lam_i * (p ** alpha) for p, Lam_i in zip(primes, Lambda)]
17
18         if B_ops is None:
19             # Scalar specialization
20             b_scalar = b_p if b_p is not None else [1.0] * len(primes)
21             w_proj = project_weighted_l1(w_raw, b_scalar, tau)
22             k_eff = sum(w_proj)
23             T_next = k_eff * T + F
24             margins = {
25                 "||K||": abs(k_eff),
26                 "gapLB": 1.0 - abs(k_eff),
27                 "contraction_rate": abs(k_eff),
28                 "budget_used": sum(b_i * abs(w_i) for w_i, b_i in zip(w_proj, b_scalar)),
29             }
30             debug = {"w": w_proj, "k_eff": k_eff, "w_raw": w_raw}
31             return T_next, margins, debug
32
33         # Operator case
34         assert b_p is not None and len(b_p) == len(primes)
35         w_proj = project_weighted_l1(w_raw, b_p, tau)
36
37         def K_operator(X: Tensor) -> Tensor:
38             Y = np.zeros_like(X)
39             for w_i, B_i in zip(w_proj, B_ops):
40                 Y = Y + w_i * B_i(X)
41             return Y
42
43         T_next = K_operator(T) + F
44         K_norm_upper = sum(abs(w_i) * bp for w_i, bp in zip(w_proj, b_p))
45         margins = {
46             "||K||_ub": K_norm_upper,
47             "gapLB": 1.0 - K_norm_upper,
48             "contraction_rate": K_norm_upper,
49             "budget_used": K_norm_upper,
50         }
51         debug = {"w": w_proj, "K_norm_ub": K_norm_upper, "K_operator": K_operator}
52         return T_next, margins, debug




                                                 6
     7.3     Monitoring and safety status

                              Listing 3: Real-time ACE margins monitor
1 class PIRTMMonitor:
2     """Real-time monitoring of ACEPETC safety margins"""
3     def __init__(self, tau: float = 0.9, window: int = 100, norm_fn=None):
4         self.tau = tau
5         self.window = window
6         self.norm_fn = norm_fn if norm_fn is not None else \
7             (lambda x: float(np.linalg.norm(np.asarray(x))))
8         self.history = {"K_norm": [], "gapLB": [], "T_diff": [], "sensitivity": []}
9
10         def update(self, margins: Dict, T_prev: Tensor, T_current: Tensor):
11             K_norm = margins.get("||K||", margins.get("||K||_ub", 0.0))
12             gap = margins.get("gapLB", 0.0)
13             self.history["K_norm"].append(K_norm)
14             self.history["gapLB"].append(gap)
15             self.history["T_diff"].append(self.norm_fn(np.asarray(T_current) - np.asarray(
           T_prev)))
16             self.history["sensitivity"].append(1.0 / max(gap, 1e-9))
17             for key in self.history:
18                 if len(self.history[key]) > self.window:
19                     self.history[key].pop(0)
20
21         def safety_status(self) -> Dict:
22             if not self.history["K_norm"]:
23                 return {"status": "NO_DATA"}
24             recent_K = float(np.mean(self.history["K_norm"][ -5: ]))
25             recent_gap = float(np.mean(self.history["gapLB"][ -5: ]))
26             if recent_K > self.tau:
27                 status = "VIOLATION"
28             elif recent_gap < 0.05:
29                 status = "CRITICAL"
30             elif recent_gap < 0.10:
31                 status = "WARNING"
32             else:
33                 status = "SAFE"
34             return {
35                 "status": status,
36                 "avg_contraction": recent_K,
37                 "avg_gap": recent_gap,
38                 "sensitivity": 1.0 / max(recent_gap, 1e-9),
39             }


     7.4     Fixed-point estimator with certified tail

                      Listing 4: (I - K)−1 F viaN eumannserieswithtailcertif icate
1 def fixed_point_estimate(F: Tensor,
2                          K_apply: LinearOp,
3                          K_norm_ub: float,
4                          tol: float = 1e-8,
5                          max_terms: int = 10_000) -> Tensor:
6     """Computes (I - K)^{-1} F via Neumann series; requires K_norm_ub < 1."""
7     assert K_norm_ub < 1.0, "Neumann series requires ||K|| < 1."
8     S = np.zeros_like(F)
9     term = F.copy()


                                                   7
10         tau = K_norm_ub
11         for j in range(max_terms):
12              S = S + term
13              tail_bound = (tau ** (j + 1)) * float(np.linalg.norm(np.asarray(F))) / (1 -
           tau)
14              if tail_bound <= tol:
15                  break
16              term = K_apply(term)
17         return S


     7.5     Adaptive budget to maintain a target gap

                       Listing 5: Simple adaptive policy for to keep a safety gap
1 def adapt_tau(tau: float, gapLB: float, gap_target: float = 0.1, eta: float = 0.5) ->
      float:
2     """If gapLB < target, move tau toward 1 - gap_target by factor eta."""
3     if gapLB < gap_target:
4         return (1 - eta) * tau + eta * (1.0 - gap_target)
5     return tau


     7.6     Infinite-prime convergence check (corrected)

                            Listing 6: Absolute convergence test for bp |p |p
1 def check_infinite_prime_convergence(alpha: float, Lambda_bound: float, b_bound: float
      ) -> bool:
2     """Returns True iff < -1 and bounds are finite and nonnegative."""
3     ok_bounds = np.isfinite(Lambda_bound) and np.isfinite(b_bound) and (Lambda_bound
      >= 0) and (b_bound >= 0)
4     return (alpha < -1) and ok_bounds


     7.7     Usage example (scalar case)

                 Listing 7: Scalar PIRTM loop with monitoring and fixed-point estimate
1 primes = [2, 3, 5, 7, 11]
2 alpha = -1.5
3 Lambda = [0.1] * len(primes)
4 F = 1.0

5 T = 0.0
6
7  monitor = PIRTMMonitor(tau=0.85)
8  for step in range(100):
 9     T_next, margins, debug = ace_petc_step(T, F, primes, alpha, Lambda, tau=0.85)
10     monitor.update(margins, T, T_next)
11     T = T_next
12     if step % 10 == 0:
13         status = monitor.safety_status()
14         print(f"Step {step}: {status[’status’]} (K={margins.get(’||K||’, 0):.3f}, gap
       ={margins[’gapLB’]:.3f})")
15

16 # Fixed point
17 k_eff = debug[’k_eff’]
18 T_inf = F / (1 - k_eff)
19 print(f"Fixed point: {T_inf:.6f}")




                                                   8
7.8    Design Guidelines and Checklists
• Choose α: start with α ∈ (−2, −1); adjust Λp to keep
                                                               P
                                                                   bp |wp | ≤ τ .

• Projection: always use the exact weighted-ℓ1 projection (not uniform scaling).

• Monitoring: log ∥K∥,
                  d gap 1 − ∥K∥,
                            d and ∥Tt+1 − Tt ∥.

• Safety margins: begin with τ ≤ 0.9; adapt using adapt tau only when margins erode.

• Infinite primes: ensure p bp |Λp |pα < 1 (e.g., α < −1 with bounded Λp , bp ), noting this is
                             P
  sufficient but not necessary.

7.9    Conclusions
The PIRTM dynamics combined with ACE and PETC yield a contractive, well-conditioned, and
monitorable system. The theory (spectral radius criterion, budget-based sufficiency) aligns exactly
with the provided implementations (projection, monitors, fixed-point estimation), enabling
reliable deployment.


8     Lightweight Scalar Friendly
We study a prime-indexed linear iteration for tensors,

                                     Tt+1 = F + k Tt ,    k ∈ R,

and show that convergence is guaranteed iff |k| < 1. “Prime structure” is treated as a
dictionary (representation/regularization) and as typing metadata via the Prime-Encoded
Tensor Calculus (PETC; Ryan Van Gelder) [?], rather than as a physical law. Stability
and safety are certified with a 1-Lipschitz projection from the Arithmetic Control Engine
(ACE; Tyler Van Osdol) [?]. We replace universal constants with explicit budgets, move
speculative physics to future work with a parameter-identification plan, and add a preregistered
experimental protocol.

8.1    Notation and Setup
Let (, ∥·∥) be a real Banach space (e.g., ℓ2 coefficients under a fixed dictionary). Fix a finite prime
set PN = {p1 , . . . , pN }. A prime dictionary is a collection = {ϕp }p∈PN ⊂ used for expansions
and penalties; we make no basis/completeness claim. For external drive F ∈, define the scalar
gain                                   X
                                 k =       Λp pα ,      Λp ∈ R, α ∈ R.                               (4)
                                     p∈PN

Older drafts used a single Λ; here we allow per-prime Λp .

8.2    Convergence and Safety
Theorem 5 (Convergence ⇔ contraction). Let T (X) = F + kX on . If |k| < 1, then for any
T0 ,
                                              1
                               Tt → T∞ =         F,
                                           1−k
with linear rate |k|.

Proof. We have ∥T (X) − T (Y )∥ = |k| ∥X − Y ∥. If |k| < 1, T is a contraction; apply Banach’s
fixed-point theorem [?].


                                                   9
Lemma 6 (One sufficient route to |k| < 1). If Λp ≥ 0 and α < −1, then

                                      X                              N
                                                                      X
                              |k| =          Λp pα ≤        max Λp          pαi .
                                                             p
                                      p∈PN                            i=1

Choosing maxp Λp small enough makes |k| < 1. (Sufficient, not necessary.)

ACE safety wrapper (spectral certification). Let S ⊂ be a safety/regularization set
(e.g., a weighted-ℓ1 ball on dictionary coefficients). Let ΠS be the Euclidean projection onto S
(1-Lipschitz). The ACE-wrapped update
                                                            
                                      Tt+1 = ΠS F + k Tt                                      (5)

has global Lipschitz constant ≤ |k|; thus |k| < 1 gives a certified contraction and feasibility
Tt ∈ S for all t.

8.3    PETC Typing: Prime Structure as Metadata
            P
Expand T = p∈PN wp ϕp . Each coefficient wp carries a PETC “prime type” tag [?]. We impose
a prime-mix budget          X
                                bp |wp (T )| ≤ τ,      bp > 0,                         (6)
                                 p∈PN

which is enforced via the projection ΠS (weighted soft-thresholding on wp ). Optional prime
gating gp (α, Λp ) = Λp pα modulates proposals but is bounded by the same budget; no “universal
constant” is assumed.

8.4    Algorithm (ACE×PETC-compliant)
Inputs. F , dictionary {ϕp }, weights {Λp }, exponent α, budget (bp , τ ).

 1. Gain synthesis. Compute k from eq. (4). If |k| ≥ 1, shrink Λp and/or PN until |k| < 1.
                                   P
 2. Projection set. Define S = {T : p bp |wp (T )| ≤ τ }. Use ΠS (1-Lipschitz).

 3. Iteration. Tt+1 = ΠS (F + kTt ) as in eq. (5).

 4. Stopping. Stop when ∥Tt+1 − Tt ∥ ≤ ε; output T∞ .

Properties. Certified convergence (theorem 5), feasibility (ACE), and auditable prime composition
(PETC).

8.5    Practical Guidance
Choosing α, Λp , PN . Pick PN by model/compute budget; start with α ∈ (−2, −1) and uniform
Λp = Λ; use theorem 6 to get a safe Λ with margin ε ∈ [0.1, 0.3]; tune (bp , τ ) and re-check |k| < 1.
                                           P
Diagnostics. Track |k|, budget usage          bp |wp |, and prime-mix histograms per iteration. If
convergence slows, reduce |k|, tighten τ , or shrink PN .




                                                   10
8.6   Experimental Protocol (Preregistered)
Benchmarks. MSD-PrimeMix (multi-scale disturbances with controlled prime-spread).
Baselines. LQR (if model known), projected gradient with fixed step, Adam; RL baseline (e.g.,
TD3/DQN as applicable).
Metrics. Task cost, settling time, safety-violation count, robustness vs. disturbance ampli-
tude/sparsity; report mean±95% CI over 10 seeds.
Ablations. With/without ACE; with/without PETC budget; vary α at fixed |k|; expand/shrink
PN .
Reporting. Publish code/configs; include certificate traces (GapLB, SlopeUB).

8.7   Related Work
Contractions and projection operators are classical [?]; proximal methods and Lipschitz pro-
jections connect to the modern optimization toolkit [?]. Weighted ℓ1 projections and soft-
thresholding date to wavelet shrinkage [?] and LASSO [?]. Prime-indexed dictionaries fit within
sparse coding and dictionary learning [?, ?, ?]. Lipschitz-controlled neural networks relate via
Parseval regularization [?] and spectral normalization [?]. The ACE and PETC frameworks
formalize safety via contraction certificates and structural typing, respectively [?, ?].

8.8   Limitations
The linear core is intentional; nonlinear variants require fresh contraction proofs (local or global).
Dictionary choice is application-dependent; performance hinges on whether {ϕp } captures salient
structure.

8.9   Future Work
Operator learning. Learn diagonal-plus-low-rank operators in the prime dictionary with
PETC regularizers; verify a contraction region.
Physical identification. Units-consistent maps from data to (Λp , α) with uncertainty quantifi-
cation.
Nonlinear plants. ACE-style sector-bounded contractions and piecewise certificates.


9     The Prime-Recursive Foundations of Mathematical Existence

A central question is whether diverse structures—algebraic, topological, or computational—can
be generated by a single, prime-based, recursive mechanism. We formalize this as a meta-
recursive prime-indexed constructor that is both auditable (PETC: unambiguous retrospection)
and stable (ACE: certified contraction).

9.1   The Meta-Recursive Function (ACE×PETC Form)
Let PN = {p1 , . . . , pN } be the first N primes. Let H be a Banach space of (typed) tensors. For
each prime p ∈ PN choose a bounded linear channel Bp : H → H with ∥Bp ∥ ≤ bp . Define prime
weights
            wp = Λp pα , Λp ∈ R (typically Λp ≥ 0), α < −1 (sufficient decay).
The gain operator and the meta-recursion are
                         X
                    K=       wp Bp ,    Tt+1 = M(PN ; Tt ) := F + K Tt .                          (7)
                            p∈PN




                                                 11
                                      (m,n)
This refines the informal sum p Λ pα Tp
                             P
                                             into an operator form while keeping primes explicit
as independent channels.       P                                    P
    [ACE Contraction Budget]     p∈PN |wp | bp < 1     =⇒ ∥K∥ ≤ p |wp |bp < 1.

Theorem 7 (Convergence & Fixed Point). Under Assumption B.2, the affine map T 7→ F + KT
is a strict contraction on (H, ∥ · ∥). Hence there exists a unique fixed point

                                       T∞ = (I − K)−1 F,

and for any T0 one has linear convergence ∥Tt − T∞ ∥ ≤ ∥K∥ t ∥T0 − T∞ ∥. In the scalar special
                                                    F
case (T ∈ R, K = k ∈ (−1, 1)) this reduces to T∞ = 1−k .

Theorem 8 (Uniqueness & Stability under Projection). Let ΠS be a nonexpansive projection
(e.g., a convex projection) and consider the projected recursion
                                                          
                                      Tt+1 = ΠS F + KTt .

If Assumption B.2 holds, then T 7→ ΠS (F + KT ) is also a contraction with constant ≤ ∥K∥ < 1;
therefore it admits a unique fixed point in S and the iteration converges linearly to it.

Remark 9 (Safe Design Regime for Prime Weights). A sufficient (not necessary) recipe: choose
α < −1, Λp ≥ 0, and cap Λp ≤ Λ̄ so that p∈PN Λp pα bp < 1. Increasing N or tightening Λ̄
                                        P
preserves the margin.

9.2   PETC: Prime-Signature Ledger for Unambiguous Retrospection
Let P be the set of primes. A prime signature is a finitely supported vector e = (ep )p∈P ∈ Z(P) .
Define the multiplicity map                 Y
                                   M (e) =     pep ∈ Q>0 .
                                               p

Composition of interactions is e + e′ (multiset union); undo/consumption is e − e′ ; dualization is
−e. Unique factorization makes the history canonical: ep = vp (M (e)) records how many times
the p-tagged event occurred.

Definition 10 (Conservation Certificate). For any
                                              P typed operation with inputs X1 , . . . , Xr and
output Y , PETC conservation requires e(Y ) = ri=1 e(Xi ). A system is ledger-consistent if the
equality holds for all executed operations.

Proposition 11 (Lossless Retrospection). If a system is ledger-consistent, then for every state
the accumulated signature e determines the exact multiset of prime-tagged interactions that
occurred, via ep = vp (M (e)).

Complexity. Maintain e as a sparse map (prime 7→ exponent). Updates/audits run in
O(|supp(e)|)—no integer factorization is needed.

9.3   Interpretation as a Universal Constructor
Recursive self-modification. The assignment Tt+1 = M(PN ; Tt ) mirrors prior states via K,
with uniqueness/convergence guaranteed by Theorems 7–8.
   Structure emergence. Choosing F (drive) and {Bp } (channels) yields a wide class of
constructs: neural weights, quantum states, algebraic operators, or kernel process states.
   Universality (within H). Iteration converges to T∞ = (I − K)−1 F ; by selecting F and
{Bp } appropriately, one can encode a broad family of objects in tensor space.



                                                12
9.4   Examples of Emergent Structures
   1. Algebraic Systems. Let Bp be structured projectors/sparsity masks; F encodes a
      group/semiring operation tensor. Contraction yields stable algebraic updates.

   2. Topological/Geometric Bases. Choose Bp as basis selectors; prime indices organize
      connectivity. Stable decompositions follow from Theorem 7.

   3. Tensor Networks. Let Bp act on tensor cores/edges; the fixed point realizes a high-
      dimensional network with controlled growth.

   4. Reinforcement Learning. Take T as weights, F as TD/gradient drive, and Bp as feature
      filters. Stability ensures convergent Q/policy updates.

   5. Kernel-Level Scheduling. Model dispatch channels as Bp and resource demand as F
      for a multiplicity-driven scheduler (Section 9.7).
                                                                     Q
Theorem 12 (Fractal Stability via Prime-Indexed IFS). If H = j Hj with componentwise
contractions {T 7→ F + KT } whose constants are < 1, then the induced self-map on H is a
contraction; the unique attractor T∞ is the limit of a prime-indexed iterated function system
(IFS). Hierarchical prime partitioning induces self-similar structure in the limit.

9.5   Refinements: Compression, Hierarchies, Causality, and Performance
Signature compression
                    P     (checkpointing). At epoch k, store ck ← e and reset e ← 0. The
rolled signature e = k ck + e equals the uncheckpointed signature, preserving audits exactly.
                                                                                      P
Exact/approximate/log-space
                          P         conservation.   Prefer exact  exponent   equality
                                                                              P P      i e(Xi ) =
P ). For noise, allow ∥ i e(Xi )−e(Y )∥∞ ≤ ε. If only M (e) is accessible, use i p ep (Xi ) log p ≈
e(Y
  p ep (Y ) log p with tolerance η.


Hierarchical
P                rollups. For a module tree T with local signatures e[u], define E[u] = e[u] +
  v∈Children(u) E[v]. If primitives are conservative, then E[u] matches u’s external interface;
conservation at the root implies global conservation.

Causality (optional). Augment PETC with a DAG G = (V, E); label each edge with its prime
increment. The justification set for a node (state) is the multiset union along any source–node
path; its signature equals the state’s PETC signature.

9.6   ACE: Exact Weighted-ℓ1 Projection
          P
WePenforce p bp |wp | ≤ τ < 1 via the exactP
                                           projection onto the weighted ball. Let zp = bp |wp |.
If p zp ≤ τ return w; else find θ ≥ 0 with p max(zp − θ, 0) = τ and set

                                                   max(zp − θ, 0)
                                 wp⋆ = sign(wp )                  .
                                                        bp

This is the weighted analogue of soft-thresholding; θ can be found by sorting {zp } and a
cumulative scan.




                                               13
9.7    Kernel-Level Multiplicity Scheduler
Associate each queue/class with a prime p; maintain
                                                 PPETC signatures per process and per core.
Use ACE to allocate per-prime weights wp under      bp |wp | ≤ τ < 1; update dispatch decisions
via Tt+1 = F + KTt where T aggregates runnable-state indicators and F encodes exogenous
demand. PETC provides exact provenance for merges/splits; ACE maintains stability and
responsiveness through budgeted adjustments.

9.8    Algorithms and Code (Runnable Sketches)
PETC prime ledger with checkpointing and exact conservation.

class PrimeLedger:
    def __init__(self):
        self.sig = {}                # dict[int -> int], sparse exponents e_p
        self.checkpoints = []        # list[dict[int -> int]]

      def add_event(self, p: int, mult: int = 1, sign: int = +1):
          self.sig[p] = self.sig.get(p, 0) + sign * mult
          if self.sig[p] == 0: self.sig.pop(p)

      def checkpoint(self):
          self.checkpoints.append(self.sig.copy())
          self.sig.clear()

      def rolled_signature(self):
          roll = {}
          def add_map(dst, src, sgn=+1):
              for p, e in src.items():
                  dst[p] = dst.get(p, 0) + sgn * e
                  if dst[p] == 0: dst.pop(p)
          for ck in self.checkpoints: add_map(roll, ck, +1)
          add_map(roll, self.sig, +1)
          return roll

def conservation_ok_exact(inputs, out) -> bool:
    acc = {}
    def add(dst, src, sgn=+1):
        for p, e in src.items():
            dst[p] = dst.get(p, 0) + sgn * e
            if dst[p] == 0: dst.pop(p)
    for L in inputs: add(acc, L.rolled_signature(), +1)
    add(acc, out.rolled_signature(), -1)
    return len(acc) == 0

Optional log-space surrogate (tolerant).

import math

def log_signature(sig: dict[int,int]) -> float:
    return sum(e * math.log(p) for p, e in sig.items())

def conservation_ok_log(inputs, out, eta: float = 1e-9):

                                              14
   lhs = sum(log_signature(L.rolled_signature()) for L in inputs)
   rhs = log_signature(out.rolled_signature())
   return abs(lhs - rhs) <= eta

ACE exact weighted-ℓ1 projection and prime-indexed operator.

import math
import numpy as np

def project_weighted_l1(w: dict[int,float], b: dict[int,float], tau: float):
    z = {p: b[p] * abs(w[p]) for p in w}
    S = sum(z.values())
    if S <= tau: return w
    items = sorted(z.items(), key=lambda kv: kv[1], reverse=True)
    cumsum, theta = 0.0, 0.0
    for k, (_, zk) in enumerate(items, start=1):
        cumsum += zk
        theta = (cumsum - tau) / k
        if k == len(items) or items[k][1] <= theta < items[k-1][1]:
            break
    w_star = {}
    for p in w:
        val = max(z[p] - theta, 0.0) / max(b[p], 1e-12)
        w_star[p] = math.copysign(val, w[p])
    return w_star

class PrimeAffine:
    def __init__(self, B_ops: dict[int, callable], b_norms: dict[int,float], tau: float = 0.
        self.B = B_ops     # p -> H->H
        self.b = b_norms   # p -> ||B_p||
        self.tau = tau
        self.w = {p: 0.0 for p in B_ops}

   def set_weights(self, Lambda: dict[int,float], alpha: float):
       w = {p: Lambda.get(p, 0.0) * (p ** alpha) for p in self.B}
       self.w = project_weighted_l1(w, self.b, self.tau)

   def K_apply(self, T):
       acc = 0 * T
       for p, Bp in self.B.items():
           acc = acc + self.w[p] * Bp(T)
       return acc

   def step(self, T, F):
       return F + self.K_apply(T)

End-to-end loop (with PETC logging and ACE budget check).

def run_loop(T0, F, prime_affine: PrimeAffine, ledger: PrimeLedger,
             prime_of_update: int, steps: int = 100):
    T = T0
    for t in range(steps):

                                      15
          ledger.add_event(prime_of_update, mult=1, sign=+1)   # PETC log
          T_next = prime_affine.step(T, F)                     # ACE step
          budget = sum(abs(prime_affine.w[p]) * prime_affine.b[p] for p in prime_affine.w)
          assert budget < 1.0, "ACE budget violated: not a contraction"
          T = T_next
      return T

9.9    Operational Checklist
    1. Ledger (PETC). Assign primes to components/events; maintain signatures additively;
       enforce conservation. Use checkpointing and hierarchical rollups for scale; optionally attach
       a causality DAG.

    2. Weights (ACE). Set wp = Λp pα with α < −1 (sufficient) and project onto
                                                                                        P
                                                                                            bp |wp | ≤
       τ < 1 via weighted-ℓ1 projection.
                                         P
    3. Certificates. Monitor budget         bp |wp |, and (optionally) gap/slope margins during
       learning.

    4. Convergence. By Theorems 7–8, Tt+1 = F + KTt (or its projected form) converges
       uniquely to a fixed point at rate ∥K∥.


A      Handy Design Bound for |k|
For uniform Λp = Λ and α < −1,
                                                      N
                                                      X
                                           |k| = Λ          pαi .
                                                      i=1

Solve |k| = 1 − ε for Λ to initialize with margin ε.

Reproducibility Checklist (suggested). Provide code/configs; fix seeds; publish CSV logs
for |k|, budget usage, and certificate traces; include README with environment and commit
hash.


B      Prime-Recursive Mechanical Stabilization: PETC × ACE
       Formalization
Attribution. ACE (Arithmetic Control Engine): Tyler Van Osdol.              PETC (Prime-Encoded
Tensor Calculus): Ryan Van Gelder.

B.1     Prime-Signature Ledger (PETC) for Unambiguous Retrospection
Let P denote the set of primes. A prime signature is a finitely supported vector e ∈ Z(P) ; we
write e = (ep )p∈P with ep = 0 for all but finitely many p. Define the multiplicity map
                                                Y
                                    M (e) =        pep ∈ Q>0 .
                                                p∈P

Operations are componentwise: composition of events is e + e′ , undo/consumption is e − e′ ,
dualization is −e. This realizes the slogan “multiply primes now, factor later ” as add exponents
now, read them later : unique factorization ensures that e (hence the full interaction multiset) is
recoverable without ambiguity.


                                                  16
Definition 13 (Conservation Certificate). For any typed operation Φ
                                                                  Pwith   inputs X1 , . . . , Xr
                                                                    r
and output Y , the PETC conservation check requires e(Y ) =         i=1 e(Xi ). A system is
ledger-consistent if the equality holds for all executed Φ.

Proposition 14 (Lossless Retrospection). If a system is ledger-consistent, then for every state
the accumulated signature e determines the exact multiset of prime-tagged interactions that
occurred (with multiplicities), via the valuation ep = vp (M (e)).

Complexity. Maintain e as a sparse map (prime 7→ exponent). Updates and audits are
O(|supp(e)|); no integer factorization is required.

B.2    Prime-Indexed Affine Recursion (ACE-Certified)
Let H be a Banach space of tensors (axes carry PETC types). For each prime p choose a
bounded linear “channel” Bp : H → H with ∥Bp ∥ ≤ bp . Choose per-prime weights wp = Λp pα
(design knob: Λp ∈ R, typically Λp ≥ 0, and α < −1 for decay). Define the gain operator
                                X                       X
                         K =        wp B p ,   ∥K∥ ≤        |wp | bp .
                                 p∈PN                      p∈PN

The meta-recursion is the affine map

                                        Tt+1 = F + K Tt ,                                       (8)

which collapses your original sumX
                                 into an operator form while keeping primes as explicit channels.
   [ACE Contraction Budget]         |wp | bp < 1.
                                p∈PN

Theorem 15 (Fixed Point, Uniqueness, and Linear Rate). Under Assumption B.2, the recursion
(8) is a strict contraction on (H, ∥ · ∥). Hence there exists a unique fixed point T∞ = (I − K)−1 F
and for any T0
                                 ∥Tt − T∞ ∥ ≤ ∥K∥ t ∥T0 − T∞ ∥.
                                                            F
In the scalar special case T ∈ R and K = k ∈ (−1, 1), T∞ = 1−k .

Remark 16 (Safe Design Regime). AP  sufficient (not necessary) recipe is α < −1, Λp ≥ 0, and
a global cap Λp ≤ Λ̄ chosen so that p∈PN Λp pα bp < 1. Increase N or tighten Λ̄ to keep the
margin.

ACE Safety Certificates. Let δS > 0 be a certified lower bound on the system’s stability
gap in the absence of K, and let Lp bound the local schedule slope contributed by channel Bp .
Define                              X                               X
              GapLB(w) := δS − 2       bp |wp |,   SlopeUB(w) :=        Lp |wp |.
                                       p∈PN                            p∈PN

Operate under the constraints GapLB(w) > 0 and SlopeUB(w) < 1. These provide online,
quantitative margins for stability and non-expansiveness during learning.

B.3    Algorithms and Code Snippets
PETC Prime Ledger (lossless history).

class PrimeLedger:
    def __init__(self):
        self.sig = {} # dict[int -> int], sparse exponents e_p


                                                17
    def add_event(self, p: int, mult: int = 1, sign: int = +1):
        # sign=+1 for occurrence, -1 for consumption/undo
        self.sig[p] = self.sig.get(p, 0) + sign * mult
        if self.sig[p] == 0:
            self.sig.pop(p)

    def valuation(self, p: int) -> int:
        return self.sig.get(p, 0)

    def multiplicity_Q(self):
        # returns numerator, denominator of product p^{e_p}
        num, den = 1, 1
        for p, e in self.sig.items():
            if e >= 0: num *= p ** e
            else:      den *= p ** (-e)
        return num, den

def conservation_ok(inputs, output) -> bool:
    # Check PETC conservation: sum(e_in) == e_out
    acc = {}
    def add_into(dst, src, sgn=+1):
        for p, e in src.sig.items():
            dst[p] = dst.get(p, 0) + sgn * e
            if dst[p] == 0: dst.pop(p)
    for L in inputs: add_into(acc, L, +1)
    add_into(acc, output, -1)
    return len(acc) == 0

ACE-Certified Affine Update with Budget Projection.   P           We implement a simple (con-
servative) weighted-ℓ1 shrinkage to enforce the budget p bp |wp | ≤ τ < 1. Replace shrink wl1
with an exact weighted-ℓ1 projection if needed.

import numpy as np

def shrink_wl1(w, b, tau):
    # Conservative shrink: scale if the budget is exceeded
    # w, b are dict[int->float]. Returns dict[int->float].
    budget = sum(abs(w[p]) * b[p] for p in w)
    if budget <= tau: return w
    scale = tau / budget
    return {p: scale * w[p] for p in w}

class PrimeAffine:
    def __init__(self, B_ops, b_norms, tau=0.9):
        # B_ops: dict[int -> callable H->H], b_norms: dict[int->float] with ||B_p||<=b_p
        self.B = B_ops
        self.b = b_norms
        self.tau = tau
        self.w = {p: 0.0 for p in B_ops} # start neutral

    def set_weights(self, Lambda, alpha):
        # Lambda: dict[int->float], alpha< -1 recommended

                                             18
         w = {p: Lambda.get(p, 0.0) * (p ** alpha) for p in self.B}
         self.w = shrink_wl1(w, self.b, self.tau) # enforce ACE budget

      def K_apply(self, T):
          acc = 0 * T
          for p, Bp in self.B.items():
              acc = acc + self.w[p] * Bp(T)
          return acc

      def step(self, T, F):
          # One affine contraction step: T_{t+1} = F + K T_t
          return F + self.K_apply(T)

End-to-End Loop with Ledger and Stability Checks.
def run_loop(T0, F, prime_affine, ledger, prime_of_update, steps=100):
    T = T0
    for t in range(steps):
        # Log the update event in PETC:
        ledger.add_event(prime_of_update, mult=1, sign=+1)

         # ACE contraction step:
         T_next = prime_affine.step(T, F)

         # Optional: online margin monitoring
         budget = sum(abs(prime_affine.w[p]) * prime_affine.b[p] for p in prime_affine.w)
         assert budget < 1.0, "ACE budget violated: not a contraction"

          T = T_next
      return T

B.4    Design Pattern and Examples
  • RL / Control. Let T be a weight tensor (e.g., linear Q or policy params), F the
    external drive (TD target / gradient),
                                       P and Bp prime-typed feature filters. PETC logs every
    gradient/apply step; ACE ensures       bp |wp | < 1 for stable convergence to T∞ .
  • Tensor Networks / Algebraic Systems. Choose Bp as structured projectors or sparsity
    masks whose norms are known. PETC ensures typed contractions respect multiplicity
    conservation; ACE budgets keep the build-up stable.
  • Auditing & Replay. Given a terminal signature e, valuations ep give exact interaction
    counts (multiset multiplicities). The system can replay or attribute decisions without
    ambiguity.

B.5    Takeaways (Operational Rules)
  1. Ledger: assign each component/event a prime; update signatures additively; enforce
     PETC conservation.
  2. Weights: set wp = Λp pα with α < −1 (sufficient) and cap Λp to satisfy
                                                                            P
                                                                              |wp |bp < 1.
  3. Certificates: monitor GapLB(w) > 0 and SlopeUB(w) < 1 online.
  4. Convergence: Tt+1 = F + KTt contracts to T∞ = (I − K)−1 F with linear rate ∥K∥.

                                            19
References
[1] Ryan O. Van Gelder. The universal multiplicity constant (λm ): Prime-encoded recursive
    structures in physics and computation. Citizen Gardens - The Foundation of Multiplicity,
    2024. Preprint - PrimeAI Enhanced Template.

[2] Martin Gibson. Construction of the natural numbers from a real exponential field. Private
    Research Publication, 2007. All Rights Reserved.

[3] Martin Gibson. Defining a unification gauge on the inertial field. Private Research Publication,
    2024. All Rights Reserved.

[4] Martin Gibson and Ryan O. Van Gelder. Prime spin compute paradigm: Integrating
    fibonacci/lucas sequences, the golden mean, prime encoding, and quantum ai. Citizen
    Gardens – The Foundation of Multiplicity, Preprint, 2024.

[5] Tyler Van Osdol. Dynamic k, ray tracing and black hole halos. Intergalactic Quantum
    Research Society, 2024. Minor revisions from first posting, November 6, 2024.

[6] Tyler Van Osdol. Formal proof and empirical validation of the dynamic K framework for
    gravitational lensing. Citizen Gardens – The Foundation of Multiplicity, Preprint, 2024.

[7] Tyler Van Osdol. Ray tracing and dark matter halos: A tensor-based quantum gravity
    approach. Citizen Gardens – The Foundation of Multiplicity, Preprint, 2024.

[8] Miroslav Zidek. Integrating pythagorean triplets and fibonacci sequences with multiplicity
    theory. Citizen Gardens – The Foundation of Multiplicity, Preprint, 2024.




                                                20
