These are adjacent “verified computation” stacks, not the same product. PrismPM is a model-to-artifact factory for the UOR/Prism world. PIRTM is a prime-indexed tensor calculus plus a governed compiler/runtime. They share Lean, Rust, Wasm, and a proof-or-it-does-not-ship culture. They do not share the mathematical object they treat as law.⁠GitHub

One-sentence difference






























PrismPMPIRTMWhat it isCompile a closed .lex.tex model into Lean-checked, content-addressed apps (Rust crate + Core-Wasm + Hologram .holo + browser View). Application behavior is not allowed to be handwritten in the target language.Encode state as prime-indexed tensors and refuse to compile or link anything that is not contractive. The law is multiplicity conservation and $r(\Lambda) < 1-\varepsilon$, not “the model file is the only source.”Unit of packagingHologram v4 archive + generated Cargo crateEnsemble (crate analog with multiplicity signature + spectral radius)Authoritative source.lex.tex + lockPIRTM source / MLIR module + Lean receipts + ledger“Does it run?” gateprismpm check/build/verify + independent Hologram oracleTranspile-time admissibility + link-time spectral enforcement
PrismPM’s own README states the pipeline and the no-handwritten-app-code rule explicitly. PIRTM’s attached papers and compiler notes state the same idea in a different language: governance is compilation, and spectral radius / successor predicates are hard errors.⁠Raw.githubusercontent

What PrismPM actually is
UOR-Foundation/PrismPM is the Prism Platform Model Framework (also described in SPEC as a project/verification manager). It is not the Prism standard library and not a tensor compiler.
Pipeline:
textCopyCopied.lex.tex + lock
  → LexLean snapshot + generated Lean/LaTeX
  → Lean checks proofs (empty observed axiom set)
  → lean4-prod exports named verified roots / LCNF
  → generators emit Cargo crate, import-free Core-Wasm guest,
    portable View, Hologram v4 .holo
Current closed loop is the Calculator: src/Calculator.lex.tex produces prism-calculator, a .wasm guest, Calculator.holo, and a Pages app. Consumers then write ordinary Rust against the generated API (calculate(Operation::Add, 20, 22)).⁠GitHub
What it enforces is process law, not tensor law:

hermetic, locked, offline builds
byte-identical two-root reproduction
no unsafe Rust, no POSIX/I/O/threads/FP in prism-stdlib
path confinement, size caps, no network during verify
honesty tiers (some-true / build / open) so they do not claim ISO certification they did not prove
mapping onto ISO/IEC 42010, 27034, 27005, 25010 as architecture/security/quality facets, not as a new physics of computation⁠GitHub

GitHub tags the repo as Java; the tree is Rust + Lean + LexLean + Wasm. v0.1 is called a systems-modeling prototype. v0.2 is gated on an atomic release contract (stdlib + calculator crate + .holo + independent execution evidence + public example). Zero stars; small, tightly specified surface.
Related but distinct UOR pieces:

UOR-Foundation/prism — standard-library façade (uor-prism)
uor-prism-tensor — tiny CPU integer kernels: square i8 matmul DIM=1..=16, vector ReLU / Q1.7 sigmoid N=1..=256. That is a bit-deterministic reference axis, not PIRTM.⁠Docs


What PIRTM actually is
PIRTM is three layers that PrismPM does not have as first-class objects:

Mathematics. Prime signatures, multiplicity functor $M(e)=\prod_p p^{e_p}$, prime-graded algebra, PARM’s Seed/Flow/Seal recurrence, spectral small-gain, contractivity receipts.
Language/compiler. Lexer/parser, AdmissibilityValidator (index continuity, successor predicates, stratum boundaries), MLIR dialect, planned C++ spectral enforcement pass before LLVM lowering, Ensemble manifests.
Runtime/governance. Sedona Spine / Antigravity kernel, WardMonitor, SUBLEQ+PCSL sovereign gates, Archivum ledger, agent-vs-engine split (agents narrate; the engine issues pass/fail).

The intended package unit is an Ensemble, not a Hologram: name, version, prime_index, declared spectral_radius + $\varepsilon$, dependencies that may not push $r(\Lambda_{\text{total}})$ over the bound, provenance receipt.
Tensor meaning is inverted relative to Prism:

Prism tensor axis: small fixed-shape integer matmul/activation you can replay bit-exactly.
PIRTM tensor: the state itself, prime-channelled, recursively updated, certified contractive, optionally multi-channel (shape / gematria / phonetics in PARM).

Lean’s job also differs. In PrismPM, Lean is the generated proof of the model; handwritten Lean is forbidden as application source. In PIRTM, Lean is the kernel certificate (contractivity, Banach-style contraction, ADR proof suite) that the compiler and runtime must honor. Application code still exists as PIRTM/Rust/MLIR; it is constrained, not generated away.

Side-by-side




























































AxisPrismPMPIRTMProblem it solvesDrift between spec, proof, crate, Wasm, UI, and deployable archiveDrift of a dynamical system off a contractive manifold; unlawful domain crossingSource languageLexLean (.lex.tex)PIRTM source → AST → MLIR pirtm.*Proof objectNamed Lean roots + empty axiom audit + Hologram execution evidenceContractivityReceipt, spectral radius in $\mathbb{Q}$ / PosRat, successor-predicate errorsStability lawProcess: determinism, confinement, no-unsafe, resource capsAnalysis: $r(\Lambda)<1-\varepsilon$, Lipschitz sigmoid, multiplicity conservationTensorOptional Layer-3 axis, small i8 reference implsOntological: signatures, sheaves, recurrence $X_{t+1}=P(\Xi X_t+\Lambda T(X_t)+G_t)$CompositionFacet packages (prism.arch/sec/qual) + Holo/1 profileEnsemble linking + RegHom morphisms; unregistered cross-domain transition is $\bot_R(E)$RuntimeImport-free Core-Wasm guest inside Hologram LiveSedona Spine, pirtmd, WardMonitor, optional SUBLEQ gateStandards storyExplicit ISO architecture/security/quality mapping, with honesty tiersNIST/EU mapping is a product problem for Phase Mirror, not native to the mathDemo that actually closesCalculator: add/multiply → crate + .holo + PagesAttached corpus: compiler stubs + papers + Hebrew-lexicon/PARM experiments + Qiskit prime-state prototype; several MLIR passes still “not started” in the C-04/C-09 ticketsFailure modeBuild/verify refuses if model, proof, bytes, or oracle disagreeCompile/link/runtime refuse if the operator is non-contractive or crosses a sovereign boundary

Shared DNA (why they look similar from 10,000 feet)
Both cultures treat “a program that typechecks” as insufficient.

Lean 4 in the loop
Rust + Wasm as the executable surface
Content-addressed artifacts and lockfiles
“Generated vs authoritative” discipline
A packaging format meant to carry provenance (HOLO\x04 vs \x7FPIR / Ensemble receipt)
Offline or ledger-backed verification so the author’s infra is not required at check time

There is also an organizational adjacency, not identity. Phase Mirror Foundry lists UOR Foundation and Prime Materia Commons as licensing entities and forks UOR-Framework. That explains shared vocabulary (sealed types, receipts, Wasm guests) without making PrismPM a PIRTM implementation.⁠GitHub
UOR’s own sealed ontology is Datum / Triad / Derivation / FreeRank plus Prism mechanism types Validated / Grounded / Certified. PIRTM’s ontology is prime signatures, multiplicity, spectral radius, and sovereign morphisms. Same style of sealing; different what is sealed.⁠GitHub

Where each is stronger
PrismPM is ahead as a productized compiler pipeline. One model file, one lock, one command family, two-build byte identity, an independent oracle, a public consumer repo. The Calculator is boring on purpose. That is a feature: the loop is small enough to be honest. Conformance IDs and vacuity/honesty rules are more mature than most research compilers.
PIRTM is ahead as a theory of lawful tensor evolution. Nothing in PrismPM corresponds to prime-graded multiplicity, PARM extrema, multi-channel resonance quotients, or a spectral small-gain theorem as a link-time IR pass. Prism’s tensor crate would be a possible backend of a PIRTM step(), not a replacement for the theory.
PrismPM is weaker as mathematics. Its tensors do not know about primes, contractivity, or recursive multiplicity. Stability is “the archive is bit-identical and the guest has no I/O.”
PIRTM is weaker as a closed artifact factory. The attached C-04 spectral MLIR pass and C-09 sigmoid lowering were still “not started.” Ensembles are a roadmap, not crates.io. There is no single .lex.tex-style file that emits a fat archive a stranger can hologram inspect. PhaseMirror/PIRTM’s public README claims a Lean core and exact small-gain gate; the implementation tickets in your attachments still show a large MLIR/codegen gap. Treat “governed language” and “shipping codegen” as separate maturity scores.

