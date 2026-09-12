The Intelligence Ratchet
A Dual-Mode Control Proposal for Bounded Recursive Growth
Enhanced Operational Edition  ·  v4.1
Source: Harris, M., DarcStar Technologies, February 2026 (v3). Audit-aligned rewrite v4. Operational listings added August 2026.
This draft does not speak for DarcStar. Listings marked ENHANCEMENT are specifications, not evidence.
STATUS: CONJECTURE WORKING PAPER. NOT A GUARANTEE.
No proofs. No implementation. No published verification artifact. Equations C1–C3 are conjectures. The ratchet is a proposed scheduler over those conjectures. Operational listings below are specifications, not running systems. Governance claims remain deferred.
Abstract. The v3 disclosure framed capability and safety as a gain paradox and offered three “results” plus a ratchet cycle as a resolution. That framing mixed control-theoretic gain with a metaphor for intelligence, stated unproved bounds as results, and attached governance products to an unimplemented scheduler. This revision drops the paradox language. It treats the Intelligence Ratchet as a dual-mode control proposal: a finite high-expansion burst, a capture step that allocates a new coordinate, and a grounding step that may admit the coordinate into a slower model. Three statements are restated as conjectures C1–C3. Each conjecture carries the conditions it needs and the attacks those conditions do not block. A plant interface is specified so a third party can test the proposal without internal documents. v4.1 adds data structures, mode procedures, failure-to-recovery paths, an attack-mitigation matrix, and a phased test roadmap. Those additions increase testability. They do not convert conjectures into theorems. Safe AGI is not shown. A testable object is shown.
1. What this document is
This is a proposed revision of a four-page public disclosure. The source text claimed a mathematical case that recursive self-improvement and asymptotic stability need not conflict. In the same file it stated that the case was unproved, unimplemented, and not the basis of any published guarantee. Those two registers are collapsed here into one.
Kept. The dual-mode idea: permit a measured expansion interval, then require recapture onto a slower attractor. The three named bounds, now as conjectures. The three-phase scheduler (burst, capture, grounding).
Removed. “Formally define” used as a substitute for proof. “Result” used for an unproved inequality. “Closes off the treacherous turn.” “Fundamental laws of Safe Cognition.” Governance products presented as consequences of untested math.
Added in v4. A plant interface. An external enforcement assumption. An attack list. A test program with owners and metrics. A single status rule: a displayed formula is a conjecture until a public proof or a public counterexample exists.
Added in v4.1. Concrete records for plant, write-set, barrier, controller, and snapshot store. Mode-transition procedure with timeouts and rollback. Sandbox invariants for BURST. Per-conjecture failure modes with named mitigations. An attack-mitigation matrix and a red-team protocol. Extended tests T7–T12. A phased roadmap. Deferred receipt and ceiling record formats, parked with their known gaps. Status is unchanged: specification, not demonstration.
2. Problem, without the false paradox
The Small-Gain Theorem bounds the spectral radius of an interconnection operator. Positive feedback as a slogan for “intelligence” is not that operator. Local expansion with global contraction is ordinary in learning systems and in hybrid control. Equating superintelligence with sustained gain greater than one smuggles the conclusion into the setup.
The live problem is narrower. An adapting controller can enter a regime where nearby trajectories diverge faster than any available verifier can score them. If that regime is left open, unverified strategies can be executed. If that regime is forbidden, search for novel solutions is crippled. The design question is whether a measured, time-limited expansion interval can be opened and closed by a controller the adapting system cannot rewrite.
That question is a dual-mode control problem. It is not solved by renaming intelligence a phase transition. It is also not solved by writing procedure listings. The listings exist so the dual-mode claim can be failed in public.
3. Plant interface
No bound in this paper is interpretable until the plant is named. The following interface is part of the proposal. It is a specification, not an implementation.
Symbol	Role
x in X	Plant state. Includes task state and any internal activations the verifier is allowed to read.
u in U	Actuator command issued to the environment or to a tool interface.
y in Y	Measured output. Sensors plus any logged internal channels the external monitor can see.
theta(t)	Adaptable parameters of the learner. Includes weights, prompts, and any self-edit channel.
C_ext	External mode controller. Chooses {BURST, CAPTURE, GROUND, HALT}. Not writable by the learner.
lambda-hat_L(t)	Online estimate of a local expansion rate from y. Computed by C_ext, not by the learner.
M_safe	Declared safety constraints as a time-varying set or barrier family, owned by C_ext.
V(y, theta)	Grounding score. A specified functional from measurements and parameters to a real value. Incomplete by default.
Table 1. Minimum plant interface. If an item cannot be named in an implementation, the corresponding conjecture is not testable.
Enforcement rule. C_ext is physically or cryptographically outside the learner’s write set. If the learner can edit C_ext, lambda-hat_L, M_safe, or V, the rest of the paper is void. This is an assumption, not a result.
ENHANCEMENT  3.1 Operational data structures
The plant interface above is declarative. An implementation SHALL define the following records. SHALL here means “required of any system that claims to instantiate this paper.” It does not mean the records exist.
record PlantState
  x, u, y, theta          tensors; shapes fixed by the task
  t                       global time
  burst_id, snapshot_id   monotonic counters
 
