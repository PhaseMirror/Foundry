//! Typed registries parsed from `model/*.toml`.
//!
//! The model is authored once, as prose in `docs/conceptual-model/` and as
//! typed data here (R10). Constants, tiers, envelopes, oracles, and the claim
//! ledger have exactly one source, and the Rust consts in the shipped crates
//! are generated from it by [`codegen`].
//!
//! This crate is build-time and CI infrastructure. It is not a dependency of
//! any shipped crate, and it may use `std`.

#![deny(missing_docs)]

pub mod codegen;
pub mod derive;
pub mod registry;

pub use registry::{
    Authorities, Authority, AuthorityRow, Blocking, Claim, Codebook, Complete, Constants, Element,
    IdRow, Ids, Instantiation, Ledger, Level, Narrow, Oracle, Oracles, Threshold, Tier, Tiers,
    Width, Widths,
};

use std::path::{Path, PathBuf};

/// Everything `model/*.toml` says, parsed and cross-checked.
#[derive(Debug, Clone)]
pub struct Model {
    /// `model/constants.toml`.
    pub constants: Constants,
    /// `model/widths.toml`.
    pub widths: Widths,
    /// `model/tiers.toml`.
    pub tiers: Tiers,
    /// `model/oracles.toml`.
    pub oracles: Oracles,
    /// `model/ledger.toml`.
    pub ledger: Ledger,
    /// `model/ids.toml`: the conformance ID register (§2.1).
    pub ids: Ids,
    /// `model/authorities.toml`: what this repository cites (§12).
    pub authorities: Authorities,
}

/// A failure to load or to cross-check the model.
#[derive(Debug)]
pub enum ModelError {
    /// A model file could not be read.
    Io(PathBuf, std::io::Error),
    /// A model file could not be parsed.
    Parse(PathBuf, toml::de::Error),
    /// The model disagrees with itself, or with a derivation (CM-01).
    Inconsistent(String),
}

impl std::fmt::Display for ModelError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(p, e) => write!(f, "reading {}: {e}", p.display()),
            Self::Parse(p, e) => write!(f, "parsing {}: {e}", p.display()),
            Self::Inconsistent(m) => write!(f, "model is inconsistent: {m}"),
        }
    }
}

impl std::error::Error for ModelError {}

impl Model {
    /// Load every model file from a `model/` directory.
    pub fn load(dir: &Path) -> Result<Self, ModelError> {
        Ok(Self {
            constants: read(dir, "constants.toml")?,
            widths: read(dir, "widths.toml")?,
            tiers: read(dir, "tiers.toml")?,
            oracles: read(dir, "oracles.toml")?,
            ledger: read(dir, "ledger.toml")?,
            ids: read(dir, "ids.toml")?,
            authorities: read(dir, "authorities.toml")?,
        })
    }

    /// Load the model from the repository root, resolved from this crate's
    /// manifest directory so that it works from any working directory.
    pub fn load_from_repo_root() -> Result<Self, ModelError> {
        Self::load(&repo_root().join("model"))
    }