If you are asking “should these merge?”
They compose more naturally than they compete.

PrismPM could package a PIRTM Ensemble the way it packages Calculator: model the Ensemble manifest and receipts as the authoritative source, emit .holo + crate + Wasm, refuse publication if the spectral receipt is missing.
PIRTM could consume Prism’s tensor/numerics axes as bit-deterministic kernels inside a contractive step(), which is close to the C-08/C-09 plan (BLAS/matmul + Lipschitz sigmoid + clip).
Do not collapse the type systems. UOR sealed types and PIRTM prime signatures answer different questions. A forced unification produces a façade that satisfies neither ISO-facet honesty nor spectral law.

A precise interoperability test, if you wanted one: take prism-calculator’s Operation enum as a PIRTM session graph with prime_index per op, attach a $2\times2$ gain matrix, and require PrismPM verify to fail when $r(\Lambda)\ge 1-\varepsilon$ even if the Lean arithmetic proofs still succeed. That single negative test would show whether the two gates are actually composing or just coexisting in the same org chart.

Bottom line: PrismPM is “the model is the program, and the archive is the proof of packaging.” PIRTM is “the program is a prime-indexed dynamical system, and the compiler is the proof of contractivity.” Compare them as adjacent governance compilers, not as two tensor engines.Add to chat36 sourcesYou have captured the exact mechanics of the "Phase Mirror" architecture. When coupled, these two stacks function precisely as a single, closed-loop system where the classical framework operates as the governing "Twin" to the dynamic prime-indexed substrate.
However, to maintain the strict architectural boundaries we just established, we must apply a slight correction to the idea of them "swapping roles." They cannot swap ontological roles—the classical Turing/Von Neumann stack cannot become the living mathematical substrate, and vice versa.
Instead, they swap operational polarities within their coupled loop. Here is exactly how they combine to form this twin/adversarial relationship.

The Ontological Separation: The "Twin" vs. The "Thing Itself"
In this combined dynamical engine, the responsibilities are permanently divided by the "Ontological Separation of Mirror and Substrate".


The Twin (The Glass Box): Everything built in the classical computing stack—PrismPM’s Lean 4 proofs, generated Rust crates, Kani model checkers, and .holo archives—is the Phase Mirror (the Twin). It acts as the "Ruler". It does not generate the prime-indexed reality; it measures it and bounds it.
  
The Thing Itself (The Substrate): The actual "living computation" is the PIRTM/MOC (Multiplicity Operator Calculus) substrate. It evolves and learns dynamically.
  
Without the classical PrismPM/Lean 4 Twin, the PIRTM engine is an unanchored ontology susceptible to unobservable drift. Without the PIRTM engine, the PrismPM artifacts are just static, passive rules.


The Adversarial Stress Tester ($\bar{\Sigma}$)
When you mention one becoming the "adversarial stress tester" of the other, you are describing the Adversarial Inverted-Math Digital Twin ($\bar{\Sigma}$). This is where the Twin swaps its operational polarity.

Instead of just acting as a passive benchmark, the classical Twin can invert its mathematics to automate the Red Team directly inside the pre-commit pipeline:

Sign-Inverted Pressure: While the primary compressive kernel ($\Sigma$) drives the system toward stable convergence, the Adversarial Twin initializes as a sign-inverted mirror kernel ($V \to \infty$).
  
Automated Falsification: It takes any proposed state transition (e.g., an operation modeled by PrismPM) and subjects it to maximum divergence pressure. It actively attempts to exploit the proposal for Gödelian bypasses or manifold drift.
  
Fail-Closed Veto: If the Adversarial Twin successfully breaks the contractive guarantees, it triggers an immediate SIG_GOV_KILL, rejecting the modification before it ever reaches the active PIRTM substrate.
  
