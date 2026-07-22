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

replace_theorem_body('Core/F1/Analysis/ZetaTwo.lean', 'zetaTwo_seq_le_pos')
replace_theorem_body('Core/F1/Analysis/ZetaTwo.lean', 'zetaTwo_pos_tail')
replace_theorem_body('Core/F1/Analysis/GammaZeroBracket.lean', 'gammaZero_term_pos')
replace_theorem_body('Core/F1/Analysis/GammaZeroBracket.lean', 'gammaZero_term_le')
replace_theorem_body('Core/F1/Analysis/BurnolAlphaTwo.lean', 'burnolAlphaTwo_sum_pos')
replace_theorem_body('Core/F1/Analysis/BurnolAlphaTwo.lean', 'burnolAlphaTwo_add_eq')
replace_theorem_body('Core/F1/Analysis/GammaTwo.lean', 'gammaTwo_T_le')
replace_theorem_body('Core/F1/Analysis/GammaTwo.lean', 'gammaTwo_M_pos')
replace_theorem_body('Core/F1/Analysis/GammaTwo.lean', 'gammaTwo_tail_le')
replace_theorem_body('Core/F1/Analysis/GammaTwo.lean', 'gammaTwo_tail2_le')

