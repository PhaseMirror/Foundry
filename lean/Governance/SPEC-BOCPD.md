# Specification: BOCPD Integration for Continuous Audit

## 1. Overview
This specification defines the integration of Bayesian Online Change-Point Detection (BOCPD) into the **Examiner** module. The goal is to reduce semantic drift detection latency from 1,000 blocks to < 50 blocks by identifying probabilistic regime shifts in real-time.

## 2. BOCPD Mathematical Model

### 2.1 Posterior Predictive Distribution
The detector calculates the probability of a "run length" $r_t$ (time since the last change-point) given the observed drift sequence $x_{1:t}$:
$P(r_t | x_{1:t}) \propto \sum_{r_{t-1}} P(r_t | r_{t-1}) P(x_t | r_{t-1}, x_t^{(r)}) P(r_{t-1} | x_{1:t-1})$

- **Hazard Function:** Constant prior probability of a change-point at any step (e.g., $H = 1/250$).
- **Likelihood:** Normal-Inverse-Gamma (NIG) prior on the drift distribution parameters ($\mu, \sigma^2$).

### 2.2 Alert Thresholds
Regime shifts are flagged when the maximum likelihood run-length drops significantly or the probability of $r_t = 0$ exceeds the trigger bound.

| Signal Level | Probability $P(r_t=0)$ | Action |
| :--- | :--- | :--- |
| **STABLE** | $< 0.05$ | Routine Logging |
| **WARNING** | $0.05 \le p < 0.20$ | Increased Audit Frequency (100 blocks) |
| **ALERT** | $\ge 0.20$ | immediate $\Lambda_m$ Attractor Audit |

## 3. Examiner Integration

### 3.1 Data Pipeline
The BOCPD detector consumes the drift magnitude $\delta(t)$ emitted by the ensembles **FT-01** and **LE-02** at every block transition.

### 3.2 Detection Latency Metric
- **Target:** Change-point detected within 50 blocks of occurrence.
- **Verification:** Benchmarked against mock-market volatility spikes in the FT-01 ensemble.

## 4. Implementation Guardrails

### 4.1 Zero-Drift Precedence
BOCPD is a *diagnostic* tool. It cannot override the L0 `SIG_GOV_KILL` trigger. If $\delta(t) > \epsilon$, the system halts regardless of the BOCPD run-length.

### 4.2 False Positive Calibration
Participation in the Aggregate FP Calibration Service (Tier 5) will refine the Hazard function $H$ over multiple epochs to minimize detection noise without sacrificing sensitivity.

---
*Signed by Phase Mirror Data Science Module on 2026-06-14*
