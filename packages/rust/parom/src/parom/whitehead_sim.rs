use std::collections::{HashMap, HashSet};
use rand::Rng;
use serde_json::json;
use std::fs::File;
use std::io::Write;

fn walsh_hadamard_transform_128(x: &mut [f64; 128], n: usize) {
    let mut h = 1;
    while h < n {
        for i in (0..n).step_by(h * 2) {
            for j in i..i+h {
                let u = x[j];
                let v = x[j+h];
                x[j] = u + v;
                x[j+h] = u - v;
            }
        }
        h *= 2;
    }
    let sqrt_n = (n as f64).sqrt();
    for i in 0..n {
        x[i] /= sqrt_n;
    }
}

fn is_prime_u64(n: u64) -> bool {
    match num_prime::nt_funcs::is_prime(&n, None) {
        num_prime::Primality::Yes | num_prime::Primality::Probable(_) => true,
        num_prime::Primality::No => false,
    }
}

pub struct WhiteheadHypergraph {
    pub next_node_id: usize,
    pub node_to_prime: HashMap<usize, u64>,
    pub prime_to_node: HashMap<u64, usize>,
    pub node_labels: Vec<String>,
    pub hyperedges: Vec<HashSet<usize>>,
}

impl WhiteheadHypergraph {
    pub fn new(initial_nodes: Vec<String>, initial_edges: Vec<Vec<String>>, primes_opt: Option<Vec<u64>>) -> Self {
        let mut hg = Self {
            next_node_id: 0,
            node_to_prime: HashMap::new(),
            prime_to_node: HashMap::new(),
            node_labels: Vec::new(),
            hyperedges: Vec::new(),
        };

        let primes = primes_opt.unwrap_or_else(|| {
            let mut list = Vec::new();
            for i in 1..=initial_nodes.len() {
                list.push(num_prime::nt_funcs::nth_prime(i as u64));
            }
            list
        });

        for (i, label) in initial_nodes.into_iter().enumerate() {
            let p = primes[i];
            hg.add_node_with_prime(label, p);
        }

        for edge in initial_edges {
            let mut node_ids = HashSet::new();
            for lbl in edge {
                if let Some(pos) = hg.node_labels.iter().position(|l| l == &lbl) {
                    node_ids.insert(pos);
                }
            }
            hg.hyperedges.push(node_ids);
        }

        hg
    }

    pub fn add_node_with_prime(&mut self, label: String, prime_val: u64) -> usize {
        let node_id = self.next_node_id;
        self.next_node_id += 1;
        self.node_to_prime.insert(node_id, prime_val);
        self.prime_to_node.insert(prime_val, node_id);
        self.node_labels.push(label);
        node_id
    }

    pub fn contract_subgraph(&mut self, node_ids: &[usize], new_label: String, is_random: bool) -> usize {
        let new_prime = if is_random {
            let mut rng = rand::thread_rng();
            rng.gen_range(2u64.pow(31)..2u64.pow(32))
        } else {
            let mut prod: u128 = 1;
            for &nid in node_ids {
                if let Some(&p) = self.node_to_prime.get(&nid) {
                    prod = prod.wrapping_mul(p as u128);
                }
            }
            prod as u64
        };

        let new_node_id = self.add_node_with_prime(new_label, new_prime);

        // Update hyperedges
        let mut new_edges = Vec::new();
        for edge in &self.hyperedges {
            let has_intersection = node_ids.iter().any(|nid| edge.contains(nid));
            if !has_intersection {
                new_edges.push(edge.clone());
            } else {
                let mut new_edge = HashSet::new();
                for &n in edge {
                    if node_ids.contains(&n) {
                        new_edge.insert(new_node_id);
                    } else {
                        new_edge.insert(n);
                    }
                }
                new_edges.push(new_edge);
            }
        }
        self.hyperedges = new_edges;

        // Remove contracted nodes
        for &nid in node_ids {
            if let Some(p) = self.node_to_prime.remove(&nid) {
                self.prime_to_node.remove(&p);
            }
        }

        // Rebuild prime_to_node
        self.prime_to_node.clear();
        for (&nid, &p) in &self.node_to_prime {
            self.prime_to_node.insert(p, nid);
        }

        new_node_id
    }

    pub fn adjacency_matrix(&self) -> Vec<Vec<f64>> {
        let n = self.next_node_id;
        let mut adj = vec![vec![0.0; n]; n];
        for edge in &self.hyperedges {
            let nodes: Vec<&usize> = edge.iter().collect();
            for i in 0..nodes.len() {
                for j in i+1..nodes.len() {
                    let u = *nodes[i];
                    let v = *nodes[j];
                    if u < n && v < n {
                        adj[u][v] += 1.0;
                        adj[v][u] += 1.0;
                    }
                }
            }
        }
        adj
    }
}