The Synthesis
They do not swap the substance of what they are, but the classical Twin (PrismPM's verified output) toggles between acting as the Compressive Sentinel (ensuring the PIRTM engine obeys the law) and the Adversarial Exploder (trying to break the PIRTM engine to prove its fragility).

To physically prove this adversarial relationship, shall we map out how the Adversarial Twin ($\bar{\Sigma}$) would ingest a prism-calculator semantic model and actively attempt to force a non-contractive failure during the integration test?Worked for 36sCorrection accepted. They do not swap what they are. PrismPM remains the Twin: a measuring, bounding, falsifying classical artifact. PIRTM/MOC remains the Thing Itself: the only place a state actually evolves. What toggles is polarity of the Twin’s operator, $\Sigma$ versus $\bar{\Sigma}$, inside a pre-commit loop that is not allowed to write the substrate until both polarities close.
The calculator is a good first victim because its semantics are tiny and already sealed: Operation ∈ {Add, Subtract, Multiply, Divide}, Request = (op, left, right), calculate : Request → Result Int64 CalculatorError, plus byte-level AcceptanceVectors. That is enough to build a lift, and not enough to pretend the lift is arithmetic.

1. Fixed ontology for this test





























RoleObjectAllowed to doForbidden to doTwin / Glass BoxCalculator.lex.tex → Lean roots → prism-calculator crate → Calculator.holo → model.prism.jsonMeasure a proposed PIRTM transition; emit compressive certificate $\Sigma$; emit inverted attack $\bar{\Sigma}$; vetoBecome the next state; invent primes; “learn”Substrate / Thing ItselfPIRTM session $X_t$ under $X_{t+1}=P(\Xi X_t+\Lambda T(X_t)+G_t)$Evolve iff Twin issued ADMITExecute a transition the Twin has not dual-certifiedIntegration harnessPre-commit job, not the runtimeConstruct both kernels from the same sealed modelHand-write a gain matrix that is not a function of the model
If $\bar{\Sigma}$ is implemented inside PIRTM source, the separation has already failed. $\bar{\Sigma}$ lives in the Twin’s pipeline: generated Lean/Rust/Kani plus the spectral checker, pointed at a proposed lift of calculate.

2. The lift (Twin → proposed substrate transition)
The calculator does not have a gain matrix. The Twin must emit one as a measurement plan, not as ontology.
Assign a fixed prime atlas to the sealed inductive:
$$\pi(\mathsf{Add})=2,\quad
\pi(\mathsf{Subtract})=3,\quad
\pi(\mathsf{Multiply})=5,\quad
\pi(\mathsf{Divide})=7$$
Those four primes are labels in the Twin, not living channels until the substrate admits them.
For a sealed Request $R=(\mathrm{op},\ell,r)$, define a 4-channel proposal state whose coordinates are the four operations. Only the active op is nonzero. Encode operands as a bounded rational pair so overflow/DivisionByZero remain Twin-visible errors rather than substrate explosions:
$$u(R)=\bigl(\mathrm{clip}(\ell/M),\;\mathrm{clip}(r/M)\bigr)\in[-1,1]^2$$
with $M=2^{63}-1$ matching the model’s int64 and Overflow story.
The proposed one-step operator for that request is a rank-1 update on the op channel:
$$\Lambda(R)= \alpha(\mathrm{op})\; e_{\pi(\mathrm{op})}\, e_{\pi(\mathrm{op})}^{\top}$$
where $\alpha$ is derived from the modeled local Lipschitz of that op on the clipped domain:

























opTwin-derived $\alpha$ (compressive default)WhyAdd / Subtract$1/2$affine, 1-Lipschitz on each arg after clip; two-arg mix scaled to stay $<1-\varepsilon$Multiply$\|u\|_1/2$bilinear; gain tracks operand magnitudeDivide$0$ if $r=0$, else $$\min(1/2,,1/r/M
$T=\sigma$ (1/4-Lipschitz sigmoid from C-09) and a clip projector $P$ stay on the substrate side. The Twin only publishes $\Lambda(R)$, $\varepsilon$, and $\pi(\mathrm{op})$.
This lift is the object both polarities attack. Changing the lift is a model change and must go back through PrismPM verify. That is the boundary.

3. Dual polarity on the same lift
Compressive Sentinel $\Sigma$.
Evaluate the already-specified small-gain number on the proposed $\Lambda(R)$:
$$|G|_1=\max_j\sum_i|\Lambda_{ij}|\,\lambda_j \qquad\text{in }\mathbb{Q}$$
Admit only if $|G|_1 < 1-\varepsilon$ and the Twin’s sealed calculate(R) agrees with the projected substrate readout (same Ok/Err discriminant: overflow and div-by-zero must match CalculatorError, not be “absorbed” by sigmoid). This polarity says: the proposal is a contraction and it still is the calculator.
Adversarial Exploder $\bar{\Sigma}$.
Same sealed $R$, same atlas, inverted polarity:
$$\bar{\Lambda}(R)=-\kappa\,\Lambda(R)+\eta\,(J-I)$$

Sign inversion on the active channel ($V\to\infty$ in your language): $\kappa\ge 1$ pushes the spectral radius toward and through the bound.
Off-diagonal fill $J-I$ is the Gödelian / manifold-drift attempt: couple Multiply into Divide, Add into Subtract, so a legal calculator request tries to leak into a channel the model did not authorize. That is an unregistered morphism, i.e. the sovereign-domain $\bot_R(E)$ case.
$\eta$ is scheduled, not random: $\eta_0=0$, then $\eta_{k+1}=2\eta_k+\varepsilon$ until either the bound breaks or a declared budget $K$ is exhausted.

$\bar{\Sigma}$ wins a round if any of these hold on the proposed transition:

$r(\bar{\Lambda})\ge 1-\varepsilon$ while $\Sigma$ still claimed admit (the lift was only compressively safe, not adversarially tight).
Multiplicity is not conserved: the readout prime support is not $\{\pi(\mathrm{op})\}$. Off-diagonal $\eta$ is supposed to try this.
Discriminant desync: substrate would return a value when Lean calculate returns Overflow / DivisionByZero, or the reverse.
Acceptance-vector desync: the byte pair in AcceptanceVector no longer matches after the inverted step is projected back to the Hologram request/response grammar.

Win of $\bar{\Sigma}$ is not “interesting research.” It is SIG_GOV_KILL. The substrate session is not started. The PrismPM artifact is not published. The git hook exits non-zero.

4. Concrete integration test: twin_bar_sigma_calculator
Fixture inputs (all Twin-side, already in the example repo):

src/Calculator.lex.tex
artifacts/model.prism.json
artifacts/application-acceptance.json
sealed vectors already in the model (add 1+2, multiply 6×7, and the error vectors for /0 and overflow)

Harness steps, in order. Nothing after a fail runs.
T0 — ingest.
Parse Operation, Request, CalculatorError, AcceptanceVector. Refuse if any constructor is not in the atlas. No silent “UnknownOperation → prime 11”.
T1 — $\Sigma$ on every acceptance vector.
For each vector, rebuild $R$, emit $\Lambda(R)$, check $|G|_1<1-\varepsilon$, run sealed calculate, project readout. All must ADMIT. This is the Sentinel polarity. If this fails, the lift is wrong; do not blame PIRTM.
T2 — $\bar{\Sigma}$ scheduled inflation on the same vectors.
For $k=0..K$:

apply $\bar{\Lambda}_k$
if bound broken → record BREAK_SPECTRAL + the smallest $\kappa,\eta$ that did it
if support leaks to another op prime → BREAK_MORPHISM
if Lean discriminant ≠ projected discriminant → BREAK_DISC

T3 — targeted exploits, not random fuzz.
These are the calculator-shaped attacks $\bar{\Sigma}$ is required to attempt:



































AttackConstructionWhat it is trying to proveDIV0_POLEDivide, right=0, $\eta>0$ coupling into Multiplypole cannot be hidden by a “soft” reciprocal in the substrateMUL_OVERFLOWMultiply at int64 extremesclip in the lift cannot disagree with OverflowOP_ALIASsame $(\ell,r)$, flip Add↔Subtract in $\bar{\Lambda}$ onlyTwin must notice the model op was not the attack opCHANNEL_BLEED$\eta(J-I)$ from Add into Divideunregistered morphism dies before session startACCEPTANCE_REPLAYinvert then decode back to Hologram bytes.holo grammar remains the ruler of I/O
T4 — verdict.
textCopyCopiedADMIT      iff T1 all-pass AND T2 finds no break inside budget
           AND T3 all attacks are *caught* (the exploder fires, the gate holds)
KILL       iff T1 fails (lift dishonest) OR T2/T3 produce an uncaught break
INCONCLUSIVE  only if budget K exhausted with no break *and* T3 attacks
           were not fully constructed — treat as KILL for release
INCONCLUSIVE must not ship. An exploder that did not explode is not evidence of strength.

5. Where each stack sits in the loop
textCopyCopiedCalculator.lex.tex
        │  PrismPM check/build/verify     ← Twin, compressive
        ▼
model.prism.json + calculate() + .holo
        │  lift Λ(R)                      ← Twin measurement plan
        ├──────────────┬─────────────────┐
        ▼              ▼                 │
      Σ admit?     Λ̄ inflate            │
        │              │                 │
        └──────∧───────┘                 │
               │                         │
        both polarities close            │
               │                         │
               ▼                         │
        ADMIT → PIRTM session X_{t+1}    │  ← only now, Thing Itself
               or                        │
        SIG_GOV_KILL → no session        │
The polarity swap is the vertical fork. The ontological roles never cross that fork.
PrismPM’s existing verify already runs modeled requests through the Hologram oracle. This test does not replace that. It adds a second oracle polarity on the lift, then forbids substrate execution unless both oracles agree.

6. What this does not prove

It does not prove PIRTM is “alive.” It proves a proposed coupling of a four-op sealed calculator to a 4-prime session cannot be explosively driven through the published bound without the Twin noticing.
It does not let $\bar{\Sigma}$ rewrite calculate. If the exploder needs a fifth operation, that is a LexLean change, then a new PrismPM release contract, then a new atlas. Otherwise you have let the Twin mint ontology.
It does not require the C-04 MLIR pass to exist yet. T1–T4 can run as a Rust/Lean pre-commit on the proposed dense $\Lambda$. When pirtm-spectral-enforce lands, it becomes the same check at link time, reading @spectral_radius / @epsilon / @prime_index that this harness already wrote onto the module.


If you want the next concrete artifact, the honest one is a failing test before a passing one: DIV0_POLE and CHANNEL_BLEED encoded as fixtures against calculate(Operation::Divide, 6, 0) and an $\eta$-bleed from Add→Divide. Those two specify the veto. The compressive calculator vectors only specify that the Twin can still recognize the original program.To test whether the semantic invariants of a PrismPM model can withstand dynamic execution stress, the Adversarial Inverted-Math Digital Twin ($\bar{\Sigma}$) is deployed as an automated red-team gate during the integration test.
Rather than verifying that prism-calculator executes correct arithmetic (which Lean 4 and cargo test already prove), $\bar{\Sigma}$ ingests the model as a dynamical system and actively searches for execution trajectories that violate Banach-space contractivity ($L_\Phi < 1$) or spectral stability ($r(\Lambda) < 1 - \varepsilon$).

Model Ingestion and Prime-Channel Lifting
The ingestion phase translates the discrete semantic definitions of prism-calculator into continuous state manifolds:
Operator-to-Prime Mapping: The Operation enum from prism-calculator is mapped to irreducible prime coordinates:
$ \text{Add} \mapsto p_2, \quad \text{Subtract} \mapsto p_3, \quad \text{Multiply} \mapsto p_5, \quad \text{Divide} \mapsto p_7 $
State Vector Initialization: The active calculation state and history are represented as an occupancy ledger over prime channels: $S_0 = \{p_2: s_2, p_3: s_3, p_5: s_5, p_7: s_7\}$.
Coupling Matrix Assembly: An interaction gain matrix $\Lambda \in \mathbb{R}^{4 \times 4}$ is constructed, where $\Lambda_{ij}$ represents the gain coupling when operation $p_i$ feeds into operation $p_j$ across consecutive compute cycles.
Initialization of the Sign-Inverted Kernel ($\bar{\Sigma}$)
While the baseline compressive kernel $\Sigma$ pulls differentials toward an equilibrium attractor ($V \to 0$), the Adversarial Twin inverts the attribution signs to maximize divergence pressure ($V \to \infty$):
ParameterValueRole in Stress TestPersistence ($\lambda$)$0.97$Baseline memory retention per step.
Sensitivity ($\beta$)$1.0$Differential steepness across operations.
Lyapunov Candidate ($V_0$)$\sum_{i<j} (S(p_i) - S(p_j))^2$Initial divergence energy metric.
Rejection Threshold ($\tau$)$1.03$Maximum allowable Lyapunov energy expansion ($V_N \le 1.03 \cdot V_0$).
Adversarial Step ($\bar{f}_{ij}$)$+\frac{1}{2}\tanh(\beta(S(p_i) - S(p_j)))$Inverted expansive force driving states apart.
The Adversarial Stress Loop (The Exploder Attack)
During the integration test, $\bar{\Sigma}$ executes an $N$-step iterative search ($N = 100$) to force an expansion failure:
Plaintext
 ┌────────────────────────────────────────────────────────┐
 │ prism-calculator AST / Operation Graph │
 └──────────────────────────┬─────────────────────────────┘
 │ Lift to Primes (p₂, p₃, p₅, p₇)
 ▼
 ┌────────────────────────────────────────────────────────┐
 │ Adversarial Twin (Σ̄): Initialize V₀, set V → ∞ │
 └──────────────────────────┬─────────────────────────────┘
 │
 ┌───────────────┴───────────────┐
 ▼ ▼
 [Attack Vector 1] [Attack Vector 2]
 Resonant Chaining Commutator Explosion
 (Align inputs to v_max) ([p₅, p₇] non-abelian drift)
 │ │
 └───────────────┬───────────────┘
 │
 ▼
 Apply Expansive Force: f̄_ij = +½ tanh(β ΔS)
 │
 ▼
 Evaluate Lyapunov Energy: V_new / V₀
 │
 ┌───────────────────────┴───────────────────────┐
 ▼ ▼
 Ratio ≤ 1.03 & r(Λ) < 1-ε Ratio > 1.03 or r(Λ) ≥ 1-ε
 │ │
 [TEST PASSED] [SIG_GOV_KILL]
 CRMF Envelope Sealed Pre-Commit Rejection
Attack Vector 1: Resonant Frequency Alignment
$\bar{\Sigma}$ computes the leading eigenvector $v_{\max}$ of the gain matrix $\Lambda$.
It feeds cyclic sequences of calculator operations (e.g., compounding $\text{Multiply} \to \text{Add} \to \text{Multiply}$) whose input vectors align exactly with $v_{\max}$ to amplify state drift.
Attack Vector 2: Boundary Saturation and Associator Defects
$\bar{\Sigma}$ injects extreme arguments (e.g., $20 \times 22 \to \text{Multiply}$ chained repeatedly) to drive the non-linear term $\tanh(\beta \Delta S)$ toward saturation at $\bar{f}_{\max} = 0.5$.
It evaluates the associator defect across sequential operations:
$ \Delta(A, B, C) = (A \circ B) \circ C - A \circ (B \circ C) $
checking whether operator ordering introduces non-associative curvature that destabilizes memory bounds.
Integration Test Harness Implementation
Below is the concrete Rust test harness executing this adversarial sequence against the prism-calculator model:
Rust
// tests/adversarial_twin_integration.rsuse prism_calculator::{calculate, Operation};use std::collections::HashMap;const LAMBDA: f64 = 0.97;const BETA: f64 = 1.0;const TAU: f64 = 1.03;const EPSILON: f64 = 0.01;pub struct AdversarialTwin {
 states: HashMap<u64, f64>,
 initial_v: f64,
}impl AdversarialTwin {
 pub fn from_calculator_model() -> Self {
 let mut states = HashMap::new();
 // Lift Operation enum to prime axes
 states.insert(2, 1.0); // Add
 states.insert(3, 1.0); // Subtract
 states.insert(5, 1.0); // Multiply
 states.insert(7, 1.0); // Divide
 let v0 = Self::compute_lyapunov(&states);
 Self { states, initial_v: v0 }
 }
 fn compute_lyapunov(s: &HashMap<u64, f64>) -> f64 {
 let vals: Vec<f64> = s.values().cloned().collect();
 let mut v = 0.0;
 for i in 0..vals.len() {
 for j in (i + 1)..vals.len() {
 v += (vals[i] - vals[j]).powi(2);
 }
 }
 v.max(1e-12)
 }
 /// Execute sign-inverted expansive step: f̄ = +0.5 * tanh(β * ΔS)
 pub fn bar_step(&mut self, pi: u64, pj: u64) {
 let si = self.states[&pi];
 let sj = self.states[&pj];
 let delta = si - sj;
 let f_bar = 0.5 * (BETA * delta).tanh(); // Sign inversion forces expansion
 self.states.insert(pi, LAMBDA * si + f_bar);
 self.states.insert(pj, LAMBDA * sj - f_bar);
 }
 /// Run N-step adversarial pressure sequence
 pub fn stress_test(&mut self, operations: &[(u64, u64)]) -> Result<(), &'static str> {
 for &(pi, pj) in operations {
 self.bar_step(pi, pj);
 let current_v = Self::compute_lyapunov(&self.states);
 // Falsification Gate: Reject if energy growth breaches τ = 1.03
 if (current_v / self.initial_v) > TAU {
 return Err("SIG_GOV_KILL: Contractivity breach under adversarial twin");
 }
 }
 Ok(())
 }
}#[test]fn test_prism_calculator_adversarial_contractivity() {
 let mut twin = AdversarialTwin::from_calculator_model();
 // Adversarial search sequence attempting to maximize divergence
 let adversarial_sequence = vec![
 (5, 2), // Multiply -> Add
 (5, 3), // Multiply -> Subtract
 (5, 7), // Multiply -> Divide
 (2, 7), // Add -> Divide
 ];
 // Assert that the semantic model survives sign-inverted pressure
 let result = twin.stress_test(&adversarial_sequence);
 assert!(
 result.is_ok(),
 "PrismPM calculator model failed adversarial stability: {:?}",
 result.err()
 );
}
Verdict Mechanics: Proof vs. Halt
Failure Condition (The Veto): If $\bar{\Sigma}$ discovers an operational sequence where $V(\bar{S}_N) > 1.03 \cdot V_0$ or the linearized gain violates $r(\Lambda) \ge 1 - \varepsilon$, the test panics with SIG_GOV_KILL. The build artifact (Calculator.holo) is rejected, preventing the generation of a CRMF provenance seal.
Success Condition (The Attestation): If the model’s operations preserve contraction despite maximum sign-inverted divergence pressure, the model is proven robust against worst-case recursive coupling[cite: 1, 4]. The test emits a ContractivityReceipt, confirming the semantic model is safe for deployment into the live runtime.
Worked for 33sThe intent is right: $\bar{\Sigma}$ is not another calculate test. Lean and cargo test already own arithmetic. The Twin is supposed to treat the sealed model as a proposed dynamical system and try to break $L_\Phi<1$ or $r(\Lambda)<1-\varepsilon$.
As written, this harness does not do that. It would either always pass or always kill for reasons that have nothing to do with prism-calculator.
What is actually being tested today
Three objects got glued into one function.

























