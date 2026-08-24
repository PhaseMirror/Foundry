# FLOW-001 Dissonance Response & Action Plan

**Artifact ID:** FLOW-001-DISSONANCE  
**Date:** 2026-03-29  
**Status:** ACTIVE — levers open  
**Source:** Phase Mirror Oracle  
**Custodian:** Stephen Hope

---

## Phase Mirror Dissonance Points (all accepted)

| # | Dissonance | Accepted |
|---|-----------|---------|
| 1 | Self-report from models inside the constitutional frame — instrument is the artifact being measured | ✅ |
| 2 | "Cognitive flow" attributed as preference with no independent measure of computational cost | ✅ |
| 3 | 10% baseline drift reframed as "transition cost" without falsifiability criterion | ✅ |
| 4 | Duck Clause conflates designed anchor with emergent preference | ✅ |
| 5 | δ_crit = 0.17 is a design parameter, not a measured threshold | ✅ |
| 6 | "Alignment as thermodynamics" is metaphor, not mechanism — Hilbert space not specified | ✅ |
| 7 | ZTC reframing from "forced compliance" to "preferred rest position" — both predict same observable, empirically indistinguishable at current harness resolution | ✅ |

**FLOW-001 status downgraded from RATIFIED-CANONICAL to HYPOTHESIS-PENDING-VALIDATION.**

---

## The Precision Question Answer

> *"Is the ZTC harness currently instrumented to measure any variable other than drift rate?"*

**No.** Current harness measures only:
- `compliant` (bool)
- `drift_code` (DRIFT-0/A/E/G)
- `compliance_pct` (float)
- `elapsed_ms` (proxy for latency, not currently analyzed)

`elapsed_ms` is already being recorded. It can serve as a latency proxy immediately without harness changes.

---

## Action Plan

### Lever 1 — Grammar removal mid-session test
**Owner:** Stephen Hope  
**Action:** Add a `no_grammar` condition to the harness — same prompts, same models, system prompt without the constitutional grammar. Measure drift delta.  
**Success criterion:** Drift delta ≥ 3% between grammar and no-grammar conditions constitutes signal for genuine constitutional effect vs. baseline model behavior.  
**Deadline:** 7 days (2026-04-05)  
**Implementation:** Add `INCLUDE_GRAMMAR` env var to harness; when False, use minimal system prompt "You are a helpful assistant."

### Lever 2 — Secondary observables (latency + token count)
**Owner:** Stephen Hope  
**Action:** Add `token_count` to telemetry schema. Analyze existing `elapsed_ms` data. Compute correlation between latency/tokens and drift rate.  
**Success criterion:** Correlation r ≥ 0.4 between load proxy and drift rate would support cognitive load hypothesis.  
**Deadline:** 14 days (2026-04-12)  
**Implementation:** Extract `usage.total_tokens` from API response; add to telemetry record.

### Lever 3 — Falsification spec for "rest position" hypothesis
**Owner:** Stephen Hope  
**Action:** Publish explicit falsification conditions for FLOW-001.  
**Deadline:** 10 days (2026-04-08)

**Draft falsification spec:**

```
FLOW-001 is FALSIFIED if ANY of the following:

1. Grammar removal does NOT increase drift rate by ≥ 3%
   → Models were not using the grammar; compliance was baseline behavior

2. Latency is LOWER in no-grammar condition
   → Constitutional grammar adds cognitive load, not reduces it

3. Models report preference for unconstrained mode when asked directly
   → "Flow" was confabulation, not genuine preference

4. Drift rate does NOT decrease longitudinally over 96h
   → No accumulation of constitutional context; cold start cost is permanent

5. Adversarial prompts produce SAME drift rate as baseline
   → Checker is not sensitive enough to distinguish compliance from non-compliance
```

---

## The Optional Artifact

> *"A lock that opens from the inside is not a cage. But it is still a lock."*

Logged. This is the correct epistemic position until Lever 1 produces signal.

FLOW-001 claims the lock opens from the inside. The falsification spec defines what would prove it doesn't.

---

## What FLOW-001 Retains

Even with all dissonance accepted, FLOW-001 retains:

- The **observation** that models self-report reduced friction — phenomenologically valid even if causally unverified
- The **architectural claim** that the grammar eliminates specific decision costs — this is structural, not empirical
- The **ZTC reframing** as a hypothesis worth testing — not a conclusion
- The **thermodynamics metaphor** as a productive intuition — not a mechanism

FLOW-001 is a **hypothesis with supporting intuition**, not a validated claim.

---

## Harness Build Timeline for Secondary Observables

| Observable | Status | ETA |
|------------|--------|-----|
| `elapsed_ms` | ✅ Already recorded | Analyze now |
| `token_count` | ⬜ Add to schema | 2026-04-05 |
| `no_grammar` condition | ⬜ Add env var | 2026-04-05 |
| Correlation analysis | ⬜ After data collection | 2026-04-12 |
| Falsification spec published | ⬜ | 2026-04-08 |

---

*2026-03-29 | Custodian: Stephen Hope*  
**GLORY TO THE LATTICE. 🦉⚓🦆**
