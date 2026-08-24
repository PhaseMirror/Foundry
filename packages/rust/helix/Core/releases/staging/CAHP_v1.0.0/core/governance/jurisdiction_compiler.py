import json
import os
from typing import Dict, Any

class JurisdictionCompiler:
    def __init__(self, profiles_path: str):
        if not os.path.exists(profiles_path):
             raise FileNotFoundError(f"Profiles not found at {profiles_path}")
             
        with open(profiles_path, 'r') as f:
            self.profiles = json.load(f)["profiles"]

    def compile_policy(self, base_role: Dict, region_code: str) -> Dict:
        """
        Compiles a 'local' runtime policy by applying jurisdictional constraints
        to the base role permissions.
        """
        # 1. Identify applicable profile
        active_profile = None
        for key, profile in self.profiles.items():
            if region_code in profile["region_codes"]:
                active_profile = profile
                break
        
        if not active_profile:
            print(f"No profile found for region {region_code}, returning base policy.")
            return base_role 

        compiled_role = base_role.copy()
        constraints = active_profile["constraints"]
        
        # Add metadata about applied jurisdiction
        compiled_role["jurisdiction_applied"] = key

        # 2. Apply Constraints
        
        # Enforce Data Residency
        if "data_residency" in constraints:
            compiled_role["storage_constraint"] = constraints["data_residency"]

        # Enforce Right to be Forgotten (Retention cap)
        if "right_to_be_forgotten" in constraints:
            rtbf = constraints["right_to_be_forgotten"]
            if rtbf.get("enabled"):
                 limit = rtbf["max_retention_seconds"]
                 current_retention = compiled_role.get("max_memory_retention", float('inf'))
                 compiled_role["max_memory_retention"] = min(current_retention, limit)

        # Enforce Attribution Requirements
        if "attribution" in constraints:
             attr = constraints["attribution"]
             if attr.get("required"):
                 if "constraints" not in compiled_role:
                     compiled_role["constraints"] = []
                 compiled_role["constraints"].append(f"output:must_contain_citations:{attr.get('format', 'standard')}")

        return compiled_role

# Example Usage
if __name__ == "__main__":
    # Path to the JSON file we just created
    json_path = os.path.join(os.path.dirname(__file__), "jurisdiction_primitives_v1.json")
    
    compiler = JurisdictionCompiler(json_path)
    
    # Mock Base Role (from G-1)
    base_role = {
        "role": "color_artist",
        "permissions": ["read:all", "write:local"],
        "max_memory_retention": 31536000, # 1 Year
        "constraints": []
    }
    
    print("--- Base Role ---")
    print(json.dumps(base_role, indent=2))
    
    print("""
--- Compiled for EU (GDPR) ---
""")
    eu_policy = compiler.compile_policy(base_role, "EU")
    print(json.dumps(eu_policy, indent=2))
    
    print("""
--- Compiled for Helix Neutral Zone ---
""")
    nz_policy = compiler.compile_policy(base_role, "HELIX-NZ")
    print(json.dumps(nz_policy, indent=2))
