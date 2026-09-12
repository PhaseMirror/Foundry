//! The typed shape of `model/*.toml`.
//!
//! Nothing here interprets the model; [`crate::Model::check`] does that. These
//! types exist so that a malformed model is a parse error rather than a
//! silently wrong constant.

use serde::{Deserialize, Deserializer};

use crate::ModelError;

/// Deserialize a `u128` written either as a TOML integer or as a string.
///
/// TOML integers are `i64`, so `|i64::MIN|` --- the `FULL` of the `i64`
/// alphabet --- has no integer spelling. Writing it as a string is not a
/// workaround: it is the model saying that this value is a magnitude, not a
/// machine integer, which is exactly why the accumulator is wider than one.
fn u128_flex<'de, D: Deserializer<'de>>(d: D) -> Result<u128, D::Error> {
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum Repr {
        // TOML's integer type is i64; anything wider arrives as a string.
        Int(i64),
        Str(String),
    }
    match Repr::deserialize(d)? {
        Repr::Int(i) => u128::try_from(i).map_err(serde::de::Error::custom),
        Repr::Str(s) => s.trim().parse().map_err(serde::de::Error::custom),
    }
}

/// [`u128_flex`] for an optional field.
fn opt_u128_flex<'de, D: Deserializer<'de>>(d: D) -> Result<Option<u128>, D::Error> {
    Option::<toml::Value>::deserialize(d)?
        .map(|v| u128_flex(v).map_err(serde::de::Error::custom))
        .transpose()
}

/// One of the three UTQC honesty levels (R4).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Level {
    /// A fact reproduced from an authority. Not established here.
    SomeTrue,
    /// Constructed here and validated against its oracle.
    Build,
    /// Measured and reported, never asserted.
    Open,
}

impl Level {
    /// The token used in `model/*.toml` and in generated documentation.
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::SomeTrue => "some-true",
            Self::Build => "build",
            Self::Open => "open",
        }
    }
}

/// `model/constants.toml`.
#[derive(Debug, Clone, Deserialize)]
pub struct Constants {
    /// The schema tag; must be `uor-matmul/1`.
    pub spec: String,
    /// The largest reduction depth any addressable machine can present.
    ///
    /// Declared, not probed, so the accumulator type is the same on a 64-bit
    /// host, a 32-bit host, and wasm32 (§3.2).
    pub max_k_bits: u32,
    /// Machine integer types usable as alphabet elements.
    pub element: Vec<Element>,
    /// Named `(element, bound)` pairs. Exactly one is canonical.
    pub instantiation: Vec<Instantiation>,
    /// Narrow-register thresholds. Not limits (§5.1).
    pub narrow: Narrow,
    /// Cache-shaped tuning parameters, allowlisted out of R1.
    pub blocking: Blocking,
}

/// A machine integer type usable as an alphabet element and as a coded weight.
#[derive(Debug, Clone, Deserialize)]
pub struct Element {
    /// The Rust type name.
    pub name: String,
    /// Width in bits.
    pub bits: u32,
    /// The largest magnitude the type can hold, so that `Full<E>` admits every
    /// value of `E` and the default path cannot reject anything.
    #[serde(deserialize_with = "u128_flex")]
    pub full: u128,
    /// Size of one value in bytes. For a complex type this is twice the
    /// component size, which is why the derivation reads it separately from
    /// `bits`.
    pub bytes: u32,
    /// Element-products summed by one `mac`. One for a scalar type, two for a
    /// complex one.
    #[serde(default = "one")]
    pub product_terms: u32,
    /// The resolved accumulator type name.
    pub accumulator: String,
}

const fn one() -> u32 {
    1
}

/// A named `(element, bound)` pair. W8A8 is the canonical one.
#[derive(Debug, Clone, Deserialize)]
pub struct Instantiation {
    /// The name used in documentation and test IDs.
    pub name: String,
    /// The element type this instantiates over.
    pub element: String,
    /// The declared alphabet bound `B`.
    #[serde(deserialize_with = "u128_flex")]
    pub bound: u128,
    /// Whether this is *the* canonical instantiation. Exactly one is.
    pub canonical: bool,
    /// Free-form provenance.
    #[serde(default)]
    pub note: String,
}

