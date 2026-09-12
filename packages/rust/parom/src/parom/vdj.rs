use nalgebra::{DMatrix, DVector};
use crate::{Parom, ParomConfig};
use std::sync::Arc;

pub type VSegment = Arc<dyn Fn(&DVector<f64>) -> DVector<f64> + Send + Sync>;
pub type DSegment = DMatrix<f64>; // Mixing kernel
pub type JSegment = Arc<dyn Fn(&DVector<f64>) -> DVector<f64> + Send + Sync>; // Activation

pub struct Recombinant {
    pub id: String,
    pub parom: Parom,
}

pub struct VDJEngine {
    pub v_library: Vec<VSegment>,
    pub d_library: Vec<DSegment>,
    pub j_library: Vec<JSegment>,
}

impl VDJEngine {
    pub fn new(dim: usize) -> Self {
        // Initialize with standard stubs
        let v_library: Vec<VSegment> = vec![
            Arc::new(|x: &DVector<f64>| x.clone()),
            Arc::new(|x: &DVector<f64>| x.map(|v| v * 1.1)),
        ];
        
        let d_library = vec![
            DMatrix::identity(dim, dim),
            DMatrix::from_diagonal(&DVector::from_element(dim, 0.9)),
        ];
        
        let j_library: Vec<JSegment> = vec![
            Arc::new(|x: &DVector<f64>| x.map(|v| v.tanh())),
            Arc::new(|x: &DVector<f64>| x.map(|v| v.sin())),
        ];

        Self { v_library, d_library, j_library }
    }

    /// Combinatorial Assembly of a new Parom Basis.
    pub fn recombine(&self, v_idx: usize, d_idx: usize, j_idx: usize, config: ParomConfig) -> Recombinant {
        let _v = self.v_library[v_idx].clone();
        let d = self.d_library[d_idx].clone();
        let j = self.j_library[j_idx].clone();
        
        // Assemble into a Parom instance
        let t_op = Box::new(move |x: &DVector<f64>| j(x));
        let mut parom = Parom::new(config, t_op);
        
        // Inject the D-segment (Mixing kernel) into the operator
        parom = parom.with_operator(d);
        
        Recombinant {
            id: format!("V{}-D{}-J{}", v_idx, d_idx, j_idx),
            parom,
        }
    }

    /// Express a repertoire of diverse recombinants.
    pub fn express_repertoire(&self, config: ParomConfig) -> Vec<Recombinant> {
        let mut repertoire = Vec::new();
        for v in 0..self.v_library.len() {
            for d in 0..self.d_library.len() {
                for j in 0..self.j_library.len() {
                    let rec = self.recombine(v, d, j, config.clone());
                    // Negative Selection: Only express if stable
                    if rec.parom.verify_stability(100) {
                        println!("Expressing Recombinant: {}", rec.id);
                        repertoire.push(rec);
                    } else {
                        println!("Discarding Recombinant (Self-Reactive): {}", rec.id);
                    }
                }
            }
        }
        repertoire
    }
}
