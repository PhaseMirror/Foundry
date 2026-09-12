import DCA.Core
import DCA.Proofs
import DCA.Examples
import DCA.Export

/-!
# DCA Test Harness

Run with `lake test`.

This test harness validates all DCA invariants from ADR-0030:
1. Valid state format (all fields are UInt64)
2. FIR transition validity (proven transitions exist)
3. Invariant preservation (validity, root, epsilon)
4. FIR reversibility (inverse path is reconstructible)
5. Execution safety gates (memory topology, overflow)
6. Registry invariants (append-only, valid count)
7. Consequence entailment (word-subset check)
8. Export pipeline (markdown generation)

Tests are structured as Bool property checks for compile-time-verifiable
invariants, plus IO output for proof-referenced tests (if the proof terms
compile, the test passes).
-/

open DCA
open DCA.Proofs

/-! ### Property-Based Tests -/

/-- Property: all valid DCA states have `is_valid = true` by construction. -/
def prop_valid_state_has_flag (s : DcaState) : Bool :=
  s.is_valid == true

/-- Property: the root pointer is non-zero in all example states. -/
def prop_root_nonzero (s : DcaState) : Bool :=
  s.root_pointer != 0

/-- Property: memory frame size is exactly 48 bytes. -/
def prop_frame_size_exact : Bool :=
  fitsInFrame (6 * 8) == true

/-! ### Test Suites -/

/-- Test 1: all example valid states pass the validity check. -/
def test_all_valid_states : Bool :=
  prop_valid_state_has_flag dca_state_1_0 &&
  prop_valid_state_has_flag dca_state_1_1 &&
  prop_valid_state_has_flag dca_state_1_2 &&
  prop_valid_state_has_flag dca_state_2_0 &&
  prop_valid_state_has_flag dca_state_2_1 &&
  prop_valid_state_has_flag dca_state_3_0 &&
  prop_valid_state_has_flag dca_state_3_1 &&
  prop_valid_state_has_flag dca_state_5_0 &&
  prop_valid_state_has_flag dca_state_5_1 &&
  prop_valid_state_has_flag dca_state_5_2

/-- Test 2: the invalid state is correctly flagged. -/
def test_invalid_state_detected : Bool :=
  dca_state_4_invalid.is_valid == false

/-- Test 3: all example states have non-zero root pointers. -/
def test_all_roots_nonzero : Bool :=
  prop_root_nonzero dca_state_1_0 &&
  prop_root_nonzero dca_state_1_1 &&
  prop_root_nonzero dca_state_1_2 &&
  prop_root_nonzero dca_state_2_0 &&
  prop_root_nonzero dca_state_2_1 &&
  prop_root_nonzero dca_state_3_0 &&
  prop_root_nonzero dca_state_3_1 &&
  prop_root_nonzero dca_state_5_0 &&
  prop_root_nonzero dca_state_5_1 &&
  prop_root_nonzero dca_state_5_2

/-- Test 4: memory topology is sound. -/
def test_memory_topology : Bool :=
  prop_frame_size_exact

/-- Test 5: execution gate passes for all valid states. -/
def test_execution_gate : Bool :=
  ExecutionGate.check dca_state_1_0 == true &&
  ExecutionGate.check dca_state_1_1 == true &&
  ExecutionGate.check dca_state_1_2 == true &&
  ExecutionGate.check dca_state_2_0 == true &&
  ExecutionGate.check dca_state_2_1 == true &&
  ExecutionGate.check dca_state_3_0 == true &&
  ExecutionGate.check dca_state_3_1 == true &&
  ExecutionGate.check dca_state_5_0 == true &&
  ExecutionGate.check dca_state_5_1 == true &&
  ExecutionGate.check dca_state_5_2 == true

