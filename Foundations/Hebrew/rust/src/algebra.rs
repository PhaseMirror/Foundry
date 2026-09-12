use super::Nat;

/// A trivial ring structure over Nat, mirroring the Lean definition.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Ring {
    pub zero: Nat,
    pub one: Nat,
}

impl Ring {
    pub const fn new() -> Self {
        Self { zero: Nat::ZERO, one: Nat(Nat::ZERO.0 + 1) }
    }

    #[inline]
    pub fn add(&self, a: Nat, b: Nat) -> Nat {
        // Nat addition uses the wrapper's `add` function.
        super::add(a, b)
    }

    #[inline]
    pub fn mul(&self, a: Nat, b: Nat) -> Nat {
        super::mul(a, b)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use kani::proof;

    #[proof]
    fn ring_add_comm() {
        let a = Nat(kani::any());
        let b = Nat(kani::any());
        let r = Ring::new();
        assert_eq!(r.add(a, b), r.add(b, a));
    }
    // Additional ring axioms can be added similarly.
}