/// Narrow-register thresholds (§5.1, §7.3).
#[derive(Debug, Clone, Deserialize)]
pub struct Narrow {
    /// `i32::MAX`, the default cap for a 32-bit lane.
    #[serde(deserialize_with = "u128_flex")]
    pub cap_i32: u128,
    /// One row per instruction sequence.
    pub threshold: Vec<Threshold>,
}

/// The `k` at which one instruction sequence stops being usable for a tile.
///
/// This is not a limit on anything. A tile past its threshold uses a wider
/// register and computes the same integer.
#[derive(Debug, Clone, Deserialize)]
pub struct Threshold {
    /// Stable identifier, used in generated const names.
    pub name: String,
    /// The instruction sequence and its worst-case per-step magnitude.
    pub sequence: String,
    /// The worst-case magnitude contributed by one step.
    #[serde(deserialize_with = "u128_flex")]
    pub per_step: u128,
    /// `floor(cap / per_step)`, pinned so R1's gate has something to check.
    #[serde(deserialize_with = "u128_flex")]
    pub k_max: u128,
    /// A cap other than `cap_i32`, for sequences that accumulate in i16.
    #[serde(default, deserialize_with = "opt_u128_flex")]
    pub cap_override: Option<u128>,
}

/// Cache-shaped tuning parameters. Changing one cannot change any output byte,
/// only which traversal produces it (`CD-01`).
#[derive(Debug, Clone, Deserialize)]
pub struct Blocking {
    /// Asserts the R1 allowlist applies to this table.
    pub allowlisted_from_r1: bool,
    /// Why the allowlist is sound.
    pub reason: String,
    /// Rows of A per block.
    pub mc: usize,
    /// Depth per panel.
    pub kc: usize,
    /// Columns of B per block.
    pub nc: usize,
    /// The machine's cache line, in bytes. Sizes the transpose a reduce panel
    /// needs so that the operand is read once rather than once per column.
    pub cache_line_bytes: usize,
}

/// `model/widths.toml`.
#[derive(Debug, Clone, Deserialize)]
pub struct Widths {
    /// The schema tag.
    pub spec: String,
    /// One row per integer element type.
    pub width: Vec<Width>,
    /// One row per float element type.
    pub complete: Vec<Complete>,
}

/// The derived accumulator for one integer element type.
#[derive(Debug, Clone, Deserialize)]
pub struct Width {
    /// The element type name.
    pub element: String,
    /// `acc_bits(E)`: the worst case any addressable machine can express.
    pub bits: u32,
    /// The resolved accumulator type name.
    pub accumulator: String,
    /// The accumulator's actual width.
    pub acc_bits: u32,
    /// The accumulator's size in bytes.
    pub bytes: usize,
}

/// The derived complete accumulator for one float element type (§3.3).
#[derive(Debug, Clone, Deserialize)]
pub struct Complete {
    /// The element type name.
    pub element: String,
    /// Twice the minimum subnormal exponent.
    pub min_product_exp: i64,
    /// Twice the maximum finite exponent.
    pub max_product_exp: i64,
    /// The product exponent range.
    pub span_bits: i64,
    /// `log2` of the largest `k` the machine can address.
    pub guard_bits: u32,
    /// One.
    pub sign_bits: u32,
    /// Span plus guard plus sign.
    pub total_bits: i64,
    /// 64-bit limbs sufficient for `total_bits`.
    pub limbs: usize,
    /// The accumulator's size in bytes.
    pub bytes: usize,
}

/// `model/tiers.toml`.
#[derive(Debug, Clone, Deserialize)]
pub struct Tiers {
    /// The schema tag.
    pub spec: String,
    /// One row per codec tier.
    pub tier: Vec<Tier>,
    /// One row per shipped codebook.
    pub codebook: Vec<Codebook>,
}

