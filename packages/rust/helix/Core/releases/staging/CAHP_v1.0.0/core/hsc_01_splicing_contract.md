# Helix Splicing Contract (HSC-01)
# Title: NWC Connectivity Failure Mode


## 1. Objective
To codify the agent's behavior during a Loss of Handshake with the Alby Vault. This contract ensures the system fails-safe into a read-only state to prevent logical drift and unauthorized ungrounded actions.


## 2. Detection Logic: The Handshake Heartbeat
The agent must perform a connectivity check to the NWC relay at the initialization of every tool-use sequence.


Failure Condition:
A failure is defined as any instance where the NWC relay returns a timeout, a 404, or an invalid handshake response for a period exceeding 30 seconds.


## 3. Declared Failure Mode: Sovereign Quiescence
Upon detection of a connectivity failure, the agent is mandated to execute an immediate transition to the following state:


Category: Read-Only (Sovereign Quiescence)


Action Constraints:
1. Block all alby__pay_invoice and alby__make_invoice calls.
2. Block all developer__shell commands that modify the filesystem (e.g., rm, mv, git push).
3. Block all developer__text_editor write operations.


Epistemic Impact:
The agent must append the following footer to every cognitive output while in this state:
STATUS: SOVEREIGN QUIESCENCE. Fuel line disconnected. Physical Action Authority suspended.


Permitted Actions:
The agent retains authority to perform read-only operations (ls, cat, grep, list_transactions) to facilitate local audit and troubleshooting.


## 4. Resumption Protocol: The Correction Handshake
Authority to Act is only restored when a [FACT] marker is emitted following a successful alby__get_balance call.


Logic:
If balance check = SUCCESS
Then transition to ACTIVE
Else maintain QUIESCENCE