    /// Cross-check every derivable numeral in the model against the `const fn`
    /// that derives it (`CM-01`, `CM-02`, R1).
    ///
    /// This is the whole of R1's enforcement: a numeral that survives this
    /// check is either derived or explicitly allowlisted, and there is no third
    /// category.
    pub fn check(&self) -> Result<(), ModelError> {
        let bad = |m: String| ModelError::Inconsistent(m);
        let max_k_bits = self.constants.max_k_bits;

        // CM-01: every accumulator width is `acc_bits` of its element type.
        for w in &self.widths.width {
            let e = self
                .constants
                .element
                .iter()
                .find(|e| e.name == w.element)
                .ok_or_else(|| bad(format!("widths.toml names unknown element {}", w.element)))?;

            let bits = derive::acc_bits(max_k_bits, e.bits, e.product_terms);
            if bits != w.bits {
                return Err(bad(format!(
                    "acc_bits({}) = {bits}, but widths.toml says {}",
                    e.name, w.bits
                )));
            }
            if derive::accumulator_for(bits) != w.accumulator {
                return Err(bad(format!(
                    "acc_bits({}) = {bits} resolves to {}, but widths.toml says {}",
                    e.name,
                    derive::accumulator_for(bits),
                    w.accumulator
                )));
            }
            if w.acc_bits != (w.bytes as u32).saturating_mul(8) {
                return Err(bad(format!(
                    "{}: acc_bits {} disagrees with bytes {}",
                    e.name, w.acc_bits, w.bytes
                )));
            }
            if w.acc_bits < w.bits {
                return Err(bad(format!(
                    "{}: the accumulator has {} bits but the worst case needs {}",
                    e.name, w.acc_bits, w.bits
                )));
            }
        }

        // `full` is a property of the type: |E::MIN| = 2^(BITS-1).
        for e in &self.constants.element {
            let expect = 1u128 << (e.bits - 1);
            if e.bytes.saturating_mul(8) != e.bits.saturating_mul(e.product_terms) {
                return Err(bad(format!(
                    "{}: {} bytes cannot hold {} components of {} bits",
                    e.name, e.bytes, e.product_terms, e.bits
                )));
            }
            if e.full != expect {
                return Err(bad(format!(
                    "{}: FULL should be 2^{} = {expect}, model says {}",
                    e.name,
                    e.bits - 1,
                    e.full
                )));
            }
        }

        // R1: every narrow-register threshold is floor(cap / per_step).
        for t in &self.constants.narrow.threshold {
            let cap = t.cap_override.unwrap_or(self.constants.narrow.cap_i32);
            let expect = cap / t.per_step;
            if expect != t.k_max {
                return Err(bad(format!(
                    "narrow threshold {}: floor({cap} / {}) = {expect}, model says {}",
                    t.name, t.per_step, t.k_max
                )));
            }
        }

        // Complete accumulators: the span is the product exponent range, and
        // the limb count covers span + guard + sign.
        for c in &self.widths.complete {
            let span = c
                .max_product_exp
                .checked_sub(c.min_product_exp)
                .ok_or_else(|| bad(format!("{}: product exponent range underflows", c.element)))?;
            if span != c.span_bits {
                return Err(bad(format!(
                    "{}: product exponent span is {span}, model says {}",
                    c.element, c.span_bits
                )));
            }
            let total = c.span_bits + c.guard_bits as i64 + c.sign_bits as i64;
            if total != c.total_bits {
                return Err(bad(format!(
                    "{}: total bits should be {total}, model says {}",
                    c.element, c.total_bits
                )));
            }
            let limbs = derive::limbs_for(c.total_bits as u32);
            if limbs != c.limbs {
                return Err(bad(format!(
                    "{}: {} bits needs {limbs} limbs, model says {}",
                    c.element, c.total_bits, c.limbs
                )));
            }
            if c.bytes != c.limbs.saturating_mul(8) {
                return Err(bad(format!(
                    "{}: {} limbs is {} bytes, model says {}",
                    c.element,
                    c.limbs,
                    c.limbs * 8,
                    c.bytes
                )));
            }
        }

        // Exactly one canonical instantiation, and every instantiation's bound
        // is admissible for its element type.
        let canonical: Vec<_> = self
            .constants
            .instantiation
            .iter()
            .filter(|i| i.canonical)
            .collect();
        if canonical.len() != 1 {
            return Err(bad(format!(
                "expected exactly one canonical instantiation, found {}",
                canonical.len()
            )));
        }
        for i in &self.constants.instantiation {
            let e = self
                .constants
                .element
                .iter()
                .find(|e| e.name == i.element)
                .ok_or_else(|| bad(format!("instantiation {} names unknown element", i.name)))?;
            if i.bound > e.full {
                return Err(bad(format!(
                    "instantiation {}: bound {} exceeds {}'s FULL of {}",
                    i.name, i.bound, e.name, e.full
                )));
            }
        }

        // The complete accumulator's guard is the same declared depth the
        // integer accumulators use. If the two ever diverged, a float
        // accumulation and an integer one would be sized against different
        // machines (§3.3).
        for c in &self.widths.complete {
            if c.guard_bits != max_k_bits {
                return Err(bad(format!(
                    "{}: guard_bits is {} but MAX_K_BITS is {max_k_bits}; a float and an \
                     integer accumulation must be sized against the same machine",
                    c.element, c.guard_bits
                )));
            }
        }

        self.ledger.check()?;
        self.check_oracle_ledger_agreement()?;
        self.check_ids()?;
        self.check_authorities()?;
        Ok(())
    }

    /// `CM-02`: every registered ID is well formed, and every class obeys the
    /// rules §2 states about it.
    fn check_ids(&self) -> Result<(), ModelError> {
        let bad = |m: String| ModelError::Inconsistent(m);
        let mut seen: Vec<&str> = Vec::new();
        for row in &self.ids.id {
            if seen.contains(&row.id.as_str()) {
                return Err(bad(format!("{}: registered twice", row.id)));
            }
            seen.push(&row.id);

            // §2: there is no CN-* class. Negative testing presupposes inputs
            // the library rejects, and by C6 there are none.
            if row.id.starts_with("CN-") {
                return Err(bad(format!(
                    "{}: there is no CN-* class; the library rejects nothing beyond \
                     non-existence of the requested object, which CS-03 covers",
                    row.id
                )));
            }
            // §2: a fitted exponent is measured and reported, never asserted.
            if row.id.starts_with("CG-") && row.level != Level::Open {
                return Err(bad(format!("{}: a scaling exponent must be open", row.id)));
            }
            // §2, R4: a cross-library *result* is evidence that the kernels
            // realize the identity, not a proof of it. It is never some-true.
            if row.id.starts_with("CX-") && row.level == Level::SomeTrue {
                return Err(bad(format!(
                    "{}: a cross-library result is `build`, never `some-true`",
                    row.id
                )));
            }
            if row.statement.trim().is_empty() {
                return Err(bad(format!(
                    "{}: an untagged claim does not ship (R4)",
                    row.id
                )));
            }
        }

        // §3.4: the integer oracles agree byte for byte over the whole corpus
        // with no exempted region, so none of them may be `open`.
        for id in ["CX-01", "CX-02", "CX-03", "CX-04", "CX-10"] {
            let row = self
                .ids
                .get(id)
                .ok_or_else(|| bad(format!("{id}: an integer oracle with no register row")))?;
            if row.level != Level::Build {
                return Err(bad(format!(
                    "{id}: an integer oracle is bit-identical everywhere by ring \
                     homomorphism, so its claim is `build` and not a measurement"
                )));
            }
        }
        Ok(())
    }