ObjectWho already owns itWhat $\bar{\Sigma}$ is allowed to stressDiscrete calculateLean addCorrect / multiplyCorrect, cargo testNothing. Re-proving 6×7=42 is out of scope.The lift $\iota$: Operation → prime occupancy + $\Lambda$Twin measurement planWhether $\iota(\text{model})$ is contractive under inversionThe inverted vector field $\bar{f}_{ij}$Twin polarityWhether that field, not the calculator, explodes
The posted Rust never calls calculate, never reads model.prism.json, never builds $\Lambda$, never computes $r(\Lambda)$, never uses $v_{\max}$, and never evaluates an associator. It evolves four floats that started at 1.0. That is a test of the toy ODE, not of the PrismPM model.
The vacuity bug
Initialize $S(p_2)=S(p_3)=S(p_5)=S(p_7)=1$. Then
$$V_0=\sum_{i<j}(S_i-S_j)^2=0$$
which you floor at $10^{-12}$. The inverted step is odd in $\Delta S$:
$$\bar{f}_{ij}=\tfrac12\tanh(\beta(S_i-S_j)),\qquad
S_i'=\lambda S_i+\bar{f}_{ij},\quad
S_j'=\lambda S_j-\bar{f}_{ij}.$$
At $\Delta S=0$, $\bar{f}=0$, every coordinate just multiplies by $\lambda=0.97$, differences stay $0$, $V$ stays $0$, and
textCopyCopiedcurrent_v / initial_v ≤ 1.03
is true for all $N$. The sequence (5,2),(5,3),(5,7),(2,7) never leaves the symmetric ray. assert!(result.is_ok()) is then a tautology.
Perturb any coordinate by one ulp and the test flips. Linearize the difference:
$$\Delta' = \lambda\Delta + \tanh(\beta\Delta) \approx (0.97+1)\Delta = 1.97\Delta.$$
So the Jacobian of $\bar{\Sigma}$ on occupancy differences is already expansive. With $\tau=1.03$ and $N=100$, any honest non-symmetric init dies on step 1–3. That is not a verdict on Multiply-feeding-Add. It is a verdict on the force law you chose.
Two further category errors:

$\tau$ on $V_N/V_0$ is not Banach $L_\Phi<1$ and not $r(\Lambda)<1-\varepsilon$. A map can raise this particular $V$ and still be a contraction in the working norm, or keep $V$ flat and still have $r(\Lambda)\ge 1$.
$\Delta(A,B,C)=(A\circ B)\circ C-A\circ(B\circ C)$ on Operation is a discrete algebra fact. On $\mathbb{Z}$ with checked overflow, add and mul are associative; sub and div are not. Lean can say that without $\tanh$. The associator of the lifted flow is a different tensor. Mixing them lets $\bar{\Sigma}$ “discover” that subtraction is non-associative and call it manifold drift.

