use pyo3::prelude::*;
use mqnn_kani::CandidateState;

const DELTA_THRESHOLD_0_05: u32 = 3000; // Scaled deterministic bounding limit

#[pyclass]
#[derive(Clone)]
pub struct PyCandidateState {
    inner: CandidateState,
}

#[pymethods]
impl PyCandidateState {
    #[new]
    fn new(zeros: u32, shots: u32) -> Self {
        PyCandidateState { inner: CandidateState { zeros, shots } }
    }

    #[getter]
    fn zeros(&self) -> u32 { self.inner.zeros }
    
    #[getter]
    fn shots(&self) -> u32 { self.inner.shots }

    fn __repr__(&self) -> String {
        format!("CandidateState(zeros={}, shots={})", self.inner.zeros, self.inner.shots)
    }
}

#[pyfunction]
fn is_better_certified(delta: f64, j: &PyCandidateState, k: &PyCandidateState) -> bool {
    let _ = delta; 
    j.inner.is_better_certified_than(&k.inner, DELTA_THRESHOLD_0_05)
}

#[pyfunction]
fn mqnn_policy(states: Vec<PyCandidateState>) -> usize {
    let inner_states: Vec<CandidateState> = states.into_iter().map(|s| s.inner).collect();
    mqnn_kani::mqnnPolicy(&inner_states)
}

#[pymodule]
fn mqnn_ffi(_py: Python, m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_class::<PyCandidateState>()?;
    m.add_function(wrap_pyfunction!(is_better_certified, m)?)?;
    m.add_function(wrap_pyfunction!(mqnn_policy, m)?)?;
    Ok(())
}
