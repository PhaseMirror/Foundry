import os

core_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core"
original_projects = [
    "AceScnCsc", "AlphaFunction", "Aztftc", "EigenSolvers", "ElasticTether",
    "Hcqa", "LowComplexityAttractor", "WestEast", "Zetacell", "LanglandsPrism",
    "Mcpe", "Mersenne503", "ExoticSpheres", "GodelianTruth", "LorenzAtractor",
    "AutomorphicLearning", "EchoBraid", "IntegrativeSolver",
    "MonodialEnsembleAggregation", "Neuroplasticity", "RecursiveFoundations",
    "Shpa", "UniversalLogic", "MOperator", "Mqem", "ZetaPhiPi"
]

imports = []
for p in original_projects:
    p_lean = os.path.join(core_dir, f"{p}.lean")
    p_dir = os.path.join(core_dir, p)
    
    if os.path.exists(p_lean):
        imports.append(f"import Core.{p}")
    
    if os.path.exists(p_dir):
        for f in os.listdir(p_dir):
            if f.endswith(".lean"):
                mod = f[:-5]
                imports.append(f"import Core.{p}.{mod}")

out_path = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core/Migrated.lean"
with open(out_path, "w") as f:
    f.write("-- Aggregation of all migrated Sedona Spine compliant packages\n")
    for imp in imports:
        f.write(imp + "\n")

print(f"Generated {out_path} with {len(imports)} imports.")
