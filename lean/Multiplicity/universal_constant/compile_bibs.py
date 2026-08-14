import os
import glob

root_dir = '/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core/universal_constant'
out_file = os.path.join(root_dir, 'reference.bib')

bib_contents = []
bib_files_found = []

for dirpath, dirnames, filenames in os.walk(root_dir):
    for filename in filenames:
        if filename.endswith('.bib') and os.path.join(dirpath, filename) != out_file:
            file_path = os.path.join(dirpath, filename)
            bib_files_found.append(file_path)
            with open(file_path, 'r') as f:
                bib_contents.append(f.read())

if bib_contents:
    with open(out_file, 'w') as f:
        f.write('\n\n'.join(bib_contents))
    print(f"Master reference.bib created at {out_file}.")
    print("Combined the following files:")
    for f in bib_files_found:
        print(f" - {f}")
else:
    print("No .bib files found in subdirectories.")
