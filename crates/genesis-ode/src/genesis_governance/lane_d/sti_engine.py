import numpy as np
import torch
from typing import List, Dict, Any
from scipy.stats import entropy
from sentence_transformers import SentenceTransformer

class STIEngine:
    """
    Computational engine for Semantic Traceability Index (STI).
    Computes governing metrics for Lane S (Symbolic/Cognitive).
    """
    def __init__(self, coherence_model: str = 'all-mpnet-base-v2'):
        # Using sentence-transformers for coherence (Ψ)
        self.coherence_model = SentenceTransformer(coherence_model)
        # Ethics model placeholder (for Δ_drift)
        self.drift_embedding = None

    def compute_psi_coherence(self, text_sequence: List[str]) -> float:
        """Calculate Ψ_coherence: normalized consistency of linguistic embeddings."""
        if not text_sequence:
            return 0.0
        embeddings = self.coherence_model.encode(text_sequence, convert_to_tensor=True)
        # Calculate consistency via average cosine similarity or entropy
        # Here: normalized entropy of embedding distribution
        probs = torch.softmax(embeddings, dim=1).cpu().numpy()
        return 1.0 / (1.0 + entropy(probs.T, axis=0).mean())

    def compute_delta_drift(self, current_embedding: np.ndarray) -> float:
        """Calculate Δ_drift: shift in ethical tensor field."""
        if self.drift_embedding is None:
            self.drift_embedding = current_embedding
            return 0.0
        
        drift = np.linalg.norm(current_embedding - self.drift_embedding)
        self.drift_embedding = current_embedding
        return float(drift)

    def compute_theta_audit(self, inference_tree: Dict[str, Any]) -> float:
        """Calculate Θ_audit: ratio of resolvable inference paths."""
        resolvable = inference_tree.get('resolvable_paths', 0)
        total = inference_tree.get('total_branches', 1)
        return float(resolvable / max(total, 1))

    def compute_sti(self, text_sequence: List[str], inference_tree: Dict[str, Any], ethics_embedding: np.ndarray) -> Dict[str, float]:
        """
        Compute total STI(t) and individual components.
        """
        psi = self.compute_psi_coherence(text_sequence)
        delta = self.compute_delta_drift(ethics_embedding)
        theta = self.compute_theta_audit(inference_tree)
        
        # STI(t) = (theta / (1 + delta)) * psi
        sti_value = (theta / (1.0 + delta)) * psi
        
        return {
            "sti": float(sti_value),
            "psi_coherence": float(psi),
            "delta_drift": float(delta),
            "theta_audit": float(theta)
        }
