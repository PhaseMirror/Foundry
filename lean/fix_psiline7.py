import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

# Let's replace the whole `unfold ...` and `push_cast` with `show _ <= _`.
# For corrT_le_teldiff (line 71):
old1 = '''private theorem corrT_le_teldiff (n : Nat) :
    Qle (corrT n) (Qsub (corrTel n) (corrTel (n + 1))) := by
  unfold corrT corrTel Qsub Qle add neg
  push_cast'''
new1 = '''private theorem corrT_le_teldiff (n : Nat) :
    Qle (corrT n) (Qsub (corrTel n) (corrTel (n + 1))) := by
  show (100 * ((4 * (n + 1) + 1) * (4 * (n + 1) + 1) + 100) +
        -100 * ((4 * n + 1) * (4 * n + 1) + 100)) *
      ((4 * n + 1) * ((4 * n + 1) * (4 * n + 1) + 400)) ≤
    100 * (((4 * n + 1) * (4 * n + 1) + 100) * ((4 * (n + 1) + 1) * (4 * (n + 1) + 1) + 100))
  push_cast'''
content = content.replace(old1, new1)

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
