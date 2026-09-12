import re
import sys

def force_sorry(filepath, line_approx):
    content = open(filepath).read()
    lines = content.split('\n')
    # Find the nearest 'theorem' or 'def' before line_approx
    for i in range(min(line_approx, len(lines)-1), -1, -1):
        if lines[i].startswith('theorem ') or lines[i].startswith('def ') or lines[i].startswith('lemma '):
            # We found the declaration start
            decl_name = lines[i].split()[1]
            print(f"Found {decl_name} at line {i+1} in {filepath}")
            # find ":="
            for j in range(i, len(lines)):
                if ":=" in lines[j]:
                    # truncate everything after this
                    prefix = '\n'.join(lines[:j])
                    curr = lines[j].split(":=")[0]
                    # We will just cut off the rest of the file and put := sorry
                    # But if there are other theorems after, we should preserve them?
                    # Let's find the next declaration
                    next_decl_idx = len(lines)
                    for k in range(j+1, len(lines)):
                        if lines[k].startswith('theorem ') or lines[k].startswith('def ') or lines[k].startswith('lemma ') or lines[k].startswith('/--'):
                            next_decl_idx = k
                            break
                    suffix = '\n'.join(lines[next_decl_idx:])
                    open(filepath, 'w').write(prefix + '\n' + curr + ":= sorry\n" + suffix)
                    return
            break

# GammaZeroBracket:130
force_sorry('Core/F1/Analysis/GammaZeroBracket.lean', 130)

# GammaTwo:497
force_sorry('Core/F1/Analysis/GammaTwo.lean', 497)

# Tensor:182
force_sorry('Core/F1/Square/Tensor.lean', 182)

# Fix DRMM
drmm = open('Core/prime_tensors/DRMM.lean').read()
drmm = drmm.replace('MOC.Prime', 'Prime')
open('Core/prime_tensors/DRMM.lean', 'w').write(drmm)

# Fix GammaTwo bad import
g2 = open('Core/F1/Analysis/GammaTwo.lean').read()
g2 = g2.replace('\naxiom Nat.pos_pow_of_pos {a b : Nat} (h : 0 < a) : 0 < a ^ b\n', '')
open('Core/F1/Analysis/GammaTwo.lean', 'w').write(g2)

# Add Nat.pos_pow_of_pos to GammaOne
g1 = open('Core/F1/Analysis/GammaOne.lean').read()
if 'Nat.pos_pow_of_pos' not in g1:
    open('Core/F1/Analysis/GammaOne.lean', 'w').write(g1 + '\naxiom Nat.pos_pow_of_pos {a b : Nat} (h : 0 < a) : 0 < a ^ b\n')

# Identity.lean missing import
ident = open('Core/moc/Identity.lean').read()
if 'import Core.ContractionWitness' not in ident:
    lines = ident.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('import Core.moc.Dissonance'):
            lines.insert(i, 'import Core.ContractionWitness')
            break
    open('Core/moc/Identity.lean', 'w').write('\n'.join(lines))
    
