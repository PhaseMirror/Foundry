# Pull Request Checklist

- [ ] **Build & Tests** – `lake build && lake test` passes.
- [ ] **Documentation** – Updated docs/adr/ADR_Lean4_Proofing.md if required.
- [ ] **Mathlib import review** – Verify the change does **not** introduce a Mathlib import via:
  - macro expansion,
  - conditional compilation (`#if`, `if`, `match`),
  - `#eval` / runtime loading,
  - string‑concatenated import paths.

  If any such pattern is present, the change must be rejected or marked with `@[mathlib_exempt]`.

<!-- Add any other project‑specific items here -->