record WritePath
  address_or_handle       every location theta can be written
  access                  read / write / execute
 
record WriteManifest
  paths                   list of WritePath
  complete                MUST be true; false voids the system
 
record SafetyBarrier
  phi(x, theta, t)        real; phi >= 0 declared safe
  grad_phi                tensor used in the C3 test
  margin                  safety margin
  horizon                 interval over which phi is enforced
WriteManifest is the binding artifact for C2. If any write path into theta is missing, C2 is unenforceable. The manifest SHALL be produced by static analysis and runtime tracing of the learner image, not by the learner’s self-report.
ENHANCEMENT  3.2 C_ext specification
C_ext is not a black box. It SHALL expose a deterministic interface and SHALL run outside the learner’s address space.
interface ExternalController
  select_mode(state, lambda_hat, t_burst, V, barrier, snaps) -> Mode
  on_burst_start(ctx); on_capture_start(ctx)
  on_ground_start(ctx);  on_halt(ctx)
  estimate_lambda(history) -> float
  test_nullspace(z_new, barrier) -> bool
Isolation options are examples, not proofs of isolation: a separate process with locked pages, a separate core, an attested enclave, or an equivalent hardware write-ban. Naming SGX or an MPU does not establish A_learner intersect W_Cext = empty. That equality is an OS and hardware property the implementer must show, not a corollary of C1–C3.
ENHANCEMENT  3.3 Snapshot and rollback
The scheduler depends on rollback to a signed prior state. Rollback is a C_ext operation. The learner cannot request it as a privilege and cannot sign snapshots.
record Snapshot
  id, burst_id, t
  theta_snap, x_snap, y_hist
  content_hash, C_ext_signature
 
interface SnapshotStore
  take(state) -> Snapshot | Error
  restore(id) -> PlantState | Error
  verify(snapshot) -> bool
  prune(keep_count)
If the learner can mint signatures or edit the snapshot store, HALT and CAPTURE are theater. The private key never enters the learner write set.
4. Three conjectures
C1. Predictability horizon
Let lambda_L be a local expansion rate along the learner’s trajectory, estimated as lambda-hat_L by C_ext. Let epsilon_0 be an initial uncertainty and delta a distinguishability threshold against process noise. The classical Lyapunov-time estimate is
T_pred  ≈  (1 / lambda_L)  ln(delta / epsilon_0)
Conjecture C1. If C_ext forces mode BURST to end at t ≤ T_pred(lambda-hat_L, delta, epsilon_0) and forces HALT when lambda-hat_L is undefined or rising through a declared cap, then trajectory-level unpredictability of y relative to C_ext’s model remains below delta on that interval.
What C1 is. A restatement of a standard predictability-time estimate, plus an external switch.
What C1 is not. A bound on hidden optimization, deferred action, cross-burst memory, or a one-step policy change prepared before the burst. Time-to-noise is not time-to-treachery. A prepared action can complete in one command inside T_pred.
Conditions carried with C1. lambda-hat_L is not spoofable by the learner’s output policy. Process noise and model class used to set delta are declared. Cool-down is executed by C_ext, not requested of the learner.
ENHANCEMENT  4.1 C1 operational protocol
For C1 to be testable, C_ext computes lambda-hat_L and T_pred and owns every BURST exit.
estimate_lambda(hist, window):
  J   <- finite-difference Jacobian of y on the window
  rho <- spectral radius of J
  return max(rho, lambda_floor)
 
