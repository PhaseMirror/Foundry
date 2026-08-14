use num_bigint::BigInt;
use num_traits::{One, Zero};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

/// Exact rational interval [lower, upper] eliminating IEEE-754 drift.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct RatInterval {
    pub lower: BigInt,
    pub upper: BigInt,
    pub denominator: BigInt,
}

impl RatInterval {
    pub fn new(lower: BigInt, upper: BigInt, denominator: BigInt) -> Self {
        assert!(lower <= upper, "RatInterval: lower > upper");
        assert!(
            denominator > BigInt::zero(),
            "RatInterval: non-positive denominator"
        );
        Self {
            lower,
            upper,
            denominator,
        }
    }

    pub fn singleton(q: BigInt, denom: BigInt) -> Self {
        Self::new(q.clone(), q, denom)
    }

    pub fn add(&self, other: &Self) -> Self {
        let common_denom = &self.denominator * &other.denominator;
        let self_num = &self.lower * &other.denominator;
        let other_num_l = &other.lower * &self.denominator;
        let self_num_u = &self.upper * &other.denominator;
        let other_num_u = &other.upper * &self.denominator;
        Self {
            lower: self_num + other_num_l,
            upper: self_num_u + other_num_u,
            denominator: common_denom,
        }
    }

    pub fn mul(&self, other: &Self) -> Self {
        let common_denom = &self.denominator * &other.denominator;
        let candidates = [
            &self.lower * &other.lower,
            &self.lower * &other.upper,
            &self.upper * &other.lower,
            &self.upper * &other.upper,
        ];
        let min = candidates.iter().min().unwrap().clone();
        let max = candidates.iter().max().unwrap().clone();
        Self {
            lower: min,
            upper: max,
            denominator: common_denom,
        }
    }

    pub fn width(&self) -> BigInt {
        &self.upper - &self.lower
    }

    pub fn is_contractive(&self, lip_bound: &BigInt) -> bool {
        self.width() < *lip_bound
    }
}

/// Operator symbol with arity and contraction bound.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct OpSymbol {
    pub name: String,
    pub arity: usize,
    pub lip_bound: RatInterval,
}

/// Terms of the initial algebra over an operator signature.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum Term {
    Var { name: String },
    App { op: OpSymbol, args: Vec<Term> },
}

impl Term {
    pub fn depth(&self) -> usize {
        match self {
            Term::Var { .. } => 0,
            Term::App { args, .. } => 1 + args.iter().map(|a| a.depth()).max().unwrap_or(0),
        }
    }

    pub fn size(&self) -> usize {
        match self {
            Term::Var { .. } => 1,
            Term::App { args, .. } => 1 + args.iter().map(|a| a.size()).sum::<usize>(),
        }
    }

    pub fn hash(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.serialize().as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn serialize(&self) -> String {
        serde_json::to_string(self).unwrap_or_default()
    }
}

/// Endomorphism of the initial algebra.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Endomorphism {
    pub on_var: HashMap<String, Term>,
    pub on_app: HashMap<String, Vec<Term>>,
}

impl Endomorphism {
    pub fn identity() -> Self {
        Self {
            on_var: HashMap::new(),
            on_app: HashMap::new(),
        }
    }

    pub fn compose(&self, other: &Self) -> Self {
        let mut on_var = HashMap::new();
        for (x, t) in &self.on_var {
            on_var.insert(x.clone(), other.apply(t));
        }
        let mut on_app = HashMap::new();
        for (op, args) in &self.on_app {
            let mapped_args: Vec<Term> = args.iter().map(|a| other.apply(a)).collect();
            on_app.insert(op.clone(), mapped_args);
        }
        Self { on_var, on_app }
    }

    pub fn apply(&self, term: &Term) -> Term {
        match term {
            Term::Var { name } => self
                .on_var
                .get(name)
                .cloned()
                .unwrap_or_else(|| term.clone()),
            Term::App { op, args } => {
                let mapped_args: Vec<Term> = args.iter().map(|a| self.apply(a)).collect();
                Term::App {
                    op: op.clone(),
                    args: mapped_args,
                }
            }
        }
    }

    pub fn is_contractive(&self) -> bool {
        for (_, t) in &self.on_var {
            if t.depth() > 0 {
                return false;
            }
        }
        true
    }
}

/// Operator-first arithmetic trait.
pub trait Operator {
    type Domain;
    type Codomain;

    fn apply(&self, input: Self::Domain) -> Self::Codomain;
    fn lip_constant(&self) -> RatInterval;
    fn is_contractive(&self) -> bool {
        self.lip_constant().width() < BigInt::one()
    }
}

/// Endomorphism rule trait for bounded composition.
pub trait EndomorphismRule {
    fn compose(&self, other: &Self) -> Self;
    fn identity() -> Self;
    fn verify_contraction(&self, bound: &RatInterval) -> bool;
}

/// Deterministic witness for Kani bounded model checking.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Witness {
    pub term_hash: String,
    pub interval: RatInterval,
    pub dimension: usize,
    pub verified: bool,
}

/// Telemetry binding for audit trail.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Telemetry {
    pub timestamp: String,
    pub witness: Witness,
    pub governor: String,
    pub contract_id: String,
}

impl Telemetry {
    pub fn new(witness: Witness, governor: String, contract_id: String) -> Self {
        Self {
            timestamp: timestamp_now(),
            witness,
            governor,
            contract_id,
        }
    }

    pub fn anchor(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.serialize().as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn serialize(&self) -> String {
        serde_json::to_string(self).unwrap_or_default()
    }
}

fn timestamp_now() -> String {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rat_interval_add() {
        let a = RatInterval::new(BigInt::from(1), BigInt::from(3), BigInt::from(2));
        let b = RatInterval::new(BigInt::from(2), BigInt::from(4), BigInt::from(3));
        let result = a.add(&b);
        assert_eq!(result.lower, BigInt::from(7));
        assert_eq!(result.upper, BigInt::from(17));
    }

    #[test]
    fn test_term_depth() {
        let op = OpSymbol {
            name: "test_op".to_string(),
            arity: 2,
            lip_bound: RatInterval::singleton(BigInt::from(1), BigInt::from(1)),
        };
        let t = Term::App {
            op,
            args: vec![Term::Var {
                name: "x".to_string(),
            }],
        };
        assert_eq!(t.depth(), 1);
    }

    #[test]
    fn test_endomorphism_contractive() {
        let e = Endomorphism::identity();
        assert!(e.is_contractive());
    }
}
