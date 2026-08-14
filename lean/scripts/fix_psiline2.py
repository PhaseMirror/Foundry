import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

# Replace all occurrences of `simp only [..., add, neg]\n  push_cast`
# Wait, let's just replace `simp only ` with `dsimp only ` in the specific theorems.
content = content.replace("simp only [corrT, corrTel, Qsub, Qle, add, neg]", "dsimp [corrT, corrTel, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel2, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel2, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel3, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel3, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel4, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel4, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel5, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel5, Qsub, Qle, add, neg]")
content = content.replace("simp only [corrTP, corrTel1, Qsub, Qle, add, neg]", "dsimp [corrTP, corrTel1, Qsub, Qle, add, neg]")

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
