pub const MAX_TERMS: usize = 32;
pub const MAX_QUBITS: usize = 4;

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Term {
    Var(u8),
    Comp(u8, u8),
    Close(u8),
}

impl Term {
    pub fn is_var(&self) -> bool {
        matches!(self, Term::Var(_))
    }
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Axis { X, Y, Z }

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum TwoQubitType { CNOT, CZ, SWAP }

#[derive(Clone, Debug)]
pub enum GateOperation {
    Identity,
    SingleQubitGate { qubit: u8, angle: f64, axis: Axis },
    TwoQubitGate { control: u8, target: u8, gate_type: TwoQubitType },
    // active counts how many qubits in the array are used
    RydbergPulse { qubits: [u8; MAX_QUBITS], active: u8, duration: f64, detuning: f64 },
}

impl Default for GateOperation {
    fn default() -> Self {
        GateOperation::Identity
    }
}

impl GateOperation {
    pub fn active_qubits(&self) -> Vec<u8> {
        match self {
            GateOperation::Identity => vec![],
            GateOperation::SingleQubitGate { qubit, .. } => vec![*qubit],
            GateOperation::TwoQubitGate { control, target, .. } => vec![*control, *target],
            GateOperation::RydbergPulse { qubits, active, .. } => {
                let mut v = Vec::new();
                for i in 0..*active as usize {
                    v.push(qubits[i]);
                }
                v
            }
        }
    }
}

#[derive(Clone, Debug)]
pub struct HardwareSpec {
    pub num_qubits: u8,
    pub qubit_positions: [[f64; 2]; MAX_QUBITS],
    pub rabi_frequency: [f64; MAX_QUBITS],
    pub detuning: [f64; MAX_QUBITS],
    pub blockade_radius: f64,
    pub blockade_interaction: [[f64; MAX_QUBITS]; MAX_QUBITS],
    pub allowed_transitions: [[bool; 2]; MAX_QUBITS],
    pub pulse_length_tolerance: f64,
    pub phase_tolerance: f64,
    pub leakage_rate: f64,
    pub decoherence_rate: f64,
}

impl Default for HardwareSpec {
    fn default() -> Self {
        Self {
            num_qubits: 0,
            qubit_positions: [[0.0; 2]; MAX_QUBITS],
            rabi_frequency: [0.0; MAX_QUBITS],
            detuning: [0.0; MAX_QUBITS],
            blockade_radius: 0.0,
            blockade_interaction: [[0.0; MAX_QUBITS]; MAX_QUBITS],
            allowed_transitions: [[true; 2]; MAX_QUBITS],
            pulse_length_tolerance: 0.1,
            phase_tolerance: 0.1,
            leakage_rate: 0.01,
            decoherence_rate: 100.0,
        }
    }
}

impl HardwareSpec {
    pub fn distance_between(&self, q1: u8, q2: u8) -> f64 {
        let p1 = self.qubit_positions[q1 as usize];
        let p2 = self.qubit_positions[q2 as usize];
        let dx = p1[0] - p2[0];
        let dy = p1[1] - p2[1];
        (dx * dx + dy * dy).sqrt()
    }

    pub fn is_blockaded(&self, q1: u8, q2: u8) -> bool {
        if self.blockade_radius <= 0.0 {
            return false;
        }
        self.distance_between(q1, q2) < self.blockade_radius
    }

