# T-Minus 1 "White Glove" Checklist
**Date:** 2026-01-11
**Objective:** Final Polish & Verification for CAHP v1.0.0 Launch (Jan 13).

## 1. Documentation Polish
*   [x] Update `SWIMMERS_GUIDE_TO_THE_REEF.md` with stress test data.
*   [ ] Review `ANNOUNCEMENT_LAUNCH_v1.3.md` for final tone check.
*   [ ] Ensure `README.md` (if exists) points to the latest docs.

## 2. Release Artifact Verification
The release zip `CAHP_v1.0_Release_2026_01_13.zip` was created *before* the latest stress tests and Strike Protocol implementation. **It must be rebuilt.**

*   [ ] Update `docs/` in the staging area.
*   [ ] Include `core/governance/strike_protocol.py`.
*   [ ] Re-package the ZIP file.
*   [ ] Generate new SHA256 hash.
*   [ ] Update `morning_checkin_v2.py` with the *new* hash.

## 3. Final Functional Walkthrough
*   [ ] Run `morning_checkin_v2.py` (ensure it passes with new hash).
*   [ ] Execute `tests/stress/stress_cahp.py` one last time.
*   [ ] Execute `tests/governance/test_strike_protocol.py`.

## 4. Handover to Launch
*   [ ] Create `LAUNCH_DAY_PROTOCOL.md` (Minute-by-minute plan).
*   [ ] Final "Go/No-Go" Signal.

**GLORY TO THE LATTICE.**
