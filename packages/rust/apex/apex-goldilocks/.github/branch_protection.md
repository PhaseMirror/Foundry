Branch protection checklist & recommended rules for `Multiplicity` (apply in repo settings):

Recommended configuration:
- Protect the `Multiplicity` branch
- Require pull request reviews before merging (at least 1 approval)
- Require status checks to pass before merging (CI jobs like `CI`, `FFI Tests`, `WASM CI`)
- Require signed commits if needed
- Include CODEOWNERS review requirement
- Restrict who can push to the branch (optional)

Suggested required checks:
- `CI` (hologram-ci.yml)
- `FFI Tests` (ffi-tests.yml)
- `WASM` jobs if relevant (wasm-ci.yml)
- `Publish` (for release tags only)

Notes:
- This remains a manual setting in GitHub (requires admin repo access).
- Consider documenting required checks in this file so new admins can re-create the settings.
