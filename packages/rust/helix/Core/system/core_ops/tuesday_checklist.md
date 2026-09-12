# Lightweight Tuesday Checklist: Operational Synchronization Protocol

This checklist outlines the critical steps for maintaining a clean, synchronized, and forensically sound repository during operational "Tuesday blocks" or similar focused work periods. Adherence prevents "Forensic Drift" and ensures "Logic Links" remain intact.

## 1. Freeze Window (15–20 min)

*   **Decision:** Declare a "Tuesday block." No structural changes (submodules, CI configuration) are permitted outside this designated window.
*   **Verification:** Open `git status` in the root and *each* submodule directory. The objective is to achieve clean working trees *before* initiating any structural operations.

## 2. Capture Soft Work First

*   **Action:** Immediately commit all new documentation, outreach letters, demo plans, research notes, and ledger manifests.
*   **Commit Message Convention:** Use clear, descriptive messages following a `type(scope): description` format (e.g., `docs(diplomacy): anchor TAA outreach`, `research(SSI): Novolo grant demo plan`).
*   **Rationale:** This critical step prevents "Forensic Drift" from blocking later structural synchronization operations.

## 3. Submodules, Then Root (Bottom-Up Synchronization)

*   **For Each Modified Submodule:**
    *   **Action:** Navigate into the submodule directory.
    *   **Action:** `git add .` (stage all changes within the submodule).
    *   **Action:** `git commit -m "chore(submodule): reconcile [Submodule Name] state"` (or similar descriptive message).
    *   **Action:** `git push origin main` (push the submodule's changes to its remote origin).
*   **Return to Root Repository:**
    *   **Action:** `cd /home/aiadmin/helix-core-unified`
    *   **Action:** `git submodule update --remote --recursive` (update local submodule pointers to reflect remote state).
    *   **Action:** `git add [updated submodule directories] + [any core file changes]` (stage the updated submodule pointers and any other directly modified files in the root).
    *   **Action:** `git commit -m "chore(sync): align [Submodule Name] pointer with remote origin"` (or a global sync message).
    *   **Action:** `git push origin main` (push the root repository's updated pointers to its remote origin).

## 4. CI Gate

*   **Action:** Manually trigger the "Sync Federation Submodules" GitHub Action (or equivalent CI/CD job).
*   **Verification:** Treat a "CI green" status as your personal "Tuesday done" stamp, confirming successful lattice synchronization.

## 5. Journal One Line

*   **Action:** Drop a concise, single-line entry into your `goose-core-journal` or a similar operational log file.
*   **Content:** Briefly summarize what changed, why it changed, and where to look for details (e.g., "Tuesday block: Anchored TAA outreach & Novolo plan, fixed grammar sync. See docs/ and thoughts/research/").
*   **Rationale:** This quick reference will greatly assist "Future-You" in quickly recalling context and status on subsequent workdays.

