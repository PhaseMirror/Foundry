import re
from pathlib import Path

prime_dir = Path('Prime')

moved_modules = [
    'ExplicitFormula', 'DirichletConvergence', 'DirichletMul', 
    'EulerProduct', 'TraceFormula', 'Xi', 'RiemannHypothesis', 
    'SafePrimeDefect', 'CompositeFunctorDefect', 'SedonaRiskModel'
]

for f in prime_dir.glob('*.lean'):
    content = f.read_text(encoding='utf-8')
    orig = content
    
    # 1. Move imports before namespace
    imports = re.findall(r'^import .*$', content, re.MULTILINE)
    content = re.sub(r'^import .*$\n', '', content, flags=re.MULTILINE)
    
    # Put imports at top
    if imports:
        content = '\n'.join(imports) + '\n\n' + content.lstrip()
        
    # 2. Fix internal imports to Prime
    for mod in moved_modules:
        content = re.sub(r'import Multiplicity\.F1\.Analysis\.' + mod, r'import Prime.' + mod, content)
        content = re.sub(r'import Multiplicity\.dynamics\.' + mod, r'import Prime.' + mod, content)
        content = re.sub(r'import Multiplicity\.' + mod, r'import Prime.' + mod, content)
        
    # 3. Fix Zeta import in TraceFormula
    content = re.sub(r'import Prime\.Zeta', r'import Multiplicity.F1.Analysis.Zeta', content)
    
    # 4. Fix Sedona end
    content = re.sub(r'end Prime\.Sedona\n', 'end Prime.SedonaRiskModel\n', content)
    
    if content != orig:
        f.write_text(content, encoding='utf-8')

