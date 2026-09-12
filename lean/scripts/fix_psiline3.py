import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

# Fix `simpa using hh` in corrT_le_teldiff
content = content.replace(
'''      · have h' : (0 : Int) ≤ -(4 * (n : Int) - 1) := by omega
        have hh : (0 : Int) ≤ (-(4 * (n : Int) - 1)) * (-(4 * (n : Int) - 1)) := Int.mul_nonneg h' h'
        simpa using hh''',
'''      · have h' : (0 : Int) ≤ -(4 * (n : Int) - 1) := by omega
        have hh : (0 : Int) ≤ (-(4 * (n : Int) - 1)) * (-(4 * (n : Int) - 1)) := Int.mul_nonneg h' h'
        have h2 : (-(4 * (n : Int) - 1)) * (-(4 * (n : Int) - 1)) = (4 * (n : Int) - 1) * (4 * (n : Int) - 1) := by ring_uor
        omega''')

# For the max recursion depth, we will extract private int lemmas for each.
# Actually, the problem is just `simp only [...]` looping. If we change it to:
# `change (((...num ... ))) <= ...\n  dsimp [corrT, corrTel, Qsub, Qle, add, neg]\n  push_cast`
# Why did my previous python script fail to replace?
# Let's check if the strings matched.

content = content.replace("simp only [corrT, corrTel, Qsub, Qle, add, neg]", "dsimp [corrT, corrTel, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel2, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel2, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel3, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel3, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel4, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel4, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel5, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel5, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel1, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel1, Qsub, Qle, add, neg]")

# Also replace `push_cast` and `ring_uor` that fail.
# In corrTP1_le_teldiff1:
content = content.replace(
'''  have key :
      (16 * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16)
          + -16 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16))
        * ((4 * (n : Int) + 1) * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * 1 + 16))
      = 64 * (((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16))
        + 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) := by ring_uor
  rw [key]''',
'''  have key :
      (16 * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16)
          + -16 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16))
        * ((4 * (n : Int) + 1) * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * 1 + 16))
      = 64 * (((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16))
        + 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) := by ring_uor
  have key2 : (16 : Int) = 16 := rfl
  -- wait, I need to extract the lemma for this because `push_cast` evaluates `16` to `1+1...16` in the target, and `rw` fails.''')

# Let's extract the lemma instead.

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
