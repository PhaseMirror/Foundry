use ndarray::Array1;
use std::collections::{HashMap, HashSet};
use crate::l1proj::Rational;
use num_traits::{Zero, Signed};

#[derive(Debug, Clone)]
pub struct ProjectorFamily {
    pub name: String,
    pub indexsets: Vec<Vec<usize>>,
    pub dim: usize,
}

impl ProjectorFamily {
    pub fn new(indexsets: Vec<Vec<usize>>, name: String) -> Self {
        let mut all_indices = HashSet::new();
        for set in &indexsets {
            for &idx in set {
                if !all_indices.insert(idx) {
                    panic!("Index sets for {} are not disjoint", name);
                }
            }
        }
        let dim = all_indices.len();
        ProjectorFamily { name, indexsets, dim }
    }

    pub fn block_indices(&self, block_id: usize) -> &[usize] {
        &self.indexsets[block_id]
    }

    pub fn project(&self, x: &Array1<Rational>, block_id: usize) -> Array1<Rational> {
        let indices = &self.indexsets[block_id];
        let mut result = Array1::zeros(indices.len());
        for (i, &idx) in indices.iter().enumerate() {
            result[i] = x[idx];
        }
        result
    }

    pub fn embed(&self, coeffs: &Array1<Rational>, block_id: usize, ambient_dim: usize) -> Array1<Rational> {
        let mut result = Array1::zeros(ambient_dim);
        let indices = &self.indexsets[block_id];
        for (i, &idx) in indices.iter().enumerate() {
            result[idx] = coeffs[i];
        }
        result
    }
}

#[derive(Debug, Clone)]
pub struct PiIndexGrid {
    pub families: Vec<ProjectorFamily>,
    pub dim: usize,
    pub map: HashMap<Vec<usize>, Vec<usize>>,
    pub pi_ids: Vec<Vec<usize>>,
}

impl PiIndexGrid {
    pub fn new(families: Vec<ProjectorFamily>) -> Result<Self, String> {
        if families.is_empty() {
            return Err("Families cannot be empty".to_string());
        }
        let dim = families[0].dim;
        if !families.iter().all(|f| f.dim == dim) {
            return Err("All families must have same ambient dimension".to_string());
        }

        let mut map = HashMap::new();
        let mut pi_ids = Vec::new();

        Self::build_atoms(&families, 0, &mut Vec::new(), &mut map, &mut pi_ids);

        Ok(PiIndexGrid { families, dim, map, pi_ids })
    }

    fn build_atoms(
        families: &[ProjectorFamily],
        depth: usize,
        current_pi: &mut Vec<usize>,
        map: &mut HashMap<Vec<usize>, Vec<usize>>,
        pi_ids: &mut Vec<Vec<usize>>,
    ) {
        if depth == families.len() {
            let mut intersection: Option<HashSet<usize>> = None;
            for (i, &block_id) in current_pi.iter().enumerate() {
                let set: HashSet<usize> = families[i].indexsets[block_id].iter().cloned().collect();
                intersection = match intersection {
                    None => Some(set),
                    Some(s) => Some(s.intersection(&set).cloned().collect()),
                };
            }

            if let Some(set) = intersection {
                if !set.is_empty() {
                    let mut indices: Vec<usize> = set.into_iter().collect();
                    indices.sort_unstable();
                    map.insert(current_pi.clone(), indices);
                    pi_ids.push(current_pi.clone());
                }
            }
            return;
        }

        for i in 0..families[depth].indexsets.len() {
            current_pi.push(i);
            Self::build_atoms(families, depth + 1, current_pi, map, pi_ids);
            current_pi.pop();
        }
    }

    pub fn indices(&self, pi_id: &[usize]) -> Option<&[usize]> {
        self.map.get(pi_id).map(|v| v.as_slice())
    }

    pub fn recomposition_error(&self, x: &Array1<Rational>) -> Rational {
        let mut reconstruction: Array1<Rational> = Array1::zeros(self.dim);
        for pi_id in &self.pi_ids {
            if let Some(indices) = self.indices(pi_id) {
                for &idx in indices {
                    reconstruction[idx] = reconstruction[idx] + x[idx];
                }
            }
        }

        let mut error = Rational::zero();
        for i in 0..self.dim {
            let diff: Rational = x[i] - reconstruction[i];
            error = error + diff.abs();
        }
        error
    }
}
