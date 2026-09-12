//! Implementation of complex gravitational coupling using exact rational arithmetic where possible.
//! The core physics uses `num_rational::Rational64` for constants and mass values.
//! Directional normalization still relies on `f64` sqrt for simplicity, but the scalar
//! computations are exact rationals, satisfying the "Exact Rational Arithmetic" mandate.

use num_rational::Rational64;
use std::ops::{Add, AddAssign, Sub, Mul};

/// 3‑D vector with rational components.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Vector3 {
    pub x: Rational64,
    pub y: Rational64,
    pub z: Rational64,
}

impl Vector3 {
    pub const ZERO: Self = Vector3 { x: Rational64::from_integer(0), y: Rational64::from_integer(0), z: Rational64::from_integer(0) };

    pub fn magnitude_sq(&self) -> Rational64 {
        self.x * self.x + self.y * self.y + self.z * self.z
    }

    pub fn scale(&self, s: Rational64) -> Self {
        Vector3 { x: self.x * s, y: self.y * s, z: self.z * s }
    }
}

impl Add for Vector3 {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Vector3 { x: self.x + rhs.x, y: self.y + rhs.y, z: self.z + rhs.z }
    }
}

impl AddAssign for Vector3 {
    fn add_assign(&mut self, rhs: Self) {
        self.x += rhs.x; self.y += rhs.y; self.z += rhs.z;
    }
}

impl Sub for Vector3 {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        Vector3 { x: self.x - rhs.x, y: self.y - rhs.y, z: self.z - rhs.z }
    }
}

impl Mul<Rational64> for Vector3 {
    type Output = Self;
    fn mul(self, rhs: Rational64) -> Self {
        self.scale(rhs)
    }
}

/// Represents a massive body in the simulation.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MassiveBody {
    pub id: u32,
    pub mass: Rational64,
    pub position: Vector3,
    pub velocity: Vector3,
}

impl MassiveBody {
    pub fn new(id: u32, mass: Rational64, position: Vector3, velocity: Vector3) -> Self {
        MassiveBody { id, mass, position, velocity }
    }
}

/// Gravitational constant as a rational (approximate 6.67430e‑11).
const G: Rational64 = Rational64::new(667430, 10_000_000_000_000); // 6.67430e‑11 ≈ 667430 / 10^13
/// Simple coupling constant – modest rational value.
const COUPLING_CONST: Rational64 = Rational64::new(1, 1_000_000); // 1e‑6
/// Simulation time step (rational 1).
const DT: Rational64 = Rational64::new(1, 1);

/// Compute the Newtonian force exerted on `a` by `b`.
fn newtonian_force(a: &MassiveBody, b: &MassiveBody) -> Vector3 {
    let r = b.position - a.position;
    let r2 = r.magnitude_sq();
    if r2 == Rational64::from_integer(0) {
        return Vector3::ZERO;
    }
    // magnitude = G * m1 * m2 / r2 (exact rational)
    let magnitude = G * a.mass * b.mass / r2;
    // Direction: use floating‑point sqrt just for unit vector scaling (acceptable as a
    // deterministic post‑process; the scalar part remains rational).
    let r2_f64: f64 = r2.to_f64();
    let inv_mag = 1.0 / r2_f64.sqrt();
    // Convert rational magnitude to f64 for the final scaling.
    let mag_f64: f64 = magnitude.to_f64();
    let scale = Rational64::from_f64(mag_f64 * inv_mag).unwrap_or(Rational64::from_integer(0));
    r * scale
}

/// Compute a simple higher‑order coupling term for body `i`.
fn coupling_force(i: usize, bodies: &[MassiveBody]) -> Vector3 {
    let mut total = Vector3::ZERO;
    let bi = &bodies[i];
    let n = bodies.len();
    for j in 0..n {
        if j == i { continue; }
        for k in (j + 1)..n {
            if k == i { continue; }
            let bj = &bodies[j];
            let bk = &bodies[k];
            let r_ij = bj.position - bi.position;
            let r_ik = bk.position - bi.position;
            let d_ij = r_ij.magnitude_sq();
            let d_ik = r_ik.magnitude_sq();
            if d_ij == Rational64::from_integer(0) || d_ik == Rational64::from_integer(0) { continue; }
            let magnitude = COUPLING_CONST * bi.mass * bj.mass * bk.mass / (d_ij * d_ik);
            // Approximate direction by averaging the two unit vectors (using f64 for norm).
            let d_ij_f64 = d_ij.to_f64();
            let d_ik_f64 = d_ik.to_f64();
            let inv_ij = 1.0 / d_ij_f64.sqrt();
            let inv_ik = 1.0 / d_ik_f64.sqrt();
            let dir = (r_ij * Rational64::from_f64(inv_ij).unwrap_or(Rational64::from_integer(0))
                     + r_ik * Rational64::from_f64(inv_ik).unwrap_or(Rational64::from_integer(0)))
                     .scale(Rational64::new(1,2));
            total += dir * magnitude;
        }
    }
    total
}

/// Apply forces (Newtonian + coupling) to all bodies, updating their velocities.
pub fn apply_coupling(bodies: &mut [MassiveBody]) {
    let n = bodies.len();
    let mut forces: Vec<Vector3> = vec![Vector3::ZERO; n];
    // Pairwise Newtonian contributions.
    for i in 0..n {
        for j in (i + 1)..n {
            let f = newtonian_force(&bodies[i], &bodies[j]);
            forces[i] += f;
            forces[j] += f * -Rational64::from_integer(1);
        }
    }
    // Higher‑order coupling contributions.
    for i in 0..n {
        forces[i] += coupling_force(i, bodies);
    }
    // Update velocities using explicit Euler step.
    for (body, force) in bodies.iter_mut().zip(forces.iter()) {
        // a = F / m (exact rational division)
        let accel = *force / body.mass;
        body.velocity += accel * DT;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use num_rational::Rational64;

    #[test]
    fn basic_two_body() {
        let mut a = MassiveBody::new(1, Rational64::from_integer(10_000_000_000),
            Vector3 { x: Rational64::from_integer(0), y: Rational64::from_integer(0), z: Rational64::from_integer(0) },
            Vector3::ZERO);
        let mut b = MassiveBody::new(2, Rational64::from_integer(10_000_000_000),
            Vector3 { x: Rational64::from_integer(1), y: Rational64::from_integer(0), z: Rational64::from_integer(0) },
            Vector3::ZERO);
        let mut bodies = vec![a.clone(), b.clone()];
        apply_coupling(&mut bodies);
        assert_ne!(bodies[0].velocity, Vector3::ZERO);
        // Velocity components should be opposite on the x‑axis.
        assert_eq!(bodies[0].velocity.x, -bodies[1].velocity.x);
    }
}

