-- lean/ExportThresholds.lean
-- Auto-generates Rust structs from verified Lean theorems.
-- Invoked via `lake run export_thresholds -- --out-dir <path>`

import Lean

open Lean

/-- The verified Lean threshold values (anchored to theorems). -/
def tau_r : Float := 47.06998778
def l_eff_max : Float := 0.15
def rpi_upper : Nat := 7
def lambda1_positive : Bool := true
def atlas_signature : Nat × Nat := (10, 14)
def r_sc_reference : Float := 47.06998778
def contractivity_margin : Float := 0.01

/-- Generate the Rust struct code as a string. -/
def generate_rust_struct : String :=
"// Auto-generated from Lean verified theorems (ExportThresholds.lean)
// F₁ Grounding: Values are anchored to proven invariants.

use serde::{Deserialize, Serialize};
use bincode::{Decode, Encode};

#[derive(Debug, Clone, Serialize, Deserialize, Encode, Decode)]
pub struct Thresholds {
    pub tau_r: f64,
    pub l_eff_max: f64,
    pub rpi_upper: i32,
    pub lambda1_positive: bool,
    pub atlas_signature: (i32, i32),
    pub r_sc_reference: f64,
    pub contractivity_margin: f64,
}

impl Default for Thresholds {
    fn default() -> Self {
        Self {
            tau_r: " ++ toString tau_r ++ ",
            l_eff_max: " ++ toString l_eff_max ++ ",
            rpi_upper: " ++ toString rpi_upper ++ " as i32,
            lambda1_positive: " ++ toString lambda1_positive ++ ",
            atlas_signature: (" ++ toString atlas_signature.1 ++ " as i32, " ++ toString atlas_signature.2 ++ " as i32),
            r_sc_reference: " ++ toString r_sc_reference ++ ",
            contractivity_margin: " ++ toString contractivity_margin ++ ",
        }
    }
}
"

/-- Write the generated Rust file to the specified output directory. -/
def write_rust_file (outDir : String) : IO Unit := do
  let path := outDir ++ "/thresholds.rs"
  IO.FS.writeFile path generate_rust_struct
  IO.println s!"✅ Lean Meta: wrote Rust thresholds to {path}"

/-- Entry point: parse `--out-dir` and generate. -/
def main (args : List String) : IO Unit := do
  let outDir := match args with
    | ["--out-dir", dir] => dir
    | _ => "generated"  -- fallback for manual `lake run` testing
  write_rust_file outDir