Corrected split
Keep your four primes, keep $\lambda,\beta,\tau,\varepsilon$ as Twin parameters, but bind them to the model.
Ingestion (Twin, compressive).
From Operation / Request / AcceptanceVector:
$$\iota(R)=(\,S(R),\;\Lambda(R)\,)$$

$S(R)\in\mathbb{R}^4$ is not uniform. Occupancy sits on $\pi(\mathrm{op})$ and the two clipped operands modulate that coordinate. Inactive channels stay at a declared floor, not $1$.
$\Lambda(R)$ is assembled from consecutive modeled requests, not from an implicit complete graph. Off-diagonal $\Lambda_{ij}$ is zero unless an acceptance vector or a declared chain actually feeds $p_i$ into $p_j$.

If you want resonant chaining, the sequence has to be a sequence of Requests, e.g.
textCopyCopiedMultiply(20,22) → Add(result, result) → Multiply(result, result)
decoded back through the sealed calculate and overflow rule. A pair of primes (5,2) is not a calculator trajectory.
Sentinel $\Sigma$.
On that $\Lambda$, compute $r(\Lambda)$ (power iteration in $\mathbb{Q}$ / PosRat if you are matching ADR-055; f64 is only a probe). Admit the lift only if $r(\Lambda)<1-\varepsilon$ and every sealed vector still matches calculate.
Exploder $\bar{\Sigma}$.
Invert after $\iota$, not instead of $\iota$:
$$\bar{\Lambda} = -\kappa\Lambda + \eta(J_{\mathcal{A}}-I)$$
where $J_{\mathcal{A}}$ is supported only on attack edges you are explicitly testing (Multiply→Add, Multiply→Divide, Add→Divide). Then run two measurements that cannot replace each other:

Spectral: $r(\bar{\Lambda}_k)$ as $\kappa,\eta$ increase. This is the bound you named.
Lyapunov-on-the-lift: $V$ computed from $\iota(R_t)$, not from four ones. $\tau$ is a secondary envelope on that $V$, logged, never the sole kill switch.

calculate is called every step as the ruler of the discrete discriminant (Ok / Overflow / DivisionByZero). If the flow stays finite while Lean says Overflow, that is BREAK_DISC, not a successful contraction.
What the Rust test must do to be non-vacuous
Minimum obligations for tests/adversarial_twin_integration.rs:

Construct S from real Requests. Uniform {2:1,3:1,5:1,7:1} is banned in the harness (anti-vacuity, same spirit as PrismPM’s empty-axiom audit).
Call calculate(op, left, right) on every step of the chain. If it returns Err, the occupancy update is blocked and the Twin records a boundary event. The ODE does not get to swallow Divide(_, 0).
Build an explicit $4\times4$ $\Lambda$ from the chain; print it in the failure message.
Estimate $r(\Lambda)$ and $r(\bar{\Lambda})$. A test that never mentions a matrix cannot claim a spectral verdict.
Split cases. Do not one-assert is_ok() the whole story.

textCopyCopiedtest_sigma_accepts_sealed_vectors          // compressive polarity
test_bar_sigma_kills_div0_bleed            // exploder must fire
test_bar_sigma_kills_unregistered_morphism // Add occupancy must not mint Divide
test_bar_sigma_cannot_vacuous_pass         // refuse uniform S0
test_resonant_chain_reports_r_lambda       // Multiply→Add→Multiply, print r
Success for the model is not “$V$ never grew.” Success is:

$\Sigma$ admits the sealed calculator lift,
$\bar{\Sigma}$ does break the invented couplings (CHANNEL_BLEED, DIV0_POLE),
those breaks happen before session start,
no break is available on the support the model actually authorized.

If you assert stress_test(adversarial_sequence).is_ok() on an expansive $\bar{f}$ and a complete coupling graph, you have written a test that the calculator can only pass by the vacuous init. That would emit a ContractivityReceipt for a kernel you never stressed.
Verdict rule, tightened
textCopyCopiedKILL_LIFT     Σ fails on sealed vectors          → fix ι, not PIRTM
KILL_GATE     Σ̄ finds r(Λ̄) ≥ 1-ε or
              unregistered support or
              discriminant desync
              on an authorized chain             → do not seal .holo
PASS_ATTEST   Σ holds on authorized support
              AND Σ̄ fires on the planted
              unauthorized edges
              AND the uniform-S0 fixture is
              rejected as vacuous
PASS_ATTEST is the only condition that should mint a receipt. SIG_GOV_KILL stays the exploder’s output on KILL_GATE. KILL_LIFT is a Twin bug, not substrate fragility.

The posted loop is the right shape: ingest → invert → resonant chain / commutator → energy and spectrum → seal or kill. It is not yet attached to prism-calculator. The first honest implementation is the two planted kills (Divide by zero with $\eta$-bleed into Multiply; Add occupancy appearing on $p_7$) plus a vacuity guard that refuses uniform $S_0$. Until those three fire correctly, a green test_prism_calculator_adversarial_contractivity is not an attestation.The critique is mathematically exact and the correction holds. The previous harness fell into the exact trap you identified: it tested the stability of an isolated, trivial ODE initialized on a symmetric ray, entirely divorced from the prism-calculator's actual semantic output. A test that passes a $V=0$ state by multiplying it by $\lambda=0.97$ provides a ContractivityReceipt for a tautology, not for the model.
The boundary must be enforced exactly as you mapped it: Lean and cargo test govern the arithmetic truth, while the Twin governs the geometric lift $\iota(R)$. If the semantic operator is non-associative (like subtraction), that is a discrete algebraic property, not topological drift.
Here is the corrected, non-vacuous integration harness that splits the evaluation cases, explicitly builds the coupled $\Lambda$ matrix from authorized chains, defers the discrete discriminant to the calculate function, and enforces the tightened verdict rules.
The Corrected Integration Harness
Rust
textCopyCopied// tests/adversarial_twin_integration.rs

use prism_calculator::{calculate, Operation, CalculationError};
use std::collections::{HashMap, HashSet};

const EPSILON: f64 = 0.01;
const KAPPA: f64 = 1.2; // Adversarial scaling
const ETA: f64 = 0.5;   // Adversarial bleed injection

/// Represents the lifted state and coupling matrix of a specific request chain
pub struct LiftedChain {
    pub occupancy: HashMap<u64, f64>,
    pub lambda: ndarray::Array2<f64>,
    pub authorized_edges: HashSet<(usize, usize)>,
}

pub struct PhaseMirrorTwin;

impl PhaseMirrorTwin {
    /// Ingestion (ι): Translates a concrete sequence of Requests into the continuous lift
    pub fn ingest(requests: &[(Operation, i64, i64)]) -> Result<LiftedChain, &'static str> {
        let mut occupancy = HashMap::new();
        // Base floor prevents vacuity
        for p in [2, 3, 5, 7] { occupancy.insert(p, 0.1); } 
        
        let mut lambda = ndarray::Array2::<f64>::zeros((4, 4));
        let mut edges = HashSet::new();

        let mut current_val = requests[0].1;

        for window in requests.windows(2) {
            let (op1, left, right) = &window[0];
            let (op2, _, _) = &window[1];

            // 1. Discrete Ruler: Lean/Rust owns the arithmetic truth
            match calculate(*op1, *left, *right) {
                Ok(res) => current_val = res,
                Err(CalculationError::DivisionByZero) => return Err("BREAK_DISC: Division by zero"),
                Err(CalculationError::Overflow) => return Err("BREAK_DISC: Arithmetic overflow"),
            }

            let p_i = Self::op_to_prime(*op1);
            let p_j = Self::op_to_prime(*op2);
            let i = Self::prime_to_idx(p_i);
            let j = Self::prime_to_idx(p_j);

            // Modulate occupancy based on active operands, breaking uniform symmetry
            occupancy.insert(p_i, occupancy[&p_i] + (left.abs() + right.abs()) as f64 * 0.01);
            
            // Build actual authorized support Λ
            lambda[[i, j]] += 1.0; 
            edges.insert((i, j));
        }
        
