from typing import List, Dict, Any
import uuid
from genesis_governance.schemas.shrapnel import ShrapnelFragment

class ProvenanceManager:
    """
    Utility to preserve and merge provenance across Builder fragments.
    """
    
    @staticmethod
    def merge_provenance(fragments: List[ShrapnelFragment]) -> Dict[str, Any]:
        merged = {
            "source_run_ids": [],
            "combined_adr_ids": set(),
            "fragment_count": len(fragments),
            "lineage": []
        }
        
        for f in fragments:
            merged["source_run_ids"].append(f.run_id)
            for adr in f.source_adr_ids:
                merged["combined_adr_ids"].add(adr)
            
            # Simple lineage tracking
            merged["lineage"].append({
                "run_id": f.run_id,
                "tier": f.tier,
                "tau": f.tether_tension
            })
            
        merged["combined_adr_ids"] = list(merged["combined_adr_ids"])
        return merged
