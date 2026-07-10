from typing import Literal, Dict, Any, List, Optional
from pydantic import BaseModel, Field
from datetime import datetime
import uuid

EvidenceTier = Literal["E", "S", "I"]

class GenesisBaseModel(BaseModel):
    schema_version: str = "1.0.0"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    run_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    source_adr_ids: List[str] = []
    tier: EvidenceTier = "I"
    provenance: Dict[str, Any] = {}

class MultiplicityEncoding(BaseModel):
    prime_signature: List[int] = []
    exponent_vector: Dict[int, int] = {}
    sparsity_index: float = 0.0
    locality_score: float = 0.0
    reconstruction_score: Optional[float] = None
    locality_delta: Optional[float] = None

class SurfaceState(BaseModel):
    substrate: str
    coherence: float  # C_X
    stability_threshold: float # C_X*
    effective_stress: float # S_eff
    grounding: float = 0.0 # G_X
    alignment: float = 0.0 # A_X
    impedance: float = 1.0 # Omega_X
    kinematic_drag: float = 0.0 # D_k,X
    frequency: float = 1.0 # omega
    timestamp: float = 0.0
    multiplicity: Optional[MultiplicityEncoding] = None
    # Lane C Extensions
    switching_threshold: Optional[float] = None # V_th
    hysteresis_band: Optional[float] = None # Delta
    logical_state: Optional[str] = "ON" # "ON" or "OFF"

class MultiSubstrateState(BaseModel):
    states: Dict[str, SurfaceState]
    coupling_matrix: Dict[str, Dict[str, float]] # w_ij
    timestamp: float = 0.0
