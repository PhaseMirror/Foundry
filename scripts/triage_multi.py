import os
import re

dir_path = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/multi-ensembles"
root_cargo = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/Cargo.toml"

def analyze_crates():
    print("Multi-Ensembles Triage Analysis")
    print("===============================")
    for d in os.listdir(dir_path):
        p = os.path.join(dir_path, d)
        if not os.path.isdir(p): continue
        
        has_cargo = os.path.exists(os.path.join(p, "Cargo.toml"))
        lib_path = os.path.join(p, "src", "lib.rs")
        main_path = os.path.join(p, "src", "main.rs")
        
        has_lib = os.path.exists(lib_path)
        has_main = os.path.exists(main_path)
        
        size = sum(os.path.getsize(os.path.join(root, file)) 
                   for root, _, files in os.walk(p) 
                   for file in files)
        
        empty = size < 100 or (not has_lib and not has_main)
        
        print(f"Crate: {d}")
        print(f"  Has Cargo: {has_cargo}")
        print(f"  Empty/Stub: {empty}")
        print(f"  Size: {size} bytes")
        print("---")

if __name__ == "__main__":
    analyze_crates()