    pub fn associator_defect(&self, ops1: &[GateOperation], ops2: &[GateOperation]) -> f64 {
        let mut total = 0.0;
        for op1 in ops1 {
            for op2 in ops2 {
                let q1 = op1.active_qubits();
                let q2 = op2.active_qubits();
                let mut interaction = 0.0;
                for &a in &q1 {
                    for &b in &q2 {
                        let dist = self.distance_between(a, b);
                        if dist > 0.0 {
                            interaction += self.blockade_interaction[a as usize][b as usize] / dist;
                        }
                    }
                }
                total += interaction.abs();
            }
        }
        total
    }
}

#[derive(Clone, Debug)]
pub struct PartialSystem {
    pub vars: u8,
    pub comp_def: [(u8, u8, Option<u8>); MAX_TERMS],
    pub close_def: [(u8, Option<u8>); MAX_TERMS],
    pub gate_terms: [GateOperation; MAX_TERMS],
    pub hardware: HardwareSpec,
}

impl Default for PartialSystem {
    fn default() -> Self {
        const DEFAULT_GATE: GateOperation = GateOperation::Identity;
        Self {
            vars: 0,
            comp_def: [(0, 0, None); MAX_TERMS],
            close_def: [(0, None); MAX_TERMS],
            gate_terms: [DEFAULT_GATE; MAX_TERMS],
            hardware: HardwareSpec::default(),
        }
    }
}

impl PartialSystem {
    pub fn is_composition_lawful(&self, x: u8, y: u8) -> bool {
        let gate_x = &self.gate_terms[x as usize];
        let gate_y = &self.gate_terms[y as usize];
        
        let qubits_x = gate_x.active_qubits();
        let qubits_y = gate_y.active_qubits();
        
        if self.hardware.blockade_radius > 0.0 {
            for qx in qubits_x.iter() {
                for qy in qubits_y.iter() {
                    if self.hardware.distance_between(*qx, *qy) < self.hardware.blockade_radius {
                        return false;
                    }
                }
            }
        }
        
        for q in qubits_x.iter().chain(qubits_y.iter()) {
            if !self.hardware.allowed_transitions[*q as usize][1] {
                return false;
            }
        }

        // Check associator defect
        let delta = self.hardware.associator_defect(&[gate_x.clone()], &[gate_y.clone()]);
        if delta > self.hardware.pulse_length_tolerance {
            return false;
        }
        
        true
    }
}

pub struct UnionFind {
    pub parent: [usize; MAX_TERMS],
    pub terms: [Option<Term>; MAX_TERMS],
    pub size: usize,
}

impl UnionFind {
    pub fn new() -> Self {
        let mut uf = Self {
            parent: [0; MAX_TERMS],
            terms: [None; MAX_TERMS],
            size: 0,
        };
        for i in 0..MAX_TERMS {
            uf.parent[i] = i;
        }
        uf
    }

    pub fn find(&mut self, i: usize) -> usize {
        let mut root = i;
        while root != self.parent[root] {
            root = self.parent[root];
        }
        let mut curr = i;
        while curr != root {
            let nxt = self.parent[curr];
            self.parent[curr] = root;
            curr = nxt;
        }
        root
    }

    pub fn union(&mut self, i: usize, j: usize) -> bool {
        let root_i = self.find(i);
        let root_j = self.find(j);
        if root_i != root_j {
            self.parent[root_i] = root_j;
            true
        } else {
            false
        }
    }

    pub fn add_node(&mut self, term: Term) -> usize {
        if self.size < MAX_TERMS {
            let idx = self.size;
            self.terms[idx] = Some(term);
            self.size += 1;
            idx
        } else {
            0
        }
    }

    pub fn get_or_create(&mut self, term: Term) -> usize {
        for i in 0..self.size {
            if let Some(t) = self.terms[i] {
                if t == term {
                    return i;
                }
            }
        }
        self.add_node(term)
    }

    pub fn get_index(&self, term: Term) -> usize {
        for i in 0..self.size {
            if let Some(t) = self.terms[i] {
                if t == term {
                    return i;
                }
            }
        }
        MAX_TERMS
    }

    pub fn is_congruence_closed(&mut self) -> bool {
        for i in 0..self.size {
            for j in 0..self.size {
                if self.find(i) == self.find(j) {
                    let ci = self.get_or_create(Term::Close(i as u8));
                    let cj = self.get_or_create(Term::Close(j as u8));
                    if self.find(ci) != self.find(cj) {
                        return false;
                    }
                }
            }
        }
        true
    }

    pub fn preserves_defined_ops(
        &mut self,
        comp_def: &[(u8, u8, Option<u8>); MAX_TERMS],
        close_def: &[(u8, Option<u8>); MAX_TERMS],
    ) -> bool {
        for &(x, y, z_opt) in comp_def.iter() {
            if let Some(z) = z_opt {
                let idx_xy = self.get_or_create(Term::Comp(x, y));
                let idx_z = self.get_or_create(Term::Var(z));
                if self.find(idx_xy) != self.find(idx_z) {
                    return false;
                }
            }
        }
        for &(x, y_opt) in close_def.iter() {
            if let Some(y) = y_opt {
                let idx_close = self.get_or_create(Term::Close(x));
                let idx_y = self.get_or_create(Term::Var(y));
                if self.find(idx_close) != self.find(idx_y) {
                    return false;
                }
            }
        }
        true
    }

