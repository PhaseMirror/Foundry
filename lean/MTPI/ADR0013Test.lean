import MTPI.ADR0013

open MTPI.ADR0013

/-! Runtime witness for the ADR-0013 formal scaffold.

Executes the closed-form claims of `MTPI.ADR0013` as a runnable test driver;
each line is the executable counterpart of a zero-sorry theorem. Run with
`lake exe adr0013_test`. -/

def check (name : String) (cond : Prop) [Decidable cond] : IO Unit := do
  IO.println (name ++ ": " ++ if decide cond then "PASS" else "FAIL")

def main : IO Unit := do
  check "fixedWidth is 184" (fixedWidth = 184)
  check "minEnvelopeLen is 188" (minEnvelopeLen = 188)
  check "example envelope encodes to 191 bytes" ((canonicalBytes exampleEnvelope).length = 191)
  check "example envelope has canonical widths" (canonicalWidths exampleEnvelope)
  check "be8 length is 8" ((be8 0xFF).length = 8)
  check "be4 length is 4" ((be4 0xFF).length = 4)
  check "contractivity admists below scale" (Contractive (SCALE - 1))
  check "contractivity rejects at scale" (¬ Contractive SCALE)
  check "defect norm is above epsilon" (AssociatorDefect (EPSILON + 1))
  check "defect triggers kill" ((commit false (EPSILON + 1 > EPSILON) false) = true)
  check "expansive transition triggers kill" ((commit false false true) = true)
  check "nominal commit does not kill" ((commit false false false) = false)
  check "latch never unhalts" ((commit true false false) = true)
  check "kill requires defect evidence" ((commit false false false = true) → False)
  check "pweh bind is injective (witness)" (PwehBind.mk 2 9 27 5 ≠ PwehBind.mk 9 2 27 5)
  check "pweh bind order matters" (PwehBind.mk 2 9 27 5 ≠ PwehBind.mk 9 2 27 5)
  check "pweh preimage width is 32" ((pweh_preimage_bytes (PwehBind.mk 1 2 3 4)).length = 32)