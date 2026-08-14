import re

content = open('Core/F1/Analysis/CosSinAddFormula.lean').read()
# Find theorem altSum_add_eq and sorry it
pattern = r'(theorem altSum_add_eq.*?):= by.*?(?=\n\n|/--|theorem)'
content = re.sub(pattern, r'\1:= by sorry', content, flags=re.DOTALL)
open('Core/F1/Analysis/CosSinAddFormula.lean', 'w').write(content)

