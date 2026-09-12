import os
import sys
import json
from genesis_governance.lane_d.cir_generator import CIRGenerator
from genesis_governance.lane_d.schema import MultiSubstrateMetaMap

# Path to the last meta telemetry
meta_path = "output/lane_d_meta_telemetry.json"
with open(meta_path, "r") as f:
    data = json.load(f)
    meta_map = MultiSubstrateMetaMap(**data)

# Generate CIR
report_path = CIRGenerator.generate(
    source_run_id=data["source_run_ids"][0],
    meta_map=meta_map
)
print(f"CIR Generated: {report_path}")
