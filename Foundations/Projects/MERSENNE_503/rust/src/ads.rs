//! AdS (anti-de Sitter) geometric structures.
//!
//! Implements AdS_{d+1} coordinates, bulk points, and boundary
//! embeddings with verified geometric invariants.

use crate::error::Error;

/// AdS coordinate representation.
///
/// AdS_{d+1} is embedded in ℝ^{2,d} with metric
/// ds² = -(dt)² + dr² + r² dΩ² + ...
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AdSCoord {
    /// Time coordinate t.
    pub t: i64,
    /// Radial coordinate r.
    pub r: i64,
    /// Angular coordinates (simplified).
    pub theta: i64,
}

impl AdSCoord {
    /// Create a new AdS coordinate.
    pub fn new(t: i64, r: i64, theta: i64) -> Self {
        Self { t, r, theta }
    }

    /// Compute the AdS interval (simplified: -t² + r²).
    pub fn interval(&self) -> i64 {
        -self.t * self.t + self.r * self.r
    }

    /// Check if point is in the AdS bulk (interval < 0 for timelike).
    pub fn is_bulk(&self) -> bool {
        self.interval() < 0
    }

    /// Check if point is on the boundary (interval = 0).
    pub fn is_boundary(&self) -> bool {
        self.interval() == 0
    }

    /// Compute geodesic distance to another point (simplified).
    pub fn geodesic_distance(&self, other: &Self) -> f64 {
        let dt = (self.t - other.t) as f64;
        let dr = (self.r - other.r) as f64;
        let dt2 = dt * dt;
        let dr2 = dr * dr;
        let interval = -dt2 + dr2;
        if interval <= 0.0 {
            return f64::INFINITY;
        }
        interval.sqrt()
    }
}

/// Bulk point in AdS with additional field data.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BulkPoint {
    coord: AdSCoord,
    field_value: i64,
}

impl BulkPoint {
    /// Create a new bulk point.
    pub fn new(coord: AdSCoord, field_value: i64) -> Self {
        Self { coord, field_value }
    }

    /// Get the AdS coordinate.
    pub fn coord(&self) -> &AdSCoord {
        &self.coord
    }

    /// Get the field value.
    pub fn field_value(&self) -> i64 {
        self.field_value
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ads_interval() {
        let coord = AdSCoord::new(3, 5, 0);
        assert_eq!(coord.interval(), -9 + 25);
    }

    #[test]
    fn test_ads_bulk() {
        let coord = AdSCoord::new(3, 2, 0);
        assert!(coord.is_bulk());
    }

    #[test]
    fn test_ads_boundary() {
        let coord = AdSCoord::new(3, 3, 0);
        assert!(coord.is_boundary());
    }

    #[test]
    fn test_geodesic_distance() {
        let p1 = AdSCoord::new(0, 0, 0);
        let p2 = AdSCoord::new(0, 5, 0);
        assert_eq!(p1.geodesic_distance(&p2), 5.0);
    }
}
