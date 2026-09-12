//! `CX-10`: byte equality with NumPy `int64`, out of process.
//!
//! Every other oracle in this repository is a Rust crate. They share a
//! language, a compiler, and in more than one case a kernel author, so
//! agreement among them is weaker evidence than it looks. NumPy shares none of
//! those, which is why it is registered separately and why its outputs are
//! *committed artifacts* rather than a live dependency: the claim is
//! reproducible without a Python toolchain, and `oracles/numpy/generate.py`
//! records exactly how the artifacts were made.
//!
//! `int64` accumulation wraps where a two's complement accumulator does, so
//! this is byte equality with no exempted region (§3.4).

use std::path::PathBuf;

use uor_matmul::prelude::*;
use uor_matmul_core::EncodeMode;

fn oracle_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("crates/uor-matmul-validate is two below the root")
        .join("oracles/numpy")
}

fn read_i64(path: &std::path::Path) -> Vec<i64> {
    let bytes = std::fs::read(path).unwrap_or_else(|e| panic!("{}: {e}", path.display()));
    bytes
        .chunks_exact(8)
        .map(|c| i64::from_le_bytes(c.try_into().expect("eight bytes")))
        .collect()
}

fn sha256_hex(bytes: &[u8]) -> String {
    // A small SHA-256, so that verifying a committed artifact needs no
    // dependency. R11 asks for a checksum; a checksum that required a crate to
    // check would be one more thing to trust.
    const K: [u32; 64] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
        0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
        0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
        0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
        0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
        0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
        0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
        0xc67178f2,
    ];
    let mut h: [u32; 8] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab,
        0x5be0cd19,
    ];
    let mut msg = bytes.to_vec();
    let bit_len = (bytes.len() as u64) * 8;
    msg.push(0x80);
    while msg.len() % 64 != 56 {
        msg.push(0);
    }
    msg.extend_from_slice(&bit_len.to_be_bytes());

    for block in msg.chunks_exact(64) {
        let mut w = [0u32; 64];
        for (i, c) in block.chunks_exact(4).enumerate() {
            w[i] = u32::from_be_bytes(c.try_into().unwrap());
        }
        for i in 16..64 {
            let s0 = w[i - 15].rotate_right(7) ^ w[i - 15].rotate_right(18) ^ (w[i - 15] >> 3);
            let s1 = w[i - 2].rotate_right(17) ^ w[i - 2].rotate_right(19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16]
                .wrapping_add(s0)
                .wrapping_add(w[i - 7])
                .wrapping_add(s1);
        }
        let mut v = h;
        for i in 0..64 {
            let s1 = v[4].rotate_right(6) ^ v[4].rotate_right(11) ^ v[4].rotate_right(25);
            let ch = (v[4] & v[5]) ^ ((!v[4]) & v[6]);
            let t1 = v[7]
                .wrapping_add(s1)
                .wrapping_add(ch)
                .wrapping_add(K[i])
                .wrapping_add(w[i]);
            let s0 = v[0].rotate_right(2) ^ v[0].rotate_right(13) ^ v[0].rotate_right(22);
            let maj = (v[0] & v[1]) ^ (v[0] & v[2]) ^ (v[1] & v[2]);
            let t2 = s0.wrapping_add(maj);
            v = [
                t1.wrapping_add(t2),
                v[0],
                v[1],
                v[2],
                v[3].wrapping_add(t1),
                v[4],
                v[5],
                v[6],
            ];
        }
        for (dst, src) in h.iter_mut().zip(v.iter()) {
            *dst = dst.wrapping_add(*src);
        }
    }
    h.iter().map(|w| format!("{w:08x}")).collect()
}

/// Our `i64` product, encoded with wrapping semantics to match NumPy's `int64`.
fn ours_i64(m: usize, k: usize, n: usize, a: &[i64], b: &[i64]) -> Vec<i64> {
    let mut c = vec![0i64; m * n];
    if m == 0 || n == 0 {
        return c;
    }
    let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
    let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
    let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
    let mut t = Triple::new(av, bv, cv).unwrap();
    gemm(
        &mut t,
        &Linear::OVERWRITE,
        GemmOptions {
            encode: EncodeMode::Wrapping,
            ..Default::default()
        },
        &mut Scratch::none(),
    );
    c
}

/// `CX-10`: byte-identical with NumPy `int64` over every committed case.
#[test]
fn numpy_int64_is_byte_identical_cx_10() {
    let dir = oracle_dir();
    let manifest: serde_json::Value =
        serde_json::from_slice(&std::fs::read(dir.join("manifest.json")).expect("manifest"))
            .expect("manifest parses");

    assert_eq!(manifest["id"], "CX-10");
    assert_eq!(manifest["dtype"], "int64");
    eprintln!(
        "CX-10: numpy {} via {}",
        manifest["numpy_version"].as_str().unwrap_or("?"),
        manifest["entry"].as_str().unwrap_or("?")
    );

    let cases = manifest["cases"].as_array().expect("cases");
    assert!(!cases.is_empty(), "the oracle must have cases");

    for case in cases {
        let stem = case["stem"].as_str().expect("stem");
        let m = case["shape"]["m"].as_u64().unwrap() as usize;
        let k = case["shape"]["k"].as_u64().unwrap() as usize;
        let n = case["shape"]["n"].as_u64().unwrap() as usize;

        // R11: the artifact is checked against its recorded digest before it is
        // believed. An oracle whose bytes have drifted is not an oracle.
        for (field, name) in [
            ("a_sha256", "a"),
            ("b_sha256", "b"),
            ("expected_sha256", "expected"),
        ] {
            let path = dir.join(format!("{stem}.{name}.bin"));
            let actual = format!("sha256:{}", sha256_hex(&std::fs::read(&path).unwrap()));
            assert_eq!(
                actual,
                case[field].as_str().unwrap(),
                "{} has drifted from its recorded digest",
                path.display()
            );
        }

        let a = read_i64(&dir.join(format!("{stem}.a.bin")));
        let b = read_i64(&dir.join(format!("{stem}.b.bin")));
        let expected = read_i64(&dir.join(format!("{stem}.expected.bin")));

        assert_eq!(
            ours_i64(m, k, n, &a, &b),
            expected,
            "CX-10 mismatch at {stem}"
        );
    }
}

/// The checksum routine must be able to fail, or the verification above is
/// decoration.
#[test]
fn the_committed_checksum_is_falsifiable() {
    // The empty string's SHA-256 is a published constant.
    assert_eq!(
        sha256_hex(b""),
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    );
    assert_eq!(
        sha256_hex(b"abc"),
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    );
    assert_ne!(sha256_hex(b"abc"), sha256_hex(b"abd"));
}
