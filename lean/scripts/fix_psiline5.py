import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

# Remove the bad set_option at the top
content = content.replace("set_option maxRecDepth 200000\n", "", 1)

# Add it after imports
content = content.replace("import Core.F1.Analysis.RealPow", "import Core.F1.Analysis.RealPow\n\nset_option maxRecDepth 200000\n")

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
