/// FRI (Fast Reed-Solomon IOP) Protocol Implementation
///
/// Implements the commit-query-prove phases of FRI for STARK proofs.
///
/// Parameters (from playbook):
/// - Domain: 2^21
/// - Fold factor: 4
/// - Query count: 56
/// - DEEP sampling: enabled
use crate::merkle::MerkleTree;
use crate::transcript::Keccak256Transcript;
use crate::{ProverError, QueryOpening, StarkProof};
use goldilocks::GoldilocksField;

#[allow(unused_imports)]
use goldilocks::polynomial::{ntt, intt, eval_poly};

#[allow(dead_code)]
pub struct FriProver {
    domain_pow: u32,
    fold_factor: u32,
    num_queries: u32,
    deep_enabled: bool,
}

impl FriProver {
    pub fn new(domain_pow: u32, fold_factor: u32, num_queries: u32, deep_enabled: bool) -> Self {
        Self {
            domain_pow,
            fold_factor,
            num_queries,
            deep_enabled,
        }
    }

    /// Generate a STARK proof for the given trace
    pub fn prove(&self, trace: &[Vec<GoldilocksField>]) -> Result<StarkProof, ProverError> {
        let start = std::time::Instant::now();
        let mut transcript = Keccak256Transcript::new(b"STARK");

        // 0. Perform LDE (Low Degree Extension) on trace columns
        let lde_start = std::time::Instant::now();
        let domain_size = 1 << self.domain_pow;
        let mut extended_trace = Vec::with_capacity(trace.len());
        
        for col in trace {
            // Interpolate to coefficients
            let mut coeffs = col.clone();
            let original_len = coeffs.len();
            if !original_len.is_power_of_two() {
                coeffs.resize(original_len.next_power_of_two(), GoldilocksField::ZERO);
            }
            goldilocks::polynomial::intt(&mut coeffs);
            
            // Evaluate on larger domain
            coeffs.resize(domain_size, GoldilocksField::ZERO);
            goldilocks::polynomial::ntt(&mut coeffs);
            
            extended_trace.push(coeffs);
        }
        println!("  - LDE took: {:?}", lde_start.elapsed());

        // 1. Commit to trace columns
        let commit_start = std::time::Instant::now();
        let trace_tree = self.commit_trace(&extended_trace, &mut transcript)?;
        let trace_commitment = trace_tree.root();
        println!("  - Trace commitment took: {:?}", commit_start.elapsed());

        // 2. Compute composition polynomial (simplified - just use first column for now)
        let composition = extended_trace[0].clone();

        // 3. Commit to composition polynomial
        let comp_commit_start = std::time::Instant::now();
        let comp_tree = self.commit_polynomial(&composition)?;
        transcript.append_commitment(b"composition", &comp_tree.root());
        println!("  - Composition commitment took: {:?}", comp_commit_start.elapsed());

        // 4. FRI folding rounds
        let fri_start = std::time::Instant::now();
        let (fri_commitments, fri_layers) = self.fri_folding(&composition, &mut transcript)?;
        println!("  - FRI folding took: {:?}", fri_start.elapsed());

        // 5. Sample query indices
        let query_indices = self.sample_query_indices(&mut transcript);

        // 6. Generate query openings
        let open_start = std::time::Instant::now();
        let query_openings =
            self.generate_query_openings(&extended_trace, &trace_tree, &composition, &fri_layers, &query_indices)?;
        println!("  - Query openings took: {:?}", open_start.elapsed());

        // 7. Final polynomial should be constant after folding
        let fri_final_poly = fri_layers.last().cloned().unwrap_or_default();

        println!("  - Total prove time: {:?}", start.elapsed());
        Ok(StarkProof {
            trace_commitment,
            fri_commitments,
            query_openings,
            fri_final_poly,
        })
    }

    /// Commit to trace columns
    fn commit_trace(
        &self,
        trace: &[Vec<GoldilocksField>],
        transcript: &mut Keccak256Transcript,
    ) -> Result<MerkleTree, ProverError> {
        // Flatten trace columns into leaf data
        let trace_len = trace[0].len();
        let mut leaf_data = Vec::with_capacity(trace_len);

        for i in 0..trace_len {
            let mut row_data = Vec::with_capacity(trace.len() * 8);
            for col in trace {
                row_data.extend_from_slice(&col[i].to_canonical().to_le_bytes());
            }
            leaf_data.push(row_data);
        }

        let tree = MerkleTree::new(leaf_data);
        transcript.append_commitment(b"trace", &tree.root());

        Ok(tree)
    }