pub fn resonance_function(subgraph: &[usize], hg: &WhiteheadHypergraph, cv: &[f64]) -> f64 {
    let mut prod: u128 = 1;
    for &nid in subgraph {
        if let Some(&p) = hg.node_to_prime.get(&nid) {
            prod = prod.wrapping_mul(p as u128);
        }
    }
    if prod == 0 {
        return 0.0;
    }
    
    // Map u128 bits to f64 vector for Walsh-Hadamard
    let mut bits = [0.0; 128];
    for i in 0..128 {
        if (prod >> i) & 1 == 1 {
            bits[i] = 1.0;
        } else {
            bits[i] = -1.0;
        }
    }
    
    walsh_hadamard_transform_128(&mut bits, 128);
    
    let mut dot = 0.0;
    for i in 0..64 {
        dot += bits[i] * cv[i];
    }
    dot * dot
}

pub fn find_best_subgraph(hg: &WhiteheadHypergraph, cv: &[f64]) -> Option<Vec<usize>> {
    let n_nodes = hg.next_node_id;
    if n_nodes == 0 {
        return None;
    }

    let active_nodes: Vec<usize> = hg.node_to_prime.keys().cloned().collect();
    if active_nodes.is_empty() {
        return None;
    }

    let adj = hg.adjacency_matrix();
    let mut best_subgraph = Vec::new();
    let mut best_score = f64::NEG_INFINITY;

    // 1. Single nodes
    for &node in &active_nodes {
        let score = resonance_function(&[node], hg, cv);
        if score > best_score {
            best_score = score;
            best_subgraph = vec![node];
        }
    }

    // 2. Pairs (connected)
    for i in 0..active_nodes.len() {
        for j in i+1..active_nodes.len() {
            let u = active_nodes[i];
            let v = active_nodes[j];
            if u < adj.len() && v < adj[u].len() && adj[u][v] > 0.0 {
                let score = resonance_function(&[u, v], hg, cv);
                if score > best_score {
                    best_score = score;
                    best_subgraph = vec![u, v];
                }
            }
        }
    }

    // 3. Triples (connected)
    let mut checked_triplets = HashSet::new();
    for &u in &active_nodes {
        for &v in &active_nodes {
            if u != v && u < adj.len() && v < adj[u].len() && adj[u][v] > 0.0 {
                for &w in &active_nodes {
                    if w != u && w != v {
                        let c_vw = v < adj.len() && w < adj[v].len() && adj[v][w] > 0.0;
                        let c_uw = u < adj.len() && w < adj[u].len() && adj[u][w] > 0.0;
                        if c_vw || c_uw {
                            let mut triple = vec![u, v, w];
                            triple.sort_unstable();
                            let key = (triple[0], triple[1], triple[2]);
                            if checked_triplets.insert(key) {
                                let score = resonance_function(&triple, hg, cv);
                                if score > best_score {
                                    best_score = score;
                                    best_subgraph = triple;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if best_subgraph.is_empty() {
        None
    } else {
        Some(best_subgraph)
    }
}

pub fn parom_step(hg: &mut WhiteheadHypergraph, cv: &[f64], alpha: f64) {
    let n_edges = hg.hyperedges.len();
    let mut new_edges = Vec::new();
    for j in 0..n_edges {
        let edge_nodes: Vec<usize> = hg.hyperedges[j].iter().cloned().collect();
        let score = resonance_function(&edge_nodes, hg, cv);
        // Reinforcement probability increases with alpha and resonance
        let prob = (score * alpha) / 100.0;
        if rand::thread_rng().gen_range(0.0..1.0) < prob {
            new_edges.push(hg.hyperedges[j].clone());
        }
    }
    for e in new_edges {
        if hg.hyperedges.len() < 2000 {
            hg.hyperedges.push(e);
        }
    }
}

pub fn compute_spectral_radius(hg: &WhiteheadHypergraph) -> f64 {
    let active_nodes: Vec<usize> = hg.node_to_prime.keys().cloned().collect();
    let n = active_nodes.len();
    if n == 0 {
        return 0.0;
    }

    // Create a mapping from node_id to dense matrix index
    let mut node_to_idx = HashMap::new();
    for (idx, &node_id) in active_nodes.iter().enumerate() {
        node_to_idx.insert(node_id, idx);
    }

    // Build the dense adjacency matrix for active nodes only
    let mut adj = vec![vec![0.0; n]; n];
    let mut has_non_zero = false;
    for edge in &hg.hyperedges {
        let nodes: Vec<&usize> = edge.iter().collect();
        for i in 0..nodes.len() {
            for j in i+1..nodes.len() {
                let u = *nodes[i];
                let v = *nodes[j];
                if let (Some(&u_idx), Some(&v_idx)) = (node_to_idx.get(&u), node_to_idx.get(&v)) {
                    adj[u_idx][v_idx] += 1.0;
                    adj[v_idx][u_idx] += 1.0;
                    has_non_zero = true;
                }
            }
        }
    }

    if !has_non_zero {
        return 0.0;
    }

    /*
    let mut adj_norm = vec![vec![0.0; n]; n];
    for i in 0..n {
        let sum: f64 = adj[i].iter().sum();
        let divisor = if sum == 0.0 { 1.0 } else { sum };
        for j in 0..n {
            adj_norm[i][j] = adj[i][j] / divisor;
        }
    }
    */

    let flat_data: Vec<f64> = adj.into_iter().flatten().collect();
    let dmat = nalgebra::DMatrix::from_vec(n, n, flat_data).transpose();
    
    // Power iteration to find the spectral radius of the non-negative matrix
    let mut v = nalgebra::DVector::from_element(n, 1.0 / (n as f64).sqrt());
    for _ in 0..100 {
        let next_v = &dmat * &v;
        let norm = next_v.norm();
        if norm < 1e-12 {
            break;
        }
        v = next_v / norm;
    }
    
    (&dmat * &v).norm()
}

pub fn compute_prime_entropy(hg: &WhiteheadHypergraph) -> f64 {
    let primes: Vec<u64> = hg.node_to_prime.values().cloned().collect();
    if primes.is_empty() {
        return 0.0;
    }
    let mut counts = HashMap::new();
    for &p in &primes {
        *counts.entry(p).or_insert(0) += 1;
    }
    let total = primes.len() as f64;
    let mut entropy = 0.0;
    for &count in counts.values() {
        let prob = count as f64 / total;
        entropy -= prob * prob.log2();
    }
    entropy
}

pub struct SimStepResult {
    pub step: usize,
    pub lambda: f64,
    pub entropy: f64,
    pub l_eff: f64,
    pub n_nodes: usize,
    pub n_edges: usize,
    pub novelty_rate: f64,
    pub primes: HashSet<u64>,
}

pub fn run_simulation(
    alpha: f64,
    beta: f64,
    max_steps: usize,
    initial_nodes: Vec<String>,
    initial_edges: Vec<Vec<String>>,
    primes_opt: Option<Vec<u64>>,
    is_random: bool,
) -> Vec<SimStepResult> {
    let mut hg = WhiteheadHypergraph::new(initial_nodes, initial_edges, primes_opt);
    let mut history: Vec<SimStepResult> = Vec::new();
    let cv = {
        let mut v = vec![0.0; 64];
        for i in 0..64 {
            v[i] = if i % 2 == 0 { 1.0 } else { -1.0 };
        }
        v
    };

    let mut rng = rand::thread_rng();

    for step in 0..max_steps {
        if let Some(best) = find_best_subgraph(&hg, &cv) {
            let new_label = format!("c{}", step);
            hg.contract_subgraph(&best, new_label, is_random);
        }

        if alpha > 0.0 {
            parom_step(&mut hg, &cv, alpha);
        }

        if beta > 0.0 && rng.gen_range(0.0..1.0) < beta {
            let next_p = if is_random {
                rng.gen_range(2u64.pow(31)..2u64.pow(32))
            } else {
                let used_primes: HashSet<u64> = hg.node_to_prime.values().cloned().collect();
                let mut p = 2;
                while used_primes.contains(&p) {
                    p += 1;
                    while !is_prime_u64(p) {
                        p += 1;
                    }
                }
                p
            };
            let new_label = format!("novel_{}", step);
            let nid = hg.add_node_with_prime(new_label, next_p);
            
            // Connect novelty node to a random existing node to ensure connectivity
            let active_nodes: Vec<usize> = hg.node_to_prime.keys().cloned().collect();
            if active_nodes.len() > 1 {
                let target = active_nodes[rng.gen_range(0..active_nodes.len())];
                if target != nid {
                    let mut edge = HashSet::new();
                    edge.insert(nid);
                    edge.insert(target);
                    hg.hyperedges.push(edge);
                }
            }
        }

        let l_eff = compute_spectral_radius(&hg);
        let lambda_val = l_eff;
        let entropy = compute_prime_entropy(&hg);

        let novelty_rate = if step == 0 {
            0.0
        } else {
            let all_primes: HashSet<u64> = hg.node_to_prime.values().cloned().collect();
            let prev_primes = &history[step - 1].primes;
            let new_primes: HashSet<u64> = all_primes.difference(prev_primes).cloned().collect();
            new_primes.len() as f64 / all_primes.len().max(1) as f64
        };

        history.push(SimStepResult {
            step,
            lambda: lambda_val,
            entropy,
            l_eff,
            n_nodes: hg.node_to_prime.len(),
            n_edges: hg.hyperedges.len(),
            novelty_rate,
            primes: hg.node_to_prime.values().cloned().collect(),
        });

        while hg.node_to_prime.len() > 108 {
            if let Some((&min_node, _)) = hg.node_to_prime.iter().min_by_key(|&(_, &p)| p) {
                hg.hyperedges.retain(|edge| !edge.contains(&min_node));
                if let Some(p) = hg.node_to_prime.remove(&min_node) {
                    hg.prime_to_node.remove(&p);
                }
            }
            hg.prime_to_node.clear();
            for (&nid, &p) in &hg.node_to_prime {
                hg.prime_to_node.insert(p, nid);
            }
        }
    }

    history
}

pub fn run_c4_ablation() {
    let mut alphas = Vec::new();
    let mut betas = Vec::new();
    for i in 0..20 {
        let alpha = (i as f64) / 19.0 * 2.0;
        let beta = (1.0 - alpha).max(0.0);
        alphas.push(alpha);
        betas.push(beta);
    }

    let mut results_prime = Vec::new();
    let mut results_random = Vec::new();

    let initial_nodes: Vec<String> = (0..5).map(|i| format!("n{}", i)).collect();
    let mut initial_edges = Vec::new();
    for i in 0..5 {
        for j in i+1..5 {
            initial_edges.push(vec![format!("n{}", i), format!("n{}", j)]);
        }
    }

    println!("Running α sweep for C4 ablation...");
    for i in 0..20 {
        let alpha = alphas[i];
        let beta = betas[i];
        println!("Alpha sweep step {}/20: alpha = {:.4}, beta = {:.4}", i + 1, alpha, beta);

        // 1. Prime case
        let primes = vec![2, 3, 5, 7, 11];
        let hist_prime = run_simulation(
            alpha,
            beta,
            108,
            initial_nodes.clone(),
            initial_edges.clone(),
            Some(primes),
            false,
        );
        let last_50_prime: Vec<f64> = hist_prime.iter().skip(58).map(|h| h.lambda).collect();
        let mean_prime = last_50_prime.iter().sum::<f64>() / last_50_prime.len() as f64;
        results_prime.push(mean_prime);

        // 2. Random case
        let mut rng = rand::thread_rng();
        let random_ints: Vec<u64> = (0..5).map(|_| rng.gen_range(2u64.pow(31)..2u64.pow(32))).collect();
        let hist_random = run_simulation(
            alpha,
            beta,
            108,
            initial_nodes.clone(),
            initial_edges.clone(),
            Some(random_ints),
            true,
        );
        let last_50_random: Vec<f64> = hist_random.iter().skip(58).map(|h| h.lambda).collect();
        let mean_random = last_50_random.iter().sum::<f64>() / last_50_random.len() as f64;
        results_random.push(mean_random);
    }

    // Compute gradients (slopes)
    let mut grad_prime = vec![0.0; 20];
    let mut grad_random = vec![0.0; 20];
    for i in 1..19 {
        grad_prime[i] = (results_prime[i+1] - results_prime[i-1]) / 2.0;
        grad_random[i] = (results_random[i+1] - results_random[i-1]) / 2.0;
    }
    grad_prime[0] = results_prime[1] - results_prime[0];
    grad_prime[19] = results_prime[19] - results_prime[18];
    grad_random[0] = results_random[1] - results_random[0];
    grad_random[19] = results_random[19] - results_random[18];

    // Compute variance of gradients
    let mean_grad_prime = grad_prime.iter().sum::<f64>() / 20.0;
    let var_grad_prime = grad_prime.iter().map(|g| (g - mean_grad_prime).powi(2)).sum::<f64>() / 20.0;

    let mean_grad_random = grad_random.iter().sum::<f64>() / 20.0;
    let var_grad_random = grad_random.iter().map(|g| (g - mean_grad_random).powi(2)).sum::<f64>() / 20.0;

    let chi2 = (var_grad_prime / (var_grad_random + 1e-9)) * 30.0;
    println!("----- C4 Ablation Results -----");
    println!("Prime Slope Variance: {:.6}", var_grad_prime);
    println!("Random Slope Variance: {:.6}", var_grad_random);
    println!("χ² detectability statistic: {:.4}", chi2);

    let output_json = json!({
        "alphas": alphas,
        "results_prime": results_prime,
        "results_random": results_random,
        "var_grad_prime": var_grad_prime,
        "var_grad_random": var_grad_random,
        "chi2": chi2,
    });

    let mut file = File::create("c4_results.json").expect("Failed to create c4_results.json");
    file.write_all(serde_json::to_string_pretty(&output_json).unwrap().as_bytes())
        .expect("Failed to write c4_results.json");
    println!("Results successfully written to c4_results.json.");
}