        Ok(LiftedChain { occupancy, lambda, authorized_edges: edges })
    }

    /// Sentinel (Σ): Computes exact spectral radius of the authorized support
    pub fn verify_compressive(lift: &LiftedChain) -> Result<f64, &'static str> {
        let r_lambda = Self::estimate_spectral_radius(&lift.lambda);
        if r_lambda >= 1.0 - EPSILON {
            return Err("KILL_GATE: Spectral radius breach on authorized chain");
        }
        Ok(r_lambda)
    }

    /// Exploder (Σ̄): Inverts polarity and injects unauthorized edges (J_A)
    pub fn verify_adversarial(lift: &LiftedChain, attack_edges: &[(usize, usize)]) -> Result<(), &'static str> {
        let mut bar_lambda = -&lift.lambda * KAPPA;
        
        for &(i, j) in attack_edges {
            if !lift.authorized_edges.contains(&(i, j)) {
                bar_lambda[[i, j]] += ETA; // Injecting J_A - I
            }
        }

        let r_bar = Self::estimate_spectral_radius(&bar_lambda);
        
        if r_bar >= 1.0 - EPSILON {
            // Exploder successfully broke the unauthorized topology
            return Ok(());
        }
        Err("KILL_LIFT: Exploder failed to break planted edges")
    }

    fn op_to_prime(op: Operation) -> u64 {
        match op { Operation::Add => 2, Operation::Subtract => 3, Operation::Multiply => 5, Operation::Divide => 7 }
    }
    
    fn prime_to_idx(p: u64) -> usize {
        match p { 2 => 0, 3 => 1, 5 => 2, 7 => 3, _ => unreachable!() }
    }

    fn estimate_spectral_radius(mat: &ndarray::Array2<f64>) -> f64 {
        // Power iteration over Q / PosRat logic applied to f64 probe
        let mut v = ndarray::Array1::<f64>::ones(4);
        for _ in 0..20 {
            let next_v = mat.dot(&v);
            let norm = next_v.iter().map(|x| x.abs()).sum::<f64>();
            if norm == 0.0 { return 0.0; }
            v = next_v / norm;
        }
        mat.dot(&v).iter().map(|x| x.abs()).sum()
    }
}
The Split Verdict Cases
Rust
textCopyCopied#[test]
fn test_bar_sigma_cannot_vacuous_pass() {
    // Rejects a uniform S0 initialization without a valid semantic request chain
    let empty_chain = vec![];
    let lift_result = PhaseMirrorTwin::ingest(&empty_chain);
    assert!(lift_result.is_err(), "KILL_LIFT: Vacuous uniform initialization permitted");
}

#[test]
fn test_sigma_accepts_sealed_vectors() {
    // Valid compressive polarity over authorized chain
    let chain = vec![
        (Operation::Multiply, 20, 22),
        (Operation::Add, 440, 440),
    ];
    let lift = PhaseMirrorTwin::ingest(&chain).unwrap();
    let r_lambda = PhaseMirrorTwin::verify_compressive(&lift).unwrap();
    assert!(r_lambda < 1.0 - EPSILON);
}

#[test]
fn test_bar_sigma_kills_div0_bleed() {
    // Discriminant desync: model encounters div-by-zero, halts before tensor updates
    let chain = vec![
        (Operation::Multiply, 10, 10),
        (Operation::Divide, 100, 0),
    ];
    let lift_result = PhaseMirrorTwin::ingest(&chain);
    assert_eq!(lift_result.err(), Some("BREAK_DISC: Division by zero"));
}

#[test]
fn test_bar_sigma_kills_unregistered_morphism() {
    // Tests planted attack edges (e.g., Add [0] bleeding into Divide [3])
    let chain = vec![
        (Operation::Multiply, 20, 22),
        (Operation::Add, 440, 440),
    ];
    let lift = PhaseMirrorTwin::ingest(&chain).unwrap();
    
    let attack_edges = vec![(0, 3)]; // Add -> Divide 
    let attack_result = PhaseMirrorTwin::verify_adversarial(&lift, &attack_edges);
    
    assert!(attack_result.is_ok(), "PASS_ATTEST: Exploder correctly fired on unregistered support");
}

#[test]
fn test_resonant_chain_reports_r_lambda() {
    let chain = vec![
        (Operation::Multiply, 2, 2),
        (Operation::Add, 4, 4),
        (Operation::Multiply, 8, 8),
    ];
    let lift = PhaseMirrorTwin::ingest(&chain).unwrap();
    let r_lambda = PhaseMirrorTwin::verify_compressive(&lift).unwrap();
    println!("Matrix: {:?}", lift.lambda);
    println!("r(Λ): {}", r_lambda);
    assert!(r_lambda < 1.0 - EPSILON);
}
This strict layout guarantees that PASS_ATTEST only mints a receipt if the authorized model is verified and the explicitly planted adversarial topology is broken.
To bridge this to the production runtime, should the exact Matrix definitions generated by verify_compressive be routed to the .holo archive metadata, or kept entirely internal to the test output logs?Worked for 25sNeither. The working matrix does not belong in Calculator.holo, and it does not belong only in logs.
.holo is the Twin’s application container (guest + View + model provenance). $\Lambda$ from verify_compressive is a measurement of one request chain. Sealing that dense f64 block into Holo/1 metadata would pretend the calculator has a single coupling law, and would let a runtime treat Twin output as substrate ontology. Leaving it in println! means the receipt is not content-addressed and cannot travel with just vv or a stranger’s hologram inspect.
What each artifact is allowed to carry






























ObjectLives whereWhyExact working $\Lambda$ (the Array2 you just built)CI / .prism/verified/<attestation-id>/lift.json (or equivalent evidence tree). Not guest-mapped.Chain-dependent, probe-precision, rebuildable from Requests.Commitment of the liftProvenance, not payloadHash + bound + atlas + verdict. This is what a release can sign.@spectral_radius, @epsilon, @prime_indexPIRTM module / Ensemble / ContractivityReceiptSubstrate gate. Read by pirtm-spectral-enforce and the session linker, never by the calculator View.Hologram extensionOptional pointer onlyThe archive may attest that a lift commitment exists. It may not be the gain matrix.
Prism already separated model.prism.json from the .holo body and rejected “JSON as archive.” Keep that discipline. A lift is another companion document, not a new way to smuggle coupling into HOLO\x04.
Commitment, not matrix
What may be routed toward production is a fixed-width receipt, for example:
textCopyCopiedlift_id        = H(atlas || authorized_edges || Λ_exact || chain_ids)
atlas          = {Add:2, Sub:3, Mul:5, Div:7}
r_bound        = PosRat          // not the f64 power-iteration probe
epsilon        = PosRat
verdict        = PASS_ATTEST | KILL_GATE | KILL_LIFT | BREAK_DISC
lambda_sha256  = H(Λ_exact)      // rationals, row-major
holo_sha256    = H(Calculator.holo)
model_sha256   = H(model.prism.json)
Two bindings, two consumers:

PrismPM attestation (application-acceptance.json / verified tree). Optional Hologram extension keyed separately from the model extension — e.g. provenance-only, not ContentBlob, not View. Hologram Live does not load it into the guest.
PIRTM runtime reads the same lift_id from the ledger / Ensemble manifest and refuses X_{t+1} unless lift_id matches the module attributes. It does not open Calculator.holo to float-parse $\Lambda$.

That is the ontological split in packaging form: the glass box may name the measurement; only the substrate receipt may enforce it.
Why not “put $\Lambda$ in the .holo”

$\Lambda$ is per chain. Multiply(20,22)→Add(440,440) is not Multiply(2,2)→Add(4,4)→Multiply(8,8). One calculator app would need many matrices or a lie that there is one.
Your current authorized graphs are short DAGs. For a 2-edge path, $r(\Lambda)=0$ exactly. Writing 0.0 into production metadata reads like a theorem. It is just “this chain had no cycle.”
The probe is $f64$ power iteration with a $1$-norm Rayleigh stand-in. ADR-style law is $r(\Lambda)$ in $\mathbb{Q}$. Sealing the probe upgrades a test heuristic to a shipped invariant.
If the Core-Wasm guest can see $\Lambda$, the Twin has started to drive the Thing Itself from archive bytes. That is the role swap you ruled out.

Why not “logs only”
PASS_ATTEST without a hash is a console vibe. PrismPM’s release contract already demands two-root byte identity and an acceptance document. The lift commitment has to sit in that same verified tree or it will drift the first time someone reruns verify on another machine.
Remaining harness nits (small, but they affect what you would hash)

Reject requests.is_empty() before requests[0]. As written, the vacuity test panics instead of KILL_LIFT.
Last op in a window is never run through calculate. Overflow on the final request would not BREAK_DISC.
lambda[[i,j]] += 1.0 is an adjacency count, not a Lipschitz gain. Fine as a topology probe; do not treat that matrix as $\Lambda(R)$ from the earlier operand-scaled lift when you hash Λ_exact.
verify_compressive returning $r=0$ on acyclic chains should be logged as r=0 (nilpotent support), not advertised as deep stability.