/// One instantiation of the `Codec` trait.
#[derive(Debug, Clone, Deserialize)]
pub struct Tier {
    /// The `TierId` discriminant name.
    pub id: String,
    /// The Rust type, with its parameters.
    pub rust: String,
    /// The stored code type.
    pub code: String,
    /// Alphabet elements produced per code, as a literal or an expression.
    pub block: toml::Value,
    /// Where the decode table lives. Always borrowed, never owned.
    pub table: String,
    /// Free-form notes, including anything normative about the encoding.
    #[serde(default)]
    pub note: String,
    /// The honesty level of the tier's claim.
    pub honesty: Level,
}

/// A shipped codebook. Data, borrowed from the caller, never learned here.
#[derive(Debug, Clone, Deserialize)]
pub struct Codebook {
    /// Stable identifier.
    pub id: String,
    /// Number of entries.
    pub entries: usize,
    /// Alphabet elements per entry.
    pub block: usize,
    /// The element type the entries are drawn from.
    pub element: String,
    /// Size of the table in bytes.
    pub bytes: usize,
    /// Where the table came from.
    pub source: String,
    /// The honesty level of the codebook's own claim.
    pub honesty: Level,
    /// The quality claim, which is always "none" (N3).
    pub quality_claim: String,
}

/// `model/oracles.toml`.
#[derive(Debug, Clone, Deserialize)]
pub struct Oracles {
    /// The schema tag.
    pub spec: String,
    /// External crates used as oracles.
    pub oracle: Vec<Oracle>,
    /// Cited authorities. Not executed, never re-derived (§12, N2).
    pub authority: Vec<Authority>,
}

/// An external crate used as an oracle.
#[derive(Debug, Clone, Deserialize)]
pub struct Oracle {
    /// The conformance ID this oracle discharges.
    pub id: String,
    /// The crate name.
    #[serde(rename = "crate")]
    pub krate: String,
    /// The `uor-matmul-validate` feature that enables it.
    pub feature: String,
    /// The element type compared.
    pub element: String,
    /// The oracle's entry point.
    pub entry: String,
    /// `exact` or `inexact` (§3.4).
    pub exactness: String,
    /// Whether this oracle's lineage is independent of the others'.
    pub independent: bool,
    /// Whether the oracle is behind an opt-in feature.
    #[serde(default)]
    pub optional: bool,
    /// The honesty level of the resulting claim.
    pub honesty: Level,
    /// Free-form provenance.
    #[serde(default)]
    pub note: String,
}

/// A cited authority. It tells the implementation what identity to realize, and
/// it is never re-derived, vendored, or gated on.
#[derive(Debug, Clone, Deserialize)]
pub struct Authority {
    /// Stable identifier, e.g. `CL-MM01`.
    pub id: String,
    /// Human-readable name.
    pub name: String,
    /// Where the authority lives.
    pub source: String,
    /// Always `some-true`.
    pub honesty: Level,
    /// What the authority says.
    pub statement: String,
}

/// `model/ledger.toml`.
#[derive(Debug, Clone, Deserialize)]
pub struct Ledger {
    /// The schema tag.
    pub spec: String,
    /// One row per claim.
    pub claim: Vec<Claim>,
}

/// One claim, at exactly one honesty level.
#[derive(Debug, Clone, Deserialize)]
pub struct Claim {
    /// The conformance ID, or an `AUTH-`/`OPEN-` prefixed identifier.
    pub id: String,
    /// The honesty level. Untagged claims do not ship (R4).
    pub level: Level,
    /// What is claimed.
    pub statement: String,
    /// The Gherkin file carrying the scenario (R9).
    #[serde(default)]
    pub feature: Option<String>,
    /// The authority a `some-true` claim is reproduced from.
    #[serde(default)]
    pub authority: Option<String>,
    /// Recorded sample size, for a `CP-*` claim.
    #[serde(default)]
    pub sample_size: Option<u64>,
    /// Recorded seed, for a `CP-*` claim.
    #[serde(default)]
    pub seed: Option<u64>,
}

