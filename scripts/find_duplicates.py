import os
from collections import defaultdict

root = "/home/multiplicity/Multiplicity/PhaseMirror/Prime"
excludes_dirs = {".git", "target", "node_modules", ".lake", ".devcontainer", "artifact", "compiler", "mlir", "libcxx", "llvm", "docs", "scripts", "materia_commons", "wasm-bridge"}
excludes_files = {
    "Cargo.toml", "Cargo.lock", "lib.rs", "main.rs", "mod.rs",
    "lakefile.lean", "lakefile.toml", "lake-manifest.json", "lean-toolchain",
    "README.md", "LICENSE", "package.json", "index.js", ".gitignore",
    "kani_verification.rs"
}

file_map = defaultdict(list)

for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d not in excludes_dirs]
    
    # We only care about user source code duplicates
    if "libcxx" in dirpath or "llvm" in dirpath or "clang" in dirpath:
        continue
        
    for f in filenames:
        if f in excludes_files:
            continue
        if f.endswith(".lean") or f.endswith(".rs") or f.endswith(".yaml"):
            file_map[f].append(os.path.join(dirpath, f))

out = []
for f, paths in file_map.items():
    if len(paths) > 1:
        out.append(f"Duplicate {f}:")
        for p in paths:
            out.append(f"  {p}")
        out.append("-" * 40)

with open("/home/multiplicity/Multiplicity/PhaseMirror/duplicate_results.txt", "w") as f:
    f.write("\n".join(out))
