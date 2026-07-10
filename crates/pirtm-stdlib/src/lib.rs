/// PIRTM Standard Library (MOC Primitives)
/// Provides the foundational operators for PhaseSpace governed execution.

pub mod prelude {
    pub use crate::moc::{Ap, EvalNF, Resonance, MOCWord};
}

pub mod moc {
    use std::fmt;

    /// Governed Operator Word structure
    #[derive(Debug, Clone, PartialEq)]
    pub enum MOCWord {
        Atom(u64),
        Composite(Box<MOCWord>, Box<MOCWord>),
        Successor(Box<MOCWord>),
        StratumBoundary(Box<MOCWord>),
    }

    /// Construct a fundamental Prime-Indexed Operator Ap(p)
    #[allow(non_snake_case)]
    pub fn Ap(prime: u64) -> MOCWord {
        MOCWord::Atom(prime)
    }

    impl std::ops::Add for MOCWord {
        type Output = Self;
        fn add(self, rhs: Self) -> Self::Output {
            MOCWord::Composite(Box::new(self), Box::new(rhs))
        }
    }

    impl fmt::Display for MOCWord {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            match self {
                MOCWord::Atom(p) => write!(f, "Ap({})", p),
                MOCWord::Composite(l, r) => write!(f, "({} + {})", l, r),
                MOCWord::Successor(inner) => write!(f, "succ({})", inner),
                MOCWord::StratumBoundary(inner) => write!(f, "boundary({})", inner),
            }
        }
    }

    /// Phase Mirror Norm Factor Evaluator (EvalNF)
    pub struct EvalNF;
    impl EvalNF {
        pub fn evaluate(word: &MOCWord) -> (f64, f64, f64, f64) {
            match word {
                MOCWord::Atom(p) => {
                    if *p == 1 {
                        (1.5, 0.9, 0.9, 0.9) // Unlawful Expansive
                    } else {
                        let pf = *p as f64;
                        (1.0 / pf, 1.0 + (pf * 0.1), 1.0 + (pf * 0.15), 1.0 + (pf * 0.2))
                    }
                }
                MOCWord::Composite(left, right) => {
                    let (c1, r1a, r2a, r3a) = Self::evaluate(left);
                    let (c2, r1b, r2b, r3b) = Self::evaluate(right);
                    (c1 + c2, r1a * r1b, r2a * r2b, r3a * r3b)
                }
                MOCWord::Successor(inner) => {
                    let (c, r1, r2, r3) = Self::evaluate(inner);
                    (c * 1.1, r1 * 1.05, r2 * 1.05, r3 * 1.05)
                }
                MOCWord::StratumBoundary(inner) => {
                    let (c, r1, r2, r3) = Self::evaluate(inner);
                    (c * 0.5, r1 * 1.2, r2 * 1.2, r3 * 1.2)
                }
            }
        }
    }

    /// System Resonance derived from MOC operations
    pub struct Resonance;
    impl Resonance {
        pub fn calculate(r1: f64, r2: f64, r3: f64) -> f64 {
            (r1 * r2 * r3).powf(1.0 / 3.0)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::prelude::*;

    #[test]
    fn test_core_word_aggregation() {
        let word = Ap(2) + Ap(3);
        let (c, r1, r2, r3) = EvalNF::evaluate(&word);
        let rsc = Resonance::calculate(r1, r2, r3);
        
        assert_eq!(word.to_string(), "(Ap(2) + Ap(3))");
        assert!(c < 1.0 - 1e-6); // Lawful check
        assert!(rsc >= 1.0);     // Resonance tension satisfied
    }
}
