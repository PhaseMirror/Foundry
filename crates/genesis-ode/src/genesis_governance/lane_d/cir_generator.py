import json
import os
from typing import Optional, List, Any
from genesis_governance.lane_d.schema import ConstitutionalIncidentReport, MetaContext, HumanAudit, MetaShrapnelFragment

class CIRGenerator:
    """
    Generates Constitutional Incident Reports from MetaOrchestrator outputs.
    """
    @staticmethod
    def generate(source_run_id: str, meta_map: Any, output_dir: str = "output/reports") -> str:
        report = ConstitutionalIncidentReport(
            source_run_id=source_run_id,
            context=meta_map.global_context,
            meta_fragility_class=meta_map.meta_fragments.get("A").meta_fragility_class if "A" in meta_map.meta_fragments else "UNKNOWN",
            cd_global=meta_map.global_assessment.cd_global,
            actions=meta_map.recommended_actions
        )
        report.artifact_hash = report.compute_hash()
        
        os.makedirs(output_dir, exist_ok=True)
        report_path = os.path.join(output_dir, f"CIR_{report.report_id}.json")
        with open(report_path, "w") as f:
            f.write(report.model_dump_json(indent=2))
        return report_path