impl Ledger {
    /// The meta-gate's structural half: every claim is well formed for its
    /// level (R4).
    ///
    /// The behavioural half --- that no test asserts an `open` claim as
    /// established --- lives in `uor-matmul-conformance`, because it needs the
    /// test names, not the model.
    pub fn check(&self) -> Result<(), ModelError> {
        for c in &self.claim {
            match c.level {
                Level::SomeTrue => {
                    if c.authority.is_none() {
                        return Err(ModelError::Inconsistent(format!(
                            "{}: a some-true claim must name the authority it is \
                             reproduced from",
                            c.id
                        )));
                    }
                }
                Level::Build => {
                    if c.feature.is_none() {
                        return Err(ModelError::Inconsistent(format!(
                            "{}: a build claim must name the Gherkin scenario that \
                             validates it (R9)",
                            c.id
                        )));
                    }
                    if c.authority.is_some() {
                        return Err(ModelError::Inconsistent(format!(
                            "{}: a build claim is evidence, not a reproduction of an \
                             authority; it must not name one",
                            c.id
                        )));
                    }
                }
                Level::Open => {
                    if c.authority.is_some() {
                        return Err(ModelError::Inconsistent(format!(
                            "{}: an open claim is a measurement and cannot cite an \
                             authority for its value",
                            c.id
                        )));
                    }
                }
            }
            // R4: every CP-* claim records its sample size and seed.
            if c.id.starts_with("CP-") && (c.sample_size.is_none() || c.seed.is_none()) {
                return Err(ModelError::Inconsistent(format!(
                    "{}: a statistical claim must record its sample size and seed",
                    c.id
                )));
            }
            // §2: every CG-* claim is open. A fitted exponent is a measurement.
            if c.id.starts_with("CG-") && c.level != Level::Open {
                return Err(ModelError::Inconsistent(format!(
                    "{}: a scaling exponent is measured and reported, never asserted",
                    c.id
                )));
            }
            // §2: there is no CN-* class. Negative testing presupposes inputs
            // the library rejects, and by C6 there are none.
            if c.id.starts_with("CN-") {
                return Err(ModelError::Inconsistent(format!(
                    "{}: there is no CN-* class; the library rejects nothing beyond \
                     non-existence of the requested object, which CS-* covers",
                    c.id
                )));
            }
        }
        Ok(())
    }

    /// Look up a claim by conformance ID.
    pub fn get(&self, id: &str) -> Option<&Claim> {
        self.claim.iter().find(|c| c.id == id)
    }
}

/// `model/ids.toml` --- the conformance ID register (§2.1).
#[derive(Debug, Clone, Deserialize)]
pub struct Ids {
    /// The schema tag.
    pub spec: String,
    /// One row per conformance ID.
    pub id: Vec<IdRow>,
}

/// One registered conformance ID.
#[derive(Debug, Clone, Deserialize)]
pub struct IdRow {
    /// The ID, e.g. `CS-04`.
    pub id: String,
    /// The honesty level of the claim (R4).
    pub level: Level,
    /// The Gherkin suite the scenario belongs to.
    pub suite: String,
    /// What the ID claims.
    pub statement: String,
}

impl Ids {
    /// Look up a row.
    pub fn get(&self, id: &str) -> Option<&IdRow> {
        self.id.iter().find(|r| r.id == id)
    }
}

/// `model/authorities.toml` --- what this repository cites (§12, CM-03).
#[derive(Debug, Clone, Deserialize)]
pub struct Authorities {
    /// The schema tag.
    pub spec: String,
    /// One row per cited authority.
    pub authority: Vec<AuthorityRow>,
}

/// A cited authority. Never re-derived, vendored, or gated on.
#[derive(Debug, Clone, Deserialize)]
pub struct AuthorityRow {
    /// Stable identifier, e.g. `CL-MM01`.
    pub id: String,
    /// Human-readable name.
    pub name: String,
    /// What a third party needs to find the source.
    pub citation: String,
    /// A checksum over the committed artifact, or `none`.
    pub checksum: String,
    /// Why there is no checksum, when there is none.
    #[serde(default)]
    pub checksum_reason: String,
    /// What the authority says.
    pub statement: String,
    /// The conformance IDs that are evidence this library realizes it.
    #[serde(default)]
    pub realized_by: Vec<String>,
}
