use super::Nat;

/// 2‑D point with Nat coordinates (for demonstration).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Point {
    pub x: Nat,
    pub y: Nat,
}

impl Point {
    /// Squared Euclidean distance using Nat arithmetic.
    pub fn sq_dist(self, other: Point) -> Nat {
        // Compute absolute difference for each coordinate.
        let dx = if self.x.0 >= other.x.0 {
            Nat(self.x.0 - other.x.0)
        } else {
            Nat(other.x.0 - self.x.0)
        };
        let dy = if self.y.0 >= other.y.0 {
            Nat(self.y.0 - other.y.0)
        } else {
            Nat(other.y.0 - self.y.0)
        };
        // (dx*dx) + (dy*dy)
        let dx2 = super::mul(dx, dx);
        let dy2 = super::mul(dy, dy);
        super::add(dx2, dy2)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use kani::proof;

    #[proof]
    fn sq_dist_nonneg() {
        let p = Point { x: Nat(kani::any()), y: Nat(kani::any()) };
        let q = Point { x: Nat(kani::any()), y: Nat(kani::any()) };
        let d = p.sq_dist(q);
        // Nat is always non‑negative; trivially holds.
        assert!(d.0 >= 0);
    }
    // Triangle inequality can be added later.
}

