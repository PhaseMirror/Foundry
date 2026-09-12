//! Fuzzy Logic Module: MV-Algebra, Product, and Gödel t-norms

pub struct FuzzyLogic;

impl FuzzyLogic {
    // 1. Standard Negation
    pub fn not(x: f64) -> f64 {
        (1.0 - x).clamp(0.0, 1.0)
    }

    // 2. MV-Algebra (Łukasiewicz)
    pub fn mv_and(x: f64, y: f64) -> f64 {
        (x + y - 1.0).max(0.0)
    }

    pub fn mv_or(x: f64, y: f64) -> f64 {
        (x + y).min(1.0)
    }

    pub fn mv_implies(x: f64, y: f64) -> f64 {
        (1.0 - x + y).min(1.0)
    }

    // 3. Product Logic
    pub fn prod_and(x: f64, y: f64) -> f64 {
        (x * y).clamp(0.0, 1.0)
    }

    pub fn prod_or(x: f64, y: f64) -> f64 {
        (x + y - x * y).clamp(0.0, 1.0)
    }

    // 4. Gödel Logic
    pub fn godel_and(x: f64, y: f64) -> f64 {
        x.min(y)
    }

    pub fn godel_or(x: f64, y: f64) -> f64 {
        x.max(y)
    }

    pub fn godel_implies(x: f64, y: f64) -> f64 {
        if x <= y {
            1.0
        } else {
            y
        }
    }
}