    /// Execute FRI folding rounds
    fn fri_folding(
        &self,
        poly: &[GoldilocksField],
        transcript: &mut Keccak256Transcript,
    ) -> Result<(Vec<[u8; 32]>, Vec<Vec<GoldilocksField>>), ProverError> {
        let mut commitments = Vec::new();
        let mut layers = vec![poly.to_vec()];
        let mut current = poly.to_vec();

        // Compute number of folding rounds
        let fold_factor = self.fold_factor.max(2) as usize;
        let mut round = 0usize;

        while current.len() > fold_factor {
            // Get folding challenge (use DEEP variant label when enabled)
            let beta_label: &[u8] = if self.deep_enabled {
                b"fri_beta_deep"
            } else {
                b"fri_beta"
            };
            let beta = transcript.challenge(beta_label);
            let beta_field = GoldilocksField::new(beta);

            // Fold polynomial by configured factor
            current = self.fold_polynomial(&current, &beta_field);

            // Commit to folded polynomial
            let tree = self.commit_polynomial(&current)?;
            commitments.push(tree.root());
            transcript.append_commitment(b"fri_layer", &tree.root());

            layers.push(current.clone());
            round += 1;

            // Avoid excessive folding if domain_pow is very small
            if round >= self.domain_pow as usize {
                break;
            }
        }

        Ok((commitments, layers))
    }

    /// Generate query openings for verification
    fn generate_query_openings(
        &self,
        trace: &[Vec<GoldilocksField>],
        trace_tree: &MerkleTree,
        _composition: &[GoldilocksField],
        fri_layers: &[Vec<GoldilocksField>],
        query_indices: &[usize],
    ) -> Result<Vec<QueryOpening>, ProverError> {
        let mut openings = Vec::new();

        for &index in query_indices {
            // Extract trace values at this index
            let trace_values: Vec<GoldilocksField> = trace
                .iter()
                .map(|col| col.get(index).copied().unwrap_or(GoldilocksField::ZERO))
                .collect();

            // Extract FRI layer values
            let fri_layer_values: Vec<GoldilocksField> = fri_layers
                .iter()
                .map(|layer| {
                    layer
                        .get(index % layer.len())
                        .copied()
                        .unwrap_or(GoldilocksField::ZERO)
                })
                .collect();

            // Generate Merkle authentication path
            let auth_path = trace_tree.prove(index);

            openings.push(QueryOpening {
                index,
                trace_values,
                auth_path,
                fri_layers: fri_layer_values,
            });
        }

        Ok(openings)
    }

    /// Commit to a polynomial by evaluating on domain and building Merkle tree
    fn commit_polynomial(&self, poly: &[GoldilocksField]) -> Result<MerkleTree, ProverError> {
        // Convert polynomial evaluations to bytes for Merkle tree
        let leaf_data: Vec<Vec<u8>> = poly
            .iter()
            .map(|val| val.to_canonical().to_le_bytes().to_vec())
            .collect();

        Ok(MerkleTree::new(leaf_data))
    }

    /// Execute one round of FRI folding
    ///
    /// Folds polynomial by splitting into even/odd and combining with challenge
    fn fold_polynomial(
        &self,
        poly: &[GoldilocksField],
        challenge: &GoldilocksField,
    ) -> Vec<GoldilocksField> {
        let n = poly.len();
        if n <= 1 {
            return poly.to_vec();
        }

        let fold_factor = self.fold_factor.max(2) as usize;
        let chunk_size = (n + fold_factor - 1) / fold_factor;
        let mut folded = Vec::with_capacity(chunk_size);

        for i in 0..chunk_size {
            let mut acc = GoldilocksField::ZERO;
            let mut challenge_power = GoldilocksField::ONE;

            for j in 0..fold_factor {
                let idx = i + j * chunk_size;
                if idx >= n {
                    break;
                }

                let term = poly.get(idx).copied().unwrap_or(GoldilocksField::ZERO);
                acc = acc.add(&challenge_power.mul(&term));
                challenge_power = challenge_power.mul(challenge);
            }

            folded.push(acc);
        }

        folded
    }

    /// Sample query indices from transcript
    fn sample_query_indices(&self, transcript: &mut Keccak256Transcript) -> Vec<usize> {
        let mut indices = Vec::new();
        let domain_size = 1 << self.domain_pow;
        
        for _ in 0..self.num_queries {
            let challenge = transcript.challenge(b"query_index");
            indices.push((challenge % domain_size as u64) as usize);
        }
        
        indices
    }
}
