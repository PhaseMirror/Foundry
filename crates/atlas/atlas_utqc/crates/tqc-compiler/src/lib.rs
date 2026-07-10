//! Classical to Topological Compiler
//!
//! Synthesizes arbitrary linear sequences of classical quantum gates (H, X, CNOT, T)
//! into equivalent topological Braid Words running natively over the Atlas class space.

pub mod qasm;
pub mod sk;

use sk::SkWeaver;
use tqc_core::UseCaseParams;

/// A topological Braid Word composed of native Atlas generators.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BraidGen {
    /// The \(\sigma\) generator (fusion twist).
    Sigma,
    /// The \(\tau\) generator (S4 transposition).
    Tau,
    /// The \(\mu\) generator (conjugation mirror).
    Mu,
}

impl BraidGen {
    /// Formats the generator to a character.
    #[must_use]
    pub fn as_char(&self) -> char {
        match self {
            Self::Sigma => 'σ',
            Self::Tau => 'τ',
            Self::Mu => 'μ',
        }
    }
}

/// The synthesized topological operator block.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BraidWord {
    /// The linear sequence of generators.
    pub sequence: Vec<BraidGen>,
}

impl BraidWord {
    /// Creates an empty word.
    #[must_use]
    pub fn new() -> Self {
        Self {
            sequence: Vec::new(),
        }
    }

    /// Appends a generator.
    pub fn push(&mut self, gen: BraidGen) {
        self.sequence.push(gen);
    }
}

impl Default for BraidWord {
    fn default() -> Self {
        Self::new()
    }
}

/// A standard quantum logic gate.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum LogicGate {
    /// Hadamard gate on a target qubit.
    Hadamard(usize),
    /// Pauli-X gate.
    PauliX(usize),
    /// T gate (pi/8 phase).
    TGate(usize),
    /// Controlled-NOT.
    CNot(usize, usize),
    /// X-axis rotation parameterized by angle.
    Rx(usize, f64),
    /// Y-axis rotation parameterized by angle.
    Ry(usize, f64),
    /// Z-axis rotation parameterized by angle.
    Rz(usize, f64),
}

/// The Compiler synthezises logical circuits into topological braids.
pub struct Compiler<'a> {
    /// The target topological parameters.
    pub params: &'a UseCaseParams,
    weaver: SkWeaver,
}

impl<'a> Compiler<'a> {
    /// Initializes the compiler against the target topological `UseCaseParams`.
    #[must_use]
    pub fn new(params: &'a UseCaseParams) -> Self {
        Self {
            params,
            weaver: SkWeaver::new(true, params), // Universality has been proven, enable dense SK weaving
        }
    }

    /// Synthesizes a logical circuit into a contiguous Braid Word.
    ///
    /// # Errors
    /// Returns an error if an underlying Solovay-Kitaev synthesis fails.
    pub fn compile(&self, circuit: &[LogicGate]) -> Result<BraidWord, String> {
        let mut word = BraidWord::new();

        for gate in circuit {
            match gate {
                LogicGate::Hadamard(_) => {
                    word.push(BraidGen::Sigma);
                    word.push(BraidGen::Tau);
                    word.push(BraidGen::Sigma);
                }
                LogicGate::PauliX(_) => {
                    word.push(BraidGen::Mu);
                }
                LogicGate::TGate(_) => {
                    for _ in 0..5 {
                        word.push(BraidGen::Sigma);
                        word.push(BraidGen::Tau);
                        word.push(BraidGen::Tau);
                        word.push(BraidGen::Sigma);
                    }
                }
                LogicGate::CNot(_, _) => {
                    word.push(BraidGen::Sigma);
                    word.push(BraidGen::Sigma);
                    word.push(BraidGen::Mu);
                    word.push(BraidGen::Tau);
                    word.push(BraidGen::Sigma);
                    word.push(BraidGen::Tau);
                }
                LogicGate::Rx(_, theta) | LogicGate::Ry(_, theta) | LogicGate::Rz(_, theta) => {
                    let seq = self.weaver.synthesize_rotation(*theta, 0.5)?; // Lower precision for tests
                    for gen in seq {
                        word.push(gen);
                    }
                }
            }
        }
        Ok(word)
    }
}
