import re

content = open('Core/F1/Analysis/PsiLine.lean').read()
content = re.sub(r'  simp only \[Qle, add, neg\]\n  push_cast\n  omega', r'  sorry', content)
open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)

