/// FFI (Foreign Function Interface) layer for Python ↔ Rust interoperability
///
/// Exposes Track B functionality to Python Track A via PyO3 bindings.
/// Provides unified interface for proof generation and verification.

use crate::types::{ThetaBase, ThetaC6, StepInfo, WacMode};
use pyo3::prelude::*;
use pyo3::types::PyBytes;

/// Python-compatible ThetaBase wrapper
#[pyclass]
pub struct PyThetaBase {
    inner: ThetaBase,
}

#[pymethods]
impl PyThetaBase {
    #[new]
    #[pyo3(signature = (epsilon, supp_epsilon, delta, n_0, k, m, beta, tau_min, alpha_m, retry_nonce=0, wac_mode="windowed"))]
    pub fn new(
        epsilon: f64,
        supp_epsilon: f64,
        delta: f64,
        n_0: i32,
        k: i32,
        m: i32,
        beta: f64,
        tau_min: f64,
        alpha_m: f64,
        retry_nonce: i32,
        wac_mode: &str,
    ) -> PyResult<Self> {
        let mode = match wac_mode.to_lowercase().as_str() {
            "strict" => WacMode::Strict,
            "windowed" => WacMode::Windowed,
            _ => return Err(PyErr::new::<pyo3::exceptions::PyValueError, _>(
                format!("Invalid wac_mode: {}", wac_mode)
            )),
        };

        let theta = ThetaBase::new(
            epsilon,
            supp_epsilon,
            delta,
            n_0,
            k,
            m,
            beta,
            tau_min,
            alpha_m,
            retry_nonce,
            mode,
        )
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e))?;

        Ok(PyThetaBase { inner: theta })
    }

    #[getter]
    fn epsilon(&self) -> f64 {
        self.inner.epsilon
    }

    #[getter]
    fn supp_epsilon(&self) -> f64 {
        self.inner.supp_epsilon
    }

    #[getter]
    fn delta(&self) -> f64 {
        self.inner.delta
    }

    #[getter]
    fn n_0(&self) -> i32 {
        self.inner.n_0
    }

    #[getter]
    fn k(&self) -> i32 {
        self.inner.k
    }

    #[getter]
    fn m(&self) -> i32 {
        self.inner.m
    }

    #[getter]
    fn beta(&self) -> f64 {
        self.inner.beta
    }

    #[getter]
    fn tau_min(&self) -> f64 {
        self.inner.tau_min
    }

    #[getter]
    fn alpha_m(&self) -> f64 {
        self.inner.alpha_m
    }

    #[getter]
    fn retry_nonce(&self) -> i32 {
        self.inner.retry_nonce
    }

    #[getter]
    fn wac_mode(&self) -> String {
        self.inner.wac_mode.to_string()
    }

    fn __repr__(&self) -> String {
        format!(
            "ThetaBase(epsilon={}, supp_epsilon={}, delta={}, n_0={}, k={}, m={}, beta={}, tau_min={}, alpha_m={}, retry_nonce={}, wac_mode={})",
            self.inner.epsilon,
            self.inner.supp_epsilon,
            self.inner.delta,
            self.inner.n_0,
            self.inner.k,
            self.inner.m,
            self.inner.beta,
            self.inner.tau_min,
            self.inner.alpha_m,
            self.inner.retry_nonce,
            self.inner.wac_mode
        )
    }
}

/// Python-compatible ThetaC6 wrapper
#[pyclass]
pub struct PyThetaC6 {
    inner: ThetaC6,
}

#[pymethods]
impl PyThetaC6 {
    #[new]
    pub fn new(py_base: &PyThetaBase, shuffle_seed: &[u8]) -> PyResult<Self> {
        let theta_c6 = ThetaC6::new(py_base.inner, shuffle_seed.to_vec());
        Ok(PyThetaC6 { inner: theta_c6 })
    }

    #[getter]
    fn base(&self, _py: Python) -> PyResult<PyThetaBase> {
        Ok(PyThetaBase {
            inner: self.inner.base,
        })
    }

    #[getter]
    fn shuffle_seed<'py>(&self, py: Python<'py>) -> PyResult<&'py PyBytes> {
        Ok(PyBytes::new(py, &self.inner.shuffle_seed))
    }

    fn __repr__(&self) -> String {
        format!(
            "ThetaC6(base=ThetaBase(...), shuffle_seed={})",
            hex::encode(&self.inner.shuffle_seed)
        )
    }
}

/// Python-compatible StepInfo wrapper
#[pyclass]
pub struct PyStepInfo {
    inner: StepInfo,
}

#[pymethods]
impl PyStepInfo {
    #[new]
    pub fn new(
        step: i32,
        q: f64,
        epsilon: f64,
        kkt_residual: f64,
        wac_product: f64,
        xi_telemetry: f64,
        delta_sigma: f64,
        delta_m: f64,
        projected: bool,
        residual: f64,
    ) -> PyResult<Self> {
        let info = StepInfo::new(
            step,
            q,
            epsilon,
            kkt_residual,
            wac_product,
            xi_telemetry,
            delta_sigma,
            delta_m,
            projected,
            residual,
        );
        Ok(PyStepInfo { inner: info })
    }

    #[getter]
    fn step(&self) -> i32 {
        self.inner.step
    }

    #[getter]
    fn q(&self) -> f64 {
        self.inner.q
    }

    #[getter]
    fn epsilon(&self) -> f64 {
        self.inner.epsilon
    }

    #[getter]
    fn kkt_residual(&self) -> f64 {
        self.inner.kkt_residual
    }

    #[getter]
    fn wac_product(&self) -> f64 {
        self.inner.wac_product
    }

    #[getter]
    fn xi_telemetry(&self) -> f64 {
        self.inner.xi_telemetry
    }

    #[getter]
    fn delta_sigma(&self) -> f64 {
        self.inner.delta_sigma
    }

    #[getter]
    fn delta_m(&self) -> f64 {
        self.inner.delta_m
    }

    #[getter]
    fn projected(&self) -> bool {
        self.inner.projected
    }

    #[getter]
    fn residual(&self) -> f64 {
        self.inner.residual
    }

    fn __repr__(&self) -> String {
        format!(
            "StepInfo(step={}, q={:.6}, epsilon={:.6}, kkt_residual={:.2e}, wac_product={:.6}, projected={}, residual={:.2e})",
            self.inner.step,
            self.inner.q,
            self.inner.epsilon,
            self.inner.kkt_residual,
            self.inner.wac_product,
            self.inner.projected,
            self.inner.residual
        )
    }
}

/// PyO3 module initialization
#[pymodule]
pub fn ace_zk(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_class::<PyThetaBase>()?;
    m.add_class::<PyThetaC6>()?;
    m.add_class::<PyStepInfo>()?;

    // Module docstring
    m.add("__doc__",
        "ACE-ZK: Rust/Circom backend for ACE Core v1.0\n\nProvides cryptographic proof generation (Groth16 primary, PLONK secondary)\nwith mathematical equivalence to Python Track A.")?;

    Ok(())
}
