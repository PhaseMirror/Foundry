import Lean

/-!
# Prime-Encoded Eigen Solvers: Core Category & Prime-Weighted Lanczos

Formal Lean 4 core module implementing Prime-Encoded Eigenvalue Decomposition (PEED)
and the Prime-Weighted Lanczos category $\mathbf{PrimeMod}_A$.

Reference: docs/templateArxiv.tex
"Prime-Encoded Eigen Solvers as Categorical Prime Flows:
A Multiplicity-Theoretic and Tensor-Quantum Framework"

## Key Structures

1. **Prime-Labelled Krylov Module** $M_m = (\mathcal{C}_m, \mathcal{L}, \tau_m)$:
   - Subspace $\mathcal{C}_m \subseteq \mathcal{H}$ of dimension $m$.
   - Free prime identity module $\mathcal{L} = \bigoplus_{p \in \mathbb{P}_A} \mathbb{R} e_p$.
   - Interaction map $\tau : \mathcal{L} \otimes \mathcal{C} \to \mathcal{H}$ with $\tau(e_p \otimes v) = A_p v$.

2. **Prime-Weighted Lanczos Recurrence**:
   - $w_{k+1} = A v_k - \alpha_k v_k - \beta_k v_{k-1}$
   - $\beta_k = \|w_k\| p_k$
   - Off-diagonals of tridiagonal $T_m$ are $\beta_k p_k$.

3. **Invariants as Functors**:
   - $\mathrm{Tr}(M_m) = \sum_{k=1}^m \alpha_k$
   - $E(M_m) = \sum_{k=1}^{m-1} (\beta_k p_k)^2$ (Frobenius off-diagonal energy)
   - Scale-free coupling ratios: $r_k = \frac{\beta_k p_k}{\beta_{k-1} p_{k-1}}$
   - Prime-exponent signature: $s_m = \sum_{k=1}^{m-1} \log_{p_k} |\beta_k p_k|$
   - Recursive feedback dynamics: $\mathcal{R}(M_m)(t) = \lambda_0 + \sum_{\tau=0}^{t-1} \alpha_\tau \sum_i p_i e^{-\beta_i \tau}$
-/

namespace EigenSolvers.Core

/-! ## 1. Prime Identity Module & Vector Data -/

/-- Prime index type. -/
abbrev Prime := Nat

/-- Standard prime sequence $\vec{p} = (2, 3, 5, 7, 11, 13, 17, 19, 23, \dots)$. -/
def standardPrimes : List Prime :=
  [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]

/-- Get the $k$-th prime (1-indexed). -/
def getNthPrime (k : Nat) : Prime :=
  let rec nth (ps : List Prime) (idx : Nat) : Prime :=
    match ps, idx with
    | [], _ => 2
    | p :: _, 0 => p
    | _ :: rest, n + 1 => nth rest n
  if k == 0 then 2 else nth standardPrimes (k - 1)

/-! ## 2. Prime-Weighted Lanczos Data Structures -/

/-- Representation of a tridiagonal matrix $T_m$ with diagonal $\alpha_k$ and off-diagonals $\beta_k p_k$. -/
structure TridiagonalMatrix where
  dim      : Nat
  alphas   : List Float
  betas    : List Float
  primes   : List Prime
  deriving Repr, BEq, Inhabited

/-- Prime-labelled Krylov module object $M_m$ in $\mathbf{PrimeMod}_A$. -/
structure PrimeKrylovModule where
  krylovDepth : Nat
  alphas      : List Float
  rawBetas    : List Float
  primes      : List Prime
  deriving Repr, BEq, Inhabited

/-- Construct an initial 1-dimensional Krylov module $M_1$. -/
def initKrylovModule (alpha1 : Float) (p1 : Prime := 2) : PrimeKrylovModule :=
  {
    krylovDepth := 1
    alphas      := [alpha1]
    rawBetas    := []
    primes      := [p1]
  }

/-- Prime-weighted effective off-diagonal elements $\beta_k^{\mathrm{eff}} = \beta_k \cdot p_k$. -/
def effectiveBetas (M : PrimeKrylovModule) : List Float :=
  let rec loop (bs : List Float) (ps : List Prime) (acc : List Float) : List Float :=
    match bs, ps with
    | [], _ => acc.reverse
    | _, [] => acc.reverse
    | b :: brest, p :: prest =>
      loop brest prest ((b * Float.ofNat p) :: acc)
  loop M.rawBetas M.primes []

/-- Advance the Krylov module by one prime-weighted Lanczos step:
    Functor $\mathcal{F}_{\vec{p}} : M_m \mapsto M_{m+1}$. -/
def advanceKrylovStep (M : PrimeKrylovModule) (nextAlpha : Float) (nextRawBeta : Float) (nextPrime : Prime) : PrimeKrylovModule :=
  {
    krylovDepth := M.krylovDepth + 1
    alphas      := M.alphas ++ [nextAlpha]
    rawBetas    := M.rawBetas ++ [nextRawBeta]
    primes      := M.primes ++ [nextPrime]
  }

