import re
from pathlib import Path

prime_dir = Path('Prime')

for f in prime_dir.glob('*.lean'):
    content = f.read_text(encoding='utf-8')
    orig = content
    
    # Fix open statements
    content = re.sub(r'open Multiplicity\.F1\.Analysis\.', 'open Prime.', content)
    content = re.sub(r'open Multiplicity\.ExplicitFormula', 'open Prime.ExplicitFormula', content)
    content = re.sub(r'open Multiplicity\.', 'open Prime.', content)
    
    if content != orig:
        f.write_text(content, encoding='utf-8')

