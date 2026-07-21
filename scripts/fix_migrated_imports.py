import os
import re

core_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core"

def to_camel_case(s):
    return ''.join(word.capitalize() for word in re.split(r'[-_\s]+', s.strip()))

# Project names mapped to camel case
original_projects = [
    "ACE_SCN_CSC", "ALPHA_FUNCTION", "AZTFTC", "EIGEN_SOLVERS", "ELASTIC_TETHER",
    "HCQA", "LOW-COMPLEXITY_ATTRACTOR", "WEST_EAST", "ZETACELL", "LANGLANDS_PRISM",
    "MCPE", "MERSENNE_503", "EXOTIC_SPHERES", "GODELIAN_TRUTH", "LORENZ_ATRACTOR",
    "AUTOMORPHIC_LEARNING", "ECHO_BRAID", "INTEGRATIVE_SOLVER",
    "MONODIAL_ENSEMBLE_ AGGREGATION", "NEUROPLASTICITY", "RECURSIVE_FOUNDATIONS ",
    "SHPA", "UNIVERSAL_LOGIC", "M_OPERATOR", "MQEM", "ZETA-PHI-PI"
]

project_map = {p: to_camel_case(p) for p in original_projects}
# Add variants if necessary, like AceScnCsc
project_map["AceScnCsc"] = "AceScnCsc"

def fix_imports():
    for root, _, files in os.walk(core_dir):
        for file in files:
            if file.endswith(".lean"):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                new_lines = []
                changed = False
                for line in content.split('\n'):
                    if line.startswith("import "):
                        # e.g. import ACE_SCN_CSC.KernelTelemetry
                        # e.g. import .AtlasSCNBridge -> import Core.AceScnCsc.AtlasSCNBridge
                        for orig, camel in project_map.items():
                            if orig in line:
                                line = line.replace(f"import {orig}", f"import Core.{camel}")
                                changed = True
                        
                        # Fix dot imports if they are in AceScnCsc
                        if "AceScnCsc" in root and "import ." in line:
                            line = line.replace("import .", "import Core.AceScnCsc.")
                            changed = True

                        if "F1Square.Analysis" in line and not line.startswith("import Core."):
                            line = line.replace("import F1Square", "import Core.F1Square")
                            changed = True

                    new_lines.append(line)
                
                if changed:
                    with open(filepath, 'w') as f:
                        f.write('\n'.join(new_lines))

if __name__ == "__main__":
    fix_imports()
    print("Fixed imports.")
