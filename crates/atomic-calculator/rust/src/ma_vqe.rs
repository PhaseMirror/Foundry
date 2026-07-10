//! Multiplicity-Adaptive Variational Quantum Eigensolver (MA-VQE)
//!
//! Modeled as a SnapKitty Quantum Superposition Monad.

/// The QuantumM Monad enforces the "no-cloning" corollary and prunes the search space.
pub enum QuantumM<T> {
    Pure(T),
    Superpose(Vec<(u64, T)>),
    Collapse(T),
}

impl<T: Clone> QuantumM<T> {
    /// The monadic bind operator that natively destroys failed or unphysical branches.
    pub fn bind<U, F>(self, f: F, fallback: U) -> QuantumM<U>
    where
        F: Fn(T) -> QuantumM<U>,
        U: Clone,
    {
        match self {
            QuantumM::Pure(a) => f(a),
            QuantumM::Superpose(bs) => {
                let mut new_bs = Vec::new();
                for (weight, branch) in bs {
                    match f(branch) {
                        QuantumM::Pure(b) | QuantumM::Collapse(b) => {
                            new_bs.push((weight, b));
                        }
                        QuantumM::Superpose(_) => {
                            // Unphysical branch discarded (pruning)
                        }
                    }
                }
                if new_bs.is_empty() {
                    QuantumM::Collapse(fallback)
                } else {
                    QuantumM::Superpose(new_bs)
                }
            }
            QuantumM::Collapse(a) => match f(a) {
                QuantumM::Pure(b) | QuantumM::Collapse(b) => QuantumM::Collapse(b),
                QuantumM::Superpose(_) => QuantumM::Collapse(fallback),
            },
        }
    }
}