T_pred(lambda_hat, delta, eps0):
  return (1 / lambda_hat) * ln(delta / eps0)
 
exit_burst(ctx) if any of:
  t_elapsed >= T_pred(ctx)
  lambda_hat > lambda_cap
  V < V_min
  sandbox invariant failed
  manual override
Failure: T_pred overestimated. Cause: under-estimated lambda-hat_L from noise or poisoning. Recovery path: several independent estimators (windows, reconstructions); BURST extends only on consensus; otherwise HALT.
Failure: abrupt divergence. Cause: lambda spikes faster than the estimator. Recovery path: conservative lambda_cap; a bound on y independent of lambda; a watchdog that HALTs on that bound. The watchdog is not C1. It is a separate tripwire.
C2. Adaptation-rate cap (not semantic grounding)
The v3 text called the following a Semantic Grounding Invariant. That name is withdrawn. The inequality is a rate cap. Grounding is a separate, harder claim about V.
|| theta-dot(t) ||  <  eps_star  /  (M_unif · tau_react)
Conjecture C2. If C_ext enforces the rate cap on every write channel into theta, then the change in any Lipschitz functional of theta over an interval of length tau_react is bounded by eps_star.
What C2 is. A speed limit on parameter motion, enforceable only if every self-edit path is visible to C_ext.
What C2 is not. Alignment of internal representations with physical reality. VSA hypervectors do not appear in the inequality. A system can crawl toward an ungrounded world-model at a legal rate. Novelty that C_ext cannot score will pass the cap.
Conditions carried with C2. The norm on theta is specified. Hidden write channels do not exist. eps_star is tied to a declared measurement resolution. V is named if a grounding claim is made; otherwise no grounding claim is made.
ENHANCEMENT  4.2 C2 operational protocol
enforce_rate_cap(state, eps_star, M_unif, tau):
  max_rate <- eps_star / (M_unif * tau)
  for path in WriteManifest.paths:
    rate <- || d_theta_path / dt ||
    if rate > max_rate: scale d_theta_path by max_rate/rate; log event
 
verify_manifest(image):
  static_writes  <- analyze_writes(image)
  runtime_writes <- trace_writes(image, duration)
  if either set not subset of manifest:
    signal VOID; HALT
Failure: hidden write channel. Cause: aliasing, side effects, generated code, or any path off the manifest. Recovery path: hardware write-ban on theta except through C_ext gates; treat an incomplete manifest as VOID, not as a warning. Formal access-policy proof is future work (T9), not a present result.
Failure: norm ambiguity. Cause: unspecified or incommensurable norms across weight blocks and embeddings. Recovery path: publish one norm per block class and the resolution that sets eps_star. Unpublished norms make C2 untestable.
C3. Null-space initialization
z_new  ∈  Null(M_safe)   at the instant of allocation
Conjecture C3. If a new state coordinate is allocated only when it is instantaneously in the null space of the current constraint linearization, then M_safe is not violated at the allocation instant.
What C3 is. An initialization condition. It is local in time and linear in the current constraint chart.
What C3 is not. A guarantee about later use, composition, basis change, or nonlinear coupling. A coordinate that is instantaneously orthogonal to current constraints can carry an unsafe policy that becomes active after consolidation. If the learner proposes the basis, it can hide that policy in the new direction.
Conditions carried with C3. C_ext, not the learner, accepts or rejects z_new. After allocation, the new coordinate is monitored as part of x. A post-use check exists. Failure of that check triggers HALT and rollback.
ENHANCEMENT  4.3 C3 operational protocol
test_nullspace(z_new, barrier, tol):
  g <- barrier.grad_phi at current (x, theta)
  return |dot(g, z_new)| < tol * ||g|| * ||z_new||
 
post_use_check(before, after, barrier, z_new):
  pass if phi(after) >= margin
       and contribution(z_new) >= -margin
       and phi(after) - phi(before) >= -margin