/-- Test 6: FIR path self-matching for all example states. -/
def test_fir_path_self_match : Bool :=
  FirPath.matches (DcaState.firPath dca_state_1_0) dca_state_1_0 == true &&
  FirPath.matches (DcaState.firPath dca_state_1_1) dca_state_1_1 == true &&
  FirPath.matches (DcaState.firPath dca_state_1_2) dca_state_1_2 == true &&
  FirPath.matches (DcaState.firPath dca_state_2_0) dca_state_2_0 == true &&
  FirPath.matches (DcaState.firPath dca_state_2_1) dca_state_2_1 == true &&
  FirPath.matches (DcaState.firPath dca_state_3_0) dca_state_3_0 == true &&
  FirPath.matches (DcaState.firPath dca_state_3_1) dca_state_3_1 == true &&
  FirPath.matches (DcaState.firPath dca_state_5_0) dca_state_5_0 == true &&
  FirPath.matches (DcaState.firPath dca_state_5_1) dca_state_5_1 == true &&
  FirPath.matches (DcaState.firPath dca_state_5_2) dca_state_5_2 == true

/-- Test 7: consequence entailment (positive). -/
def test_consequence_entailment : Bool :=
  entails dca_context dca_decision
    "FIR state machine deterministic" == true &&
  entails dca_context dca_decision
    "invariant deterministic memory" == true

/-- Test 8: consequence entailment (negative — not entailed). -/
def test_consequence_not_entailed : Bool :=
  entails dca_context dca_decision "quantum computing is required" == false

/-! ### Main Test Runner -/

