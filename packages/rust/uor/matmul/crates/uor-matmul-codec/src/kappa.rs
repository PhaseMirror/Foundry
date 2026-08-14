//! Content addressing (§6.4).
//!
//! A weight artifact's identity is the kappa label of its **canonical
//! manifest**, not of its code bytes, so that a transcode between tiers is
//! visibly a different artifact with a provably identical decoded stream. That
//! is `CL-MM01` with an address attached to each side, and `CK-05` is the test
//! that says it.
//!
//! Bulk arrays are referenced by digest rather than inlined, so the manifest
//! stays inside `uor-addr-1`'s depth and width ceilings and the address stays
//! cheap.
//!
//! # Allocation
//!
//! [`Manifest::write_canonical_json`] writes into a caller-supplied buffer and
//! allocates nothing, so the default build of this crate remains heap-free
//! (R7). The `kappa` feature additionally pulls in `uor-addr-1` to turn that
//! JSON into a label; that crate owns its own allocation, which is why the
//! feature is off by default and why the manifest writer is usable without it.

use uor_matmul_core::Bound;

use crate::tier::TierId;

/// Bytes in a kappa label.
pub const ADDRESS_LABEL_BYTES: usize = 71;

/// A canonical weight-artifact manifest.
///
/// The field set and its JSON spelling are normative and are restated in
/// `ARCHITECTURE.md`. Changing either changes every artifact's identity, which
/// is why the schema carries a `spec` tag.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Manifest<'a> {
    /// Which tier decodes the codes.
    pub tier: TierId,
    /// The alphabet bound the decoded stream satisfies.
    pub bound: u128,
    /// Rows of the decoded matrix.
    pub rows: usize,
    /// Decoded elements per row.
    pub cols: usize,
    /// Alphabet elements produced per code.
    pub block: usize,
    /// `sha256:<64hex>` of the codebook, or of the empty table for a codec that
    /// has none.
    pub codebook_sha256: &'a str,
    /// `sha256:<64hex>` of the code bytes.
    pub codes_sha256: &'a str,
    /// The schema tag.
    pub spec: &'a str,
}

/// The manifest could not be rendered or addressed.
///
/// Neither variant can be caused by the *values* in a matrix, only by a
/// manifest that does not describe an artifact. Like [`uor_matmul_core::
/// NotAProduct`], this is non-existence, decided before any arithmetic.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[non_exhaustive]
pub enum KappaError {
    /// The caller's buffer is too small for the canonical JSON.
    BufferTooSmall {
        /// Bytes the manifest needs.
        needed: usize,
        /// Bytes the caller offered.
        offered: usize,
    },
    /// A digest field is not a `sha256:<64hex>` string.
    MalformedDigest,
    /// The addressing transform rejected the manifest.
    NotAddressable,
}

impl core::fmt::Display for KappaError {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::BufferTooSmall { needed, offered } => {
                write!(
                    f,
                    "the canonical manifest needs {needed} bytes, {offered} offered"
                )
            }
            Self::MalformedDigest => write!(f, "a digest field is not sha256:<64hex>"),
            Self::NotAddressable => write!(f, "the addressing transform rejected the manifest"),
        }
    }
}

/// A cursor that writes into a caller's buffer and never allocates.
struct Out<'a> {
    buf: &'a mut [u8],
    at: usize,
    overflowed: bool,
}

impl Out<'_> {
    fn push(&mut self, bytes: &[u8]) {
        let end = self.at.saturating_add(bytes.len()); // R3-ok: a buffer cursor, checked below
        if end > self.buf.len() {
            self.overflowed = true;
            self.at = end;
            return;
        }
        self.buf[self.at..end].copy_from_slice(bytes);
        self.at = end;
    }

    fn push_u128(&mut self, mut v: u128) {
        // 39 is the decimal width of `u128::MAX`, so this buffer cannot be
        // outrun by any input. A derivation, not a choice (R8).
        let mut digits = [0u8; 39];
        let mut n = 0;
        if v == 0 {
            self.push(b"0");
            return;
        }
        while v > 0 {
            digits[n] = b'0' + (v % 10) as u8;
            v /= 10;
            n += 1;
        }
        for i in (0..n).rev() {
            self.push(&digits[i..=i]);
        }
    }
}