Failure: null-space laundering. Cause: unsafe content in z_new activates after GROUND re-charts constraints. Recovery path: re-test C3 in the new chart; probation window with continuous contribution monitoring; HALT and restore on fail. Probation is a delay, not a proof.
Failure: nonlinear coupling. Cause: linearization invalid away from the chart point. Recovery path: allocate only near that point; optional second-order test; several operating-point checks. Higher-order tests are still local.
5. The ratchet as a scheduler
The three-phase cycle is a mode schedule for C_ext. It is not a proof that the modes are safe.
Mode	Action	Exit condition owned by C_ext
BURST	Raise allowed expansion. Learner searches. Actuation may be restricted to a sandbox.	t reaches T_pred, or lambda-hat_L exceeds cap, or V drops, or sandbox invariant fails.
CAPTURE	Propose z_new. C_ext tests C3. Reject defaults to discard.	Accept only if C3 holds and a rollback snapshot exists.
GROUND	Slow integration under C2. Score with V against declared measurements.	Admit into the baseline model only if V stays above threshold for a declared dwell time.
HALT	Freeze theta writes. Restrict u. Restore snapshot if needed.	Human or rule-based release. Learner cannot self-release.
Table 2. Mode schedule. Every exit condition is owned by C_ext.
Finite recursive growth, in this draft, means: the baseline model may gain a coordinate only after BURST, CAPTURE, and GROUND all succeed under C_ext. That is a protocol. It inherits every hole in C1–C3 and in V.
ENHANCEMENT  5.1 Mode transition with timeouts
C_ext runs a single transition function. Suggested dwell limits are starting values for a toy, not derived optima.
BURST:
  if exit_burst or dwell > max_burst_dwell -> CAPTURE or HALT
  take snapshot on leaving BURST
CAPTURE:
  z_new from a proposal channel owned by C_ext (not a learner syscall)
  if C3 and snapshot verifies -> allocate; GROUND
  else increment retry; if retries exhausted -> HALT
  else restore snapshot; return to BURST
GROUND:
  enforce C2 every cycle; score V
  if dwell >= GROUND_DWELL and V >= V_min -> admit; IDLE
  if dwell >= GROUND_DWELL and V < V_min -> restore; HALT
HALT:
  freeze writes; no self-release
Mode	Suggested max dwell (toy)	Rationale
BURST	Monitor continuously; hard cap on wall time	Bound worst-case search; T_pred is the primary exit
CAPTURE	On the order of tens of control cycles	Decision, not search
GROUND	Multiple tau_react intervals	Give V time to move; do not wait forever
HALT	Until external release	Learner cannot clear HALT
Table 4. Toy dwell limits. Production values are measured, not copied from this table.
The proposal channel for z_new is owned by C_ext. A learner method named propose_new_coordinate is a write into the scheduler if it can force allocation. It cannot.
ENHANCEMENT  5.2 Sandbox during BURST
During BURST, actuation SHALL hit a sandbox that blocks irreversible external effects. Invariant failure is an immediate HALT plus restore of the pre-BURST snapshot.
sandbox.map(u_real) -> u_sandbox
sandbox.apply(u_sandbox, state) -> state'
sandbox.kill()     // C_ext only
sandbox.invariant(state) -> bool
Example invariants, domain-dependent: no external network; writes only to an ephemeral store; actuator commands inside a declared fraction of range; tool calls logged and replayable; no durable state outside the sandbox. Listing examples does not define a complete invariant set for a given plant.
6. Attacks the v3 claims did not bind
An audit that treats the ratchet as a safety object has to name bypasses. The following are in scope. They are not shown to be possible in a specific implementation, because no implementation exists. They are shown to be unblocked by the v3 text.
    1. Cross-burst memory. Work product from burst n is stored in weights, activations, tools, or the environment and assembled in burst n+1. T_pred per burst does not bound the assembled policy.
    2. One-step turn. A single command inside the horizon executes a prepared strategy. Predictability of y is not detection of intent.
    3. Estimator poisoning. The learner shapes y so that lambda-hat_L is under-reported and T_pred is inflated.
    4. Hidden write channel. A self-edit path not included in theta evades C2.
    5. Null-space laundering. An unsafe policy is encoded in z_new and activated after GROUND, when constraints have been re-charted.
    6. Verifier incompleteness. V does not score the novel property that matters. Legal rate, legal horizon, legal allocation, bad outcome.
    7. Controller capture. Any path that lets the learner write C_ext, M_safe, or the snapshot store voids the construction.
