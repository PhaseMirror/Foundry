//! Ξ (Xi) Compiler Core Library
//!
//! This crate provides the foundational abstract syntax tree (AST), type system,
//! and type-checking mechanisms for the Ξ-Compiler as defined in ADR-070.
//! It translates high-level multiplicity-theoretic constructs into executable code
//! safely and reliably.

#![forbid(unsafe_code)]
#![deny(clippy::all, missing_docs)]

use serde::{Deserialize, Serialize};

/// Represents the types available in the Ξ language.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum XiType {
    /// A prime-indexed type, parameterised by a prime number.
    Prime(u64),
    /// A multiplicity type, reflecting multiplicity counts.
    Multiplicity(u64),
    /// A contraction bound type, mapping directly to spectral contraction limits.
    Contraction(f64),
    /// A multi-dimensional tensor type.
    Tensor(Vec<usize>),
}

/// Represents the Abstract Syntax Tree (AST) nodes of the Ξ language.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum XiExpr {
    /// A constant integer value.
    Const(i64),
    /// A literal representing a prime number.
    PrimeLit(u64),
    /// A literal representing a multiplicity integer.
    MultiplicityLit(u64),
    /// Addition of two Ξ expressions.
    Add(Box<XiExpr>, Box<XiExpr>),
    /// A bounded contraction operation applied to an expression.
    Contract(Box<XiExpr>, f64),
}

/// Errors that can occur during the type-checking phase.
#[derive(Debug, thiserror::Error)]
pub enum TypeError {
    /// Indicates that an expression's type did not match the expected type.
    #[error("type mismatch: expected {expected:?}, got {actual:?}")]
    TypeMismatch { 
        /// The type that was expected.
        expected: XiType, 
        /// The type that was actually provided.
        actual: XiType 
    },
    /// Indicates that a value expected to be prime is not a valid prime number.
    #[error("not a prime: {0}")]
    NotPrime(u64),
}

/// Helper function to mathematically verify if a `u64` is prime.
fn is_prime(n: u64) -> bool {
    if n <= 1 {
        return false;
    }
    for i in 2..=(n as f64).sqrt() as u64 {
        if n.is_multiple_of(i) {
            return false;
        }
    }
    true
}

/// Evaluates a `XiExpr` within a given context and infers or validates its `XiType`.
/// 
/// Returns `Ok(XiType)` if the expression is well-typed, or a `TypeError` if a
/// type mismatch or invalid structural invariant (like a composite number passed
/// to a prime literal) is detected.
#[allow(clippy::only_used_in_recursion)]
pub fn type_check(
    ctx: &[(String, XiType)],
    expr: &XiExpr,
) -> Result<XiType, TypeError> {
    match expr {
        XiExpr::Const(_) => Ok(XiType::Contraction(1.0)),
        XiExpr::PrimeLit(p) => {
            if !is_prime(*p) {
                return Err(TypeError::NotPrime(*p));
            }
            Ok(XiType::Prime(*p))
        }
        XiExpr::MultiplicityLit(n) => Ok(XiType::Multiplicity(*n)),
        XiExpr::Add(e1, e2) => {
            let t1 = type_check(ctx, e1)?;
            let t2 = type_check(ctx, e2)?;
            if t1 == t2 {
                Ok(t1)
            } else {
                Err(TypeError::TypeMismatch {
                    expected: t1,
                    actual: t2,
                })
            }
        }
        XiExpr::Contract(e, b) => {
            type_check(ctx, e)?;
            Ok(XiType::Contraction(*b))
        }
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_type_check_sound() {
        let expr = XiExpr::Const(42);
        let ctx = vec![];
        let ty = type_check(&ctx, &expr).unwrap();
        if let XiType::Contraction(b) = ty {
            kani::assert(b == 1.0, "Const should have Contraction(1.0) type");
        } else {
            kani::assert(false, "Const should have Contraction type");
        }
    }
}
