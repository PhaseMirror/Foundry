use serde::{Deserialize, Serialize};

/// Truth values for Priest's Logic of Paradox (LP).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum LpTruth {
    True,   // 1
    False,  // 0
    Both,   // 1/2 (Dialetheia)
}

impl LpTruth {
    /// Designated values are those considered "acceptable" for validity.
    /// In LP, both True and Both are designated.
    pub fn is_designated(&self) -> bool {
        match self {
            LpTruth::True | LpTruth::Both => true,
            LpTruth::False => false,
        }
    }

    /// Negation in LP: ¬T = F, ¬F = T, ¬B = B
    pub fn not(&self) -> Self {
        match self {
            LpTruth::True => LpTruth::False,
            LpTruth::False => LpTruth::True,
            LpTruth::Both => LpTruth::Both,
        }
    }

    /// Conjunction in LP (MIN)
    pub fn and(&self, other: &Self) -> Self {
        use LpTruth::*;
        match (self, other) {
            (False, _) | (_, False) => False,
            (Both, Both) | (Both, True) | (True, Both) => Both,
            (True, True) => True,
        }
    }

    /// Disjunction in LP (MAX)
    pub fn or(&self, other: &Self) -> Self {
        use LpTruth::*;
        match (self, other) {
            (True, _) | (_, True) => True,
            (Both, Both) | (Both, False) | (False, Both) => Both,
            (False, False) => False,
        }
    }
}

/// A Dialetheic Filter wraps an operation and traps explosive contradictions,
/// rendering them as `Both` instead of panicking or failing to resolve.
pub struct DialetheicFilter;

impl DialetheicFilter {
    pub fn evaluate<F>(f: F) -> LpTruth
    where
        F: FnOnce() -> std::result::Result<bool, String>,
    {
        match f() {
            Ok(true) => LpTruth::True,
            Ok(false) => LpTruth::False,
            Err(_) => LpTruth::Both, // A localized paradox or glut
        }
    }
}
