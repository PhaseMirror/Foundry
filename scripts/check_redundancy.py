import os

def get_names(path):
    if not os.path.exists(path): return []
    return [d for d in os.listdir(path) if os.path.isdir(os.path.join(path, d))]

substrates = get_names("/home/multiplicity/Multiplicity/Phase Mirror/Prime/substrates")
crates = get_names("/home/multiplicity/Multiplicity/Phase Mirror/Prime/crates")
multi = get_names("/home/multiplicity/Multiplicity/Phase Mirror/Prime/multi-ensembles")

existing = set(substrates + crates)

print("Redundancy Check:")
for m in multi:
    if m in existing:
        print(f"Exact match: {m}")
    else:
        # Check for partial matches
        for e in existing:
            if m.replace('-', '') in e.replace('-', '') or e.replace('-', '') in m.replace('-', ''):
                print(f"Partial match: {m} <-> {e}")
