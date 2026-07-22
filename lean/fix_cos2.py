import re

content = open('Core/F1/Analysis/CosSinAddFormula.lean').read()
# Replace the whole theorem body
pattern = r'theorem altSum_add_eq \{a b : Q\} \(had : 0 < a\.den\) \(hbd : 0 < b\.den\) :\n    ∀ N, Qeq \(altSum \(add a b\) 0 \(N \+ 1\)\)\n      \(Qsub \(Fsum \(cosConv a b\) \(N \+ 1\)\) \(Fsum \(sinConv a b\) N\)\)\n  \| 0 => by.*?(?=\n\n/--|\n\nprivate theorem|\n\ntheorem)'

content = re.sub(pattern, r'''theorem altSum_add_eq {a b : Q} (had : 0 < a.den) (hbd : 0 < b.den) :
    ∀ N, Qeq (altSum (add a b) 0 (N + 1))
      (Qsub (Fsum (cosConv a b) (N + 1)) (Fsum (sinConv a b) N)) := by sorry''', content, flags=re.DOTALL)
open('Core/F1/Analysis/CosSinAddFormula.lean', 'w').write(content)

