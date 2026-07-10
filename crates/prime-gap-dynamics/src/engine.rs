use ndarray::{Array1, Array2};
use num_complex::Complex64;
use crate::simulator::Hamiltonian;

pub struct SimulationEngine {
    pub hamiltonian: Hamiltonian,
    pub dt: f64,
}

impl SimulationEngine {
    pub fn new(hamiltonian: Hamiltonian, dt: f64) -> Self {
        SimulationEngine { hamiltonian, dt }
    }

    /// Performs one step of time evolution using a simple Runge-Kutta 4 (RK4) method
    /// d|psi>/dt = -i H(t) |psi>
    pub fn step(&self, t: f64, psi: &Array1<Complex64>, zero_freqs: &[f64], gammas: &[f64], phases: &[f64]) -> Array1<Complex64> {
        let k1 = self.rhs(t, psi, zero_freqs, gammas, phases);
        let k2 = self.rhs(t + self.dt / 2.0, &(psi + &(&k1 * (self.dt / 2.0))), zero_freqs, gammas, phases);
        let k3 = self.rhs(t + self.dt / 2.0, &(psi + &(&k2 * (self.dt / 2.0))), zero_freqs, gammas, phases);
        let k4 = self.rhs(t + self.dt, &(psi + &(&k3 * self.dt)), zero_freqs, gammas, phases);

        psi + &((&k1 + &(&k2 * 2.0) + &(&k3 * 2.0) + &k4) * (self.dt / 6.0))
    }

    fn rhs(&self, t: f64, psi: &Array1<Complex64>, zero_freqs: &[f64], gammas: &[f64], phases: &[f64]) -> Array1<Complex64> {
        let h = self.hamiltonian.construct_h(t, zero_freqs, gammas, phases);
        // -i * H * psi
        let i = Complex64::new(0.0, 1.0);
        h.dot(psi) * (-i)
    }
}
