import os
import shutil

core_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core"

mapping = {
    "prime_tensors": [("CRMF", "Crmf")],
    "moc": [("AUTOMORPHIC", "AutomorphicTransformer")],
    "alp": [("XICOMPILER", "XiLang")],
    "foundations": [("VERIFICATION", "RecursiveProver")]
}

def consolidate_caps():
    new_imports = []
    
    for target_dir, items in mapping.items():
        for src_dir, mod in items:
            src_path = os.path.join(core_dir, src_dir, f"{mod}.lean")
            dest_dir = os.path.join(core_dir, target_dir)
            dest_path = os.path.join(dest_dir, f"{mod}.lean")
            
            if os.path.exists(src_path):
                # move file
                shutil.move(src_path, dest_path)
                
                # update namespace
                with open(dest_path, 'r') as f:
                    content = f.read()
                
                # We know from the files their namespaces:
                # Crmf.lean -> ADR.CRMF
                # AutomorphicTransformer.lean -> ADR.Automorphic
                # XiLang.lean -> ADR.XiCompiler
                # RecursiveProver.lean -> ADR.RecursiveProver
                if mod == "Crmf":
                    content = content.replace("namespace ADR.CRMF", f"namespace Core.{target_dir}.{mod}")
                    content = content.replace("end ADR.CRMF", f"end Core.{target_dir}.{mod}")
                elif mod == "AutomorphicTransformer":
                    content = content.replace("namespace ADR.Automorphic", f"namespace Core.{target_dir}.{mod}")
                    content = content.replace("end ADR.Automorphic", f"end Core.{target_dir}.{mod}")
                elif mod == "XiLang":
                    content = content.replace("namespace ADR.XiCompiler", f"namespace Core.{target_dir}.{mod}")
                    content = content.replace("end ADR.XiCompiler", f"end Core.{target_dir}.{mod}")
                elif mod == "RecursiveProver":
                    content = content.replace("namespace ADR.RecursiveProver", f"namespace Core.{target_dir}.{mod}")
                    content = content.replace("end ADR.RecursiveProver", f"end Core.{target_dir}.{mod}")
                
                with open(dest_path, 'w') as f:
                    f.write(content)
                
                new_imports.append(f"import Core.{target_dir}.{mod}")
            
            # Try to remove the empty dir
            src_dir_path = os.path.join(core_dir, src_dir)
            if os.path.exists(src_dir_path):
                # Some might have .tex files. We can move the .tex files to docs/ inside the target dir
                docs_dir = os.path.join(dest_dir, "docs")
                os.makedirs(docs_dir, exist_ok=True)
                for f in os.listdir(src_dir_path):
                    if f.endswith(".tex") or f.endswith(".md"):
                        shutil.move(os.path.join(src_dir_path, f), os.path.join(docs_dir, f))
                
                # now remove the dir if empty
                if not os.listdir(src_dir_path):
                    os.rmdir(src_dir_path)
                else:
                    shutil.rmtree(src_dir_path) # just remove it to clean up fully

    # Append to Migrated.lean
    migrated_path = os.path.join(core_dir, "Migrated.lean")
    with open(migrated_path, 'a') as f:
        for imp in new_imports:
            f.write(imp + "\n")
            
    print("Consolidated all-caps directories successfully!")

if __name__ == "__main__":
    consolidate_caps()
