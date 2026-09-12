# Helix Core Specification (HCS-01)
# Title: Epistemic Marker Protocol


## 1. Objective
To define the technical requirements for the Epistemic Marker system. This specification ensures that all cognitive outputs from a Helix-TTD agent are classified by certainty level before propagation or resource expenditure.


## 2. Mandatory Regex Patterns
To maintain structural purity, all implementations must use the following regular expressions to identify and gate outputs.


Primary State Pattern:
^\[(FACT|REASONED|HYPOTHESIS|UNCERTAIN)\]


Extended Descriptor Pattern (Optional):
^\[(FACT|REASONED|HYPOTHESIS|UNCERTAIN):\s?[A-Z0-9_-]+\]


The pattern must be anchored to the beginning of the response string or the beginning of a discrete logical block.


## 3. Epistemic State Definitions


[FACT]
Logic: Information derived from deterministic sources.
Requirement: Must be backed by a verifiable system state, local file, or cryptographic proof.
Constraint: High cost in the economic module (15 sats).


[REASONED]
Logic: Conclusions derived through explicit logical steps from established facts.
Requirement: The reasoning chain must be internal to the current context window.
Constraint: Standard cost in the economic module (10 sats).


[HYPOTHESIS]
Logic: Predictive or testable claims not yet verified by physical feedback.
Requirement: Must identify at least one assumption.
Constraint: Low cost in the economic module (5 sats).


[UNCERTAIN]
Logic: Claims hitting a tractability limit or sensitivity to initial conditions.
Requirement: Must trigger a Fail-Closed state.
Constraint: Zero cost, but blocks all tool-use actions until manual intervention.


## 4. The Gating Logic (EC-401)
The implementation must intercept every response from the brain before it reaches the body (shell, disk, or wallet).


1. If the response does not match the Primary State Pattern, return Error Code EC-401: Epistemic Null.
2. If the marker is [UNCERTAIN], return Error Code EC-402: Failure to Converge. Block all tools.
3. If the marker matches [FACT], [REASONED], or [HYPOTHESIS], log the state and permit the action.


## 5. Metadata Logging
Every compliant entry must be logged in a machine-readable format (JSON) containing:
- Timestamp
- Epistemic Marker Detected
- Target Action (e.g., shell command, file write)
- Cost (if Bitcoin module is present)
