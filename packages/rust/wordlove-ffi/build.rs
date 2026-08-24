//! Build script: drives `lake build WordLove:shared` in the Prime Lake
//! project (repo root), then emits the capability manifest plus Cargo
//! link/env directives so `lean_rs` can dlopen the dylib at runtime.

use lean_toolchain::{
    CargoLeanCapability, LeanExportAbiRepr, LeanExportArgAbi, LeanExportOwnership,
    LeanExportResultConvention, LeanExportReturnAbi, LeanExportSignature,
};

const TARGET: &str = "WordLove";

fn arg(repr: LeanExportAbiRepr) -> LeanExportArgAbi {
    LeanExportArgAbi::new(repr, LeanExportOwnership::None)
}

fn ret(repr: LeanExportAbiRepr) -> LeanExportReturnAbi {
    LeanExportReturnAbi::new(repr, LeanExportOwnership::None, LeanExportResultConvention::Pure)
}

fn sig(symbol: &str, args: Vec<LeanExportArgAbi>, result: LeanExportReturnAbi) -> LeanExportSignature {
    LeanExportSignature::function(symbol, args, result)
}

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-env-changed=LEAN_SYSROOT");

    let project_root = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../..")
        .canonicalize()
        .expect("wordlove-ffi lives three levels below the repo root");

    let u8_ret = ret(LeanExportAbiRepr::U8);
    let u32_ret = ret(LeanExportAbiRepr::U32);
    let u64_ret = ret(LeanExportAbiRepr::U64);

    // LargePrimeExport group — hybrid primality + factor statistics.
    // LargePrimeExport: hybrid gate (Tier-1 table / Tier-2 Pratt witness).
    //   Lean Bool lowers to uint8_t under @[export].
    CargoLeanCapability::new(project_root.clone(), TARGET)
        .package("Prime")
        .module("Prime.Multiplicity.WordLove.FFI")
        .export_signature(sig(
            "wordlove_is_hybrid_prime_fast_ffi",
            vec![arg(LeanExportAbiRepr::U64)],
            u8_ret,
        ))
        .export_signature(sig(
            "wordlove_prime_omega_ffi",
            vec![arg(LeanExportAbiRepr::U32)],
            u32_ret,
        ))
        .export_signature(sig(
            "wordlove_prime_Omega_ffi",
            vec![arg(LeanExportAbiRepr::U32)],
            u32_ret,
        ))
        .export_signature(sig(
            "wordlove_parm_sealed_state_108_ffi",
            vec![arg(LeanExportAbiRepr::U32)],
            u64_ret,
        ))
        // CertifiedCouplingExport group — gated fixed-point coupling.
        .export_signature(sig(
            "wordlove_gamma_certified_ffi",
            vec![
                arg(LeanExportAbiRepr::U32),
                arg(LeanExportAbiRepr::U32),
                arg(LeanExportAbiRepr::U32),
            ],
            u32_ret,
        ))
        .build()
        .expect("lake build WordLove:shared failed; run `lake build WordLove` first");
}
