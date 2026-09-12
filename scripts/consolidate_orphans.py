import os
import shutil

core_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core"

mapping = {
    "f1_square": ["AlphaFunction", "ZetaPhiPi", "Zetacell", "LanglandsPrism", "Mersenne503", "ExoticSpheres", "Aztftc"],
    "Operators": ["EigenSolvers", "MOperator", "IntegrativeSolver", "AceScnCsc"],
    "foundations": ["GodelianTruth", "UniversalLogic", "AutomorphicLearning"],
    "stability": ["LorenzAtractor", "LowComplexityAttractor", "ElasticTether"],
    "prime_tensors": ["Mqem", "EchoBraid", "WestEast", "MonodialEnsembleAggregation"],
    "moc": ["Neuroplasticity", "Hcqa", "Mcpe", "Shpa", "RecursiveFoundations"]
}

def consolidate():
    imports_for_migrated = []

    for target_dir, modules in mapping.items():
        target_path = os.path.join(core_dir, target_dir)
        os.makedirs(target_path, exist_ok=True)
        
        for mod in modules:
            # There can be mod.lean or a directory mod/
            lean_file = os.path.join(core_dir, f"{mod}.lean")
            mod_dir = os.path.join(core_dir, mod)
            
            # If it's a directory (like AceScnCsc)
            if os.path.isdir(mod_dir):
                dest_dir = os.path.join(target_path, mod)
                if not os.path.exists(dest_dir):
                    shutil.move(mod_dir, dest_dir)
                
                # Update namespaces in the directory
                for root, _, files in os.walk(dest_dir):
                    for f in files:
                        if f.endswith(".lean"):
                            filepath = os.path.join(root, f)
                            with open(filepath, 'r') as file:
                                content = file.read()
                            
                            # Replace namespace
                            content = content.replace(f"namespace Core.{mod}", f"namespace Core.{target_dir}.{mod}")
                            content = content.replace(f"end Core.{mod}", f"end Core.{target_dir}.{mod}")
                            content = content.replace(f"import Core.{mod}", f"import Core.{target_dir}.{mod}")
                            
                            with open(filepath, 'w') as file:
                                file.write(content)
                                
                            mod_name = f[:-5]
                            imports_for_migrated.append(f"import Core.{target_dir}.{mod}.{mod_name}")

            # If it's a standalone file
            if os.path.exists(lean_file):
                dest_file = os.path.join(target_path, f"{mod}.lean")
                if not os.path.exists(dest_file):
                    shutil.move(lean_file, dest_file)
                
                with open(dest_file, 'r') as file:
                    content = file.read()
                
                # Replace namespace
                content = content.replace(f"namespace Core.{mod}", f"namespace Core.{target_dir}.{mod}")
                content = content.replace(f"end Core.{mod}", f"end Core.{target_dir}.{mod}")
                content = content.replace(f"import Core.{mod}", f"import Core.{target_dir}.{mod}")
                
                with open(dest_file, 'w') as file:
                    file.write(content)
                
                imports_for_migrated.append(f"import Core.{target_dir}.{mod}")

    # Write a new Migrated.lean
    migrated_path = os.path.join(core_dir, "Migrated.lean")
    with open(migrated_path, 'w') as f:
        f.write("-- Aggregation of all consolidated Sedona Spine compliant packages\n")
        for imp in sorted(set(imports_for_migrated)):
            f.write(imp + "\n")

    print(f"Consolidation complete. Updated Migrated.lean with {len(imports_for_migrated)} imports.")

if __name__ == "__main__":
    consolidate()