/-- Build the corresponding tridiagonal matrix $T_m$. -/
def toTridiagonal (M : PrimeKrylovModule) : TridiagonalMatrix :=
  {
    dim    := M.krylovDepth
    alphas := M.alphas
    betas  := M.rawBetas
    primes := M.primes
  }

/-! ## 3. Spectral and Dynamical Invariants -/

/-- Trace functor: $\mathrm{Tr}(M_m) = \sum_{k=1}^m \alpha_k$. -/
def trace (M : PrimeKrylovModule) : Float :=
  M.alphas.foldl (· + ·) 0.0

/-- Prime-weighted off-diagonal energy functor:
    $E(M_m) = \sum_{k=1}^{m-1} (\beta_k p_k)^2$. -/
def primeWeightedEnergy (M : PrimeKrylovModule) : Float :=
  let eff := effectiveBetas M
  eff.foldl (fun acc b_eff => acc + b_eff * b_eff) 0.0

/-- Scale-free coupling ratios:
    $r_k = \frac{\beta_k p_k}{\beta_{k-1} p_{k-1}}$ for $k = 2, \dots, m$. -/
def scaleFreeCouplingRatios (M : PrimeKrylovModule) : List Float :=
  let eff := effectiveBetas M
  let rec loop (l : List Float) (acc : List Float) : List Float :=
    match l with
    | b1 :: b2 :: rest =>
      let r := if b1 != 0.0 then b2 / b1 else 0.0
      loop (b2 :: rest) (r :: acc)
    | _ => acc.reverse
  loop eff []

/-- Prime-exponent signature:
    $s_m = \sum_{k=1}^{m-1} \log_{p_k} |\beta_k p_k| = \sum_{k=1}^{m-1} \frac{\ln|\beta_k p_k|}{\ln p_k}$. -/
def primeExponentSignature (M : PrimeKrylovModule) : Float :=
  let rec loop (bs : List Float) (ps : List Prime) (acc : Float) : Float :=
    match bs, ps with
    | [], _ => acc
    | _, [] => acc
    | b :: brest, p :: prest =>
      let pF := Float.ofNat p
      let eff := Float.abs (b * pF)
      let logTerm := if eff > 0.0 && pF > 1.0 then (Float.log eff) / (Float.log pF) else 0.0
      loop brest prest (acc + logTerm)
  loop M.rawBetas M.primes 0.0

/-- Recursive feedback eigenvalue update:
    $\lambda_{t} = \lambda_0 + \sum_{\tau=0}^{t-1} \alpha_\tau \sum_i p_i e^{-\beta_i \tau}$. -/
def recursiveFeedbackUpdate (lambda0 : Float) (learningRate : Float) (primes : List Prime) (betaScales : List Float) (steps : Nat) : Float :=
  let rec loop (t : Nat) (currentLambda : Float) : Float :=
    match t with
    | 0 => currentLambda
    | tStep + 1 =>
      let tau := Float.ofNat (steps - (tStep + 1))
      let rec sumPrimes (ps : List Prime) (bs : List Float) (sumAcc : Float) : Float :=
        match ps, bs with
        | [], _ => sumAcc
        | _, [] => sumAcc
        | p :: prest, b :: brest =>
          let decay := Float.exp (- (b * tau))
          sumPrimes prest brest (sumAcc + (Float.ofNat p) * decay)
      let primeDecaySum := sumPrimes primes betaScales 0.0
      let nextLambda := currentLambda + learningRate * primeDecaySum
      loop tStep nextLambda
  loop steps lambda0

/-! ## 4. Categorical Morphisms and Intertwining -/

/-- Morphism in $\mathbf{PrimeMod}_A$: pair $(\phi_{\mathcal{C}}, \phi_{\mathcal{L}})$. -/
structure PrimeModMorphism where
  domainDepth    : Nat
  codomainDepth  : Nat
  scalingFactor  : Float
  isIntertwining : Bool
  deriving Repr, BEq, Inhabited

/-- Identity morphism on $M_m$. -/
def idMorphism (depth : Nat) : PrimeModMorphism :=
  {
    domainDepth    := depth
    codomainDepth  := depth
    scalingFactor  := 1.0
    isIntertwining := true
  }

/-- Composition of morphisms in $\mathbf{PrimeMod}_A$. -/
def composeMorphisms (f g : PrimeModMorphism) : Option PrimeModMorphism :=
  if f.codomainDepth == g.domainDepth then
    some {
      domainDepth    := f.domainDepth
      codomainDepth  := g.codomainDepth
      scalingFactor  := f.scalingFactor * g.scalingFactor
      isIntertwining := f.isIntertwining && g.isIntertwining
    }
  else none

/-- Canonical inclusion $\iota : M_m \to M_{m+1}$ (natural transformation). -/
def canonicalInclusion (m : Nat) : PrimeModMorphism :=
  {
    domainDepth    := m
    codomainDepth  := m + 1
    scalingFactor  := 1.0
    isIntertwining := true
  }

end EigenSolvers.Core
