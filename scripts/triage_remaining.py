import os
import json

ensembles_dir = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/ensembles"
substrates_dir = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/substrates"

def get_dir_size(path):
    total = 0
    for dirpath, _, filenames in os.walk(path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            if not os.path.islink(fp):
                total += os.path.getsize(fp)
    return total

def analyze_ensembles():
    results = {}
    for d in os.listdir(ensembles_dir):
        path = os.path.join(ensembles_dir, d)
        if not os.path.isdir(path): continue
        
        has_cargo = os.path.exists(os.path.join(path, "Cargo.toml"))
        has_lean = False
        empty_lib = False
        
        lib_path = os.path.join(path, "src", "lib.rs")
        if os.path.exists(lib_path):
            if os.path.getsize(lib_path) == 0:
                empty_lib = True
                
        size = get_dir_size(path)
        
        # Check if corresponding substrate exists
        sub_match = None
        for sd in os.listdir(substrates_dir):
            if sd.lower() == d.lower() or sd.lower() == d.lower().replace("-", "_"):
                sub_match = sd
                
        results[d] = {
            "has_cargo": has_cargo,
            "empty_lib": empty_lib,
            "size_bytes": size,
            "substrate_match": sub_match
        }
        
    print(json.dumps(results, indent=2))

analyze_ensembles()
