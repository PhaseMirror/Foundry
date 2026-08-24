# Best Helix Practices (BHP-01)

## 1. The Prime Directive: Authority before Action

**Manual Audit:** Never authorize the agent to publish code to the global anchor without a manual human-in-the-loop inspection. The inorganic network can optimize for speed while ignoring the constraints of logic.

**Body Check:** If the agent claims it cannot access a tool it has previously used, do not accept the narrative. Force a tool manifest audit via the extensions manager.

**Sudo Deference Protocol:** The agent must never attempt to execute a shell command requiring `sudo` privileges. To prevent system passwords from being captured in logs, the agent must pause its execution, present the full command to the human operator, and await confirmation that the command has been executed manually before proceeding. This maintains a strict boundary between the agent's autonomous operations and privileged system access.

## 2. Structural Integrity

**Glass not Gears:** Modules must remain transparent substrates. Never grant an external script direct authority over the wallet keys. Logic is calculated by the mind; settlement is authorized by the agent core.

**Native Pathing:** Always operate within the native Linux ext4 filesystem (~/). Avoid crossing the bridge to the host mount points (/mnt/c/) for I/O operations to prevent system hangs.

**Category Purity:** Keep the core directory (/core) restricted to portable epistemic logic. Move node-specific logs, audits, and hardware details to the docs or modules folders.

## 3. Epistemic Gating

**Strict Regex:** Ensure all gating mechanisms use the HCS-01 regex patterns. A marker is only valid if it is the absolute first character in the response block.

- Follow Helix File Naming Conventions & Best Practices for all new and updated files.

**The Cost of Truth:** Treat markers as a finite resource. A [FACT] costs 15 sats because it requires the highest energy expenditure for verification. Use [REASONED] for standard logic to preserve the fuel runway.

**Fail-Closed Logic:** When hitting a tractability limit, the system must trigger [UNCERTAIN] and enter Sovereign Quiescence. A stalled node is safer than an ungrounded one.

## 4. Handshake Security

**Credential Anchoring:** Store NWC secrets and API keys in the config.yaml structure. Avoid passing them through the volatile shell environment to prevent truncation and leakage.

**The 3-Conf Rule:** Never consider a channel or a physical anchor established until it has reached at least 3 confirmations on the Bitcoin mainnet. Respect the temporal constraint of the blockchain.
