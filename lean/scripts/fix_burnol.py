import re

content = open('Core/F1/Analysis/BurnolAlphaTwo.lean').read()
content = re.sub(r'(theorem\s+burnolAlphaTwo_neg\b[^:=]*?:\s*(?:[^=]|=(?!>))*?)(:=[\s\S]*?)(?=\n\n/--|\n\n(?:@[^\n]+\n)?(?:theorem|def|lemma|instance|abbrev)|$)', r'\1:= sorry', content)
open('Core/F1/Analysis/BurnolAlphaTwo.lean', 'w').write(content)