impl Manifest<'_> {
    /// Write the JCS-RFC8785 canonical JSON for this manifest.
    ///
    /// Returns the number of bytes written. Object members are emitted in
    /// lexicographic order of their keys, with no whitespace and no escapes,
    /// which is what JCS requires and what makes two independently produced
    /// manifests of the same artifact byte-identical.
    ///
    /// Allocates nothing. If `out` is too small the needed length is reported
    /// rather than a partial write being passed off as a manifest.
    pub fn write_canonical_json(&self, out: &mut [u8]) -> Result<usize, KappaError> {
        for d in [self.codebook_sha256, self.codes_sha256] {
            if !is_sha256(d) {
                return Err(KappaError::MalformedDigest);
            }
        }
        let mut w = Out {
            buf: out,
            at: 0,
            overflowed: false,
        };

        // Lexicographic key order: block, bound, codebook_sha256,
        // codes_sha256, cols, rows, spec, tier.
        w.push(b"{\"block\":");
        w.push_u128(self.block as u128);
        w.push(b",\"bound\":");
        w.push_u128(self.bound);
        w.push(b",\"codebook_sha256\":\"");
        w.push(self.codebook_sha256.as_bytes());
        w.push(b"\",\"codes_sha256\":\"");
        w.push(self.codes_sha256.as_bytes());
        w.push(b"\",\"cols\":");
        w.push_u128(self.cols as u128);
        w.push(b",\"rows\":");
        w.push_u128(self.rows as u128);
        w.push(b",\"spec\":\"");
        w.push(self.spec.as_bytes());
        w.push(b"\",\"tier\":\"");
        w.push(self.tier.as_str().as_bytes());
        w.push(b"\"}");

        if w.overflowed {
            return Err(KappaError::BufferTooSmall {
                needed: w.at,
                offered: w.buf.len(),
            });
        }
        Ok(w.at)
    }

    /// The manifest for a coded matrix, given the two digests the caller has
    /// computed over the bulk arrays.
    pub fn of<E, Bd, C>(
        matrix: &crate::CodedMatrix<'_, E, Bd, C>,
        codebook_sha256: &'static str,
        codes_sha256: &'static str,
        spec: &'static str,
    ) -> Manifest<'static>
    where
        E: uor_matmul_core::IntegerElement,
        Bd: Bound,
        C: crate::Codec<E, Bd>,
    {
        Manifest {
            tier: C::TIER,
            bound: Bd::VALUE,
            rows: matrix.rows(),
            cols: matrix.cols(),
            block: C::MAX_BLOCK,
            codebook_sha256,
            codes_sha256,
            spec,
        }
    }
}

fn is_sha256(s: &str) -> bool {
    let Some(hex) = s.strip_prefix("sha256:") else {
        return false;
    };
    hex.len() == 64
        && hex
            .bytes()
            .all(|b| b.is_ascii_hexdigit() && !b.is_ascii_uppercase())
}

/// Address a manifest, writing the label into a caller-supplied buffer.
///
/// The label is `uor-addr-1`'s JCS-RFC8785 + NFC + SHA-256 transform applied to
/// [`Manifest::write_canonical_json`]'s output.
#[cfg(feature = "kappa")]
pub fn address_into(
    manifest: &Manifest<'_>,
    scratch: &mut [u8],
    out: &mut [u8; ADDRESS_LABEL_BYTES],
) -> Result<(), KappaError> {
    let n = manifest.write_canonical_json(scratch)?;
    let outcome = uor_addr_1::address(&scratch[..n]).map_err(|_| KappaError::NotAddressable)?;
    let label = outcome.label.as_bytes();
    if label.len() != ADDRESS_LABEL_BYTES {
        return Err(KappaError::NotAddressable);
    }
    out.copy_from_slice(label);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const D0: &str = "sha256:0000000000000000000000000000000000000000000000000000000000000000";
    const D1: &str = "sha256:1111111111111111111111111111111111111111111111111111111111111111";

    /// CK-08: the manifest is canonical --- keys in lexicographic order, no
    /// whitespace --- so two independent producers of the same artifact write
    /// the same bytes and therefore mint the same label.
    #[test]
    fn canonical_json_is_byte_stable_ck_08() {
        let m = Manifest {
            tier: TierId::Book,
            bound: 127,
            rows: 4096,
            cols: 4096,
            block: 8,
            codebook_sha256: D0,
            codes_sha256: D1,
            spec: "uor-matmul/1",
        };
        let mut buf = [0u8; 512];
        let n = m.write_canonical_json(&mut buf).unwrap();
        let text = core::str::from_utf8(&buf[..n]).unwrap();
        assert_eq!(
            text,
            concat!(
                "{\"block\":8,\"bound\":127,",
                "\"codebook_sha256\":\"sha256:00000000000000000000000000000000",
                "00000000000000000000000000000000\",",
                "\"codes_sha256\":\"sha256:11111111111111111111111111111111",
                "11111111111111111111111111111111\",",
                "\"cols\":4096,\"rows\":4096,\"spec\":\"uor-matmul/1\",\"tier\":\"Book\"}"
            )
        );
    }

    /// A short buffer reports what it needed rather than truncating, because a
    /// truncated manifest would address a different artifact.
    #[test]
    fn a_short_buffer_reports_the_need_ck_08() {
        let m = Manifest {
            tier: TierId::Identity,
            bound: 1,
            rows: 1,
            cols: 1,
            block: 1,
            codebook_sha256: D0,
            codes_sha256: D1,
            spec: "uor-matmul/1",
        };
        let mut buf = [0u8; 8];
        match m.write_canonical_json(&mut buf) {
            Err(KappaError::BufferTooSmall { needed, offered }) => {
                assert!(needed > 8);
                assert_eq!(offered, 8);
            }
            other => panic!("expected BufferTooSmall, got {other:?}"),
        }
    }

    /// A malformed digest is rejected before anything is written: an artifact
    /// whose bulk arrays are not addressed is not an addressable artifact.
    #[test]
    fn a_malformed_digest_is_rejected_ck_08() {
        let m = Manifest {
            tier: TierId::Identity,
            bound: 1,
            rows: 1,
            cols: 1,
            block: 1,
            codebook_sha256: "not-a-digest",
            codes_sha256: D1,
            spec: "uor-matmul/1",
        };
        let mut buf = [0u8; 512];
        assert_eq!(
            m.write_canonical_json(&mut buf),
            Err(KappaError::MalformedDigest)
        );
    }
}