    pub fn composition_respects_congruence(&mut self) -> bool {
        for i in 0..self.size {
            for j in 0..self.size {
                if self.find(i) == self.find(j) {
                    for k in 0..self.size {
                        let cik = self.get_or_create(Term::Comp(i as u8, k as u8));
                        let cjk = self.get_or_create(Term::Comp(j as u8, k as u8));
                        if self.find(cik) != self.find(cjk) {
                            return false;
                        }
                        let cki = self.get_or_create(Term::Comp(k as u8, i as u8));
                        let ckj = self.get_or_create(Term::Comp(k as u8, j as u8));
                        if self.find(cki) != self.find(ckj) {
                            return false;
                        }
                    }
                }
            }
        }
        true
    }
}

pub fn complete(system: &PartialSystem) -> UnionFind {
    let mut uf = UnionFind::new();
    
    for i in 0..system.vars {
        uf.add_node(Term::Var(i));
    }

    let mut iterations = 0;
    while iterations < MAX_TERMS * MAX_TERMS {
        let mut changed = false;

        for i in 0..MAX_TERMS {
            let (x, y, z_opt) = system.comp_def[i];
            if system.is_composition_lawful(x, y) {
                if let Some(z) = z_opt {
                    let idx_xy = uf.get_or_create(Term::Comp(x, y));
                    let idx_z = uf.get_or_create(Term::Var(z));
                    if uf.union(idx_xy, idx_z) { changed = true; }
                }
            }
        }

        for i in 0..MAX_TERMS {
            let (x, y_opt) = system.close_def[i];
            if let Some(y) = y_opt {
                let idx_close = uf.get_or_create(Term::Close(x));
                let idx_y = uf.get_or_create(Term::Var(y));
                if uf.union(idx_close, idx_y) { changed = true; }
            }
        }

        for i in 0..uf.size {
            for j in 0..uf.size {
                if uf.find(i) == uf.find(j) {
                    let ci = uf.get_or_create(Term::Close(i as u8));
                    let cj = uf.get_or_create(Term::Close(j as u8));
                    if uf.union(ci, cj) { changed = true; }
                    
                    let cci = uf.get_or_create(Term::Close(ci as u8));
                    if uf.union(cci, ci) { changed = true; }
                    
                    for k in 0..uf.size {
                        let cik = uf.get_or_create(Term::Comp(i as u8, k as u8));
                        let cjk = uf.get_or_create(Term::Comp(j as u8, k as u8));
                        if uf.union(cik, cjk) { changed = true; }

                        let cki = uf.get_or_create(Term::Comp(k as u8, i as u8));
                        let ckj = uf.get_or_create(Term::Comp(k as u8, j as u8));
                        if uf.union(cki, ckj) { changed = true; }
                    }
                }
            }
        }

        if !changed { break; }
        iterations += 1;
    }

    uf
}

#[cfg(kani)]
mod tests {
    use super::*;

    #[kani::proof]
    #[kani::unwind(1025)]
    fn verify_blockade_respected() {
        let mut hw = HardwareSpec::default();
        hw.blockade_radius = 5.0;
        hw.qubit_positions[0] = [0.0, 0.0];
        hw.qubit_positions[1] = [4.9, 0.0];
        
        let mut sys = PartialSystem::default();
        sys.vars = 3;
        sys.hardware = hw;
        
        let mut ryd1 = [0; MAX_QUBITS];
        ryd1[0] = 0;
        sys.gate_terms[0] = GateOperation::RydbergPulse { qubits: ryd1, active: 1, duration: 1.0, detuning: 0.0 };
        
        let mut ryd2 = [0; MAX_QUBITS];
        ryd2[0] = 1;
        sys.gate_terms[1] = GateOperation::RydbergPulse { qubits: ryd2, active: 1, duration: 1.0, detuning: 0.0 };
        
        sys.comp_def[0] = (0, 1, Some(2));
        
        let mut uf = complete(&sys);
        
        let idx_01 = uf.get_index(Term::Comp(0, 1));
        let idx_2 = uf.get_index(Term::Var(2));
        
        if idx_01 < MAX_TERMS && idx_2 < MAX_TERMS {
            assert!(uf.find(idx_01) != uf.find(idx_2));
        }
    }
}
