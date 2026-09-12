import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

# Fix sq_nonneg_int
content = content.replace(
'''private theorem sq_nonneg_int (a : Int) : 0 ≤ a * a := by
  rcases Int.le_total 0 a with h | h
  · exact Int.mul_nonneg h h
  · have h' : (0 : Int) ≤ -a := by omega
    have := Int.mul_nonneg h' h'; simpa using this''',
'''private theorem sq_nonneg_int (a : Int) : 0 ≤ a * a := by
  rcases Int.le_total 0 a with h | h
  · exact Int.mul_nonneg h h
  · have h' : (0 : Int) ≤ -a := by omega
    have h1 := Int.mul_nonneg h' h'
    have h2 : (-a) * (-a) = a * a := by ring_uor
    omega''')

# For the max recursion depth, we will extract the exact integer equality into a lemma!
# But there are many. Let's just fix the push_cast issue and maxRecDepth by using dsimp.
# We replace `simp only [..., Qsub, Qle, add, neg]\n  push_cast`
# with:
# `change (((...num ... ))) <= ...\n  dsimp [corrT, corrTel, Qsub, Qle, add, neg]\n  push_cast`

# Actually, the unrolling happens because of `push_cast` on `16 : Nat`, which gets unrolled to `1+1...`.
# We can avoid this by replacing `16` with `(16 : Int)` in the definitions?
# Let's change the definitions to use `.den : Int` instead.

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
