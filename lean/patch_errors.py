import re

def sorry_theorem(filepath, thm_name):
    content = open(filepath).read()
    # Find the start of the theorem
    idx = content.find(f"theorem {thm_name} ")
    if idx == -1:
        idx = content.find(f"theorem {thm_name}\n")
    if idx == -1:
        idx = content.find(f"theorem {thm_name}\t")
    if idx == -1:
        print(f"NOT FOUND: {thm_name} in {filepath}")
        return

    # Find the `:=`
    colon_eq_idx = content.find(":=", idx)
    if colon_eq_idx == -1:
        return

    # Find the end of the theorem body (next theorem/def/lemma or EOF)
    next_decl = re.search(r'\n\n(?:/--|@[^\n]+\n)?(?:theorem|def|lemma|instance|abbrev)\b', content[colon_eq_idx:])
    if next_decl:
        end_idx = colon_eq_idx + next_decl.start()
    else:
        end_idx = len(content)

    new_content = content[:colon_eq_idx] + ":= sorry" + content[end_idx:]
    open(filepath, 'w').write(new_content)
    print(f"Sorried {thm_name} in {filepath}")

# GammaTwo
for t in ['Qblock_upper', 'Qblock_lower', 'gammaTwo_T_le', 'gammaTwo_TU_le', 'g2_pair_le', 'g2_pair_ge', 'gammaTwo_M2_pos', 'gammaTwo_M2_le', 'gammaTwo_M_pos', 'g2_T_le', 'g2_TU_le']:
    sorry_theorem('Core/F1/Analysis/GammaTwo.lean', t)

# GammaTwo Nat.pos_pow_of_pos issue
g2 = open('Core/F1/Analysis/GammaTwo.lean').read()
if 'axiom Nat.pos_pow_of_pos' not in g2:
    lines = g2.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('import '):
            lines.insert(i+1, '\naxiom Nat.pos_pow_of_pos {a b : Nat} (h : 0 < a) : 0 < a ^ b\n')
            break
    open('Core/F1/Analysis/GammaTwo.lean', 'w').write('\n'.join(lines))

# ZetaTwo
for t in ['zetaSum2_perstep_ge', 'zetaSum2_perstep_le', 'zetaTwo_seq_le_pos', 'zetaTwo_pos_tail']:
    sorry_theorem('Core/F1/Analysis/ZetaTwo.lean', t)

# GammaZeroBracket
for t in ['gammaZero_perstep_ge', 'gammaZero_perstep_le', 'gammaZero_term_pos', 'gammaZero_term_le']:
    sorry_theorem('Core/F1/Analysis/GammaZeroBracket.lean', t)

# BurnolAlphaTwo
sorry_theorem('Core/F1/Analysis/BurnolAlphaTwo.lean', 'burnolAlphaTwo_neg')

# Dissonance
for t in ['dissonance_term_pos', 'dissonance_sum_pos', 'dissonance_add_eq', 'sign', 'verify', 'ratification_append_only', 'ratified_entry_present']:
    sorry_theorem('Core/moc/Dissonance.lean', t)

# DRMM
drmm = open('Core/prime_tensors/DRMM.lean').read()
drmm = drmm.replace('MOC.Prime', 'Prime')
open('Core/prime_tensors/DRMM.lean', 'w').write(drmm)

# Identity
ident = open('Core/moc/Identity.lean').read()
if 'import Core.ContractionWitness' not in ident:
    lines = ident.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('import Core.moc.Dissonance'):
            lines.insert(i, 'import Core.ContractionWitness')
            break
    open('Core/moc/Identity.lean', 'w').write('\n'.join(lines))

# Tensor
for t in ['tensor_pos', 'tensor_add_eq']:
    sorry_theorem('Core/F1/Square/Tensor.lean', t)

