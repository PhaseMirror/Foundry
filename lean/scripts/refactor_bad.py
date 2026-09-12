import os
import re

replacements = {
    "import Core.Foundations.": "import Core.foundations.",
    "import Core.MTPI.": "import Core.mtpi.",
    "import Core.Operators.": "import Core.operators.",
    "import Core.Stability.": "import Core.stability.",
    "import Core.MOC.": "import Core.moc.",
    "import Core.f1_square.IntersectionTemplate": "import Core.f1_square.Square.IntersectionTemplate",
    "import Core.f1_square.DeitmarTest": "import Core.f1_square.Square.DeitmarTest",
    
    # Missing files, we will comment them out
    "import Core.Basic": "-- import Core.Basic",
    "import Core.AdelicBorn": "-- import Core.AdelicBorn",
    "import Core.EthicalConvergence": "-- import Core.EthicalConvergence",
    "import Core.prime_tensors.AL_GFT": "-- import Core.prime_tensors.AL_GFT",
    "import Core.kernels.Core": "-- import Core.kernels.Core",
    "import Core.kernels.Contraction": "-- import Core.kernels.Contraction",
    "import Core.universal_constant.BoundedMultiplicity": "-- import Core.universal_constant.BoundedMultiplicity",
    "import Core.f1_square.SovereignBridge": "-- import Core.f1_square.SovereignBridge",
    "import Core.foundations.SpectralTheory": "-- import Core.foundations.SpectralTheory",
    "import Core.foundations.HilbertSchmidt": "-- import Core.foundations.HilbertSchmidt",
    "import Core.mtpi.PrimeWord": "-- import Core.mtpi.PrimeWord",
}

for root, dirs, files in os.walk('Core'):
    for file in files:
        if file.endswith('.lean'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()

            new_content = content
            for old, new in replacements.items():
                new_content = new_content.replace(old, new)

            if new_content != content:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
