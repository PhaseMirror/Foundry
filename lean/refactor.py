import os

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacements based on the directory structure mapping
    replacements = {
        "import MOC.": "import Core.moc.",
        "import PIRTM.": "import Core.prime_tensors.",
        "import PRMS.": "import Core.multiplicity_substrate.",
        "import F1Square.": "import Core.f1_square.",
        "import PARM.": "import Core.position_aware.",
        "import UMCPAROM.": "import Core.kernels.",
        "import RocEngine.": "import Core.roc_engine.",
        "import RAMANUJAN.": "import Core.moc.Ramanujan.",
        "import Governance.": "import Governance.",
        "import AffineCore.": "import Core.",
        "import ZMOD.": "import Core.universal_constant.",
    }

    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('Core'):
    for file in files:
        if file.endswith('.lean'):
            process_file(os.path.join(root, file))
