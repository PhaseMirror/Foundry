import os

models_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/models"

for root, dirs, files in os.walk(models_dir):
    if ".lake" in root:
        continue
    for file in files:
        if file.endswith(".lean"):
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            
            # Find all import lines
            lines = content.split('\n')
            imports = []
            others = []
            
            for line in lines:
                if line.startswith('import '):
                    imports.append(line)
                else:
                    others.append(line)
            
            if imports:
                # remove empty lines at the start of others
                while others and others[0] == '':
                    others.pop(0)
                    
                new_content = '\n'.join(imports) + '\n\n' + '\n'.join(others)
                with open(path, "w") as f:
                    f.write(new_content)

print("Fixed imports for all lean files in models.")
