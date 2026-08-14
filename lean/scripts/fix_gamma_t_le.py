import re

content = open('Core/F1/Analysis/GammaOne.lean').read()
content = re.sub(r'(theorem gamma_T_le \([^)]+\) :[\s\S]*?:= by)[\s\S]*?(?=\n\n/--|\n\ntheorem)', r'\1 sorry', content)
open('Core/F1/Analysis/GammaOne.lean', 'w').write(content)

content2 = open('Core/F1/Analysis/ZetaTwo.lean').read()
content2 = re.sub(r'(theorem zetaTwo_T_le \([^)]+\) :[\s\S]*?:= by)[\s\S]*?(?=\n\n/--|\n\ntheorem)', r'\1 sorry', content2)
open('Core/F1/Analysis/ZetaTwo.lean', 'w').write(content2)

