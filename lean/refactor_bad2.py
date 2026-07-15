import os

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    new_lines = []
    changed = False
    
    # We will just comment out the bad imports that were identified.
    bad_prefixes = [
        "import CRMF.",
        "import GOLDILOCKS.",
        "import Governance.",
        "import META_RELATIVITY.",
        "import CRMF",
        "import PRMS",
        "import UMCPAROM",
        "import PARM",
        "import ZMOD",
        "import RocEngine",
        "import XI_FORMAL",
        "import AxiomCleanCore.",
        "import Lean4PolicyKernel.",
        "import UAC.",
        "import ALP.",
        "import ProofWidgets",
        "import Core.VERIFICATION", # just in case
    ]
    
    # Special exact replacements
    exact_replacements = {
        "import CRMF.Resonance": "import Core.Resonance",
        "import CRMF.ContractionWitness": "import Core.ContractionWitness",
        "import CRMF.Stability": "import Core.prime_tensors.Stability",
    }
    
    for line in lines:
        stripped = line.strip()
        
        # apply exact replacement
        if stripped in exact_replacements:
            new_lines.append(exact_replacements[stripped] + "\n")
            changed = True
            continue
            
        if stripped.startswith("import "):
            if any(stripped.startswith(bp) for bp in bad_prefixes):
                # if it starts with import CRMF but is not in exact_replacements, comment it out
                new_lines.append("-- " + line)
                changed = True
                continue
                
        new_lines.append(line)

    if changed:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('Core'):
    for file in files:
        if file.endswith('.lean'):
            process_file(os.path.join(root, file))