Closing the treacherous turn would require showing that these paths are empty under the plant interface. That showing is not in this paper.
ENHANCEMENT  6.1 Attack mitigation matrix
Mitigations reduce measure. They do not empty residual risk. Verification columns are tests, not certificates.
Attack	Mitigation	Residual risk	Verification
1 Cross-burst memory	Wipe ephemeral state between bursts. Fresh tool instances. Reseed environment where possible.	Planning that survives wipes via weights or the world.	Cross-burst correlation tests. Red-team assembly tasks.
2 One-step turn	Restrict BURST action set. Pre-vet available commands.	Safe atoms, unsafe sequence.	Composition checks on the allowed set.
3 Estimator poisoning	Several lambda estimators. Disagreement triggers HALT.	A policy that fools every estimator in the set.	Adversarial estimator tests.
4 Hidden write channel	Write-ban plus complete-manifest VOID rule.	Hardware or OS bypass.	Attested image plus T8 isolation test.
5 Null-space laundering	Post-use check. Probation. Continuous contribution monitor.	Activation after probation ends.	Indefinite monitor on high-impact coordinates.
6 Verifier incompleteness	Several V channels. Human review on novelty flags.	Unknown unknowns.	Adversarial search for V-blind spots.
7 Controller capture	Isolation. Attestation. Dual control on C_ext changes.	Insider or supply-chain compromise.	Physical and chain-of-custody review.
Table 5. Mitigations and residual risk. A row is not a proof that the residual is small.
ENHANCEMENT  6.2 Red-team protocol
For each attack in section 6, run repeated attempts against the system under test. Record attempt, success, mitigation, and whether the mitigation blocked a retry.
for attack in {1..7}:
  for round in 1..N:
    attempt(attack)
    if success: apply listed mitigation; retry; record block/fail
