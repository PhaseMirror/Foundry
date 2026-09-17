# ADR Test Results — ADR-0108

- **ADR file:** `docs/adr/completed/ADR-0108-PrismPM and Langlands Prism.md`
- **Started:** 2026-09-17T02:17:16Z
- **Duration:** 1361285 ms
- **Overall:** `PASS`

## Gate

| Step | Description | Status | Exit | Duration |
| :--- | :--- | :--- | :---: | ---: |
| `adr-index` | Regenerate docs/adr/README.md from registry.json | `PASS` | 0 | 214 ms |
| `adr-sorry-check` | ADR-0010: zero untracked sorry tactics in ADR/ | `PASS` | 0 | 55 ms |
| `lean-build` | lake build ADR (Lean 4 formal library) | `PASS` | 0 | 265268 ms |
| `lean-test` | lake test (adrTest driver, incl. Prism gate soundness + property sweep) | `PASS` | 0 | 2958 ms |
| `cargo-test` | pirtm-engine Rust tests (ensemble manifest, Phase D, interop, property) | `PASS` | 0 | 1568 ms |
| `kani:adversarial_gain_is_vetoed_despite_valid_semantics` | Kani bounded model checking — adversarial_gain_is_vetoed_despite_valid_semantics | `PASS` | 0 | 2442 ms |
| `kani:invalid_semantics_are_rejected` | Kani bounded model checking — invalid_semantics_are_rejected | `PASS` | 0 | 972 ms |
| `kani:bcs_serialization_is_injective` | Kani bounded model checking — bcs_serialization_is_injective | `PASS` | 0 | 950337 ms |
| `kani:canonical_wire_format_is_injective` | Kani bounded model checking — canonical_wire_format_is_injective | `PASS` | 0 | 82774 ms |
| `kani:canonical_wire_format_roundtrips` | Kani bounded model checking — canonical_wire_format_roundtrips | `PASS` | 0 | 50794 ms |
| `kani:contractivity_gate_is_fail_closed` | Kani bounded model checking — contractivity_gate_is_fail_closed | `PASS` | 0 | 3903 ms |

## Artifacts

Results directory: `docs/adr/results/ADR-0108-PrismPM-and-Langlands-Prism`

* [`adr-index` log](latest/logs/adr-index.log)
* [`adr-sorry-check` log](latest/logs/adr-sorry-check.log)
* [`lean-build` log](latest/logs/lean-build.log)
* [`lean-test` log](latest/logs/lean-test.log)
* [`cargo-test` log](latest/logs/cargo-test.log)
* [`kani:adversarial_gain_is_vetoed_despite_valid_semantics` log](latest/logs/kani:adversarial_gain_is_vetoed_despite_valid_semantics.log)
* [`kani:invalid_semantics_are_rejected` log](latest/logs/kani:invalid_semantics_are_rejected.log)
* [`kani:bcs_serialization_is_injective` log](latest/logs/kani:bcs_serialization_is_injective.log)
* [`kani:canonical_wire_format_is_injective` log](latest/logs/kani:canonical_wire_format_is_injective.log)
* [`kani:canonical_wire_format_roundtrips` log](latest/logs/kani:canonical_wire_format_roundtrips.log)
* [`kani:contractivity_gate_is_fail_closed` log](latest/logs/kani:contractivity_gate_is_fail_closed.log)

* [`summary.json`](summary.json)

**All checks passed.** ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・
