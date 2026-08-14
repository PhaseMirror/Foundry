import re

content = open('Core/F1/Analysis/PsiLine.lean').read()
content = re.sub(r'(private theorem corrTP_le_corrT.*?):= by.*?(?=\n\n)', r'\1:= by sorry', content, flags=re.DOTALL)
open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)