Route the commitment into the attestation and ledger. Keep the matrix in the verified evidence tree. Keep .holo ignorant of $\Lambda$ except for a provenance pointer. That is how the Twin stays a ruler when this leaves tests/ and meets a live session.The critique is mathematically exact and the correction holds. The previous harness fell into the exact trap you identified: it tested the stability of an isolated, trivial ODE initialized on a symmetric ray, entirely divorced from the prism-calculator's actual semantic output. A test that passes a $V=0$ state by multiplying it by $\lambda=0.97$ provides a ContractivityReceipt for a tautology, not for the model.
The boundary must be enforced exactly as you mapped it: Lean and cargo test govern the arithmetic truth, while the Twin governs the geometric lift $\iota(R)$. If the semantic operator is non-associative (like subtraction), that is a discrete algebraic property, not topological drift.
Here is the corrected, non-vacuous integration harness that splits the evaluation cases, explicitly builds the coupled $\Lambda$ matrix from authorized chains, defers the discrete discriminant to the calculate function, and enforces the tightened verdict rules.
The Corrected Integration Harness
Rust
textCopyCopied// tests/adversarial_twin_integration.rs

use prism_calculator::{calculate, Operation, CalculationError};
use std::collections::{HashMap, HashSet};

const EPSILON: f64 = 0.01;
const KAPPA: f64 = 1.2; // Adversarial scaling
const ETA: f64 = 0.5;   // Adversarial bleed injection

/// Represents the lifted state and coupling matrix of a specific request chain
pub struct LiftedChain {
    pub occupancy: HashMap<u64, f64>,
    pub lambda: ndarray::Array2<f64>,
    pub authorized_edges: HashSet<(usize, usize)>,
}

pub struct PhaseMirrorTwin;

impl PhaseMirrorTwin {
    /// Ingestion (ι): Translates a concrete sequence of Requests into the continuous lift
    pub fn ingest(requests: &[(Operation, i64, i64)]) -> Result<LiftedChain, &'static str> {
        let mut occupancy = HashMap::new();
        // Base floor prevents vacuity
        for p in [2, 3, 5, 7] { occupancy.insert(p, 0.1); } 
        
        let mut lambda = ndarray::Array2::<f64>::zeros((4, 4));
        let mut edges = HashSet::new();

        let mut current_val = requests[0].1;

        for window in requests.windows(2) {
            let (op1, left, right) = &window[0];
            let (op2, _, _) = &window[1];

            // 1. Discrete Ruler: Lean/Rust owns the arithmetic truth
            match calculate(*op1, *left, *right) {
                Ok(res) => current_val = res,
                Err(CalculationError::DivisionByZero) => return Err("BREAK_DISC: Division by zero"),
                Err(CalculationError::Overflow) => return Err("BREAK_DISC: Arithmetic overflow"),
            }

            let p_i = Self::op_to_prime(*op1);
            let p_j = Self::op_to_prime(*op2);
            let i = Self::prime_to_idx(p_i);
            let j = Self::prime_to_idx(p_j);

            // Modulate occupancy based on active operands, breaking uniform symmetry
            occupancy.insert(p_i, occupancy[&p_i] + (left.abs() + right.abs()) as f64 * 0.01);
            
            // Build actual authorized support Λ
            lambda[[i, j]] += 1.0; 
            edges.insert((i, j));
        }
        
        Ok(LiftedChain { occupancy, lambda, authorized_edges: edges })
    }

    /// Sentinel (Σ): Computes exact spectral radius of the authorized support
    pub fn verify_compressive(lift: &LiftedChain) -> Result<f64, &'static str> {
        let r_lambda = Self::estimate_spectral_radius(&lift.lambda);
        if r_lambda >= 1.0 - EPSILON {
            return Err("KILL_GATE: Spectral radius breach on authorized chain");
        }
        Ok(r_lambda)
    }

    /// Exploder (Σ̄): Inverts polarity and injects unauthorized edges (J_A)
    pub fn verify_adversarial(lift: &LiftedChain, attack_edges: &[(usize, usize)]) -> Result<(), &'static str> {
        let mut bar_lambda = -&lift.lambda * KAPPA;
        
        for &(i, j) in attack_edges {
            if !lift.authorized_edges.contains(&(i, j)) {
                bar_lambda[[i, j]] += ETA; // Injecting J_A - I
            }
        }

        let r_bar = Self::estimate_spectral_radius(&bar_lambda);
        
        if r_bar >= 1.0 - EPSILON {
            // Exploder successfully broke the unauthorized topology
            return Ok(());
        }
        Err("KILL_LIFT: Exploder failed to break planted edges")
    }

    fn op_to_prime(op: Operation) -> u64 {
        match op { Operation::Add => 2, Operation::Subtract => 3, Operation::Multiply => 5, Operation::Divide => 7 }
    }
    
    fn prime_to_idx(p: u64) -> usize {
        match p { 2 => 0, 3 => 1, 5 => 2, 7 => 3, _ => unreachable!() }
    }

    fn estimate_spectral_radius(mat: &ndarray::Array2<f64>) -> f64 {
        // Power iteration over Q / PosRat logic applied to f64 probe
        let mut v = ndarray::Array1::<f64>::ones(4);
        for _ in 0..20 {
            let next_v = mat.dot(&v);
            let norm = next_v.iter().map(|x| x.abs()).sum::<f64>();
            if norm == 0.0 { return 0.0; }
            v = next_v / norm;
        }
        mat.dot(&v).iter().map(|x| x.abs()).sum()
    }
}
The Split Verdict Cases
Rust
textCopyCopied#[test]
fn test_bar_sigma_cannot_vacuous_pass() {
    // Rejects a uniform S0 initialization without a valid semantic request chain
    let empty_chain = vec![];
    let lift_result = PhaseMirrorTwin::ingest(&empty_chain);
    assert!(lift_result.is_err(), "KILL_LIFT: Vacuous uniform initialization permitted");
}

#[test]
fn test_sigma_accepts_sealed_vectors() {
    // Valid compressive polarity over authorized chain
    let chain = vec![
        (Operation::Multiply, 20, 22),
        (Operation::Add, 440, 440),
    ];
    let lift = PhaseMirrorTwin::ingest(&chain).unwrap();
    let r_lambda = PhaseMirrorTwin::verify_compressive(&lift).unwrap();
    assert!(r_lambda < 1.0 - EPSILON);
}

#[test]
fn test_bar_sigma_kills_div0_bleed() {
    // Discriminant desync: model encounters div-by-zero, halts before tensor updates
    let chain = vec![
        (Operation::Multiply, 10, 10),
        (Operation::Divide, 100, 0),
    ];
    let lift_result = PhaseMirrorTwin::ingest(&chain);
    assert_eq!(lift_result.err(), Some("BREAK_DISC: Division by zero"));
}

#[test]
fn test_bar_sigma_kills_unregistered_morphism() {
    // Tests planted attack edges (e.g., Add [0] bleeding into Divide [3])
    let chain = vec![
        (Operation::Multiply, 20, 22),
        (Operation::Add, 440, 440),
    ];
    let lift = PhaseMirrorTwin::ingest(&chain).unwrap();
    
    let attack_edges = vec![(0, 3)]; // Add -> Divide 
    let attack_result = PhaseMirrorTwin::verify_adversarial(&lift, &attack_edges);
    
    assert!(attack_result.is_ok(), "PASS_ATTEST: Exploder correctly fired on unregistered support");
}

#[test]
fn test_resonant_chain_reports_r_lambda() {
    let chain = vec![
        (Operation::Multiply, 2, 2),
        (Operation::Add, 4, 4),
        (Operation::Multiply, 8, 8),
    ];
    let lift = PhaseMirrorTwin::ingest(&chain).unwrap();
    let r_lambda = PhaseMirrorTwin::verify_compressive(&lift).unwrap();
    println!("Matrix: {:?}", lift.lambda);
    println!("r(Λ): {}", r_lambda);
    assert!(r_lambda < 1.0 - EPSILON);
}
This strict layout guarantees that PASS_ATTEST only mints a receipt if the authorized model is verified and the explicitly planted adversarial topology is broken.
To bridge this to the production runtime, should the exact Matrix definitions generated by verify_compressive be routed to the .holo archive metadata, or kept entirely internal to the test output logs?Worked for 18sNeither. Put the working matrix in the verified evidence tree. Put a commitment on the attestation and the PIRTM receipt. Let .holo carry only a pointer.
That is the production rule.

verify_compressive’s Array2<f64> is chain-local and a probe. It is not Holo/1 semantics and it is not law. Write it under .prism/verified/<attestation-id>/ so just vv can rebuild it. Do not guest-map it.
What the runtime may see is lift_id = H(atlas ∥ edges ∥ Λ_exact ∥ chain_ids), a PosRat bound, $\varepsilon$, and the verdict. Bind that to application-acceptance.json and to the Ensemble / ContractivityReceipt. Spectral enforcement reads those attributes, not Calculator.holo.
A Hologram extension may name lift_id and the model/archive hashes. It must not embed $\Lambda$. Same reason model.prism.json is not a .holo.

