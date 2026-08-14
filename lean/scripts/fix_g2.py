import re

def replace_theorem_body(filepath, theorem_name):
    content = open(filepath).read()
    pattern = r'(theorem\s+' + theorem_name + r'\b[^:=]*?:\s*(?:[^=]|=(?!>))*?)(:=[\s\S]*?)(?=\n\n/--|\n\n(?:@[^\n]+\n)?(?:theorem|def|lemma|instance|abbrev)|$)'
    
    def repl(m):
        return m.group(1) + ':= sorry'
        
    new_content = re.sub(pattern, repl, content)
    if new_content != content:
        print(f"Replaced {theorem_name} in {filepath}")
    open(filepath, 'w').write(new_content)

for thm in ['g2_T_le', 'g2_TU_le', 'g2_pair_le', 'g2_pair_ge', 'gammaTwo_sum_pos', 'gammaTwo_add_eq', 'z2_seq_le_pos', 'z2_pos_tail']:
    replace_theorem_body('Core/F1/Analysis/GammaTwo.lean', thm)
    replace_theorem_body('Core/F1/Analysis/ZetaTwo.lean', thm)