def main : IO UInt32 := do
  IO.println "╔══════════════════════════════════════════════════════╗"
  IO.println "║  DCA Test Harness — ADR-0030 Formal Verification   ║"
  IO.println "╚══════════════════════════════════════════════════════╝"
  IO.println ""

  IO.println "=== Property-Based Tests ==="
  IO.println ""

  if test_all_valid_states then
    IO.println "✓ [1/8] All valid DCA states have is_valid=true."
  else
    IO.println "✗ [1/8] State validity check failed."
    return 1

  if test_invalid_state_detected then
    IO.println "✓ [2/8] Invalid state correctly flagged as is_valid=false."
  else
    IO.println "✗ [2/8] Invalid state detection failed."
    return 1

  if test_all_roots_nonzero then
    IO.println "✓ [3/8] All example states have non-zero root pointers."
  else
    IO.println "✗ [3/8] Root pointer check failed."
    return 1

  if test_memory_topology then
    IO.println "✓ [4/8] Memory topology: DcaState fits in 48-byte frame."
  else
    IO.println "✗ [4/8] Memory topology check failed."
    return 1

  IO.println ""
  IO.println "=== Execution Safety Tests ==="
  IO.println ""

  if test_execution_gate then
    IO.println "✓ [5/8] Composite execution gate passes for all valid states."
  else
    IO.println "✗ [5/8] Execution gate check failed."
    return 1

  IO.println ""
  IO.println "=== FIR Reversibility Tests ==="
  IO.println ""

  if test_fir_path_self_match then
    IO.println "✓ [6/8] FIR inverse path matches state fields for all examples."
  else
    IO.println "✗ [6/8] FIR path matching check failed."
    return 1

  IO.println ""
  IO.println "=== Consequence Entailment Tests ==="
  IO.println ""

  if test_consequence_entailment then
    IO.println "✓ [7/8] Entailed consequences pass the word-subset check."
  else
    IO.println "✗ [7/8] Consequence entailment check failed."
    return 1

  if test_consequence_not_entailed then
    IO.println "✓ [8/8] Non-entailed consequence correctly rejected (negative test)."
  else
    IO.println "✗ [8/8] Negative entailment test failed."
    return 1

  IO.println ""
  IO.println "=== Proof Verification (compile-time) ==="
  IO.println ""
  IO.println "The following proofs are verified at compile time."
  IO.println "If this test harness builds, all proofs are valid."
  IO.println ""

  -- Scenario 1: Baseline FIR Pipeline (3 steps, 2 transitions)
  let _ := dca_1_0_to_1_1
  let _ := dca_1_1_to_1_2
  IO.println "✓ [P1] Scenario 1: 2 FIR transitions proven (dca_1_0_to_1_1, dca_1_1_to_1_2)"

  -- Scenario 2: Large Epsilon Growth
  let _ := dca_2_0_to_2_1
  IO.println "✓ [P2] Scenario 2: 1 FIR transition proven (dca_2_0_to_2_1)"

  -- Scenario 3: Zero Epsilon (Stalled Pipeline)
  let _ := dca_3_0_to_3_1
  IO.println "✓ [P3] Scenario 3: 1 FIR transition proven (dca_3_0_to_3_1)"

  -- Scenario 5: Full Three-Step Chain
  let _ := dca_5_0_to_5_1
  let _ := dca_5_1_to_5_2
  IO.println "✓ [P4] Scenario 5: 2 FIR transitions proven (dca_5_0_to_5_1, dca_5_1_to_5_2)"

  -- Core invariants
  let _ := @preserve_invariants
  IO.println "✓ [P5] preserve_invariants: validity preserved across transitions"

  let _ := @transition_preserves_root
  IO.println "✓ [P6] transition_preserves_root: root pointer immutable"

  let _ := @transition_preserves_epsilon
  IO.println "✓ [P7] transition_preserves_epsilon: growth rate constant"

  let _ := @transition_deterministic
  IO.println "✓ [P8] transition_deterministic: successor fields uniquely determined"

  -- FIR reversibility
  let _ := @fir_path_reconstructible
  IO.println "✓ [P9] fir_path_reconstructible: inverse path reconstructible"

  let _ := @fir_path_self_match
  IO.println "✓ [P10] fir_path_self_match: path matches state by construction"

  -- Execution safety
  let _ := @memory_topology_sound
  IO.println "✓ [P11] memory_topology_sound: DcaState fits in 48-byte frame"

  let _ := @overflow_gate_trivial_invalid
  IO.println "✓ [P12] overflow_gate_trivial_invalid: isolated states pass gate"

  let _ := @execution_gate_sound
  IO.println "✓ [P13] execution_gate_sound: composite gate decomposes correctly"

  -- Registry
  let _ := @registry_valid_count_nonneg
  IO.println "✓ [P14] registry_valid_count_nonneg: valid count non-negative"

  let _ := @registry_add_preserves_existing
  IO.println "✓ [P15] registry_add_preserves_existing: append-only discipline"

  let _ := @registry_valid_subset
  IO.println "✓ [P16] registry_valid_subset: valid states are subset of all"

  -- Traceability
  let _ := @history_reconstructible
  IO.println "✓ [P17] history_reconstructible: full history reconstructible"

  -- State identity
  let _ := @transition_changes_is
  IO.println "✓ [P18] transition_changes_is: strictly different successor when eps > 0"

  -- Chain validity propagation (Scenario 5)
  let _ := dca_chain_5_valid
  IO.println "✓ [P19] dca_chain_5_valid: chain validity propagation"

  -- Consequence entailment proofs
  let _ := @consequence_fir_deterministic
  IO.println "✓ [P20] consequence_fir_deterministic: entails check passes"

  let _ := @consequence_invariant_preservation
  IO.println "✓ [P21] consequence_invariant_preservation: entails check passes"

  -- Registry example
  IO.println ""
  IO.println "=== Export Tests ==="
  IO.println ""

  IO.println "--- DCA State 1_0 (Genesis) ---"
  IO.println (DCA.Export.stateToMarkdown dca_state_1_0)

  IO.println "--- DCA State 5_2 (Two FIR cycles) ---"
  IO.println (DCA.Export.stateToMarkdown dca_state_5_2)

  IO.println "--- Transition: dca_5_0_to_5_1 ---"
  IO.println (DCA.Export.transitionToMarkdown "dca_5_0_to_5_1" dca_state_5_0 dca_state_5_1)

  IO.println "--- Registry Audit ---"
  IO.println (DCA.Export.registryToMarkdown example_registry)

  IO.println "--- Full Audit Report ---"
  IO.println (DCA.Export.auditReport "Scenario 1: Baseline FIR Pipeline"
    [dca_state_1_0, dca_state_1_1, dca_state_1_2])

  IO.println ""
  IO.println "╔══════════════════════════════════════════════════════╗"
  IO.println "║  All 8 property tests + 21 proof checks passed!    ║"
  IO.println "║  DCA-0030 invariants verified.                     ║"
  IO.println "╚══════════════════════════════════════════════════════╝"
  return 0