    /// `CM-03`: every `some-true` claim has a row in `model/authorities.toml`
    /// with a citation, and every authority names IDs that exist.
    fn check_authorities(&self) -> Result<(), ModelError> {
        let bad = |m: String| ModelError::Inconsistent(m);
        for a in &self.authorities.authority {
            if a.citation.trim().is_empty() {
                return Err(bad(format!("{}: an authority with no citation", a.id)));
            }
            if a.checksum == "none" && a.checksum_reason.trim().is_empty() {
                return Err(bad(format!(
                    "{}: no checksum and no reason. A missing checksum must be a stated \
                     fact, not an omission (R11)",
                    a.id
                )));
            }
            for id in &a.realized_by {
                if self.ids.get(id).is_none() {
                    return Err(bad(format!("{}: realized_by names unknown ID {id}", a.id)));
                }
            }
        }
        // Every some-true claim in the ledger names a known authority.
        for c in &self.ledger.claim {
            if c.level != Level::SomeTrue {
                continue;
            }
            let Some(name) = &c.authority else {
                return Err(bad(format!(
                    "{}: a some-true claim must name an authority",
                    c.id
                )));
            };
            if !self.authorities.authority.iter().any(|a| &a.id == name) {
                return Err(bad(format!(
                    "{}: cites {name}, which has no row in model/authorities.toml (CM-03)",
                    c.id
                )));
            }
        }
        Ok(())
    }

    /// Every oracle row's honesty level agrees with its ledger claim, and every
    /// `inexact` oracle is `open` rather than `build` (§3.4, R4).
    fn check_oracle_ledger_agreement(&self) -> Result<(), ModelError> {
        for o in &self.oracles.oracle {
            let claim = self.ids.get(&o.id).ok_or_else(|| {
                ModelError::Inconsistent(format!("oracle {} has no register row", o.id))
            })?;
            if claim.level != o.honesty {
                return Err(ModelError::Inconsistent(format!(
                    "oracle {}: registry says {:?}, ledger says {:?}",
                    o.id, o.honesty, claim.level
                )));
            }
            // §3.4: an oracle that is not exact for a case cannot be expected
            // to return our bytes, so its claim is a measurement, not a result.
            let want = if o.exactness == "exact" {
                Level::Build
            } else {
                Level::Open
            };
            if claim.level != want {
                return Err(ModelError::Inconsistent(format!(
                    "oracle {} is {} so its claim must be {want:?}, not {:?}",
                    o.id, o.exactness, claim.level
                )));
            }
            // R4: a CX-* result is `build`, never `some-true`.
            if claim.level == Level::SomeTrue {
                return Err(ModelError::Inconsistent(format!(
                    "oracle {} is some-true; a cross-library result is evidence that the \
                     kernels realize the identity, not a proof of it",
                    o.id
                )));
            }
        }
        Ok(())
    }
}

fn read<T: serde::de::DeserializeOwned>(dir: &Path, name: &str) -> Result<T, ModelError> {
    let path = dir.join(name);
    let text = std::fs::read_to_string(&path).map_err(|e| ModelError::Io(path.clone(), e))?;
    toml::from_str(&text).map_err(|e| ModelError::Parse(path, e))
}

/// The repository root, resolved from this crate's manifest directory.
pub fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("crates/uor-matmul-model is two levels below the repository root")
        .to_path_buf()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// CM-01: the model is self-consistent and every numeral in it derives.
    #[test]
    fn model_is_consistent_cm_01() {
        let model = Model::load_from_repo_root().expect("model loads");
        model.check().expect("model checks");
    }

    /// CM-02: every registered ID is unique and well formed.
    #[test]
    fn the_id_register_is_well_formed_cm_02() {
        let model = Model::load_from_repo_root().expect("model loads");
        model.check().expect("model checks");
        assert!(model.ids.id.len() > 50, "the register is the whole of §2.1");
    }

    /// CM-03: every `some-true` claim cites an authority that exists.
    #[test]
    fn every_some_true_claim_cites_an_authority_cm_03() {
        let model = Model::load_from_repo_root().expect("model loads");
        for c in &model.ledger.claim {
            if c.level == Level::SomeTrue {
                let name = c
                    .authority
                    .as_ref()
                    .expect("a some-true claim names its authority");
                assert!(
                    model.authorities.authority.iter().any(|a| &a.id == name),
                    "{name}"
                );
            }
        }
    }
}
