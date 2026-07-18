import os

lean_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean"

replacements = {
    "import MOC.Core": "import Core.Spine",
    "MOC.Core.": "Core.Spine.",
    "MOC.RiskLevel": "Core.Spine.RiskLevel",
    "MOC.EsiInputs": "Core.Spine.EsiInputs",
    "MOC.evaluateEsiRiskLevel": "Core.Spine.evaluateEsiRiskLevel",
    "MOC.MocOp": "Core.Spine.MocOp",
    "MOC.OperatorWord": "Core.Spine.OperatorWord",
    "MOC.StateMorphism": "Core.Spine.StateMorphism",
    "MOC.isMorphismAdmissible": "Core.Spine.isMorphismAdmissible",
    "MOC.aceBound": "Core.Spine.aceBound",
    "MOC.isAdmissible": "Core.Spine.isAdmissible",
    "MOC.ResonanceBound": "Core.Spine.ResonanceBound",
    "MOC.is_lambda_m_stable": "Core.Spine.is_lambda_m_stable"
}

def replace_in_files():
    for root, dirs, files in os.walk(lean_dir):
        if ".lake" in root:
            continue
        for file in files:
            if file.endswith(".lean"):
                path = os.path.join(root, file)
                with open(path, "r") as f:
                    content = f.read()
                
                changed = False
                for old_str, new_str in replacements.items():
                    if old_str in content:
                        content = content.replace(old_str, new_str)
                        changed = True
                
                if changed:
                    with open(path, "w") as f:
                        f.write(content)

replace_in_files()
print("Refactor complete.")