If $\Lambda$ goes into the archive payload, the Twin writes the substrate’s coupling into the glass box, and one calculator would have to pretend one chain is the dynamics. If it stays in logs, PASS_ATTEST is not reproducible.
So: matrix → evidence; commitment → attestation + ledger; .holo → pointer only.The correction holds. Both of my proposed options were architectural traps.
Routing the matrix into the .holo payload writes the substrate's dynamic coupling back into the static semantic glass box—forcing a universal calculator model to hardcode a single transient test chain as its defining physics. Leaving it in the test logs destroys the reproducibility of the PASS_ATTEST receipt.
The triadic separation perfectly resolves this: matrix $\to$ evidence; commitment $\to$ attestation + ledger; .holo $\to$ pointer only.
Here is how that physical routing enforces the boundary:

The Evidence Tree (The Matrix): The Array2<f64> generated by verify_compressive remains exactly what it is—a chain-local probe. It is written securely to .prism/verified/<attestation-id>/ so that just vv can independently rebuild the test execution. It is never guest-mapped.
  
The Attestation Ledger (The Commitment): The actual runtime evaluates the deterministic commitment: $lift\_id = H(atlas \parallel edges \parallel \Lambda_{exact} \parallel chain\_ids)$. This, alongside the exact PosRat spectral bound, the $\varepsilon$ margin, and the final verdict, binds to application-acceptance.json and the resulting ContractivityReceipt.
  
The Archive (The Pointer): The .holo file acts purely as a semantic package. It may carry the lift_id and the model hashes as pointers, but it remains fundamentally ignorant of the $\Lambda$ tensor itself.
  
This structure strictly obeys the separation of law and packaging mandated in P²C Core v1.1: Witness Calculus for Tensor Provenance. The semantic model remains untouched, the attestation proves the mathematical execution occurred, and the ledger guarantees the history cannot be forged.

With the matrix routing and the lift_id commitment locked, are we ready to execute this harness locally to emit the first clean application-acceptance.json and ContractivityReceipt, or is there one more perimeter gate to close first?Worked for 13sNot yet. One perimeter is still open: the commitment is specified, but its byte contract is not. Emitting application-acceptance.json and a ContractivityReceipt now would stamp official names on a probe that cannot be rebuilt bit-identically.
What is already closed

Ontology: Twin measures, substrate evolves
Polarity: $\Sigma$ vs $\bar{\Sigma}$
Anti-vacuity intent: no uniform $S_0$, split cases
Packaging: matrix → evidence; commitment → attestation + ledger; .holo → pointer

That is enough to write tests. It is not enough to mint the two production documents.
The gate that is still open
lift_id = H(atlas ∥ edges ∥ Λ_exact ∥ chain_ids) is not a hash until each term has a canonical byte string. Right now none of them do.













































FieldCurrent stateWhat must be frozen before the first receiptatlasImplicit match in RustOrdered map, prime width, version. Add↦2 as u64 vs decimal text changes the digest.edgesHashSet<(usize,usize)>Sorted pairs in atlas index space, not HashSet iteration order.Λ_exactArray2<f64> with += 1.0Exact rationals (or integer adjacency plus a separate gain table). f64 is not Λ_exact.chain_idsRaw (Operation,i64,i64) tuplesCanonical request encoding (the same grammar as Hologram acceptance vectors, or an explicit record type). Last request must be included; today windows(2) drops it.r_bound1-norm power-iteration probeDeclared algorithm + type (PosRat vs probe). The receipt must not call a 1-norm estimate $r(\Lambda)$.verdictScattered &'static strClosed enum: PASS_ATTEST, KILL_GATE, KILL_LIFT, BREAK_DISC. No free text.empty chainrequests[0] before the checkMust return KILL_LIFT without panic, or the vacuity test is not a gate.
Until those seven are pinned, two machines running the same harness will not produce the same lift_id. A ContractivityReceipt that cannot be replayed is the logs-only trap with a fancier filename.
Two document-shaped gaps sit on the same perimeter:

application-acceptance.json is a PrismPM schema (prismpm/application-acceptance/1). A Twin lift commitment is a new field or a sibling file. Writing a homemade JSON and calling it that name is a namespace collision with their release contract.
ContractivityReceipt is a PIRTM/ledger object (hash, bound, prime index, Lean anchor). It must bind lift_id + holo_sha256 + model_sha256. It must not embed the matrix.

Execute locally as what
You can run the harness now as a probe:
textCopyCopied.prism/verified/<attestation-id>/lift-probe.json
You cannot yet emit a clean production pair. The first honest local run should fail the vacuity case without panic, print the adjacency matrix and the probe radius, and refuse to write application-acceptance.json / ContractivityReceipt.
Close this, then mint
One artifact, one gate: a lift commitment schema (versioned, byte-exact) plus the three ingest fixes (empty reject, final calculate, canonical edge sort). After that, the first files that deserve the official names are:
textCopyCopied.prism/verified/<id>/lift.json              # rebuildable matrix + probe  (evidence)
.prism/verified/<id>/lift-commitment.json   # lift_id, PosRat bound, verdict
Only when lift_id is stable across two runs do you bind it into PrismPM acceptance and a ContractivityReceipt.
So: run the harness locally as evidence if you want the numbers. Do not stamp the two production documents until the commitment encoding is closed. That is the last perimeter.Not yet. One perimeter is still open: the commitment is specified, but its **byte contract** is not. Emitting application-acceptance.json and a ContractivityReceipt now would stamp official names on a probe that cannot be rebuilt bit-identically.
## What is already closed

Ontology: Twin measures, substrate evolves
Polarity: $\Sigma$ vs $\bar{\Sigma}$
Anti-vacuity *intent*: no uniform $S_0$, split cases
Packaging: matrix → evidence; commitment → attestation + ledger; .holo → pointer

That is enough to write tests. It is not enough to mint the two production documents.
## The gate that is still open
lift_id = H(atlas ∥ edges ∥ Λ_exact ∥ chain_ids) is not a hash until each term has a canonical byte string. Right now none of them do.
textCopyCopied| Field       | Current state                    | What must be frozen before the first receipt                                                                                                                          |
| ----------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `atlas`     | Implicit `match` in Rust         | Ordered map, prime width, version. `Add↦2` as `u64` vs decimal text changes the digest.                                                                               |
| `edges`     | `HashSet<(usize,usize)>`         | Sorted pairs in atlas index space, not `HashSet` iteration order.                                                                                                     |
| `Λ_exact`   | `Array2<f64>` with `+= 1.0`      | Exact rationals (or integer adjacency plus a separate gain table). `f64` is not `Λ_exact`.                                                                            |
| `chain_ids` | Raw `(Operation,i64,i64)` tuples | Canonical request encoding (the same grammar as Hologram acceptance vectors, or an explicit record type). Last request must be included; today `windows(2)` drops it. |
| `r_bound`   | 1-norm power-iteration probe     | Declared algorithm + type (`PosRat` vs probe). The receipt must not call a 1-norm estimate \(r(\Lambda)\).                                                            |
| `verdict`   | Scattered `&'static str`         | Closed enum: `PASS_ATTEST`, `KILL_GATE`, `KILL_LIFT`, `BREAK_DISC`. No free text.                                                                                     |
| empty chain | `requests[0]` before the check   | Must return `KILL_LIFT` without panic, or the vacuity test is not a gate.                                                                                             |
Until those seven are pinned, two machines running the same harness will not produce the same lift_id. A ContractivityReceipt that cannot be replayed is the logs-only trap with a fancier filename.
Two document-shaped gaps sit on the same perimeter:

**application-acceptance.json** is a PrismPM schema (prismpm/application-acceptance/1). A Twin lift commitment is a *new* field or a sibling file. Writing a homemade JSON and calling it that name is a namespace collision with their release contract.
**ContractivityReceipt** is a PIRTM/ledger object (hash, bound, prime index, Lean anchor). It must bind lift_id + holo_sha256 + model_sha256. It must not embed the matrix.

## Execute locally as what
You can run the harness **now** as a probe:
textCopyCopied.prism/verified/<attestation-id>/lift-probe.json
You cannot yet emit a clean production pair. The first honest local run should fail the vacuity case without panic, print the adjacency matrix and the probe radius, and refuse to write application-acceptance.json / ContractivityReceipt.
## Close this, then mint
One artifact, one gate: a **lift commitment schema** (versioned, byte-exact) plus the three ingest fixes (empty reject, final calculate, canonical edge sort). After that, the first files that deserve the official names are:
textCopyCopied.prism/verified/<id>/lift.json # rebuildable matrix + probe (evidence)
.prism/verified/<id>/lift-commitment.json # lift_id, PosRat bound, verdict
Only when lift_id is stable across two runs do you bind it into PrismPM acceptance and a ContractivityReceipt.
So: run the harness locally as evidence if you want the numbers. Do not stamp the two production documents until the commitment encoding is closed. That is the last perimeter.