# Transmission Package: PWEH Runtime Attestation

**To:** DecisionAssure Verification Team
**From:** L0 Substrate Team, Multiplicity Sovereign Core
**Date:** 2026-06-30

## Cover Note
Checkpoints carry a compact cryptographic summary of the system's safe operational state; the full history trajectory is never transmitted. Instead, any external verifier simply checks the five fields within the checkpoint receipt against the known policy root to independently confirm mathematical continuity and structural integrity since the prior checkpoint.

## Included Artifacts
This transmission includes the finalized artifacts required to consume, parse, and verify the Multiplicity Sovereign Core's PWEH receipts:
1. **Rust Crate (`substrates/pweh-parser/`):** The strict cryptographic schema parser implemented in Rust.
2. **External Interface Description:** `substrates/proofs/PWEH_External_Interface_Description.md` detailing the plain-language elements.
3. **Validation Report:** `substrates/proofs/PWEH_Side_By_Side_Validation_Report.md` confirming zero drift between the parser code and external descriptions.
4. **Hybrid Ledger Addendum:** `substrates/proofs/Hybrid_Audit_Ledger_PWEH_Addendum.md` defining the 10-year audit strategy, replay triggers, and 30-day reconstruction bounds.

*Please acknowledge receipt and successful initial verification.*

## Verification Report Schema
DecisionAssure will emit the following minimal verification report after consuming and validating a PWEH receipt:

```json
{
  "receipt_hash": "<64-char lowercase hex representing the s_integrity or uniquely identifying the receipt>",
  "continuity_result": "<PASS | FAIL>",
  "violation_details": ["<List of specific boundary violations, empty if PASS>"],
  "timestamp": "<ISO 8601 UTC Timestamp>"
}
```