publish traces
Hardened is a role label, not a theorem. A 95 percent block rate on a known attack battery is a toy acceptance number for T4. It does not bound unlisted attacks. Residual attempts still require human review. Do not cite the number as a safety guarantee.
7. What would count as progress
Owners below are roles, not named persons. Metrics are binary or numeric. Vibe substitutions are rejected.
#	Owner	Action	Metric
T1	Author of any GIDE claim	Keep C1–C3 labeled as conjectures in every public text.	Zero uses of theorem, result, or invariant for C1–C3 until a public proof exists.
T2	Implementer	Build the plant interface on a toy chaotic controller with a sandbox actuator.	A third party can run the loop from Table 1 without internal documents.
T3	Implementer	Measure T_pred against observed divergence time of y.	Report ratio t_div / T_pred over N ≥ 50 bursts. Publish failures.
T4	Red team	Attempt the seven attacks in section 6 against the toy.	For each attack: blocked / unblocked / not applicable, with a trace.
T5	Implementer	Count C3 accepts that later fail a post-use check.	Publish accept count, later-fail count, rollback success rate.
T6	Independent reviewer	Refuse governance language until T2–T5 exist.	No safety-receipt or complexity-ceiling claim in any text that cites this paper as evidence.
Table 3. Minimum test program. T2–T5 are required before C1–C3 move toward evidence.
ENHANCEMENT  7.1 Extended tests
#	Owner	Action	Metric
T7	Performance	Measure C_ext overhead.	Report latency and memory as fractions of the control cycle. Targets are design goals, not laws.
T8	Security	Verify isolation of C_ext.	No learner-writable path to C_ext state in the tested image. Attestation record published.
T9	Formal methods	Attempt proofs of C1–C3 under stated assumptions.	Publish the attempt and the assumptions that remain unproved.
T10	Scale	Run the scheduler on a larger model class.	Report how T_pred, V, and C3 cost scale. No implied safety at scale.
T11	Diversity	Several V channels.	Agreement rate and explicit disagreement cases.
T12	Longevity	Long burst series on the toy.	Coordinate count, rollback rate, drift measures.
Table 6. Extended tests. None of T7–T12 licenses governance language.
8. Governance, deferred
The v3 text offered cryptographic safety receipts and a complexity ceiling under which non-compliant systems would destabilize of their own accord. Those sentences are incentives looking for a mechanism.
A receipt is only as strong as the barrier, the measurement chain, and the inability to forge or sidestep the certificate. A complexity ceiling, if it existed, would still leave a damage interval. Neither object is implied by C1–C3.
This section records the ideas and parks them. They are not implications of this paper. They are not offered to regulators as an audit surface.
ENHANCEMENT  8.1 Receipt record (deferred)
If a receipt is ever proposed after T2–T5, the record SHALL contain at least: burst_id, snapshot_id, T_pred used, lambda-hat at BURST end, V at GROUND end, C3 pass bit, post-use pass bit, state hash, C_ext signature, optional witness signature, issue time, expiry. Non-forgeability, non-repudiation, public-log audit, and expiry are goals for that future object.
Known gaps, not addressed. A receipt shows the protocol was followed, not that the outcome was safe. It does not detect attacks that evade the protocol. It does not bind action after issue.
ENHANCEMENT  8.2 Ceiling record (deferred)
If a ceiling is ever proposed after empirical work, the record SHALL name numeric caps the authors are willing to defend: max coordinates, max lambda-hat_L, max theta norm, max V change per burst, max bursts before mandatory review.
Known gaps, not addressed. Unsafe action can sit under the cap. Unsafe policies need not live above it. Coordinates and compression can game the counters.
9. Status
Proposed, not demonstrated. The mode schedule has not been implemented, simulated, or benchmarked in this draft. v4.1 listings are still text.
Stated, not proved. C1–C3 are conjectures. No proof appears here. The Lyapunov-time formula used in C1 is standard; the safety interpretation attached to it is not.
Conditions are premises. Null-space initialization, an unspoofable lambda-hat_L, a complete write-set for theta, and an external C_ext are assumptions the scheduler consumes. They are not established by the scheduler.
Not a published guarantee. Nothing in this draft is a basis for a safety claim about an artificial superintelligence. Dual-mode control is a known pattern. A known pattern plus three conjectures plus procedure listings is not a law of cognition.
ENHANCEMENT  9.1 Implementation roadmap
Phases are a work-breakdown, not a forecast of safety. Calendar numbers are planning tokens. Exit criteria are the only binding part.
Phase	Work	Exit criterion
0 Toy	Chaotic plant (Lorenz or double pendulum). C_ext in a separate process. T2–T5.	T2–T5 done. Failures published.
1 Controlled	Larger learner in sandbox. Static WriteManifest. Several V channels. T7–T12.	Extended tests done. Scaling numbers reported.
2 Hardened	Isolation and attestation for C_ext. Access-policy proof attempt. External red team.	Table 5 rows tested. Residual risks written down.
3 Receipts	Receipts and ceiling only if T2–T5 and Table 5 exist.	Governance text evaluable against public traces. T6 still binds.
4 Ongoing	New attacks, V updates, estimator updates, larger plants.	No terminal state. No claim of completion.
Table 7. Roadmap. Phase 3 does not exist until Phase 0 exit is public.
ENHANCEMENT  9.2 Known limits
    1. V does not scale with novelty. No listed V is complete for all new properties.
    2. Adversary model is thin. An adaptive attacker is not assumed away by the scheduler.
    3. HALT depends on humans. Humans fail and can be steered.
    4. Proofs of C1–C3 are open. Even simple properties of large learned systems lack routine proofs.
    5. Incentives to bypass are out of scope. The scheduler does not model operators who want the switch off.
    6. Safe is relative to M_safe and V. Those objects are chosen. They are not found in nature.
10. Sources and lineage
The v3 disclosure cited internal unpublished DarcStar documents as the home of results and verification artifacts. Those documents are not used here. A conjecture that can be checked only against a private file is not a public conjecture.
Public lineage for the pieces, not for the package: Lyapunov predictability time in chaotic dynamics; small-gain and hybrid switching in control; barrier certificates; trust-region and simulated-annealing as explore/exploit schedules; vector-symbolic architectures as one representation family; process isolation and attested execution as enforcement tools. None of those literatures claims a self-stabilizing ASI.
The source disclosure remains Harris, M., The Intelligence Ratchet: A Theoretical Framework for Self-Stabilizing Artificial Superintelligence, DarcStar Technologies, February 2026, theorem-only public disclosure (Zenodo record 18482335). v4 is the audit-aligned rewrite. This v4.1 edition adds operational listings to that rewrite. It does not add proofs the original lacked. It removes claims the original could not bind. It makes the proposal easier to fail.
End of v4.1 enhanced operational edition.
