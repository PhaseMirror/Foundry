//! `CA-02`, `CA-03`, `CU-01`: claims about the built artifact rather than about
//! the arithmetic.
//!
//! Each shells out with its own `--target-dir`, because these run *inside*
//! `cargo test` and sharing the workspace target directory would block on its
//! lock.

use std::path::{Path, PathBuf};
use std::process::Command;

use uor_matmul_core::EncodeMode;
use uor_matmul_validate::{Case, Corpus};

fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("two below the root")
        .to_path_buf()
}

/// The corpus digest: the whole standing corpus, serialized little-endian and
/// hashed.
///
/// One number that stands for every output byte the library produces on the
/// standing corpus. `CA-02` is the claim that this number is the same on
/// `thumbv7em-none-eabihf`, on both wasm targets, and on x86-64 --- which the
/// cross-target CI jobs check by running this same function and comparing
/// against the same committed constant.
fn corpus_digest() -> u64 {
    // FNV-1a over the serialized corpus. A digest, not a checksum against
    // tampering: what it has to detect is a *different answer*, and any
    // avalanche function does that.
    let mut h: u64 = 0xcbf2_9ce4_8422_2325;
    for case in Corpus::standard(20_260_724).cases {
        let Case { m, k, n, .. } = case;
        let a = case.fill_i8(m * k, 1);
        let b = case.fill_i8(k * n, 2);
        let out = uor_matmul_validate::ours_i8_i32(m, k, n, &a, &b, EncodeMode::Wrapping);
        for v in out {
            for byte in v.to_le_bytes() {
                h ^= u64::from(byte);
                h = h.wrapping_mul(0x1000_0000_01b3);
            }
        }
    }
    h
}

/// The digest this library produces on the standing corpus.
///
/// Committed, so that a change to it is a change a reviewer must approve. Every
/// target in CI must reproduce it exactly (`CA-02`).
const CORPUS_DIGEST: u64 = 0x659C_D7C8_2BBA_2AFD;

/// `CA-02`: identical bytes on every target.
#[test]
fn the_corpus_digest_is_target_independent_ca_02() {
    let actual = corpus_digest();
    assert_eq!(
        actual, CORPUS_DIGEST,
        "the corpus digest changed. If this is intentional, update CORPUS_DIGEST \
         and say why in the commit; if it is not, the library's output has moved. \
         actual = {actual:#018X}"
    );

    // The claim has content only if the shipped crates *build* for those
    // targets, so build them here rather than trusting CI to notice.
    for target in ["thumbv7em-none-eabihf", "wasm32-unknown-unknown"] {
        let status = Command::new(env!("CARGO"))
            .current_dir(root())
            .args([
                "build",
                "-p",
                "uor-matmul",
                "--no-default-features",
                "--target",
                target,
            ])
            .args(["--target-dir"])
            .arg(root().join("target").join("ca02"))
            .status()
            .expect("cargo build runs");
        assert!(
            status.success(),
            "the shipped crates must build for {target}"
        );
    }
    eprintln!("CA-02: corpus digest {CORPUS_DIGEST:#018X}, reproduced on every target in CI");
}

/// `CA-03`: no shipped crate links an allocator symbol on a `no_std` target.
///
/// The strongest form of R7. An `alloc` dependency introduced anywhere in the
/// tree would put `__rust_alloc` in the object, and a `no_std` target with no
/// allocator would then fail to link --- but this checks the symbol table
/// directly, so it fails at the crate that introduced it rather than at some
/// downstream binary.
#[test]
fn no_allocator_symbol_on_a_no_std_target_ca_03() {
    let out_dir = root().join("target").join("ca03");
    let status = Command::new(env!("CARGO"))
        .current_dir(root())
        .args([
            "build",
            "-p",
            "uor-matmul",
            "--no-default-features",
            "--release",
            "--target",
            "thumbv7em-none-eabihf",
            "--target-dir",
        ])
        .arg(&out_dir)
        .status()
        .expect("cargo build runs");
    assert!(
        status.success(),
        "the shipped crates must build for thumbv7em"
    );

    let rlibs = collect_rlibs(&out_dir.join("thumbv7em-none-eabihf/release/deps"));
    assert!(
        !rlibs.is_empty(),
        "the build must have produced rlibs to inspect"
    );

    let forbidden = [
        "__rust_alloc",
        "__rust_dealloc",
        "__rust_realloc",
        "__rust_alloc_zeroed",
    ];
    let mut checked = 0usize;
    for rlib in &rlibs {
        let bytes = std::fs::read(rlib).expect("rlib reads");
        let name = rlib.file_name().unwrap_or_default().to_string_lossy();
        if !name.starts_with("libuor_matmul") {
            continue;
        }
        checked += 1;
        for symbol in forbidden {
            assert!(
                !contains(&bytes, symbol.as_bytes()),
                "{name} references `{symbol}`; a shipped crate has acquired a heap (R7)"
            );
        }
    }
    assert!(
        checked >= 1,
        "at least one shipped rlib must have been inspected"
    );
    eprintln!("CA-03: {checked} shipped rlib(s) reference no allocator symbol");
}

/// `CU-01`: no float arithmetic opcode in any shipped kernel's disassembly.
///
/// Delegates to the `xtask` gate, which owns the emit-and-scan, so the rule has
/// one implementation rather than two that could drift.
#[test]
fn no_float_arithmetic_opcode_in_any_kernel_cu_01() {
    let status = Command::new(env!("CARGO"))
        .current_dir(root())
        .args(["run", "-q", "-p", "xtask", "--target-dir"])
        .arg(root().join("target").join("cu01"))
        .args(["--", "audit-disassembly"])
        .status()
        .expect("xtask runs");
    assert!(
        status.success(),
        "CU-01: a shipped kernel contains float arithmetic"
    );
}

fn collect_rlibs(dir: &Path) -> Vec<PathBuf> {
    let mut out = Vec::new();
    let Ok(entries) = std::fs::read_dir(dir) else {
        return out;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.extension().is_some_and(|e| e == "rlib") {
            out.push(path);
        }
    }
    out
}

/// Does `haystack` contain `needle`? A three-line search, so that inspecting an
/// object file needs no dependency.
fn contains(haystack: &[u8], needle: &[u8]) -> bool {
    haystack.windows(needle.len()).any(|w| w == needle)
}
