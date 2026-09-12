import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

content = content.replace("simp only [corrT, corrTel, Qsub, Qle, add, neg]", "unfold corrT corrTel Qsub Qle add neg")
content = content.replace("simp only [corrTP, corrTel2, Qsub, Qle, add, neg]", "unfold corrTP corrTel2 Qsub Qle add neg")
content = content.replace("simp only [corrTP, corrTel3, Qsub, Qle, add, neg]", "unfold corrTP corrTel3 Qsub Qle add neg")
content = content.replace("simp only [corrTP, corrTel4, Qsub, Qle, add, neg]", "unfold corrTP corrTel4 Qsub Qle add neg")
content = content.replace("simp only [corrTP, corrTel5, Qsub, Qle, add, neg]", "unfold corrTP corrTel5 Qsub Qle add neg")

# For corrTP1_le_teldiff1: it also has push_cast and unrolling of 16.
# I already replaced it with a private int lemma, but omega failed because 16 got unrolled in `e1`?
# In my python script for `corrTP1_int_eq`, I didn't change `16` to `(16 : Int)` properly.
# The error said: `b - 64*c >= 0`. `b` had 16, `c` had `1 + 1 ... 16`.
# This is because I didn't change `corrTel1` to use `(16:Int)`.
# Let's just fix corrTel1 and all others by replacing `16` with `(16 : Int)` inside `corrTel1`?
# No, Q takes `Int` and `Nat`. 16 is Nat for the denominator.
# The issue is `exact exact_mod_cast hn` or `push_cast` expanding `16:Nat` to `1+1..`.
# Let's replace `push_cast` with `change`!
# If we replace `push_cast` with a lemma, we avoid the unrolling.

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
